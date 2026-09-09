  --[[
	ZDF HBBTV
	Copyright (C) 2021 Jacek Jendrzej 'satbaby'
	Copyright (C) 2022 'bazi98' for Vers. 0.24  - add. UHD and FullHD
	License: WTFPLv2

	0.26: the old JSON proxy hbbtv.zdf.de/zdfm3/dyn/get.php answers
	HTTP 500 for every content id; all data now comes from
	hbbtv.zdf.de/legacy-al/ - the token-free backend of the official
	ZDFmediathek HbbTV app (1.41.5), which delivers the same elems
	document format.
]]

-- legacy-al base and the start page id of the official HbbTV app;
-- the app maps "zdf-hbbtv-startseite-100" to this uuid in its xo-*.js
-- (the readable id itself is not resolvable, the API answers 404)
local AL_BASE = "https://hbbtv.zdf.de/legacy-al/"
local START_ID = "8c3f3656-ceff-48ed-a199-9e23c5a3d135"

-- page documents: special:* ids have their own endpoint
function al_page_url(id)
	if id ~= nil and id:sub(1, 8) == "special:" then
		return AL_BASE .. "special-page?id=" .. id
	end
	return AL_BASE .. "dispatcher?id=" .. (id or "")
end

function init()
	Version = "0.26"
	CONF_PATH = "/var/tuxbox/config/"
	if DIR and DIR.CONFIGDIR then
		CONF_PATH = DIR.CONFIGDIR .. '/'
	end
	picfile = "/tmp/ZDFhbbtvEpg.jpg"
	dlPath = '/'
	lastmid = 1000
	json = require "json"
	fh = filehelpers.new()
	n = neutrino()
	vPlay = video.new()
	nMisc = misc.new()
	last_menu = {}
	hid = 0
	dl = {}
	Epg = nil
	Title = nil
	Info1 = nil
	Info2 = nil
	UrlPic = nil
	videostream, audiostream = nil,nil
	have_ffmpeg = which("ffmpeg")
	zdfhbbtv_icon = script_path() .. '/zdfhbbtv_hint.png'
	if not fh:exist(zdfhbbtv_icon , "f") then
		zdfhbbtv_icon='streaming'
	end
	-- last: needs json/fh/lastmid and, for error hints, a working info()
	inittab()
end

function inittab()
	local h = hintbox.new{text="Lese Daten..."}
	if h then
		h:paint()
	end
	aktivelist = get_zdf_data(al_page_url(START_ID))
	if aktivelist == nil or aktivelist.elems == nil then
		-- no start page, no plugin: main() shows the hint and exits
		aktivelist = nil
		if h then
			h:hide()
		end
		return
	end
	-- the api names neither the page nor its stage cluster
	aktivelist.title = aktivelist.title or 'ZDF Mediathek'
	local stage = aktivelist.elems[1]
	if type(stage) == "table" then
		local st = stage.title or stage.titletxt
		if st == nil or (type(st) == "string" and st:gsub('%s','') == '') then
			stage.title = 'Empfehlungen'
		end
	end
	-- optional sources may fail without blocking the start
	local jnTab = get_zdf_data(al_page_url('special:time'))
	if jnTab and jnTab.elems and jnTab.elems[1] and jnTab.elems[1].elems then
		lastmid = lastmid + 1
		table.insert(aktivelist.elems,{title='Sendung verpasst',myid=lastmid,elems=jnTab.elems[1].elems})
	end
	-- the a-z page carries the letter ranges as dropdown options
	-- (special:atoz: with a trailing colon is rejected nowadays)
	jnTab = get_zdf_data(al_page_url('special:atoz'))
	if jnTab and jnTab.elems and jnTab.elems[1] and jnTab.elems[1].options then
		local a = {}
		-- setmid() has tagged the options array with a myid field,
		-- so plain pairs() also yields that number - skip non-tables
		for _,v in pairs(jnTab.elems[1].options) do
			if type(v) == "table" and v.id and v.name then
				lastmid = lastmid + 1
				table.insert(a,{title=v.name,myid=lastmid,link={id='special:atoz:' .. v.id}})
			end
		end
		lastmid = lastmid + 1
		table.insert(aktivelist.elems,{title='A to Z',myid=lastmid,elems=a})
	end
	if h then
		h:hide()
	end
end

