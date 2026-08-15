-- Voxtype compositor integration, ported from conf.d/voxtype-submap.conf
-- (voxtype 0.7.5 only generates hyprlang; regenerate by hand if voxtype's
-- template changes). Voxtype enters these submaps itself via
-- `hyprctl dispatch submap`.
--
-- Do not bind Escape in voxtype_suppress: it makes wtype drop the first
-- character. See https://github.com/hyprwm/Hyprland/issues/3165

hl.define_submap("voxtype_recording", function()
  hl.bind("F12", hl.dsp.exec_cmd("voxtype record cancel"))
  hl.bind("F12", hl.dsp.exec_cmd("hyprctl dispatch submap reset"))
end)

hl.define_submap("voxtype_suppress", function()
  local modifier_keys = {
    "SUPER_L", "SUPER_R",
    "Control_L", "Control_R",
    "Alt_L", "Alt_R",
    "Shift_L", "Shift_R",
  }
  for _, key in ipairs(modifier_keys) do
    hl.bind(key, hl.dsp.exec_cmd("true"))
  end
  -- Emergency escape if voxtype crashes.
  hl.bind("F12", hl.dsp.exec_cmd("hyprctl dispatch submap reset"))
end)
