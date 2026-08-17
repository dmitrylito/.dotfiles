#!/usr/bin/env python3
"""style-guard.py — enforces the output contract in style-rules.md on every response.

Wired from ~/.claude/settings.json (hook JSON arrives on stdin):
    style-guard.py inject      UserPromptSubmit -> re-injects style-rules.md every turn
    style-guard.py check       Stop             -> pattern checks + judge, blocks on failure
    style-guard.py check-fast  SubagentStop     -> pattern checks only, no judge call

A blocked Stop is fed back to Claude as an instruction, so it must rewrite before it can
finish. Two layers: deterministic pattern checks (free), then an optional Haiku judge for
fabrication and invented jargon, which regex cannot see.

Env:
    STYLE_GUARD=0        disable everything
    STYLE_GUARD_JUDGE=0  keep the pattern checks, skip the ~5s judge call
    STYLE_GUARD_CHILD=1  set on the judge subprocess; makes this hook a no-op so the
                         nested `claude -p` cannot recurse into itself

Requires python3 and the `claude` CLI on PATH. No third-party deps.
"""

import json
import os
import re
import subprocess
import sys
import time
from pathlib import Path

RULES_FILE = Path(__file__).resolve().with_name("style-rules.md")
JUDGE_MODEL = "claude-haiku-4-5-20251001"
JUDGE_MIN_CHARS = 400
JUDGE_TIMEOUT = 60
MAX_BLOCKS_PER_TURN = 2

BANNED = [
    (r"\bleverag(e|es|ed|ing)\b", "leverage -> use"),
    (r"\butiliz(e|es|ed|ing|ation)\b", "utilize -> use"),
    (r"\bin order to\b", "in order to -> to"),
    (r"\bfacilitat(e|es|ed|ing)\b", "facilitate -> help"),
    (r"\b(essentially|basically|fundamentally)\b", "filler adverb"),
    (r"\b(it'?s|it is)? ?worth noting\b", "worth noting"),
    (r"\bas you know\b", "as you know"),
    (r"\b(note that|please note|keep in mind)\b", "note that / keep in mind"),
    (r"\bdelv(e|es|ed|ing)\b", "delve"),
    (r"\b(deep dive|dive into|diving into|let'?s dive)\b", "dive into"),
    (r"\b(robust|seamless|seamlessly|streamlin(e|es|ed|ing))\b", "marketing adjective"),
    (r"\b(comprehensive|myriad|plethora|vast array)\b", "inflated quantifier"),
    (r"\b(key )?(takeaway|insight)s?\b", "takeaway / insight section"),
    (r"\b(in summary|to summarize|in conclusion|overall,)\b", "closing summary"),
    (r"\b(moreover|furthermore)\b", "moreover / furthermore"),
    (r"\ba testament to\b", "a testament to"),
    (r"\b(game.?chang\w+|cutting.?edge|state.of.the.art)\b", "hype phrase"),
    (
        r"\b(i hope this helps|let me know if|feel free to|"
        r"is there (anything|something) else|anything else (i can|you)|"
        r"happy to help|glad i could help)\b",
        "closing pleasantry",
    ),
    (r"★", "insight block marker"),
    (
        r"\b(i apologi[sz]e|my apologies|sorry about that|my mistake|"
        r"you'?re (absolutely )?right|you are (absolutely )?right|"
        r"good catch|great catch|excellent point)\b",
        "apology / flattery",
    ),
]

PREAMBLE = re.compile(
    r"^\W*(sure|certainly|absolutely|of course|great question|excellent question|"
    r"good question|happy to|i'?ll help|let me help|i can help|no problem|perfect!|great!)"
    r"\b",
    re.I,
)

EMOJI = re.compile(
    "[\U0001f300-\U0001faff\U00002700-\U000027bf\U0001f1e6-\U0001f1ff☀-⛿]"
)

