-- hyprsunset is not started here: v4 runs it via the hyprsunset.service user unit.
o.launch_on_start("solaar --window=hide")
o.exec_on_start("/usr/lib/kdeconnectd")
o.exec_on_start("/usr/bin/kdeconnect-indicator")
o.exec_on_start("hyprctl dispatch workspace 1")
