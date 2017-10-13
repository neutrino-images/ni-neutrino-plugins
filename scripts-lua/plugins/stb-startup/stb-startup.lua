-- Plugin to change the startup partition
-- (c) Markus Volk, Sven Hoefer
-- distributed under BSD-2-Clause License

-- TODO: find current startup partition

caption = "STB-StartUp"
version = 0.03

n = neutrino()
fh = filehelpers.new()

locale = {}
locale["deutsch"] = {
	choose_partition = "Startpartition auswählen",
	start_partition = "Die gewählte Partition starten?"
}
locale["english"] = {
	choose_partition = "Choose start partition",
	start_partition = "Start the chosen partition?"
}

neutrino_conf = configfile.new()
neutrino_conf:loadConfig("/var/tuxbox/config/neutrino.conf")
lang = neutrino_conf:getString("language", "english")
if locale[lang] == nil then
	lang = "english"
end
timing_menu = neutrino_conf:getString("timing.menu", "0")

chooser_dx = n:scale2Res(500) 
chooser_dy = n:scale2Res(120)
chooser_x = SCREEN.OFF_X + (((SCREEN.END_X - SCREEN.OFF_X) - chooser_dx) / 2)
chooser_y = SCREEN.OFF_Y + (((SCREEN.END_Y - SCREEN.OFF_Y) - chooser_dy) / 2)

chooser = cwindow.new {
	x = chooser_x,
	y = chooser_y,
	dx = chooser_dx,
	dy = chooser_dy,
	title = caption .. " v" .. version,
	icon = "settings",
	has_shadow = true,
	btnRed = "Partition 1",
	btnGreen = "Partition 2",
	btnYellow = "Partition 3",
	btnBlue = "Partition 4"
}
chooser_text = ctext.new {
	parent = chooser,
	x = OFFSET.INNER_MID,
	y = OFFSET.INNER_SMALL,
	dx = chooser_dx - 2*OFFSET.INNER_MID,
	dy = chooser_dy - chooser:headerHeight() - chooser:footerHeight() - 2*OFFSET.INNER_SMALL,
	text = locale[lang].choose_partition,
	font_text = FONT.MENU,
	mode = "ALIGN_CENTER"
}
chooser:paint()

i = 0
d = 500 -- ms
t = (timing_menu * 1000) / d
if t == 0 then
	t = -1 -- no timeout
end

colorkey = nil
repeat
	i = i + 1
	msg, data = n:GetInput(d)
	if (msg == RC['red']) then
		fh:cp("/boot/STARTUP_1", "/boot/STARTUP", "f")
		colorkey = true
	elseif (msg == RC['green']) then
		fh:cp("/boot/STARTUP_2", "/boot/STARTUP", "f")
		colorkey = true
	elseif (msg == RC['yellow']) then
		fh:cp("/boot/STARTUP_3", "/boot/STARTUP", "f")
		colorkey = true
	elseif (msg == RC['blue']) then
		fh:cp("/boot/STARTUP_4", "/boot/STARTUP", "f")
		colorkey = true
	end
until msg == RC['home'] or colorkey or i == t

chooser:hide()

if colorkey then
	res = messagebox.exec {
		title = caption .. " v" .. version,
		icon = "settings",
		text = locale[lang].start_partition,
		timeout = 0,
		buttons={ "yes", "no" }
	}
	if res == "yes" then
		os.execute("reboot")
	end
end
