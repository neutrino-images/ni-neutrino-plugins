local resolution = {'1920x1080','1280x720','854x480','640x360','426x240','128x72'}
local itags = {[37]='1920x1080',[96]='1920x1080',[22]='1280x720',[95]='1280x720',[136]='1280x720',[94]='854x480',[35]='854x480',[135]='854x480',
		[18]='640x360',[93]='640x360',[34]='640x360',[134]='640x360',[5]='400x240',[6]='450x270',[133]='426x240',[36]='320x240',
		[92]='320x240',[132]='320x240',[17]='176x144',[13]='176x144',[151]='128x72',
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

function js_extract(data,patern)
	for  line  in  data:gmatch("(.-};)"  )  do
		local m = line:match(patern)
		if m then
			return m
		end
	end
	return nil
end

--- vlc youtube.lua code
function js_descramble( sig, js )
	local descrambler = js_extract( js, "%.set%([^,]-%.sp,([^)]-)%(" )
	if descrambler == nil then return sig end
	local rules = js_extract( js, descrambler.."=function%([^)]*%){(.-)};" )
	if rules == nil then return sig end
	local helper = rules:match(";(..)%...%(" )
	if helper == nil then return sig end
	local transformations = js_extract( js, "[ ,]"..helper.."={(.-)};" )
	if transformations == nil then return sig end

	-- Parse the helper object to map available transformations
	local trans = {}
	for meth,code in string.gmatch( transformations, "(..):function%([^)]*%){([^}]*)}" ) do
		-- a=a.reverse()
		if string.match( code, "%.reverse%(" ) then
			trans[meth] = "reverse"
		-- a.splice(0,b)
		elseif string.match( code, "%.splice%(") then
			trans[meth] = "slice"
		-- var c=a[0];a[0]=a[b%a.length];a[b]=c
		elseif string.match( code, "var c=" ) then
			trans[meth] = "swap"
		else
			print("Couldn't parse unknown youtube video URL signature transformation")
		end
	end

	-- Parse descrambling rules, map them to known transformations
	-- and apply them on the signature
	local missing = false
	for meth,idx in string.gmatch( rules, "..%.(..)%([^,]+,(%d+)%)" ) do
		idx = tonumber( idx )
		if trans[meth] == "reverse" then
			sig = string.reverse( sig )
		elseif trans[meth] == "slice" then
			sig = string.sub( sig, idx + 1 )
		elseif trans[meth] == "swap" then
			if idx > 1 then
				sig = string.gsub( sig, "^(.)("..string.rep( ".", idx - 1 )..")(.)(.*)$", "%3%2%1%4" )
			elseif idx == 1 then
				sig = string.gsub( sig, "^(.)(.)", "%2%1" )
			end
		else
			print("Couldn't apply unknown youtube video URL signature transformation")
			missing = true
		end
	end
	if missing then
		print( "Couldn't process youtube video URL, please check for updates to this script" )
	end
	return sig
end
local jsdata = nil
function newsig(sig,js_url)
	if sig and js_url then
		if jsdata ==  nil then
			jsdata = getdata("https://www.youtube.com" .. js_url)
		end
		if jsdata then
			return js_descramble( sig, jsdata )
		end
	end
	return nil
end

function getVideoData(yurl)
	if yurl == nil then return 0 end

	if yurl:find("www.youtube.com/user/") or yurl:find("youtube.com/channel") then --check user link
		local youtube_user = getdata(yurl)
		if youtube_user == nil then return 0 end
		local youtube_live_url = youtube_user:match('feature=c4.-href="(/watch.-)"')
		if youtube_live_url == nil then return 0 end
		yurl = 'https://www.youtube.com' .. youtube_live_url
	end

	local video_url = nil
	local count = 0
	for i = 1,6 do
		local data = getdata(yurl)
		if data:find('player%-age%-gate%-content') then
			local id = yurl:match("/watch%?v=([%w+%p+]+)")
			if id then
				data = getdata('https://www.youtube.com/embed/' .. id)
				local sts = data:match('"sts":(%d+)')
				if sts then
					data = getdata('https://www.youtube.com/get_video_info?video_id=' .. id .. '&eurl=https%3A%2F%2Fyoutube.googleapis.com%2Fv%2F' .. id .. '&sts=' .. sts)
				end
			end
		end

		if data then
			local m3u_url = data:match('hlsvp.:.(https:\\.-m3u8)')
			if m3u_url == nil then
				m3u_url = data:match('hlsvp=(https%%3A%%2F%%2F.-m3u8)')
				if m3u_url then
					m3u_url = unescape_uri(m3u_url)
				end
			end
			local newname = data:match('<title>(.-)</title>')
			M = misc.new()
			local revision = 0
			-- revision = M:GetRevision() -- enable if you use gstreamer
			if revision == 1 and m3u_url then -- for gstreamer
				m3u_url = m3u_url:gsub("\\", "")
				entry = {}
				entry['url']  = m3u_url
				entry['band'] = "1" --dummy
				entry['res1'] = 1280
				entry['res2'] = 720
				entry['name'] = ""
				if newname then
					entry['name'] = newname
				end
				count = count + 1
				ret[count] = {}
				ret[count] = entry
				return count
			elseif m3u_url then
				m3u_url = m3u_url:gsub("\\", "")
				local videodata = getdata(m3u_url)
				for band, res1, res2, url in videodata:gmatch('#EXT.X.STREAM.INF.BANDWIDTH=(%d+).-RESOLUTION=(%d+)x(%d+).-(http.-)\n') do
					if url and res1 then
						url = url:gsub("/keepalive/yes","")--fix for new ffmpeg
						entry = {}
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
			end
			if count > 0 then return count end
			local myurl = nil
			local url_map = data:match('"url_encoded_fmt_stream_map":"(.-)"' )
			if url_map == nil then
				url_map = data:match('url_encoded_fmt_stream_map=(.-)$' )
				url_map=unescape_uri(url_map)
			end
			if url_map then
				for url in url_map:gmatch( "[^,]+" ) do
					if url then
						myurl=url:match('url=(.-)$')
						local myitag = ""
						if myurl then
							myitag = myurl:match('itag=(%d+)')
						else
							myitag = data:match('fmt_list=(%d+)')
						end
						if myurl and myitag ~= nil and itags[tonumber(myitag)] then
							if url:sub(1, 4) == 'url=' then
								myurl=url:match('url=(.-)$')
							else
								myurl=url:match('url=(.-)$') .. "&" .. url:match('(.-)url')
							end
							local s=myurl:match('s=(%w+.%w+)')
							if s then
								local js_url= data:match('<script src="([/%w%p]+base%.js)"')
								local signature = newsig(s,js_url)
								if signature then
									myurl=myurl:gsub('s=' .. s ,'signature=' .. signature)
								end
							end
							myurl=myurl:gsub("itag=" .. myitag, "")
							myurl=myurl:gsub("\\u0026", "&")
							myurl=myurl:gsub("&&", "&")
							video_url=unescape_uri(myurl)
							local itagnum = tonumber(myitag)
							entry = {}
							entry['url']  = video_url
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
		end
		if count > 0 then
			print("TRY",i)
			break
		end
	end
	return count
end

if (getVideoData(_url) > 0) then
	return json:encode(ret)
end

return ""
