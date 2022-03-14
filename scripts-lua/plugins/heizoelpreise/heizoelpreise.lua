--[[
	Heizölpreise Plugin lua v0.6
	Copyright (C) 2018-2022,  Jacek Jendrzej 'satbaby'

	License: GPL

	This program is free software; you can redistribute it and/or
	modify it under the terms of the GNU General Public
	License as published by the Free Software Foundation; either
	version 2 of the License, or (at your option) any later version.

	This program is distributed in the hope that it will be useful,
	but WITHOUT ANY WARRANTY; without even the implied warranty of
	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
	General Public License for more details.

	You should have received a copy of the GNU General Public
	License along with this program; if not, write to the
	Free Software Foundation, Inc., 51 Franklin St, Fifth Floor,
	Boston, MA  02110-1301, USA.
]]

local hop={}
local top={}
n = neutrino()
local FontMenu = FONT.MENU
local FontTitle = FONT.MENU_TITLE
local conf = {}

function loadConfig()
	local Nconfig	= configfile.new()
	Nconfig:loadConfig("/var/tuxbox/config/neutrino.conf")
	conf.corner_on = Nconfig:getInt32("rounded_corners", 0)
	conf.corner_large = 0
	conf.corner_top = 0
	conf.corner_bottom = 0
	conf.select = 0
	if conf.corner_on then
		 conf.corner_large = CORNER.RADIUS_LARGE
		 conf.corner_top = (CORNER.TOP_LEFT + CORNER.TOP_RIGHT)
		 conf.corner_bottom = (CORNER.BOTTOM_LEFT + CORNER.BOTTOM_RIGHT)
	end
end
-- character table string
local b='ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/'

