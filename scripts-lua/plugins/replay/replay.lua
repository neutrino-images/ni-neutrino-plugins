--[[
	Replay Plugin

	Copyright (C) 2022 Jacek Jendrzej 'satbaby'
	Copyright (C) 2022 Sven Hoefer 'vanhofen'

	License: WTFPLv2
]]

-- version 0.1 add ard

plugin_name = "Replay"

-- list duplicates
duplicates = false
--duplicates = true

-- list specific channels only
--channels = {1,14,20,12,5,15,19,7,36,3,4,33}
channels = {}

if next(channels) ~= nil then
	duplicates = true
end

json = require "json"
n = neutrino()
replayList = {}
replayMenu = nil
vPlay = video.new()
repaint = false
Title = nil
Epg = nil

locale = {}
locale["deutsch"] = {
	wait = "Bitte warten ...",
	read_data = "Lese Daten ..."
}
locale["english"] = {
	wait = "Please wait ...",
	read_data = "Read data ..."
}

neutrino_conf = configfile.new()
neutrino_conf:loadConfig("/var/tuxbox/config/neutrino.conf")
lang = neutrino_conf:getString("language", "english")
if locale[lang] == nil then
	lang = "english"
end

-- ----------------------------------------------------------------------------

function getdata(Url,Postfields,outputfile,pass_headers,httpheaders)
	if Url == nil then return nil end
	if Curl == nil then
		Curl = curl.new()
	end

	if Url:sub(1, 2) == '//' then
		Url = 'https:' .. Url
	end

	local ret, data = Curl:download{ url=Url, A="Mozilla/5.0",maxRedirs=5,followRedir=false,postfields=Postfields,header=pass_headers,o=outputfile,httpheader=httpheaders }
	if ret == CURL.OK then
		if outputfile then
			return 1
		end
		return data
	else
		return nil
	end
end

function godirectkey(d)
	if d == nil then return d end
	local _dkey = ""
	if d == 1 then
		_dkey = RC.red
	elseif d == 2 then
		_dkey = RC.green
	elseif d == 3 then
		_dkey = RC.yellow
	elseif d == 4 then
		_dkey = RC.blue
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

function hideMenu(menu)
	if menu ~= nil then
		menu:hide()
	end
end

function epgInfo(xres, yres, aspectRatio, framerate)
	local dx = n:scale2Res(800);
	local dy = n:scale2Res(450);
	local x = ((SCREEN['END_X'] - SCREEN['OFF_X']) - dx) / 2;
	local y = ((SCREEN['END_Y'] - SCREEN['OFF_Y']) - dy) / 2;

	local wh = cwindow.new{x=x, y=y, dx=dx, dy=dy, title=Title, icon="", show_footer=false};
	local ct = ctext.new{parent=wh, text=Epg, font_text=FONT['MENU'], mode="ALIGN_SCROLL | ALIGN_TOP"};
	wh:paint()

	repeat
		msg, data = n:GetInput(500)
		if msg == RC.up or msg == RC.page_up then
			ct:scroll{dir="up"};
		elseif msg == RC.down or msg == RC.page_down then
			ct:scroll{dir="down"};
		end
		msg, data = n:GetInput(500)
	until msg == RC.ok or msg == RC.home or msg == RC.info

	wh:hide()
end

function play_live(_id)
	local id = tonumber(_id)
	if replayList[id].stream == nil then
		getStream(id)
	end
	if replayList[id].stream then
		hideMenu(replayMenu)
		Title = replayList[id].title
		Epg = replayList[id].info1 .. "\n" .. replayList[id].info2
		if Title and Epg ~= "\n" then
			vPlay:setInfoFunc("epgInfo")
		end

		vPlay:PlayFile(replayList[id].name, replayList[id].stream, replayList[id].title, replayList[id].info1, replayList[id].audiostream or "")

		Title = nil
		Epg = nil
		repaint = true
		return MENU_RETURN.EXIT
	end
end

function getStream_ARD(id)
	local url = replayList[id].url
	local jdata = getdata(url)
	if jdata then
		local jnTab = json:decode(jdata)
		if jnTab and jnTab.streamurl and jnTab.diff then
			replayList[id].stream = jnTab.streamurl .. jnTab.diff .. '/manifest.mpd'
		end
	end
end

function getStream(id)
	local url = replayList[id].url
	if url and replayList[id].ch == "ard" then
		getStream_ARD(id)
	end
	return replayList[id].stream
end

function getReplayList_ARD()
	local titleList = {}
	local h = hintbox.new{caption=locale[lang].wait, text=locale[lang].read_data}
	if h then
		h:paint()
	end
	if next(channels) == nil then
		-- add all channels
		channels = {}
		for i = 1, 37 do
			table.insert(channels, i)
		end
	end
	for _, i in ipairs(channels) do
		local duplicate = false
		local subtitle = ""
		local detail = ""
		local link = 'http://itv.ard.de/replay/dyn/index.php?sid=' .. i
		local data = getdata(link)
		--if data then
		if data and string.sub(data,1,1) == "{" then
			local jnTab = json:decode(data)
			if jnTab and jnTab.diff then
				if jnTab.subtitle then
					subtitle = jnTab.subtitle
					if subtitle == "" then
						subtitle = jnTab.title
					end
				end
				if jnTab.detail then
					detail = jnTab.detail
					if detail == "" then
						detail = subtitle
					end
				end
				if duplicates == false then
					for j, v in ipairs(titleList) do
						if v.title == jnTab.title then
							duplicate = true
						end
					end
				end
				if duplicate == false then
					table.insert(titleList, {title=jnTab.title})
					table.insert(replayList, {
						name = "ARD: " .. jnTab.name,
						title = jnTab.title,
						url = link,
						stream = nil,
						audiostream = nil,
						info1 = subtitle,
						info2 = detail,
						hasVideo = true,
						ch = 'ard'})
				end
			end
		end
	end
	if h then
		h:hide()
	end
	titleList = {}
end

function mainMenu()
	if #replayList == 0 then
		return
	end

	replayMenu = menu.new{name=plugin_name, icon="streaming"}
	replayMenu:addItem{type="separator"}
	replayMenu:addItem{type="back"}
	replayMenu:addItem{type="separatorline"}
	local d = 0
	for i, v in ipairs(replayList) do
		d = d+1
		if v.hasvideo ~= nil then
			local _name = "n/a"
			local _hint = "n/a"
			if v.name ~= nil and v.name ~= "" then
				_name = v.name
			end
			if v.title ~= nil and v.title ~= "" then
				_name = _name .. " - " .. v.title
			end
			if v.info1 ~= nil and v.info1 ~= "" then
				_hint = v.info1
			end
			replayMenu:addItem{ type="forwarder",
				action="play_live",
				name=_name,
				hint=_hint,
				enabled=v.hasVideo,
				id=i,
				directkey=godirectkey(d)
			}
		end
	end
	replayMenu:exec()
	replayMenu:hide()
end

-- ----------------------------------------------------------------------------

getReplayList_ARD()

repeat
	mainMenu()
	if repaint then
		replayList = {}
		getReplayList_ARD()
		repaint = false
	end
	collectgarbage()
until repaint == false
