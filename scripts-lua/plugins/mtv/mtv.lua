--[[
	mtv.de
	Copyright (C) 2015,  Jacek Jendrzej 'satbaby'

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
local mtv_version="mtv.de Version 0.17" -- Lua API Version: " .. APIVERSION.MAJOR .. "." .. APIVERSION.MINOR
local n = neutrino()
local conf = {}
local on="ein"
local off="aus"

function get_confFile()
	return "/var/tuxbox/config/mtv.conf"
end
function get_conf_mtvfavFile()
	return "/var/tuxbox/config/mtvfav.conf"
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
	local f = io.open(file, "rb")
	if f then f:close() end
	return f ~= nil
end

function saveConfig()
	if conf.changed then
		local config	= configfile.new()
		config:setString("path", conf.path)
		config:setBool  ("dlflag",conf.dlflag)
		config:setBool  ("flvflag",conf.flvflag)
		config:setBool  ("playflvflag",conf.playflvflag)
		config:setBool  ("shuffleflag",conf.shuffleflag)
		config:setString("search", conf.search)
		config:saveConfig(get_confFile())
		conf.changed = false
	end
	if glob.fav_changed == true then
		local file_mtvconf=io.open(get_conf_mtvfavFile(),"w")
		for k, v in ipairs(glob.mtv) do
			if v.fav == true then
				file_mtvconf:write('name="'.. v.name ..'",url="'.. v.url ..'"\n')
			end
		end
		file_mtvconf:close()
	end
end

function loadConfig()
	local config	= configfile.new()
	config:loadConfig(get_confFile())
	conf.path = config:getString("path", "/media/sda1/movies/")
	conf.dlflag = config:getBool("dlflag", false)
	conf.flvflag = config:getBool("flvflag", false)
	conf.playflvflag = config:getBool("playflvflag", false)
	conf.shuffleflag = config:getBool("shuffleflag", false)
	conf.search = config:getString("search", "Jessie J")
	conf.changed = false
end

function pop(cmd)
       local f = assert(io.popen(cmd, 'r'))
       local s = assert(f:read('*a'))
       f:close()
       return s
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

function init()
	if vodeoPlay == nil then
		vodeoPlay = video.new()
	end

	glob.fav_changed = false
	glob.have_rtmpdump=false
	local r= pop("which rtmpdump")
	if #r>0 then 
		glob.have_rtmpdump=true
	end
	glob.mtv_artist={}
	glob.mtv={
		{name = "Brandneu",url="http://www.mtv.de/musik",fav=false},
		{name = "SINGLE TOP 20",url="http://www.mtv.de/charts/302-single-top-20",fav=false},
		{name = "SINGLE TOP 100",url="http://www.mtv.de/charts/288-single-top-100",fav=false},
		{name = "MTV.de Videocharts",url="http://www.mtv.de/charts/8-mtv-de-videocharts",fav=false},
		{name = "MTV.ch Videocharts",url="http://www.mtv.ch/charts/206-mtv-ch-videocharts",fav=false},
		{name = "MTV unplugged DE",url="http://www.mtv.de/mtv-unplugged",fav=false},
		{name = "Top 100 Jahrescharts 2016",url="http://www.mtv.de/charts/274-top-100-jahrescharts-2016",fav=false},
		{name = "Top 100 Jahrescharts 2015",url="http://www.mtv.de/charts/275-top-100-jahrescharts-2015",fav=false},
		{name = "Top 100 Jahrescharts 2014",url="http://www.mtv.de/charts/241-top-100-single-jahrescharts-2014",fav=false},
		{name = "Viva Top 100 Jahrescharts 2016",url="http://www.viva.tv/charts/277-eure-viva-jahrescharts-2016",fav=false},
		{name = "Dance Charts",url="http://www.mtv.de/charts/293-dance-charts",fav=false},
		{name = "Viva Brandneu",url="http://www.viva.tv/news/19363-viva-neu",fav=false},
		{name = "HIP HOP CHARTS",url="http://www.mtv.de/charts/292-hip-hop-charts",fav=false},
		{name = "SINGLE TRENDING",url="http://www.mtv.de/charts/301-single-trending",fav=false},
		{name = "TOP 100 MUSIC STREAMING",url="http://www.mtv.de/charts/286-top-100-music-streaming",fav=false},
		{name = "TOP 15 DEUTSCHSPRACHIGE SINGLES",url="http://www.mtv.de/charts/304-top-15-deutschsprachige-singles",fav=false},
		{name = "DOWNLOAD CHARTS SINGLE",url="http://www.mtv.de/charts/289-download-charts-single",fav=false},
		{name = "MOST WANTED 90'S",url="http://www.mtv.de/charts/295-most-wanted-90-s",fav=false},
		{name = "MOST WANTED 2000'S",url="http://www.mtv.de/charts/296-most-wanted-2000-s",fav=false},
		{name = "MTV unplugged AT",url="http://at.mtv.de/mtv-unplugged",fav=false},
	}
	local mtvconf = get_conf_mtvfavFile()
	local havefile = file_exists(mtvconf)
	if havefile == true then
		local favdata = read_file(mtvconf)
		if havefile ~= nil then
			for _name ,_url in favdata:gmatch('name%s-=%s-"(.-)"%s-,%s-url%s-=%s-"(.-)"') do
				table.insert(glob.mtv,{name=_name, url=_url,fav=true})
			end
		end
	end
end

function info(captxt,infotxt, sleep)
	if captxt == mtv_version and infotxt==nil then
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

function getdata(Url,outputfile)
	if Url == nil then return nil end
	if Curl == nil then
		Curl = curl.new()
	end
	local ret, data = Curl:download{url=Url,A="Mozilla/5.0;",maxRedirs=5,followRedir=true,o=outputfile }
	if ret == CURL.OK then
		if outputfile then
			return 1
		end
		return data
	else
		return nil
	end
end

function exist_id(table, id)
	for i, v in ipairs(table) do
		if tonumber(v.vid) == tonumber(id) then
			return i
		end
	end
	return nil
end

function getliste(url)
	local clip_page = getdata(url)
	if clip_page == nil then return nil end
	local videosection = string.match(clip_page,"window.pagePlaylist = %[(.-)%];")
	if videosection == nil then return nil end
	local liste = {}
	local json = require "json"
	for j in string.gmatch(videosection, "(%{.id.-%})") do
		local jnTab = json:decode(j)
		if(jnTab.title and jnTab.subtitle and jnTab.riptide_image_id) then
			local pic = ""
			if jnTab.riptide_image_id then
				pic = "http://images.mtvnn.com/" .. jnTab.riptide_image_id .. "/306x172_"
			end
			jnTab.title=jnTab.title:gsub("&quot;",'"')
			jnTab.title=jnTab.title:gsub("&amp;",'&')
			table.insert(liste,{name=jnTab.title .. ": " .. jnTab.subtitle, url=jnTab.mrss,
			type=jnTab.video_type, tok=jnTab.video_token, logo=pic,enabled=conf.dlflag, vid=jnTab.id
			})
		end
	end
	local listechart = {}
	local begin = clip_page:find('<ul class="video%-collection">')
	if begin then
		local section = clip_page:sub(begin,#clip_page)
		for _chartpos , id in section:gmatch('<div class="chart%-position">(%d+)</div>.-data%-object%-id="(%d+)">') do
			local vid = exist_id(liste, id)
			if vid then
				table.insert(listechart,{name=liste[vid].name, url=liste[vid].url,
				type=liste[vid].type, tok=liste[vid].tok, logo=liste[vid].logo,enabled=conf.dlflag, vid=liste[vid].vid, chartpos=_chartpos
			})
			end
		end
	end
	if #listechart > 0 then
		return listechart
	end
	return liste
end

function getvideourl(url,vidname,tok,typ,h)
	if url == nil then return nil end
	local video_url = nil
	if (typ ~= "arc" and typ ~="local_playlist") and tok  ~= nil then
		url = 'http://intl.esperanto.mtvi.com/www/xml/media/mediaGen.jhtml?uri=mgid:uma:video:mtv.de:' .. tok
	end
	local clip_page = getdata(url)
	if clip_page == nil then return nil end

	if (typ ~= "arc" and typ ~="local_playlist") and tok  ~= nil then
		video_url  = clip_page:match("<src>(.-)</src>")
		print(video_url)
	else

		url  = clip_page:match("url='(.-)'")
		if url == nil then return nil end
		url=url:gsub(":mtvni.com:",":mtv.de:")
		clip_page = getdata(url)
		local max_width = -1
		for  width,url in string.gmatch(clip_page, '<rendition.-width="(%d+).-<src>(.-)</src>') do
			if max_width < tonumber(width) and url then
				max_width = tonumber(width)
				video_url = url
			end
		end
	end
	if video_url and video_url:sub(1,5) == "rtmpe" then
		video_url = "rtmp" .. video_url:sub(6,#video_url)
	end
	local x = nil
	if video_url then
		x = video_url:find("rtmp")
	end
	if not x then
	  print("########## Error ##########")
	  print(url,video_url,clip_page)
	  print("###########################")
	end
	if video_url and video_url:find("copyright_error") then
		if h then
			h:hide()
		end
		info("Video Not Available", "Copyright Error\n" .. vidname,2)
	end
	return video_url
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

function action_exec(id)
	if id  then
		local i = tonumber(id)
		if glob.MTVliste[i].name == nil then
			glob.MTVliste[i].name = "NoName_" .. i
		end
		local url = getvideourl(glob.MTVliste[i].url,glob.MTVliste[i].name,glob.MTVliste[i].tok,glob.MTVliste[i].type)
		if url then
			hideMenu(glob.menu_liste)
			vodeoPlay:setSinglePlay()
			vodeoPlay:PlayFile(glob.MTVliste[i].name, url,glob.MTVliste[i].type);
		end
	end
	return MENU_RETURN.EXIT_REPAINT
end

function gen_m3u_list(filename)
	local m3ufilename="/tmp/" .. filename .. ".m3u"

	local h = hintbox.new{caption="Info", text=filename .." - Playlist wird erstellt\n"..m3ufilename}
	h:paint()

	local m3ufile=io.open(m3ufilename,"w")
	m3ufile:write("#EXTM3U name=" .. filename .. "\n")
        for k, v in ipairs(glob.MTVliste) do
		if v.name == nil then
			v.name = "NoName"
		end
		local url = getvideourl(v.url,v.name,v.tok,v.type)
		if url then
			local extinf = ", "
-- 			if v.logo then --TODO Add Logo parse to CMoviePlayerGui::parsePlaylist
-- 				extinf = " logo=" .. v.logo ..".jpg ,"
-- 			end
			extinf = extinf .. v.name
			m3ufile:write("#EXTINF:-1".. extinf .."\n")
			m3ufile:write(url .."\n")
		end
	end
	h:hide()
        m3ufile:close()
	info("Info", filename.." - Playlist wurde erstellt\n"..m3ufilename,2)
	return MENU_RETURN.EXIT_REPAINT
end

function make_shuffle_list(tab)
	local randTable={}
	for k=1 , #tab do
		randTable[k]=k
	end
	local shuffleTable = {}
	for k=1,#randTable do
		math.randomseed(os.time() *100000000000)
		local r=table.remove(randTable,math.random(#randTable))
		shuffleTable[k]=tab[r]
	end
	return shuffleTable
end

function playlist(filename)
	if (n:checkVersion(1, 1) == 0) then do return end end
	hideMenu(glob.menu_liste)

	local tab = {}
	if conf.shuffleflag == true then
		tab = make_shuffle_list(glob.MTVliste)
	else
		tab = glob.MTVliste
	end

	local i = 1
	local KeyPressed = 0
	vodeoPlay:setSinglePlay(false)
	repeat
		if tab[i].name == nil then
			tab[i].name = "NoName"
		end
		local url = getvideourl(tab[i].url,tab[i].name,tab[i].tok,tab[i].type)
		if url then
			local videoformat = url:sub(-4)
			if videoformat ~= ".flv" or conf.playflvflag then
				local prevn , nextn = "",""
				if i-1 ~= 0 then
					prevn = "Vorherige Titel: " .. tab[i-1].name
				end
				if i < #tab then
					nextn = "Nächste Titel: ".. tab[i+1].name
				end
				KeyPressed = vodeoPlay:PlayFile( "(" .. i.. "/" .. #tab .. ") " .. tab[i].name,url, nextn, prevn)
			end
		end
		if KeyPressed == PLAYSTATE.NORMAL then --play continue
			i=i+1
		elseif KeyPressed == PLAYSTATE.STOP then
			i=0
			break
		elseif KeyPressed == PLAYSTATE.NEXT then
			i=i+1
		elseif KeyPressed == PLAYSTATE.PREV then
			i=i-1
		else
			print("Error")
			i=0
			break
		end

	until i==0 or i == #tab+1

	return MENU_RETURN.EXIT_REPAINT
end

function dlstart(name)
	local infotext = "Dateien werden für Download vorbereitet.  "
	name = name:gsub([[%s+]], "_")
	name = name:gsub("[:'&()/]", "_")
	local dlname = "/tmp/" .. name ..".dl"
	local havefile = file_exists("/tmp/.rtmpdl")
	if havefile == true then
		info("Info", "Ein anderer Download ist bereits aktiv.",4)
		return
	end
	local dl=io.open(dlname,"w")
	local script_start = false

	local pw = cprogresswindow.new{title=infotext}
	pw:paint()
	for i, v in ipairs(glob.MTVliste) do
		if v.enabled == true then
			if glob.MTVliste[i].name == nil then
				glob.MTVliste[i].name = "NoName_" .. i
			end
			local url = getvideourl(glob.MTVliste[i].url,glob.MTVliste[i].name,glob.MTVliste[i].tok,glob.MTVliste[i].type,h)
			if url then
				local fname = v.name:gsub([[%s+]], "_")
				fname = fname:gsub("[:'()]", "_")
				pw:showStatus{prog=i,max=#glob.MTVliste,statusText=tostring(i) .. "/" .. tostring(#glob.MTVliste) .. "  " .. fname}
				local videoformat = url:sub(-4)
				if videoformat == nil then
					videoformat = ".mp4"
				end
				if videoformat ~= ".flv" or conf.flvflag then
					dl:write("rtmpdump -e -r " .. url .. " -o " .. conf.path .. "/" .. fname  .. videoformat .."\n")
					script_start = true
				end
			end
		end
	end
	pw:hide()
	if script_start == true then
	dl:close()
	local scriptname  = "/tmp/" .. name ..".sh"
	local script=io.open(scriptname,"w")
	script:write(
	[[#!/bin/sh
	while read -r i
	do
		$i
	done < ]]
	)
	script:write("'" .. dlname .. "'\n")
	script:write([[
	wget -q 'http://127.0.0.1/control/message?popup=Video Liste ]])
		script:write(name .. " wurde heruntergeladen.' -O /dev/null\n")
		script:write("rm '" .. dlname .. "'\n")
		script:write("rm '" .. scriptname .. "'\n")
		script:write("rm /tmp/.rtmpdl\n")

		script:close()
		os.execute("echo >/tmp/.rtmpdl")
		os.execute("sleep 2")
		os.execute("chmod 755 '" .. scriptname .. "'")
		os.execute("sh '"..scriptname.."' &")
	else
		local er = hintbox.new{caption="Info", text=name .." - \nDownload ist fehlerhaft \noder Video in FLV-Format"}
		er:paint()
		os.remove(dlname)
		print("ERROR")
		os.execute("sleep 2")
		er:hide()
	end
end

function exist(_url)
	for i, v in ipairs(glob.mtv) do
		if v.fav == true and v.url == _url then
			return true
		end
	end
	return false
end

function addfav(id)
	local addinfo = false
	for i, v in ipairs(glob.mtv_artist) do
		if v.enabled and exist(v.url) == false then
			table.insert(glob.mtv,{name=v.name, url=v.url,fav=true})
			glob.mtv_artist[i].disabled=true
			glob.fav_changed = true
			addinfo = true
		end
	end
	if addinfo == true then
		info("Info","Zu Favoriten hinzugefügt",2)
	end
end

function favdel(id)
	local delinfo = false
	for i, v in ipairs(glob.mtv) do
		if v.fav and v.enabled then
			table.remove(glob.mtv,i)
			glob.fav_changed = true
			delinfo = true
		end
	end
	if delinfo == true then
		info("Info","Ausgewählten Favoriten gelöscht",2)
	end

end

function chooser_menu(id)
	if id:sub(1,29) =="Erstelle Download Liste für " then
		local forwarder_action = "dlstart"
		local forwarder_name = "Download starten"
		local chooser_action = "set_bool_in_liste"
		local hintname = "Speichert die ausgewählten Videos unter: " .. conf.path
		local _id = id:sub(30,#id)
		local name = id
		local value=conf.dlflag
		gen_chooser_menu(glob.MTVliste, name, _id, chooser_action, forwarder_action, forwarder_name, hintname, value, glob.menu_liste)
	elseif id:sub(1,15) =="Neue Favoriten" then
		local forwarder_action = "addfav"
		local forwarder_name = "Zu Favoriten hinzufügen"
		local chooser_action = "set_bool_in_searchliste"
		local hintname = "Speichert die ausgewählten Videos unter: " .. conf.path
		local name = id .. " hinzufügen"
		local value=false
		gen_chooser_menu(glob.mtv_artist, name , id, chooser_action, forwarder_action, forwarder_name, hintname, value, glob.search_artists_menu)
	elseif id =="favdel" then
		local forwarder_action = "favdel"
		local forwarder_name = "Favoriten löschen"
		local chooser_action = "set_bool_in_mtv"
		local hintname = "Lösche die ausgewählten Videos."
		local name = id .. " hinzufügen"
		local value=false
		gen_chooser_menu(glob.mtv, name , id, chooser_action, forwarder_action, forwarder_name, hintname, value, glob.settings_menu)

	end
end

function set_bool_in_liste(k, v)
	local i = tonumber(k)
	if v == on then
		glob.MTVliste[i].enabled=true
	else
		glob.MTVliste[i].enabled=false
	end
end

function set_bool_in_searchliste(k, v)
	local i = tonumber(k)
	if v == on then
		glob.mtv_artist[i].enabled=true
	else
		glob.mtv_artist[i].enabled=false
	end
end

function set_bool_in_mtv(k, v)
	local i = tonumber(k)
	if v == on then
		glob.mtv[i].enabled=true
	else
		glob.mtv[i].enabled=false
	end
end

function gen_chooser_menu(table, name , _id, _chooser_action, _forwarder_action, _forwarder, _hintname, _value, hidemenu)
	hideMenu(hidemenu)
	local menu =  menu.new{name=name, icon="icon_red"}
	menu:addItem{type="back"}
	menu:addItem{type="separatorline"}
	local d = 1 -- directkey

	menu:addItem{type="forwarder", name=_forwarder, action=_forwarder_action, enabled=true,
	id=_id, directkey=godirectkey(d),hint=_hintname}
	menu:addItem{type="separatorline"}
	for i, v in ipairs(table) do
		if (("favdel" == _forwarder_action and v.fav==true) or "addfav" ==  _forwarder_action or "dlstart" ==  _forwarder_action) then
			d = d + 1
			local dkey = godirectkey(d)
			menu:addItem{type="chooser", action=_chooser_action, options={ on, off }, id=i, value=bool2onoff(_value), 
			name= i .. ": " ..v.name, hint_icon="hint_service",hint=v.name .. " speichern ? Ein/Aus"}
		end
	end
	menu:exec()
	menu:hide()
	return MENU_RETURN.EXIT_REPAINT
end

function __menu(_menu,menu_name,table,_action)
	if table == nil or #table == 0 then
		info("Info", "Liste ist leer.", 1)
		return
	end
	hideMenu(glob.mtv_listen_menu)
	_menu:addItem{type="back"}
	_menu:addItem{type="separatorline"}
	local d = 1 -- directkey
	local playhint = "Playlist: "
	if conf.shuffleflag then
		playhint = "Playlist in zufällig Reihenfolge: "
	end
	_menu:addItem{type="forwarder", name="Playlist", action="playlist", enabled=true,
	id="Playlist " .. menu_name, directkey=godirectkey(d),hint=playhint .. menu_name}
        d=d+1
	_menu:addItem{type="forwarder", name="Erstelle M3U Playlist", action="gen_m3u_list", enabled=true,
	id=menu_name, directkey=godirectkey(d),hint="Erstelle eine M3U Playlist im Verzeichnis: /tmp/" .. menu_name .. ".m3u"}
	d = d + 1
	_menu:addItem{type="forwarder", name="Erstelle Download Liste", action="chooser_menu", enabled=glob.have_rtmpdump,
			id="Erstelle Download Liste für "..menu_name, directkey=godirectkey(d),hint="Welche Videos sollen heruntergeladen werden ?"}
	_menu:addItem{type="separatorline"}
	d = d + 1 --skip blue

	for i, v in ipairs(table) do
		d = d + 1
		local dkey = godirectkey(d)
		local cont = i .. ": "
		if v.chartpos then
			cont = " (" .. v.chartpos .. ") "
		end
		_menu:addItem{type="forwarder", name=cont .. v.name, action=_action,enabled=true,id=i,directkey=dkey,hint=v.type}
	end
	_menu:exec()
	_menu:hide()
	return MENU_RETURN.EXIT_REPAINT
end

function mtv_liste(id)
	local i = tonumber(id)
	glob.MTVliste=nil;
	local url=glob.mtv[i].url
	glob.MTVliste = getliste(url)
	glob.menu_liste  = menu.new{name=glob.mtv[i].name, icon="icon_blue"}
	__menu(glob.menu_liste ,glob.mtv[i].name, glob.MTVliste,"action_exec")
	return MENU_RETURN.EXIT_REPAINT
end

if APIVERSION ~=nil and (APIVERSION.MAJOR > 1 or ( APIVERSION.MAJOR == 1 and APIVERSION.MINOR > 24 )) then
	function set_path(id,value)
		conf[id]=value
		conf.changed = true
	end
else
	function set_path(value)
		conf.path=value
		conf.changed = true
	end
end

function set_option(k, v)
	if v == on then
		conf[k]=true
	else
		conf[k]=false
	end
	conf.changed = true
end

function bool2onoff(a)
	if a then return on end
	return off
end

function setings()
	hideMenu(glob.main_menu)

	local d =  1
	local menu =  menu.new{name="Einstellungen", icon="icon_blue"}
	glob.settings_menu = menu
	menu:addItem{type="back"}
	menu:addItem{type="separatorline"}
	menu:addItem{ type="filebrowser", dir_mode="1", id="path", name="Verzeichnis: ", action="set_path",
		   enabled=true,value=conf.path,directkey=godirectkey(d),
		   hint_icon="hint_service",hint="In welchem Verzeichnis soll das Video gespeichert werden ?"
		 }
	d=d+1
	menu:addItem{type="chooser", action="set_option", options={ on, off }, id="dlflag", value=bool2onoff(conf.dlflag), directkey=godirectkey(d), name="Auswahl vorbelegen mit",hint_icon="hint_service",hint="Erstelle Auswahlliste mit 'ein' oder 'aus'"}
	d=d+1
	menu:addItem{type="chooser", action="set_option", options={ on, off }, id="flvflag", value=bool2onoff(conf.flvflag), directkey=godirectkey(d), name="Videos in FLV-Format herunterladen ? ",hint_icon="hint_service",hint="Videos in FLV-Format sind meisten mit nicht kompatiblen Video-Codec (zB: vp6f)."}
	d=d+1
	menu:addItem{type="chooser", action="set_option", options={ on, off }, id="playflvflag", value=bool2onoff(conf.playflvflag),
	directkey=godirectkey(d), name="Videos in FLV-Format abspielen ? ",hint_icon="hint_service",hint="Videos in FLV-Format sind meisten mit nicht kompatiblen Video-Codec (zB: vp6f)."}
	d=d+1
	menu:addItem{type="chooser", action="set_option", options={ on, off }, id="shuffleflag", value=bool2onoff(conf.shuffleflag),
	directkey=godirectkey(d), name="Zufällig abspielen ? ",hint_icon="hint_service",hint="Video wiedergabelisten zufällig abspielen. "}

	menu:addItem{type="separatorline"}
	d=d+1
	menu:addItem{type="forwarder", name="Ausgewählte Favoriten löschen.", action="chooser_menu", enabled=true,
	id="favdel", directkey=godirectkey(d),hint="Favoriten bearbeiten"}
	menu:exec()
	menu:hide()
	return MENU_RETURN.EXIT_REPAINT
end

function gen_search_list(search)
	local url = "http://www.mtv.de/searches?q=+"..search .. "+&ajax=1"
	local clip_page = getdata(url)
	if clip_page == nil then return nil end
	glob.mtv_artist={}
	for _url ,title in clip_page:gmatch('/artists/(.-)"><div class="title">(.-)</div>') do
		title=title:gsub("&quot;",'"')
		title=title:gsub("&amp;",'&')
		_url="http://www.mtv.de/artists/" .. _url
		if exist(_url) == false then
			table.insert(glob.mtv_artist,{name=title, url=_url, enabled=false,disabled=false})
		end
	end
	return MENU_RETURN.EXIT_REPAINT

end

function searchliste(id)
	hideMenu(glob.artists_menu)
	local i = tonumber(id)
	glob.MTVliste=nil;
	if glob.mtv_artist[i].disabled == true then return end
	local url=glob.mtv_artist[i].url
	glob.MTVliste = getliste(url)
	glob.menu_liste  = menu.new{name=glob.mtv_artist[i].name, icon="icon_blue"}
	__menu(glob.menu_liste ,glob.mtv_artist[i].name, glob.MTVliste,"action_exec")
	return MENU_RETURN.EXIT_REPAINT
end

function search_artists()
	if conf.search == nil then return end

	hideMenu(glob.main_menu)
	local h = hintbox.new{caption="Info", text="Suche: " .. conf.search}
	h:paint()
	if #conf.search > 1 then
		gen_search_list(conf.search)
	end
	h:hide()
	if glob.mtv_artist == nil or #glob.mtv_artist == 0 then
		info("Info", "Liste ist leer.", 1)
		return
	end

	local d = 1
	local menu =  menu.new{name=conf.search, icon="icon_yellow"}
	glob.search_artists_menu = menu
	glob.artists_menu = menu
	menu:addItem{type="back"}
	menu:addItem{type="separatorline"}
	menu:addItem{type="forwarder", name="Neue Favoriten hinzufügen", action="chooser_menu", enabled=true,
	id="Neue Favoriten", directkey=godirectkey(d),hint="Listen für Favoriten auswählen und hinzufügen."}
	menu:addItem{type="separatorline"}

	if glob.mtv_artist then
	for i, v in ipairs(glob.mtv_artist) do
		d = d + 1
		local dkey = godirectkey(d)
		menu:addItem{type="forwarder", name=i .. ": " .. v.name, action="searchliste",enabled=true,id=i,directkey=dkey,hint="Suchwort-Liste für " .. conf.search}
	end
	end
	menu:exec()
	menu:hide()
end

function mtv_listen_menu()
	if glob.mtv == nil then
		return
	end
	hideMenu(glob.main_menu)
	glob.mtv_listen_menu  = menu.new{name="MTV Listen", icon="icon_red"}
	local menu = glob.mtv_listen_menu
	menu:addItem{type="back"}
	menu:addItem{type="separatorline"}
	local d = 0 -- directkey
	for i, v in ipairs(glob.mtv) do
		d = d + 1
		local dkey = godirectkey(d)
		menu:addItem{type="forwarder", name=v.name, action="mtv_liste",enabled=true,id=i,directkey=dkey,hint=v.url}
	end
	menu:exec()
	menu:hide()
	return MENU_RETURN.EXIT_REPAINT
end

function main_menu()
	glob.main_menu  = menu.new{name="MTV", icon="icon_red"}
	local menu = glob.main_menu
	local d = 1 -- directkey

	menu:addKey{directkey=RC["info"], id=mtv_version, action="info"}
	menu:addItem{type="back"}
	menu:addItem{type="separatorline"}
	menu:addItem{type="forwarder", name="MTV Listen", action="mtv_listen_menu", enabled=true,
	id="dummy"..d, directkey=godirectkey(d),hint="MTV Listen"}
        d=d+1
	menu:addItem{type="separatorline"}
	menu:addItem{type="forwarder", name="Suche nach Künstler", action="search_artists", enabled=true,
	id="find", directkey=godirectkey(d),hint="Suche nach Künstler"}
	d=d+1
	menu:addItem{type="keyboardinput", action="setvar", id="search", name="Künstler Name:", value=conf.search,directkey=godirectkey(d),hint_icon="hint_service",hint="Nach welchem Künstler soll gesucht werden ?"}

	menu:addItem{type="separatorline"}
	d=d+1
	menu:addItem{type="forwarder", name="Einstellungen", action="setings", enabled=true,
	id="dummy"..d, directkey=godirectkey(d),hint="Einstellungen"}
	menu:exec()
end

function main()
	init()
	loadConfig()
	main_menu()
	saveConfig()
end

main()
