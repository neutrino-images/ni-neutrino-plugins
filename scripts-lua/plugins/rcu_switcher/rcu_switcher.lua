--[[
	RCU Switcher Plugin lua v0.9
	Based on Switch RC by BPanther, 02-Sep-2019
	Mod by TangoCash, 28-Nov-2019
	
	Copyright 2019 - ported to Lua by GetAway, 01-Dec-2019, Icon from Bazi98

	License: GPL

	This program is free software; you can redistribute it and/or
	modify it under the terms of the GNU General Public
	License as published by the Free Software Foundation; either
	version 2 of the License, or (at your option) any later version.

	This program is distributed in the hope that it will be useful,
	but WITHOUT ANY WARRANTY; without even the implied warranty of
	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
	General Public License for more details.

	You should have received a copy of the GNU General Public
	License along with this program; if not, write to the
	Free Software Foundation, Inc., 51 Franklin St, Fifth Floor,
	Boston, MA  02110-1301, USA.
]]

local posix = require "posix"

ret = nil -- global return value
function key_home(a)
	ret = MENU_RETURN["EXIT"]
	return ret
end

function key_setup(a)
	ret = MENU_RETURN["EXIT_ALL"]
	return ret
end

function exists(file)
	return fh:exist(file, "f")
end

function isdir(fn)
    return (posix.stat(fn, "type") == 'directory')
end

function send_code(code)
	if os.execute("echo " .. code .. " > " .. procfile) == true then
	    return true
	else
		return false
	end
end

function proc_get(procfile)
	fp = io.open(procfile, "r")
	s = fp:read("*a")
	code = string.gsub(s, "\n", "")
	fp:close()
	return code
end

function write_config(code)
	local fp = io.open(rc_config, 'w')
	print("Schreibe Code: ", code)
	fp:write(code)
	fp:close()
end

function get_config()
	fp = io.open(rc_config, "r")
	s = fp:read("*a")
	fp:close()
	s = string.gsub(s, "\n", "")
	return s
end

function sleep(n)
	os.execute("sleep " .. tonumber(n))
end

