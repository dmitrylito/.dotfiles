-- hyprsunset is not autostarted: it only ever ran to cancel its own default tint
-- (see the identity profile in hyprsunset.conf). Nothing tints the screen unless
-- nightlight is toggled, which starts hyprsunset on demand.
o.launch_on_start("solaar --window=hide")
o.exec_on_start("/usr/lib/kdeconnectd")
o.exec_on_start("/usr/bin/kdeconnect-indicator")
o.exec_on_start("hyprctl dispatch workspace 1")
