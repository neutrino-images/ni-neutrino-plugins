--[[
	plutotv-vod.lua v1.21

	Copyright (C) 2021 TangoCash
	License: WTFPLv2
]]

plugin_title = "Pluto TV VoD"
plutotv_vod_png = arg[0]:match('.*/') .. "/plutotv-vod_hint.png"

hotkeys = true

json = require "json"
n = neutrino()

catlist = {}

itemlist = {}
itemlist_details = {}

episodelist = {}
episodelist_details = {}

playback_details = {}

mode = 0;

re_url= ""

fh = filehelpers.new()

current_uuid = ""

CONF_PATH = "/var/tuxbox/config/"
if DIR and DIR.CONFIGDIR then
	CONF_PATH = DIR.CONFIGDIR .. '/'
end

dlPath = '/'

function getdata(Url, File)
	if Url == nil then return nil end
	if Curl == nil then
		Curl = curl.new()
	end
	local ret, data = Curl:download{ url=Url, ipv4=true, A="Mozilla/5.0", o=File}
	if ret == CURL.OK then
		if File then
			return 1
		else
			return data
		end
	else
		return nil
	end
end

function which(bin_name)
	local path = os.getenv("PATH") or "/bin"
	for v in path:gmatch("([^:]+):?") do
		local file = v .. "/" .. bin_name
		if fh:exist(file , "f") then
			return true
		end
	end
	return false
end

function sleep(a)
	local sec = tonumber(os.clock() + a)
	while (os.clock() < sec) do
	end
end

--herunterladen des Bildes
function getPicture(_picture)
	local fname = coverPic;
	return getdata(_picture,fname)
end

-- UTF8 in Umlaute wandeln
function conv_utf8(_string)
	if _string ~= nil then
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
	end
	return _string
end

function gen_ids() -- Generation of a random sid 
	local a = string.format("%x", math.random(1000000000,9999999999)) 
	local b = string.format("%x", math.random(1000,9999)) 
	local c = string.format("%x", math.random(1000,9999)) 
	local d = string.format("%x", math.random(10000000000000,99999999999999))
	local id = tostring(a) .. '-' .. tostring(b) .. '-' .. tostring(c) .. '-' .. tostring(d)
	return id
end

function getVideoData(url) -- Generate stream address and evaluate it according to the best resolution
	http = "http://service-stitcher-ipv4.clusters.pluto.tv/stitch/hls/episode/"
	token = "?terminate=false&embedPartner=&serverSideAds=&paln=&includeExtendedEvents=false&architecture=&deviceId=" .. gen_ids() .. "&deviceVersion=unknown&appVersion=unknown&deviceType=web&deviceMake=Chrome&sid=" .. gen_ids() .. "&advertisingId=&deviceDNT=0&deviceModel=Chrome&userId=&appName="
	local data = getdata(http .. url .."/master.m3u8" ..token) -- Calling the generated master.m3u8
	local count = 0
	if data then
		local res = 0
		for band, url2 in data:gmatch(',BANDWIDTH=(%d+).-\n(%d+.-m3u8)') do
			if band and url2 then
				local nr = tonumber(band)
				if nr > res then
					res=nr
					re_url = http .. url .. "/" .. url2 .. token 
				end
			end
		end
	end
end

function rescalePic(picW,picH,maxW,maxH)
	if picW and picW > 0 and picH and picH > 0 then
		local aspect = picW / picH
		if not maxH then
			maxH = getMaxScreenHeight()
		end
		if not maxW then
			maxW = getMaxScreenWidth()
		end
		if picW / maxW > picH / maxH then
			picW = maxW
			picH = maxW/aspect
		else
			picH = maxH
			picW = maxH * aspect
		end
		picH = math.floor(picH)
		picW = math.floor(picW)
	end
	return picW,picH
end

function getMaxScreenWidth()
	local max_w = SCREEN.END_X - SCREEN.OFF_X
	return max_w
end

function getMaxScreenHeight()
	local max_h = SCREEN.END_Y - SCREEN.OFF_Y
	return max_h
end

