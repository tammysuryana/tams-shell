-- tams-shell untuk Hyprland (config format Lua).
-- Dipasang install.sh ke ~/.config/hypr/tams-shell.lua dan dimuat dari hyprland.lua dengan:
--   require("tams-shell")

hl.on("hyprland.start", function()
    hl.exec_cmd("qs -c tams")
end)

hl.bind("SUPER + Space", hl.dsp.global("tams:launcher"), { description = "tams-shell: launcher" })
-- Super ditekan sendiri = launcher. Tombol lain yang ditekan selama Super ditahan membatalkannya
-- (catchall hanya boleh di submap di Hyprland 0.57, jadi dibuat satu bind per tombol).
hl.bind("SUPER + SUPER_L", hl.dsp.global("tams:launcherTap"), { description = "tams-shell: launcher" })
hl.bind("SUPER + SUPER_R", hl.dsp.global("tams:launcherTap"))
do
    local cancel = hl.dsp.global("tams:launcherTapCancel")
    local keys = {
        "Left", "Right", "Up", "Down", "Tab", "Return", "Space", "BackSpace", "Delete", "Escape",
        "Home", "End", "Prior", "Next", "Insert", "Print",
        "Minus", "Equal", "BracketLeft", "BracketRight", "Backslash", "Semicolon", "Apostrophe",
        "Grave", "Comma", "Period", "Slash",
    }
    for i = 0, 9 do table.insert(keys, tostring(i)) end
    for c = string.byte("A"), string.byte("Z") do table.insert(keys, string.char(c)) end
    for i = 1, 12 do table.insert(keys, "F" .. i) end
    for _, mods in ipairs({ "SUPER", "SUPER + SHIFT", "SUPER + ALT", "SUPER + CTRL", "SUPER + SHIFT + ALT", "SUPER + CTRL + SHIFT" }) do
        for _, key in ipairs(keys) do hl.bind(mods .. " + " .. key, cancel, { non_consuming = true }) end
    end
    for _, btn in ipairs({ "mouse:272", "mouse:273", "mouse:274", "mouse:275", "mouse_up", "mouse_down" }) do
        hl.bind("SUPER + " .. btn, cancel, { non_consuming = true })
    end
end
hl.bind("SUPER + A", hl.dsp.global("tams:dashboard"), { description = "tams-shell: dashboard" })
hl.bind("SUPER + I", hl.dsp.global("tams:settings"), { description = "tams-shell: pengaturan" })
hl.bind("SUPER + Escape", hl.dsp.global("tams:settings"), { description = "tams-shell: pengaturan" })
hl.bind("SUPER + slash", hl.dsp.global("tams:keys"), { description = "tams-shell: keys" })
hl.bind("SUPER + SHIFT + S", hl.dsp.global("tams:screenshotArea"), { description = "tams-shell: screenshotArea" })
hl.bind("Print", hl.dsp.global("tams:screenshotScreen"), { description = "tams-shell: screenshotScreen" })
hl.bind("SHIFT + Print", hl.dsp.global("tams:screenshotAll"), { description = "tams-shell: screenshotAll" })

-- Jendela milik tams-shell (mis. pemilih wallpaper) melayang di tengah, tidak ikut ditata
hl.window_rule({
    name   = "tams-shell-dialog",
    match  = { class = "org.quickshell" },
    float  = true,
    size   = "70% 80%",   -- relatif terhadap layar (papan 1920x540 maupun laptop)
    center = true,
})
