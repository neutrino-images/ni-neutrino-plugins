--version 0.2
local media = {}
function media.getAddonMedia(url)
	local video_url = nil
	local pic_url = nil
	local id =nil
	if url then
		local data = getdata(url)
		if data then
			local js_url = data:match('<div async src="(//.-)" ')
			local ytdata = data:match('<div class="video%-content"(.-)</div>')
			if ytdata then
				id = ytdata:match('youtube%.%w+/embed/([%w%-]+)?')
				if id == nil then
					id = ytdata:match('embed/(.*)?')
				end
			end
			local tmp_video_id,tmp_player_id = data:match('/tv/(%w+)/(%w+)') -- og:image" content="http://cdn2.pitchfork.com/
			if tmp_video_id == nil and tmp_player_id == nil then
				tmp_video_id,tmp_player_id = data:match('photos/(%w+)/([%w+%p]+)/[%w+%p]+/(%w+)%.jpg')
			end
			media.newText = data:match('class="desc" data%-reactid="%d+">(.-)</p>')
			if js_url and #js_url > 10 then
				data = getdata(js_url)
				if data then
					local video_id, player_id = data:match("embedPath:%s+'/embed/(%w+)/(%w+)'")
					if video_id == nil and tmp_video_id then
						video_id = tmp_video_id
					end
					if player_id == nil and tmp_player_id then
						player_id = tmp_player_id
					end
					local embed_player = data:match("embedUrl[%s+]?=[%s+]?..(//.-%.js)")
					if embed_player and video_id and  player_id then
						local video_urls = "http:" .. embed_player .. "?videoId=" .. video_id .. "&playerId=" .. player_id .."&target=embedplayer"
						data = getdata(video_urls)
						if data then
							video_url = data:match('{"type":"video/mp4","src":"(.-)"')
							local pic_url = data:match('poster_frame":"(http://.-%.jpg)",')
							if pic_url then
								media.PicUrl = pic_url
							end
						end
					end 
				end
			end
			if video_url== nil and id then
				local hasaddon,b = pcall(require,"yt_video_url")
				if hasaddon then
					b.getVideoUrl('https://youtube.com/watch?v=' .. id)
					video_url = b.VideoUrl
				end
			end
		end
	end
	if video_url and #video_url > 8 then
		media.VideoUrl=video_url
	end
end
return media