function godirectkey(d)
	if d  == nil then return d end
	local  _dkey = ""
	if d == 11 then
		_dkey = RC.red
	elseif d == 12 then
		_dkey = RC.green
	elseif d == 13 then
		_dkey = RC.yellow
	elseif d == 14 then
		_dkey = RC.blue
	elseif d < 10 then
		_dkey = RC[""..d..""]
	elseif d == 10 then
		_dkey = RC["0"]
	else
		-- rest
		_dkey = ""
	end
	return _dkey
end

function godirectbutton(d)
	if d  == nil then return d end
	local  _dkey = ""
	if d == 11 then
		_dkey = "rot"
	elseif d == 12 then
		_dkey = "gruen"
	elseif d == 13 then
		_dkey = "gelb"
	elseif d == 14 then
		_dkey = "blau"
	elseif d < 10 then
		_dkey = ""..d..""
	elseif d == 10 then
		_dkey = "0"
	else
		-- rest
		_dkey = ""
	end
	return _dkey
end

function godirect(ik, count)
	if hotkeys then
		if ik == "icon" then return godirectbutton(count) end
		if ik == "directkey" then return godirectkey(count) end
	else
		if ik == "icon" then return nil end
		if ik == "directkey" then return nil end
	end
end

function hint_text(text)
	if text == "Serie" then
		return text
	elseif tostring(text):find("Staffel") then
		return text
	else
		return "Video - Länge " ..text.. " min"
	end
end

function hint_icon(text)
	if text == "Serie" then
		return "hint_next"
	else
		return "video"
	end
end

function value_text(text)
	if text == "Serie" then
		return "("..text..")"
	else
		return "("..text.." min)"
	end
end

function hint_value(ik, text)
	if hints then
		if ik == "hinticon" then return hint_icon(text) end
		if ik == "hinttext" then return hint_text(text) end
		if ik == "value" then return nil end
	else
		if ik == "hinticon" then return nil end
		if ik == "hinttext" then return nil end
		if ik == "value" then return value_text(text) end
	end
end

function get_timing_menu()
	local ret = 0
	local Nconfig = configfile.new()
	if Nconfig then
		Nconfig:loadConfig(CONF_PATH .. "neutrino.conf")
		ret = Nconfig:getInt32("timing.menu", 0)
	end
	return ret
end

function get_hints_menu()
	local ret = false
	local Nconfig = configfile.new()
	if Nconfig then
		Nconfig:loadConfig(CONF_PATH .. "neutrino.conf")
		ret = Nconfig:getBool("show_menu_hints", false)
	end
	return ret
end

--auf Tasteneingaben reagieren
function getInput()
	local i = 0
	local d = 500 -- ms
	local t = (get_timing_menu() * 1000) / d
	if t == 0 then
		t = -1 -- no timeout
	end
	repeat
		i = i + 1
		msg, data = n:GetInput(d)
		if msg >= RC["0"] and msg <= RC.MaxRC then
			i = 0 -- reset timeout
		end
		-- Taste OK/Play startet Stream
		if (msg == RC['ok']) or (msg == RC['play']) or (msg == RC['playpause']) then
			mode = 1;
			break;
		-- Taste Rot/Record startet Download
		elseif ((msg == RC['red']) or (msg == RC['record'])) and have_ffmpeg then
			mode = 2;
			break;
		elseif (msg == RC['up'] or msg == RC['page_up']) then
			ct:scroll{dir="up"};
		elseif (msg == RC['down'] or msg == RC['page_down']) then
			ct:scroll{dir="down"};
		end
	-- Taste Exit oder Menü beendet das Fenster
	until msg == RC['home'] or msg == RC['setup'] or i == t;

	if msg == RC['setup'] then
		return MENU_RETURN["EXIT_ALL"]
	end
end

function showBGPicture()
	if fh:exist(bigPicBG, 'f') then
		vPlay:zapitStopPlayBack()
		vPlay:ShowPicture(bigPicBG)
	end
end

function hideBGPicture(rezap)
	if (rezap == true) then
		vPlay:channelRezap()
	end
	local rev, box = nMisc:GetRevision()
	if fh:exist(bigPicBG, 'f') and rev == 1 then vPlay:StopPicture() end
end

