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

-- Jendela milik tams-shell (mis. pemilih wallpaper) melayang di tengah, tidak ikut ditata
hl.window_rule({
    name   = "tams-shell-dialog",
    match  = { class = "org.quickshell" },
    float  = true,
    size   = "900 600",
    center = true,
})
