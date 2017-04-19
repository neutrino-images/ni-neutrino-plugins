-------- cczwei
function cczwei_updatefeed(feed,friendly_name)
	local url='http://cc2.tv/feedv.xml'
	local rc=false
	local feed_data=http.download(url)
	if feed_data then
		feed_data=feed_data .. http.download("http://cc2.tv/feed.xml")
		local tmp_m3u_filename = cfg.tmp_path..friendly_name..".m3u"
		local feed_m3u_path= cfg.feeds_path..friendly_name..'.m3u'

		local m3ufile = io.open(tmp_m3u_filename,"w")
		m3ufile:write("#EXTM3U name=\""..friendly_name.."\" plugin=cczwei type=mp4\n")
		for item in feed_data:gmatch("<item>(.-)</item>") do
			if item then
				local title = item:match("<title>(.-)</title>")
				local videourl = item:match('<enclosure url="(.-)"')
				local day = item:match('<pubDate>%w+. (%d+ %w+ %d+)')
				if videourl and title then
					title = title:gsub('ä','ae')
					title = title:gsub('ö','oe')
					title = title:gsub('ü','ue')
					title = title:gsub('Ü','Ue')
					title = title:gsub('ß','ss')
					title = title:gsub('–',' ')
					title = title:gsub('²','2')
					title = title:gsub('®',' ')
					title = title:gsub('€','Euro')
					for i = 1, #title do
						local c=title:sub( i, i)
						if (string.byte(c)>128) then
							title = title:gsub(c,' ')
						end
					end
					if day == nil then
						day = ""
					end
					m3ufile:write("#EXTINF:0,".. day ..": "..title.."\n")
					m3ufile:write(videourl .. "\n")
				end
			end
		end
		m3ufile:close()
		feed_data=nil
		if util.md5(tmp_m3u_filename)~=util.md5(feed_m3u_path) then
			 if os.execute(string.format('mv %s %s',tmp_m3u_filename,feed_m3u_path))==0 then
				if cfg.debug>0 then 
					print('CCZwei feed \''..friendly_name..'\' updated') 
				end
				rc=true
			end
		else
 			util.unlink(tmp_m3u_filename)
		end
	end
	return rc
end

function cczwei_sendurl(cczwei_url,range)
	plugin_sendurl(cczwei_url,cczwei_url,range)
end


plugins['cczwei']={}
plugins.cczwei.name="CCZwei"
plugins.cczwei.sendurl=cczwei_sendurl
plugins.cczwei.updatefeed=cczwei_updatefeed
plugins.cczwei.getvideourl=cczwei_get_video_url

cczwei_updatefeed('cczwei', 'ComputerClub2')