function playback_stream(uuid)
	hideBGPicture(false)
	local h = hintbox.new{caption=plugin_title, text='Starte\n"' .. playback_details[uuid].name .. '"', icon=plutotv_vod_png}
	h:paint()
	getVideoData(uuid)
	h:hide()
	if (re_url) then
		local info1  =  playback_details[uuid].desc
		if playback_details[uuid].type == "episode" then
			info1 = playback_details[uuid].name
			local info2 = playback_details[uuid].desc
		end
		current_uuid = uuid
		local data = getdata(re_url)
		local dlm3 = "/tmp/.plutotv_vod_play.m3u8"
		local m3uw = io.open(dlm3,"w")
		local nomarkerfound = true
		local marker = ""
		local skipline = false
		local count = 1
		for line in data:gmatch("([^\n]*)\n?") do
			if nomarkerfound and count > 12 then
				if line:find('#EXT-X-KEY',1,true) then
					marker = line:match('.-://.-/(.-)/')
					nomarkerfound = false
				end
			end
			if not skipline and line == '#EXT-X-DISCONTINUITY' then
				skipline = true
			end
			if skipline and line:find('#EXT-X-KEY',1,true) and line:find(marker,1,true) then
				skipline = false
			end
			if skipline and line == '#EXT-X-ENDLIST' then
				skipline = false
			end
			if count < 12 then
				skipline = false
			end
			if not skipline then
				m3uw:write(line..'\n')
			end
			count = count + 1
		end
		m3uw:close()
		vPlay:setSinglePlay(true)
		vPlay:setInfoFunc("epgInfo")
		vPlay:PlayFile(playback_details[uuid].title or playback_details[uuid].name, dlm3, info1, info2 or "");
		os.execute('rm '.. dlm3)
	end
	current_uuid = ""
	showBGPicture()
end

function dl_check(streamUrl)
	local check = false
	local Nconfig = configfile.new()
	if Nconfig then
		Nconfig:loadConfig(CONF_PATH .. "neutrino.conf")
		dlPath = Nconfig:getString("network_nfs_recordingdir", '/tmp')
	end

	local dl_not_possible = dlPath == '/tmp' or dlPath == '/'
	if dl_not_possible then return check end
	if fh:exist('/tmp/.plutotv_vod_dl.sh', 'f') then return check end
	if have_ffmpeg and streamUrl:find('m3u8') then
		check = true
	end
	return check
end

function start_bg_download(streamUrl,filename,title)
	local Format = nil
	if streamUrl then
		if streamUrl:find("m3u8") then
			Format = 'mp4'
		end
		local file_id = gen_ids()
		local data = getdata(streamUrl)
		local dlm3 = "/tmp/.plutotv_vod_dl_" .. file_id .. ".m3u8"
		local m3uw = io.open(dlm3,"w")
		local nomarkerfound = true
		local marker = ""
		local count = 1
		for line in data:gmatch("([^\n]*)\n?") do
			if nomarkerfound and count > 12 then
				if line:find('#EXT-X-KEY',1,true) then
					marker = line:match('.-://.-/(.-)/')
					nomarkerfound = false
				end
			end
			if not skipline and line == '#EXT-X-DISCONTINUITY' then
				skipline = true
			end
			if skipline and line:find('#EXT-X-KEY',1,true) and line:find(marker,1,true) then
				skipline = false
			end
			if skipline and line == '#EXT-X-ENDLIST' then
				skipline = false
			end
			if count < 12 then
				skipline = false
			end
			if not skipline then
				m3uw:write(line..'\n')
			end
			count = count + 1
		end
		m3uw:close()
		if filename and Format then
			local dls  = "/tmp/.plutotv_vod_dl_" .. file_id .. ".sh"
			dlname = filename
			local script=io.open(dls,"w")
			script:write('echo "download start" ;\n')
			script:write("ffmpeg -y -nostdin -loglevel 30 -force_dts_monotonicity -protocol_whitelist 'http,https,file,crypto,tls,tcp' -i '" .. dlm3 .. "' -c copy " .. dlname   .. "." .. Format .. "\n")
			script:write('if [ $? -eq 0 ]; then \n')
			script:write('wget -q http://127.0.0.1/control/message?popup="Video ' .. title .. ' wurde heruntergeladen." -O /dev/null ; \n')
			script:write('mv ' .. dlname .. '.' .. Format .. ' ' .. dlname .. '.ts\n')
			script:write('rm ' .. dlm3 .. '; \n')
			script:write('echo "download success" ;\n')
			script:write('else \n')
			script:write('wget -q http://127.0.0.1/control/message?popup="Download ' .. title .. ' FEHLGESCHLAGEN" -O /dev/null ; \n')
			script:write('rm ' .. dlname .. '.*; \n')
			script:write('rm ' .. dlm3 .. '; \n')
			script:write('echo "download failed" ;\n')
			script:write('fi \n')
			script:write('rm ' .. dls .. '; \n')
			script:close()
			os.execute('sh  ' .. dls .. ' &')
			return true
		end
	end
	return false
