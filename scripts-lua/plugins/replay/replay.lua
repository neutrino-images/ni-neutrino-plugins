-- version 0.1 add ard

function init()
	json = require "json"
	livelist = {}
	getReLiveList_ARD()
	n = neutrino()
	vPlay = video.new()
	nMisc = misc.new()
	repaint = false
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
	if menu ~= nil then menu:hide() end
end

local Epg = nil
local Title = nil

function epgInfo (xres, yres, aspectRatio, framerate)
	local dx = 800;
	local dy = 260;
	local x = ((SCREEN['END_X'] - SCREEN['OFF_X']) - dx) / 2;
	local y = ((SCREEN['END_Y'] - SCREEN['OFF_Y']) - dy) / 2;

	local wh = cwindow.new{x=x, y=y, dx=dx, dy=dy, icon="" , show_footer=false };
	local ct = ctext.new{parent=wh, x=0, y=0, dx=0, dy=0, text = Epg , font_text=FONT['MENU'], mode = "ALIGN_SCROLL | ALIGN_TOP"};
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
	if livelist[id].stream == nil then
		getLiveStream(id)
	end
	if livelist[id].stream then
		hideMenu(live_listen_menu)
		if Epg and Title then
			vPlay:setInfoFunc("epgInfo")
		end
		local info1 = "Replay"
		if Title then
			info1 = Title
		end
		vPlay:PlayFile(livelist[id].name, livelist[id].stream, info1,"",livelist[id].audiostream or "")
		Epg = nil
		Title = nil
		repaint = true
		return MENU_RETURN.EXIT
	end
end

function getARDstream(id)
	local url = livelist[id].url
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
			livelist[id].stream = jnTab.streamurl .. jnTab.diff .. '/manifest.mpd'
		end
	end
end

function getLiveStream(id)
	local url = livelist[id].url
	if url and livelist[id].ch == "ard" then
			getARDstream(id)
	end
	return livelist[id].stream
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
				if jnTab.subtitle then _hint = jnTab.subtitle end
				table.insert(livelist,{name="ARD: " .. jnTab.name .. ' - ' .. jnTab.title, url=link, stream=nil,audiostream=nil,hint=_hint,hasVideo=true,ch='ard'})
			end
		end
	end
	if h then
		h:hide()
	end
end

function main_menu()
	if repaint then
		livelist = {}
		getReLiveList_ARD()
		repaint = false
	end
	if #livelist == 0 then
		return
	end
	live_listen_menu  = menu.new{name="Replay", icon="streaming"}
	local menu = live_listen_menu
	menu:addItem{type="back"}
	menu:addItem{type="separatorline"}
	local d =  0
	for i, v in ipairs(livelist) do
		d=d+1
		menu:addItem{type="forwarder", name=v.name, action="play_live",hint=v.hint,enabled=v.hasVideo,id=i,directkey=godirectkey(d)}
	end
	menu:exec()
	menu:hide()
end

function main()
	init()
	repeat
		main_menu()
		collectgarbage()
	until repaint == false
end

main()
