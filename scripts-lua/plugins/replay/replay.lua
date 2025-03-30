--[[
	replay.lua
	16/2/2024 by jokel
	Version 0.80 beta

	Changed by BPanther - 30/Apr/2024
	Changed by jokel - 25/3/2025
]]

local sender_mpd = {

	["3sat"] = "https://zdf-dash-18.akamaized.net/dash/live/2016511/dach/manifest.mpd",
	["ARD alpha"] = "https://ardalphadash.akamaized.net/dash/live/2016972/ard_alpha/dvbt2/manifest.mpd",
	["arte"] = "https://arteliveext.akamaized.net/dash/live/2031004/artelive_de/dash.mpd",
	["BR Fernsehen Nord"] = "https://bfrnorddash.akamaized.net/dash/live/2016971/bfs_nord_de/dvbt2/manifest.mpd",
	["BR Fernsehen Süd"] = "https://bfrsueddash.akamaized.net/dash/live/2016970/bfs_sued_de/dvbt2/manifest.mpd",
	["BR Süd"] = "https://bfrsueddash.akamaized.net/dash/live/2016970/bfs_sued_de/dvbt2/manifest.mpd",
	["Das Erste"] = "https://daserste-live.ard-mcdn.de/daserste/replay/dash/de/manifest.mpd",
	["hr-fernsehen"] = "https://hrdashde.akamaized.net/dash/live/2024544/hrdashde/manifest.mpd",
	["KiKA"] = "https://kikageoilsdash.akamaized.net/dash/live/2099498/dashhbbtv-ebu-proxy-full/manifest.mpd",
	["MDR Sachsen"] = "https://mdrtvsndash.akamaized.net/dash/live/2094117/mdrtvsn/dash.mpd",
	["MDR S-Anhalt"] = "https://mdrtvsadash.akamaized.net/dash/live/2094116/mdrtvsa/dash.mpd",
	["MDR Thüringen"] = "https://mdrtvthdash.akamaized.net/dash/live/2094118/mdrtvth/dash.mpd",
	["NDR FS HH"] = "https://mcdn.ndr.de/ndr/dash/ndr_hbbtv/ndr_hbbtv_hh/ndr_hbbtv_hh.mpd",
	["NDR FS MV"] = "https://mcdn.ndr.de/ndr/dash/ndr_hbbtv/ndr_hbbtv_mv/ndr_hbbtv_mv.mpd",
	["NDR FS NDS"] = "https://mcdn.ndr.de/ndr/dash/ndr_hbbtv/ndr_hbbtv_nds/ndr_hbbtv_nds.mpd",
	["NDR FS SH"] = "https://mcdn.ndr.de/ndr/dash/ndr_hbbtv/ndr_hbbtv_sh/ndr_hbbtv_sh.mpd",
	["ONE"] = "https://mcdn-one.ard.de/ardone/dash/manifest.mpd",
	["phoenix"] = "https://zdf-dash-19.akamaized.net/dash/live/2016512/de/manifest.mpd",
	["PHOENIX"] = "https://zdf-dash-19.akamaized.net/dash/live/2016512/de/manifest.mpd",
	["Radio Bremen"] = "https://rbdashlive.akamaized.net/dash/live/2020436/rbfs/dash.mpd",
	["rbb Berlin"] = "https://rbb-dash-berlin.akamaized.net/dash/live/2017826/rbb_berlin/manifest.mpd",
	["rbb Brandenburg"] = "https://rbb-dash-brandenburg.akamaized.net/dash/live/2017827/rbb_brandenburg/manifest.mpd",
	["SR Fernsehen"] = "https://swrsrfs-dash.akamaized.net/dash/live/2018687/srfsgeo/dash.mpd",
	["SWR BW"] = "https://swrbw-dash.akamaized.net/dash/live/2018674/swrbwd/manifest.mpd",
	["SWR RP"] = "https://swrrp-dash.akamaized.net/dash/live/2018680/swrrpd/manifest.mpd",
	["tagesschau24"] = "https://tagesschau.akamaized.net/dash/live/2020098/tagesschau/tagesschau_3/tagesschau_3.mpd",
	["WDR Aachen"] = "https://wdrlokalzeit.akamaized.net/dash/live/2018107/wdrlz_aachen/dash.mpd",
	["WDR Bielefeld"] = "https://wdrlokalzeit.akamaized.net/dash/live/2018117/wdrlz_bielefeld/dash.mpd",
	["WDR Bonn"] = "https://wdrlokalzeit.akamaized.net/dash/live/2018112/wdrlz_bonn/dash.mpd",
	["WDR Dortmund"] = "https://wdrlokalzeit.akamaized.net/dash/live/2018113/wdrlz_dortmund/dash.mpd",
	["WDR Duisburg"] = "https://wdrlokalzeit.akamaized.net/dash/live/2018115/wdrlz_duisburg/dash.mpd",
	["WDR Düsseldorf"] = "https://wdrlokalzeit.akamaized.net/dash/live/2018114/wdrlz_duesseldorf/dash.mpd",
	["WDR Essen"] = "https://wdrlokalzeit.akamaized.net/dash/live/2018118/wdrlz_essen/dash.mpd",
	["WDR Köln"] = "https://wdrfs247.akamaized.net/dash/live/2016702/wdrfs247_geo/dash.mpd",
	["WDR Münster"] = "https://wdrlokalzeit.akamaized.net/dash/live/2018116/wdrlz_muensterland/dash.mpd",
	["WDR Siegen"] = "https://wdrlokalzeit.akamaized.net/dash/live/2018111/wdrlz_siegen/dash.mpd",
	["WDR Wuppertal"] = "https://wdrlokalzeit.akamaized.net/dash/live/2018126/wdrlz_wuppertal/dash.mpd",
	["ZDF"] = "https://zdf-dash-15.akamaized.net/dash/live/2016508/de/manifest.mpd",
	["ZDFinfo"] = "https://zdf-dash-17.akamaized.net/dash/live/2016510/de/manifest.mpd",
	["zdf_neo"] = "https://zdf-dash-16.akamaized.net/dash/live/2016509/de/manifest.mpd",
}