end

function download_stream(uuid)
	local h = hintbox.new{caption=plugin_title, text='Download im Hintergrund wird vorbereitet\n\n"' .. playback_details[uuid].name .. '"', icon=plutotv_vod_png}
	h:paint()
	getVideoData(uuid)
	h:hide()
	if (re_url) then
		if dl_check(re_url) then
			local h1 = hintbox.new{caption=plugin_title, text='Download im Hintergrund wird gestartet\n\n"' .. playback_details[uuid].name .. '"', icon=plutotv_vod_png}
			h1:paint()
			local filename = plugin_title .. "_" .. playback_details[uuid].name
			if playback_details[uuid].type == "episode" then
				filename = plugin_title .. "_".. playback_details[uuid].title .. "_" .. playback_details[uuid].name
			end
			filename = filename:gsub("[%p%s/]", "_")
			if fh:exist(dlPath.."/"..filename..'.ts', 'f') then
				h1:hide()
				local h2 = hintbox.new{caption=plugin_title, text='Download bereits vorhanden...\n\n"' .. playback_details[uuid].name .. '"', icon=plutotv_vod_png}
				h2:paint()
				sleep(3)
				h2:hide()
				return
			end
			save_info(uuid,dlPath.."/"..filename)
			start_bg_download(re_url,dlPath.."/"..filename,playback_details[uuid].name)
			sleep(3)
			h1:hide()
		else
			local h3 = hintbox.new{caption=plugin_title, text="Ein Download läuft bereits...\n\nBitte warten bis dieser abgeschlossen ist  ", icon=plutotv_vod_png}
			h3:paint()
			sleep(3)
			h3:hide()
		end
	end
end

function save_info(uuid,filename)
	local ch = plugin_title
	local title = playback_details[uuid].title or playback_details[uuid].name
	local info1 = playback_details[uuid].eptitle or ""
	local info2 = playback_details[uuid].desc
	local dur   = playback_details[uuid].duration
	local name  = playback_details[uuid].title or ""
local xml='<?xml version="1.0" encoding="UTF-8"?>\
\
<neutrino commandversion="1">\
	<record command="record">\
		<channelname>' .. ch .. '</channelname>\
		<epgtitle>' .. conv_utf8(title) .. '</epgtitle>\
		<id>0</id>\
		<info1>' .. conv_utf8(info1) .. '</info1>\
		<info2>' .. conv_utf8(info2) .. '</info2>\
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
		<seriename>'.. name ..'</seriename>\
		<length>' .. dur ..'</length>\
		<productioncountry></productioncountry>\
		<productiondate>0</productiondate>\
		<rating>0</rating>\
		<quality>0</quality>\
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

	local file = io.open(filename..".xml",'w')
	file:write(xml)
	file:close()
	if playback_details[uuid].cover ~= nil then
		if getdata(playback_details[uuid].cover,filename..".jpg") == nil then
			os.execute('rm  ' .. filename .. '.jpg')
		end
	end
end