function setmid(tab,mid)
	for k,v in pairs(tab) do
		if type(v) == "table" then
			if v.type == 'specialcovers' or v.type == 'header' or v.type == 'infotext' then
				local el0 = {'addDocs','img','logo','refid','subtype','title','type','variant'}
				for _,k in pairs(el0) do
					v[k] = nil
				end
			else
				if v.headtxt and type(v.headtxt) == 'string' and #v.headtxt==0 then
					v.headtxt = nil
				end
				if v.elems then
					if #v.elems == 0 then
						v.elems=nil
					end
				end
				local el1 = {'broadcast','chapter1','chapter2','chapter3','chapter4','cl','click','co','ctype','date','eventType',
				            'eventType','foottxt','href','htmlAnchor','imageWithoutLogo','inhaltsTyp','internalId','isgroup',
				            'level1','level2','logo','overlay','path','pause','play','structureNodePath','track','url',
				            'variant','view','zdfView'}
				for _,k in pairs(el1) do
					v[k] = nil
				end
				if k ~= 'link' and k ~= 'infoline' then
					v.myid = mid
					mid = mid + 1
				end
				mid = setmid(v,mid)
			end
		end
	end
	return mid
end

function getmid(tab,mid)
	for k,v in pairs(tab) do
		if type(v) == "table" then
			if v.myid == mid then
				return v
			end
			v = getmid(v,mid)
			if v then return v end
		end
	end
end

function getitkey(tab,key,str)
	if tab == nil then return str end
	for k,v in pairs(tab) do
			if k == key then
				if str == nil then
					str = v
				else
					str = str .. ' ' .. v
				end
			end
		if type(v) == "table" then
			str = getitkey(v,key,str)
		end
	end
	return str
end

function script_path()
	local path = (debug.getinfo(2, "S").source:sub(2))
	return path:match("(.*[/\\])")
end

function getMaxRes()
	local maxRes = 1280
	local Nconfig = configfile.new()
	if Nconfig then
		Nconfig:loadConfig(CONF_PATH .. "neutrino.conf")
		maxRes = Nconfig:getInt32("livestreamResolution", 1280)
	end
	return maxRes
end

function getdata(Url,Postfields,outputfile,pass_headers,httpheaders)
	if Url == nil then return nil end
	if Curl == nil then
		Curl = curl.new()
	end

	if Url:sub(1, 2) == '//' then
		Url =  'https:' .. Url
	end

	local ret, data = Curl:download{ url=Url, A="Mozilla/5.0",maxRedirs=5,followRedir=true,postfields=Postfields,header=pass_headers,o=outputfile,httpheader=httpheaders }
	if ret == CURL.OK then
		if outputfile then
			return 1
		end
		return data
	else
		return nil
	end
end

function info(infotxt,cap)
	if cap == nil then
		cap = 'Information'
	end
	local h = hintbox.new{caption=cap, text=infotxt}
	if h then
		h:paint()
	local msg, data = nil,nil
	local stop = false
		repeat
			msg, data = n:GetInput(500)
		until msg == RC.ok or msg == RC.home or msg == RC.info
		h:hide()
	end
	h = nil
end

function version()
	local f = io.popen('stat -c %Y ' .. arg[0])
	local last_modified = f:read()
	local mdate = os.date("%c", last_modified)
	info('Version ' .. Version .. ' von satbaby\nZuletzt modifiziert\n' .. mdate,'ZDF HbbTV Versionsinfo')
end

function godirectkey(d)
	if d  == nil then return d end
	local  _dkey = ""
	if d == 1 then
		_dkey = RC.red
	elseif d == 2 then
		_dkey = RC.green
	elseif d == 3 then
		_dkey = RC.yellow
	elseif d == 4 then
		_dkey = RC.blue
	elseif d < 14 then
		_dkey = RC[""..d - 4 ..""]
	elseif d == 14 then
		_dkey = RC["0"]
	else
		-- rest
		_dkey = ""
	end
	return _dkey
end

function hideMenu(menu)
	if menu then menu:hide() end
end


function sleep(a)
	local sec = tonumber(os.clock() + a)
	while (os.clock() < sec) do
	end
end

function rescalePic(picW,picH,maxW,maxH)
	if picW and picW > 0 and picH and picH > 0 then
		local aspect = picW / picH
		if not maxH then
			maxH = getMaxScreenHeight()
		end
		if not maxW then
			maxW = getMaxScreenWidth()
		end
		if picW / maxW > picH / maxH then
			picW = maxW
			picH = maxW/aspect
		else
			picH = maxH
			picW = maxH * aspect
		end
		picH = math.floor(picH)
		picW = math.floor(picW)
	end
	return picW,picH
