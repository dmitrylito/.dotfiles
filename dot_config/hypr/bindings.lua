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
o.bind("SUPER + semicolon", "Terminal", { launch = 'xdg-terminal-exec --dir="$(omarchy-cmd-terminal-cwd)"' })
-- server keybindings: with the default (local) the client owns prefix mode, so the
-- server-side [[keys.command]] popups (prefix+g lazygit, prefix+u urls) never fire
o.bind("SUPER + CTRL + semicolon", "Herdr remote (choose SSH target)", { launch = "xdg-terminal-exec ~/.local/bin/herdr-remote-picker" })
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
--
-- Pop the focused window out of the dwindle tree into a centered 16:10 float,
-- and put it back exactly where it was.  Putting it back relies on three
-- compositor behaviours that are easy to get wrong:
--   * dwindle re-tiles a window by splitting the ACTIVE window's node, so the
--     anchor must be focused first and the untoggle aimed at the popped window
--     by address -- otherwise the window lands in an arbitrary slot.
--   * swapping only permutes windows between existing rectangles; it can never
--     restore a split ratio.  Sizes have to be replayed with resize.
--   * hl.dsp.window.resize ignores a `window` field and always resizes the
--     ACTIVE window, hence the focus-then-resize pass below.
local popout_state = {}
local popout_dir = (os.getenv("XDG_RUNTIME_DIR") or "/tmp") .. "/hypr-popout"
os.execute("mkdir -p " .. popout_dir)

local function popout_file(address)
  return popout_dir .. "/" .. address:gsub("[^%w]", "_")
end

local function popout_coord(vector, key)
  if vector == nil then return 0 end
  return tonumber(vector[key]) or 0
end

local function popout_save(address, state)
  local file = io.open(popout_file(address), "w")
  if file == nil then return end
  file:write(state.workspace, " ", state.anchor, " ", state.side, "\n")
  for _, item in ipairs(state.windows) do
    file:write(item.address, " ", item.x, " ", item.y, " ",
      item.width, " ", item.height, "\n")
  end
  file:close()
end

local function popout_load(address)
  local file = io.open(popout_file(address), "r")
  if file == nil then return nil end
  local workspace, anchor, side = (file:read("*l") or ""):match("^(%S+) (%S+) (%S+)$")
  local windows = {}
  for line in file:lines() do
    local item, x, y, width, height = line:match("^(%S+) (%S+) (%S+) (%S+) (%S+)$")
    if item ~= nil then
      windows[#windows + 1] = { address = item, x = tonumber(x), y = tonumber(y),
        width = tonumber(width), height = tonumber(height) }
    end
  end
  file:close()
  if workspace == nil or #windows == 0 then return nil end
  return { workspace = tonumber(workspace), anchor = anchor, side = side, windows = windows }
end

local function popout_clear(address)
  popout_state[address] = nil
  os.remove(popout_file(address))
end

-- The tiled window sharing the longest edge with `window`; `side` is where the
-- popped window sits relative to it, which is what a corrective swap needs.
local function popout_anchor(window, windows)
  local px = popout_coord(window.at, "x")
  local py = popout_coord(window.at, "y")
  local pr = px + popout_coord(window.size, "x")
  local pb = py + popout_coord(window.size, "y")
  local best = nil

  for _, candidate in ipairs(windows) do
    if not candidate.floating and candidate.address ~= window.address then
      local nx = popout_coord(candidate.at, "x")
      local ny = popout_coord(candidate.at, "y")
      local nr = nx + popout_coord(candidate.size, "x")
      local nb = ny + popout_coord(candidate.size, "y")
      local vertical = math.min(pb, nb) - math.max(py, ny)
      local horizontal = math.min(pr, nr) - math.max(px, nx)
      local choices = {
        { side = "l", gap = math.abs(nx - pr), overlap = vertical },
        { side = "r", gap = math.abs(px - nr), overlap = vertical },
        { side = "u", gap = math.abs(ny - pb), overlap = horizontal },
        { side = "d", gap = math.abs(py - nb), overlap = horizontal },
      }
      for _, choice in ipairs(choices) do
        local better = best == nil or choice.overlap > best.overlap
          or (choice.overlap == best.overlap and choice.gap < best.gap)
        if choice.overlap > 0 and choice.gap <= 100 and better then
          best = { address = candidate.address, side = choice.side,
            overlap = choice.overlap, gap = choice.gap }
        end
      end
    end
  end

  return best
end