function epgInfo(xres, yres, aspectRatio, framerate)
	local off_w,x,y,w,h  = 0,0,0,0,0
	local space = OFFSET.INNER_MID
	local withPic = false
	local wow = cwindow.new{x=x, y=y, dx=w, dy=h, title=playback_details[current_uuid].title or playback_details[current_uuid].name, icon=plutotv_vod_png }
	local tf = wow:headerHeight() + wow:footerHeight()
	w,h = n:scale2Res(1000), n:scale2Res(600) + tf
	local tw = n:getRenderWidth(FONT.MENU_TITLE,playback_details[current_uuid].title or playback_details[current_uuid].name) + (wow:headerHeight() * 2)
	if tw > w then
		w = tw
		if w > n:scale2Res(1200) then w = n:scale2Res(1200) end
	end

	if playback_details[current_uuid].cover ~= nil then
		if getPicture(conv_utf8(playback_details[current_uuid].cover)) ~= nil then
			withPic = true
		end
	end

	if withPic then
		local maxW ,maxH = n:scale2Res(347), n:scale2Res(500)
		local picW, picH = n:GetSize(coverPic)
		maxW,maxH = rescalePic(picW,picH,maxW,maxH)
		off_w,h = maxW,maxH
		cpicture.new{parent=wow, x=space, y=space, dx=maxW, dy=maxH, image=coverPic}
		h = maxH + tf + (space*2)
		local wP =  (maxW * 2) + (space * 3)
		if w < wP then
			w = wP
		end
	end

	local episode = playback_details[current_uuid].eptitle or ""
	local desc_text = episode .. "\n" .. conv_utf8(playback_details[current_uuid].desc).."\n\n"..playback_details[current_uuid].duration.." min".."\n" .. playback_details[current_uuid].rating.."\n" .. conv_utf8(playback_details[current_uuid].genre)
	ct = ctext.new{parent=wow, x=off_w + (space*2), y=space, dx=w-off_w, dy=h-tf, text=desc_text, mode="ALIGN_TOP | ALIGN_SCROLL"}

	if withPic == false then
		local ctLines = ct:getLines() + 1
		local th = ctLines * n:FontHeight(FONT.MENU) + tf + (2*space)
		if th < n:scale2Res(720) then
			h = th
		end
	end

	wow:setDimensionsAll(x , y, w, h)
	wow:setCenterPos{3}
	wow:paint()

	local i = 0
	local d = 500 -- ms
	local msg, data = nil,nil
	local t = (get_timing_menu() * 1000) / d
	if t == 0 then
		t = -1 -- no timeout
	end
	repeat
		i = i + 1
		msg, data = n:GetInput(d)
		if ct and (msg == RC.up or msg == RC.page_up) then
			ct:scroll{dir="up"}
		elseif ct and (msg == RC.down or msg == RC.page_down) then
			ct:scroll{dir="down"}
		end
	until msg == RC.ok or msg == RC.home or msg == RC.info or i == t
	wow:hide()
end

function show_playback_info_e(uuid)
	em:hide()
	show_playback_info(uuid)
end

function show_playback_info_m(uuid)
	cm:hide()
	show_playback_info(uuid)
end

-- Filminfos anzeigen
function show_playback_info(uuid)
	mode = 0;

	local off_w,x,y,w,h  = 0,0,0,0,0
	local space = OFFSET.INNER_MID
	local withPic = false
	local btn_text = "Film"
	if playback_details[uuid].type == "episode" then
		btn_text = "Episode"
	end
	w = n:scale2Res(1000)
	h = n:scale2Res(600) 
	local wow = cwindow.new{x=x, y=y, dx=w, dy=h, title=playback_details[uuid].title or playback_details[uuid].name, btnOk=btn_text .." abspielen", btnRed=btn_text.." downloaden", icon=plutotv_vod_png }
	local tf = wow:headerHeight() + wow:footerHeight()
	h = h + tf
	local tw = n:getRenderWidth(FONT.MENU_TITLE,playback_details[uuid].title or playback_details[uuid].name) + (wow:headerHeight() * 2)
	if tw > w then
		w = tw
		if w > n:scale2Res(1200) then w = n:scale2Res(1200) end
	end

	if playback_details[uuid].cover ~= nil then
		if getPicture(conv_utf8(playback_details[uuid].cover)) ~= nil then
			withPic = true
		end
	end

	if withPic then
		local maxW ,maxH = n:scale2Res(347), n:scale2Res(500)
		local picW, picH = n:GetSize(coverPic)
		maxW,maxH = rescalePic(picW,picH,maxW,maxH)
		off_w,h = maxW,maxH
		cpicture.new{parent=wow, x=space, y=space, dx=maxW, dy=maxH, image=coverPic}
		h = maxH + tf + (space*2)
		local wP =  (maxW * 2) + (space * 3)
		if w < wP then
			w = wP
		end
	end

	local episode = playback_details[uuid].eptitle or ""
	local desc_text = episode .. "\n" .. conv_utf8(playback_details[uuid].desc).."\n\n"..playback_details[uuid].duration.." min".."\n" .. playback_details[uuid].rating.."\n" .. conv_utf8(playback_details[uuid].genre)
	ct = ctext.new{parent=wow, x=off_w + (space*2), y=space, dx=w-off_w, dy=h-tf, text=desc_text, mode="ALIGN_TOP | ALIGN_SCROLL"}

	if withPic == false then
		local ctLines = ct:getLines() + 1
		local th = ctLines * n:FontHeight(FONT.MENU) + tf + (2*space)
		if th < n:scale2Res(720) then
			h = th
		end
	end

	wow:setDimensionsAll(x , y, w, h)
	wow:setCenterPos{3}
	wow:paint()
	ret = getInput();
	wow:hide();

	if ret == MENU_RETURN["EXIT_ALL"] then
		return ret
	elseif mode == 1 then
		playback_stream(uuid);
		collectgarbage();
	elseif mode == 2 then
		download_stream(uuid);
		collectgarbage();
	end
