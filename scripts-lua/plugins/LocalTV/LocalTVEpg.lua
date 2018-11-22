-- LocalTVEpg.lua 2018-04-18 ver 0.2 by 'satbaby'

local n = neutrino(0, 0, SCREEN.X_RES, SCREEN.Y_RES);
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
	local ret, data = Curl:download{ url=Url, ipv4=true, A="Mozilla/5.0 (Linux;)"}
	if ret == CURL.OK then
		return data
	else
		return nil
	end
end

function toXMLcode(str)
	local ustr=str:gsub("&","&amp;")
	ustr=ustr:gsub("\n","&#x0a;")
	ustr=ustr:gsub("'","&apos;")
	ustr=ustr:gsub('"',"&quot;")
	ustr=ustr:gsub("<","&lt;")
	ustr=ustr:gsub(">","&qt;")
	return ustr
end

local epgdir = "/tmp/epg"

function genXML(epgdata)
	local fileout = io.open("/tmp/epg/epgfile.xml", 'w+')
	local jnTab = json:decode(epgdata)
	if fileout and jnTab then
		fileout:write('<?xml version="1.0" encoding="UTF-8"?>\n')
		fileout:write('<dvbepg>\n')
		fileout:write(toXMLcode(jnTab.data.epglist.channelData.channel_name))
		local service = jnTab.data.epglist.channelData.epg_id
		local tsid,onid,sid = service:match("%w%w%w%w(%w%w%w%w)(%w%w%w%w)(%w%w%w%w)")
		fileout:write('	<service original_network_id="' .. onid .. '" transport_stream_id="' .. tsid .. '" service_id="' .. sid .. '">\n')
		for k,v in pairs(jnTab.data.epglist.progData) do
			local eid = v.eventid_hex:match("%w%w%w%w%w%w%w%w%w%w%w(%w%w%w%w)")
			fileout:write('		<event id="' .. eid .. '" tid="50">\n')
			fileout:write('			<name lang="deu" string="' .. toXMLcode(v.description) ..'"/>\n')
			fileout:write('			<text lang="deu" string="' .. toXMLcode(v.info1) .. '"/>\n')
			fileout:write('			<extended_text lang="deu" string="' .. toXMLcode(v.info2) .. '"/>\n')
			fileout:write('			<time start_time="' .. v.start_sec .. '" duration="' .. tonumber(v.duration_min)*60 .. '"/>\n')
			fileout:write('		</event>\n')
		end
		fileout:write('	</service>\n')
		fileout:write('</dvbepg>\n')
		fileout:close()
		os.execute("sectionsdcontrol --readepg " .. epgdir )
	end
end

function getEPGData(url)
	if url == nil then return 0 end
	local ip,chid = url:match("//(%d+%.%d+%.%d+%.%d+):31339/id=(%w+)")
	if ip and chid then
		local epgurl = 'http://' .. ip .. '/control/epg?format=json&channelid=' .. chid .. '&details=true'
		local data=getdata(epgurl)
		if data then
			local fh = filehelpers.new()
			if fh then
				fh:mkdir(epgdir)
				genXML(data)
				fh:rmdir(epgdir)
			end
		end
	end
	entry = {}
	entry['url']  = url
	entry['band'] = "1" --dummy
	entry['res1'] = 1280
	entry['res2'] = 720
	entry['name'] = ""
	ret[1] = {}
	ret[1] = entry
	return 1
end

if (getEPGData(_url) > 0) then
	return json:encode(ret)
end

return ""
