--[[
	replay.lua

	16/2/2024 by jokel
	Version 0.80 beta
]]

local sender_mpd =
{	["Das Erste HD"] = "https://mcdn.daserste.de/daserste/dash/manifest.mpd",
	["arte HD"] = "https://arteliveext.akamaized.net/dash/live/2031004/artelive_de/dash.mpd",
	["SWR BW HD"] = "https://swrbw-dash.akamaized.net/dash/live/2018674/swrbwd/manifest.mpd",
	["SWR RP HD"] = "https://swrrp-dash.akamaized.net/dash/live/2018680/swrrpd/manifest.mpd",
	["WDR HD Köln"] = "https://wdrfs247.akamaized.net/dash/live/2016702/wdrfs247_geo/dash.mpd",
	["WDR HD Aachen"] = "https://wdrlokalzeit.akamaized.net/dash/live/2018107/wdrlz_aachen/dash.mpd",
	["WDR HD Bielefeld"] = "https://wdrlokalzeit.akamaized.net/dash/live/2018117/wdrlz_bielefeld/dash.mpd",
	["WDR HD Bonn"] = "https://wdrlokalzeit.akamaized.net/dash/live/2018112/wdrlz_bonn/dash.mpd",
	["WDR HD Dortmund"] = "https://wdrlokalzeit.akamaized.net/dash/live/2018113/wdrlz_dortmund/dash.mpd",
	["WDR HD Duisburg"] = "https://wdrlokalzeit.akamaized.net/dash/live/2018115/wdrlz_duisburg/dash.mpd",
	["WDR HD Düsseldorf"] = "https://wdrlokalzeit.akamaized.net/dash/live/2018114/wdrlz_duesseldorf/dash.mpd",
	["WDR HD Essen"] = "https://wdrlokalzeit.akamaized.net/dash/live/2018118/wdrlz_essen/dash.mpd",
	["WDR HD Münster"] = "https://wdrlokalzeit.akamaized.net/dash/live/2018116/wdrlz_muensterland/dash.mpd",
	["WDR HD Siegen"] = "https://wdrlokalzeit.akamaized.net/dash/live/2018111/wdrlz_siegen/dash.mpd",
	["WDR HD Wuppertal"] = "https://wdrlokalzeit.akamaized.net/dash/live/2018126/wdrlz_wuppertal/dash.mpd",
	["BR Süd HD"] = "https://bfrsueddash.akamaized.net/dash/live/2016970/bfs_sued_de/dvbt2/manifest.mpd",
	["BR Fernsehen Süd HD"] = "https://bfrsueddash.akamaized.net/dash/live/2016970/bfs_sued_de/dvbt2/manifest.mpd",
	["BR Fernsehen Nord HD"] = "https://bfrnorddash.akamaized.net/dash/live/2016971/bfs_nord_de/dvbt2/manifest.mpd",
	["NDR FS NDS HD"] = "https://mcdn.ndr.de/ndr/dash/ndr_hbbtv/ndr_hbbtv_nds/ndr_hbbtv_nds.mpd",
	["NDR FS MV HD"] = "https://mcdn.ndr.de/ndr/dash/ndr_hbbtv/ndr_hbbtv_mv/ndr_hbbtv_mv.mpd",
	["NDR FS HH HD"] = "https://mcdn.ndr.de/ndr/dash/ndr_hbbtv/ndr_hbbtv_hh/ndr_hbbtv_hh.mpd",
	["NDR FS SH HD"] = "https://mcdn.ndr.de/ndr/dash/ndr_hbbtv/ndr_hbbtv_sh/ndr_hbbtv_sh.mpd",
	["phoenix HD"] = "https://zdf-dash-19.akamaized.net/dash/live/2016512/de/manifest.mpd",
	["PHOENIX HD"] = "https://zdf-dash-19.akamaized.net/dash/live/2016512/de/manifest.mpd",
	["tagesschau24 HD"] = "https://tagesschau.akamaized.net/dash/live/2020098/tagesschau/tagesschau_3/tagesschau_3.mpd",
	["ONE HD"] = "https://mcdn.one.ard.de/ardone/dash/manifest.mpd",
	["ARD alpha HD"] = "https://ardalphadash.akamaized.net/dash/live/2016972/ard_alpha/dvbt2/manifest.mpd",
	["SR Fernsehen HD"] = "https://swrsrfs-dash.akamaized.net/dash/live/2018687/srfsgeo/dash.mpd",
	["Radio Bremen HD"] = "https://rbdashlive.akamaized.net/dash/live/2020436/rbfs/dash.mpd",
	["rbb Brandenburg HD"] = "https://rbb-dash-brandenburg.akamaized.net/dash/live/2017827/rbb_brandenburg/manifest.mpd",
	["rbb Berlin HD"] = "https://rbb-dash-berlin.akamaized.net/dash/live/2017826/rbb_berlin/manifest.mpd",
	["MDR Sachsen HD"] = "https://mdrtvsndash.akamaized.net/dash/live/2094117/mdrtvsn/dash.mpd",
	["MDR S-Anhalt HD"] = "https://mdrtvsadash.akamaized.net/dash/live/2094116/mdrtvsa/dash.mpd",
	["MDR Thüringen HD"] = "https://mdrtvthdash.akamaized.net/dash/live/2094118/mdrtvth/dash.mpd",
	["hr-fernsehen HD"] = "https://hrdashde.akamaized.net/dash/live/2024544/hrdashde/manifest.mpd",
	["ZDF HD"] = "https://zdf-dash-15.akamaized.net/dash/live/2016508/de/manifest.mpd",
	["ZDFinfo HD"] = "https://zdf-dash-17.akamaized.net/dash/live/2016510/de/manifest.mpd",
	["zdf_neo HD"] = "https://zdf-dash-16.akamaized.net/dash/live/2016509/de/manifest.mpd",
	["3sat HD"] = "https://zdf-dash-18.akamaized.net/dash/live/2016511/dach/manifest.mpd",
	["KiKA HD"] = "https://kikageoilsdash.akamaized.net/dash/live/2099498/dashhbbtv-ebu-proxy-full/manifest.mpd"
}

