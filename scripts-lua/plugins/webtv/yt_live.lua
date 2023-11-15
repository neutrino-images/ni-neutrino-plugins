
if #arg < 1 then return nil end
json = require "json"
local _url = arg[1]
local ret = {}
local Curl = nil
local CONF_PATH = "/var/tuxbox/config/"
if DIR and DIR.CONFIGDIR then
	CONF_PATH = DIR.CONFIGDIR .. '/'
end

function pop(cmd)
	local f = assert(io.popen(cmd, 'r'))
	local s = assert(f:read('*a'))
	f:close()
	return s
end

function add_entry(vurl,aurl,res1,res2,newname,count)
	entry = {}
	entry['url']  = vurl
	if aurl then entry['url2']  = aurl end
	entry['band'] = "1" --dummy
	entry['res1'] = res1
	entry['res2'] = res2
	entry['name'] = ""
	if newname then
		entry['name'] = newname
	end
	count = count + 1
	ret[count] = {}
	ret[count] = entry
	return count
end

function get_MaxRes_YTKey()
	local maxRes = 1280
	local key = nil
	local Nconfig = configfile.new()
	if Nconfig then
		Nconfig:loadConfig(CONF_PATH .. "neutrino.conf")
		maxRes = Nconfig:getInt32("livestreamResolution", 1280)
		key = Nconfig:getString("youtube_dev_id", '#')
	end
	return maxRes, key
end

function getVideoData(yurl)
	if yurl == nil then return 0 end
	local h = hintbox.new{caption="Please Wait ...", text="I'm Thinking."}
	if h then
		h:paint()
	end

	local data = pop("python /usr/bin/yt-dlp --dump-single-json " .. yurl)
	local itagnum = 0
	local urls = {}
	local count = 0

	if data then
		local jnTab = json:decode(data)
		if jnTab ~= nil then
			for k,v in pairs(jnTab.formats) do
				if v and v.format and v.quality and v.url then
					itagnum = tonumber(v.format_id)
					if itagnum then
						urls[itagnum] = v.url
					end
				end
			end
		end
		local audio = urls[140] or urls[251] or urls[250] or urls[249]
		local maxRes,key = get_MaxRes_YTKey()
		local res1, res2 = 3840, 2160
		local video = urls[628]
		if maxRes < 2561 or video == nil then
			video = urls[623] or video
			res1, res2 = 2560, 1440
		end
		if maxRes < 1981 or video == nil then
			video = urls[270] or urls[137] or urls[617] or urls[614] or urls[248] or urls[616] or video
			res1, res2 = 1980, 1080
		end
		if maxRes < 1281 or video == nil then
			video = urls[22] or urls[232] or urls[136] or urls[612] or urls[609] or urls[247] or video
			res1, res2 = 1280, 720
		end
		if maxRes < 855 or video == nil then
			video = urls[231] or urls[135] or urls[606] or urls[244] or video
			res1, res2 = 854, 480
		end
		if maxRes < 641 or video == nil then
			video = urls[230] or urls[134] or urls[18] or urls[605] or urls[243] or video
			res1, res2 = 640, 480
		end
		if video then
			count = count + 1
			add_entry(video,audio,res1,res2,"",count)
		end
	end
	if h then
		h:hide()
	end
	return count
end

if (getVideoData(_url) > 0) then
	return json:encode(ret)
end

return ""
