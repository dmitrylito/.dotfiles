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
-- SUPER+U pops the focused window out into a centered 16:10 float and puts it
-- back.  How much can be put back is a property of dwindle, measured on this
-- box (Hyprland 0.56.2, force_split=2, preserve_split=true):
--   * Floating a tiled window DELETES its node and its sibling expands into the
--     parent rect.  Re-tiling only ever splits a single leaf, so the tree is
--     recoverable exactly when that sibling was ONE window.  When the sibling is
--     a subtree -- common past ~4 windows -- no sequence of swaps or resizes
--     rebuilds it, and forcing the recorded sizes actively mangles the layout.
--     So the exact path is taken only when the sibling is a leaf.
--   * swap only permutes windows between existing rectangles -- it can never
--     restore a split ratio.  Only resize moves a divider.
--   * hl.dsp.window.resize ignores a `window` field (it always resizes the
--     ACTIVE window) and is only correct on the LEFT/TOP child of a split; on
--     the right/bottom child it moves the divider the wrong way.
local popout_state = {}
local popout_dir = (os.getenv("XDG_RUNTIME_DIR") or "/tmp") .. "/hypr-popout"
os.execute("mkdir -p " .. popout_dir)

local EDGE_TOLERANCE = 8
local GAP_TOLERANCE = 60

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
  file:write(state.workspace, " ", state.tiled, " ", state.sibling, " ", state.side,
    " ", state.left_child, " ", state.left_width, " ", state.top_height, "\n")
  file:close()
end

local function popout_load(address)
  local file = io.open(popout_file(address), "r")
  if file == nil then return nil end
  local line = file:read("*l")
  file:close()
  local workspace, tiled, sibling, side, left_child, left_width, top_height =
    (line or ""):match("^(%S+) (%S+) (%S+) (%S+) (%S+) (%S+) (%S+)$")
  if workspace == nil then return nil end
  return { workspace = tonumber(workspace), tiled = tonumber(tiled), sibling = sibling,
    side = side, left_child = left_child, left_width = tonumber(left_width),
    top_height = tonumber(top_height) }
end

local function popout_clear(address)
  popout_state[address] = nil
  os.remove(popout_file(address))
end

local function popout_rect(window)
  local x, y = popout_coord(window.at, "x"), popout_coord(window.at, "y")
  local w, h = popout_coord(window.size, "x"), popout_coord(window.size, "y")
  return { x = x, y = y, w = w, h = h, r = x + w, b = y + h }
end

