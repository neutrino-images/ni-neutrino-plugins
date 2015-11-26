
function getJsonData(url, file)
	local box = nil
	local dataExist = false
	if (not file) then
		data = jsonData
	else
		data = file
		if (helpers.fileExist(data) == true) then dataExist = true end
	end
	if ((dataExist == false) or (noCacheFiles == true)) then
		box = paintMiniInfoBox(readData);
		os.remove(data);
		local cmd = wget_cmd .. data .. " '" .. url .. "'";
		print(cmd);
		os.execute(cmd);
	end
	
	local fp, s;
	fp = io.open(data, "r");
	if fp == nil then
		gui.hideInfoBox(box)
		error("Error connecting to database server.")
	end;
	s = fp:read("*a");
	fp:close();
	gui.hideInfoBox(box)
	return s;
end

function checkJsonError(tab)
	if tab.error > 0 then
		local box = gui.paintInfoBox(tab.entry .. "\nAbort...");
		posix.sleep(4);
		gui.hideInfoBox(box)
		return false
	end
	return true
end

function decodeJson(data)
	local s = helpers.trim(data);
	local x = s.sub(s, 1, 1);
	if x ~= "{" and x ~= "[" then
		local box = gui.paintInfoBox("Error parsing json data.");
		posix.sleep(4);
		gui.hideInfoBox(box)
		return nil
	end
	return json:decode(s);
end

