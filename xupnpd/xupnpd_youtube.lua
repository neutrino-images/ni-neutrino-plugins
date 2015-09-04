-- Copyright (C) 2011-2013 Anton Burdinuk
-- clark15b@gmail.com
-- https://tsdemuxer.googlecode.com/svn/trunk/xupnpd

-- sysmer add support api v3 (need install curl with ssl)

-- 20150524 AnLeAl changes:
-- in url fetch, added docs section

-- 20150527 AnLeAl changes:
-- fixed for video get when less than 50
-- returned ui config for user amount video
-- add possibility get more than 50 videos

-- 20150527 MejGun changes:
-- code refactoring for feed update

-- 20150530 AnLeAl changes:
-- small code cleanup
-- added 'channel/mostpopular' for youtube mostpopular videos (it's only 30 from api), also region code from ui working
-- added favorites/username to get favorites
-- added search function

-- 20150531 AnLeAl changes:
-- fixed error when only first feed can get all videos for cfg.youtube_video_count and other no more 50
-- ui help updated
-- curl settings from cycles was moved to variables

-- 20150612 AnLeAl changes:
-- added playlist/playlistid option
-- ui help updated
-- doc section updated

-- README
-- This is YouTube api v3 plugin for xupnpd.
-- Be accurate when search for real username or playlist id.
-- Quickstart:
-- 1. Place this file into xupnpd plugin directory.
-- 2. Go to google developers console: https://developers.google.com/youtube/registering_an_application?hl=ru
-- 3. You need API Key, choose Browser key: https://developers.google.com/youtube/registering_an_application?hl=ru#Create_API_Keys
-- 4. Don't use option: only allow referrals from domains.
-- 5. Replace '***' with your new key in section '&key=***' in this file. Save file.
-- 6. Restart xupnpd, remove any old feeds that was made for youtube earlier. Add new one based on ui help patterns.
-- 7. Enjoy!


-- 18 - 360p  (MP4,h.264/AVC)
-- 22 - 720p  (MP4,h.264/AVC) hd
-- 37 - 1080p (MP4,h.264/AVC) hd
-- 82 - 360p  (MP4,h.264/AVC)    stereo3d
-- 83 - 480p  (MP4,h.264/AVC) hq stereo3d
-- 84 - 720p  (MP4,h.264/AVC) hd stereo3d
-- 85 - 1080p (MP4,h.264/AVC) hd stereo3d

cfg.youtube_fmt=22
cfg.youtube_region='*'
cfg.youtube_video_count=100
-- cfg.youtube_api_key=123


function read_file(filename)
	local fp = io.open(filename, "r")
	if fp == nil then error("Error opening file '" .. filename .. "'.") end
	local data = fp:read("*a")
	fp:close()
	return data
end

function youtube_updatefeed(feed,friendly_name)

  local function isempty(s)
    return s == nil or s == ''
  end

   local keyA = '&key=***' -- change *** to your youtube api key from: https://console.developers.google.com
    if keyA == '&key=***' then
	local keydata = read_file("/var/tuxbox/config/neutrino.conf") --file with key
	keyA = "&key=" .. keydata:match("youtube_dev_id=(.-)\n")
    end

  local rc=false

  local feed_url=nil
  local feed_urn=nil

  local tfeed=split_string(feed,'/')

  local feed_name='youtube_'..string.lower(string.gsub(feed,"[/ :\'\"]",'_'))

  local feed_m3u_path=cfg.feeds_path..feed_name..'.m3u'
  local tmp_m3u_path=cfg.tmp_path..feed_name..'.m3u'

  local dfd=io.open(tmp_m3u_path,'w+')

  if dfd then
    dfd:write('#EXTM3U name=\"',friendly_name or feed_name,'\" type=mp4 plugin=youtube\n')

    --------------------------------------------------------------------------------------------------
    local count = 0
    local totalres = 0
    local numA = 50 -- show 50 videos per page 0..50 from youtube api v3
    local pagetokenA = ''
    local nextpageA = ''
    local allpages = math.ceil(cfg.youtube_video_count/numA) -- check how much pages per 50 videos there can be
    local lastpage = allpages - 1
    local maxA = '&maxResults=' .. numA
    if cfg.youtube_video_count < numA then
      maxA = '&maxResults=' .. cfg.youtube_video_count
      numA = cfg.youtube_video_count
    end

    local cA = 'https://www.googleapis.com/youtube/v3/channels?part=contentDetails&forUsername='
    local iA = 'https://www.googleapis.com/youtube/v3/playlistItems?part=snippet&playlistId='
    local userA = tfeed[1]
    local uploads = ''
    local region = ''
    local enough = false

    -- Get what exactly user wants to get.
    if tfeed[1]=='channel' and tfeed[2]=='mostpopular' then
            if cfg.youtube_region and cfg.youtube_region~='*' then uploads='&regionCode='..cfg.youtube_region end
            iA = 'https://www.googleapis.com/youtube/v3/videos?part=snippet&chart=mostPopular'

    elseif tfeed[1]=='favorites' then
            userA = tfeed[2]
            local jsonA = '"' .. cA .. userA .. keyA .. '"'
	    local user_data = https_download(jsonA)
	    local x=json.decode(user_data)
	    uploads = x['items'][1]['contentDetails']['relatedPlaylists']['favorites']
	    x=nil

    elseif tfeed[1]=='search' then
            -- feed_urn='videos?vq='..util.urlencode(tfeed[2])..'&alt=json'
            if cfg.youtube_region and cfg.youtube_region~='*' then region='&regionCode='..cfg.youtube_region end
            iA = 'https://www.googleapis.com/youtube/v3/search?type=video&part=snippet&order=date&q=' .. util.urlencode(tfeed[2]) .. '&videoDefinition=high&videoDimension=2d' .. region
            uploads = ''

    elseif tfeed[1]=='playlist' then
            uploads = tfeed[2]

        else
            userA = tfeed[1]
            local jsonA = '"' .. cA .. userA .. keyA .. '"'
	    local user_data = https_download(jsonA)
	    local x=json.decode(user_data)
	    uploads = x['items'][1]['contentDetails']['relatedPlaylists']['uploads']
	    x=nil
    end


    while true do
      local jsonA = '"' .. iA .. uploads .. maxA .. pagetokenA .. keyA ..'"'
      local item_data = https_download(jsonA)
      local x=json.decode(item_data)
      totalres = x['pageInfo']['totalResults']
      local realpages = math.ceil(totalres/numA)
      local prelastpage = realpages - 1

      local items = nil
      local title = nil
      local url = nil
      local img = nil
      local countx = 0

      for key,value in pairs(x['items']) do
        count = count + 1
        if count > cfg.youtube_video_count then
          enough = true
          break
        end
    	    if tfeed[1]=='channel' then
    		    items = value['id']

    		elseif tfeed[1]=='search' then
    		    items = value['id']['videoId']

        	else
    		    items = value['snippet']['resourceId']['videoId']
    	    end
        title = value['snippet']['title']
	-- eltype = embedded or detailpage or vevo
        url = 'http://www.youtube.com/get_video_info?video_id=' .. items .. '&el=embedded&ps=default&eurl=&gl=US&hl=en'
        img = 'http://i.ytimg.com/vi/' .. items .. '/mqdefault.jpg'
        dfd:write('#EXTINF:0 logo=',img,' ,',title,'\n',url,'\n')
      end

      if isempty(x['nextPageToken']) or enough then
        break
      else
        nextpageA = x['nextPageToken']
        pagetokenA = '&pageToken=' .. nextpageA
      end
      x=nil
--    enough=nil
    end


    dfd:close()
    ---------------------------------------------------------------------------------------------------------

    if util.md5(tmp_m3u_path)~=util.md5(feed_m3u_path) then
      if os.execute(string.format('mv %s %s',tmp_m3u_path,feed_m3u_path))==0 then
        if cfg.debug>0 then print('YouTube feed \''..feed_name..'\' updated') end
        rc=true
      end
    else
      util.unlink(tmp_m3u_path)
    end
  end

  return rc
end

function youtube_sendurl(youtube_url,range)
  local url=nil
  if plugin_sendurl_from_cache(youtube_url,range) then return end

  url=youtube_get_video_url(youtube_url)
  if url then
    if cfg.debug>0 then print('YouTube Real URL: '..url) end

    plugin_sendurl(youtube_url,url,range)
  else
    if cfg.debug>0 then print('YouTube clip is not found') end

    plugin_sendfile('www/corrupted.mp4')
  end
end

function youtube_get_best_fmt(urls,fmt)
  if fmt>81 and fmt<86 then -- 3d
    local i=fmt while(i>81) do
    if urls[i] then return urls[i] end
    i=i-1
  end

  local t={ [82]=18, [83]=18, [84]=22, [85]=37 }

  fmt=t[fmt]
end

local t={ 37,22,18 }
local t2={ [18]=true, [22]=true, [37]=true }

for i=1,3,1 do
  local u=urls[ t[i] ]

  if u and t2[fmt] and t[i]<=fmt then return u end
end

return urls[18]
end

function pop(cmd)
	local f = assert(io.popen(cmd, 'r'))
	local s = assert(f:read('*a'))
	f:close()
	return s
end

function https_download(url)
	local clip_page = pop("curl -k " .. url)
	return clip_page
end

function youtube_get_video_url(youtube_url)
	local url=nil
	local old_url_found=youtube_url:find("feature=youtube_gdata")
	if old_url_found then -- workaround for old liste
		local  id=youtube_url:match(".-youtube.com/watch%?v=(.+)&feature=youtube_gdata")
		youtube_url = 'http://www.youtube.com/get_video_info?video_id=' .. id .. '&el=embedded&ps=default&eurl=&gl=US&hl=en'
	print(youtube_url)

	end

	local clip_page=plugin_download(youtube_url)
	-- workaround for https
	if clip_page ==  nil then
		local redirecturl = 'https' .. youtube_url:sub(5, #youtube_url) .. youtube_url
		clip_page = https_download(redirecturl)
	end

	if clip_page then
-- s.args.adaptive_fmts
-- itag 137: 1080p
-- itag 136: 720p
-- itag 135: 480p
-- itag 134: 360p
-- itag 133: 240p
-- itag 160: 144

	local stream_map = clip_page:gsub("^(.-)url_encoded_fmt_stream_map","")
	clip_page = nil
	stream_map=util.urldecode(stream_map)
        if stream_map then
	    local fmt=string.match(youtube_url,'&fmt=(%w+)$')
	    if not fmt then fmt=cfg.youtube_fmt end

	    local urls={}
            for d in stream_map:gmatch('url=(.-)[,;]') do
		local item={}
		d=util.urldecode(d)
 		item['itag']=d:match('itag=(%w+)')
		if  item['itag'] ~= nil then
			d=d:gsub("(&itag=%d+)","")
			local video_url = d
			if video_url ~= nil then
				item['url']=video_url .. "&itag=".. item['itag']
				urls[tonumber(item['itag'])]=item['url']
			end
		end
            end

            url=youtube_get_best_fmt(urls,tonumber(fmt))
        end

        return url
    else
        if cfg.debug>0 then print('YouTube clip is not found') end
        return nil
    end
end

plugins['youtube']={}
plugins.youtube.name="YouTube"
plugins.youtube.desc="<i>username</i>, favorites/<i>username</i>, search/<i>search_string</i>, playlist/<i>id</i>"..
"<br/><b>YouTube channels</b>: channel/mostpopular"
plugins.youtube.sendurl=youtube_sendurl
plugins.youtube.updatefeed=youtube_updatefeed
plugins.youtube.getvideourl=youtube_get_video_url

plugins.youtube.ui_config_vars=
{
  { "select", "youtube_fmt", "int" },
  { "select", "youtube_region" },
  { "input",  "youtube_video_count", "int" }
  --    { "input",  "youtube_api_key", "int" }
}

--youtube_updatefeed('channel/top_rated','')
