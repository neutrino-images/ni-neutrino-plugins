--[[
	plutotv-vod.lua v1.0

	Copyright (C) 2021 TangoCash
	License: WTFPLv2
]]

plugin = "Pluto TV VOD"

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
	local fname = "/tmp/plutovod_cover.jpg";
	getdata(_picture,fname)
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
	token = "?advertisingId=&appName=web&appVersion=unknown&appStoreUrl=&architecture=&buildVersion=&clientTime=0&deviceDNT=0&deviceId=" .. gen_ids() .. "&deviceMake=Chrome&deviceModel=web&deviceType=web&deviceVersion=unknown&includeExtendedEvents=false&sid=" .. gen_ids() .. "&userId=&serverSideAds=true"
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

--auf Tasteneingaben reagieren
function getInput()
	local i = 0
	local d = 500 -- ms
	local t = -1  --(get_timing_menu() * 1000) / d
	if t == 0 then
		t = -1 -- no timeout
	end
	repeat
		i = i + 1
		msg, data = n:GetInput(d)
		if msg >= RC["0"] and msg <= RC.MaxRC then
			i = 0 -- reset timeout
		end
		-- Taste Rot startet Stream
		if (msg == RC['ok']) or (msg == RC['red']) then
			mode = 1;
			break;
		-- Taste Gruen startet Download
		elseif (msg == RC['green']) and have_ffmpeg then
			mode = 2;
			break;
		elseif (msg == RC['up'] or msg == RC['page_up']) then
			ct1:scroll{dir="up"};
		elseif (msg == RC['down'] or msg == RC['page_down']) then
			ct1:scroll{dir="down"};
		end
	-- Taste Exit oder Menü beendet das Fenster
	until msg == RC['home'] or msg == RC['setup'] or i == t;

	if msg == RC['setup'] then
		return MENU_RETURN["EXIT_ALL"]
	end
end

function playback_stream(uuid)
	cm:hide()
	if em then
		em:hide()
	end
	local h = hintbox.new{caption=plugin, text='Starte\n"' .. playback_details[uuid].name .. '"', icon=plutotv_vod_png}
	h:paint()
	getVideoData(uuid)
	h:hide()
	if (re_url) then
		local vPlay  =  video.new()
		local info1  =  playback_details[uuid].desc
		if playback_details[uuid].type == "episode" then
			info1 = playback_details[uuid].name
			local info2 = playback_details[uuid].desc
		end
		current_uuid = uuid
		vPlay:setInfoFunc("epgInfo")
		vPlay:PlayFile(playback_details[uuid].title or playback_details[uuid].name, re_url, info1, info2 or "");
	end
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
			Format = 'ts'
		end
		if filename and Format then
			local dls  = "/tmp/.plutotv_vod_dl.sh"
			dlname = filename
			local script=io.open(dls,"w")
			script:write('echo "download start" ;\n')
			script:write("ffmpeg -y -nostdin -loglevel 30 -i '" .. streamUrl .. "' -c copy  " .. dlname   .. "." .. Format .. "\n")
			script:write('if [ $? -eq 0 ]; then \n')
			script:write('wget -q http://127.0.0.1/control/message?popup="Video ' .. title .. ' wurde heruntergeladen." -O /dev/null ; \n')
			script:write('else \n')
			script:write('wget -q http://127.0.0.1/control/message?popup="Download ' .. title .. ' FEHLGESCHLAGEN" -O /dev/null ; \n')
			script:write('rm ' .. dlname .. '.*; \n')
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
	cm:hide()
	if em then
		em:hide()
	end
	local h = hintbox.new{caption=plugin, text='Download im Hintergrund wird vorbereitet\n\n"' .. playback_details[uuid].name .. '"', icon=plutotv_vod_png}
	h:paint()
	getVideoData(uuid)
	h:hide()
	if (re_url) then
		if dl_check(re_url) then
			local h1 = hintbox.new{caption=plugin, text='Download im Hintergrund wird gestartet\n\n"' .. playback_details[uuid].name .. '"', icon=plutotv_vod_png}
			h1:paint()
			local filename = plugin .. "_" .. playback_details[uuid].name
			if playback_details[uuid].type == "episode" then
				filename = plugin .. "_".. playback_details[uuid].title .. "_" .. playback_details[uuid].name
			end
			filename = filename:gsub("[%p%s/]", "_")
			if fh:exist(dlPath.."/"..filename..'.ts', 'f') then
				h1:hide()
				local h2 = hintbox.new{caption=plugin, text='Download bereits vorhanden...\n\n"' .. playback_details[uuid].name .. '"', icon=plutotv_vod_png}
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
			local h3 = hintbox.new{caption=plugin, text="Ein Download läuft bereits...\n\nBitte warten bis dieser abgeschlossen ist  ", icon=plutotv_vod_png}
			h3:paint()
			sleep(3)
			h3:hide()
		end
	end
