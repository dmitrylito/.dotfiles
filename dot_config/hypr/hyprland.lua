-- Learn how to configure Hyprland: https://wiki.hypr.land/Configuring/Start/

-- Omarchy's bootstrap keeps path setup out of this user config.
dofile((os.getenv("OMARCHY_PATH") or "/usr/share/omarchy") .. "/default/hypr/bootstrap.lua")

-- Load Omarchy defaults.
require("default.hypr.omarchy")

-- Personal overrides, loaded after Omarchy's defaults.
-- monitors.lua/workspaces.lua are nwg-displays output, per-device and chezmoi-ignored.
local require_optional = require("default.hypr.require_optional")
require_optional.module("hypr.monitors")
require_optional.module("hypr.workspaces")
require("hypr.input")
require("hypr.bindings")
require("hypr.looknfeel")
require("hypr.autostart")
require("hypr.voxtype_submap")

-- Give any monitor without a per-device rule its preferred mode automatically.
hl.monitor({ output = "", mode = "preferred", position = "auto", scale = 1 })

-- The LG dual-mode panel switches between 4K@144 and 1080p@480 in its own OSD;
-- Hyprland only sees the mode change, so scale and position have to follow it.
-- Positions keep the panel's physical footprint: same centre, same bottom edge,
-- so the pointer still crosses into the Gigabyte below it in either mode.
local lg_dual_mode_description = "LG Electronics LG ULTRAGEAR+ 510RMXX5G570"
local lg_dual_mode_width = nil

-- Keyed by the width Hyprland reports, which is the only signal the OSD switch
-- gives. The 4K side is pinned rather than "preferred" because preferred is
-- 3840x2160@240.08 here; the 1080p EDID is only visible once the panel is in it.
local lg_dual_mode_layout = {
  [3840] = { mode = "3840x2160@144.05", scale = 1.3333334, position = "0x0" },
  [1920] = { mode = "preferred", scale = 1, position = "480x540" },
}

local function configure_lg_dual_mode()
  for _, monitor in ipairs(hl.get_monitors()) do
    if monitor.description == lg_dual_mode_description then
      local layout = lg_dual_mode_layout[monitor.width]
      if not layout or monitor.width == lg_dual_mode_width then
        return
      end

      lg_dual_mode_width = monitor.width
      hl.monitor({
        output = "desc:" .. lg_dual_mode_description,
        mode = layout.mode,
        position = layout.position,
        scale = layout.scale,
        bitdepth = 10,
      })
      return
    end
  end

  lg_dual_mode_width = nil
end

configure_lg_dual_mode()
hl.on("monitor.added", configure_lg_dual_mode)
hl.on("monitor.layout_changed", configure_lg_dual_mode)

-- Toggle config flags dynamically.
require("default.hypr.toggles")

-- Float Chromium extension windows and keep PiP floating + pinned.
o.window({ class = "^(chromium)$", title = "^(Picture-in-Picture)$" }, { float = true, pin = true })
o.window({ class = "^(chromium)$", title = "^(Extension:.*)$" }, { float = true })
-- Not silent: a cold launch has to reveal the workspace itself, since the binding
-- cannot toggle it before the window maps. Nothing autostarts spotify.
o.window({ class = "^(spotify)$" }, { workspace = "special:spotify" })
o.window({ class = "^(steam)$", title = "^(Counter-Strike 2)$" }, { workspace = "1 silent" })
o.window({ class = "^(cs2)$" }, { fullscreen = true, immediate = true, workspace = "1 silent" })
o.window({ class = "^(gamescope)$" }, { workspace = "1 silent" })

-- Herdr runs inside Ghostty and titles its host window as "hostname: workspace".
-- Keep agent/session updates from activating it over whatever is being used.
o.window({ class = "^(com\\.mitchellh\\.ghostty)$", title = "^.+: .+$" }, { focus_on_activate = false })