local function popout_float(window)
  local monitor = hl.get_active_monitor()
  if monitor == nil then return end

  local windows = hl.get_workspace_windows(window.workspace.id)
  local snapshot = {}
  for _, candidate in ipairs(windows) do
    if not candidate.floating then
      snapshot[#snapshot + 1] = { address = candidate.address,
        x = popout_coord(candidate.at, "x"), y = popout_coord(candidate.at, "y"),
        width = popout_coord(candidate.size, "x"),
        height = popout_coord(candidate.size, "y") }
    end
  end
  if #snapshot == 0 then return end

  local anchor = popout_anchor(window, windows)
  local state = {
    workspace = window.workspace.id,
    anchor = anchor and anchor.address or "-",
    side = anchor and anchor.side or "-",
    windows = snapshot,
  }
  popout_state[window.address] = state
  popout_save(window.address, state)

  local width = monitor.width / monitor.scale
  local height = monitor.height / monitor.scale
  local pop_width = width * 0.80
  local pop_height = pop_width / 1.6
  if pop_height > height * 0.82 then
    pop_height = height * 0.82
    pop_width = pop_height * 1.6
  end

  hl.dispatch(hl.dsp.window.float({ action = "toggle" }))
  hl.dispatch(hl.dsp.window.resize({
    x = math.floor(pop_width),
    y = math.floor(pop_height),
    relative = false,
  }))
  hl.dispatch(hl.dsp.window.center())
end

local function popout_restore(window, state)
  local address = window.address
  local anchor = state.anchor ~= "-" and hl.get_window("address:" .. state.anchor) or nil
  if anchor ~= nil and not anchor.floating then
    hl.dispatch(hl.dsp.focus({ window = "address:" .. state.anchor }))
  end
  hl.dispatch(hl.dsp.window.float({ action = "toggle", window = "address:" .. address }))

  local reinserted = hl.get_window("address:" .. address)
  if reinserted == nil then
    popout_clear(address)
    return
  end
  local workspace = reinserted.workspace.id

  -- force_split=2 always drops the re-inserted window right/bottom of the
  -- anchor; one swap puts it back on the side it came from.
  local neighbor = anchor ~= nil and hl.get_window("address:" .. state.anchor) or nil
  if neighbor ~= nil and not neighbor.floating then
    local px = popout_coord(reinserted.at, "x")
    local py = popout_coord(reinserted.at, "y")
    local nx = popout_coord(neighbor.at, "x")
    local ny = popout_coord(neighbor.at, "y")
    if (state.side == "l" and px > nx) or (state.side == "r" and px < nx)
      or (state.side == "u" and py > ny) or (state.side == "d" and py < ny) then
      hl.dispatch(hl.dsp.focus({ window = "address:" .. address }))
      hl.dispatch(hl.dsp.window.swap({ direction = state.side }))
    end
  end

  -- Replaying every recorded size walks the ancestor split ratios back; each
  -- resize perturbs its siblings, so it takes a few passes to settle.
  for _ = 1, 4 do
    local current = {}
    for _, candidate in ipairs(hl.get_workspace_windows(workspace)) do
      current[candidate.address] = candidate
    end

    local worst = 0
    for _, target in ipairs(state.windows) do
      local candidate = current[target.address]
      if candidate ~= nil and not candidate.floating then
        local dw = target.width - popout_coord(candidate.size, "x")
        local dh = target.height - popout_coord(candidate.size, "y")
        worst = math.max(worst, math.abs(dw), math.abs(dh))
        if math.abs(dw) > 2 or math.abs(dh) > 2 then
          hl.dispatch(hl.dsp.focus({ window = "address:" .. target.address }))
          hl.dispatch(hl.dsp.window.resize({
            x = target.width,
            y = target.height,
            relative = false,
          }))
        end
      end
    end
    if worst <= 2 then break end
  end

  hl.dispatch(hl.dsp.focus({ window = "address:" .. address }))
  popout_clear(address)
end

local function popout_toggle()
  local window = hl.get_active_window()
  if window == nil then return end

  if not window.floating then
    popout_float(window)
    return
  end

  local state = popout_state[window.address] or popout_load(window.address)
  if state == nil then
    hl.dispatch(hl.dsp.window.float({ action = "toggle" }))
    return
  end
  popout_restore(window, state)
end

hl.unbind("SUPER + U")
hl.bind("SUPER + U", popout_toggle, { description = "Toggle window pop-out (centered 16:10 float)" })
hl.unbind("SUPER + SHIFT + U")
hl.bind(
  "SUPER + SHIFT + U",
  hl.dsp.exec_cmd(os.getenv("HOME") .. "/.config/hypr/scripts/toggle-popout.sh"),
  { description = "Toggle window pop-out (Bash fallback)" }
)

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