end

function save_info(uuid,filename)
	local ch = plugin
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
	getdata(playback_details[uuid].cover,filename..".jpg")
end

function epgInfo(xres, yres, aspectRatio, framerate)
	local off_w,x,y,w,h  = 0,0,0,0,0
	local space = OFFSET.INNER_MID
	local wow = cwindow.new{x=x, y=y, dx=w, dy=h, title=playback_details[current_uuid].title or playback_details[current_uuid].name }
	local tf = wow:headerHeight() + wow:footerHeight()
	w,h = n:scale2Res(600), n:scale2Res(300) + tf
	local tw = n:getRenderWidth(FONT.MENU_TITLE,playback_details[current_uuid].title or playback_details[current_uuid].name) + (wow:headerHeight() * 2)
	if tw > w then
		w = tw
		if w > 1200 then w = 1200 end
	end

	local maxW ,maxH = n:scale2Res(440), n:scale2Res(368)
	local picW, picH = n:GetSize("/tmp/plutovod_cover.jpg")
	maxW,maxH = rescalePic(picW,picH,maxW,maxH)
	off_w,h = maxW,maxH
	cpicture.new{parent=wow, x=space, y=space, dx=maxW, dy=maxH, image="/tmp/plutovod_cover.jpg"}
	h = maxH + tf + (space*2)
	local wP =  (maxW * 2) + (space * 3)
	if w < wP then
		w = wP
	end
	local episode = playback_details[current_uuid].eptitle or ""
	local desc_text = episode .. conv_utf8(playback_details[current_uuid].desc).."\n\n"..playback_details[current_uuid].duration.." min".."\n" .. playback_details[current_uuid].rating.."\n" .. conv_utf8(playback_details[current_uuid].genre)
	ct = ctext.new{parent=wow, x=off_w + (space*2), y=space, dx=w-off_w, dy=h-tf, text=desc_text, mode="ALIGN_TOP | ALIGN_SCROLL"}

	wow:setDimensionsAll(x , y, w, h)
	wow:setCenterPos{3}
	wow:paint()

	local msg, data = nil,nil
	repeat
		msg, data = n:GetInput(500)
		if ct and (msg == RC.up or msg == RC.page_up) then
			ct:scroll{dir="up"}
		elseif ct and (msg == RC.down or msg == RC.page_down) then
			ct:scroll{dir="down"}
		end
	until msg == RC.ok or msg == RC.home or msg == RC.info
	wow:hide()
end

