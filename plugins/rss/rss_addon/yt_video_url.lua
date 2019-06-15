function getdata(Url,outputfile)
	if Url == nil then return nil end
	if Curl == nil then
		Curl = curl.new()
	end
	local ret, data = Curl:download{url=Url,A="Mozilla/5.0;",maxRedirs=5,followRedir=true,o=outputfile }
	if ret == CURL.OK then
		if outputfile then
			return 1
		end
		return data
	else
		return nil
	end
end

function hex2char(hex)
  return string.char(tonumber(hex, 16))
end
function unescape_uri(url)
	if url == nil then return nil end
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

function js_descramble( sig, js )
-- 	local descrambler = js_extract( js, "%.set%([^,]-\"signature\",([^)]-)%(" )
-- 	local descrambler = js_extract( js, "%.set%([^,]-%.sp,([^)]-)%(" )
	local descrambler = js_extract( js, "%.set%([^,]-%.sp,[^;]-%((..)%(" )
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
	print('signature=' .. sig)
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

local media = {}
function media.getVideoUrl(yurl)
local itags = {[37]='1920x1080',[96]='1920x1080',[22]='1280x720',[95]='1280x720',[136]='1280x720',[94]='854x480',[35]='854x480',[135]='854x480',
		[18]='640x360',[93]='640x360',[34]='640x360',[134]='640x360',[5]='400x240',[6]='450x270',[133]='426x240',[36]='320x240',
		[92]='320x240',[132]='320x240',[17]='176x144',[13]='176x144',[151]='128x72',
		[85]='1920x1080p',[84]='1280x720',[83]='854x480',[82]='640x360'
	}
	if yurl == nil then return end

	if yurl:find("www.youtube.com/user/") then --check user link
		local youtube_user = getdata(yurl)
		if youtube_user == nil then return end
		local youtube_live_url = youtube_user:match('feature=c4.-href="(/watch.-)">')
		if youtube_live_url == nil then return end
		yurl = 'https://www.youtube.com' .. youtube_live_url
	end

	local video_url = nil
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
			if m3u_url then
				m3u_url = m3u_url:gsub("\\", "")
				local videodata = getdata(m3u_url)
				local res = 0
				for band, res1, res2, url in videodata:gmatch('#EXT.X.STREAM.INF.BANDWIDTH=(%d+).-RESOLUTION=(%d+)x(%d+).-(http.-)\n') do
					if url and res1 then
						local nr = tonumber(res1)
						if nr < 2000 and nr > res then
							res=nr
							url = url:gsub("/keepalive/yes","")--fix for new ffmpeg
							video_url = url
						end
					end
				end
			end
			if video_url and #video_url > 8 then
				media.VideoUrl=video_url
			end
			if video_url then return end

			local fmt_list=data:match('"fmt_list":"(.-)",')
			local myitag = nil
			local myurl = nil
			if fmt_list then
				for itag in fmt_list:gmatch("(%d+)\\/[^,]+" ) do
					if itag then
						if itags[tonumber(itag)] then
							myitag=itag
							break
						end
					end
				end
			end
			if not myitag then myitag =data:match('fmt_list=(%d+)') end
			if not myitag then return end

			local url_map = data:match('"url_encoded_fmt_stream_map":"(.-)"' )
			if url_map == nil then
				url_map = data:match('url_encoded_fmt_stream_map=(.-)$' )
				url_map=unescape_uri(url_map)
			end
			if url_map then
				for url in url_map:gmatch( "[^,]+" ) do
					if url and url:find('itag=' .. myitag) then
						myurl=url:match('url=(.-)$')
						if myurl then
							if url:sub(1, 4) == 'url=' then
								myurl=url:match('url=(.-)$')
							else
								myurl=url:match('url=(.-)$') .. "&" .. url:match('(.-)url')
							end						
							local s=myurl:match('s=([%%%-%=%w+_]+)')
							if s then
								local s2=unescape_uri(s)
								local js_url= data:match('<script src="([/%w%p]+base%.js)"')
								local signature = newsig(s2,js_url)
								if signature then
									s = s:gsub("[%+%?%-%*%(%)%.%[%]%^%$%%]","%%%1")
									signature = signature:gsub("[%%]","%%%%")
									myurl = myurl:gsub('s=' .. s ,'sig=' .. signature)
								end
							end
							myurl=myurl:gsub("itag=" .. myitag, "")
							myurl=myurl:gsub("\\u0026", "&")
							myurl=myurl:gsub("&&", "&")
							video_url=unescape_uri(myurl)
							break
						end
					end
				end
			end
		end
		if video_url then
			print("TRY",i)
			break
		end
	end
	if video_url and #video_url > 8 then
		media.VideoUrl=video_url
	end
end

return media
