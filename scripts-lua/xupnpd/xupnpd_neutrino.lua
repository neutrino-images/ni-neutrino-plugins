-- Plugin for converting channels lists from neutrino receivers
-- Author focus.cst@gmail.com
-- License GPL v2
-- Copyright (C) 2013 CoolStream International Ltd

-- flag to test as plain script, without xupnpd - cfg not defined in this case
local cst_test = false

if not cfg then
cfg={}
cfg.tmp_path='/tmp/'
cfg.feeds_path='/tmp/'
cfg.debug=1
cst_test = true
end

function trim(s)
	return (s:gsub("^%s*(.-)%s*$", "%1"))
end

function cst_debug(level, msg)
	if cfg.debug>level then
		print(msg)
	end
end

-- xupnpd has its own json module; plain lua (cst_test) uses cjson
function cst_json_decode(s)
	if json and json.decode then
		return json.decode(s)
	end
	return require("cjson").decode(s)
end

function isFile(name)
	if type(name)~="string" then return false end
	local f = io.open(name)
	if f then
		f:close()
		return true
	end
	return false
end

function cst_get_logo_hdd_dir()
	local d = nil
	local f = io.open("/var/tuxbox/config/neutrino.conf", "r")
	if f then
		for line in f:lines() do
			local _d = line:match("logo_hdd_dir=(.*)")
			if _d then
				d = _d
				goto continue
			end
		end
		::continue::
		f:close()
	end
	if d then
		cst_debug(0, "cst_get_logo_hdd_dir: logo_hdd_dir="..d)
	end
	return d
end

local logo_hdd_dir = cst_get_logo_hdd_dir()
local logo_flash_dir = "/usr/share/tuxbox/neutrino/icons/logo"
local logo_flash_dir_var = "/var/tuxbox/icons/logo"

function cst_get_logo(id, name)
	Path = {logo_hdd_dir, logo_flash_dir_var, logo_flash_dir}
	local x=5
	if string.sub(id ,5,5) == '0' then
		x = x + 1
		if string.sub(id ,6,6) == '0' then
			x = x + 1
			if string.sub(id ,7,7) == '0' then
				x = x + 1
			end
		end
	end
	id = string.sub(id ,x,16)

	chan = {name,id}
	for v, varPath in pairs(Path) do
		for v2, varChan in pairs(chan) do
			file = varPath .."/" .. varChan
			if isFile(file .. ".png") then
				return file .. ".png"
			end
			if isFile(file .. ".jpg") then
				return file .. ".jpg"
			end
		end
	end
	return nil
end

function cst_get_bouquets(s)
	local btable={}
	for string in string.gmatch(s, "(.-)%c") do
		if string then
			cst_debug(1, "########## bouquet="..string)
			local num = string.match(string, "%d+");
			if num then
				local len = string.len(num);
				local name = string.sub(string, len+1);
				btable[num] = name
				cst_debug(1, "num="..num.." name="..btable[num]);
			end
			--break; -- one bouquet
		end
	end
	return btable
end

function cst_get_channels(s)
	local ctable={}
	for string in string.gmatch(s, "(.-)%c") do
		idx = 1;
		if string then
			cst_debug(1, "########## channel="..string)
			local num = string.match(string, "%d+");
			if num then
				local len = string.len(num);
				local rest = string.sub(string, len+1);
				local id = string.match(rest, "%x+ ");
				len = string.len(id);
				local name = string.sub(rest, len+2);
				cst_debug(1, "num="..num.." id="..id.." name="..name)
				if id and name then
					table.insert(ctable, {id, name});
					idx = idx + 1;
				end
			end
		end
	end
	return ctable
end

function cst_read_url(url)
	local string = ""
	cst_debug(0, "url: "..url)
	if cst_test then
		local wget = "wget -q -O- "
		local turl = wget.."\""..url.."\""
		local file = io.popen(turl)
		repeat
			local st = file:read()
			if st then
				string = string..st.."\n";
			end
		until not st
		file:close()
	else
		string = http.download(url)
	end

	if string == nil then
		string =""
	end
	cst_debug(0, "url read: "..string.len(string))
	return string