function buildSortLookup( contentTab, sortKey )
    local lookup = {}
    for k, _ in pairs(contentTab) do
        lookup[#lookup+1] = k
    end
 
    table.sort( lookup, function(a, b ) return contentTab[a][sortKey] < contentTab[b][sortKey] end )
    return lookup
end

function rc_select_menu(code)
	rc_code, index = 0, 1
	found = false

	m = menu.new{name="Wähle eine Fernbedienung", icon=rcu}
	m:addKey{directkey=RC["home"], id="home", action="key_home"}
	m:addKey{directkey=RC["setup"], id="setup", action="key_setup"}
	m:addItem{type="separator"}

	sortByName = buildSortLookup( rc_list, "name" )
	local sortLookup = sortByName

	for i = 1,#sortLookup do
	    local entry = rc_list[sortLookup[i]]
		m:addItem{type="forwarder", action="set_rc", id=entry.code, name=entry.name}
		if entry.code == tonumber(code) then
			found = true
		end
		if found == false then
			index = index + 1
		end
	end
	if useFeature == true then
		m:setSelected{preselected=index}
	end
	m:exec()

	-- Menü verlassen
	if ret == MENU_RETURN["EXIT"] then
		return code
	elseif tonumber(rc_code) ~= 0 then
		return rc_code
	end
end

-- Setze Code der ausgewählten RC
function set_rc(_id)
	rc_code = tonumber(_id);
	return MENU_RETURN["EXIT_ALL"];
end

-- 
function checkCode(oldcode, newcode)

	if tonumber(newcode) ~= tonumber(oldcode) then
		isSend = send_code(newcode)
		if isSend == true then
			res = messagebox.exec {
				title = "Fernbedienung umschalten",
				icon = rcu,
				text = "Funktioniert die gewählte Fernbedienung?",
				timeout = 15,
				buttons={ "yes", "no" }
			}
		else
			local hint = hintbox.new { title = "Fernbedienung umschalten", icon = "error", text = "Fehler beim Senden des Codes" };
			hint:paint();
			sleep(3)
		end

		if res == "yes" then
			write_config(newcode)
		else
			print("set old code: ", oldcode)
			send_code(oldcode)
			local h = hintbox.new { title = "Fernbedienung umschalten", icon = "info", text = "Originale Fernbedienung wiederhergestellt." };
			h:paint();
			sleep(3)
		end
	end
end

-- decode base 64-- function from http://lua-users.org/wiki/BaseSixtyFour
-- character table string
local b='ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/'

function dec(data)
	data = string.gsub(data, '[^'..b..'=]', '')
	return (data:gsub('.', function(x)
	if (x == '=') then return '' end
	local r,f='',(b:find(x)-1)
	for i=6,1,-1 do r=r..(f%2^i-f%2^(i-1)>0 and '1' or '0') end
	return r;
	end):gsub('%d%d%d?%d?%d?%d?%d?%d?', function(x)
	if (#x ~= 8) then return '' end
	local c=0
	for i=1,8 do c=c+(x:sub(i,i)=='1' and 2^(8-i) or 0) end
	return string.char(c)
	end))
end

function decodeImage(b64Image)
	local imgTyp = b64Image:match("data:image/(.-);base64,")
	local repData = "data:image/" .. imgTyp .. ";base64,"
	local b64Data = string.gsub(b64Image, repData, "");

	local tmpImg = os.tmpname()
	local retImg = tmpImg .. "." .. imgTyp

	local f = io.open(retImg, "w+")
	f:write(dec(b64Data))
	f:close()
	os.remove(tmpImg)

	return retImg
end

function init()
	n = neutrino()
	fh = filehelpers.new()
	procfile      = "/proc/stb/ir/rc/type"
	tuxbox_config = "/var/tuxbox/config"
	neutrino_conf = configfile.new()
	neutrino_conf:loadConfig(tuxbox_config .. "/neutrino.conf")
	rcu = decodeImage("data:image/png;base64,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")

	local req_major = 1
	local req_minor = 84
	if ((APIVERSION.MAJOR > req_major) or (APIVERSION.MAJOR == req_major and APIVERSION.MINOR >= req_minor)) then
		useFeature = true
	end
	if isdir("/var/etc") == true then
		rc_config = "/var/etc/rccode"
	else
		rc_config = "/etc/rccode"
	end

	rc_list = {
		[4]  = {code = 4,  name = "Dreambox"         			},
		[5]  = {code = 5,  name = "ET 9000"           			},
		[7]  = {code = 7,  name = "ET 5000 / ET 6000" 			},
		[8]  = {code = 8,  name = "VU+ (Code 0001)"   			},
		[9]  = {code = 9,  name = "ET 6500 / 8000 / 9500 / 10000"},
		[11] = {code = 11, name = "ET 9200"        				},
		[13] = {code = 13, name = "ET 4000"        				},
		[16] = {code = 16, name = "ET 7000 / 7500 / 8500 / HD51" },
		[21] = {code = 21, name = "Zgemma H7"      				},
		[23] = {code = 23, name = "Bre2ze 4K"      				}
	}
end

function main()
	if not exists(rc_config) then
		code = proc_get(procfile)
		write_config(code)
	else
		code = get_config()
	end

	res = messagebox.exec {
		title = "Fernbedienung umschalten",
		icon = rcu,
		text = "Definieren Sie in der folgenden Auswahl die Fernbedienung\nwelche Sie verwendet möchten.\n\nDie Bestätigung erfolgt mit der Ausgewählten!",
		timeout = 0,
		buttons={ "ok" }
	}
	if res == "ok" then
		newcode = rc_select_menu(code)
		checkCode(code, newcode)
	end
end

init()
main()
os.execute("rm /tmp/lua*.png")
