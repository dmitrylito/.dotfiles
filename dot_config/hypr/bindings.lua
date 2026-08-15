-- Omarchy defaults deliberately disabled (vim-style HJKL is used instead of
-- arrows) or replaced by a binding below.
local unbinds = {
  "SUPER + LEFT",
  "SUPER + RIGHT",
  "SUPER + UP",
  "SUPER + DOWN",
  "SUPER + ALT + LEFT",
  "SUPER + ALT + RIGHT",
  "SUPER + ALT + UP",
  "SUPER + ALT + DOWN",
  "SUPER + SHIFT + LEFT",
  "SUPER + SHIFT + RIGHT",
  "SUPER + SHIFT + UP",
  "SUPER + SHIFT + DOWN",
  "SUPER + CTRL + X",
  "SUPER + J",
  "SUPER + K",
  "SUPER + L",
  "SUPER + ALT + K",
  "SUPER + ALT + RETURN",
  "SUPER + SHIFT + F",
  "SUPER + ALT + SHIFT + F",
  "SUPER + SHIFT + B",
  "SUPER + SHIFT + ALT + B",
  "SUPER + SHIFT + M",
  "SUPER + SHIFT + N",
  "SUPER + SHIFT + D",
  "SUPER + SHIFT + Y",
  "SUPER + SHIFT + X",
  "SUPER + SHIFT + ALT + X",
}
for _, keys in ipairs(unbinds) do
  hl.unbind(keys)
end

-- Applications
o.bind("SUPER + ALT + RETURN", "Tmux", { launch = 'xdg-terminal-exec --dir="$(omarchy-cmd-terminal-cwd)" tmux new' })
o.bind("SUPER + SEMICOLON", "Terminal", { launch = 'xdg-terminal-exec --dir="$(omarchy-cmd-terminal-cwd)"' })
o.bind("SUPER + SHIFT + F", "File manager", { launch = "nautilus --new-window" })
o.bind("SUPER + ALT + SHIFT + F", "File manager (cwd)", { launch = 'nautilus --new-window "$(omarchy-cmd-terminal-cwd)"' })
o.bind("SUPER + SHIFT + B", "Browser", "omarchy-launch-browser")
o.bind("SUPER + ALT + SHIFT + B", "Browser (private)", "omarchy-launch-browser --private")
o.bind("SUPER + SHIFT + M", "Music", "omarchy-launch-or-focus spotify")
o.bind("SUPER + SHIFT + N", "Editor", "omarchy-launch-editor")
o.bind("SUPER + SHIFT + D", "Discord", 'omarchy-launch-or-focus ^discord$ "uwsm-app -- discordx.desktop"')

-- Web apps
o.bind("SUPER + SHIFT + Y", "YouTube", 'omarchy-launch-webapp "https://youtube.com/" --profile-directory="Default"')
o.bind("SUPER + SHIFT + X", "X", 'omarchy-launch-webapp "https://x.com/"')
o.bind("SUPER + ALT + SHIFT + X", "X Post", 'omarchy-launch-webapp "https://x.com/compose/post"')

-- System
o.bind("SUPER + CTRL + ALT + L", "Suspend", "systemctl suspend", { locked = true })

-- Dictation
o.bind("SUPER + Z", "Start dictation", "voxtype record toggle")
o.bind("RETURN", "Stop dictation", "voxtype record stop", { non_consuming = true })

-- Window management
o.bind("SUPER + U", "Toggle window pop-out (centered 16:10 float)", os.getenv("HOME") .. "/.config/hypr/scripts/toggle-popout.sh")
o.bind("SUPER + H", "Focus left window", hl.dsp.focus({ direction = "l" }))
o.bind("SUPER + J", "Focus next window", hl.dsp.focus({ direction = "d" }))
o.bind("SUPER + K", "Focus previous window", hl.dsp.focus({ direction = "u" }))
o.bind("SUPER + L", "Focus right window", hl.dsp.focus({ direction = "r" }))
o.bind("SUPER + SHIFT + H", "Swap window to the left", hl.dsp.window.swap({ direction = "l" }))
o.bind("SUPER + SHIFT + L", "Swap window to the right", hl.dsp.window.swap({ direction = "r" }))
o.bind("SUPER + SHIFT + K", "Swap window up", hl.dsp.window.swap({ direction = "u" }))
o.bind("SUPER + SHIFT + J", "Swap window down", hl.dsp.window.swap({ direction = "d" }))

-- Groups (dispatch args preserved from the legacy config)
o.bind("SUPER + ALT + L", "Move window to group on left", "hyprctl dispatch moveintogroup l")
o.bind("SUPER + ALT + H", "Move window to group on right", "hyprctl dispatch moveintogroup r")
o.bind("SUPER + ALT + K", "Move window to group on top", "hyprctl dispatch moveintogroup u")
o.bind("SUPER + ALT + J", "Move window to group on bottom", "hyprctl dispatch moveintogroup d")

-- Layout
o.bind("SUPER + M", "Show key bindings", "omarchy-menu-keybindings")
o.bind("SUPER + N", "Toggle window split", hl.dsp.layout("togglesplit"))

-- Special workspace
o.bind("SUPER + A", "Toggle AI scratchpad", hl.dsp.workspace.toggle_special("AI"))
o.bind("SUPER + ALT + A", "Move window to AI", hl.dsp.window.move({ workspace = "special:AI", follow = false }))
