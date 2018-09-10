-- The Tuxbox Copyright
--
-- Copyright 2018 The Tuxbox Project. All rights reserved.
--
-- Redistribution and use in source and binary forms, with or without modification, 
-- are permitted provided that the following conditions are met:
--
-- Redistributions of source code must retain the above copyright notice, this list
-- of conditions and the following disclaimer. Redistributions in binary form must
-- reproduce the above copyright notice, this list of conditions and the following
-- disclaimer in the documentation and/or other materials provided with the distribution.
--
-- THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS ``AS IS`` AND ANY EXPRESS OR IMPLIED
-- WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
-- AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
-- HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
-- EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
-- SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
-- HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
-- OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
-- SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
--
-- The views and conclusions contained in the software and documentation are those of the
-- authors and should not be interpreted as representing official policies, either expressed
-- or implied, of the Tuxbox Project.

caption = "STB-Image-Tools"

local posix = require "posix"
n = neutrino()
fh = filehelpers.new()

local g = {}
locale = {}

locale["deutsch"] = {
locale_image_management = "Image-Verwaltung",
locale_stb_flash = "Image flashen (online)",
locale_stb_local_flash = "Image flashen (lokal)",
locale_stb_backup = "Image Backup erstellen",
locale_stb_restore = "Image Backup wiederherstellen",
locale_stb_move = "Image Backup verschieben",
}

locale["english"] = {
locale_image_management = "Image-management",
locale_stb_flash = "Flash image (online)",
locale_stb_local_flash = "Flash image (local)",
locale_stb_backup = "Create an image backup",
locale_stb_restore = "Restore an image backup",
locale_stb_move = "Move an image backup",
}

function sleep (a) 
	local sec = tonumber(os.clock() + a); 
	while (os.clock() < sec) do 
	end 
end

neutrino_conf = configfile.new()
neutrino_conf:loadConfig("/etc/neutrino/config/neutrino.conf")
lang = neutrino_conf:getString("language", "english")
pluginpath = "/usr/share/tuxbox/plugins/"

if locale[lang] == nil then
	lang = "english"
end

function start_flash()
	dofile(pluginpath .. "stb-flash.lua")
end

function start_local_flash()
       	dofile(pluginpath .. "stb-local-flash.lua")
end

function start_backup()
       	dofile(pluginpath .. "stb-backup.lua")
end

function start_restore()
       	dofile(pluginpath .. "stb-restore.lua")
end

function start_move()
       	dofile(pluginpath .. "stb-move.lua")
end

function main_menu()
	g.main = menu.new{name=locale[lang].locale_image_management, icon="settings"}
	m=g.main
	m:addItem{type="back"}
	m:addItem{type="separatorline"}
	m:addItem{type="forwarder", name=locale[lang].locale_stb_flash, action="start_flash", icon="1", directkey=RC["1"]};
       	m:addItem{type="forwarder", name=locale[lang].locale_stb_local_flash, action="start_local_flash", icon="2", directkey=RC["2"]};
       	m:addItem{type="forwarder", name=locale[lang].locale_stb_backup, action="start_backup", icon="3", directkey=RC["3"]};
       	m:addItem{type="forwarder", name=locale[lang].locale_stb_restore, action="start_restore", icon="4", directkey=RC["4"]};
       	m:addItem{type="forwarder", name=locale[lang].locale_stb_move, action="start_move", icon="5", directkey=RC["5"]};
	m:exec()
	m:hide()
end

main_menu()