end

-- ni-web /api/v1: returns the decoded answer or nil
function cst_api_get(feed, path)
	local data = cst_read_url('http://'..feed..'/api/v1/'..path)
	if data == "" then
		return nil
	end
	local ok, t = pcall(cst_json_decode, data)
	if not ok or type(t) ~= "table" then
		cst_debug(0, "api: no json answer for "..path)
		return nil
	end
	return t
end

-- the user bouquets that are not hidden and hold channels of the mode, as
-- getbouquets?fav=true listed them; the provider bouquets only if there is
-- no such user bouquet
function cst_api_bouquets(feed, mode)
	local t = cst_api_get(feed, "bouquets")
	if not t or type(t.items) ~= "table" then
		return nil
	end
	local user = {}
	local provider = {}
	for _, b in ipairs(t.items) do
		local count = b.radio_count
		if mode == "TV" then
			count = b.tv_count
		end
		if type(b.id) == "number" and b.hidden ~= true
		   and type(count) == "number" and count > 0 then
			if b.user_bouquet == true then
				table.insert(user, { id = b.id, name = b.name or "" })
			else
				table.insert(provider, { id = b.id, name = b.name or "" })
			end
		end
	end
	if #user > 0 then
		return user
	end
	cst_debug(0, "no user bouquets for "..mode..", using provider bouquets")
	return provider
end

-- all channels of one bouquet, page by page; nil if a page could not be read
function cst_api_channels(feed, mode, bouquet)
	local channels = {}
	local cursor = nil
	local pages = 0
	repeat
		local path = string.format("channels?bouquet=%d&mode=%s&limit=500", bouquet, string.lower(mode))
		if cursor then
			path = path.."&cursor="..cursor
		end
		local t = cst_api_get(feed, path)
		if not t or type(t.items) ~= "table" then
			return nil
		end
		for _, c in ipairs(t.items) do
			if type(c.id) == "string" and type(c.name) == "string" then
				table.insert(channels, { c.id, c.name })
			end
		end
		cursor = t.next_cursor
		pages = pages + 1
	until type(cursor) ~= "string" or cursor == "" or pages >= 100
	return channels
end

-- old /control/ interface, for boxes without ni-web
function cst_legacy_bouquet_list(feed, query)
	local data = cst_read_url('http://'..feed..'/control/getbouquets?'..query)
	if data == "" then
		return nil
	end
	local list = {}
	for num, name in pairs(cst_get_bouquets(data)) do
		table.insert(list, { id = tonumber(num), name = name })
	end
	table.sort(list, function(a, b) return a.id < b.id end)
	return list
end

-- user bouquets, all visible bouquets only if there is none; without user
-- bouquets those are the provider bouquets
function cst_legacy_bouquets(feed, mode)
	local list = cst_legacy_bouquet_list(feed, 'fav=true&mode='..mode)
	if list and #list > 0 then
		return list
	end
	return cst_legacy_bouquet_list(feed, 'mode='..mode)
end

function cst_legacy_channels(feed, mode, bouquet)
	local data = cst_read_url('http://'..feed..'/control/getbouquet?epg=true&mode='..mode..'&bouquet='..string.format("%d", bouquet))
	return cst_get_channels(data)
end