end

function getMaxScreenWidth()
	local max_w = SCREEN.END_X - SCREEN.OFF_X
	return max_w
end

function getMaxScreenHeight()
	local max_h = SCREEN.END_Y - SCREEN.OFF_Y
	return max_h
end

function epgInfo(xres, yres, aspectRatio, framerate)
	local dltxt = ''
	local dl_possible = dl_check(videostream)
	local dl = {}
	if dl_possible then
		dl = gen_dl(videostream, audiostream, Title, Epg)
		dltxt = 'Download Video'
	end
	local withPic = false
	if not fh:exist(picfile , "f") then
		local ok = getdata(UrlPic, nil, picfile)
		if ok then
			withPic = true
		end
	else
		withPic = true
	end

	local off_w,x,y,w,h  = 0,0,0,0,0
	local space = OFFSET.INNER_MID
	local wow = cwindow.new{x=x, y=y, dx=w, dy=h, title=Title, btnRed=dltxt }
	local tf = wow:headerHeight() + wow:footerHeight()
	w,h = n:scale2Res(600), n:scale2Res(300) + tf
	local tw = n:getRenderWidth(FONT.MENU_TITLE,Title) + (wow:headerHeight() * 2)
	if tw > w then
		w = tw
		if w > 1200 then w = 1200 end
	end
	if withPic then
		local maxW ,maxH = n:scale2Res(440), n:scale2Res(368)
		local picW, picH = n:GetSize(picfile)
		maxW,maxH = rescalePic(picW,picH,maxW,maxH)
		off_w,h = maxW,maxH
		cpicture.new{parent=wow, x=space, y=space, dx=maxW, dy=maxH, image=picfile}
		h = maxH + tf + (space*2)
		local wP =  (maxW * 2) + (space * 3)
		if w < wP then
			w = wP
		end
	end

	ct = ctext.new{parent=wow, x=off_w + (space*2), y=space, dx=w-off_w, dy=h-tf, text=Epg, mode="ALIGN_TOP | ALIGN_SCROLL"}
	if withPic == false then
		local ctLines = ct:getLines() + 1
		local th = ctLines * n:FontHeight(FONT.MENU) + tf + (2*space)
		if th < 720 then
			h = th
		end
	end
	wow:setDimensionsAll(x , y, w, h)
	wow:setCenterPos{3}
	wow:paint()

	local msg, data = nil,nil
	local stop = false
	repeat
		msg, data = n:GetInput(500)
		if ct and (msg == RC.up or msg == RC.page_up) then
			ct:scroll{dir="up"}
		elseif ct and (msg == RC.down or msg == RC.page_down) then
			ct:scroll{dir="down"}
		elseif dl_possible and msg == RC.red then
			stop = true
		end
	until msg == RC.ok or msg == RC.home or msg == RC.info or stop
	wow:hide()

	if dl_possible and msg == RC.red  then
		local h = hintbox.new{caption="Download gestartet   ", text=Title}
		h:paint()
		dl_stream(dl)
		sleep(3)
		h:hide()
	end
end

function toUcode(s)
	if s == nil or type(s) ~= 'string' then return s end
	s=s:gsub("&","&amp;")

	s=s:gsub("'","&apos;")
	s=s:gsub("<","&lt;")
	s=s:gsub(">","&gt;")
	s=s:gsub('"',"&quot;")
	s=s:gsub("\x0a","&#x0a;")
	s=s:gsub("\x0d","&#x0d;")
	return s
end