-- Filminfos anzeigen
function show_playback_info(uuid)
	if em then
		em:hide()
	end

	mode = 0;

	local x  = n:scale2Res(150);
	local y  = n:scale2Res(70);
	local dx = n:scale2Res(1000);
	local dy = n:scale2Res(600);
	local ct1_x = n:scale2Res(400);

	local window_title = playback_details[uuid].name;
	local btn_text = "Film"
	if playback_details[uuid].type == "episode" then
		btn_text = "Episode"
	end
	local desc_text = conv_utf8(playback_details[uuid].desc).."\n\n"..playback_details[uuid].duration.." min".."\n" .. playback_details[uuid].rating.."\n" .. conv_utf8(playback_details[uuid].genre)
	w = cwindow.new{x=x, y=y, dx=dx, dy=dy, title=conv_utf8(window_title), icon=plutotv_vod_png, btnRed=btn_text .." abspielen", btnGreen=btn_text.." downloaden" };
	local tmp_h = w:headerHeight() + w:footerHeight();
	ct1 = ctext.new{parent=w, x=ct1_x, y=n:scale2Res(20), dx=dx-ct1_x-n:scale2Res(2), dy=dy-tmp_h-n:scale2Res(40), text=desc_text, mode = "ALIGN_TOP | ALIGN_SCROLL | DECODE_HTML"};

	if playback_details[uuid].cover ~= nil then
		getPicture(conv_utf8(playback_details[uuid].cover));

		local pic_x = n:scale2Res(20)
		local pic_y = n:scale2Res(35)
		local pic_w = n:scale2Res(347)
		local pic_h = n:scale2Res(500)
		local tmp_w;
		tmp_w, tmp_h = n:GetSize("/tmp/plutovod_cover.jpg");
		if tmp_w < pic_w then
			pic_x = (ct1_x - tmp_w) / 2;
		else
			pic_x = (ct1_x - pic_w) / 2;
		end
		cpicture.new{parent=w, x=pic_x, y=pic_y, dx=pic_w, dy=pic_h, image="/tmp/plutovod_cover.jpg"}
	end

	w:paint();
	ret = getInput();
	w:hide();

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
	local h = hintbox.new{caption=plugin, text='Starte...', icon=plutotv_vod_png}
	h:paint()
	local r = false
	local c = curl.new()
	local c_data = getdata("http://api.pluto.tv/v3/vod/categories?includeItems=true&deviceType=web")
	h:hide()
	if c_data then
		local jd = json:decode(c_data)
		if jd then
			for i = 1, jd.totalCategories do
				if jd.categories[i] then
					table.insert(catlist, i, jd.categories[i].name)
					itemlist_details = {}
					for k = 1, #jd.categories[i].items do
						local _duration = 0
						if jd.categories[i].items[k].duration then
							_duration = tonumber(jd.categories[i].items[k].duration) / 1000 / 60
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
					cm:addItem{type="forwarder", name=conv_utf8(item_detail.name), action="show_playback_info", id=item_detail.uuid, icon=godirectbutton(count), value="("..item_detail.duration.." min)", enabled=true, directkey=godirectkey(count)}
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
					cm:addItem{type="forwarder", name=conv_utf8(item_detail.name), action="season_menu", id=item_detail.uuid, icon=godirectbutton(count), value="(Serie)", enabled=true, directkey=godirectkey(count)}
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
	local h = hintbox.new{caption=plugin, text='Suche Episoden...', icon=plutotv_vod_png}
	h:paint()
	local c = curl.new()
	local c_data = getdata("http://api.pluto.tv/v3/vod/series/".. _id .."/seasons?includeItems=true&deviceType=web")
	h:hide()
	if c_data then
		local jd = json:decode(c_data)
		if jd then
			sm = menu.new{name=jd.name, has_shadow=true, icon=plutotv_vod_png}
			episodelist = {}
			local count = 1
			for i=1, #jd.seasons do
				sm:addItem{type="forwarder", name="Season "..i, action="episode_menu", id=i, icon=godirectbutton(count), enabled=true, directkey=godirectkey(count)}
				episodelist_details = {}
				for k = 1, #jd.seasons[i].episodes do
					episodelist_details[k] =
					{
						title = jd.name;
						season = i;
						episode = k;
						name = i.."x"..string.format("%02d",k).." - ".. jd.seasons[i].episodes[k].name;
						desc = jd.seasons[i].episodes[k].description;
						duration = tonumber(jd.seasons[i].episodes[k].duration) / 1000 / 60;
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
	sm:exec()
end

function episode_menu(s)
	sm:hide()
	em = menu.new{name=episodelist[tonumber(s)][1].title .. " - Season "..s, has_shadow=true, icon=plutotv_vod_png}
	for season, episodelist_detail in pairs (episodelist) do
		if season == tonumber(s) then
			local count = 1
			for episode, episode_detail in pairs(episodelist_detail) do
				em:addItem{type="forwarder", name=episode_detail.name, action="show_playback_info", id=episode_detail.uuid, icon=godirectbutton(count), value="("..episode_detail.duration.." min)", enabled=true, directkey=godirectkey(count)}
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
	get_cat();
	m = menu.new{name=plugin, has_shadow=true, icon=plutotv_vod_png}
	local count = 1
	for _id,_name in pairs(catlist) do
		m:addItem{type="forwarder", name=conv_utf8(_name), action="cat_menu", id=_id, icon=godirectbutton(count), enabled=true, directkey=godirectkey(count)}
		if count == 0 then
			count = 11
		elseif count == 9 then 
			count = 0
		else
			count = count + 1
		end
	end
	m:exec()
	os.execute("rm /tmp/plutovod_*.*");
	os.execute("rm "..plutotv_vod_png);
	collectgarbage()
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

have_ffmpeg = which("ffmpeg")

plutotv_vod_png = decodeImage("data:image/png;base64,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");
MainMenue()
