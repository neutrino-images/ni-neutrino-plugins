--[[
	favorites2bin - Put the favorites bouquet into an installable package

	Copyright (C) 2015 Sven Hoefer <svenhoefer@svenhoefer.com>
	License: WTFPLv2
]]

local n = neutrino()

name = {}
desc = {}
favs = "/var/tuxbox/config/zapit/ubouquets.xml"
dest = "/media/sda1"

-- ----------------------------------------------------------------------------

function key_home(a)
	return MENU_RETURN.EXIT
end

function key_setup(a)
	return MENU_RETURN.EXIT_ALL
end

function read_cfg()
	local file, dummy = string.gsub(debug.getinfo(1).short_src, "lua", "cfg")
	local cfg = io.open(file, "r")
	if cfg then
		for line in cfg:lines() do
			local key, val = line:match("^([^=#]+)=([^\n]*)")
			if (key) then
				if key == "name" then
					name = val
				elseif key == "desc" then
					desc = val
				end
			end
		end
		cfg:close()
	else
		error("Error opening file '" .. cfg .. "'.")
	end
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

function set_dest(value)
	dest=value
end

function create(file)
	local sh, dummy = string.gsub(debug.getinfo(1).short_src, "lua", "sh")
	os.execute(sh .. " " .. dest .. " " .. file)

	if file_exists(dest .. "/" .. file) then
		text="bin-Paket erfolgreich erstellt."
	else
		text="Fehler! bin-Paket nicht erstellt."
	end

	local h = hintbox.new{caption=name, text=text}
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

read_cfg()

local m = menu.new{name=name, icon="settings"}
m:addKey{directkey=RC["home"], id="home", action="key_home"}
m:addKey{directkey=RC["setup"], id="setup", action="key_setup"}
m:addItem{type="separator"}
m:addItem{type="back"}
m:addItem{type="separatorline"}
m:addItem{
	type="filebrowser",
	dir_mode="1",
	name="Verzeichnis",
	action="set_dest",
	enabled=file_exists(favs),
	value=dest,
	icon="rot",
	directkey=RC["red"],
	hint_icon="hint_service",
	hint="Verzeichnis wählen, in dem das bin-Paket erstellt werden soll"
}
m:addItem{
	type="forwarder",
	name="Erstelle bin-Paket",
	action="create",
	enabled=file_exists(favs),
	id="favorites.bin",
	icon="gruen",
	directkey=RC["green"],
	hint_icon="hint_service",
	hint=desc
}
m:exec()