function xml_entities(s)
	if s == nil or type(s) ~= 'string' then return s end
	s = s:gsub('&lt;'  , '<' )
	s = s:gsub('&gt;'  , '>' )
	s = s:gsub('&quot;', '"' )
	s = s:gsub('&apos;', "'" )

	s = s:gsub('&Auml;', 'Ä' )
	s = s:gsub('&auml;', 'ä' )
	s = s:gsub('&Ouml;', 'Ö' )
	s = s:gsub('&ouml;', 'ö' )
	s = s:gsub('&uuml;', 'ü' )
	s = s:gsub('&Uuml;', 'Ü' )
	s = s:gsub('&szlig;','ß' )

	s = s:gsub('&aacute;','á' )
	s = s:gsub('&Aacute;','Á' )
	s = s:gsub('&eacute;','é' )
	s = s:gsub('&Eacute;','É' )
	s = s:gsub('&uacute;','ú' )
	s = s:gsub('&Uacute;','Ú' )

	s = s:gsub('&euro;','€' )
	s = s:gsub('&copy;','©' )
	s = s:gsub('&reg;','®' )
	s = s:gsub('&nbsp;',' ' )
	s = s:gsub('&shy;','' )
	s = s:gsub('&Oacute;','Ó' )
	s = s:gsub('&oacute;','ó' )
	s = s:gsub('&bdquo;','„' )
	s = s:gsub('&ldquo;','“' )
	s = s:gsub('&ndash;','–' )
	s = s:gsub('&mdash;','—' )
	s = s:gsub('&hellip;','…' )
	s = s:gsub('&lsquo;','‘' )
	s = s:gsub('&rsquo;','’' )
	s = s:gsub('&lsaquo;','‹' )
	s = s:gsub('&rsaquo;','›' )
	s = s:gsub('&permil;','‰' )
	s = s:gsub('&egrave;','è' )
	s = s:gsub('&sbquo;','‚' )
	s = s:gsub('&raquo;','»' )
	s = s:gsub('&rdquo;','”' )
	s = s:gsub('&ccedil;','ç' )

	s = s:gsub('&amp;' , '&' )
	return s
end

function writeXML(ch, title, info1, info2, filename)
	ch = ch or ""
	title = title or ""
	info1 = info1 or ""
	info2 = info2 or ""
local xml='<?xml version="1.0" encoding="UTF-8"?>\
\
<neutrino commandversion="1">\
	<record command="record">\
		<channelname>' .. ch .. '</channelname>\
		<epgtitle>' .. toUcode(title) .. '</epgtitle>\
		<id>0</id>\
		<info1>' .. toUcode(info1) .. '</info1>\
		<info2>' .. info2 .. '</info2>\
		<epgid>0</epgid>\
		<mode>1</mode>\
		<videopid>0</videopid>\
		<videotype>1</videotype>\
		<audiopids>\
			<audio pid="1" audiotype="0" selected="0" name=""/>\
		</audiopids>\
		<vtxtpid>0</vtxtpid>\
		<genremajor>0</genremajor>\
		<genreminor>0</genreminor>\
		<seriename></seriename>\
		<length>0</length>\
		<productioncountry></productioncountry>\
		<productiondate>0</productiondate>\
		<rating>0</rating>\
		<quality>0</quality>\
		<parentallockage>0</parentallockage>\
		<dateoflastplay>0</dateoflastplay>\
		<bookmark>\
			<bookmarkstart>0</bookmarkstart>\
			<bookmarkend>0</bookmarkend>\
			<bookmarklast>0</bookmarklast>\
			<bookmarkuser bookmarkuserpos="0" bookmarkusertype="0" bookmarkusername=""/>\
		</bookmark>\
	</record>\
</neutrino>\n'

	local file = io.open(filename,'w')
	file:write(xml)
	file:close()
end

function dl_stream(dl)
	local Format = nil
	if dl and dl.streamUrl then
		if dl.streamUrl:sub(-4) == ".mp4" then
			Format = 'mp4'
		elseif dl.streamUrl:find("m3u8") then
			Format = 'ts'
		end
		local dlname = nil
		if dl.info1 then
			dlname = dl.ch .. "_" .. dl.name .. "_" .. dl.info1
			dlname = dlname:gsub("[%p%s/]", "_")
		end
		if dlname and Format then
			local dls  = "/tmp/.zdfhbbtv_dl.sh"
			local filenamexml = "/tmp/.zdfhbbtv_dl_xml"
			writeXML(dl.ch, dl.name, dl.info1, dl.info2, filenamexml)
			dlname = dlPath .. "/" .. dlname
			local script=io.open(dls,"w")
			script:write('echo "download start" ;\n')
			if Format == 'mp4' then
				script:write('wget -q --continue ' .. dl.streamUrl .. ' -O ' .. dlname .. '.mp4 ;\n')
			elseif Format == 'ts' or Format == 'mkv' then
				if dl.streamUrl2 then
					script:write("ffmpeg -y -nostdin -loglevel 30 -i '" .. dl.streamUrl .. "' -i '" .. dl.streamUrl2  .. "' -c copy  " .. dlname   .. "." .. Format .. "\n")
				else
					script:write("ffmpeg -y -nostdin -loglevel 30 -i '" .. dl.streamUrl .. "' -c copy  " .. dlname   .. "." .. Format .. "\n")
				end
			end
			script:write('if [ $? -eq 0 ]; then \n')
			script:write('wget -q http://127.0.0.1/control/message?popup="Video ' .. Title .. ' wurde heruntergeladen." -O /dev/null ; \n')
			script:write('mv ' .. filenamexml .. ' ' .. dlname .. '.xml ; \n')
			script:write('else \n')
			script:write('wget -q http://127.0.0.1/control/message?popup="Download ' .. Title .. ' FEHLGESCHLAGEN" -O /dev/null ; \n')
			script:write('rm ' .. filenamexml .. ' ; \n')
			script:write('fi \n')
			script:write('rm ' .. dls .. '; \n')
			script:close()
			os.execute('sh  ' .. dls .. ' &')
			return true
		end
	end
	return false