end

function get_cat()
	local r = false
	local c = curl.new()
	local c_data = getdata("http://api.pluto.tv/v3/vod/categories?includeItems=true&deviceType=web")
	if c_data then
		local jd = json:decode(c_data)
		if jd then
			for i = 1, jd.totalCategories do
				if jd.categories[i] then
					table.insert(catlist, i, jd.categories[i].name)
					itemlist_details = {}
					for k = 1, #jd.categories[i].items do
						local _duration = 0
						if jd.categories[i].items[k].originalContentDuration then
							_duration = math.floor(tonumber(jd.categories[i].items[k].originalContentDuration) / 1000 / 60 + 0.5)
						end
						itemlist_details[k] =
						{
							cat  = i;
							item = k;
							name = jd.categories[i].items[k].name;
							desc = jd.categories[i].items[k].description;
							uuid = jd.categories[i].items[k]._id;
							type = jd.categories[i].items[k].type;
							duration = _duration;
							cover = jd.categories[i].items[k].covers[1].url;
							rating = jd.categories[i].items[k].rating;
							genre = jd.categories[i].items[k].genre;
						}
					end
					table.insert(itemlist, i , itemlist_details)
				end
			end
		end
	end
end

function cat_menu(_id)
	m:hide()
	cm = menu.new{name=catlist[tonumber(_id)], has_shadow=true, icon=plutotv_vod_png}
	for cat, itemlist_detail in pairs (itemlist) do
		if cat == tonumber(_id) then
			local count = 1
			for item, item_detail in pairs(itemlist_detail) do
				if item_detail.type == "movie" then
					cm:addItem{type="forwarder", name=conv_utf8(item_detail.name), action="show_playback_info_m", id=item_detail.uuid, icon=godirect("icon", count), hint=hint_value("hinttext",item_detail.duration), hint_icon=hint_value("hinticon",item_detail.duration), value=hint_value("value",item_detail.duration), enabled=true, directkey=godirect("directkey", count)}
					playback_details[item_detail.uuid] = 
					{
						uuid = item_detail.uuid;
						name = item_detail.name;
						desc = item_detail.desc;
						cover = item_detail.cover;
						type = item_detail.type;
						duration = item_detail.duration;
						rating = item_detail.rating;
						genre = item_detail.genre;
					}
				end
				if item_detail.type == "series" then
					cm:addItem{type="forwarder", name=conv_utf8(item_detail.name), action="season_menu", id=item_detail.uuid, icon=godirect("icon", count), hint=hint_value("hinttext","Serie"), hint_icon=hint_value("hinticon","Serie"), value=hint_value("value","Serie"), enabled=true, directkey=godirect("directkey", count)}
				end
				if count == 0 then
					count = 11
				elseif count == 9 then 
					count = 0
				else
					count = count + 1
				end
			end
		end
	end
	cm:exec()
end