-- dwindle's parent of `window` is the smallest rectangle formed by the window
-- plus a complete adjacent region.  Returns that region's members, so a caller
-- can tell a leaf sibling (rebuildable) from a subtree (not rebuildable).
local function popout_parent(window, windows)
  local me = popout_rect(window)
  local others = {}
  for _, candidate in ipairs(windows) do
    if not candidate.floating and candidate.address ~= window.address then
      others[#others + 1] = { address = candidate.address, rect = popout_rect(candidate) }
    end
  end

  local probes = {
    { side = "l", along = "x", pick = function(r) return r.x >= me.r - EDGE_TOLERANCE end },
    { side = "r", along = "x", pick = function(r) return r.r <= me.x + EDGE_TOLERANCE end },
    { side = "u", along = "y", pick = function(r) return r.y >= me.b - EDGE_TOLERANCE end },
    { side = "d", along = "y", pick = function(r) return r.b <= me.y + EDGE_TOLERANCE end },
  }

  local best = nil
  for _, probe in ipairs(probes) do
    local members, box = {}, nil
    for _, other in ipairs(others) do
      local r = other.rect
      local within
      if probe.along == "x" then
        within = r.y >= me.y - EDGE_TOLERANCE and r.b <= me.b + EDGE_TOLERANCE
      else
        within = r.x >= me.x - EDGE_TOLERANCE and r.r <= me.r + EDGE_TOLERANCE
      end
      if within and probe.pick(r) then
        members[#members + 1] = other
        if box == nil then
          box = { x = r.x, y = r.y, r = r.r, b = r.b }
        else
          box.x, box.y = math.min(box.x, r.x), math.min(box.y, r.y)
          box.r, box.b = math.max(box.r, r.r), math.max(box.b, r.b)
        end
      end
    end

    if box ~= nil then
      -- the region must span the window's full perpendicular extent and butt
      -- up against it, or it is not the sibling half of a single split
      local spans, touches
      if probe.along == "x" then
        spans = math.abs(box.y - me.y) <= EDGE_TOLERANCE and math.abs(box.b - me.b) <= EDGE_TOLERANCE
        touches = (probe.side == "l" and math.abs(box.x - me.r) <= GAP_TOLERANCE)
          or (probe.side == "r" and math.abs(me.x - box.r) <= GAP_TOLERANCE)
      else
        spans = math.abs(box.x - me.x) <= EDGE_TOLERANCE and math.abs(box.r - me.r) <= EDGE_TOLERANCE
        touches = (probe.side == "u" and math.abs(box.y - me.b) <= GAP_TOLERANCE)
          or (probe.side == "d" and math.abs(me.y - box.b) <= GAP_TOLERANCE)
      end

      if spans and touches then
        local parent = {
          x = math.min(me.x, box.x), y = math.min(me.y, box.y),
          r = math.max(me.r, box.r), b = math.max(me.b, box.b),
        }
        local clean = true
        for _, other in ipairs(others) do
          local inside = false
          for _, member in ipairs(members) do
            if member.address == other.address then inside = true break end
          end
          if not inside then
            local cx = other.rect.x + other.rect.w / 2
            local cy = other.rect.y + other.rect.h / 2
            if cx > parent.x and cx < parent.r and cy > parent.y and cy < parent.b then
              clean = false
              break
            end
          end
        end

        local area = (parent.r - parent.x) * (parent.b - parent.y)
        if clean and (best == nil or area < best.area) then
          best = { side = probe.side, members = members, box = box, area = area }
        end
      end
    end
  end

  if best == nil then return nil end

  local leaf = #best.members == 1
  local sibling = best.members[1]
  local left_child, left_width, top_height = "-", 0, 0
  if leaf then
    if best.side == "l" then left_child, left_width, top_height = window.address, me.w, me.h
    elseif best.side == "r" then left_child, left_width, top_height = sibling.address, sibling.rect.w, me.h
    elseif best.side == "u" then left_child, left_width, top_height = window.address, me.w, me.h
    else left_child, left_width, top_height = sibling.address, me.w, sibling.rect.h end
  end

  return { leaf = leaf, side = best.side, sibling = sibling.address,
    left_child = left_child, left_width = math.floor(left_width),
    top_height = math.floor(top_height) }
end

local function popout_float(window)
  local monitor = hl.get_active_monitor()
  if monitor == nil then return end

  local windows = hl.get_workspace_windows(window.workspace.id)
  local tiled = 0
  for _, candidate in ipairs(windows) do
    if not candidate.floating then tiled = tiled + 1 end
  end

  local parent = popout_parent(window, windows)
  local exact = parent ~= nil and parent.leaf
  local state = {
    workspace = window.workspace.id,
    tiled = tiled,
    sibling = exact and parent.sibling or "-",
    side = exact and parent.side or "-",
    left_child = exact and parent.left_child or "-",
    left_width = exact and parent.left_width or 0,
    top_height = exact and parent.top_height or 0,
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
  local sibling = state.sibling ~= "-" and hl.get_window("address:" .. state.sibling) or nil

  local tiled = 0
  for _, candidate in ipairs(hl.get_workspace_windows(window.workspace.id)) do
    if not candidate.floating then tiled = tiled + 1 end
  end

  -- No rebuildable slot (sibling was a subtree, has gone, or the tiled set
  -- changed).  Re-tile wherever dwindle wants: any swap or forced resize from
  -- here mangles the layout instead of restoring it.
  if sibling == nil or sibling.floating or tiled + 1 ~= state.tiled then
    hl.dispatch(hl.dsp.window.float({ action = "toggle" }))
    popout_clear(address)
    return
  end

  hl.dispatch(hl.dsp.focus({ window = "address:" .. state.sibling }))
  hl.dispatch(hl.dsp.window.float({ action = "toggle", window = "address:" .. address }))

  local me = hl.get_window("address:" .. address)
  local neighbor = hl.get_window("address:" .. state.sibling)
  if me ~= nil and neighbor ~= nil then
    local px, py = popout_coord(me.at, "x"), popout_coord(me.at, "y")
    local nx, ny = popout_coord(neighbor.at, "x"), popout_coord(neighbor.at, "y")
    -- force_split=2 always drops the re-inserted window right/bottom
    if (state.side == "l" and px > nx) or (state.side == "r" and px < nx)
      or (state.side == "u" and py > ny) or (state.side == "d" and py < ny) then
      hl.dispatch(hl.dsp.focus({ window = "address:" .. address }))
      hl.dispatch(hl.dsp.window.swap({ direction = state.side }))
    end
  end

  if state.left_child ~= "-" and state.left_width > 0 and state.top_height > 0 then
    hl.dispatch(hl.dsp.focus({ window = "address:" .. state.left_child }))
    hl.dispatch(hl.dsp.window.resize({
      x = state.left_width,
      y = state.top_height,
      relative = false,
    }))
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
