-- tams-shell untuk Hyprland (config format Lua).
-- Dipasang install.sh ke ~/.config/hypr/tams-shell.lua dan dimuat dari hyprland.lua dengan:
--   require("tams-shell")

hl.on("hyprland.start", function()
    hl.exec_cmd("qs -c tams")
end)

hl.bind("SUPER + Space", hl.dsp.global("tams:launcher"), { description = "tams-shell: launcher" })
hl.bind("SUPER + A", hl.dsp.global("tams:dashboard"), { description = "tams-shell: dashboard" })
hl.bind("SUPER + I", hl.dsp.global("tams:settings"), { description = "tams-shell: pengaturan" })
hl.bind("SUPER + Escape", hl.dsp.global("tams:settings"), { description = "tams-shell: pengaturan" })