end

function dl_check(streamUrl)
	local check = false
	local Nconfig = configfile.new()
	if Nconfig then
		Nconfig:loadConfig(CONF_PATH .. "neutrino.conf")
		dlPath = Nconfig:getString("network_nfs_recordingdir", '/tmp')
	end

	local dl_not_possible = dlPath == '/tmp' or dlPath == '/'
	if dl_not_possible then return check end
	if fh:exist('/tmp/.zdfhbbtv_dl.sh', 'f') then return check end
	if streamUrl:sub(-4) == ".mp4" then
		check = true
	elseif have_ffmpeg and streamUrl:find('m3u8') then
		check = true
	end
	return check
end

function gen_dl(streamUrl,streamUrl2,title,info1)
	local dl = {}
	dl.name = title
	dl.streamUrl = streamUrl
	dl.streamUrl2 = streamUrl2
	dl.info1 = ''
	dl.ch = 'ZDF Hbbtv'
	dl.date = ''
	if info1 then
		dl.info2 = toUcode(info1)
	end

	return dl
end

function which(bin_name)
	local path = os.getenv("PATH") or "/bin"
	for v in path:gmatch("([^:]+):?") do
		local file = v .. "/" .. bin_name
		if fh:exist(file , "f") then
			return true
		end
	end
	return false
end

