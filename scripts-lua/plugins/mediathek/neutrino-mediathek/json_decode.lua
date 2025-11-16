local function logCurlRequest(url, file, post, mode)
	local postPreview = ''
	if post ~= nil then
		postPreview = tostring(post)
		if #postPreview > 200 then
			postPreview = postPreview:sub(1, 200) .. '…'
		end
	end
	H.printf('[neutrino-mediathek] mode=%s url=%s file=%s post=%s', tostring(mode), tostring(url), tostring(file), postPreview)
end

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
		logCurlRequest(url, data, post, mode)
		local ret = 1
		if ((mode > queryMode_None) and (mode < queryMode_beginPOSTmode)) then
			box, ret = curlDownload(url, data, nil, false, false, true)
		end
		if (ret ~= CURL.OK and (mode > queryMode_beginPOSTmode)) then
			box, ret = curlDownload(url, data, post, false, false, false)
		end
		if ret ~= CURL.OK then
			G.hideInfoBox(box)
			return nil, 'download_failed'
		end
	end

	local fp = io.open(data, 'r')
	if fp == nil then
		G.hideInfoBox(box)
		return nil, 'fopen_failed'
	end
	local s = fp:read('*a')
	fp:close()
	G.hideInfoBox(box)
	return s, nil
end

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
	fp = io.open(data, 'r')
	if fp == nil then
		G.hideInfoBox(box)
		error('Error connecting to database server.')
	end
	s = fp:read('*a')
	fp:close()
	G.hideInfoBox(box)
	return s
end

function checkJsonError(tab)
	if not tab or tab.error == nil then
		return false
	end
	if tab.error > 0 then
--		paintAnInfoBoxAndWait(tab.entry .. "\nAbort...", WHERE.CENTER, conf.guiTimeMsg)
		H.printf('Error: %s', tab.entry)
		messagebox.exec{title='Error', text=tab.entry, buttons={ 'ok' } }
		return false
	end
	return true
end

function decodeJson(data)
	local s = H.trim(data)
	local x = s.sub(s, 1, 1)
	if x ~= '{' and x ~= '[' then
		local box = G.paintInfoBox('Error parsing json data.')
		P.sleep(4)
		G.hideInfoBox(box)
		return nil, 'json_invalid'
	end
	local ok, result = pcall(J.decode, J, s)
	if not ok then
		return nil, 'json_decode_failed'
	end
	return result, nil
end
