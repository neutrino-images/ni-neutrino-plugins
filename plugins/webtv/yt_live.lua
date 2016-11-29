local resolution = {'1920x1080','1280x720','854x480','640x360','426x240','128x72'}
local itags = {[37]='1920x1080',[96]='1920x1080',[22]='1280x720',[95]='1280x720',[94]='854x480',[35]='854x480',
		[18]='640x360',[93]='640x360',[34]='640x360',[5]='400x240',[6]='450x270',[35]='320x240',[92]='320x240',[132]='320x240',
		[17]='176x144',[13]='176x144',[151]='128x72',
		[85]='1920x1080p',[84]='1280x720',[83]='854x480',[82]='640x360'
}


json = require "json"

if #arg < 1 then return nil end
local _url = arg[1]
local ret = {}
local Curl = nil

function getdata(Url)
	if Url == nil then return nil end
	if Curl == nil then
		Curl = curl.new()
	end
	local ret, data = Curl:download{ url=Url, A="Mozilla/5.0"}
	if ret == CURL.OK then
		return data
	else
		return nil
	end
end

function hex2char(hex)
  return string.char(tonumber(hex, 16))
end
function unescape_uri(url)
  return url:gsub("%%(%x%x)", hex2char)
end

function getAlternatevideourl(youtube_url,newname)
	local id = youtube_url:match('v=(.-)$')
	local url = 'http://www.youtube.com/get_video_info?video_id=' .. id .. '&el=embedded&ps=default&eurl=&gl=US&hl=en'
	local data = getdata(url)
	if data then
		local stream_map = data:gsub("^(.-)url_encoded_fmt_stream_map","")
		data = nil
		if stream_map == nil then
			return 0
		end
		stream_map=unescape_uri(stream_map)

		if stream_map == nil then
			return 0
		end
		if stream_map then
			local count = 0
			for d in stream_map:gmatch('url=(.-)[,;]') do
				local item={}
				d=unescape_uri(d)
				local itagstr = d:match('itag=(%w+)')
				if  itagstr ~= nil and itags[tonumber(itagstr)] then
					local itagnum = tonumber(itagstr)
					d=d:gsub("(&itag=%d+)","")
					local video_url = d
					if video_url ~= nil then
						if  itags[itagnum] then
							entry = {}
							entry['url']  = video_url .. "&itag=" .. itagnum
							entry['band'] = "1" --dummy
							entry['res1'] = itags[itagnum]:match('(%d+)x')
							entry['res2'] = itags[itagnum]:match('x(%d+)')
							entry['name'] = ""
							if newname then
								entry['name'] = newname
							end
							count = count + 1
							ret[count] = {}
							ret[count] = entry
						end
					end
				end
			end
			return count
		end
	end
	return 0
end

function getVideoData(url)
	if url == nil then return 0 end

	if string.find(url,"www.youtube.com/user/") then --check user link
		local youtube_user = getdata(url)
		if youtube_user == nil then return 0 end
		local youtube_live_url = youtube_user:match('feature=c4%-live%-promo" href="(.-)">')
		if youtube_live_url == nil then return 0 end
		url = 'https://www.youtube.com' .. youtube_live_url
	end

	local data = getdata(url)
	if data then
		local m3u_url = data:match('hlsvp.:.(https:\\.-m3u8)') 
		local newname = data:match('<title>(.-)</title>')
		if m3u_url == nil then
			local count = getAlternatevideourl(url,newname)
			return count
		end
		m3u_url = m3u_url:gsub("\\", "")
		local videodata = getdata(m3u_url)
		local url = ""
		local band = ""
		local res1 = ""
		local res2 = ""
		local count = 0
		for band, res1, res2, url in videodata:gmatch('#EXT.X.STREAM.INF.BANDWIDTH=(%d+).-RESOLUTION=(%d+)x(%d+).-(http.-)\n') do
			if url ~= nil then
				entry = {}
				url = url:gsub("/keepalive/yes","")--fix for new ffmpeg
				entry['url']  = url
				entry['band'] = band
				entry['res1'] = res1
				entry['res2'] = res2
				entry['name'] = ""
				if newname then
					entry['name'] = newname
				end
				count = count + 1
				ret[count] = {}
				ret[count] = entry
			end
		end
		return count
	end
	return 0
end

if (getVideoData(_url) > 0) then
	return json:encode(ret)
end

return ""