local outputfile = "/tmp/output.mpd"


function pop(cmd)
	local f = assert(io.popen(cmd, 'r'))
	local s = assert(f:read('*a'))
	f:close()
	return s
end

function sleep(a)
	local sec = tonumber(os.clock() + a)
	while (os.clock() < sec) do
	end
end

function umlaute(s)
	s=s:gsub("\xc4","Ä")
	s=s:gsub("\xe4","ä")
	s=s:gsub("\xd6","Ö")
	s=s:gsub("\xf6","ö")
	s=s:gsub("\xdc","Ü")
	s=s:gsub("\xfc","ü")
	s=s:gsub("\x1e9e","ß")
	s=s:gsub(" HD","")
	return s
end

function getdata(Url, outputfile)
	if Url == nil then return nil end
	if Curl == nil then
		Curl = curl.new()
	end
	local ret, data = Curl:download{url=Url, A="Mozilla/5.0", o=outputfile}
	if ret == CURL.OK then
		if outputfile then
			return 1
		end
		return data
	else
		return nil
	end
end

function putdata(output, outputfile)
	file_write = io.open(outputfile, "w")
	file_write:write(output)
	file_write:close()
end

function get_text(dir_file)
	local file_read = io.open(dir_file, "r")
	local data = {}
	local i = 0
	if file_read then
		for line in file_read:lines() do
			i = i + 1
			data[i] = line
		end
		file_read:close()
		--print("file found")
		return data
	else
		--print("file not found")
		return nil
	end
end

function replay(name, epg_now, epg_next, full_time)
	local vPlay = video.new()
	vPlay:setSinglePlay(true)
	vPlay:PlayFile("Replay - " .. name, outputfile, epg_now .. " (" .. full_time .. " min)", epg_next)
end

function message(txt, s)
	if s == nil then s = 3 end
	local h = hintbox.new{caption="Hinweis", text=txt}
	if h then
		 h:paint()
	end
	sleep(s)
	h:hide()
end

------------------- replay ------------------------------

local channelinfo = {}
local Curl = curl.new()
local ret, data = Curl:download{url="http://127.0.0.1/control/getchannelinfo"}
for line in data:gmatch("[^\r\n]+") do
	table.insert(channelinfo, line)
end

local sender = channelinfo[1]
local name = umlaute(sender)
local mpd_url = sender_mpd[name]

if mpd_url then
	local file = getdata(mpd_url, outputfile)
	if file then
		local mpd_pos = (mpd_url:reverse()):find("/")
		local mpd_tmp = mpd_url:sub(1, #mpd_url - mpd_pos + 1)
		local host = mpd_tmp
		local mpdlines = get_text(outputfile)
		mpdlines[2] = string.gsub(mpdlines[2],'timeShiftBufferDepth="PT(.-)S"', 'timeShiftBufferDepth="PT3H0M0S"')
		if string.match(mpdlines[3], "<BaseURL") then
			--print ("BaseURL gefunden")
			if string.match(mpdlines[4], "<BaseURL") then
				table.remove(mpdlines, 4)
			end

			mpdlines[8] = string.gsub(mpdlines[8],"video_00", "video_01") -- zdf handling
			mpdlines[9] = string.gsub(mpdlines[9],"video_01", "video_00")
		else
			--print ("BaseURL nicht gefunden")
			table.insert(mpdlines, 3,'  <BaseURL>' .. host .. '</BaseURL>')

			if string.match(mpdlines[6], "<Role") then -- arte handling
				if string.match(mpdlines[16], "720") then
					mpdlines[7] = mpdlines[16]
				end
			end
		end

		local output = table.concat(mpdlines, "\n")
		local zeit, fzeit = channelinfo[3]:match("(%d+)/(%d+)")
		zeit = tonumber(zeit-1) -- vergangene Zeit
		fzeit = tonumber(fzeit, 10) -- volle Laufzeit

		if string.find(mpdlines[4],"<Period") then
			--print("Period gefunden")
			local per_tmp = mpdlines[4]
			output = string.gsub(output,per_tmp, '  <Period id="1" start="PT' .. zeit .. 'M">')
		end

		putdata(output, outputfile)
		replay(sender, umlaute(channelinfo[2]), umlaute(channelinfo[4]), fzeit)

	else
		message("Konnte mpd nicht finden / laden.", 3)
	end
else
	message("Sender unbekannt, kein Replay für diesen Sender.", 3)
end

local replay_end = pop("rm " .. outputfile)
collectgarbage()
