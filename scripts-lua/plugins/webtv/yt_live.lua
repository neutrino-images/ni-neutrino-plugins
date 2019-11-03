
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

--- vlc youtube.lua code
function js_descramble( sig, js )
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

function getVideoData(yurl)
	if yurl == nil then return 0 end

	if yurl:find("www.youtube.com/user/") or yurl:find("youtube.com/channel") or yurl:find("youtube.com/c/") then --check user link or channel alias
		local youtube_user = getdata(yurl)
		if youtube_user == nil then return 0 end
		local youtube_live_url = youtube_user:match('feature=c4.-href="(/watch.-)"')
		if youtube_live_url == nil then return 0 end
		yurl = 'https://www.youtube.com' .. youtube_live_url
	end

	local revision = 0
	if APIVERSION ~= nil and (APIVERSION.MAJOR > 1 or ( APIVERSION.MAJOR == 1 and APIVERSION.MINOR > 82 )) then
		M = misc.new()
		revision = M:GetRevision()
	end
	local count = 0
	local urls = {}
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
		local newname = nil
		if data then
			newname = data:match('<title>(.-)</title>')
			local m3u_url = data:match('hlsManifestUrl..:..(https:\\.-m3u8)') or data:match('hlsvp.:.(https:\\.-m3u8)')
			if m3u_url == nil then
				m3u_url = data:match('hlsManifestUrl..:..(https%%3A%%2F%%2F.-m3u8)') or data:match('hlsvp=(https%%3A%%2F%%2F.-m3u8)')
				if m3u_url then
					m3u_url = unescape_uri(m3u_url)
				end
			end

			if m3u_url then
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
				if count > 0 then return count end
			end

			local myurl = nil
			local url_map = data:match('"url_encoded_fmt_stream_map":"(.-)<div' ) or data:match('"url_encoded_fmt_stream_map":"(.-)"' )
			if url_map == nil then
				url_map = data:match('url_encoded_fmt_stream_map=(.-)$' )
				url_map=unescape_uri(url_map)
			end
			if url_map then
				url_map=url_map:gsub('"adaptive_fmts":"',"")
				for url in url_map:gmatch( "[^,]+" ) do
					if url and #url > 100 and url:find("itag") and url:find("url=") then
						local have_itag = false
						local itagnum = 0
						local myitag = nil
						myitag = url:match('itag=(%d+)') or url:match('itag%%3D(%d+)')
						url=url:gsub('xtags=',"")
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
							local s=myurl:match('6s=([%%%-%=%w+_]+)') or myurl:match('s=([%%%-%=%w+_]+)')
							if s and #s > 90 and #s < 130 then
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
							myurl=unescape_uri(myurl)

							myurl=myurl:gsub("\\", "")
							myurl=myurl:gsub('"', "")
							myurl=myurl:gsub('}', "")
							myurl=myurl:gsub(']', "")
							if select(2,myurl:gsub('&lmt=%d+', "")) == 2 then myurl=myurl:gsub('&lmt=%d+', "",1) end
							if select(2,myurl:gsub('&clen=%d+', "")) == 2 then myurl=myurl:gsub('&clen=%d+', "",1) end

							urls[itagnum] = myurl
						end
					end
				end
			end
		end
		local audio = urls[140] or urls[251] or urls[250] or urls[249]
		for k, video in pairs(urls) do
			if itags[k] then
				count = add_entry(video,nil,itags[k]:match('(%d+)x'),itags[k]:match('x(%d+)'),newname,count)
			elseif avc1_30 and itags_avc1_30[k] then
				count = add_entry(video,audio,itags_avc1_30[k]:match('(%d+)x'),itags_avc1_30[k]:match('x(%d+)'),newname,count)
			elseif avc1_60 and itags_avc1_60[k] then
				count = add_entry(video,audio,itags_avc1_60[k]:match('(%d+)x'),itags_avc1_60[k]:match('x(%d+)'),newname,count)
			elseif vp9_30 and itags_vp9_30[k] then
				count = add_entry(video,audio,itags_vp9_30[k]:match('(%d+)x'),itags_vp9_30[k]:match('x(%d+)'),newname,count)
			elseif vp9_60 and itags_vp9_60[k] then
				count = add_entry(video,audio,itags_vp9_60[k]:match('(%d+)x'),itags_vp9_60[k]:match('x(%d+)'),newname,count)
			elseif vp9_HDR and itags_vp9_HDR[k] then
				count = add_entry(video,audio,itags_vp9_HDR[k]:match('(%d+)x'),itags_vp9_HDR[k]:match('x(%d+)'),newname,count)
			end
		end
		local mini = 3
		if  revision == 1 then mini = 3 end
		if count > mini then
			print("TRY",i,count)
			break
		end
	end
	return count
end

if (getVideoData(_url) > 0) then
	return json:encode(ret)
end

return ""
