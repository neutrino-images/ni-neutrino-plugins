json = require "json"

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
	local descrambler = js_extract( js, "[=%(,&|](...?.?)%(decodeURIComponent%(.%.s%)%)" )
	if descrambler == nil then print("decodeURIComponent error") return sig end
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
	local itags = {[37]='1920x1080',[96]='1920x1080',[22]='1280x720',[95]='1280x720',[94]='854x480',[35]='854x480',
		[18]='640x360',[93]='640x360',[34]='640x360',[5]='400x240',[6]='450x270',[36]='320x240',
		[92]='320x240',[17]='176x144',[13]='176x144',
		[85]='1920x1080p',[84]='1280x720',[83]='854x480',[82]='640x360'
	}

	local itags_audio = {[140]='m4a',[251]='opus',[250]='opus',[249]='opus'} -- 251,250,249 opus, bad audio sync
	local itags_vp9_60 = {[315]='3840x2160',[308]='2560x1440',[303]='1920x1080',[302]='1280x720'}
	local itags_vp9_30 = {[313]='3840x2160',[271]='2560x1440',[248]='1920x1080',[247]='1280x720',[244]='854x480'}
	local itags_vp9_HDR = {[337]='3840x2160',[336]='2560x1440',[335]='1920x1080',[334]='1280x720',[333]='854x480'}
	local itags_avc1_60 = {[299]='1920x1080',[298]='1280x720'}
	local itags_avc1_30 = {[137]='1920x1080',[136]='1280x720',[135]='854x480'}
	local itags_av01 = {[401]='3840x2160',[400]='2560x1440',[399]='1920x1080',[398]='1280x720',[397]='854x480'}
	-- disable or enable format
	local vp9_60 = true --webm
	local vp9_30 = true --webm
	local vp9_HDR = false --webm, HDR dont work on HD51
	local avc1_60 = true -- mp4
	local avc1_30 = true -- mp4
	local video_url = nil
	media.VideoUrl = nil

	if yurl == nil then return end

	if yurl:find("www.youtube.com/user/") then --check user link
		local youtube_user = getdata(yurl)
		if youtube_user == nil then return end
		local youtube_live_url = youtube_user:match('"url":"(/watch.-)"') or youtube_user:match('feature=c4.-href="(/watch.-)">')
		if youtube_live_url == nil then return end
		yurl = 'https://www.youtube.com' .. youtube_live_url
	end

	local h = hintbox.new{caption="Please Wait ...", text="I'm Thinking."}
	if h then
		h:paint()
	end
	local maxRes = getMaxVideoRes()
	local count,countx = 0,0
	local tmp_res = 0
	local stop = false
	local stop2 = false
	local urls = {}
	local have_itags = {}
	for i = 1,6 do
		countx = 0
		local data = getdata(yurl)
		local age_formats = false
		if data:find('LOGIN_REQUIRED') and youtube_dev_id then
			local id = yurl:match("/watch%?v=([%w+%p+]+)")
			if id then
				local postdat='{"context": {"client": {"clientName": "ANDROID", "clientVersion": "16.20", "hl": "en", "clientScreen": "EMBED"}, "thirdParty": {"embedUrl": "https://google.com"}}, "videoId": "' .. id .. '", "playbackContext": {"contentPlaybackContext": {"html5Preference": "HTML5_PREF_WANTS", "signatureTimestamp": 18872}}, "contentCheckOk": true, "racyCheckOk": true}'
				local header_opt ={'content-type:application/json'}
				data = getdata('https://www.youtube.com/youtubei/v1/player?key=' .. youtube_dev_id, nil, postdat, 0, header_opt)
				if data then age_formats = true end
			end
		end

		if data then
			local m3u_url = data:match('hlsManifestUrl.:.(https:.-m3u8)') or data:match('hlsManifestUrl..:..(https:\\.-m3u8)') or data:match('hlsvp.:.(https:\\.-m3u8)')
			if m3u_url == nil then
				m3u_url = data:match('hlsManifestUrl.:.(https%%3A%.-m3u8)') or data:match('hlsManifestUrl..:..(https%%3A%%2F%%2F.-m3u8)') or data:match('hlsvp=(https%%3A%%2F%%2F.-m3u8)')
				if m3u_url then
					m3u_url = unescape_uri(m3u_url)
				end
			end
			if m3u_url then
				m3u_url = m3u_url:gsub("\\", "")
				video_url = getVideoUrlM3U8(m3u_url)
				if video_url and #video_url > 8 then
					media.VideoUrl=video_url
				end
				if video_url then
					if h then
						h:hide()
					end
					return
				end
			end
			local myurl = nil
			local url_map = data:match('"url_encoded_fmt_stream_map":"(.-)<div' ) or data:match('"url_encoded_fmt_stream_map":"(.-)"' )
			if url_map == nil then
				url_map = data:match('url_encoded_fmt_stream_map=(.-)$' )
				if url_map then url_map=unescape_uri(url_map) end
			end
			local player_map = data:match("ytplayer.config%s-=%s-({.-});")
			local map_urls = {}
			local ucount = 0
			if player_map or age_formats then
				local formats_data = nil
				if player_map then
					formats_data = data:match('"formats%p-:(%[{.-}])')
				end
				if age_formats then
					formats_data = data:match('"formats":%s(%[.-])')
				end
				if formats_data then
					formats_data = formats_data:gsub('\\\\\\"','')
					if formats_data:find('\\"itag\\":') then
						formats_data = formats_data:gsub('\\"','"')
					end
					local formats = json:decode (formats_data)
					if formats then
						for k, v in pairs(formats) do
							if v.itag and have_itags[v.itag] ~= true then
								have_itags[v.itag] = true
								ucount = ucount + 1
								if v.signatureCipher then
									map_urls[ucount] = v.signatureCipher
								elseif v.url then
									map_urls[ucount] = "url=" .. v.url
								elseif cipher then --unnecessary?
									map_urls[ucount] = v.cipher
								end
							end
						end
						local adaptiveFormats_data = nil
						if player_map then
							adaptiveFormats_data = data:match('"adaptiveFormats%p-:(%[{.-}])')
						end
						if age_formats then
							adaptiveFormats_data = data:match('"adaptiveFormats":%s(%[.-])')
						end
						if adaptiveFormats_data then
							adaptiveFormats_data = adaptiveFormats_data:gsub('\\\\\\"','')
							if adaptiveFormats_data:find('\\"itag\\":') then
								adaptiveFormats_data = adaptiveFormats_data:gsub('\\"','"')
							end
							local adaptiveFormats = json:decode (adaptiveFormats_data)
							if adaptiveFormats then
								for k, purl in pairs(adaptiveFormats) do
									if purl.itag and have_itags[purl.itag] ~= true then
										have_itags[purl.itag] = true
										ucount = ucount + 1
										if purl.signatureCipher then
											map_urls[ucount] = purl.signatureCipher
										elseif purl.url then
											map_urls[ucount] = "url=" .. purl.url
										elseif purl.cipher then --unnecessary?
											map_urls[ucount] = purl.cipher
										end
									end
								end
							end
						end
					end
				end
			end
			if url_map then
				url_map=url_map:gsub('"adaptive_fmts":"',"")
				for murl in url_map:gmatch( "[^,]+" ) do
					if murl and #murl > 100 and murl:find("itag") and murl:find("url=") then
						local itag = murl:match('itag=(%d+)') or murl:match('itag%%3D(%d+)')
						if itag and have_itags[itag] ~= true then
							have_itags[itag] = true
							ucount = ucount + 1
							map_urls[ucount]=murl
						end
					end
				end
			end
			for k, url in pairs(map_urls) do
				local have_itag = false
				local itagnum = 0
				local myitag = nil
				myitag = url:match('itag=(%d+)') or url:match('itag%%3D(%d+)')
				url=url:gsub('xtags=',"")
				url=url:gsub('fps=%d+',"")
				if myitag ~= nil then
					itagnum = tonumber(myitag)
					if itags[itagnum] then
						have_itag = true
					elseif revision == 1 and
							((vp9_30 and itags_vp9_30[itagnum]) or (vp9_60 and itags_vp9_60[itagnum])
					         or (avc1_60 and itags_avc1_60[itagnum]) or (avc1_30 and itags_avc1_30[itagnum])
					        or (vp9_HDR and itags_vp9_HDR[itagnum])) or itags_audio[itagnum] then
						have_itag = true
					end
				end
				if have_itag then
					if url:sub(1, 4) == 'url=' then
						myurl=url:match('url=(.-)$')
					else
						local tmp = url:match('(s=.-)url') or url:match('(.-)url')
						if tmp == nil then tmp = "" end
						local tmp_url = url:match('url=(.-)$')
						myurl= tmp_url .. "&" .. tmp
					end
					local s=myurl:match('6s=([%%%-%=%w+_]+)') or myurl:match('&s=([%%%-%=%w+_]+)') or myurl:match('^s=([%%%-%=%w+_]+)')
					if s and (#s > 99 and #s < 160) then
						local s2=unescape_uri(s)
						local js_url= data:match('<script%s+src="([/%w%p]+base%.js)"')
						local signature = newsig(s2,js_url)
						if signature then
							s = s:gsub("[%+%?%-%*%(%)%.%[%]%^%$%%]","%%%1")
							signature = signature:gsub("[%%]","%%%%")
							myurl = myurl:gsub('s=' .. s ,'sig=' .. signature)
						end
						myurl=myurl:gsub("itag=" .. myitag, "")
					end
					myurl=myurl:gsub("\\u0026", "&")
					myurl=unescape_uri(myurl)
					myurl=myurl:gsub("&&", "&")

					myurl=myurl:gsub("\\", "")
					myurl=myurl:gsub('"', "")
					myurl=myurl:gsub('}', "")
					myurl=myurl:gsub(']', "")
					if select(2,myurl:gsub('&lmt=%d+', "")) == 2 then myurl=myurl:gsub('&lmt=%d+', "",1) end
					if select(2,myurl:gsub('&clen=%d+', "")) == 2 then myurl=myurl:gsub('&clen=%d+', "",1) end

					urls[itagnum] = myurl
					countx = countx + 1
				end
			end
		end
		local res = 0
		for k, video in pairs(urls) do
			if itags[k] then
				tmp_res = tonumber(itags[k]:match('(%d+)x'))
				if tmp_res > res and tmp_res <= maxRes then
					count = count + 1
					video_url = video
					res = tmp_res
					media.UrlVideoAudio = ""
				end
			elseif avc1_30 and itags_avc1_30[k] then
				tmp_res = tonumber(itags_avc1_30[k]:match('(%d+)x'))
				if tmp_res > res and tmp_res <= maxRes then
					count = count + 1
					video_url = video
					res = tmp_res
					media.UrlVideoAudio = urls[140] or urls[251] or urls[250] or urls[249]
				end
			elseif avc1_60 and itags_avc1_60[k] then
				tmp_res = tonumber(itags_avc1_60[k]:match('(%d+)x'))
				if tmp_res > res and tmp_res <= maxRes then
					count = count + 1
					video_url = video
					res = tmp_res
					media.UrlVideoAudio = urls[140] or urls[251] or urls[250] or urls[249]
				end
			elseif vp9_30 and itags_vp9_30[k] then
				tmp_res = tonumber(itags_vp9_30[k]:match('(%d+)x'))
				if tmp_res > res and tmp_res <= maxRes then
					count = count + 1
					video_url = video
					res = tmp_res
					media.UrlVideoAudio = urls[140] or urls[251] or urls[250] or urls[249]
				end
			elseif vp9_60 and itags_vp9_60[k] then
				tmp_res = tonumber(itags_vp9_60[k]:match('(%d+)x'))
				if tmp_res > res and tmp_res <= maxRes then
					count = count + 1
					video_url = video
					res = tmp_res
					media.UrlVideoAudio = urls[140] or urls[251] or urls[250] or urls[249]
				end
			elseif vp9_HDR and itags_vp9_HDR[k] then
				tmp_res = tonumber(itags_vp9_HDR[k]:match('(%d+)x'))
				if tmp_res > res and tmp_res <= maxRes then
					count = count + 1
					video_url = video
					res = tmp_res
					media.UrlVideoAudio = urls[140] or urls[251] or urls[250] or urls[249]
				end
			end
			if maxRes == res then stop = true break end
			if maxRes > 1920 and tmp_res == 1920 then stop2 = true end
		end
		if stop or stop2 or (countx==0 and i>2) then
			print("TRY",i,count)
			break
		end
	end
	if video_url and #video_url > 8 then
		media.VideoUrl=video_url
	end
	if h then
		h:hide()
	end
end

return media