JUDGE_PROMPT = """You are a strict style auditor. You are NOT a helper and you do not answer \
the content of the response. Judge one assistant response against the contract below.

Fail it ONLY for a clear, specific violation of one of these four:
A. FABRICATION - it states a file path, flag, function, API, command, error string, version, \
number, or behaviour as fact when nothing in the grounding context supports it, and it does \
not mark the claim as unverified or a guess.
B. INVENTED TERMINOLOGY - it coins a name, Capitalizes a Concept, or brands an idea with a \
label ("the X pattern", "the Y layer") that does not already exist in the context or the \
user's own words.
C. INFLATED LANGUAGE - pompous or vague wording where a plain word exists, or teaching and \
explaining that was not asked for.
D. PADDING - preamble, restating the question, or a closing summary repeating the opening.

Be conservative. Absence of evidence in the grounding context is NOT proof of fabrication \
when the context is truncated - only fail A when the claim is both specific and clearly \
unsupported. Code, quoted output, and text in backticks are exempt from C.

Reply with exactly one line:
PASS
or
FAIL: <one short sentence naming the rule letter and the exact offending words>

=== CONTRACT ===
{rules}

=== GROUNDING CONTEXT (tool output and prior turn, truncated) ===
{context}

=== RESPONSE UNDER AUDIT ===
{response}
"""


def disabled():
    return os.environ.get("STYLE_GUARD") == "0" or os.environ.get("STYLE_GUARD_CHILD") == "1"


def read_payload():
    try:
        raw = sys.stdin.read()
        data = json.loads(raw) if raw.strip() else {}
        return data if isinstance(data, dict) else {}
    except (ValueError, OSError):
        return {}


def read_rules():
    try:
        return RULES_FILE.read_text(encoding="utf-8").strip()
    except OSError:
        return ""


def prose_only(text):
    """Strip anything the contract exempts, so quoted code never trips a pattern."""
    text = re.sub(r"```.*?```", " ", text, flags=re.S)
    text = re.sub(r"~~~.*?~~~", " ", text, flags=re.S)
    text = re.sub(r"`[^`\n]*`", " ", text)
    text = re.sub(r"https?://\S+", " ", text)
    return text


def pattern_violations(message):
    prose = prose_only(message)
    found = []
    for pattern, label in BANNED:
        hit = re.search(pattern, prose, re.I)
        if hit:
            found.append('banned: {} — "{}"'.format(label, hit.group(0).strip()))
    first_line = next((ln for ln in prose.splitlines() if ln.strip()), "")
    if PREAMBLE.match(first_line):
        found.append('preamble: response opens with "{}"'.format(first_line[:60].strip()))
    hit = EMOJI.search(prose)
    if hit:
        found.append("emoji: {}".format(hit.group(0)))
    if len(prose.strip()) < 1200 and re.search(r"^#{1,6} ", prose, re.M):
        found.append("markdown heading in a short answer")
    return found


def turn_context(payload, limit=6000):
    """Best-effort grounding text from the transcript tail. Format is not guaranteed, so
    every failure here degrades to an empty context rather than blocking the turn."""
    path = payload.get("transcript_path")
    if not path:
        return ""
    try:
        lines = Path(path).read_text(encoding="utf-8", errors="replace").splitlines()[-200:]
    except OSError:
        return ""
    chunks = []
    for line in lines:
        try:
            entry = json.loads(line)
        except ValueError:
            continue
        chunks.extend(harvest_strings(entry.get("toolUseResult")))
        message = entry.get("message")
        if isinstance(message, dict):
            chunks.extend(harvest_strings(message.get("content")))
    text = "\n".join(c for c in chunks if c.strip())
    return text[-limit:]


def harvest_strings(node, depth=0):
    if depth > 6:
        return []
    if isinstance(node, str):
        return [node]
    if isinstance(node, list):
        out = []
        for item in node:
            out.extend(harvest_strings(item, depth + 1))
        return out
    if isinstance(node, dict):
        out = []
        for key in ("text", "content", "stdout", "stderr", "output"):
            if key in node:
                out.extend(harvest_strings(node[key], depth + 1))
        return out
    return []


