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

-- Follow the LG dual-mode display's EDID, using scale 1 at 1080p and 1.25 at 4K.
local lg_dual_mode_description = "LG Electronics LG ULTRAGEAR+ 510RMXX5G570"
local lg_dual_mode_scale = nil

local function configure_lg_dual_mode()
  for _, monitor in ipairs(hl.get_monitors()) do
    if monitor.description == lg_dual_mode_description then
      local scale = monitor.width == 1920 and 1 or 1.25
      if scale == lg_dual_mode_scale then
        return
      end

      lg_dual_mode_scale = scale
      hl.monitor({
        output = "desc:" .. lg_dual_mode_description,
        mode = "preferred",
        position = "3440x1152",
        scale = scale,
        bitdepth = 10,
      })
      return
    end
  end

  lg_dual_mode_scale = nil
end

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
