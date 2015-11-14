
function playLivestream(_id)

	local returnAll = true

	i = tonumber(_id);
	hideMenu(m_live)
	hideMainWindow()

	local title = videoTable[i][1] .. " Livestream";
	local url = videoTable[i][2];
	n:setBlank(true)
	os.execute("pzapit -unmute")

	n:PlayFile(title, url, "", url);

	if (helpers.checkAPIversion(1, 8)) then n:enableInfoClock(false) end
--	collectgarbage();
	os.execute("pzapit -mute")
	posix.sleep(1)
	n:ShowPicture(backgroundImage)
	
	if (returnAll == true) then
		return MENU_RETURN.EXIT_ALL;
	else
		paintMainWindow()
		return MENU_RETURN.REPAINT;
	end
end

function getLivestreams()
	local s = getJsonData(url_livestream);
	local j_table = decodeJson(s);
	if checkJsonError(j_table) == false then return false end

	m_live = menu.new{name=pluginName .. "-Livestreams", icon=pluginIcon};
	m_live:addItem{type="subhead", name=langStr_channelSelection};
	m_live:addItem{type="separator"};
	m_live:addItem{type="back"};
	m_live:addItem{type="separatorline"};

--	m_live:addKey{directkey=RC["home"], id="home", action="key_home"}
--	m_live:addKey{directkey=RC["setup"], id="setup", action="key_setup"}

	for i = 1, #j_table.entry do
		local name = j_table.entry[i].title;
		name = string.gsub(name, " Livestream", "");
		local id = j_table.entry[i].id;
		videoTable[i] = {};
		videoTable[i][1] = name;
		videoTable[i][2] = j_table.entry[i].url;
		m_live:addItem{type="forwarder", action="playLivestream", id=i, name=name};
	end

	m_live:exec()
	paintMainWindow()

	if ret == MENU_RETURN.EXIT_ALL then
		return ret
	end
	return MENU_RETURN.REPAINT;
end