def judge(message, payload, rules):
    if os.environ.get("STYLE_GUARD_JUDGE") == "0":
        return None
    if len(prose_only(message).strip()) < JUDGE_MIN_CHARS:
        return None
    prompt = JUDGE_PROMPT.format(
        rules=rules, context=turn_context(payload) or "(none available)", response=message
    )
    env = dict(os.environ, STYLE_GUARD_CHILD="1")
    try:
        result = subprocess.run(
            [
                "claude", "-p",
                "--model", JUDGE_MODEL,
                "--no-session-persistence",
                "--disallowed-tools", "*",
            ],
            input=prompt,
            capture_output=True,
            text=True,
            timeout=JUDGE_TIMEOUT,
            env=env,
        )
    except (OSError, subprocess.SubprocessError):
        return None
    if result.returncode != 0:
        return None
    verdict = result.stdout.strip().splitlines()
    verdict = verdict[-1].strip() if verdict else ""
    if verdict.upper().startswith("FAIL"):
        return verdict
    return None


def turn_key(payload):
    ident = payload.get("prompt_id") or payload.get("session_id") or "unknown"
    return re.sub(r"[^A-Za-z0-9_.-]", "_", str(ident))[:120]


def block_count(payload):
    """Cap rewrites per turn so a judge that keeps disagreeing cannot trap the session."""
    base = Path(os.environ.get("XDG_RUNTIME_DIR") or "/tmp") / "claude-style-guard"
    try:
        base.mkdir(parents=True, exist_ok=True)
        counter = base / turn_key(payload)
        fresh = counter.exists() and (time.time() - counter.stat().st_mtime) < 3600
        seen = int(counter.read_text()) if fresh else 0
        counter.write_text(str(seen + 1))
        return seen
    except (OSError, ValueError):
        return 0


def block(reason, event):
    payload = {
        "decision": "block",
        "reason": reason,
        "hookSpecificOutput": {
            "hookEventName": event,
            "decision": "block",
            "reason": reason,
        },
    }
    print(json.dumps(payload))
    sys.stderr.write(reason + "\n")
    sys.exit(2)


def do_inject():
    rules = read_rules()
    if rules:
        print(
            json.dumps(
                {
                    "hookSpecificOutput": {
                        "hookEventName": "UserPromptSubmit",
                        "additionalContext": rules,
                    }
                }
            )
        )
    sys.exit(0)


def do_check(use_judge):
    payload = read_payload()
    if payload.get("stop_hook_active"):
        sys.exit(0)
    message = payload.get("last_assistant_message")
    if not isinstance(message, str) or not message.strip():
        sys.exit(0)
    rules = read_rules()
    if not rules:
        sys.exit(0)

    problems = pattern_violations(message)
    if not problems and use_judge:
        verdict = judge(message, payload, rules)
        if verdict:
            problems = [verdict]
    if not problems:
        sys.exit(0)
    if block_count(payload) >= MAX_BLOCKS_PER_TURN:
        sys.exit(0)

    event = payload.get("hook_event_name") or "Stop"
    block(
        "STYLE GUARD BLOCKED THIS RESPONSE. It violates the output contract:\n"
        + "\n".join("  - " + p for p in problems)
        + "\n\nRewrite the response now, fixing exactly these violations. Do not apologise, "
        "do not argue, do not mention the style guard, do not explain the rewrite — just "
        "deliver the corrected response. Keep every fact, caveat, and failure report from "
        "the original; cut words, not substance. If a flagged word appears only because you "
        "were quoting or naming the word itself, wrap it in backticks, which are exempt.",
        event,
    )


def main():
    mode = sys.argv[1] if len(sys.argv) > 1 else ""
    if disabled():
        sys.exit(0)
    if mode == "inject":
        do_inject()
    elif mode in ("check", "check-fast"):
        do_check(use_judge=mode == "check")
    sys.exit(0)


if __name__ == "__main__":
    main()