-- returns the number of playlists written, or nil if the box gave no bouquet list
function cst_save_bouqutes(feed, friendly_name, mode, sysip)
	local feedspath = cfg.feeds_path

	local get_channels = cst_api_channels
	local bouquets = cst_api_bouquets(feed, mode)
	if not bouquets then
		cst_debug(0, "no /api/v1 answer from "..feed..", trying /control/")
		get_channels = cst_legacy_channels
		bouquets = cst_legacy_bouquets(feed, mode)
	end
	if not bouquets then
		return nil
	end

	local written = 0
	for _, b in ipairs(bouquets) do
		local bouquet = get_channels(feed, mode, b.id)
		if bouquet and #bouquet > 0 then
			local bnum = string.format("%03d", b.id)
			local m3ufilename = cfg.tmp_path.."cst_"..friendly_name.."_"..mode.."_bouquet_"..bnum..".m3u"
			cst_debug(0, m3ufilename)
			local m3ufile = io.open(m3ufilename,"w")
			m3ufile:write("#EXTM3U name=\""..friendly_name..": "..mode.." - "..trim(b.name).."\" plugin=neutrino type=ts\n")
			for _, channelt in ipairs(bouquet) do
				local id = channelt[1];
				local name = channelt[2];

				local logo = cst_get_logo(id, name)
				if logo == nil then
					m3ufile:write("#EXTINF:0,"..name.."\n")
				else
					m3ufile:write("#EXTINF:0 logo="..sysip..logo .." ,"..name.."\n")
				end

				m3ufile:write("http://"..feed..":31339/id="..id.."\n")
			end
			m3ufile:close()
			os.execute(string.format('mv %s %s',m3ufilename,feedspath))
			written = written + 1
		end
	end
	return written
end

-- xupnpd reads the feeds a few seconds after its start, which can be before
-- neutrino answers or has its channel lists; ask again for a while then,
-- instead of waiting for the next feeds_update_interval
local cst_retries = 12
local cst_retry_delay = 10

function cst_updatefeed(feed,friendly_name)
	if not friendly_name then
		friendly_name = feed
	end

	local sysip = ""
	if not cst_test then
		sysip = www_location
		sysip = sysip:match('(http://%d*.%d*.%d*.%d*):*.')
	end

	local tries = 1
	while true do
		local tv = cst_save_bouqutes(feed, friendly_name, "TV", sysip)
		local radio = cst_save_bouqutes(feed, friendly_name, "RADIO", sysip)
		if (tv or 0) + (radio or 0) > 0 then
			return true
		end
		if tries >= cst_retries or cst_test then
			cst_debug(0, "no channel lists from "..feed)
			return false
		end
		cst_debug(0, "no channel lists from "..feed..", retry "..tries.." in "..cst_retry_delay.." s")
		os.execute("sleep "..cst_retry_delay)
		tries = tries + 1
	end
end

function cst_zapto(urlbase,id)
	local zap = urlbase.."/control/zapto?"..id;
	cst_read_url(zap)
end

function cst_sendurl(cst_url,range)
	local i,j,baseurl = string.find(cst_url,"(.+):.+")
	cst_debug(0, "cst_sendurl: url="..cst_url.." baseurl="..baseurl)

--	i,j,id = string.find(cst_url,".*id=(.+)")
--	local surl = baseurl.."/control/standby"
--	local standby = cst_read_url(surl)

--	if standby then
--		cst_debug(0, "standby="..standby)
--
--		-- wakeup from standby
--		if string.find(standby,"on") then
--			cst_read_url(surl.."?off&cec=off")
--		end
--	end
--	-- zap to channel
--	cst_zapto(baseurl,id)

	if not cst_test then
		plugin_sendurl(cst_url,cst_url,range)
	end
end

if cst_test then
cst_updatefeed("172.16.1.20","tank")
-- cst_updatefeed("172.16.1.10","tank")
-- cst_sendurl("http://172.16.1.20:31339/id=c1f000010070277a", 0)
end

if not cst_test then
print("xupnpd_neutrino: channel lists from ni-web /api/v1, /control/ as fallback, provider bouquets without user bouquets")
plugins['neutrino']={}
plugins.neutrino.name="Neutrino"
plugins.neutrino.desc="IP address (example: <i>192.168.0.1</i>)"
plugins.neutrino.updatefeed=cst_updatefeed
plugins.neutrino.sendurl=cst_sendurl
end
