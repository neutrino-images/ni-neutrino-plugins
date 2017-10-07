--[[
	favorites2bin - Put the favorites bouquet into an installable package

	Copyright (C) 2015 Sven Hoefer <svenhoefer@svenhoefer.com>
	License: WTFPLv2
]]

local n = neutrino()

favs = "/var/tuxbox/config/zapit/ubouquets.xml"
dest = "/media/sda1"

locale = {}
locale["deutsch"] = {
	caption = "Favoriten sichern",
	directory = "Verzeichnis",
	directory_hint = "Verzeichnis wählen, in dem das bin-Paket erstellt werden soll",
	create = "Erstelle bin-Paket",
	create_hint = "Packt das Favoriten-Bouquet in ein installierbares bin-Paket",
	create_success ="bin-Paket erfolgreich erstellt.",
	create_error = "Fehler! bin-Paket nicht erstellt.",
}
locale["english"] = {
	caption = "Save favorites",
	directory = "Directory",
	directory_hint = "Choose directory where the bin-package should be created",
	create = "Create bin-package",
	create_hint = "Put the favorites bouquet into an installable bin-package",
	create_success ="bin-package successful created.",
	create_error = "Error! bin-package not created.",
}

-- ----------------------------------------------------------------------------

function key_home(a)
	return MENU_RETURN.EXIT
end

function key_setup(a)
	return MENU_RETURN.EXIT_ALL
end

function file_exists(name)
	local f = io.open(name, "r")
	if f ~= nil then
		io.close(f)
		return true
	else
		return false
	end
end

if APIVERSION ~=nil and (APIVERSION.MAJOR > 1 or ( APIVERSION.MAJOR == 1 and APIVERSION.MINOR > 24 )) then
	function set_dest(id,value)
		dest=value
	end

else
	function set_dest(value)
		dest=value
	end
end

function create(file)
	local sh, dummy = string.gsub(debug.getinfo(1).short_src, "lua", "sh")
	os.execute(sh .. " " .. dest .. " " .. file)

	if file_exists(dest .. "/" .. file) then
		text=locale[lang].create_success
	else
		text=locale[lang].create_error
	end

	local h = hintbox.new{caption=locale[lang].caption, text=text}
	h:paint()
	local i = 0
	repeat
		i = i + 1
		msg, data = n:GetInput(500)
	until msg == RC.ok or msg == RC.home or i == 4
	h:hide()

	return MENU_RETURN.EXIT_ALL
end

-- ----------------------------------------------------------------------------

local neutrino_conf = configfile.new()
neutrino_conf:loadConfig("/var/tuxbox/config/neutrino.conf")
lang = neutrino_conf:getString("language", "english")
if locale[lang] == nil then
	lang = "english"
end

local m = menu.new{name=locale[lang].caption, icon="settings"}
m:addKey{directkey=RC["home"], id="home", action="key_home"}
m:addKey{directkey=RC["setup"], id="setup", action="key_setup"}
m:addItem{type="separator"}
m:addItem{type="back"}
m:addItem{type="separatorline"}
m:addItem{
	type="filebrowser",
	dir_mode="1",
	name=locale[lang].directory,
	action="set_dest",
	enabled=file_exists(favs),
	value=dest,
	icon="rot",
	directkey=RC["red"],
	hint_icon="hint_service",
	hint=locale[lang].directory_hint
}
m:addItem{
	type="forwarder",
	name=locale[lang].create,
	action="create",
	enabled=file_exists(favs),
	id="favorites.bin",
	icon="gruen",
	directkey=RC["green"],
	hint_icon="hint_service",
	hint=locale[lang].create_hint
}
m:exec()