function getVideoUrlM3U8(m3u8_url)
	if m3u8_url == nil then return nil end
	local res = 0
	local videoUrl = nil
	local audioUrl = nil
	local data = getdata(m3u8_url)
	if data then
		local host = m3u8_url:match('([%a]+[:]?//[_%w%-%.]+)/')
		local lastpos = (m3u8_url:reverse()):find("/")
		local hosttmp = m3u8_url:sub(1,#m3u8_url-lastpos)
		if hosttmp then
			host = hosttmp .."/"
		end
		local revision = 0
		if APIVERSION ~= nil and (APIVERSION.MAJOR > 1 or ( APIVERSION.MAJOR == 1 and APIVERSION.MINOR > 82 )) then
			revision = nMisc:GetRevision()
		end

		local audio_url = nil
		if revision == 1 then -- separate audio for hd51 and co
			local Nconfig	= configfile.new()
			local lang1,lang2,lang3 = nil,nil,nil
			Nconfig:loadConfig(CONF_PATH .. "neutrino.conf")
			lang1 = Nconfig:getString("pref_lang_0", "#")
			lang2 = Nconfig:getString("pref_lang_1", "#")
			lang3 = Nconfig:getString("pref_lang_2", "#")
			if lang1 == "#" then lang1 = nil else lang1 = lang1:lower() lang1 = lang1:sub(1,3) end
			if lang2 == "#" then lang2 = nil else lang2 = lang2:lower() lang2 = lang2:sub(1,3) end
			if lang3 == "#" then lang3 = nil else lang3 = lang3:lower() lang3 = lang3:sub(1,3) end
			if lang1 == nil then
				lang1 = Nconfig:getString("language", "english")
				if lang1 == nil then
					lang1 = "eng"
				else
					lang1 = lang1:lower() lang1 = lang1:sub(1,3)
				end
			end

			local l1,l2,l3,l4,l = nil,nil,nil,nil,nil
			for adata in data:gmatch('TYPE%=AUDIO.GROUP%-ID=".-",(.-)\n') do
				local lname = adata:match('NAME="(.-)"')
				local lang = adata:match('LANGUAGE="(.-)"')
				local aurl = adata:match('URI="(.-)"')
				if aurl then
					local low_lang = lang and lang:lower() or ""
					if l1 == nil and lname and lang1 and low_lang == lang1 then
						l1 = aurl
					elseif l2 == nil and lname and lang2 and low_lang == lang2 then
						l2 = aurl
					elseif l3 == nil and lname and lang3 and low_lang == lang3 then
						l3 = aurl
					elseif l4 == nil and lname and low_lang == "deu" then
						l4 = aurl
					elseif l == nil then
						l = aurl
					end
				end
			end
			audio_url = l1 or l2 or l3 or l4 or l
		end
		local maxRes = getMaxRes()
		local allres = {}
		local j = 1
		local minRes = 0
		for band, res1, res2, url in data:gmatch('BANDWIDTH=(%d+).-RESOLUTION=(%d+)x(%d+).-\n(.-)\n') do
			local nr = tonumber(res1)
			if nr <= maxRes then
				minRes = nr
			end
			allres[j] = nr
			j=j+1
		end
		if minRes == 0 and j>1 then maxRes = math.min(unpack(allres)) end

		for band, res1, res2, url in data:gmatch('BANDWIDTH=(%d+).-RESOLUTION=(%d+)x(%d+).-\n(.-)\n') do
			if url and res1 then
				local nr = tonumber(res1)
				if (nr <= maxRes and nr > res) then
					res=nr
					if host and url:sub(1,4) ~= "http" then
						url = host .. url
					end
					if audio_url and host and audio_url:sub(1,4) ~= "http" then
						audio_url = host .. audio_url
					end
					videoUrl  = url
					audioUrl  = audio_url
				end
			end
		end
	else
		return m3u8_url, nil
	end
	if videoUrl then videoUrl = videoUrl:gsub("\x0d","") end
	if audioUrl then audioUrl = audioUrl:gsub("\x0d","") end
	return videoUrl, audioUrl
end

-- returns the first url below <codec>.main.deu following the given
-- quality order; the "ad" audio group (audio description) is not used
function urlFromCodec(codecTab, qorder)
	if type(codecTab) ~= "table" then
		return nil
	end
	local m = codecTab.main
	if type(m) ~= "table" or type(m.deu) ~= "table" then
		return nil
	end
	for _, q in ipairs(qorder) do
		local e = m.deu[q]
		if type(e) == "table" and e.url then
			return e.url
		end
	end
	return nil
end

-- streams[] selection: "default" streams first (sign language "dgs"
-- only as a last resort), per stream mp4 -> hls -> plain ts (live)
-- -> dash; every level is checked, a nil just moves on
function selectStreamUrl(streams)
	if type(streams) ~= "table" then
		return nil, nil
	end
	local maxRes = getMaxRes()
	local qorder
	if maxRes > 1921 then
		qorder = {"q5","q4","q3","q1"}
	elseif maxRes > 1281 then
		qorder = {"q4","q3","q1"}
	else
		qorder = {"q1","q3"}
	end
	local cands = {}
	for _, v in ipairs(streams) do
		if type(v) == "table" and v.kind ~= "dgs" then
			table.insert(cands, v)
		end
	end
	for _, v in ipairs(streams) do
		if type(v) == "table" and v.kind == "dgs" then
			table.insert(cands, v)
		end
	end
	for _, v in ipairs(cands) do
		local url = nil
		if maxRes > 1281 then
			url = urlFromCodec(v.h265_aac_mp4_http_na_na, qorder)
		end
		url = url or urlFromCodec(v.h264_aac_mp4_http_na_na, qorder)
		if url then
			return url, nil
		end
		local m3u8 = urlFromCodec(v.h264_aac_ts_http_m3u8_http, {"q3","q1","q4","q5"})
		if m3u8 then
			local vurl, aurl = getVideoUrlM3U8(m3u8)
			if vurl then
				return vurl, aurl
			end
			return m3u8, nil
		end
		-- live events carry a plain transport stream (and dash below)
		url = urlFromCodec(v.h264_aac_ts_http_na_na, {"q1","q3","q4"})
		if url then
			return url, nil
		end
		url = urlFromCodec(v.h264_aac_mp4_http_mpd_http, {"q1","q3","q4"})
		if url then
			return url, nil
		end
	end
	return nil, nil
end

function getZDFstream(tab)
	if tab == nil or tab.link == nil or tab.link.id == nil then
		return
	end
	local jdata = getdata(AL_BASE .. 'video?id=' .. tab.link.id)
	if jdata == nil then
		return
	end
	local ok, jnTab = pcall(function() return json:decode(jdata) end)
	if not ok or type(jnTab) ~= "table" then
		return
	end
	tab.audiostream = nil
	tab.stream = nil
	if jnTab.streams then
		tab.stream, tab.audiostream = selectStreamUrl(jnTab.streams)
	end
	Epg,Title,Info1,Info2,UrlPic = nil,nil,nil,nil,nil
	videostream, audiostream = nil,nil
	if jnTab.text then Epg = xml_entities(jnTab.text) end
	if jnTab.title then Title = xml_entities(jnTab.title) end
	if jnTab.cpix and jnTab.cpix.nielsen and jnTab.cpix.nielsen.program then
		Info1 = jnTab.cpix.nielsen.program
		if jnTab.cpix.nielsen.nol_c5 then
			-- nowadays nol_c5 often carries a media url - not a name
			local c5 = jnTab.cpix.nielsen.nol_c5:match(',(.*)')
			if c5 and not c5:match('^https?://') then
				Info2 = c5
			end
		end
	end
	local str = nil
	if jnTab.displayAvailability then
		str = getitkey(jnTab.displayAvailability.lineOne,'title',str)
		str = getitkey(jnTab.displayAvailability.lineTwo,'title',str)
	end
	if str then
		if Info2 then
			Info2 = Info2 .. ': ' .. str
		else
			Info2 = str
		end
	end
	tab.img = tab.img or jnTab.img
	tab.Epg = Epg
	tab.Title = Title
	tab.Info1 = Info1
	tab.Info2 = Info2
end

function play_video(tab)
	if tab.stream then
		hideMenu(last_menu[hid])
		if tab.Title then
			Epg = tab.Epg or ""
			Title = tab.Title
			videostream, audiostream = tab.stream,tab.audiostream
			UrlPic = tab.img
			os.remove(picfile)
			vPlay:setInfoFunc("epgInfo")
		end
		vPlay:PlayFile(tab.Title, tab.stream, tab.Info1 or "",tab.Info2 or 'ZDF hbbtv',tab.audiostream or "")
	end
end

function get_zdf_data(link,data)
	local h = hintbox.new{text="Lese Daten..."}
	if h then
		h:paint()
	end
	if data == nil then
		data = getdata(link)
	end
	local jnTab = nil
	if data then
		-- some json libs throw on invalid input, and the API answers
		-- errors as documents without elems - both count as "no data"
		local ok, js = pcall(function() return json:decode(data) end)
		if ok and type(js) == "table" and (js.elems or js.recoElems) then
			jnTab = js
			lastmid = setmid(jnTab,lastmid)
		end
	end
	if h then
		h:hide()
	end
	return jnTab
end

function selPlay(id)
	hideMenu(last_menu[hid])
	local h = hintbox.new{text="Lese Daten..."}
	if h then
		h:paint()
	end
	id = tonumber(id)
	local vTab = getmid(aktivelist,id)
	if vTab then
		if vTab.stream == nil then
			getZDFstream(vTab)
		end
	end
	if h then
		h:hide()
	end
	if vTab and vTab.stream then
		play_video(vTab)
	elseif vTab then
		info("Kein abspielbarer Stream gefunden.", "ZDF HbbTV")
	end
end

function selList(id)
	hideMenu(last_menu[hid])
	local h = hintbox.new{text="Lese Daten..."}
	if h then
		h:paint()
	end

	id = tonumber(id)
	local myTab = getmid(aktivelist,id)
	if myTab == nil then
		if h then
			h:hide()
		end
		return
	end
	if myTab.elems == nil then
		local newTab = nil
		if myTab.link and myTab.link.id then
			newTab = get_zdf_data(al_page_url(myTab.link.id))
		end
		if newTab == nil then
			if h then
				h:hide()
			end
			info("Keine Daten vom ZDF-Dienst erhalten.", "ZDF HbbTV")
			return
		end
		myTab.elems = {}
		if newTab.elems == nil and newTab.recoElems then
			myTab.elems = newTab.recoElems
			lastmid = lastmid + 1
			myTab.elems.link = {}
			local link = {}
			link.id=newTab.id
			table.insert(myTab.elems,{title=newTab.title,img=newTab.img,hasVideo=true,myid=lastmid,link=link})
		else
			myTab.elems = newTab.elems
		end
	end
	-- live stream teasers come without any text (the official app
	-- shows channel logos instead); fetch their titles from the video
	-- document once - this also caches the stream for selPlay
	for _, v in ipairs(myTab.elems or {}) do
		if type(v) == "table" and v.hasVideo and v.myid and v.link then
			local t = v.titletxt or v.title
			if t == nil or (type(t) == 'string' and t:gsub('%s','') == '') then
				getZDFstream(v)
				if v.Title then
					-- titletxt (whitespace) would win over title
					v.titletxt = nil
					v.title = v.Title
				end
			end
		end
	end
	if h then
		h:hide()
	end
	main_menu(myTab)
end

function backToMenu1(id)
	if hid == 1 then os.execute('rcsim KEY_HOME') return end

	for i=1,hid-1 do
		os.execute('rcsim KEY_HOME')
	end
end

function main_menu(liste)
	if liste == nil or liste.elems == nil then print('liste error') return end
	hid = hid + 1

	local ptype = {}
	local warning = 4
	for i, el in ipairs(liste.elems) do
		if el.elems then
			for j, v in ipairs(el.elems) do
				if v.link and v.link.type then
					ptype[i] = v.link.type
					break
				end
			end
		end
	end

	local tname = liste.title or liste.titletxt or liste.myid or liste.id
	tname = xml_entities(tname)
	if tname and type(tname) == 'string' and #tname == 0 then tname = 'Titel' end
	local menu  = menu.new{name = tname, icon=zdfhbbtv_icon}
	last_menu[hid] = menu
	menu:addItem{type='back'}
	menu:addItem{type='separatorline'}
	menu:addKey{directkey=RC.setup, id="_", action="backToMenu1"}
	menu:addKey{directkey=RC.info, id="_", action="version"}
	local d =  0
	for i, v in ipairs(liste.elems) do
		local skip = false
		if hid > 12 and ptype[i] == 'page' then skip = true end
		if not skip and v.myid and (v.hasVideo==nil or v.hasVideo==false) and (v.titletxt or v.title) then
			if d == 0 then menu:addItem{type="subhead", name='Untermenü'} end
			d=d+1
			local mact = 'selList'
			local hico = 'hint_next'
			local mname =  v.titletxt or v.title or v.myid or '## error ##'
			tname = xml_entities(tname)
			if mname and type(mname) == 'string' and mname:gsub('%s','') == '' then mname = 'Untermenü' end
			local vhint = nil
			if v.headtxt then
				vhint = v.headtxt
			end
			if v.infoline and v.infoline.text then
				if vhint then
					vhint = vhint .. ' - ' .. v.infoline.text
				else
					vhint = v.infoline.text
				end
			end
			if v.text then
				if vhint then
				 vhint = vhint .. ' - ' .. v.text
				else
					vhint = v.text
				end
			end
			if (not vhint and hid > warning and ptype[i] == 'page') or hid > 13 then
				vhint = 'Untermenü - Zurück zum Start-Menü über Menü-Taste'
			end
			if not vhint and ptype[i] == 'video' then
				vhint = 'Video-Untermenü'
			end
			if (not vhint and ptype[i] == 'video') or hid > 7 then
				vhint = 'Video-Untermenü - Zum Start-Menü über Menü-Taste'
			end
			if not vhint and ptype[i] == 'page' then
				vhint = 'Untermenü'
			end
			mname = xml_entities(mname)
			vhint = xml_entities(vhint)
			menu:addItem{type="forwarder" , name=mname, action=mact,hint=vhint ,hint_icon=hico ,id=v.myid ,directkey=godirectkey(d)}
		end
	end
	local one = true
	for i, v in ipairs(liste.elems) do
		if v.myid and v.hasVideo then
			if one then 	menu:addItem{type='subhead', name='Videos'} one = false end
			d=d+1
			local mact = 'selPlay'
			local hico = 'video'
			local mname =  v.titletxt or v.title or v.myid or '## error ##'
			local vhint = nil
			if v.headtxt then
				vhint = v.headtxt
			end
			if v.infoline and v.infoline.text then
				if vhint then
					vhint = vhint .. ' - ' .. v.infoline.text
				else
					vhint = v.infoline.text
				end
			end
			if v.text then
				if vhint then
				 vhint = vhint .. ' - ' .. v.text
				else
					vhint = v.text
				end
			end
			mname = xml_entities(mname)
			vhint = xml_entities(vhint)
			if mname and type(mname) == 'string' and mname:gsub('%s','') == '' then mname = 'Video' end
			menu:addItem{type="forwarder" ,icon="streaming", name=mname, action=mact,hint=vhint,hint_icon=hico ,id=v.myid ,directkey=godirectkey(d)}
		end
	end

	menu:exec()
	hid = hid - 1
end

function main()
	init()
	if aktivelist and aktivelist.elems then
		main_menu(aktivelist)
	else
		info("Der ZDF-Dienst ist zur Zeit nicht erreichbar.", "ZDF HbbTV")
	end
	os.remove(picfile)
	collectgarbage()
end

main()
