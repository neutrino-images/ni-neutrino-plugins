--[[
	ARD Mediathek Plugin
	Copyright (C) 2014, Michael Liebmann 'micha-bbg'
	With Help from: SatBaby, Don de Deckelwech

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
debugmode = 0 -- 0->no debug output, 1->debug output enabled, 2->debug output plus json-printout

local json = require "json"

local bor = bit and bit.bor
	or bit32 and bit32.bor
	or load[[return function(a, b) return a | b end]]()

function script_path()
	local path = (debug.getinfo(2, "S").source:sub(2))
	return path:match("(.*[/\\])")
end

ret = nil -- global return value
function key_home(a)
	ret = MENU_RETURN.EXIT
	return ret
end

function key_setup(a)
	ret = MENU_RETURN.EXIT_ALL
	return ret
end

-- ####################################################################
-- convert a image: http://websemantics.co.uk/online_tools/image_to_data_uri_convertor/
-- function from http://lua-users.org/wiki/BaseSixtyFour

-- character table string
local b='ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/'

-- decode
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
-- ####################################################################

function decodeImage(b64Image, path)
	local imgTyp = b64Image:match("data:image/(.-);base64,")
	local repData = "data:image/" .. imgTyp .. ";base64,"
	local b64Data = string.gsub(b64Image, repData, "");

	local tmpImg = os.tmpname()
	local retImg
	if path ~= nil then
		retImg = string.gsub(tmpImg, "/tmp/", path .. "/") .. "." .. imgTyp
	else
		retImg = tmpImg .. "." .. imgTyp
	end
	os.remove(tmpImg)
	local f = io.open(retImg, "w+")
	if f ~= nil then
		f:write(dec(b64Data))
		f:close()
	else
		print("Create image ["..retImg.."] failed.")
		return ""
	end

	return retImg
end

function init()
	-- set collectgarbage() interval from 200 (default) to 50
	collectgarbage('setpause', 50)

	hdsAvailable = false
--	if isNevis() == true then hdsAvailable = false end

	playQuality 			= "auto"

	livelist = {}
	firstLiveInit = true
	muteStatusNeutrino	= false
	volumeNeutrino		= 0

	n = neutrino()
	nMisc = misc.new()
	vPlay = video.new()
	bigPicBG = script_path().."ard_mediathek.jpg"
	haveBigPicBG = fileExist(bigPicBG)
	conf = {}
	confChanged 			= 0
	confFile			= "/var/tuxbox/config/ard_mediathek.conf";
	config				= configfile.new()
	loadConfig()

	baseUrl				= "https://www-origin.ardmediathek.de"
	tmpPath 			= "/tmp/ard_mediathek"
	os.execute("rm -fr " .. tmpPath)
	os.execute("sync")
	os.execute("mkdir -p " .. tmpPath)
	user_agent 			= "\"Mozilla/5.0 (Windows NT 6.1; WOW64; rv:31.0) Gecko/20100101 Firefox/31.0\""
	pluginIcon			= decodeImage("data:image/png;base64,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", tmpPath)

	selectedChannel			= ""
	selectedChannelId		= 0
	selectedTagId			= 0

	infoBox_h				= nil
	streamWindow			= nil

	setChannels()
	setTimeArea()

	local searchData_1_0 = "<div class=\"entry\" data-ctrl-"
	local searchData_1_1 = "collapse-entry=\"{"
	searchData_1 = {}
	searchData_1[1] = searchData_1_0 .. "MORGENS" .. searchData_1_1
	searchData_1[2] = searchData_1_0 .. "NACHMITTAGS" .. searchData_1_1
	searchData_1[3] = searchData_1_0 .. "VORABENDS" .. searchData_1_1
	searchData_1[4] = searchData_1_0 .. "ABENDS" .. searchData_1_1
	showBGPicture()
end

function get_timing_menu()
	local ret = 0

	local conf = io.open("/var/tuxbox/config/neutrino.conf", "r")
	if conf then
		for line in conf:lines() do
			local key, val = line:match("^([^=#]+)=([^\n]*)")
			if (key) then
				if key == "timing.menu" then
					if (val ~= nil) then
						ret = val;
					end
				end
			end
		end
		conf:close()
	end

	return ret
end

function showBGPicture()
	if haveBigPicBG then
		vPlay:zapitStopPlayBack()
		vPlay:ShowPicture(bigPicBG)
	end

	muteStatusNeutrino = nMisc:isMuted()
	volumeNeutrino = nMisc:getVolume()
	nMisc:enableMuteIcon(false)
	nMisc:AudioMute(true, false)
end

function hideBGPicture(rezap)
	if (rezap == true) then
		vPlay:channelRezap()
	end
	local rev, box = nMisc:GetRevision()
	if haveBigPicBG and rev == 1 then vPlay:StopPicture() end

	nMisc:enableMuteIcon(true)
	nMisc:AudioMute(muteStatusNeutrino, true)
	nMisc:setVolume(volumeNeutrino)
end

function setChannels()
	channels = {}
	channels[1]  = {channel = "Das Erste",                   id = 208,       enabled = true}
	channels[2]  = {channel = "tagesschau24",                id = 5878,      enabled = true}
	channels[4]  = {channel = "ONE",                         id = 673348,    enabled = true}
	channels[6]  = {channel = "BR",                          id = 2224,      enabled = true}
	channels[7]  = {channel = "HR",                          id = 5884,      enabled = true}
	channels[8]  = {channel = "MDR",                         id = 5882,      enabled = true}
	channels[9]  = {channel = "MDR Thüringen",               id = 1386988,   enabled = false}
	channels[10] = {channel = "MDR Sachsen-Anhalt",          id = 1386898,   enabled = false}
	channels[11] = {channel = "MDR Sachsen",                 id = 1386804,   enabled = false}
	channels[12] = {channel = "NDR",                         id = 5906,      enabled = true}
	channels[13] = {channel = "NDR Hamburg",                 id = 21518348,  enabled = false}
	channels[14] = {channel = "NDR Mecklenburg-Vorpommern",  id = 21518350,  enabled = false}
	channels[15] = {channel = "NDR Niedersachsen",           id = 21518352,  enabled = false}
	channels[16] = {channel = "NDR Schleswig-Holstein",      id = 21518354,  enabled = false}
	channels[17] = {channel = "RB",                          id = 5898,      enabled = true}
	channels[18] = {channel = "RBB",                         id = 5874,      enabled = true}
	channels[21] = {channel = "SR",                          id = 5870,      enabled = true}
	channels[22] = {channel = "SWR",                         id = 5310,      enabled = true}
	channels[23] = {channel = "SWR Rheinland-Pfalz",         id = 5872,      enabled = false}
	channels[24] = {channel = "SWR Baden-Württemberg",       id = 5904,      enabled = false}
	channels[25] = {channel = "WDR",                         id = 5902,      enabled = true}
	channels[26] = {channel = "ARD-alpha",                   id = 5868,      enabled = true}
	channels[27] = {channel = "KiKa",                        id = 5886,      enabled = true}
end

function setTimeArea()
	timeArea = {}
	timeArea[1] = "00:00-12:00 Uhr"
	timeArea[2] = "12:00-18:00 Uhr"
	timeArea[3] = "18:00-20:15 Uhr"
	timeArea[4] = "20:15-00:00 Uhr"
end

function getFirstMenu()
	m_modes = menu.new{name=langStr_caption .. ": " .. langStr_modeSelection, icon=pluginIcon};
	m_modes:addKey{directkey=RC["home"], id="home", action="key_home"}
	m_modes:addKey{directkey=RC["setup"], id="setup", action="key_setup"}
	m_modes:addItem{type="separator"};

	m_modes:addItem{type="forwarder", name=langStr_programMissed, action="programMissedMenu1", icon=1, directkey=RC["1"]};
	m_modes:addItem{type="forwarder", name="Livestreams", enabled=true, action="livestreamsMenu", icon=2, directkey=RC["2"]};

	m_modes:addItem{type="separatorline"};
	m_modes:addItem{type="forwarder", name=langStr_options, action="setOptions", id="-2", icon="blau", directkey=RC["blue"]};

	m_modes:exec()
end

function programMissedMenu1()
	hideMenu(m_modes)
	m_channels = menu.new{name=langStr_caption .. ": " .. langStr_programMissed, icon=pluginIcon};
	m_channels:addItem{type="subhead", name=langStr_channelSelection};
	m_channels:addItem{type="separator"};
	m_channels:addItem{type="back"};
	m_channels:addItem{type="separatorline"};

	m_channels:addKey{directkey=RC["home"], id="home", action="key_home"}
	m_channels:addKey{directkey=RC["setup"], id="setup", action="key_setup"}

	for index, channelDetail in pairs(channels) do
		if channelDetail.enabled == true then
			m_channels:addItem{type="forwarder", action="programMissedMenu2", id=channelDetail.id, name=channelDetail.channel};
		end
	end

	m_channels:exec()

	if ret == MENU_RETURN.EXIT_ALL then
		return ret
	end
	return MENU_RETURN.REPAINT;
end

function saveData(name, data)
	local f = io.open(name, "w+")
	if f then
		f:write(data)
		f:close()
	end
end


function read_file(filename)
	local fp = io.open(filename, "r")
	if fp == nil then error("Error opening file '" .. filename .. "'.") end
	local data = fp:read("*a")
	fp:close()
	return data
end


function sleep(a)
	local sec = tonumber(os.clock() + a)
	while (os.clock() < sec) do
	end
end


function getdata(Url,outputfile)
	if Url == nil then return nil end
	if Curl == nil then
		Curl = curl.new()
	end

	if Url:sub(1, 2) == '//' then
		Url =  'https:' .. Url
	end

	local ret, data = Curl:download{url=Url,A="Mozilla/5.0;",connectTimeout=5,maxRedirs=5,followRedir=true,o=outputfile }
	if ret == CURL.OK then
		if outputfile then
			return 1
		end
		return data
	else
		return nil
	end
end

function getLiveList()
	local data = getdata(baseUrl .. "/tv/live")
	if data then
		local ids= {}
		for link in data:gmatch('(/tv/%S+/live%?kanal=%d+)"') do
			local id = link:match('kanal=(%d+)')
			if ids[id] ~= true then
				ids[id] = true
				local channel = link:match('/tv/(%S+)/live%?kanal=%d+')
				table.insert(livelist,{name=channel, url=link, stream=nil,audiostream=nil})
			end
		end
	end
end

function getMaxVideoRes()
	local maxRes = 1920
	local quali = tonumber(conf.streamQuality)
	if quali == 3 then
		maxRes = 1280
	elseif quali == 2 then
		maxRes = 960
	elseif quali == 1 then
		maxRes = 640
	elseif quali == 0 then
		maxRes = 480
	end
	return maxRes
end

function getVideoUrlM3U8(m3u8_url)
	if m3u8_url == nil then return nil end
	local res = 0
	local videoUrl = nil
	local audioUrl = nil
	local data = getdata(m3u8_url)
	if data then
		local host = m3u8_url:match('([%a]+[:]?//[_%w%-%.]+)/')
		local lastpos = (m3u8_url:reverse()):find("/")
		local hosttmp = m3u8_url:sub(1,#m3u8_url-lastpos)
		if hosttmp then
			host = hosttmp .."/"
		end
		local revision = 0
		if APIVERSION ~= nil and (APIVERSION.MAJOR > 1 or ( APIVERSION.MAJOR == 1 and APIVERSION.MINOR > 82 )) then
			revision = nMisc:GetRevision()
		end

		local audio_url = nil
		if revision == 1 then -- separate audio for hd51 and co
			local Nconfig	= configfile.new()
			local lang1,lang2,lang3 = nil,nil,nil
			Nconfig:loadConfig("/var/tuxbox/config/neutrino.conf")
			lang1 = Nconfig:getString("pref_lang_0", "#")
			lang2 = Nconfig:getString("pref_lang_1", "#")
			lang3 = Nconfig:getString("pref_lang_2", "#")
			if lang1 == "#" then lang1 = nil else lang1 = lang1:lower() lang1 = lang1:sub(1,3) end
			if lang2 == "#" then lang2 = nil else lang2 = lang2:lower() lang2 = lang2:sub(1,3) end
			if lang3 == "#" then lang3 = nil else lang3 = lang3:lower() lang3 = lang3:sub(1,3) end
			if lang1 == nil then
				lang1 = Nconfig:getString("language", "english")
				if lang1 == nil then
					lang1 = "eng"
				else
					lang1 = lang1:lower() lang1 = lang1:sub(1,3)
				end
			end

			local l1,l2,l3,l4,l = nil,nil,nil,nil,nil
			for adata in data:gmatch('TYPE%=AUDIO.GROUP%-ID=".-",(.-)\n') do
				local lname = adata:match('NAME="(.-)"')
				local lang = adata:match('LANGUAGE="(.-)"')
				local aurl = adata:match('URI="(.-)"')
				if aurl then
					local low_lang = lang:lower()
					if l1 == nil and lname and lang1 and low_lang == lang1 then
						l1 = aurl
					elseif l2 == nil and lname and lang2 and low_lang == lang2 then
						l2 = aurl
					elseif l3 == nil and lname and lang3 and low_lang == lang3 then
						l3 = aurl
					elseif l4 == nil and lname and low_lang == "deu" then
						l4 = aurl
					elseif l == nil then
						l = aurl
					end
				end
			end
			audio_url = l1 or l2 or l3 or l4 or l
		end
		local first = true
		local maxRes = getMaxVideoRes()
		for band, res1, res2, url in data:gmatch('BANDWIDTH=(%d+).-RESOLUTION=(%d+)x(%d+).-\n(.-)\n') do
			if url and res1 then
				local nr = tonumber(res1)
				if (nr <= maxRes and nr > res) or first then
					first = false
					res=nr
					if host and url:sub(1,4) ~= "http" then
						url = host .. url
					end
					if audio_url and host and audio_url:sub(1,4) ~= "http" then
						audio_url = host .. audio_url
					end
					videoUrl  = url
					audioUrl  = audio_url
				end
			end
		end
	else
		return m3u8_url, nil
	end
	return videoUrl, audioUrl
end

function getLiveStream(id)
	local url = livelist[id].url
	local data = getdata(baseUrl .. url)
	if data then
		local pat1 = "/play/media/"
		local chid = data:match( pat1 .. '(%d+)')
		local jdata = getdata(baseUrl .. pat1 .. chid .. '?devicetype=pc&features=flash')
		if jdata then
			local jnTab = json:decode(jdata )
			if jnTab and jnTab._mediaArray[1] and jnTab._mediaArray[1] and jnTab._mediaArray[1]._mediaStreamArray[1] 
			and jnTab._mediaArray[1]._mediaStreamArray[1]._stream then
				livelist[id].stream , livelist[id].audiostream = getVideoUrlM3U8(jnTab._mediaArray[1]._mediaStreamArray[1]._stream)
			end
		end
	end
	return livelist[id].stream
end

function play_live(_id)
	local id = tonumber(_id)
	if livelist[id].stream == nil then
		livelist[id].stream = getLiveStream(id)
	end
	if livelist[id].stream then
		hideMenu(live_listen_menu)
		hideBGPicture(false)
		vPlay:PlayFile(livelist[id].name, livelist[id].stream, "Live","",livelist[id].audiostream or "")
		collectgarbage();
		showBGPicture()
	end
end

function livestreamsMenu()
	if firstLiveInit then
		firstLiveInit = false
		getLiveList()
	end
	if #livelist == 0 then
		return
	end
	hideMenu(m_modes)
	live_listen_menu  = menu.new{name="Live", icon=pluginIcon}
	local menu = live_listen_menu
	menu:addItem{type="back"}
	menu:addItem{type="separatorline"}
	for i, v in ipairs(livelist) do
		menu:addItem{type="forwarder", name=v.name, action="play_live",enabled=true,id=i}
	end
	menu:exec()
	menu:hide()
	return MENU_RETURN.EXIT_REPAINT
end

function makeAreaFileName(cId, tId, area)
	local tmpDataBody = tmpPath .. "/data1_" .. cId .. "_" .. tId
	return tmpDataBody .. "_area" .. area .. ".htm"
end

function getTmpData1(selectedChannelId, tagId)
	local tmpDataBody = tmpPath .. "/data1_" .. selectedChannelId .. "_" .. tagId
	local tmpData = tmpDataBody .. ".htm"

	local tmpDataArea1 = makeAreaFileName(selectedChannelId, tagId, 1)
	local tmpDataArea2 = makeAreaFileName(selectedChannelId, tagId, 2)
	local tmpDataArea3 = makeAreaFileName(selectedChannelId, tagId, 3)
	local tmpDataArea4 = makeAreaFileName(selectedChannelId, tagId, 4)

	if fileExist(tmpData) ~= true then
		paintInfoBox(langStr_contentLoad)
		local tmp1
		if tagId == 0 then
			tmp1 = selectedChannelId
		else
			tmp1 = selectedChannelId .. "&tag=" .. tagId
		end
		if debugmode >= 1 then print("[getTmpData1] "  .. tmpData .. " '" .. baseUrl .. "/tv/sendungVerpasst?kanal=" .. tmp1 .. "'"); end
		getdata(baseUrl .. "/tv/sendungVerpasst?kanal=" .. tmp1,tmpData)
		if fileExist(tmpData) == false then return end
		local s = read_file(tmpData)

		local i
		local sLen = #s
		local tmpPos = {}
		for i = 1, 4 do
			tmpPos[i] = nMisc:strFind(s, searchData_1[i])
		end
		local p1, p2
		local area
		local rest = 0

		-- Area1
		if tmpPos[1] ~= nil then
			p1 = tmpPos[1]
			rest = p1
			if tmpPos[2] ~= nil then
				p2 = tmpPos[2]
			elseif tmpPos[3] ~= nil then
				p2 = tmpPos[3]
			elseif tmpPos[4] ~= nil then
				p2 = tmpPos[4]
			else
				p2 = sLen
			end
			p2 = p2-p1-1;
			area = nMisc:strSub(s, p1, p2)
			saveData(tmpDataArea1, area);
		end

		-- Area2
		if tmpPos[2] ~= nil then
			p1 = tmpPos[2]
			if rest == 0 then rest = p1 end
			if tmpPos[3] ~= nil then
				p2 = tmpPos[3]
			elseif tmpPos[4] ~= nil then
				p2 = tmpPos[4]
			else
				p2 = sLen
			end
			p2 = p2-p1-1;
			area = nMisc:strSub(s, p1, p2)
			saveData(tmpDataArea2, area);
		end

		-- Area3
		if tmpPos[3] ~= nil then
			p1 = tmpPos[3]
			if rest == 0 then rest = p1 end
			if tmpPos[4] ~= nil then
				p2 = tmpPos[4]
			else
				p2 = sLen
			end
			p2 = p2-p1-1;
			area = nMisc:strSub(s, p1, p2)
			saveData(tmpDataArea3, area);
		end

		-- Area4
		if tmpPos[4] ~= nil then
			p1 = tmpPos[4]
			if rest == 0 then rest = p1 end
			p2 = sLen
			p2 = p2-p1-1;
			area = nMisc:strSub(s, p1, p2)
			saveData(tmpDataArea4, area);
		end

		if rest > 0 then
			-- reducing file size
			area = nMisc:strSub(s, 0, rest)
			fp = io.open(tmpData, "w")
			fp:seek("set")
			fp:write(area)
			fp:close()
		end

		hideInfoBox()
	end
	return tmpData
end

function checkAreaIsActiv(selectedChannelId, tagId)
	getTmpData1(selectedChannelId, tagId)

	local lRet = {}
	local i
	for i = 1, 4 do
		local tmpDataArea = makeAreaFileName(selectedChannelId, tagId, i)
		lRet[i] = fileExist(tmpDataArea)
	end

	return lRet
end

function miniMatch(s, s1, s2, p)
	local p1 = nMisc:strFind(s, s1, p)
	if p1 == nil then return nil end
	p1 = p1 + #s1
	local p2 = nMisc:strFind(s, s2, p1)
	if p2 == nil then return nil end
	local ret = nMisc:strSub(s, p1, p2-p1)
	local endpos = p2 + #s2
	return ret, endpos
end

function miniGMatch(s, s1, s2, p)
	local lRet = {}
	local i = 1
	local m = ""
	local p1 = p-1, p2
	repeat
		p1 = nMisc:strFind(s, s1, p1+1)
		if p1 == nil then break end
		p1 = p1 + #s1
		p2 = nMisc:strFind(s, s2, p1)
		if p2 == nil then break end
		m = nMisc:strSub(s, p1, p2-p1)
		if m ~= nil then
			lRet[i] = m
			i = i + 1
		end
	until m == ""
	return lRet
end

function listMissingContent(selectedChannelId, tagId, areaId)
	tmpData = getTmpData1(selectedChannelId, tagId)

	local tmpDataArea = makeAreaFileName(selectedChannelId, tagId, areaId)
	if fileExist(tmpDataArea) == false then return end
	local s = read_file(tmpDataArea)

	local lRet = {}
	local p = -1
	local count = 1
	-- Anzahl StreamGruppen
	repeat
		p = nMisc:strFind(s, searchData_1[areaId], p+1)
		if p ~= nil then
			lRet[count] = {pos=p}
			count = count + 1
		end
	until p == nil

	if count > 1 then
		local i
		count = 1
		local old_dId = 0
		for i = 1, #lRet do
			p = lRet[i].pos
			if i < #lRet then
				nextP = lRet[i+1].pos
			else
				nextP = #s
			end
			local data = s:sub(p,nextP)
			local d, p = miniMatch(data, "<span class=\"date\">", "</span>", 0)
			local t, p = miniMatch(data, "<span class=\"titel\">", "</span>", p)
			if t == nil then t = "" end
			t = conv_str(t)
			local dId, p = miniMatch(data, "documentId=", '" class=', p)
			if old_dId ~= dId then
				old_dId = dId
				if d == nil then d = "" end
				if t == nil then t = "" end
				local tmpName, tmpValue = getPrevDate(tagId)
				lRet[count] = {date=d, title=t, id=dId, prev_wd=tmpName, prev_date=tmpValue}
				count = count + 1
			end

			local count2 = 1
			local im, vi, hl, st
			local mandant = data:match('##width##(?%w+=%w+)&#039;')
			if mandant ==  nil then
				mandant=""
			end
			lRet[i].streams = {}
			repeat
				if p == nil or p > nextP then break end
				im, p = miniMatch(data, "urlScheme&#039;:&#039;", "##width##" .. mandant .. "&#039;}\"/>", p)
				if p == nil or p > nextP then break end
				dId, p = miniMatch(data, "documentId=", '" class=', p)
				if p == nil or p > nextP then break end
				hl, p = miniMatch(data, "<h4 class=\"headline\">", "</h4>", p)
				if p == nil or p > nextP then break end
				hl = conv_str(hl)
				st, p = miniMatch(data, "<p class=\"subtitle\">", "</p>", p)
				if p == nil or p > nextP then break end
				st = conv_str(st)
				st = string.gsub(st, " | UT", "");
				if im and dId and hl and st then
					lRet[i].streams[count2] = {image=im, id=dId, headline=hl, subtitle=st}
				else
					print("possible parse error, check: " .. tmpDataArea)
				end
				count2 = count2 + 1
			until p == nil or p > nextP or count2 > 10
			lRet[i].streamCount = count2 - 1
		end
	end
	return lRet
end

function checkDayIsActiv(selectedChannelId, tagId)
	tmpData = getTmpData1(selectedChannelId, tagId)

	local lRet = {}
	local i
	for i = 1, 7 do
		lRet[i] = false
	end
	lRet[1] = true
	if fileExist(tmpData) == false then
		if tagId == 0 then
			for i = 1, 7 do
				lRet[i] = true
			end
			lRet[1] = false
		end
		return lRet
	end

	local s = read_file(tmpData)

	local r = miniGMatch(s, "?kanal=" .. selectedChannelId .. "&amp;tag=", "\">", 0)
	for i = 1, 7 do
		if r[i] ~= nil and string.len(r[i]) < 3 then 
			lRet[tonumber(r[i])+1] = true
		end
	end
	return lRet
end

function programMissedMenu2(_id)
	local cId = tonumber(_id);
	selectedChannel = ""
	selectedChannelId = 0
	hideMenu(m_channels)

	for index, channelDetail in pairs(channels) do
		if channelDetail.id == cId then
			selectedChannel   = channelDetail.channel
			selectedChannelId = channelDetail.id
			break
		end
	end

	m_missed = menu.new{name=langStr_caption .. ": " .. langStr_programMissed, icon=pluginIcon};

	m_missed:addKey{directkey=RC["home"], id="home", action="key_home"}
	m_missed:addKey{directkey=RC["setup"], id="setup", action="key_setup"}
	m_missed:addItem{type="subhead", name=selectedChannel};
	m_missed:addItem{type="separator"};
	m_missed:addItem{type="back"};
	m_missed:addItem{type="separatorline"};

	local isActiv = checkDayIsActiv(cId, 0)

	local i
	for i = 1, 7 do
		local m_name, m_value = getPrevDate(i-1)
		m_missed:addItem{type="forwarder", name=m_name, value=m_value, enabled=isActiv[i], action="programMissedMenu3", id=i-1, icon=i, directkey=RC[tostring(i)]};
	end

	m_missed:exec()

	if ret == MENU_RETURN.EXIT_ALL then
		return ret
	end
	return MENU_RETURN.REPAINT;
end

function programMissedMenu3(_id)
	selectedTagId = tonumber(_id);
	hideMenu(m_missed)

	m_missed3 = menu.new{name=langStr_caption .. ": " .. langStr_programMissed, icon=pluginIcon};

	m_missed3:addKey{directkey=RC["home"], id="home", action="key_home"}
	m_missed3:addKey{directkey=RC["setup"], id="setup", action="key_setup"}

	local m_name, m_value = getPrevDate(selectedTagId)
	m_missed3:addItem{type="subhead", name=selectedChannel .. " / " .. m_name .. ", " .. m_value};
	m_missed3:addItem{type="separator"};
	m_missed3:addItem{type="back"};
	m_missed3:addItem{type="separatorline"};

	local isActiv = checkAreaIsActiv(selectedChannelId, selectedTagId)

	local i
	for i = 1, #timeArea do
		m_missed3:addItem{type="forwarder", name=timeArea[i], enabled=isActiv[i], action="programMissedMenu4", id=i, icon=i, directkey=RC[tostring(i)]};
	end

	m_missed3:exec()

	if ret == MENU_RETURN.EXIT_ALL then
		return ret
	end
	return MENU_RETURN.REPAINT;
end

function programMissedMenu4(_id)
	local cId = tonumber(_id);
	hideMenu(m_missed3)

	m_missed4 = menu.new{name=langStr_caption .. ": " .. langStr_programMissed, icon=pluginIcon};

	m_missed4:addKey{directkey=RC["home"], id="home", action="key_home"}
	m_missed4:addKey{directkey=RC["setup"], id="setup", action="key_setup"}

	local m_name, m_value = getPrevDate(selectedTagId)
	m_missed4:addItem{type="subhead", name=selectedChannel .. " / " .. m_name .. ", " .. m_value .. ", " .. timeArea[cId]};
	m_missed4:addItem{type="separator"};
	m_missed4:addItem{type="back"};
	m_missed4:addItem{type="separatorline"};

	listContent = listMissingContent(selectedChannelId, selectedTagId, cId)
	local i
	for i = 1, #listContent do
		if i < 10 then
			_icon = i
			_directkey = RC[tostring(i)]
		elseif i == 10 then
			_icon = 0
			_directkey = RC["0"]
		else
			_icon = ""
			_directkey = ""
		end
		local stream_active = true
		if listContent[i].streamCount == 0 then stream_active = false end
		m_missed4:addItem{type="forwarder",enabled=stream_active, value=listContent[i].date, name=listContent[i].title, action="listStreams", id=i, icon=_icon, directkey=_directkey};
	end

	m_missed4:exec()

	if ret == MENU_RETURN.EXIT_ALL then
		return ret
	end
	return MENU_RETURN.REPAINT;
end

function paintFrame(x, y, w, h, f, c)
	-- top
	n:PaintBox(x-f, y-f, w+(f*3), f, c, CORNER.RADIUS_LARGE, bor(CORNER.TOP_LEFT, CORNER.TOP_RIGHT))
	-- right
	n:PaintBox(x+w+f, y, f, h, c)
	-- bottom
	n:PaintBox(x-f, y+h, w+(f*3), f, c, CORNER.RADIUS_LARGE, bor(CORNER.BOTTOM_LEFT, CORNER.BOTTOM_RIGHT))
	-- left
	n:PaintBox(x-f, y, f, h, c)
end

function paintListContent(x, y, w, h, dId, aStream, tmpAStream)
	local relH = h - (streamWindow:headerHeight() + streamWindow:footerHeight())
	local headerH = streamWindow:headerHeight()

	local btH = 6
	local btV = 7
	local boxAnzH = 3
	local boxAnzV = 2
	local spAnzH = boxAnzH+1
	local spAnzV = boxAnzV+1
	local gesH = boxAnzH*btH + spAnzH
	local gesV = boxAnzV*btV + spAnzV

	local boxSpacerX = math.floor(w/gesH + 0.5)
	local boxSpacerY = math.floor(relH/gesV + 0.5)
	local boxW = boxSpacerX * btH
	local boxH = boxSpacerY * btV

	local i1, i2
	local aktBox = 1
	local break2 = false

	local colBgActiv   = COL.MENUCONTENTSELECTED_PLUS_0
	local colBgBack    = COL.MENUCONTENT
	local colTextActiv = COL.MENUCONTENTSELECTED_TEXT
	local colText      = COL.MENUCONTENT_TEXT
	local colFrame     = COL.MENUCONTENT_PLUS_6
	local colBgTmp     = colBgBack

	fontHeight = n:FontHeight(FONT.MENU)

	for i1 = 1, 2 do
		for i2 = 1, 3 do
			if aktBox == aStream then
				colBgTmp   = colBgActiv
			else
				colBgTmp   = colBgBack
			end

			local hl      = listContent[dId].streams[aktBox].headline
			local st      = listContent[dId].streams[aktBox].subtitle
			local picName = tmpPath .. "/" .. string.gsub(listContent[dId].streams[aktBox].image, "/", "_") .. ".jpg"
			local picUrl  = --[[baseUrl .. ]]listContent[dId].streams[aktBox].image .. "320"

			local boxX = x + boxSpacerX * i2 + boxW * (i2-1)
			local boxY = y + headerH + boxSpacerY * i1 + boxH * (i1-1)
			local frameX = boxX - SCREEN.OFF_X
			local frameY = boxY - SCREEN.OFF_Y

			if fileExist(picName) == false then
				if debugmode >= 1 then printf("#####[ard_mediathek] %s '%s'", picName, picUrl); end
				local ok = getdata(picUrl, picName)
				if haveBigPicBG and ok == nil then
						picName = bigPicBG
				end
			end

			-- Number of lines Text1
			local lines1 = 2

			local txtX = 4
			local txtY = boxH
			local txtW = boxW-8
			local txtH = fontHeight

			local txtY1 = txtY-fontHeight*(lines1+1)
			local txtY2 = txtY-fontHeight
			local txtH1 = fontHeight*lines1
			local txtH2 = fontHeight

			local picWmax = boxW
			local picHmax = boxH - txtH1 - txtH2 - fontHeight/2

			local picX = n:scale2Res(8)
			local picY = n:scale2Res(8)
			if tmpAStream == -1 or tmpAStream == -2 then
				local tmpTxt
				if (n:getRenderWidth(FONT.MENU, hl) > txtW) then
					local pos=0
					local text_w=0
					local old_pos
					local tmpTxt1, tmpTxt2
					for i1 = 1, #hl do
						old_pos = pos
						pos = string.find(hl, "[ .!?,-]", pos+1)
						tmpTxt1 = string.sub(hl, 1, pos)
						text_w = n:getRenderWidth(FONT.MENU, tmpTxt1)
						if text_w > txtW then
							tmpTxt1 = string.sub(hl, 1, old_pos)
							break
						end
					end
					tmpTxt2 = string.sub(hl, old_pos+1)
					tmpTxt = tmpTxt1 .. "\n" .. tmpTxt2
				else
					tmpTxt = hl
				end
				local w1 = cwindow.new{x=boxX, y=boxY, dx=boxW, dy=boxH, show_header=false, show_footer=false, color_body=colBgBack}
				ctext.new{parent=w1, x=txtX, y=txtY1, dx=txtW, dy=txtH1, text=tmpTxt, color_text=colText, color_body=colBgBack, mode="ALIGN_CENTER ALIGN_BOTTOM ALIGN_NO_AUTO_LINEBREAK"}
				ctext.new{parent=w1, x=txtX, y=txtY2, dx=txtW, dy=txtH2, text=st, color_text=colText, color_body=colBgBack, mode="ALIGN_CENTER ALIGN_TOP"}
				cpicture.new{parent=w1, x=picX, y=picY , dx=picWmax, dy=picHmax, image=picName}
				w1:paint{do_save_bg=false}
				if (aStream == aktBox) then
					local colBgAkt = colBgTmp
					if tmpAStream == -2 then
						colBgAkt = COL.RED
					end
					paintFrame(frameX, frameY, boxW, boxH, 12, colBgAkt)
				end
			else
				if ((aStream == aktBox) or (tmpAStream == aktBox)) then
					paintFrame(frameX, frameY, boxW, boxH, 12, colBgTmp)
				end
			end
			aktBox = aktBox + 1
			if aktBox > listContent[dId].streamCount then
				break2 = true
				break
			end
		end
		if break2 == true then break end
	end
end

function changeSel(msg, streamCount, activStream)
	if (msg == RC.right) then
		activStream = activStream + 1
	elseif (msg == RC.left) then
		activStream = activStream - 1
	elseif (msg == RC.down) then
		activStream = activStream + 3
	elseif (msg == RC.up) then
		activStream = activStream - 3
	end
	if activStream > streamCount then activStream = 1 end
	if activStream < 1 then activStream = streamCount end
	return activStream
end

function changePage(msg, id)
	if (msg == RC.page_down) then
		id = id + 1
	elseif (msg == RC.page_up) then
		id = id - 1
	end
--	if id > #listContent then id = 1 end
--	if id < 1 then id = #listContent end
	if id > #listContent then id = #listContent end
	if id < 1 then id = 1 end
	return id
end

function newWinListContent(x, y, w, h, _id)
	local dId = tonumber(_id);

	local tmpStr = " stream"
	if listContent[dId].streamCount == 1 then
		tmpStr = tmpStr..")"
	else
		tmpStr = tmpStr.."s)"
	end
	local wRet = cwindow.new{x=x, y=y, dx=w, dy=h, 
			name=langStr_caption..", "..selectedChannel..": "..listContent[dId].title.." - "..listContent[dId].prev_wd.." "..listContent[dId].prev_date..", "..listContent[dId].date.." (#"..dId.."/"..#listContent..", "..listContent[dId].streamCount..tmpStr, 
			icon=pluginIcon};
	wRet:paint{do_save_bg=true}
	return wRet
end

function listStreams(_id)
	local dId = tonumber(_id);
	hideMenu(m_missed4)

--	full screen
	local x = SCREEN.OFF_X
	local y = SCREEN.OFF_Y
	local w = SCREEN.END_X - x
	local h = SCREEN.END_Y - y

	streamWindow = newWinListContent(x, y, w, h, dId)
	local activStream = 1
	paintListContent(x, y, w, h, dId, activStream, -1)

	local i = 0
	local d = 500 -- ms
	local t = (get_timing_menu() * 1000) / d
	if t == 0 then
		t = -1 -- no timeout
	end
	repeat
		i = i + 1
		local msg, data = n:GetInput(d)
		if msg >= RC["0"] and msg <= RC.MaxRC then
			i = 0 -- reset timeout
		end
		if (msg == RC.right) or (msg == RC.left) or (msg == RC.up) or (msg == RC.down) then
			local tmp = activStream
			activStream = changeSel(msg, listContent[dId].streamCount, activStream)
			if tmp ~= activStream then
				paintListContent(x, y, w, h, dId, activStream, tmp)
			end
		elseif (msg == RC.page_up) or (msg == RC.page_down) then
			local tmp = dId
			dId = changePage(msg, dId)
			if tmp ~= dId then
				if streamWindow ~= nil then streamWindow:hide{} end
				streamWindow = newWinListContent(x, y, w, h, dId)
				activStream = 1
				paintListContent(x, y, w, h, dId, activStream, -1)
			end
		elseif (msg == RC.ok) then
			getStream(listContent[dId].streams[activStream].id)
			streamWindow = newWinListContent(x, y, w, h, dId)
			paintListContent(x, y, w, h, dId, activStream, -1)
		elseif (msg == RC.record) then
			if conf.dlPath and conf.dlPath ~= "/" and conf.dlPath:sub(-4) ~= "/tmp" then
				local dls  = "/tmp/.ard_dl.sh"
				local fh = filehelpers.new()
				if fh:exist(dls, "f") == false then
					local recActiv = -1
					local dl = getStream(listContent[dId].streams[activStream].id, true)
						if dl then
						if dl_stream(dl) then
							recActiv = -2
						end
					end
					streamWindow = newWinListContent(x, y, w, h, dId)
					paintListContent(x, y, w, h, dId, activStream, recActiv)
				else
					paintInfoBox(langStr_DLWait)
					sleep(2)
					hideInfoBox()
				end
			end
		end
		ret = msg
	until msg == RC.home or msg == RC.setup or i == t;

	if streamWindow ~= nil then streamWindow:hide{} end
	if ret == RC.setup then
		return MENU_RETURN.EXIT_ALL
	end
	return MENU_RETURN.REPAINT
end

function toUcode(s)
	s=s:gsub("'","&apos;")
	s=s:gsub("<","&lt;")
	s=s:gsub(">","&gt;")
	s=s:gsub('"',"&quot;")
	s=s:gsub("\x0a","&#x0a;")
	s=s:gsub("\x0d","&#x0d;")
	s=s:gsub("&","&amp;")
	return s
end

function writeXML(ch, title, info1, info2, quali, filename)
	ch = ch or ""
	title = title or ""
	info1 = info1 or ""
	info2 = info2 or ""
	quali = quali or "0"
local xml='<?xml version="1.0" encoding="UTF-8"?>\
\
<neutrino commandversion="1">\
	<record command="record">\
		<channelname>' .. ch .. '</channelname>\
		<epgtitle>' .. toUcode(title) .. '</epgtitle>\
		<id>0</id>\
		<info1>' .. toUcode(info1) .. '</info1>\
		<info2>' .. info2 .. '</info2>\
		<epgid>0</epgid>\
		<mode>1</mode>\
		<videopid>0</videopid>\
		<videotype>1</videotype>\
		<audiopids>\
			<audio pid="1" audiotype="0" selected="0" name=""/>\
		</audiopids>\
		<vtxtpid>0</vtxtpid>\
		<genremajor>0</genremajor>\
		<genreminor>0</genreminor>\
		<seriename></seriename>\
		<length>0</length>\
		<productioncountry></productioncountry>\
		<productiondate>0</productiondate>\
		<rating>0</rating>\
		<quality>' .. quali .. '</quality>\
		<parentallockage>0</parentallockage>\
		<dateoflastplay>0</dateoflastplay>\
		<bookmark>\
			<bookmarkstart>0</bookmarkstart>\
			<bookmarkend>0</bookmarkend>\
			<bookmarklast>0</bookmarklast>\
			<bookmarkuser bookmarkuserpos="0" bookmarkusertype="0" bookmarkusername=""/>\
		</bookmark>\
	</record>\
</neutrino>\n'

	local file = io.open(filename,'w')
	file:write(xml)
	file:close()
end

function dl_stream(dl)
	if dl and dl.streamUrl and dl.streamUrl:sub(-4) == ".mp4" then
		local dlname = nil
		if dl.ch and dl.name and dl.date and dl.info1 then
			dlname = dl.ch .. "_" .. dl.name .. "_" .. dl.info1 .. "_" .. dl.date
			dlname = dlname:gsub("[%p%s/]", "_")
		end
		if dlname then
			local dls  = "/tmp/.ard_dl.sh"
			local filenamexml = "/tmp/.ard_dl_xml"
			writeXML(dl.ch, dl.name, dl.info1, dl.info2, dl.quali, filenamexml)
			dlname = conf.dlPath .. "/" .. dlname
			local script=io.open(dls,"w")
-- write script
			script:write
(
'echo "download start" ; \
wget -q --continue ' .. dl.streamUrl .. ' -O ' .. dlname .. '.mp4 ; \
if [ $? -eq 0 ]; then \
	wget -q http://127.0.0.1/control/message?popup="Video ' .. dl.name .. ' wurde heruntergeladen." -O /dev/null ; \
	mv ' .. filenamexml .. ' ' .. dlname .. '.xml ; \
else \
	wget -q http://127.0.0.1/control/message?popup="Download ' .. dl.name .. ' FEHLGESCHLAGEN" -O /dev/null ; \
	rm ' .. filenamexml .. ' ; \
fi \
rm ' .. dls .. '; \n'
)
---
			script:close()
			os.execute('sh ' .. dls .. ' &')
			return true
		end
	end
	return false
end

function getStream(_id, dlmode)
	local tmpId = tonumber(_id);
	if streamWindow ~= nil then streamWindow:hide{} end

	local id1 = 0
	local id2 = 0
	local i1, i2
	local break2 = false
	for i1 = 1, #listContent do
		for i2 = 1, listContent[i1].streamCount do
			if tmpId == tonumber(listContent[i1].streams[i2].id) then
				id1 = i1
				id2 = i2
				break2 = true
				break
			end
			if break2 == true then break end
		end
	end
	if debugmode >= 1 then
		printf("#####[ard_mediathek] tmpId: %d, id1: %d, id2: %d", tmpId, id1, id2)
	end
	local title    = listContent[id1].title
	local headline = listContent[id1].streams[id2].headline
	local infoline = listContent[id1].prev_wd.." "..listContent[id1].prev_date..", "..listContent[id1].date.." ("..selectedChannel..")"
	local dId      = listContent[id1].streams[id2].id

	local tmpData = tmpPath .. "/json1_" .. dId .. ".txt"
	if fileExist(tmpData) ~= true then
		paintInfoBox(langStr_contentLoad)
		if debugmode >= 1 then print("[getStream] "  .. tmpData .. " '" .. baseUrl .. "/play/media/" .. dId .. "?devicetype=pc&features=flash'"); end
		getdata(baseUrl .. "/play/media/" .. dId .. "?devicetype=pc&features=flash", tmpData)
	end

	local streamUrl = "x"
	local streamQuality = "-1"

	if fileExist(tmpData) == false then hideInfoBox() return end
	local s = read_file(tmpData)

	local j_table = json:decode(s)
	if debugmode == 2 then
		print("#####[ard_mediathek] Inhalt von j_table:")
		tprint(j_table,0)
		print("#####[ard_mediathek] Ende von j_table")
	end
	local j_type = j_table._type
	if j_type == "video" then

		-- test for evaluation geo blocking
		local j_geoblocked = j_table.geoblocked
		if j_geoblocked == true then
			paintInfoBox("geoblocked: " .. tostring(j_geoblocked) .. "???\nPlease info the plugin author.")
			sleep(5)
			hideInfoBox()
			return
		end

		local j_isLive		= j_table._isLive
		local j_defaultQuality	= j_table._defaultQuality
		local j_previewImage	= j_table._previewImage
		local j_subtitleUrl	= j_table._subtitleUrl
		local j_subtitleOffset	= j_table._subtitleOffset

		if j_previewImage ~= nil then j_previewImage = baseUrl .. j_previewImage end
		if j_subtitleUrl ~= nil then j_subtitleUrl = baseUrl .. j_subtitleUrl end

		local j_mediaArray	= j_table._mediaArray
		local i1, i2

		-- available stream qualities
		local count = 1
		local j = 4
		if hdsAvailable == false or conf.auto == langStr_off then j = 3 end
		local q
		local qual = {}
		while j >= 0 do
			if j_mediaArray ~= nil then
				for i1 = 1, #j_mediaArray do
					j_mediaStreamArray = j_mediaArray[i1]._mediaStreamArray
					if j_mediaStreamArray ~= nil then
						for i2 = 1, #j_mediaStreamArray do
							if j == 4 then q = "auto" else q = tostring(j) end
							if tostring(j_mediaStreamArray[i2]._quality) == q then
								qual[count] = q
								count = count + 1
								goto qual_next
							end
						end
					end
				end
			end
			::qual_next::
			j = j - 1
		end

		-- set playQuality
		local bool qual_found = false
		if conf.auto == langStr_on and qual[1] == "auto" then
			playQuality = "auto"
			qual_found = true
		else
			i1 = #qual
			while i1 > 0 do
				if qual[i1] == tostring(conf.streamQuality) then
					playQuality = qual[i1]
					qual_found = true
					break
				end
				i1 = i1 - 1
			end
			if qual_found == false then
				if conf.streamQuality >= 2 then
					playQuality = qual[1]
				elseif conf.streamQuality == 0 then
					playQuality = qual[#qual]
				else
					i1 = #qual - 1
					if i1 < 1 then i1 = #qual end
					playQuality = qual[i1]
				end
			end
		end

		local streamBreak = false
		if j_mediaArray ~= nil then
			if debugmode == 2 then
				print("#####[ard_mediathek] Inhalt von j_mediaArray:")
				tprint(j_mediaArray,0)
				print("#####[ard_mediathek] Ende von j_mediaArray")
			end
			for i1 = 1, #j_mediaArray do
				j_mediaStreamArray = j_mediaArray[i1]._mediaStreamArray
				if j_mediaStreamArray ~= nil then
					for i2 = 1, #j_mediaStreamArray do
						if tostring(j_mediaStreamArray[i2]._quality) == tostring(playQuality) then
							local _server = ""
							if j_mediaStreamArray[i2]._server ~= nil then
								_server = j_mediaStreamArray[i2]._server
							end
							local _stream = j_mediaStreamArray[i2]._stream
							if _stream == nil then
								print("#####[ard_mediathek] No stream available, exit.")
								streamBreak = true
								break
							end
							if _stream[1] ~= nil then _stream = _stream[1] end
							streamUrl = _server .. _stream;
							streamQuality = j_mediaStreamArray[i2]._quality
							if tostring(streamQuality) == "auto" then
								if nMisc:strSub(streamUrl, #streamUrl-4) == ".f4m" then
									streamUrl = streamUrl .. "?hdcore"
								end
							end
							if _server ~= "" then goto array_next end
							if nMisc:strSub(streamUrl, 0, 2) == "//" then streamUrl = "http:" .. streamUrl end
							printf("#####[ard_mediathek] q: %s, stream: %s", tostring(playQuality), streamUrl)
							streamBreak = true
							break
						end
					end
				end
				if streamBreak == true then break end
			::array_next::
			end
		end
	end
	hideInfoBox()

	if streamUrl ~= "x" then
		local info1 = headline
--		local info2 = infoline
		local info2 = infoline .. " [q=" .. playQuality .. "]"
		if title == nil then title = "" end
		if info1 == nil then info1 = "" end
		if info2 == nil then info2 = "" end
		if dlmode then
			local dl = {}
			dl.name = title
			dl.streamUrl = streamUrl
			dl.info1 = conv_str(info1)
			dl.info2 = listContent[id1].prev_date
			dl.ch = selectedChannel
			dl.quali = playQuality
			local d,m,y = listContent[id1].prev_date:match('(%d%d)%.(%d%d)%.(%d%d%d%d)')
			local t1,t2 = listContent[id1].date:match('(%d%d):(%d%d)')
			dl.date = y .. m .. d .. "_" .. t1 .. t2 .. "00"
			return dl
		else
			hideBGPicture(false)
			vPlay:PlayFile(title, streamUrl, conv_str(info1), conv_str(info2))
			collectgarbage();
			showBGPicture()
		end
	end
end

function getPrevDate(num)
	local sDay = 86400 --24*3600
	local aktDate = os.time() - sDay * num
	local wd
	if num == 0 then
		wd = "Today"
	elseif num == 1 then
		wd = "Yesterday"
	else
		wd = os.date("%A", aktDate)
	end
	if wd == "Today"     then wd = langStr_Today end
	if wd == "Yesterday" then wd = langStr_Yesterday end
	if wd == "Monday"    then wd = langStr_Monday end
	if wd == "Tuesday"   then wd = langStr_Tuesday end
	if wd == "Wednesday" then wd = langStr_Wednesday end
	if wd == "Thursday"  then wd = langStr_Thursday end
	if wd == "Friday"    then wd = langStr_Friday end
	if wd == "Saturday"  then wd = langStr_Saturday end
	if wd == "Sunday"    then wd = langStr_Sunday end
	local formatStr
	if conf.language == "DE" then
		formatStr = "%d.%m.%Y"
	else
		formatStr = "%Y-%m-%d"
	end
	return wd, os.date(formatStr, aktDate)
end

function hideMenu(menu)
	if menu ~= nil then menu:hide() end
end

function setLangStrings(lang)
	if lang == "DE" then
		langStr_caption			= "ARD Mediathek"
		langStr_modeSelection		= "Auswahl"
		langStr_programMissed		= "Sendung verpasst?"
		langStr_channelSelection	= "Senderwahl"
		langStr_options			= "Einstellungen"
		langStr_contentLoad		= "Inhalte werden geladen..."
		langStr_saveSettings		= "Einstellungen werden gespeichert..."
		langStr_language		= "Sprache"
		langStr_save			= "Einstellungen jetzt speichern"
		langStr_discardChanges1		= "Änderungen verwerfen?"
		langStr_discardChanges2		= "Sollen die Änderungen verworfen werden?"
		langStr_auto			= "'auto' Qualität (HDS)"
		langStr_quality			= "Streamqualität"

		langStr_Today			= "Heute"
		langStr_Yesterday		= "Gestern"
		langStr_Monday			= "Montag"
		langStr_Tuesday			= "Dienstag"
		langStr_Wednesday		= "Mittwoch"
		langStr_Thursday		= "Donnerstag"
		langStr_Friday			= "Freitag"
		langStr_Saturday		= "Samstag"
		langStr_Sunday			= "Sonntag"
		langStr_on			= "ein"
		langStr_off			= "aus"
		langStr_DLPath		= "Pfad für Downloads:"
		langStr_DLWait		= "Andere Download ist schon aktiv"
	elseif lang == "EN" then
		langStr_caption			= "ARD Mediathek"
		langStr_modeSelection		= "Selection"
		langStr_programMissed		= "Program missed?"
		langStr_channelSelection	= "Channel selection"
		langStr_options			= "Options"
		langStr_contentLoad		= "Content is loading..."
		langStr_saveSettings		= "Settings will be saved..."
		langStr_language		= "Language"
		langStr_save			= "Save settings now"
		langStr_discardChanges1		= "Discard changes? "
		langStr_discardChanges2		= "Should the changes be discarded?"
		langStr_auto			= "'auto' quality (HDS)"
		langStr_quality			= "Stream quality"

		langStr_Today			= "Today"
		langStr_Yesterday		= "Yesterday"
		langStr_Monday			= "Monday"
		langStr_Tuesday			= "Tuesday"
		langStr_Wednesday		= "Wednesday"
		langStr_Thursday		= "Thursday"
		langStr_Friday			= "Friday"
		langStr_Saturday		= "Saturday"
		langStr_Sunday			= "Sunday"
		langStr_on			= "on"
		langStr_off			= "off"
		langStr_DLPath		= "Path for Downloads:"
		langStr_DLWait		= "Other download is already active"
	else
		error("No language selected!");
	end
end

function paintInfoBox(txt)
	local dx = 450
	local dy = 120
	local x = SCREEN.OFF_X + (((SCREEN.END_X - SCREEN.OFF_X) - dx) / 2)
	local y = SCREEN.OFF_Y + (((SCREEN.END_Y - SCREEN.OFF_Y) - dy) / 2)

	infoBox_h = cwindow.new{x=x, y=y, dx=dx, dy=dy, title=langStr_caption, icon=pluginIcon, has_shadow=true, show_footer=false}
	ctext.new{parent=infoBox_h, x=30, y=2, dx=dx-60, dy=dy-infoBox_h:headerHeight()-4, text=txt, font_text=FONT.MENU, mode="ALIGN_CENTER"}
	infoBox_h:paint()
end

function hideInfoBox()
	if infoBox_h ~= nil then
		infoBox_h:hide{}
		infoBox_h = nil
	end
end


function fileExist(file)
	local fh = filehelpers.new()
	return fh:exist(file, "f")
end

function trim(s)
	return (s:gsub("^%s*(.-)%s*$", "%1"))
end

function printf(...)
	print(string.format(...))
end

-- UTF8 in Umlaute wandeln
function conv_str(_string)
	if _string == nil then return _string end
	_string = string.gsub(_string,"&amp;","&");
	_string = string.gsub(_string,"&quot;","\"");
	_string = string.gsub(_string,"&#039;","'");
--[[
	_string = string.gsub(_string,"\\u0026","&");
	_string = string.gsub(_string,"\\u00a0"," ");
	_string = string.gsub(_string,"\\u00b4","´");
	_string = string.gsub(_string,"\\u00c4","Ä");
	_string = string.gsub(_string,"\\u00d6","Ö");
	_string = string.gsub(_string,"\\u00dc","Ü");
	_string = string.gsub(_string,"\\u00df","ß");
	_string = string.gsub(_string,"\\u00e1","á");
	_string = string.gsub(_string,"\\u00e4","ä");
	_string = string.gsub(_string,"\\u00e8","è");
	_string = string.gsub(_string,"\\u00e9","é");
	_string = string.gsub(_string,"\\u00f4","ô");
	_string = string.gsub(_string,"\\u00f6","ö");
	_string = string.gsub(_string,"\\u00fb","û");
	_string = string.gsub(_string,"\\u00fc","ü");
	_string = string.gsub(_string,"\\u2013","–");
	_string = string.gsub(_string,"\\u201c","“");
	_string = string.gsub(_string,"\\u201e","„");
	_string = string.gsub(_string,"\\u2026","…");
	_string = string.gsub(_string,"&#038;","&");
	_string = string.gsub(_string,"&#8211;","–");
	_string = string.gsub(_string,"&#8212;","—");
	_string = string.gsub(_string,"&#8216;","‘");
	_string = string.gsub(_string,"&#8217;","’");
	_string = string.gsub(_string,"&#8230;","…");
	_string = string.gsub(_string,"&#8243;","″");
	_string = string.gsub(_string,"<[^>]*>","");
	_string = string.gsub(_string,"\\/","/");
	_string = string.gsub(_string,"\\n","");
]]
	return _string
end

-- Print contents of `tbl`, with indentation.
-- `indent` sets the initial level of indentation.
-- function ist from https://gist.github.com/ripter/4270799
function tprint(tbl, indent)
	if not indent then indent = 0 end
	for k, v in pairs(tbl) do
		formatting = string.rep(" ", indent) .. k .. ": "
		if type(v) == "table" then
			print(formatting)
			tprint(v, indent+1)
		elseif type(v) == 'boolean' then
			print(formatting .. tostring(v))	
		else
			print(formatting .. v)
		end
	end
end

function isNevis()
	local fp = io.open("/proc/cpuinfo", "r")
	if fp == nil then error("Error opening /proc/cpuinfo.") end
	local s = fp:read("*a")
	fp:close()
	if s:find("CoolStream HDx IRD") ~= nil or s:find("CST HDx IRD") ~= nil then
		return true
	end
	return false
end

-- #######################################################################################
--  Einstellungen
-- #######################################################################################

function loadConfig()
	config:loadConfig(confFile)

	conf.dlPath   = config:getString('dlPath',      '/')
	conf.language = config:getString("language", "DE")
	setLangStrings(conf.language)
	conf.streamQuality = config:getInt32("streamQuality", 3)
	local tmp = config:getBool( "auto", false)
	if hdsAvailable ~= true then
		if tmp == true then tmp = false end
	end
	if tmp == true then conf.auto = langStr_on else conf.auto = langStr_off end
end

function saveConfig()
	if confChanged == 1 then
		paintInfoBox(langStr_saveSettings)

		config:setString('dlPath', conf.dlPath)
		config:setString("language", conf.language)
		config:setInt32("streamQuality", conf.streamQuality)
		if conf.auto == langStr_on then tmp = true else tmp = false end
		config:setBool("auto", tmp)

		config:saveConfig(confFile)
		confChanged = 0
		sleep (1)
		hideInfoBox()
	end
	return MENU_RETURN.EXIT_REPAINT
end

function setInt(k, v)
	conf[k] = v
	confChanged = 1
end

function setString(k, v)
	conf[k] = v
	confChanged = 1
end

function handle_key(a)
	if (confChanged == 0) then return MENU_RETURN.EXIT end
	local res = messagebox.exec{title=langStr_discardChanges1, text=langStr_discardChanges2, buttons={ "yes", "no" } }
	if (res == "yes") then return MENU_RETURN.EXIT end
	return MENU_RETURN.EXIT_REPAINT
end

function set_path(id,value)
	if conf[id] ~= value then
		conf[id]=value
		confChanged = 1
	end
end

function setOptions()
	hideMenu(m_modes)

	local m_conf = menu.new{name = langStr_caption .. ": " .. langStr_options, icon="settings"}
	m_conf:addKey{directkey = RC["home"], id = "home", action = "handle_key"}
	m_conf:addItem{type = "back"}
	m_conf:addItem{type = "separatorline"}
	m_conf:addItem{type = "forwarder", name = langStr_save, action = "saveConfig", icon = "rot", directkey = RC["red"]}
	m_conf:addItem{type = "separatorline"}
	opt = { "DE" ,"EN" }
	m_conf:addItem{type="chooser", action="setString", options={opt[1], opt[2]}, id="language", value=conf.language, icon=1, directkey=RC["1"], name=langStr_language}
	opt = { langStr_on, langStr_off }
--	m_conf:addItem{type="chooser", enabled=hdsAvailable, action="setString", options={opt[1], opt[2]}, id="auto", value=conf.auto, icon=2, directkey=RC["2"], name=langStr_auto}
	opt = { 0 ,1, 2 ,3 }
	m_conf:addItem{type="chooser", action="setInt", options={opt[1], opt[2], opt[3], opt[4]}, id="streamQuality", value=conf.streamQuality, icon=2, directkey=RC["2"], name=langStr_quality}
--	m_conf:addItem{type="numeric", action="setInt", range="0,3", id="streamQuality", value=conf.streamQuality, name=langStr_quality}
	m_conf:addItem{type="filebrowser", dir_mode="1", action="set_path", id="dlPath", value=conf.dlPath, directkey=RC["2"], name=langStr_DLPath}

	m_conf:exec()
	return MENU_RETURN.EXIT_REPAINT;
end

-- #######################################################################################

init()
getFirstMenu()
config:saveConfig(confFile)
hideBGPicture(true)
os.execute("rm -fr " .. tmpPath)
os.execute("sync")
collectgarbage();
