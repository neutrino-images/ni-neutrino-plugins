-- parse sportschau 0.5 Satbaby

local n = neutrino(0, 0, SCREEN.X_RES, SCREEN.Y_RES)

json = require "json"

if #arg < 1 then
	return nil
end

local _url0 = arg[1]
local ret0 = {}
local Curl = nil
local sm = nil
local nr = 0

function getdata(Url, redir)
	if Url == nil then
		return nil
	end
	if Curl == nil then
		Curl = curl.new()
	end
	local ret, data = Curl:download{
		url = Url,
		followRedir = redir,
		ipv4 = true,
		A = "Mozilla/5.0 (Linux;)"
	}
	if ret == CURL.OK then
		return data
	else
		return nil
	end
end

function godirectkey(d)
	if d == nil then
		return d
	end
	local _dkey = ""
	if d == 1 then
		_dkey = RC.red
	elseif d == 2 then
		_dkey = RC.green
	elseif d == 3 then
		_dkey = RC.yellow
	elseif d == 4 then
		_dkey = RC.blue
	elseif d < 14 then
		_dkey = RC["" .. (d - 4) .. ""]
	elseif d == 14 then
		_dkey = RC["0"]
	else
		-- rest
		_dkey = ""
	end
	return _dkey
end

function getid(id)
	sm:hide()
	nr = tonumber(id)
	return MENU_RETURN.EXIT_ALL
end

function getNeutrinoConf(Pattern)
	local neutrino_conf = "/var/tuxbox/config/neutrino.conf"
	local liveScrPath = nil
	local fh = filehelpers.new()
	if fh:exist(neutrino_conf, "f") == true then
		local config = configfile.new()
		config:loadConfig(neutrino_conf)
		liveScrPath = config:getString(Pattern, "#")
	end
	return liveScrPath
end

function playmenu(data)
	local urls = {}
	local d = 0
	local key = nil

	if data then
		local Hurls = {}
		for page in data:gmatch('v%-instance preloadingskeleton%-%-mediaplayer(.-)</h3>') do
			if not page:find('Audiostream') then
				page = page:gsub('<span class="hyphenate">', "")
				local title = page:match('teaser__headline*.>(.-)[\r\n<]')
					or page:match('teaser%-xs__headline*.>(.-)[\r\n<]')
					or ("Stream " .. d)

				local t, z = page:match('av_original_air_time.-;(%d%d%d%d%-%d%d%-%d%d)T(%d%d:%d%d:%d%d)Z')
				if t and z then
					title = t .. " " .. z .. " " .. title
				end

				local url = page:match('(https.-m3u8)')
				if url then
					url = url:gsub("[\r\n]", "")
					url = url:reverse()
					if url:find(';') then
						url = url:match('(.-);')
					end
					if url then
						url = url:reverse()
						if Hurls[url] ~= true then
							Hurls[url] = true
							d = d + 1
							key = godirectkey(d)
							table.insert(urls, {
								title = title,
								url = url,
								dkey = key
							})
-- 							print("URL " .. url)
						end
					end
				end
				key = nil
			end
		end
	end

	if #urls > 1 then
		sm = menu.new{name = "Sportschau", icon = "icon_blue"}
		for index, w in ipairs(urls) do
			sm:addItem{
				type = "forwarder",
				name = w.title,
				action = "getid",
				id = index,
				directkey = w.dkey
			}
		end
		sm:exec()
		sm:hide()
	end

	if #urls == 1 then
		nr = 1
	end

	if nr > 0 then
		local scpath = getNeutrinoConf("livestreamScriptPath")
		if scpath then
			arg = {}
			arg[1] = urls[nr].url
			arg[2] = nil
			local scriptfile = "/best_bitrate_m3u8.lua"
			local r = dofile(scpath .. scriptfile)
			if r then
				local js = json:decode(r)
				if js and next(js) ~= nil then
					for k, v in ipairs(js) do
						js[k].name = urls[nr].title
					end
					return json:encode(js)
				end
			end
		end
	end
	return nil
end

function getVideoData(url)
	if url == nil then
		return 0
	end
	local feed_data = getdata(url, true)
	if feed_data then
		ret0 = playmenu(feed_data)
		if ret0 then
			return 1
		end
	end
	return 0
end

if getVideoData(_url0) > 0 then
	return ret0
end

return ""
