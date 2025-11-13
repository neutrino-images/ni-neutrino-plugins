-- THX Jacek ;)
function getTecTimeTv_m3u8(url)
	local box, ret, feed_data = downloadFile(url, '', true, user_agent2)
	if feed_data then
		local m3u_url = feed_data:match('hlsvp.:.(https:\\.-m3u8)')
		m3u_url = m3u_url:gsub('\\', '')
		return m3u_url
	end
	return nil
end

function playLivestream(_id)
	local i = tonumber(_id)
	local videoData = videoTable[i]
	local title = videoData[1] .. ' ' .. l.lifeTitle
	local url = videoData[2]
	local url2 = ""
	local parse_m3u8 = tonumber(videoData[3])

	local qualityMap = { max = 'max', normal = 'normal', default = 'min' }
	local qual = qualityMap[conf.streamQuality] or 'min'

	if parse_m3u8 and parse_m3u8 >= 0 and parse_m3u8 <= 3 then
		local m3u8Ret = get_m3u8url(url, parse_m3u8)
		print("---------------------")
		H.tprint(m3u8Ret)
		print("---------------------")
		if m3u8Ret then
			url = m3u8Ret['url']
			url2 = m3u8Ret['url2']
			bw = tonumber(m3u8Ret['bandwidth'])
			res = m3u8Ret['resolution']
			qual = m3u8Ret['qual']
		else
			bw, res = nil, '-'
		end
	else
		bw, res = nil, '-'
	end

	bw = bw and tostring(math.floor(bw / 1000 + 0.5)) .. 'K' or '-'
	local msg1 = string.format('%s: %s, %s: %s, %s: %s', l.lifeBitRate, bw, l.lifeResolution, res, l.lifeQuality, qual)

	local screen = saveFullScreen()
	hideMenu(m_live)
	hideMainWindow()

	playMovie(url, title, msg1, url, false, url2)

	if forcePluginExit then
		return MENU_RETURN.EXIT_ALL
	end

	restoreFullScreen(screen, true)
	return MENU_RETURN.REPAINT
end

function playLivestream2(_id)
	i = tonumber(_id)
	local title = 'TecTime TV'
	local url = 'https://www.youtube.com/watch?v=dvblFe1W5Q8'
	local parse_m3u8 = 10

	local bw
	local res
	local qual
	if (conf.streamQuality == 'max') then
		qual = 'max'
	elseif (conf.streamQuality == 'normal') then
		qual = 'normal'
	else
		qual = 'min'
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
		m3u8Ret	= get_m3u8url(url, mode)
		url		= m3u8Ret['url']
		bw		= tonumber(m3u8Ret['bandwidth'])
		res		= m3u8Ret['resolution']
		qual	= m3u8Ret['qual']
	else
		bw = nil
		res = '-'
	end
	if (bw == nil) then
		bw = '-'
	else
		bw = tostring(math.floor(bw/1000 + 0.5)) .. 'K'
	end
	local msg1 = string.format(l.lifeBitRate .. ': %s, ' .. l.lifeResolution .. ': %s, ' .. l.lifeQuality .. ': %s', bw, res, qual)

	local screen = saveFullScreen()
	hideMenu(m_live)
	hideMainWindow()

	playMovie(url, title, msg1, url, false)

	if forcePluginExit == true then
		menuRet = MENU_RETURN.EXIT_ALL
		return menuRet
	end

	restoreFullScreen(screen, true)
	return MENU_RETURN.REPAINT
end

function getLivestreams()
	local s, err = getJsonData2(url_new .. actionCmd_livestream, nil, nil, queryMode_listLivestreams)
	if not s then
		messagebox.exec{title=pluginName, text=l.networkError, buttons={'ok'}}
		return false
	end
	local j_table; j_table, err = decodeJson(s)
	if not j_table then
		messagebox.exec{title=pluginName, text=l.jsonError, buttons={'ok'}}
		return false
	end

	if not checkJsonError(j_table) then
		return false
	end

	for i = 1, #j_table.entry do
		local entry = j_table.entry[i]
		local name = entry.title
		local configName = 'livestream_' .. name
		configName = string.gsub(configName, '[. -]', '_')

		videoTable[i] = {
			name,                 -- entry[1] -> Name
			entry.url,            -- entry[2] -> URL
			entry.parse_m3u8,     -- entry[3] -> Parse m3u8
			configName            -- entry[4] -> Config Name
		}
	end

	-- Optional videoTable-Output
	-- for i, entry in ipairs(videoTable) do
	-- 	print(string.format("Entry %d: Name: %s, URL: %s, Parse m3u8: %s, Config Name: %s", 
	-- 		i, entry[1], entry[2], tostring(entry[3]), entry[4]))
	-- end

	return true
end

function livestreamMenu()
	if (#videoTable == 0) then
		getLivestreamConfig()
	end

	m_live = menu.new{name=pluginName .. ' - ' .. l.lifestreamsHeader, icon=pluginIcon}
	m_live:addItem{type="subhead", name=l.livestreamsSubHeader}
	m_live:addItem{type="separator"}
	m_live:addItem{type="back", hint_icon="hint_back", hint=l.backH}
	m_live:addItem{type="separatorline"}
--	m_live:addKey{directkey=RC["home"], id="home", action="key_home"}
--	m_live:addKey{directkey=RC["setup"], id="setup", action="key_setup"}
	addKillKey(m_live)

	local i
	for i=1, #videoTable do
		if (conf.livestream[i] == 'on') then
			m_live:addItem{type='forwarder', action='playLivestream', hint_icon="hint_service", hint=l.lifestreamsEntryH, id=i, name=videoTable[i][1]}
		end
	end

--	m_live:addItem{type="forwarder", action="playLivestream2", id=100, name="TecTime TV"}

	m_live:exec()
	restoreFullScreen(mainScreen, false)
	if menuRet == MENU_RETURN.EXIT_ALL then
		return menuRet
	end
	return MENU_RETURN.REPAINT
end
