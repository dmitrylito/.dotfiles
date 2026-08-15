-- Learn how to configure Hyprland: https://wiki.hypr.land/Configuring/Start/

-- Omarchy's bootstrap keeps path setup out of this user config.
dofile((os.getenv("OMARCHY_PATH") or "/usr/share/omarchy") .. "/default/hypr/bootstrap.lua")

-- Load Omarchy defaults.
require("default.hypr.omarchy")

-- Personal overrides, loaded after Omarchy's defaults.
require("hypr.monitors")
require("hypr.workspaces")
require("hypr.input")
require("hypr.bindings")
require("hypr.looknfeel")
require("hypr.autostart")
require("hypr.voxtype_submap")

-- Toggle config flags dynamically.
require("default.hypr.toggles")

-- Float Chromium extension windows and keep PiP floating + pinned.
o.window({ class = "^(chromium)$", title = "^(Picture-in-Picture)$" }, { float = true, pin = true })
o.window({ class = "^(chromium)$", title = "^(Extension:.*)$" }, { float = true })
o.window({ class = "^(cs2)$" }, { fullscreen = true, immediate = true, workspace = "1 silent" })
o.window({ class = "^(gamescope)$" }, { workspace = "1 silent" })

-- Herdr runs inside Ghostty and titles its host window as "hostname: workspace".
-- Keep agent/session updates from activating it over whatever is being used.
o.window({ class = "^(com\\.mitchellh\\.ghostty)$", title = "^.+: .+$" }, { focus_on_activate = false })
