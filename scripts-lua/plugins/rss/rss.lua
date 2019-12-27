--[[
	RSS READER Plugin
	Copyright (C) 2014-2019,  Jacek Jendrzej 'satbaby'

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

--dependencies:  feedparser http://feedparser.luaforge.net/ ,libexpat,  lua-expat 
rssReaderVersion="Lua RSS READER v0.86"
local CONF_PATH = "/var/tuxbox/config/"
local n = neutrino()
local FontMenu = FONT.MENU
local FontTitle = FONT.MENU_TITLE
local revision = 0

local glob = {}
local conf = {}
feedentries = {} --don't make
local S_Key = {fav_setup=1,fav=2,setup=3}
local addon = nil
local nothing,hva,hvb,hvc,hve,hvf="nichts",nil,nil,nil,nil,"reader"
local picdir = "/tmp/rssPics"local vPlay = nil
local epgtext = nil
local epgtitle = nil
local LinksBrowser = "/links.so"


locale = {}
locale["english"] = {
	picdir = "Picture directory: ",
	picdirhint = "In which directory should the images be saved ?",
	bindirhint = "In which directory are HTML viewer ?",
	addonsdir = "Addons directory: ",
	addonsdirhint = "In which directory are rss addons ?",
	linksbrowserdir = "Links Browser directory: ",
	linksbrowserdirhint = "In which directory are links browser ?",
	htmlviewer = "Browser selection",
	htmlviewerhint = "Browser or HTML viewer selection",
	set_key = "Select Settings Key",
	set_key_hint = "Set key for Settings",
	fav_and_setup_key = "Fav and Setup",
	fav_key = "Fav",
	setup_key = "Setup",
	curlTimeout= "Connect Timeout",
	curlTimeouthint = "Internet connect timeout (min/max) 1...99 seconds",
	maxRes = "Max. Resolution",
	maxReshint = "Max. Resolution für Youtube Video"
}
locale["deutsch"] = {
	picdir = "Bildverzeichnis: ",
	picdirhint = "In welchem Verzeichnis sollen die Bilder gespeichert werden ?",
	bindirhint = "In welchem Verzeichnis befinden sich HTML viewer ?",
	addonsdir = "Addons Verzeichnis: ",
	addonsdirhint = "In welchem Verzeichnis befinden sich rss addons ?",
	linksbrowserdir = "Links Browser Verzeichnis: ",
	linksbrowserdirhint = "In welchem Verzeichnis befindet sich Links Browser ?",
	htmlviewer = "Browser Auswahl",
	htmlviewerhint = "Browser oder HTML viewer Auswahl",
	set_key = "Einstellungen Taste",
	set_key_hint = "Taste für Einstellungen",
	fav_and_setup_key = "Fav und Setup",
	fav_key = "Fav",
	setup_key ="Setup",
	curlTimeout="Zeitüberschreitung der Internetverbindung nach",
	curlTimeouthint="Zeitüberschreitung der Internetverbindung (min/max) 1...99 sekunden",
	maxRes = "Max. Auflösung",
	maxReshint = "Max. Auflösung für Youtube Video"
}
locale["polski"] = {
	picdir = "katalog zdjęć: ",
	picdirhint = "W którym folderze obrazy mają być zapisane ?",
	bindirhint = "W którym folderze znajduje się przeglądarka HTML?",
	addonsdir = "Addons folder: ",
	addonsdirhint = "W którym folderze znajdują się rss addons ?",
	linksbrowserdir = "Links Browser folder: ",
	linksbrowserdirhint = "W którym folderze znajduje się Links Browser ?",
	htmlviewer = "Browser wybór",
	htmlviewerhint = "Browser albo HTML viewer wybór",
	set_key = "Wybierz Klawisz dla ustawień",
	set_key_hint = "Wybór klawisza dla tego menu",
	fav_and_setup_key = "Fav i Setup",
	fav_key = "Fav",
	setup_key ="Setup",
	curlTimeout="Limit czasu połączenia z Internetem",
	curlTimeouthint="Limit czasu połączenia z Internetem (min/max) 1...99 sekund",
	maxRes = "Max. rozdzielczość",
	maxReshint = "Maksymalna rozdzielczość dla Youtube Video"
}

function get_confFile()
	return CONF_PATH .. "rss.conf"
end

function __LINE__() return debug.getinfo(2, 'l').currentline end


function pop(cmd)
       local f = assert(io.popen(cmd, 'r'))
       local s = assert(f:read('*a'))
       f:close()
       return s
end

function getdata(Url,outputfile)
	if Url == nil then return nil end
	if Curl == nil then
		Curl = curl.new()
	end

	if Url:sub(1, 2) == '//' then
		Url =  'http:' .. Url
	end
	if 1 > conf.ctimeout then conf.ctimeout=1 end

	local ret, data = Curl:download{url=Url,A="Mozilla/5.0;",connectTimeout=conf.ctimeout,maxRedirs=5,followRedir=true,o=outputfile }
	if ret == CURL.OK then
		if outputfile then
			return 1
		end
		return data
	else
		return nil
	end
end

function getFeedDataFromUrl(url)
	local h = hintbox.new{caption="Please Wait ...", text="I'm Thinking."}
	if h then
		h:paint()
	end
	local data = getdata(url)
	if h then
		h:hide()
	end
	if data then
--		fix for >>> couldn't parse xml. lxp says: junk after document element 
		local nB, nE = data:find("</rss>")
		if nE and #data > nE then
			data = string.sub(data,0,nE)
		end
	else
		return nil
	end

	local error = nil
	local feedparser = require "feedparser"
	fp,error = feedparser.parse(data)
	if error then
		print("DEBUG ".. __LINE__())
		print(data) --  DEBUG
		print ("ERROR >> ".. error .. "\n###")
		local window,x,y,w,h = showWindow("DEBUG Output", data)
		window:hide()
		window = nil
	end
	data = nil
	return fp
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

function check_if_double(tab,name)
	for index,value in ipairs(tab) do
		if value == name then
			return false
		end
	end
	return true
end

function info(infotxt,cap)
	if cap == nil then
		cap = "Information"
	end
	local h = hintbox.new{caption=cap, text=infotxt}
	if h then
		h:paint()
		get_input()
		h:hide()
	end
	h = nil
end

function get_input(ct,bRed,bGreen,bYellow,bBlue)
	local stop = false
	local ret = nil
	local msg, data = nil,nil
	repeat
		msg, data = n:GetInput(500)

		if ct and (msg == RC.up or msg == RC.page_up) then
			ct:scroll{dir="up"}
		elseif ct and (msg == RC.down or msg == RC.page_down) then
			ct:scroll{dir="down"}
		elseif bRed and msg == RC.red then
			stop = true
		elseif bGreen and msg == RC.green then
			stop = true
		elseif bYellow and msg == RC.yellow then
			stop = true
		elseif bBlue and msg == RC.blue then
			stop = true
		elseif msg == RC.left then
			stop = true
		elseif msg == RC.right then
			stop = true
		end
	until msg == RC.home or msg == RC.setup or stop
	if stop then
		ret = msg
	end
	return ret
end

function tounicode(c)
	if c > 8200 then
		return " "
	end

	if c > 383 then
		c=c-256
		return "\xC6" .. string.format('%c', c)
	elseif c > 319 then
		c=c-192
		return "\xC5" .. string.format('%c', c)
	elseif c > 254 then
		c=c-128
		return "\xC4" .. string.format('%c', c)
	elseif c > 191 then
		c=c-64
		return "\xC3" .. string.format('%c', c)
	else
		return string.format('%c', c)
	end
end

function convHTMLentities(summary)
	if summary ~= nil then
		summary = summary:gsub("&#([0-9]+);",function(c) return tounicode(tonumber(c)) end)
		summary = summary:gsub("&#x([%x]+);",function(c) return tounicode(tonumber(c, 16)) end)
	end
	return summary
end

--------------------------- new
function removeElemetsbyTagName(document,ename)
	local t = document:getElementsByTagName(ename)

	for i, element in ipairs(t) do
		element:remove()
	end

end

function removeElemetsbyTagName2(document,tagName,atrName)
	local t = document:getElementsByTagName(tagName)
	for i, element in ipairs(t) do
		local el = element:getAttribute(atrName)
		if el then
			element:remove()
		end
	end
end

function all_trim(s)
	if s == nil then return "" end
	return s:match("^%s*(.-)%s*$")
end

function xml_entities(s)
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

function prepare_text(text)
	if text == nil then return nil end
	if #text < 1 then
		return text
	end
	text = text:gsub('<.->', "") -- remove  "<" alles zwischen ">"
	text = text:gsub("\240[\144-\191][\128-\191][\128-\191]","")
	text = convHTMLentities(text)
	text = text:gsub("%s+\n", " \n")
	text = all_trim(text)
	text = xml_entities(text)
	return text
end

function getMaxScreenWidth()
	local max_w = SCREEN.END_X - SCREEN.OFF_X
	return max_w
end

function getMaxScreenHeight()
	local max_h = SCREEN.END_Y - SCREEN.OFF_Y
	return max_h
end

function getSafeScreenSize(x,y,w,h)
	local maxW = getMaxScreenWidth()
	local maxH = getMaxScreenHeight()
	if w > maxW or w < 1 then
		w = maxW
	end
	if h > maxH or h < 1 then
		if h > maxH then
			w = maxW
		end
		h = maxH
	end
	if x < 0 or x+w > maxW then
		x = 0
	end
	if y < 0 or y+h > maxH then
		y = 0
	end
	return x,y,w,h
end

function paintPic(window,fpic,x,y,w,h)
	local cp = cpicture.new{parent=window, x=x, y=y, dx=w, dy=h, image=fpic}
	if window == nil then
		cp:paint()
	end
end

function paintText(x,y,w,h,picW,picH,CPos,text,window) --ALIGN_AUTO_WIDTH
	if x == 0 then
		x = 20
	end
	local pW,pH = 0,0
	local ct = ctext.new{parent=window,x=x, y=y, dx=w, dy=h, text=text, mode = "ALIGN_SCROLL | DECODE_HTML", font_text=Font}
	if window == nil then
		ct:paint()
	else
		local ctLines = ct:getLines()
		h = ctLines * n:FontHeight(FontMenu)
		h = h + window:headerHeight() + window:footerHeight()  + window:headerHeight()/2
		h = math.floor(h)
		if ctLines < 6 then
			text = text:gsub("\n"," ")
			ct:setText{text=text}
			pW = 0
			pH = picH
			h = h + picH
		else
			w = w + picW + 4
			pH = 0
			pW = picW + 4
			h = h + window:footerHeight()
		end
		x,y,w,h = getSafeScreenSize(x,y,w,h)
		ct:setDimensionsAll(x+pW,y+pH,w,h)
		window:setDimensionsAll(x,y,w,h)
		if CPos and CPos > 0 and CPos < 4 then
			window:setCenterPos{CPos}
		end
		if ctLines > 5 and picH < h - window:headerHeight() - window:footerHeight()  then
			y = y + (h - window:headerHeight() - window:footerHeight()- picH)/2
			y = math.floor(y)
		end
	end
	return ct,x,y,w,h
end

function paintWindow(x,y,w,h,CPos,Title,Icon,RedBtn,GreBtn,YelBtn,BluBtn)
	local defaultW = math.floor(getMaxScreenWidth()- getMaxScreenWidth()/3)
	local defaultH = n:FontHeight(FontMenu)
	if w < 1 then
		w = defaultW
	end
	if h < 1 then
		h = defaultH
	end
	local window = cwindow.new{x=x, y=y, dx=w, dy=h, title=Title, icon=Icon,
		btnRed=RedBtn, btnGreen=GreBtn,btnYellow=YelBtn,btnBlue=BluBtn}
	h = h + window:footerHeight() + window:headerHeight()
	if Title and #Title > 1 then
		w = n:getRenderWidth(FontTitle,Title .. "wW")
		w = w + window:headerHeight() + 10 --icon
		if w < defaultW then
			w = defaultW
		end
		if w > getMaxScreenWidth()  then
			w = getMaxScreenWidth()
		end
	end
	x,y,w,h = getSafeScreenSize(x,y,w,h)
	window:setDimensionsAll(x,y,w,h)
	if CPos and CPos > 0 and CPos < 4 then
		window:setCenterPos{CPos}
	end
-- 		window:setCaption{title=Title, alignment=TEXT_ALIGNMENT.CENTER}

	return window,x,y,w,h
end

function showWindow(title,text,fpic,icon,bRed,bGreen,bYellow,bBlue)
	local x,y,w,h = 0,0,0,0
	local picW,picH = 0,0
	local maxW = getMaxScreenWidth()
	local maxH = getMaxScreenHeight()
	text = prepare_text(text)
	if fpic then
		picW,picH = n:GetSize(fpic)
		if picW and picW > 0 and picH and picH > 0 then
			local maxPicSizeW,maxPicSizeH = math.floor(maxW/4),math.floor(maxH/2)
			if #text < 100 then
				if #text < 10 then
					maxPicSizeH = maxH
				else
					maxPicSizeH = maxH-(5*n:FontHeight(FontMenu))
				end
				maxPicSizeW = maxW
			end
			if picH > maxPicSizeH or picW > maxW then
				picW,picH = rescalePic(picW,picH,maxPicSizeW,maxPicSizeH)
			end
			if picH < 150 and picW < 150 then
				picW,picH = rescalePic(picW,picH,picH*2,picW*2)
			end

			h = picH
		end
	end

	local wPosition = 3
	local cw,x,y,w,h = paintWindow(x,y,w,h,-1,title,icon,bRed,bGreen,bYellow,bBlue)

	local ct,x,y,w,h = paintText(x,y,w,h,picW,picH,wPosition,text,cw)
	if fpic and picW > 1 and picH > 1 then
		if x > 15 then
			x = x-10
		end
		local cp = paintPic(cw,fpic,x,y,picW,picH)
	end

	cw:paint()
	local selected =  get_input(ct,bRed,bGreen,bYellow,bBlue)
	return cw , selected
end

function show_textWindow(tit_txt, txt)
	glob.m:hide()
	if txt == nil then return end
	if txt and #txt < 1 then
		return
	end
	txt = prepare_text(txt)
	local window,x,y,w,h = showWindow(tit_txt, txt)
	window:hide()
	window = nil
end

function epgInfo(xres, yres, aspectRatio, framerate)
	local window,x,y,w,h = showWindow(epgtitle, epgtext)
	window:hide()
	window = nil
end
function checkdomain(feed,url)
	if not url then return url end
	local a,b=url:find("src=.http:")
	if a and b then
		url=url:sub(b-4,#url)
	end
	if not url:find("//") then
		local domain = nil
		if fp.feed.link then
			domain = fp.feed.link:match('^(%w+://[^/]+)')
		end
		if domain then
			url =  domain .. "/" .. url
		end
	end
	return url
end

function getMediUrls(idNr)
	local UrlVideo,UrlAudio, UrlExtra = nil,nil,nil
	local picUrl =  {}
	local feed = fp.entries[idNr]
	for i, link in ipairs(feed.enclosures) do
		local urlType =link.type
		local mediaUrlFound = false
		if link.url and urlType == "image/jpeg" then
			picUrl[#picUrl+1] =  link.url
			mediaUrlFound = true
		end
		if urlType == 'video/mp4' or  urlType == 'video/mpeg' or
		   urlType == 'video/x-m4v' or  urlType == 'video/quicktime' then
			UrlVideo =  link.url
			mediaUrlFound = true
		end
		if revision == 1 and urlType == 'video/webm' then
			UrlVideo =  link.url
			mediaUrlFound = true
		end
		if urlType == 'audio/mp3' or urlType == 'audio/mpeg' then
			UrlAudio =  link.url
			mediaUrlFound = true
		end

		if mediaUrlFound == false and link.url then
			local purl = link.url:match ('(http.-%.[JjGgPp][PpIiNn][Ee]?[GgFf])')
				if purl and #purl>4 then
					purl = checkdomain(feed,url)
					if purl ~= picUrl[#picUrl] then
						picUrl[#picUrl+1] =  purl
					end
				end
		end
	end
	if not UrlVideo and feed.summary then
		UrlVideo = feed.summary:match('<source%s+src%s?=%s?"(.-)"%s+type="video/mp4">')
	end
	if #picUrl == 0 then
		local urls = {feed.summary, feed.content}
		for i,v in ipairs(urls) do
			if type(v) == "string" then
				v=v:gsub('src=""','')
				v=v:gsub("src=''",'')
				for url in v:gmatch ('[%-%s]?src%s?=%s?[%"\']?(.-%.[JjGgPp][PpIiNn][Ee]?[GgFf])[%"\'%s%?]') do
					if url and #url > 4 then
						local a,b = url:find("http[%w%p]+$")
						if a and b then
							local tmpurl = url:sub(a,b)
							if tmpurl then
								url = tmpurl
							end
						end
						url = checkdomain(feed,url)
						if url ~= picUrl[#picUrl] then
							if check_if_double(picUrl,url) then
								picUrl[#picUrl+1] =  url
							end
						end
					end
				end
				for url in v:gmatch ('[%-%s]?<a href%s?=%s?[%"\']?(.-%.[JjGgPp][PpIiNn][Ee]?[GgFf])[%"\'%s%?]') do
					if url and #url > 4 then
						local a,b = url:find("http[%w%p]+$")
						if a and b then
							local tmpurl = url:sub(a,b)
							if tmpurl then
								url = tmpurl
							end
						end
						url = checkdomain(feed,url)
						if url ~= picUrl[#picUrl] then
							if check_if_double(picUrl,url) then
								picUrl[#picUrl+1] =  url
							end
						end
					end
				end

				if UrlExtra == nil then
					UrlExtra  = v:match('%w+://[%w+%p]+%.json')
				end
			end
		end
	end
	if not UrlVideo and not UrlAudio and not UrlExtra and fp.entries[idNr].link:find("www.youtube.com")then
		UrlExtra = fp.entries[idNr].link
	end
	glob.urlPicUrls = picUrl

	return UrlVideo , UrlAudio , UrlExtra
end

function html2text(viewer,text)
	if text == nil then return nil end
	local tmp_filename = os.tmpname()
	local fileout = io.open(tmp_filename, 'w+')
	if fileout then
		text = text:gsub("<[sS][cC][rR][iI][pP][tT][^%w%-].-</[sS][cC][rR][iI][pP][tT]%s*>", "")
		fileout:write(text .. "\n")
		fileout:close()
		collectgarbage()
	end
	local cmd = viewer .. " " .. tmp_filename
	text = pop(cmd)
	os.remove(tmp_filename)
	return text
end

function htmlreader(text)
	local text_tmp = text:match("<body.->(.-)</body>")
	local error = "RSS HTML READER ERROR\n"
	if text == nil then return error .. text end
	text = text_tmp
	local patterns = {
	{'<!%-%-.-%-%->',""},
	{'<title>.-</title>',""},
	{'<picture>.-</picture>',""},
	{'<li>.-</li>',""},
	{'<style.-</style>',""},
	{'<header.-</header>',""},
	{'<script.-</script>',""},
	{'<section.-</section>',""},
	{'<span.-</span>',""},
	{'<li.-</li>',""},
	{'<strong.-</strong>',""},
	{'<a href .->',""},
	{'<img .->',""},
	{'<h2.-</h2>',""},
	{'<h4.-</h4>',""},
	{'<.->', ""},
	{'%-%->', ""},
	{'[ ]+\n', ""},
	{'\n[ ]+', "",20},
	{'[\r]+', "\n"},
	{'^\n*', ""},
	{'[\n]+', "\n"},
	{'\n*$', ""},
	}
	for _,v in ipairs(patterns) do
		text = text:gsub( v[1], v[2],v[3] )
	end
	return text
end

function checkHaveViewer()
	if hva == conf.htmlviewer then
		return true
	elseif hvb == conf.htmlviewer then
		return true
	elseif hvc == conf.htmlviewer then
		return true
	elseif hve == conf.htmlviewer then
		return true
	elseif hvf == conf.htmlviewer then
		return true
	elseif nothing == conf.htmlviewer then
		return false
	end
		return false
end

function showWithHtmlViewer(data)
	local txt = nil
	local viewer = nil
	if hve == conf.htmlviewer then
		viewer = conf.linksbrowserdir .. LinksBrowser .. " -dump"
		txt=html2text(viewer,data)
	elseif hvb == conf.htmlviewer then
		viewer= conf.bindir .. "/html2text -nobs -utf8"
		txt=html2text(viewer,data)
	elseif hvc == conf.htmlviewer then
		viewer= conf.bindir .. "/w3m -dump"
		txt=html2text(viewer,data)
	elseif hvf == conf.htmlviewer then
		txt = htmlreader(data)
	elseif nothing == conf.htmlviewer then
		return nil
	end
	return txt
end

-----------------------------------------------
function showMenuItem(id)
	local nr = tonumber(id)
	local stop = false
	local selected = paintMenuItem(nr)
	repeat
		if selected == RC.left then
			if nr > 1 then
				nr=nr-1
			else
				nr = #glob.feedpersed.entries
			end
			selected = paintMenuItem(nr)
		elseif selected == RC.right then
			if nr < #glob.feedpersed.entries then
				nr=nr+1
			else
				nr = 1
			end
			selected = paintMenuItem(nr)
		elseif selected == RC.red or selected == RC.green or selected == RC.yellow or selected == RC.blue or selected then
			selected = paintMenuItem(nr)
		else
			stop = true
		end
	until stop

end
local tmpUrlLink,tmpUrlVideo,tmpUrlAudio,tmpUrlExtra,tmpUrlVideoAudio,tmpText = nil,nil,nil,nil,nil,nil
function paintMenuItem(idNr)
	glob.m:hide()
	local title    = fp.entries[idNr].title
	if title then
		title = title:gsub("\n", " ")
	end
	local text    = fp.entries[idNr].summary
	local UrlLink = fp.entries[idNr].link
	local UrlVideo,UrlAudio,UrlExtra,UrlVideoAudio = nil,nil,nil,nil
	local cal = false
	if UrlLink ~= tmpUrlLink then
		glob.urlPicUrls  = {}
		tmpUrlLink,tmpUrlVideo,tmpUrlAudio,tmpUrlExtra,tmpUrlVideoAudio,tmpText = nil,nil,nil,nil,nil,nil
		UrlVideo,UrlAudio,UrlExtra = getMediUrls(idNr)
		cal = true
	else
		UrlVideo,UrlAudio,UrlExtra,UrlVideoAudio,text = tmpUrlVideo,tmpUrlAudio,tmpUrlExtra,tmpUrlVideoAudio,tmpText
	end
	local fpic = nil
	if cal and addon and UrlLink then
		local hasaddon,a = pcall(require,addon)
		if hasaddon then
			a.VideoUrl = nil
			a.UrlVideoAudio = nil
			a.AudioUrl = nil
			a.getAddonMedia(UrlLink,UrlExtra)
			if a.VideoUrl then
				UrlVideo = a.VideoUrl
				a.VideoUrl = nil
			end
			if a.UrlVideoAudio then
				UrlVideoAudio = a.UrlVideoAudio
				a.UrlVideoAudio = nil
			end
			if a.AudioUrl then
				UrlAudio = a.AudioUrl
				a.AudioUrl = nil
			end
			if a.PicUrl then
				if type(a.PicUrl) == 'table' then
					for i=1,#a.PicUrl do
						if check_if_double(glob.urlPicUrls,a.PicUrl[i]) then
							glob.urlPicUrls[#glob.urlPicUrls+1] = a.PicUrl[i]
						end
					end
				else
					if check_if_double(glob.urlPicUrls,a.PicUrl) then
						glob.urlPicUrls[#glob.urlPicUrls+1] = a.PicUrl
					end
				end
				a.PicUrl = nil
			end
			if a.addText then
				if text == nil then
					text=""
				end
				text = text .. a.addText
				a.addText = nil
			end
			if a.newText then
				text = a.newText
				a.newText = nil
			end
		else
			local errMsg = ".lua not found in directory: " .. conf.addonsdir
			info( addon .. errMsg ,"ADDON: Error")
		end
	end
	if UrlLink then tmpUrlLink,tmpUrlVideo,tmpUrlAudio,tmpUrlExtra,tmpUrlVideoAudio,tmpText = UrlLink,UrlVideo,UrlAudio,UrlExtra,UrlVideoAudio,text end
	if  not vPlay  and (UrlVideo or UrlAudio) then
		vPlay  =  video.new()
	end
	if  vPlay and text and #text > 1 then
		vPlay:setInfoFunc("epgInfo")
		epgtext = text
		epgtitle = title
	end
	if UrlVideo == UrlLink then
		UrlLink = nil
	end
	if UrlAudio == UrlLink then
		UrlLink = nil
	end
	if UrlLink and UrlLink:sub(1, 4) ~= 'http' then
		UrlLink = nil
	end
	if glob.urlPicUrls and #glob.urlPicUrls > 0 then
		fpic=downloadPic(idNr,1)
	end

	if text == nil and fp.entries[idNr].content then
		text = fp.entries[idNr].content
	end
	if UrlVideo and UrlVideo:sub(1, 2) == '//' then
		UrlVideo =  'http:' .. UrlVideo
	end
	if UrlAudio and UrlAudio:sub(1, 2) == '//' then
		UrlAudio =  'http:' .. UrlAudio
	end

	if text == nil then
		if vPlay and UrlVideo then
if APIVERSION ~= nil and (APIVERSION.MAJOR > 1 or ( APIVERSION.MAJOR == 1 and APIVERSION.MINOR > 82 )) then
		vPlay:PlayFile(title,UrlVideo,UrlVideo,"",UrlVideoAudio or "")
else
		vPlay:PlayFile(title,UrlVideo,UrlVideo)
end
		elseif vPlay and UrlAudio then
			vPlay:PlayFile(title,UrlAudio,UrlAudio)
-- 			vPlay:PlayAudioFile(UrlAudio)
		end
		collectgarbage()
		return
	end

	local bRed,bGreen,bYellow,bBlue =  nil,nil,nil,nil
	if UrlVideo then bRed = "Play Video" end
	if UrlLink and checkHaveViewer() then bGreen = "Read Seite" end
	if glob.urlPicUrls and #glob.urlPicUrls > 0 then
		bYellow = "Show Pic"
		if #glob.urlPicUrls > 1 then
			bYellow = bYellow .. "s"
		end
	end
	if UrlAudio then bBlue = "Play Audio" end
	local cw,selected =  showWindow(title,text,fpic,"hint_info",bRed,bGreen,bYellow,bBlue)
	cw:hide()
	cw = nil

	if selected == RC.red and vPlay and UrlVideo then
if APIVERSION ~= nil and (APIVERSION.MAJOR > 1 or ( APIVERSION.MAJOR == 1 and APIVERSION.MINOR > 82 )) then
		vPlay:PlayFile(title,UrlVideo,UrlVideo,"",UrlVideoAudio or "")
else
		vPlay:PlayFile(title,UrlVideo,UrlVideo)
end
	elseif checkHaveViewer() and selected == RC.green and UrlLink then
	if hva == conf.htmlviewer and UrlLink then
		os.execute(conf.linksbrowserdir .. LinksBrowser .. " -g " .. UrlLink)
	else
		local data = getdata(UrlLink)
		if data then
			local txt = showWithHtmlViewer(data)
			data = nil
			if txt then
				show_textWindow(title,txt)
			end
		end
	end

	elseif selected == RC.yellow and  bYellow then
		picviewer(idNr,1)
	elseif selected == RC.blue and UrlAudio and vPlay then
		vPlay:PlayFile(title,UrlAudio,UrlAudio)
-- 		vPlay:PlayAudioFile(UrlAudio)
	end
	epgtext = nil
	epgtitle = nil
	if glob.urlPicUrls and #glob.urlPicUrls > 0 and conf.picdir == picdir then
		local fh = filehelpers.new()
		if fh then
			fh:rmdir(picdir)
			fh:mkdir(picdir)
		end
		fh = nil
	end
	collectgarbage()
	return selected
end

function downloadPic(idNr,nr)
	local fpic = nil
	if not glob.urlPicUrls[nr] then return nil end
	local picname = string.find(glob.urlPicUrls[nr], "/[^/]*$")
	if picname then
		picname = string.sub(glob.urlPicUrls[nr],picname+1,#glob.urlPicUrls[nr])
		local t = nil
		if fp.entries[idNr].updated_parsed then
		      t = os.date("%d%m%H%M%S_",fp.entries[idNr].updated_parsed)
		end
		local id2 = nil
		if t then
			id2 = t
		else
			id2 = idNr
		end
		fpic = conf.picdir .. "/" .. id2 .. picname
		local fh = filehelpers.new()
		if fh:exist(fpic, "f") == false then
			if nr > 1 then
				n:PaintIcon("icon_red", 20 + SCREEN.OFF_X, 40 + SCREEN.OFF_Y, 30,30)
			end
			local UrlPic = glob.urlPicUrls[nr]
			local ok = getdata(UrlPic,fpic)
			if not ok then
				fpic = nil
			end
		end
		fh = nil
	end
	return fpic
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

function picviewer(id,nr)
	if #glob.urlPicUrls > 0 and nr > 0 then
		local V = nil
		local msg, data = nil,nil
		local lastnr = 0
		repeat
			msg, data = n:GetInput(500)

			if msg == RC.left then
				if nr > 1 then
					nr=nr-1
				else
					nr = #glob.urlPicUrls
				end
			elseif msg == RC.right then
				if nr < #glob.urlPicUrls then
					nr=nr+1
				else
					nr = 1
				end
			end
			if lastnr ~= nr then
				lastnr = nr
				local image = downloadPic(id,nr)
				if image then
					local picW,picH = n:GetSize(image)
					if picW and picW > 0 and picH and picH > 0 then
						if picH < 250 and picW < 250 then
							picW,picH = rescalePic(picW,picH,picH*2,picW*2)
						else
							picW,picH = rescalePic(picW,picH)
						end
						local y,x=0,0
						if getMaxScreenHeight() > picH then
							y = (getMaxScreenHeight()-picH)/2
							y = math.floor(y)
						end
						if getMaxScreenWidth() > picW then
							x = (getMaxScreenWidth()-picW)/2
							x = math.floor(x)
						end
						n:PaintBox(0,0,-1,-1,COL.BLACK )
						n:DisplayImage(image,x + SCREEN.OFF_X,y + SCREEN.OFF_Y,picW,picH)
					end
					if #glob.urlPicUrls > 1 then
						local str = nr .. "/" .. #glob.urlPicUrls
						n:RenderString(FontMenu, str, 20 + SCREEN.OFF_X , 40 + SCREEN.OFF_Y, COL.RED)
					end
				end
			end
		until msg == RC.home or msg == RC.setup or stop
		n:PaintBox(-1,-1,-1,-1,COL.BACKGROUND)
	end
end
-----------------------------------------------------------------------------
function home()
	return MENU_RETURN.EXIT
end
function saveConfig()
	if conf.changed then
		local config	= configfile.new()
		if config then
			config:setString("picdir", conf.picdir)
			config:setString("bindir", conf.bindir)
			config:setString("addonsdir", conf.addonsdir)
			config:setString("htmlviewer", conf.htmlviewer)
			config:setString("maxRes", conf.maxRes)
			config:setInt32("set_key", conf.set_key)
			config:setInt32("ctimeout", conf.ctimeout)
			config:setString("linksbrowserdir", conf.linksbrowserdir)
			config:saveConfig(get_confFile())
			config = nil
		end
		conf.changed = false
	end
end
function checkhtmlviewer()
	local fh = filehelpers.new()
	if fh:exist(conf.linksbrowserdir .. LinksBrowser, "f") == true then
		hva="links browser"
		hve="links viewer"
	end
	if fh:exist(conf.bindir .. "/" .. "html2text", "f") == true then
		hvb="html2text"
	end
	if fh:exist(conf.bindir .. "/" .. "w3m" , "f") == true then
		hvc="w3m"
	end
end

function loadConfig()
	local config	= configfile.new()
	if config then
		config:loadConfig(get_confFile())
		conf.picdir = config:getString("picdir", "/tmp/rssPics")
		conf.bindir = config:getString("bindir", "/bin")
		conf.addonsdir = config:getString("addonsdir", "/share/tuxbox/neutrino/plugins/rss_addon/")
		conf.linksbrowserdir = config:getString("linksbrowserdir", "/share/tuxbox/neutrino/plugins/")
		conf.htmlviewer = config:getString("htmlviewer", "nichts")
		conf.maxRes = config:getString("maxRes", "1280x720")
		conf.set_key = config:getInt32("set_key", 1)
		conf.ctimeout = config:getInt32("ctimeout", 5)
		config = nil
	end

	local Nconfig	= configfile.new()
	Nconfig:loadConfig(CONF_PATH .. "neutrino.conf")
	conf.lang = Nconfig:getString("language", "english")
	LOC = locale[conf.lang]
	if LOC == nil then
		LOC = locale["english"]
	end
	conf.changed = false
	checkhtmlviewer()
end

function set_action(id,value)
	if id == "ctimeout" then
		value = tonumber(value)
	end

	if id == 'set_key' then
		if LOC.fav_and_setup_key == value then
			conf.set_key = S_Key.fav_setup
		elseif LOC.fav_key == value then
			conf.set_key = S_Key.fav
		elseif LOC.setup_key == value then
			conf.set_key = S_Key.setup
		end
		return
	end
	conf.changed = true
	conf[id]=value

	if id == "maxRes" then
		saveConfig()
		tmpUrlLink,tmpUrlVideo,tmpUrlAudio,tmpUrlExtra,tmpUrlVideoAudio,tmpText = nil,nil,nil,nil,nil,nil
	end
	if id == 'addonsdir' then
		package.path = package.path .. ';' .. conf.addonsdir .. '/?.lua'
	end
	if id == 'linksbrowserdir' or id == 'bindir' then
		checkhtmlviewer()
	end
end
function settings(id,a)
	glob.sm:hide()

	local d =  1
	local menu =  menu.new{name="Einstellungen", icon="icon_blue"}
	glob.settings_menu = menu
	menu:addItem{type="back"}
	menu:addItem{type="separatorline"}
	menu:addItem{ type="filebrowser", dir_mode="1", id="picdir", name= LOC.picdir, action="set_action",
		   enabled=true,value=conf.picdir,directkey=godirectkey(d),
		   hint_icon="hint_service",hint= LOC.picdirhint
		 }
	d=d+1
	menu:addItem{ type="filebrowser", dir_mode="1", id="bindir", name="HtmlViewer: ", action="set_action",
		   enabled=true,value=conf.bindir,directkey=godirectkey(d),
		   hint_icon="hint_service",hint=LOC.bindirhint .. "(html2text,w3m,links)"
		 }
	d=d+1
	menu:addItem{ type="filebrowser", dir_mode="1", id="addonsdir", name=LOC.addonsdir, action="set_action",
		   enabled=true,value=conf.addonsdir,directkey=godirectkey(d),
		   hint_icon="hint_service",hint=LOC.addonsdirhint
		 }
	d=d+1
	menu:addItem{ type="filebrowser", dir_mode="1", id="linksbrowserdir", name=LOC.linksbrowserdir, action="set_action",
		   enabled=true,value=conf.linksbrowserdir,directkey=godirectkey(d),
		   hint_icon="hint_service",hint=LOC.linksbrowserdirhint
		}
	d=d+1
	menu:addItem{type="chooser", action="set_action", options={ nothing,hva,hvb,hvc,hve,hvf }, id="htmlviewer", value=conf.htmlviewer, name=LOC.htmlviewer ,directkey=godirectkey(d),hint_icon="hint_service",hint=LOC.htmlviewerhint}

	d=d+1
	local set_key_opt={ LOC.fav_and_setup_key,LOC.fav_key,LOC.setup_key }
	menu:addItem{type="chooser", action="set_action", options=set_key_opt, id="set_key", value=set_key_opt[conf.set_key], name=LOC.set_key ,directkey=godirectkey(d),hint_icon="hint_service",hint=LOC.set_key_hint}

	d=d+1
	menu:addItem{type="stringinput", action="set_action", id="ctimeout", name=LOC.curlTimeout, value=conf.ctimeout, valid_chars="0123456789",size=2,hint_icon="hint_service",hint=LOC.curlTimeouthint}

	d=d+1
	local res_opt={ '3840x2160','2560x1440','1920x1080','1280x720','854x480','640x360' }
	menu:addItem{type="chooser", action="set_action", options=res_opt, id="maxRes", value=conf.maxRes, name=LOC.maxRes ,directkey=godirectkey(d),hint_icon="hint_service",hint=LOC.maxReshint}

	menu:exec()
	menu:hide()
	menu = nil
	return MENU_RETURN.EXIT_REPAINT
end
----
function rssurlmenu(url)
	glob.feedpersed = getFeedDataFromUrl(url)
	if glob.feedpersed == nil then return end
	local d = 0 -- directkey
	local m = menu.new{name=glob.feedpersed.feed.title, icon="icon_blue"}
	glob.m=m
	m:addKey{directkey=RC.home, id="home", action="home"}
	m:addKey{directkey=RC.info, id="FEED Version: " .. fp.version, action="info"}
	m:addItem{type="back"}
	m:addItem{type="separator"}

	for i = 1, #glob.feedpersed.entries do
		d = d + 1
		local dkey = godirectkey(d)
		local title =""
		if fp.entries[i].updated_parsed then
		      title = os.date("%d.%m %H:%M",fp.entries[i].updated_parsed)
		end
		if glob.feedpersed.entries[i].title then
			title = title .. " "..glob.feedpersed.entries[i].title:gsub("\n", " ")
			title = xml_entities(title)
			title = convHTMLentities(title)
			title = title:gsub("</i>", " ")
			title = title:gsub("<i>", " ")
		else
			title = title .. " "
		end
		m:addItem{type="forwarder", name=title, action="showMenuItem", id=i, directkey=dkey }
	end
	m:exec()
	glob.feedpersed = nil
	collectgarbage()
end

function exec_url(id)
	glob.sm:hide()
	execUrl(id)
end

function exec_url2(id)
	glob.grupm:hide()
	execUrl(id)
end

function exec_urlsub(id)
	glob.subm:hide()
	execUrl(id)
end

function execUrl(id)
	local nr = tonumber(id)
	addon = feedentries[nr].addon
	rssurlmenu(feedentries[nr].exec)
end

function exec_submenu_grup(id)
	glob.grupm:hide()
	local d = 0 -- directkey
	local subm = menu.new{name=id, icon="icon_yellow"}
	glob.subm=subm
	for v, w in ipairs(feedentries) do
		if w.grup and w.submenu == id  then
			if w.exec == "SEPARATOR" then
				subm:addItem{type="separator"}
			elseif w.exec == "SEPARATORLINE" then
				subm:addItem{type="separatorline", name=w.name}
			else
				d = d + 1
				local dkey = godirectkey(d)
				subm:addItem{type="forwarder", name=w.name, action="exec_urlsub", id=v, directkey=dkey }
			end
		end
	end
	subm:exec()
end

function exec_submenu(id)
	glob.sm:hide()
	local d = 0 -- directkey
	local subm = menu.new{name=id, icon="icon_yellow"}
	glob.subm=subm
	for v, w in ipairs(feedentries) do
		if w.submenu == id and w.grup == nil then
			if w.exec == "SEPARATOR" then
				subm:addItem{type="separator"}
			elseif w.exec == "SEPARATORLINE" then
				subm:addItem{type="separatorline", name=w.name}
			else
				d = d + 1
				local dkey = godirectkey(d)
				subm:addItem{type="forwarder", name=w.name, action="exec_urlsub", id=v, directkey=dkey }
			end
		end
	end
	subm:exec()
end

function exec_grup(id)
	glob.sm:hide()
	local submenus = {}
	local d = 0 -- directkey
	local grupm = menu.new{name=id, icon="icon_yellow"}
	glob.grupm=grupm
	for v, w in ipairs(feedentries) do
		if w.grup == id then
			if w and w.submenu and check_if_double(submenus,w.submenu) then
				submenus[#submenus+1]=w.submenu
				d = d + 1
				local dkey = godirectkey(d)
				grupm:addItem{type="forwarder", name=w.submenu, action="exec_submenu_grup", id=w.submenu, directkey=dkey }
			end
		end
	end
	if #submenus then
		grupm:addItem{type="separatorline"}
	end
	for v, w in ipairs(feedentries) do
		if w and w.grup == id and not w.submenu then
			if w.exec == "SEPARATOR" then
				grupm:addItem{type="separator"}
			elseif w.exec == "SEPARATORLINE" then
				grupm:addItem{type="separatorline", name=w.name}
			else
				d = d + 1
				local dkey = godirectkey(d)
				grupm:addItem{type="forwarder", name=w.name, action="exec_url2", id=v, directkey=dkey }
			end
		end
	end
	grupm:exec()
end

function start()
	local submenus = {}
	local grupmenus = {}

	local d = 0 -- directkey
	local sm = menu.new{name="Lua RSS READER", icon="icon_blue"}
	glob.sm=sm
	if S_Key.fav_setup == conf.set_key or S_Key.fav == conf.set_key then
		sm:addKey{directkey=RC.favorites, id="settings", action="settings"}
	else
		sm:addKey{directkey=RC.favorites, id="home", action="home"}
	end
	if S_Key.fav_setup == conf.set_key or S_Key.setup == conf.set_key then
		sm:addKey{directkey=RC.setup, id="settings", action="settings"}
	end
	sm:addKey{directkey=RC.home, id="home", action="home"}
	sm:addKey{directkey=RC.info, id=rssReaderVersion, action="info"}
-----------------
	for v, w in ipairs(feedentries) do
		if w and w.grup and w.submenu and check_if_double(grupmenus,w.grup) then
			grupmenus[#grupmenus+1]=w.grup
			d = d + 1
			local dkey = godirectkey(d)
			sm:addItem{type="forwarder", name=w.grup, action="exec_grup", id=w.grup, directkey=dkey }
		end
	end
	if #grupmenus then
		sm:addItem{type="separatorline"}
	end
------------------
	for v, w in ipairs(feedentries) do
		if w and w.submenu and w.grup == nil and check_if_double(submenus,w.submenu) then
			submenus[#submenus+1]=w.submenu
			d = d + 1
			local dkey = godirectkey(d)
			sm:addItem{type="forwarder", name=w.submenu, action="exec_submenu", id=w.submenu, directkey=dkey }
		end
	end
	if #submenus then
		sm:addItem{type="separatorline"}
	end
	for v, w in ipairs(feedentries) do
		if not w.submenu and not w.grup then
			if w.exec == "SEPARATOR" then
				sm:addItem{type="separator"}
			elseif w.exec == "SEPARATORLINE" then
				sm:addItem{type="separatorline", name=w.name}
			else
				d = d + 1
				local dkey = godirectkey(d)
				sm:addItem{type="forwarder", name=w.name, action="exec_url", id=v, directkey=dkey }
			end
		end
	end
	sm:exec()
end

function main()
	local config= CONF_PATH .. "/rssreader.conf"
	local fh = filehelpers.new()
	if fh:exist(config, "f") == false and fh:exist(config, "l") == false then
		feedentries = {
			{ name = "rssreader.conf Beispiel",		exec = "SEPARATORLINE" },
			{ name = "heise.de",		exec = "https://www.heise.de/newsticker/heise-atom.xml",addon="heise", submenu="TechNews"},
			{ name = "CHIP Hardware-News",	exec = "http://www.chip.de/rss/rss_technik.xml", submenu="TechNews"},
			{ name = "Tatort - ARD Mediathek", exec = "http://www.ardmediathek.de/tv/Tatort/Sendung?documentId=602916&rss=true", submenu="Podcast", addon="ard"},
			{ name = "Alle Filme - ARD Mediathek", exec = "http://www.ardmediathek.de/tv/Alle-Filme/mehr?documentId=31610076&rss=true", submenu="Podcast",addon="ard"},
			{ name = "arte", exec = "http://www.arte.tv/papi/tvguide-flow/feeds/videos/de.xml?currentWeek=0", submenu="Podcast",addon="arte"},
			{ name = "ARTE : TV-Programm",	exec = "http://www.arte.tv/papi/tvguide-flow/feeds/program/de.xml?currentWeek=0", submenu="Podcast",addon="arte"},
			{ name = "TecTime TV",	exec = "https://www.youtube.com/feeds/videos.xml?user=DrDishTelevision", submenu="Youtube", addon="yt" },
			{ name = "KingOfSat News",	exec = "http://de.kingofsat.net/rssnews.php",submenu="SatInfo",addon="kingofsat"},
		}
	else
		dofile(config)
	end
	fh:mkdir(picdir)

	loadConfig()

	if conf.picdir == nil or fh:exist(conf.picdir , "d") == false then
		conf.picdir = picdir
	end

	package.path = package.path .. ';' .. conf.addonsdir .. '/?.lua'
	if next(feedentries) == nil then
		print("DEBUG ".. __LINE__())
		print("failed while loading " .. config)
		return
	end

	if APIVERSION ~= nil and (APIVERSION.MAJOR > 1 or ( APIVERSION.MAJOR == 1 and APIVERSION.MINOR > 82 )) then
		M = misc.new()
		revision = M:GetRevision()
	end

	start()
	saveConfig()
	fh:rmdir(picdir)
end
main()
