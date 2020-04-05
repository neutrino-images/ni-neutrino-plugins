function getJsonData2(url, file, post, mode)
	local box = nil
	local data = nil
	local dataExist = false

	if ((not file) or (file == nil)) then
		data = jsonData
	else
		data = file
		if (H.fileExist(data) == true) then dataExist = true end
	end
	if ((dataExist == false) or (noCacheFiles == true)) then
		if ((mode > queryMode_None) and (mode < queryMode_beginPOSTmode)) then
			box = curlDownload(   url, data, nil,      false,  false, true)
		end
		if (mode > queryMode_beginPOSTmode) then
			box = curlDownload(   url, data, post,     false,  false, false)
		end
	end

	local fp, s
	fp = io.open(data, 'r')	-- no NLS
	if fp == nil then
		G.hideInfoBox(box)
		error('Error connecting to database server.')	-- no NLS
	end
	s = fp:read('*a')	-- no NLS
	fp:close()
	G.hideInfoBox(box)
	return s
end -- function getJsonData2

function getJsonData(url, file)
	local box = nil
	local data = nil
	local dataExist = false
	if (not file) then
		data = jsonData
	else
		data = file
		if (H.fileExist(data) == true) then dataExist = true end
	end
	if ((dataExist == false) or (noCacheFiles == true)) then
		box = downloadFile(url, data, false)
	end

	local fp, s
	fp = io.open(data, 'r')	-- no NLS
	if fp == nil then
		G.hideInfoBox(box)
		error('Error connecting to database server.')	-- no NLS
	end
	s = fp:read('*a')	-- no NLS
	fp:close()
	G.hideInfoBox(box)
	return s
end

function checkJsonError(tab)
	if tab.error > 0 then
--		paintMiniInfoBoxAndWait(tab.entry .. "\nAbort...")
		H.printf('Error: %s', tab.entry)	-- no NLS
		messagebox.exec{title='Error', text=tab.entry, buttons={ 'ok' } }	-- no NLS
		return false
	end
	return true
end -- function checkJsonError

function decodeJson(data)
	local s = H.trim(data)
	local x = s.sub(s, 1, 1)
	if x ~= '{' and x ~= '[' then	-- no NLS
		local box = G.paintInfoBox('Error parsing json data.')	-- no NLS
		P.sleep(4)
		G.hideInfoBox(box)
		return nil
	end
	return J:decode(s)
end -- function decodeJson
