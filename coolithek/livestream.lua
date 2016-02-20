
function getOklivetv_chan(chan)
	if (chan == "ORF-1") then
		return "orf-eins-live"
	elseif (chan == "ORF-2") then
		return "orf-2-live"
	elseif (chan == "SRF-1") then
		return "srf-1-tv-live"
	elseif (chan == "SRF-2") then
		return "srf-zwei-live"
	elseif (chan == "SRF-Info") then
		return "srf-info-live"
	elseif (chan == "Music VIVA-CH") then
		return "viva-germany-live"
	elseif (chan == "Music MTV-CH") then
		return "mtv-schweiz-live"
	else
		return nil
	end
end

-- THX Jacek ;)
function getOklivetv_m3u8(chan)

	local url = getOklivetv_chan(chan)
	if url == nil then return nil end

	local box, ret, feed_data = downloadFile('http://oklivetv.com/' ..  url, "", true)
	if feed_data then
		local urlvid = feed_data:match("<div%s+class=\"screen fluid%-width%-video%-wrapper\">.-src='(.-)'.-</div>")
		box, ret, feed_data = downloadFile(urlvid, "", true)
		local url_m3u8 = feed_data:match('|URL|%d+|%d+|%d+|%d+|m3u8|(.-)|bottom')
		if url_m3u8 then
			return "http://46.101.171.43/live/" .. url_m3u8 .. ".m3u8"
		else
			return nil
		end
	end
	return nil
end

-- THX Jacek ;)
function getTecTimeTv_m3u8(url)
	local box, ret, feed_data = downloadFile(url, "", true)
	if feed_data then
		local m3u_url = feed_data:match('hlsvp.:.(https:\\.-m3u8)') 
		m3u_url = m3u_url:gsub("\\", "")
		return m3u_url
	end
	return nil
end

function playLivestream(_id)

	i = tonumber(_id);
	local title = videoTable[i][1] .. " Livestream";
	local url = videoTable[i][2];
	local parse_m3u8 = tonumber(videoTable[i][3]);

	-- for backward compatibility
	if ((videoTable[i][1] == "ORF-1") or (videoTable[i][1] == "ORF-2")) then
		parse_m3u8 = 3
	end

	local bw;
	local res;
	local qual;
	if (conf.streamQuality == "max") then
		qual = "max";
	elseif (conf.streamQuality == "normal") then
		qual = "normal";
	else
		qual = "min";
	end
	if ((parse_m3u8 == 1) or (parse_m3u8 == 2) or (parse_m3u8 == 3)) then
		local mode = parse_m3u8
		if (parse_m3u8 == 3) then
			-- oklivetv for orf/srf
			url = getOklivetv_m3u8(videoTable[i][1])
			mode = 1
			if url == nil then
				return MENU_RETURN.REPAINT
			end
		end
		m3u8Ret = get_m3u8url(url, mode);
		url     = m3u8Ret['url'];
		bw      = tonumber(m3u8Ret['bandwidth']);
		res     = m3u8Ret['resolution'];
		qual    = m3u8Ret['qual'];
	else
		bw = nil;
		res = "-";
	end
	if (bw == nil) then
		bw = "-";
	else
		bw = tostring(math.floor(bw/1000 + 0.5)) .. "K";
	end
	local msg1 = string.format("Bitrate: %s, Auflösung: %s, Qualität: %s", bw, res, qual);

	local screen = saveFullScreen()
	hideMenu(m_live)
	hideMainWindow()

	PlayMovie(title, url, msg1, url, false)

	if forcePluginExit == true then
		menuRet = MENU_RETURN.EXIT_ALL
		return menuRet
	end

	restoreFullScreen(screen, true)
	return MENU_RETURN.REPAINT;
end

function playLivestream2(_id)

	i = tonumber(_id);
	local title = "TecTime TV"
	local url = "https://www.youtube.com/watch?v=dvblFe1W5Q8"
	local parse_m3u8 = 10

	local bw;
	local res;
	local qual;
	if (conf.streamQuality == "max") then
		qual = "max";
	elseif (conf.streamQuality == "normal") then
		qual = "normal";
	else
		qual = "min";
	end
	if (parse_m3u8 == 10) then
		local mode = 1
		if (parse_m3u8 == 10) then
			-- TecTime TV
			url = getTecTimeTv_m3u8(url)
			if url == nil then
				return MENU_RETURN.REPAINT
			end
		end
		m3u8Ret = get_m3u8url(url, mode);
		url     = m3u8Ret['url'];
		bw      = tonumber(m3u8Ret['bandwidth']);
		res     = m3u8Ret['resolution'];
		qual    = m3u8Ret['qual'];
	else
		bw = nil;
		res = "-";
	end
	if (bw == nil) then
		bw = "-";
	else
		bw = tostring(math.floor(bw/1000 + 0.5)) .. "K";
	end
	local msg1 = string.format("Bitrate: %s, Auflösung: %s, Qualität: %s", bw, res, qual);

	local screen = saveFullScreen()
	hideMenu(m_live)
	hideMainWindow()

	PlayMovie(title, url, msg1, url, false)

	if forcePluginExit == true then
		menuRet = MENU_RETURN.EXIT_ALL
		return menuRet
	end

	restoreFullScreen(screen, true)
	return MENU_RETURN.REPAINT;
end

function getLivestreams()
	local s = getJsonData(url_base .. "/?" .. actionCmd_livestream);
	local j_table = decodeJson(s);
	if checkJsonError(j_table) == false then return false end

	for i = 1, #j_table.entry do
		local name = j_table.entry[i].title;
		name = string.gsub(name, " Livestream", "");
		local configName = "livestream_" .. name
		configName = string.gsub(configName, "[. -]", "_");
		videoTable[i] = {};
		videoTable[i][1] = name;			-- name
		videoTable[i][2] = j_table.entry[i].url;	-- url
		videoTable[i][3] = j_table.entry[i].parse_m3u8;	-- parse_m3u8 flag
		videoTable[i][4] = configName;			-- config name
	end
	return true
end

function livestreamMenu()
	if (#videoTable == 0) then
		getLivestreamConfig()
	end

	m_live = menu.new{name=pluginName .. "-Livestreams", icon=pluginIcon};
	m_live:addItem{type="subhead", name=langStr_channelSelection};
	m_live:addItem{type="separator"};
	m_live:addItem{type="back"};
	m_live:addItem{type="separatorline"};
--	m_live:addKey{directkey=RC["home"], id="home", action="key_home"}
--	m_live:addKey{directkey=RC["setup"], id="setup", action="key_setup"}
	addKillKey(m_live)

	local i
	for i = 1, #videoTable do
		if (conf.livestream[i] == "on") then
			m_live:addItem{type="forwarder", action="playLivestream", id=i, name=videoTable[i][1]};
		end
	end

	m_live:addItem{type="forwarder", action="playLivestream2", id=100, name="TecTime TV"};

	m_live:exec()
	restoreFullScreen(mainScreen, false)

	if menuRet == MENU_RETURN.EXIT_ALL then
		return menuRet
	end
	return MENU_RETURN.REPAINT;
end

