--[[
	SpiegelTV-App
	Vers.: 0.6
	Copyright (C) 2020, fritz

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

        Copyright (C) for the linked videos and for the Spiegel-Logo by SpiegelTV or the respective owners!
        Copyright (C) for the Base64 encoder/decoder function by Alex Kloss <alexthkloss@web.de>, licensed under the terms of the LGPL
]]

--Objekte
function script_path()
	local str = debug.getinfo(2, "S").source:sub(2)
	return str:match("(.*/)")
end

function init()
	n = neutrino();
	p = {}
	func = {}
	pmid = 0
	stream = 1
        tmpPath = "/tmp"
	spiegel_online = decodeImage("data:image/png;base64,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")
end

function add_stream(t,u,f,d)
  p[#p+1]={title=t,url=u,from=f,description=d,access=stream}
end

function getdata(Url,outputfile)
	if Url == nil then return nil end
	if Curl == nil then
		Curl = curl.new()
	end
	local ret, data = Curl:download{url=Url,A="40tude_Dialog/2.0.8.1de",followRedir=true,o=outputfile }

	if ret == CURL.OK then
		return data
	else
		return nil
	end
end

-- UTF8 in Umlaute wandeln
function conv_str(_string)
	if _string == nil then return _string end
        _string = string.gsub(_string,'\\n','');
        _string = string.gsub(_string,'\\','');
	_string = string.gsub(_string,"&Auml;","Ä");
	_string = string.gsub(_string,"&auml;","ä");
	_string = string.gsub(_string,"&Ouml;","Ö");
	_string = string.gsub(_string,"&ouml;","ö");
	_string = string.gsub(_string,"&Uuml;","Ü");
	_string = string.gsub(_string,"&uuml;","ü");
	_string = string.gsub(_string,"&szlig;","ß");
	_string = string.gsub(_string,"&egrave;","è");
	_string = string.gsub(_string,"&eacute;","é");
	_string = string.gsub(_string,"&amp;","&");
	_string = string.gsub(_string,"&ndash;","-");
	_string = string.gsub(_string,"&lt;","<");
	_string = string.gsub(_string,"&gt;",">");
	_string = string.gsub(_string,"&quot;","");
	_string = string.gsub(_string,"&apos;","'");
	_string = string.gsub(_string,"&#x00c4","Ä");
	_string = string.gsub(_string,"u00c4","Ä");
	_string = string.gsub(_string,"&#x00e4","ä");
	_string = string.gsub(_string,"u00e4","ä");
	_string = string.gsub(_string,"&#x00d6","Ö");
	_string = string.gsub(_string,"u00d6","Ö");
	_string = string.gsub(_string,"&#x00f6","ö");
	_string = string.gsub(_string,"u00f6","ö");
	_string = string.gsub(_string,"&#x00dc","Ü");
	_string = string.gsub(_string,"u00dc","Ü");
	_string = string.gsub(_string,"&#x00fc","ü");
	_string = string.gsub(_string,"u00fc","ü");
	_string = string.gsub(_string,"&#x00df","ß");
	_string = string.gsub(_string,"u00df","ß");
	_string = string.gsub(_string,"&#039","'");
	_string = string.gsub(_string,'&#34','"');
	_string = string.gsub(_string,"&#261","ą");
	_string = string.gsub(_string,";","");
--	_string = string.gsub(_string,"SPIEGEL TV: ","");
	_string = string.gsub(_string,'u201e','„');
	_string = string.gsub(_string,'u201c','“');
	_string = string.gsub(_string,'u00d8','ø');
	_string = string.gsub(_string,'u00a0',' ');
	_string = string.gsub(_string,'u0142','ł');
	_string = string.gsub(_string,'u00b0','°');
	_string = string.gsub(_string,'u0302','̂ ');
	_string = string.gsub(_string,'u031e','̞');
	_string = string.gsub(_string,'u0301','́');
	_string = string.gsub(_string,'u201d','́');
	_string = string.gsub(_string,'u2018','‘');
	_string = string.gsub(_string,'u2013','–');
	_string = string.gsub(_string,'u2026','…');
	_string = string.gsub(_string,'u00bf',''); -- ¿
	_string = string.gsub(_string,'u00bb','»');
	_string = string.gsub(_string,'u00ab','«');
	_string = string.gsub(_string,'u00f8','ø');
	_string = string.gsub(_string,'u2026','…');
	_string = string.gsub(_string,'u00aa','ª');
	_string = string.gsub(_string,"%s+%s+", "")
	return _string
end

-- ####################################################################
-- Base64 encoder/decoder function

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
-- ####################################################################

function fill_playlist()
	local data = getdata('https://www.spiegel.de/thema/spiegel-tv/index.rss',nil)
	if data then
		for  item in data:gmatch('<item>(.-)</item>')  do
			local title = item:match("<title>(.-)</title>") -- Sendungstitel
			local url = item:match('<link>(http.-)</link>') -- URL
			local date1 = item:match("<pubDate>.-,(.-)%+.-</pubDate>") -- Sendungsdatum
			local date = "Sendung vom:" ..date1
			local description = item:match("<description>(.-)</description>") -- Sendungsbeschreibung
			if description == nil then
				description = "Spiegel TV stellt für diese Sendung keinen Begleittext bereit."
			end
			if url and title then
				add_stream(conv_str(title), url, date, conv_str(description) )
--				add_stream(conv_str(title), url, url, conv_str(description) )-- only for testing
			end
            end
	end
end

-- epg-Fenster
local epg = ""
local title = ""

function epgInfo (xres, yres, aspectRatio, framerate)
	if #epg < 1 then return end
	local dx = 800;
	local dy = 400;
	local x = 240;
	local y = 0;

	local hw = n:getRenderWidth(FONT['MENU'],title) + 20
	if hw > 400 then
		dy = hw
	end
	if dy >  SCREEN.END_X - SCREEN.OFF_X - 20 then
		dy = SCREEN.END_X - SCREEN.OFF_X - 20
	end
	local wh = cwindow.new{x=x, y=y, dx=dx, dy=dy, title="", icon=spiegel_online, has_shadow="true", show_header="true", show_footer="false"};  -- with out footer
	dy = dy + wh:headerHeight()

	local ct = ctext.new{parent=wh, x=20, y=0, dx=0, dy=dy, text = epg, font_text=FONT['MENU'], mode = "ALIGN_SCROLL | DECODE_HTML"};
 	h = ct:getLines() * n:FontHeight(FONT['MENU'])
	h = (ct:getLines() +4) * n:FontHeight(FONT['MENU'])
	if h > SCREEN.END_Y - SCREEN.OFF_Y -20 then
		h = SCREEN.END_Y - SCREEN.OFF_Y -20
	end
 	wh:setDimensionsAll(x,y,dx,h)
        ct:setDimensionsAll(20,0,dx-40,h)
	wh:setCenterPos{3}
	wh:paint()

	repeat
		msg, data = n:GetInput(500)
		if msg == RC.up or msg == RC.page_up then
			ct:scroll{dir="up"};
		elseif msg == RC.down or msg == RC.page_down then
			ct:scroll{dir="down"};
		end
	until msg == RC.ok or msg == RC.home or msg == RC.info
	wh:hide()
end

function set_pmid(id)
  pmid=tonumber(id);
  return MENU_RETURN["EXIT_ALL"];
end

function select_playitem()
--local m=menu.new{name="SpiegelTV", icon=""} -- only text
  local m=menu.new{name="", icon=spiegel_online} -- only logo,, default

  for i,r in  ipairs(p) do
    m:addItem{type="forwarder", action="set_pmid", id=i, icon="streaming", name=r.title, hint=r.from, hint_icon="hint_reload"}
  end

  repeat
    pmid=0
    m:exec()
    if pmid==0 then
      return
    end

    local vPlay = nil
    local url=func[p[pmid].access](p[pmid].url)
    if url~=nil then
      if  vPlay  ==  nil  then
	vPlay  =  video.new()
      end

	if title == nil then
		title = p[pmid].title
	end
	local js_data = getdata(url,nil)
	local url1 = js_data:match('ediaId&.-&.-;(.-)&')

	if url1 == nil then
		print("Video URL not  found") 
	end

	local js_url = getdata('https://vcdn01.spiegel.de/v2/media/' .. url1,nil)

	local url = js_url:match('180p.-"file":"(https:.-videos.-mp4)"') 

	if url == nil then
		url = js_url:match('720p.-"file":"(https.-videos.-mp4)"') 
	end
	if url == nil then
		url = js_url:match('"file":"(https.-videos.-mp4)"') 
	end


	local description = js_url:match('"description":"(.-)"') 
	if description == nil then
		description = p[pmid].description
	end

	if url then
		epg = p[pmid].title .. "\n\n" .. conv_str(description) .. "\n\n" ..p[pmid].from
		vPlay:setInfoFunc("epgInfo")
--		vPlay:PlayFile("SpiegelTV",url,p[pmid].title,url); -- with url, only for testing
		vPlay:PlayFile("SpiegelTV",url,p[pmid].title);
	else
		print("Video URL not  found")
		local h = hintbox.new{ title="Info", text="Das Video ist nicht mehr verfügbar!", icon="info"};
	end

   end
  until false
end


--Main
init()
func={
  [stream]=function (x) return x end,
}
fill_playlist()
select_playitem()
os.execute("rm /tmp/lua*.png");
