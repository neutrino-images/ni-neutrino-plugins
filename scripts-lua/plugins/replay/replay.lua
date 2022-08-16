-- version 0.1 add ard

function init()
	json = require "json"
	replayList = {}
	replayMenu = nil
	getReLiveList_ARD()
	n = neutrino()
	vPlay = video.new()
	nMisc = misc.new()
	repaint = false
	Epg = nil
	Title = nil
end

function getdata(Url,Postfields,outputfile,pass_headers,httpheaders)
	if Url == nil then return nil end
	if Curl == nil then
		Curl = curl.new()
	end

	if Url:sub(1, 2) == '//' then
		Url =  'https:' .. Url
	end

	local ret, data = Curl:download{ url=Url, A="Mozilla/5.0",maxRedirs=5,followRedir=false,postfields=Postfields,header=pass_headers,o=outputfile,httpheader=httpheaders }
	if ret == CURL.OK then
		if outputfile then
			return 1
		end
		return data
	else
		return nil
	end
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
	if menu ~= nil then
		menu:hide()
	end
end

function epgInfo (xres, yres, aspectRatio, framerate)
	local dx = n:scale2Res(800);
	local dy = n:scale2Res(400);
	local x = ((SCREEN['END_X'] - SCREEN['OFF_X']) - dx) / 2;
	local y = ((SCREEN['END_Y'] - SCREEN['OFF_Y']) - dy) / 2;

	local wh = cwindow.new{x=x, y=y, dx=dx, dy=dy, icon="", show_footer=false};
	local ct = ctext.new{parent=wh, x=20, y=20, dx=0, dy=0, text=Epg, font_text=FONT['MENU'], mode="ALIGN_SCROLL | ALIGN_TOP"};
        wh:setCaption{title=Title, alignment=TEXT_ALIGNMENT.CENTER};

	wh:paint()

	repeat
	msg, data = n:GetInput(500)
		if msg == RC.up or msg == RC.page_up then
			ct:scroll{dir="up"};
		elseif msg == RC.down or msg == RC.page_down then
			ct:scroll{dir="down"};
		end
		msg, data = n:GetInput(500)
	until msg == RC.ok or msg == RC.home or msg == RC.info ;
	wh:hide()
end

function play_live(_id)
	local id = tonumber(_id)
	if replayList[id].stream == nil then
		getLiveStream(id)
	end
	if replayList[id].stream then
		hideMenu(replayMenu)
		Epg = replayList[id].epg
		Title = replayList[id].name
		if Epg and Title then
			vPlay:setInfoFunc("epgInfo")
		end
		local info1 = "Replay"
		if Title then
			info1 = Title
		end
		vPlay:PlayFile(replayList[id].name, replayList[id].stream, info1,"",replayList[id].audiostream or "")
		Epg = nil
		Title = nil
		repaint = true
		return MENU_RETURN.EXIT
	end
end

function getARDstream(id)
	local url = replayList[id].url
	local jdata = getdata(url)
	if jdata then
		local jnTab = json:decode(jdata)
		if jnTab and jnTab.diff then
			if jnTab.title and jnTab.subtitle then
				Title = jnTab.title .. ' ' .. jnTab.subtitle
			elseif jnTab.title then
				Title = jnTab.title
			end
			if jnTab.detail then
				Epg = jnTab.detail
			end
			replayList[id].stream = jnTab.streamurl .. jnTab.diff .. '/manifest.mpd'
		end
	end
end

function getLiveStream(id)
	local url = replayList[id].url
	if url and replayList[id].ch == "ard" then
		getARDstream(id)
	end
	return replayList[id].stream
end

function getReLiveList_ARD()
	local h = hintbox.new{caption="Please Wait ...", text="I'm Thinking."}
	if h then
		h:paint()
	end
	for i=1,37 do
		local link = 'http://itv.ard.de/replay/dyn/index.php?sid=' .. i
		local data = getdata(link)
		--if data then
		if data and string.sub(data,1,1) == "{" then
			local jnTab = json:decode(data)
			if jnTab and jnTab.diff then
				if jnTab.subtitle then
					_hint = jnTab.subtitle
				end
				table.insert(replayList, {name="ARD: " .. jnTab.name .. ' - ' .. jnTab.title, url=link, stream=nil, audiostream=nil, hint=_hint, hasVideo=true, ch='ard'})
			end
		end
	end
	if h then
		h:hide()
	end
end

function main_menu()
	if repaint then
		replayList = {}
		getReLiveList_ARD()
		repaint = false
	end
	if #replayList == 0 then
		return
	end
	replayMenu = menu.new{name="Replay", icon="streaming"}
	replayMenu:addItem{type="back"}
	replayMenu:addItem{type="separatorline"}
	local d =  0
	for i, v in ipairs(replayList) do
		d = d+1
		replayMenu:addItem{type="forwarder", name=v.name, action="play_live", hint=v.hint, enabled=v.hasVideo, id=i, directkey=godirectkey(d)}
	end
	replayMenu:exec()
	replayMenu:hide()
end

function main()
	init()
	repeat
		main_menu()
		collectgarbage()
	until repaint == false
end

main()