-- decode
function dec(data)
	data = string.gsub(data, '[^'..b..'=]', '')
	return (data:gsub('.', function(x)
    	if (x == '=') then return '' end
    	local r,f='',(b:find(x)-1)
    	for i=6,1,-1 do r=r..(f%2^i-f%2^(i-1)>0 and '1' or '0') end
    	return r;
	end):gsub('%d%d%d?%d?%d?%d?%d?%d?', function(x)
    	if (#x ~= 8) then return '' end
    	local c=0
    	for i=1,8 do c=c+(x:sub(i,i)=='1' and 2^(8-i) or 0) end
    	return string.char(c)
	end))
end

function decodeImage(b64Image)
	local imgTyp = b64Image:match("data:image/(.-);base64,")
	local repData = "data:image/" .. imgTyp .. ";base64,"
	local b64Data = string.gsub(b64Image, repData, "");

	local tmpImg = os.tmpname()
	local retImg = tmpImg .. "." .. imgTyp

	local f = io.open(retImg, "w+")
	f:write(dec(b64Data))
	f:close()
	os.remove(tmpImg)

	return retImg
end


function getdata(Url,outputfile)
	if Url == nil then return nil end

	if Curl == nil then
		Curl = curl.new()
	end

	if Url:sub(1, 2) == '//' then
		Url =  'http:' .. Url
	end

	local ret, data = Curl:download{url=Url,A="Mozilla/5.0;",maxRedirs=5,followRedir=true,o=outputfile }
	if ret == CURL.OK then
		if outputfile then
			return 1
		end
		return data
	else
		return nil
	end
end

function make_tab(tab,data,patern,count)
	local k = 0
	for td in data:gmatch("<" .. patern ..".->(.-</" .. patern ..">)") do
		local aa= td:match('<div class="row">(.-)</div>%c+</' .. patern ..'>')
		if aa then
			for div in aa:gmatch("<div.->(.-)</div>") do
				local charturl = div:match'<a href="(.-)">'
				if charturl or (patern == "th" and count == 0) then 
					count = count + 1
					tab[count]={}
					k = 0
					if charturl then
						tab[count][k] = charturl
						k = k + 1
					end
				end
				local icon = div:match('<span class="icon%-(%w+)')
				if icon then tab[count].icon = icon end 
				div=div:gsub('<.->', "")
				div=div:gsub('%c+', "")
				div=div:gsub("&#150;","-")
				if div ~= nil and div and #div > 0 then 
					tab[count][k] = div
					k = k + 1
				end
			end
		end
	end
end

function gethtml(hosturl)
	local url = hosturl .. '/heizoelpreis-tendenz.htm'
	local data = getdata(url)
	if data then
		local title = data:match("<title>(.-)</title>")
		local stand = data:match("Stand: (.- %d+:%d+ Uhr)<br>")
		local tabdata = data:match("<thead>(.-)</thead>")
		make_tab(top,tabdata,"th",0)

		tabdata = data:match("</thead>%c+<tbody>(.-)</tbody>")
		for tr in tabdata:gmatch("<tr>(.-)</tr>") do
			make_tab(hop,tr,"td",#hop)
		end
		top.title = title:match("(.-),")
		top.title = top.title .. " " .. stand
	end
end

function paintFrame(x, y, w, h, c)
	local  f = 2 -- breite
	hi= h-(2*f)
	-- top
	local _x = x - SCREEN.OFF_X
	local _y = y - SCREEN.OFF_Y
	n:PaintBox(_x, _y    , w, f, c, conf.corner_large, conf.corner_top)
	-- bottom
 	n:PaintBox(_x, _y+h-f, w, f, c, conf.corner_large, conf.corner_bottom)
	-- left
  	n:PaintBox(_x  , _y+f, f, hi , c)
	-- right
 	n:PaintBox(_x+w-f, _y+f, f, hi, c)
end

function getMaxScreenWidth()
	local max_w = SCREEN.END_X - SCREEN.OFF_X
	return max_w
end

function getMaxScreenHeight()
	local max_h = SCREEN.END_Y - SCREEN.OFF_Y
	return max_h
end

function picView(hosturl,url,titletxt)
	local fpic = "/tmp/chart.png"
	local data = getdata(hosturl .. "/" .. url)
	if data then
		local urlPic = data:match('<noscript><div><img class="img%-fluid" src="(.-)"')
		if urlPic == nil then return end
		local ok = getdata(hosturl .. urlPic,fpic)
		local ww = nil
		if ok then
			local picW,picH = n:GetSize(fpic)
			ww = cwindow.new{x=0, y=0, dx=picW+20, dy=picH+20, title=titletxt, icon="info"}
			cpicture.new{parent=ww, x=10, y=0, dx=picW, dy=picH, image=fpic}
			ww:setCenterPos{3}
			ww:paint()
		end
		if ww then
			local msg, data = nil,nil
			local ok = 0
			repeat
				msg, data = n:GetInput(500)
				if msg == RC.ok then
					ok = ok + 1
				end
			until msg == RC.home or msg == RC.setup or (RC.ok and ok == 1)
			ww:hide()
		end
	end
	os.remove(fpic)
end

function start(deat)
	hop = {}
	top = {}

	local hosturl = "https://www.fastenergy." .. deat
	local flag = ""
	if deat == "at" then
		flag = decodeImage("data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAABQAAAANCAIAAAAmMtkJAAAAO0lEQVQokWO8IcfKQC5gIlsnpZpZ/n3/TbZmxjf9TeRr/v//P9maBzDA3k5oJlsz4zVRCmxm4hyKKQwAZ68L/TO9MI8AAAAASUVORK5CYII=")
	else
		flag = decodeImage("data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAABQAAAAMCAIAAADtbgqsAAAAL0lEQVQokWNgGJKAkYkSzRsp0fyIAs0svyjRzKFJvmbG/2cosJmBguCmJKYo0wwAOIMEotbwjZsAAAAASUVORK5CYII=")
	end
	gethtml(hosturl)
	conf.selectMax = #hop 
	local vSpace = n:FontHeight(FontMenu)
	local vS = math.floor((vSpace/7))
	vSpace = vSpace + math.floor(vSpace/10)+vS
	local vSHalf = math.floor(vSpace/2)
	local xStart = 40
	local yStart = vSHalf
	local _dy = (conf.selectMax+1)*vSpace+vSHalf+(n:FontHeight(FontTitle)*2)+yStart --h
	local sh = getMaxScreenHeight()
	local y =  math.floor((sh-_dy)/2) + SCREEN.OFF_Y

	local textMax = 0
	for k, v in pairs(hop) do
		local tw = n:getRenderWidth(FontMenu,v[1])
		if tw>textMax then textMax = tw end
	end
	local minusW  = n:getRenderWidth(FontMenu,"-:")
	local row = n:getRenderWidth(FontMenu,hop[1][2])
	row = math.floor(row+(row/2))
	local sw = getMaxScreenWidth()
	local _dx = (xStart*2)+textMax+(row*5)  --w
	if _dx > sw then _dx = sw end
	local x = math.floor((sw-_dx)/2) + SCREEN.OFF_X
	local land = "Deutschland"
	if deat == "de" then land = "Österreich" end
	local w = cwindow.new{x=x, y=y, dx=_dx, dy=_dy, title=top.title, icon=flag, btnRed="Heizölpreise für " .. land}
	local ct = ctext.new {parent=w, x=xStart,  y=yStart  , dx=_dx, dy=vSpace-vSHalf, text=top[1][0] , font_text=FontMenu}
	ctext.new{parent=w, x=xStart+textMax+ row, y=yStart  , dx=_dx, dy=vSpace-vSHalf, text=top[1][2] , font_text=FontMenu}
	ctext.new{parent=w, x=xStart+textMax+(row*2), y=yStart  , dx=_dx, dy=vSpace-vSHalf, text=top[1][3] , font_text=FontMenu}
	ctext.new{parent=w, x=xStart+textMax+(row*3), y=yStart  , dx=_dx, dy=vSpace-vSHalf, text=top[1][4] , font_text=FontMenu}
	ctext.new{parent=w, x=xStart+textMax+(row*4), y=yStart  , dx=_dx, dy=vSpace-vSHalf, text=top[1][5] , font_text=FontMenu}
	yStart = yStart + vSHalf
	local lineH = 0
	for k, v in pairs(hop) do
		lineH = vSpace*k
		ctext.new{parent=w, x=xStart, y=yStart+lineH  , dx=_dx, dy=vSpace-vSHalf, text=v[1], font_text=FontMenu}
		ctext.new{parent=w, x=xStart+textMax+row, y=yStart+lineH  , dx=_dx, dy=vSpace-vSHalf, text=v[2], font_text=FontMenu}
		ctext.new{parent=w, x=xStart+textMax+(row*2), y=yStart+lineH  , dx=_dx, dy=vSpace-vSHalf, text=v[3], font_text=FontMenu}
		local pm = nil
		local diff = nil
		if not v[4] then
			pm = " "
			diff = " "
		else
			pm = v[4]:match("([%+%-])")
			diff = v[4]:match("(%d+%,%d+)")
		end
		local coltext = COL.WHITE 
		if pm == "-" then coltext = COL.GREEN
		elseif pm == "+" then coltext = COL.RED end
		ctext.new{parent=w, x=xStart+textMax+(row*3), y=yStart+lineH  , dx=_dx, dy=vSpace-vSHalf, text=pm, font_text=FontMenu,color_text=coltext}
		ctext.new{parent=w, x=xStart+textMax+(row*3)+minusW, y=yStart+lineH  , dx=_dx, dy=vSpace-vSHalf, text=diff, font_text=FontMenu,color_text=coltext}
		local trend = ""
		if v.icon then trend=v.icon  end 
		cpicture.new{parent=w, x=xStart+textMax+(row*4), y=yStart+lineH+4 , dx=0, dy=0, image=trend}
	end
	w:paint()
	conf.select = 1
-------------------------------

	local Space = y+yStart+vSpace
	paintFrame(x,Space+(vSpace*conf.select)+vS,_dx,vSpace,COL.WHITE)
	n:PaintBox(x+20-SCREEN.OFF_X,Space+math.floor((vSpace/2))-SCREEN.OFF_Y, _dx-40, 1, COL.WHITE)
	local msg, data = nil,nil
	local restart = false
	repeat
		msg, data = n:GetInput(500)
		if msg == RC.down then
			paintFrame(x,Space+(vSpace*conf.select)+vS,_dx,vSpace,COL.MENUCONTENT )
			conf.select = conf.select + 1
			if conf.select > conf.selectMax then conf.select = 1 end
		elseif msg == RC.up then
			paintFrame(x,Space+(vSpace*conf.select)+vS,_dx,vSpace,COL.MENUCONTENT )
			conf.select = conf.select - 1
			if conf.select < 1 then conf.select = conf.selectMax end
		elseif msg == RC.ok then
-- 			w:hide()
			picView(hosturl,hop[conf.select][0],hop[conf.select][1])
-- 			w:paint()
		elseif msg == RC.red then
			if deat == "de" then deat = "at" else deat = "de" end
			restart = true
		end
		paintFrame(x,Space+(vSpace*conf.select)+vS,_dx,vSpace,COL.WHITE)

	until msg == RC.home or msg == RC.setup or restart
	w:hide()
	os.remove(flag)
	if restart then	start(deat) end
end

function main()
	loadConfig()
	start("de")
end

main()
