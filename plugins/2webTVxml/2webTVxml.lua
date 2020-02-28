--[[

	Copyright (C) 2020  Jacek Jendrzej 'satbaby'

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

local glob = {}
local version="2webTVxml Version 0.5"
local n = neutrino()
local conf = {}
local on="ein"
local off="aus"
local loc = nil
locale = {}
locale["deutsch"] = {
	file = "Datei auswählen",
	filehint = "Wählen Sie eine tv- oder m3u-Datei.",
	convert = "konvertieren in xml",
	converthint = "tv oder m3u in xml-format konvertieren",
	checkonline = "Online prüfen",
	checkonlinehint = "Wird geprüft , ob ein Stream online ist.",
	defpathon = "Standardpfad verwenden",
	defpathonhint = "Standardpfad verwenden?",
	defdir = "Verzeichnis: ",
	defdirhint = "In welchem Verzeichnis soll Datei (xml) gespeichert werden?",
	infohint = "Nicht unterstütztes Format"
}
locale["english"] = {
	file = "Select file",
	filehint = "Select tv or m3u file",
	convert = "convert to xml",
	converthint = "convert tv or m3u to xml format",
	checkonline = "Check  online",
	checkonlinehint = "Checks whether a stream is online.",
	defpathon = "Use default Path",
	defpathonhint = "Use default Path?",
	defdir = "Directory: ",
	defdirhint = "In which directory should file (xml) be saved?",
	infohint = "Not supported format"
}

function get_confFile()
	return "/var/tuxbox/config/2webTVxml.conf"
end

function hideMenu(menu)
	if menu ~= nil then menu:hide() end
end

function setvar(k, v)
	if v and #v > 0 then
		conf[k]=v
		conf.changed = true
	end
end

function file_exists(file)
	local fh = filehelpers.new()
	if fh then return fh:exist(file, "f") else return false end
end

function godirectkey(d)
	if d  == nil then return d end
	local  _dkey = ""
	if d == 1 then
		_dkey = RC["red"]
	elseif d == 2 then
		_dkey = RC["green"]
	elseif d == 3 then
		_dkey = RC["yellow"]
	elseif d == 4 then
		_dkey = RC["blue"]
	elseif d < 14 then
		_dkey = RC[""..d - 4 ..""]
	elseif d == 14 then
		_dkey = RC["0"]
	else
		-- rest
		_dkey = ""
	end
	return _dkey
end

function saveConfig()
	if conf.changed then
		local config	= configfile.new()
		config:setString("file", conf.file)
		config:setBool  ("checkonline",conf.checkonline)
		config:setBool  ("defpathon",conf.defpathon)
		config:setString("path", conf.path)
		config:saveConfig(get_confFile())
		conf.changed = false
	end
end

function loadConfig()
	local config	= configfile.new()
	config:loadConfig(get_confFile())
	conf.path = config:getString("path", "/tmp")
	conf.checkonline = config:getBool("checkonline", false)
	conf.defpathon = config:getBool("defpathon", false)
	conf.file = config:getString("file", "/tmp/test.tv")

	conf.ffprobe = which("ffprobe")
	conf.ctimeout = 2
	conf.changed = false

	local Nconfig	= configfile.new()
	Nconfig:loadConfig("/var/tuxbox/config/neutrino.conf")
	conf.lang = Nconfig:getString("language", "english")
	if locale[conf.lang] == nil then
		conf.lang = "english"
	end
	loc = locale[conf.lang]

end

function which(bin_name)
	local path = os.getenv("PATH") or "/bin"
	for v in path:gmatch("([^:]+):?") do
		local file = v .. "/" .. bin_name
		if file_exists(file) then
			return true
		end
	end
	return false
end

function sleep (a)
    local sec = tonumber(os.clock() + a)
    while (os.clock() < sec) do
    end
end

function getdata(Url,outputfile)
	if Url == nil then return nil end
	if Curl == nil then
		Curl = curl.new()
	end

	local ret, data = Curl:download{url=Url,A="Mozilla/5.0;",connectTimeout=conf.ctimeout,maxRedirs=5,followRedir=true,o=outputfile }
	if ret == CURL.OK then
		if outputfile then
			return 1
		end
		return data
	else
		return nil
	end
end

function read_file(filename)
	if filename == nil then
		print("Error: FileName  is empty")
		return nil
	end
	local fp = io.open(filename, "r")
	if fp == nil then print("Error opening file '" .. filename .. "'.") return nil end
	local data = fp:read("*a")
	fp:close()
	return data
end

function pop(cmd)
	local f = io.popen(cmd, 'r')
	local s = ""
	if f then
		s = f:read('*a')
		f:close()
	end
	return s
end

function hex2char(hex)
  return string.char(tonumber(hex, 16))
end
function unescape_uri(url)
  return url:gsub("%%(%x%x)", hex2char)
end

function basename(str)
	local name = string.gsub(str, "(.*/)(.*)", "%2")
	return name
end

function info(captxt,infotxt, sleep)
	if captxt == version and infotxt==nil then
		infotxt=captxt
		captxt="Information"
	end
	local msg, data = 0,0
	local h = hintbox.new{caption=captxt, text=infotxt}
	h:paint()
	if sleep then
		for i=1,sleep*5,1 do
			msg, data = n:GetInput(500)
			if msg == RC.ok or msg == RC.home then
				break
			end
		end
	else
		repeat
			msg, data = n:GetInput(500)
		until msg == RC.ok or msg == RC.home
	end
	h:hide()
end

function xmlentity(str)
	if str == nil then return "" end
	local ustr = str:gsub("'","&apos;")
	ustr = ustr:gsub('"',"&quot")
	ustr = ustr:gsub('<',"&lt")
	ustr = ustr:gsub('>',"&qt")
	ustr = ustr:gsub("&","&amp;")
	ustr = ustr:gsub("\r","")
	ustr = ustr:gsub("\n","")
	return ustr
end

function checkOnline(url)
	if url:find("%.m3u8") then
		local data = getdata(url)
		if data then
			if data:match("#EXTM3U") then
				return true
			end
		end
	elseif conf.ffprobe then
		local output = pop("ffprobe '" .. url .. "' 2>&1")
		if output:find("Stream") then
			return true
		else
			return false
		end
	else
		return true
	end
	return false
end

function saveXml(filename,name,xmliste,ext)

	if conf.defpathon then filename = conf.path .. "/" .. basename(filename) end

	local file = io.open(filename:sub(0,ext) .. "xml",'w+')
	if file then
		local saveUrl = true
		name = xmlentity(name)
		local pw = cprogresswindow.new{title=name}
		pw:paint()
		pw:showStatus{statusText="Start"}

		file:write('<?xml version="1.0" encoding="UTF-8"?>\n<webtvs name="'.. name .. '">\n')
		for i, v in ipairs(xmliste) do
			v.xurl = unescape_uri(v.xurl)
			pw:showStatus{prog=i,max=#xmliste,statusText=tostring(i) .. "/" .. tostring(#xmliste) .. "  " .. v.xtitle}
			if conf.checkonline then
				saveUrl = checkOnline(v.xurl)
			end
			if saveUrl then
				local script = ''
				if v.xurl:find("%.m3u8") then script = 'script="best_bitrate_m3u8.lua" ' end
				v.xurl = xmlentity(v.xurl)
				v.xtitle = xmlentity(v.xtitle)
				file:write('\t<webtv genre="' .. v.xgen ..  '" title="' .. v.xtitle .. '" url="' .. v.xurl .. '" ' .. script .. 'description="' .. v.xtag .. '" />\n')
			end
		end
		file:write("</webtvs>\n")
		file:close()
		sleep (1)
		pw:hide()
	end
end

function m3u2xml(filename)
	local urls = {}
	local xmliste = {}
	local data = read_file(filename)
	if data then
		for name,url in data:gmatch('#EXTINF.-,(.-)\n(http.-)\n') do
			if urls[url] ~= true then
				urls[url] = true
				local gen = "IPTV"
				local tag = "m3u"
				table.insert(xmliste,{xgen=gen,xtitle=name,xurl=url,xtag=tag})
			end
		end
		if #xmliste > 0 then
			saveXml(filename,"EXTM3U",xmliste,-4)--m3u
		end
	end
end

function tv2xml(filename)
	local urls = {}
	local xmliste = {}
	local data = read_file(filename)
	if data then
		local saveUrl = true
		local name = data:match("#NAME%s+::(.-):")
		name = name or "e2tv"
		for url,des in data:gmatch('#SERVICE .-:0:0:0:(http.-)[:\n].-#DESCRIPTION%s+(.-)\n') do
			if urls[url] ~= true then
				urls[url] = true
				local gen = "IPTV"
				local tag = "e2tv"
				table.insert(xmliste,{xgen=gen,xtitle=des,xurl=url,xtag=tag})
			end
		end
		if #xmliste > 0 then
			saveXml(filename,name,xmliste,-3)--tv
		end
	end
end

function getExt(filename)
	local lastpos = (filename:reverse()):find("%.")
	if lastpos > 0 then
		return filename:sub(#filename - lastpos + 2,#filename)
	end
	return ""
end

function convert2xml()
	hideMenu(glob.main_menu)
	local filename = conf.file
	local ext = getExt(filename)
	if ext == "tv" then
		tv2xml(filename)
	elseif ext == "m3u" then
		m3u2xml(filename)
	else
		info("  " .. ext, loc.infohint,2)
	end
end

function set_option(k, v)
	if v == on then
		conf[k]=true
	else
		conf[k]=false
	end
	if k == "defpathon" then
		glob.main_menu:setActive{item=m1, activ=conf[k]}
	end
	conf.changed = true
end

function bool2onoff(a)
	if a then return on end
	return off
end

function main_menu()
	glob.main_menu  = menu.new{name="2WebTVxml", icon="icon_yellow"}
	local menu = glob.main_menu
	local d = 1 -- directkey

	menu:addKey{directkey=RC["info"], id=version, action="info"}
	menu:addItem{type="back"}
	menu:addItem{type="separatorline"}
	menu:addItem{ type="filebrowser", dir_mode="0", id="file", name=loc.file, action="setvar",enabled=true,value=conf.file,directkey=godirectkey(d),
		   hint_icon="hint_service",hint=loc.filehint
		 }
	d=d+1
	menu:addItem{type="forwarder", name=loc.convert, action="convert2xml", enabled=true,id="dummy"..d, directkey=godirectkey(d),hint=loc.converthint}
	d=d+1
	menu:addItem{type="separatorline"}
	menu:addItem{type="chooser", action="set_option", options={ on, off }, id="checkonline", value=bool2onoff(conf.checkonline), directkey=godirectkey(d), name=loc.checkonline,hint_icon="hint_service",hint=loc.checkonlinehint}
	d=d+1
	menu:addItem{type="chooser", action="set_option", options={ on, off }, id="defpathon", value=bool2onoff(conf.defpathon), directkey=godirectkey(d), name=loc.defpathon,hint_icon="hint_service",hint=loc.defpathonhint}
	d=d+1
	m1 = menu:addItem{ 	type="filebrowser", dir_mode="1", id="path", name=loc.defdir, action="setvar",enabled=true,value=conf.path,directkey=godirectkey(d),
			hint_icon="hint_service",hint=loc.defdirhint
		 }
	menu:setActive{item=m1, activ=conf.defpathon}

	menu:exec()
end

function main()
	loadConfig()
	main_menu()
	saveConfig()
	collectgarbage()
end

main()