local outputfile = "/tmp/output.mpd"
local dir = "/tmp/lcd/"
local service = dir .. "service"
local duration = dir .. "duration"
local event = dir .. "event"

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
	s=s:gsub("\xe4","ä")
	s=s:gsub("\xfc","ü")
	s=s:gsub("\xf6","ö")
	return s
end

function getdata(Url, outputfile)
	if Url == nil then return nil end
	if Curl == nil then
		Curl = curl.new()
	end
	local ret, data = Curl:download{ url=Url, A="Mozilla/5.0", o=outputfile }
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

function replay(name,title)
	local vPlay = video.new()
	vPlay:setSinglePlay(true)
	vPlay:PlayFile("Replay - " .. name, outputfile, title[1], title[2] )
end

function message(txt,s)
	local h = hintbox.new{caption="Hinweis ...", text= txt}
	if h then
		 h:paint()
	end
	sleep(s)
	h:hide()
end

------------------- replay ------------------------------

local name = get_text(service)

if name == nil then
	message("Die LCD4Linux Unterstützung ist ausgeschaltet \n\n Bitte einschalten.", 5)
	return
end

name = umlaute(name[1])
local mpd_url = sender_mpd[name]

if mpd_url then
	local file = getdata(mpd_url, outputfile)
	if file then
		local mpd_pos = (mpd_url:reverse()):find("/")
		local mpd_tmp = mpd_url:sub( 1, #mpd_url - mpd_pos + 1)
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
		end

		local output = table.concat(mpdlines, "\n")
		local zeit = get_text(duration)
		zeit = zeit[2]
		zeit = tonumber(zeit-1,10) -- vergangene zeit

		if string.find(mpdlines[4],"<Period") then
			--print("Period gefunden")
			local per_tmp = mpdlines[4]
			output = string.gsub(output,per_tmp, '  <Period id="1" start="PT' .. zeit .. 'M">')
		end

		local title = get_text(event) -- action
		putdata(output, outputfile)
		replay(name, title)

	else
		message("konnte mpd nicht finden / laden", 3)
	end
else
	message("kein Replay für diesen Sender", 3)
end

local replay_end = pop("rm " .. outputfile)
collectgarbage()
