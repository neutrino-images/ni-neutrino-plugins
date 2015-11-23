
function getJsonData(url)
	local box = paintMiniInfoBox(readData);
	os.remove(jsonData);
	local cmd = wget_cmd .. jsonData .. " '" .. url .. "'";
	print(cmd);
	os.execute(cmd);
	
	local fp, s;
	fp = io.open(jsonData, "r");
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
		error("Error parsing json data.");
	end
	return json:decode(s);
end