function season_menu(_id)
	cm:hide()
	local h = hintbox.new{caption=plugin_title, text='Suche Episoden...', icon=plutotv_vod_png}
	h:paint()
	local seasons = 1
	local c = curl.new()
	local c_data = getdata("http://api.pluto.tv/v3/vod/series/".. _id .."/seasons?includeItems=true&deviceType=web")
	if c_data then
		local jd = json:decode(c_data)
		if jd then
			sm = menu.new{name=jd.name, has_shadow=true, icon=plutotv_vod_png}
			if jd.featuredImage.path then
				getdata(jd.featuredImage.path,bigPicBG)
				showBGPicture()
			end
			episodelist = {}
			local count = 1
			for i=1, #jd.seasons do
				sm:addItem{type="forwarder", name="Season "..i, action="episode_menu", id=i, hint=hint_value("hinttext","Staffel " ..i) , hint_icon=hint_value("hinticon","Serie"), icon=godirect("icon", count), enabled=true, directkey=godirect("directkey", count)}
				seasons = i
				episodelist_details = {}
				for k = 1, #jd.seasons[i].episodes do
					episodelist_details[k] =
					{
						title = jd.name;
						season = i;
						episode = k;
						name = i.."x"..string.format("%02d",k).." - ".. jd.seasons[i].episodes[k].name;
						desc = jd.seasons[i].episodes[k].description;
						duration = math.floor(tonumber(jd.seasons[i].episodes[k].originalContentDuration) / 1000 / 60 + 0.5);
						uuid = jd.seasons[i].episodes[k]._id;
						cover = jd.seasons[i].episodes[k].covers[1].url;
						type = jd.seasons[i].episodes[k].type;
						rating = jd.seasons[i].episodes[k].rating;
						genre = jd.seasons[i].episodes[k].genre;
					}
				end
				table.insert(episodelist, i, episodelist_details)
				if count == 0 then
					count = 11
				elseif count == 9 then 
					count = 0
				else
					count = count + 1
				end
			end
		end
	end
	h:hide()
	if seasons == 1 then
		hide_sm = false
		episode_menu(seasons)
	else
		hide_sm = true
		sm:exec()
	end
	hideBGPicture(true)
	os.execute("rm "..bigPicBG);
end

function episode_menu(s)
	if hide_sm then
		sm:hide()
	end
	em = menu.new{name=episodelist[tonumber(s)][1].title .. " - Season "..s, has_shadow=true, icon=plutotv_vod_png}
	for season, episodelist_detail in pairs (episodelist) do
		if season == tonumber(s) then
			local count = 1
			for episode, episode_detail in pairs(episodelist_detail) do
				em:addItem{type="forwarder", name=episode_detail.name, action="show_playback_info_e", id=episode_detail.uuid, icon=godirect("icon", count), hint=hint_value("hinttext",episode_detail.duration), hint_icon=hint_value("hinticon",episode_detail.duration), value=hint_value("value",episode_detail.duration), enabled=true, directkey=godirect("directkey", count)}
				playback_details[episode_detail.uuid] = 
				{
					uuid = episode_detail.uuid;
					name = episode_detail.name;
					desc = episode_detail.desc;
					cover = episode_detail.cover;
					type =  episode_detail.type;
					duration = episode_detail.duration;
					rating = episode_detail.rating;
					genre = episode_detail.genre;
					title = episodelist[tonumber(s)][1].title;
					eptitle = episode_detail.name;
				}
				if count == 0 then
					count = 11
				elseif count == 9 then 
					count = 0
				else
					count = count + 1
				end
			end
		end
	end
	em:exec()
end

--Menü anzeigen
function MainMenue()
	local h = hintbox.new{caption=plugin_title, text='Starte...', icon=plutotv_vod_png}
	h:paint()
	get_cat();
	m = menu.new{name=plugin_title, has_shadow=true, icon=plutotv_vod_png}
	local count = 1
	local htext = nil
	if hints then
		htext = "Untermenü"
	end
	for _id,_name in pairs(catlist) do
		m:addItem{type="forwarder", name=conv_utf8(_name), action="cat_menu", hint=htext, id=_id, icon=godirect("icon", count), enabled=true, directkey=godirect("directkey", count)}
		if count == 0 then
			count = 11
		elseif count == 9 then 
			count = 0
		else
			count = count + 1
		end
	end
	h:hide()
	m:exec()
	hideBGPicture(true)
	os.execute("rm /tmp/plutotv-vod_*.*");
	collectgarbage()
end

nMisc = misc.new()
vPlay = video.new()
have_ffmpeg = which("ffmpeg")
coverPic = "/tmp/plutotv-vod_cover.jpg"
bigPicBG = "/tmp/plutotv-vod_bg.jpg"
hints = get_hints_menu()
MainMenue()
