-------- cczwei
function cczwei_updatefeed(feed,friendly_name)
	local url='http://www.cczwei.de/index.php?id=tvissuearchive'
	local rc=false
	local feed_data=http.download(url)
	if feed_data then
		local f1 =string.find(feed_data,'<b>TV')
		local f2 =string.find(feed_data,'class="header">ALLE BEITRÄGE')
		if f1 and f2 then
			feed_data = string.sub(feed_data,f1,f2)
		end
		local tmp_m3u_filename = cfg.tmp_path..friendly_name..".m3u"
		local feed_m3u_path= cfg.feeds_path..friendly_name..'.m3u'

		local m3ufile = io.open(tmp_m3u_filename,"w")
		m3ufile:write("#EXTM3U name=\""..friendly_name.."\" plugin=cczwei type=mp4\n")
		for string in string.gmatch(feed_data, '(.-)<b>') do
			if string then
				local num,url,title = string.match(string, 'Folge.(%d+)</b>.*<a href="(index.php.*)#%w+">(.-)</a>') 
				if num and url and title then
--					if url then url=string.gsub(url,'&amp;','&') 
--						url = "http://www.cczwei.de/" ..url
--					end
					title = string.gsub(title,'ä','ae')
					title = string.gsub(title,'ö','oe')
					title = string.gsub(title,'ü','ue')
					title = string.gsub(title,'Ü','Ue')
					title = string.gsub(title,'ß','ss')
					title = string.gsub(title,'–',' ')
					title = string.gsub(title,'²','2')
					title = string.gsub(title,'®',' ')
					title = string.gsub(title,'€','Euro')

					fdi=string.find(feed_data,'<SPAN CLASS=.header.>',fdi)
					if fdi then
						d= string.match(feed_data, '(%d%d.%d%d.%d%d%d%d)',fdi)
						fdi=fdi+22		  
					end
					if d == nil then
						d = ""
					end
					num = string.format("%03d", num)
					m3ufile:write("#EXTINF:0,".."Folge "..num.." -- "..d ..": "..title.."\n")
					m3ufile:write("http://cczwei.mirror.speedpartner.de/cc2tv/CC2_"..num..".mp4\n")
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
