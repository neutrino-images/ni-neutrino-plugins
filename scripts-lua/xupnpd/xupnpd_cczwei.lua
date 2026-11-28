-------- cczwei
-- CC2tv with Wolfgang Rudolph, from the feeds on cc2.tv.
--
-- The feed name in xupnpd_feeds.lua picks the feed:
--   'audio'  CC2tv-Audio, the audiocast (MP3)
-- The video feed (feedv.xml) only links to YouTube pages now, which
-- xupnpd cannot play, so it is not offered.

local cczwei_feeds =
{
	audio = { url = 'http://cc2.tv/feed.xml', type = 'mp3' },
}

-- the ASCII the UPnP clients show without trouble
local function cczwei_title(title)
	title = title:gsub('<!%[CDATA%[(.-)%]%]>', '%1')
	title = title:gsub('&amp;', '&'):gsub('&quot;', '"'):gsub('&#39;', "'"):gsub('&lt;', '<'):gsub('&gt;', '>')
	title = title:gsub('ä', 'ae'):gsub('ö', 'oe'):gsub('ü', 'ue')
	title = title:gsub('Ä', 'Ae'):gsub('Ö', 'Oe'):gsub('Ü', 'Ue'):gsub('ß', 'ss')
	title = title:gsub('–', '-'):gsub('²', '2'):gsub('€', 'Euro')
	title = title:gsub('[\128-\255]', ' ')
	return title
end

function cczwei_updatefeed(feed, friendly_name)
	local f = cczwei_feeds[feed]
	if not f then
		if cfg.debug > 0 then print('CCZwei feed \'' .. tostring(feed) .. '\' unknown, use \'audio\'') end
		return false
	end
	if not friendly_name then
		friendly_name = 'CC2tv'
	end

	local feed_data = http.download(f.url)
	if not feed_data then
		if cfg.debug > 0 then print('CCZwei feed \'' .. friendly_name .. '\' not reachable: ' .. f.url) end
		return false
	end

	-- the name goes unquoted into mv
	local fname = friendly_name:gsub('[^%w_-]', '_')
	local tmp_m3u_filename = cfg.tmp_path .. 'cczwei_' .. fname .. '.m3u'
	local feed_m3u_path = cfg.feeds_path .. 'cczwei_' .. fname .. '.m3u'

	local entries = {}
	for item in feed_data:gmatch('<item>(.-)</item>') do
		local title = item:match('<title>(.-)</title>')
		local url = item:match('<enclosure[^>]-url="(.-)"')
		local day = item:match('<pubDate>%w+, (%d+ %w+ %d+)')
		-- direct media only: a link to a web page does not play
		if title and url and url:match('^https?://') and not url:match('youtu%.?be') then
			table.insert(entries, { title = cczwei_title(title), url = url, day = day or '' })
		end
	end
	feed_data = nil

	if #entries == 0 then
		if cfg.debug > 0 then print('CCZwei feed \'' .. friendly_name .. '\' has no playable entries') end
		return false
	end

	local m3ufile = io.open(tmp_m3u_filename, 'w')
	if not m3ufile then
		return false
	end
	m3ufile:write('#EXTM3U name="' .. friendly_name .. '" plugin=cczwei type=' .. f.type .. '\n')
	for _, e in ipairs(entries) do
		local name = e.title
		if e.day ~= '' then
			name = e.day .. ': ' .. name
		end
		m3ufile:write('#EXTINF:0,' .. name .. '\n')
		m3ufile:write(e.url .. '\n')
	end
	m3ufile:close()

	if util.md5(tmp_m3u_filename) == util.md5(feed_m3u_path) then
		util.unlink(tmp_m3u_filename)
		return false
	end
	-- Lua 5.1 returns 0, Lua 5.2 true
	local moved = os.execute(string.format('mv %s %s', tmp_m3u_filename, feed_m3u_path))
	if moved ~= 0 and moved ~= true then
		return false
	end
	if cfg.debug > 0 then print('CCZwei feed \'' .. friendly_name .. '\' updated') end
	return true
end

function cczwei_sendurl(cczwei_url, range)
	plugin_sendurl(cczwei_url, cczwei_url, range)
end

plugins['cczwei'] = {}
plugins.cczwei.name = "CCZwei"
plugins.cczwei.desc = "audio"
plugins.cczwei.sendurl = cczwei_sendurl
plugins.cczwei.updatefeed = cczwei_updatefeed
