--[[
	Netzkino-Plugin

	The MIT License (MIT)

	Copyright (c) 2014 Marc Szymkowiak 'Ezak91' marc.szymkowiak91@googlemail.com
	for release-version

	Copyright (c) 2014 micha_bbg, svenhoefer, bazi98 an many other db2w-user
	with hints and codesniplets for db2w-Edition

	Changed to internal curl by BPanther, 10. Feb 2019

	Permission is hereby granted, free of charge, to any person obtaining a copy
	of this software and associated documentation files (the "Software"), to deal
	in the Software without restriction, including without limitation the rights
	to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
	copies of the Software, and to permit persons to whom the Software is
	furnished to do so, subject to the following conditions:
	The above copyright notice and this permission notice shall be included in all
	copies or substantial portions of the Software.

	THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
	IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
	FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
	AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
	LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
	OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
	SOFTWARE.
]]

caption = "Netzkino HD"
local json = require "json"

--Objekte
function script_path()
	local str = debug.getinfo(2, "S").source:sub(2)
	return str:match("(.*/)")
end

ret = nil -- global return value
function key_home(a)
	ret = MENU_RETURN["EXIT"]
	return ret
end

function key_setup(a)
	ret = MENU_RETURN["EXIT_ALL"]
	return ret
end

-- ####################################################################
-- function from http://lua-users.org/wiki/BaseSixtyFour

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
-- ####################################################################

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

function init()
	-- set collectgarbage() interval from 200 (default) to 50
	collectgarbage('setpause', 50)

	categories = {};
	movies = {};
	n = neutrino();
	page = 1;
	max_page = 1;
	last_category_id = 1;
	selected_category_id = 0;
	selected_movie_id = 0;
	selected_stream_id = 0;
	mode = 0;
	config_file = "/var/tuxbox/config/netzkino.conf";

	-- use netzkino icon placed in same dir as the plugin ...
	--netzkino_png = script_path() .. "netzkino.png"
	-- ... or use icon placed in one of neutrino's icon dirs
	--netzkino_png = "netzkino"
	-- ... or use a base64 encoded icon
	netzkino_png = decodeImage("data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAABgAAAAYCAIAAABvFaqvAAAAA3NCSVQICAjb4U/gAAAAYnpUWHRSYXcgcHJvZmlsZSB0eXBlIEFQUDEAAHicVcixDYAwDADB3lN4hHccHDIOQgFFQoCyf0EBDVee7O1so696j2vrRxNVVVXPkmuuaQFmXgZuGAkoXy38TEQNDyseBiAPSLYUyXpQ8HMAAAL2SURBVDiNrZU7b1xVEMf/c869d++192FlN944rGPHdiIFCSmKeBQgREFBRUNDxQegoEWiT0FHg0QBVdpIfACqNJESKWmiBCSkOGZtL3i9jvZ57z2PGYrdldeLnUTCo1Odx+/M/GfmHPr67t84D1PnQnkzEJGA/geIFKmAvTfDbiypsPdQryAGp7oAqLyzI91dMQNL8Yc310jcwOqWKXZUVQGAvA5EypvUNh+BlLpwNazUAyZZIq8K3H9ZyffCQesg3kKYQPjs0Ii8Se2L+yitxJsfRUsrBIiwkMo98qCcV98ehlXae+iyAYjOBoFs8xGW1pNL18Q769lT8MnlET3/rRG97OcyzKwtrqbFNbf7WE4GNwMilXd2QCq5dI2dKxbUZzdKn9Y7P3331e1vvxl0WsZjZCS3NlnehC6Yw23Q8fFjjYiUdHdVdVOYveDWevmLd+Lx0vWNK14wsmK9EEHYqeoGH/xO9S3xPOcROZOKGYXlOoSJ0O7l3//4yw8/36ldrA37XevYeJnIIhJVlsVbmx4rNQUR2IwQLRJBmJXw0/1h8/Lnyx98uVK/sNfuOu8hLDwZYEZUFDM6Pf3eO2cysB/fO8zS0UCTCABh50yqxGNck6TZu1m5pyCBChPNJogWAB6XG4noKJl4rqMwLtL4DgIp7ThXYfzfrEkQL5AumN4/AAECyFyCITKeB2B6bZAKkzKmm47zJ8xUafDRNimNVxqpwHe2qdKQmeKeqSPhqLYOl2XtF6QmIROh1/5zrNGUorNOE6Yf1a7OdskJsYkQvHXL/fUgI4praxruj/3B7V93xJsOl+WQlQ6zo6YcPAtW3yOlzwRBJExKuPK+232c9lu6utFVF+/tJ84gSgI/bJujbeS9YPXdcLEifKJp57tfhIOkpDc/NofPfeuJ32dEJe+t8TkAqjSixk1Seo5yCmgMI0JheYvq123aE5sqEQqTcKFCwiI894CcDZrgWISDeBHx4mSG3fxr9kagqXev2TC1c/tF/gU5kpOQwApURgAAAABJRU5ErkJggg==");
end

--Kategorien anzeigen
function get_categories()
	local fname = "/tmp/netzkino_categories.txt";

	local h = hintbox.new{caption=caption, text="Kategorien werden geladen ...", icon=netzkino_png};
	h:paint();

	if Curl == nil then
		Curl = curl.new()
	end
	Curl:download { url = "https://www.netzkino.de/capi/get_category_index", A="Mozilla/5.0;", followRedir = true, o = fname }

	local fp = io.open(fname, "r")
	if fp == nil then
		h:hide();
		error("Error opening file '" .. fname .. "'.")
	else
		local s = fp:read("*a")
		fp:close()

		local j_table = json:decode(s)
		local j_categories = j_table.categories
		local j = 1;
		for i = 1, #j_categories do
			local cat = j_categories[i];
			if cat ~= nil then
				-- Kategorie 9  -> keine Streams
				-- todo remove Kategorie 6481 & 6491(altes Glueckskino & Glueckskino) -> keine Streams
				if cat.id ~= 9 then
					categories[j] =
					{
						id           = j;
						category_id = cat.id;
						title        = cat.title;
						post_count   = cat.post_count;
					};
					j = j + 1;
				end
			end
		end
		h:hide();

		page = 1;
		if j > 1 then
			get_categories_menu();
		else
			messagebox.exec{title="Fehler", text="Keinen Kategorien gefunden!", icon="error", timeout=5, buttons={"ok"}}
		end
	end
end

-- Erstellen des Kategorien-Menü
function get_categories_menu()
	selected_category_id = 0;
	m_categories = menu.new{name=""..caption.." Kategorien", icon=netzkino_png};

	m_categories:addKey{directkey=RC["home"], id="home", action="key_home"}
	m_categories:addKey{directkey=RC["setup"], id="setup", action="key_setup"}
	m_categories:addItem{type="separator"};

	for index, category_detail in pairs(categories) do
		local count = "(" .. category_detail.post_count .. ")"
		m_categories:addItem{type="forwarder", value=count, action="set_category", id=index, name=category_detail.title};
	end
	m_categories:exec()
	-- Alle Menüs verlassen
	if ret == MENU_RETURN["EXIT_ALL"] then
		return ret
	elseif tonumber(selected_category_id) ~= 0 then
		get_movies(selected_category_id);
	end
end

-- Setzen der ausgewählten Kategorie
function set_category(_id)
	selected_category_id = tonumber(_id);
	return MENU_RETURN["EXIT_ALL"];
end

-- Filme zur Kategorie laden (variabel Pro Seite)
function get_movies(_id)
	local fname = "/tmp/netzkino_movies.txt";
	local index = tonumber(_id);
	local page_nr = tonumber(page);
	movies = {};

	last_category_id = index;

	local sh = n:FontHeight(FONT.MENU)
	local items = math.floor(580/sh - 4);
	if items > 10 then
		items = 10 -- because of 10 hotkeys
	end

	local h = hintbox.new{caption=caption, text="Kategorie wird geladen ...", icon=netzkino_png};
	h:paint();

	if Curl == nil then
		Curl = curl.new()
	end
	Curl:download { url = "https://www.netzkino.de/capi/get_category_posts&id=" .. categories[index].category_id .. "&count=" .. items .. "d&page=" .. page_nr .. "&custom_fields=Streaming", A="Mozilla/5.0;", followRedir = true, o = fname }

	local fp = io.open(fname, "r")
	if fp == nil then
		h:hide();
		error("Error opening file '" .. fname .. "'.")
	else
		local s = fp:read("*a")
		fp:close()

		local j_table = json:decode(s)
		max_page = tonumber(j_table.pages);
		local posts = j_table.posts

		j = 1;
		for i = 1, #posts do
			local j_streaming = nil;
			local custom_fields = posts[i].custom_fields
			if custom_fields ~= nil then
				local stream = custom_fields.Streaming
				if stream ~= nil then
					j_streaming = stream[1]
				end
			end

			if j_streaming ~= nil then
				j_title = posts[i].title
				j_content = posts[i].content

				local j_cover="";
				local attachments = posts[i].attachments[1]
				if attachments ~= nil then
					local images = attachments.images;
					if images ~= nil then
						local full = images.full
						if full ~= nil then
							j_cover = full.url
						end
					end
				end

				movies[j] =
				{
					id      = j;
					title   = j_title;
					content = j_content;
					cover   = j_cover;
					stream  = j_streaming;
				};
				j = j + 1;
			end
		end
		h:hide();

		if j > 1 then
			get_movies_menu(index);
		else
			messagebox.exec{title="Fehler", text="Keinen Stream gefunden!", icon="error", timeout=5, buttons={"ok"}}
			get_categories();
		end
	end
end

--Auswahlmenü der Filme anzeigen
function get_movies_menu(_id)
	local index = tonumber(_id);
	local menu_title = caption .. ": " .. categories[index].title;
	selected_movie_id = 0;

	m_movies = menu.new{name=menu_title, icon=netzkino_png};

	m_movies:addKey{directkey=RC["home"], id="home", action="key_home"}
	m_movies:addKey{directkey=RC["setup"], id="setup", action="key_setup"}

	if max_page > 1 then
		local aktPage = tostring(page);
		local maxPage = tostring(max_page);
		local sText = "Seite " .. aktPage .. " von " .. maxPage
		m_movies:addItem{type="subhead", name=sText};
	end
	if page < max_page or page > 1 then
		m_movies:addItem{type="separator"};
	end
	if page < max_page then
		m_movies:addItem{type="forwarder", name="Nächste Seite", action="set_movie", id="-2", icon="blau", directkey=RC["blue"]};
		m_movies:addKey{directkey=RC["page_down"], action="set_movie", id="-2"}
		m_movies:addKey{directkey=RC["right"], action="set_movie", id="-2"}
	end
	if page > 1 then
		m_movies:addItem{type="forwarder", name="Vorherige Seite", action="set_movie", id="-1", icon="gelb", directkey=RC["yellow"]};
		m_movies:addKey{directkey=RC["page_up"], action="set_movie", id="-1"}
		m_movies:addKey{directkey=RC["left"], action="set_movie", id="-1"}
	end
	if page < max_page or page > 1 then
		m_movies:addItem{type="separatorline"};
	end
	m_movies:addItem{type="separator"};

	local d = 0 -- directkey
	local _icon = ""
	local _directkey = ""
	for index, movie_detail in pairs(movies) do
		d = d + 1
		if d < 10 then
			_icon = d
			_directkey = RC["".. d ..""]
		elseif d == 10 then
			_icon = "0"
			_directkey = RC["0"]
		else
			-- reset
			_icon = ""
			_directkey = ""
		end
		m_movies:addItem{type="forwarder", action="set_movie", id=index, name=conv_utf8(movie_detail.title), icon=_icon, directkey=_directkey };
	end
	m_movies:exec()

	-- Alle Menüs verlassen
	if ret == MENU_RETURN["EXIT_ALL"] then
		return ret
	-- Zurück zum Kategorien-Menü
	elseif selected_movie_id == 0 then
		get_categories();
	-- Vorherige Seite laden
	elseif selected_movie_id == -1 then
		page = page - 1;
		get_movies(last_category_id);
	-- Nächste Seite laden
	elseif selected_movie_id == -2 then
		page = page + 1;
		get_movies(last_category_id);
	-- Filminfo anzeigen
	else
		show_movie_info(selected_movie_id);
	end
end

--Setzen des ausgewählten Films
function set_movie(_id)
	selected_movie_id = tonumber(_id);
	return MENU_RETURN["EXIT_ALL"];
end

-- Filminfos anzeigen
function show_movie_info(_id)

	local index = tonumber(_id);
	selected_stream_id = 0;
	mode = 0;

	local spacer = 8;
	local x  = 150;
	local y  = 70;
	local dx = 1000;
	local dy = 600;
	local ct1_x = 240;

	local window_title = caption .. "* " .. movies[index].title;
	w = cwindow.new{x=x, y=y, dx=dx, dy=dy, title=conv_utf8(window_title), icon=netzkino_png, btnRed="Film abspielen", btnGreen="Film downloaden" };
	local tmp_h = w:headerHeight() + w:footerHeight();
	ct1 = ctext.new{parent=w, x=ct1_x, y=20, dx=dx-ct1_x-2, dy=dy-tmp_h-40, text=conv_utf8(movies[index].content), mode = "ALIGN_TOP | ALIGN_SCROLL | DECODE_HTML"};

	if movies[index].cover ~= nil then
		getPicture(conv_utf8(movies[index].cover));

		local pic_x =  20
		local pic_y =  35
		local pic_w = 190
		local pic_h = 260
		local tmp_w;
		tmp_w, tmp_h = n:GetSize("/tmp/netzkino_cover.jpg");
		if tmp_w < pic_w then
			pic_x = (ct1_x - tmp_w) / 2;
		else
			pic_x = (ct1_x - pic_w) / 2;
		end
		cpicture.new{parent=w, x=pic_x, y=pic_y, dx=pic_w, dy=pic_h, image="/tmp/netzkino_cover.jpg"}
	end

	w:paint();
	ret = getInput(index);
	w:hide();

	if ret == MENU_RETURN["EXIT_ALL"] then
		return ret
	elseif selected_stream_id == 0 then
		get_movies(last_category_id);
	elseif selected_stream_id ~= 0 and mode == 1 then
		stream_movie(selected_stream_id);
		collectgarbage();
		get_movies(last_category_id);
	elseif selected_stream_id ~= 0 and mode == 2 then
		download_stream(selected_stream_id);
		collectgarbage();
		get_movies(last_category_id)
	end
end

function get_timing_menu()
	local ret = 0

	local conf = io.open("/var/tuxbox/config/neutrino.conf", "r")
	if conf then
		for line in conf:lines() do
			local key, val = line:match("^([^=#]+)=([^\n]*)")
			if (key) then
				if key == "timing.menu" then
					if (val ~= nil) then
						ret = val;
					end
				end
			end
		end
		conf:close()
	end

	return ret
end

--auf Tasteneingaben reagieren
function getInput(_id)
	local index = tonumber(_id);
	local i = 0
	local d = 500 -- ms
	local t = (get_timing_menu() * 1000) / d
	if t == 0 then
		t = -1 -- no timeout
	end
	repeat
		i = i + 1
		msg, data = n:GetInput(d)
		if msg >= RC["0"] and msg <= RC.MaxRC then
			i = 0 -- reset timeout
		end
		-- Taste Rot startet Stream
		if (msg == RC['ok']) or (msg == RC['red']) then
			selected_stream_id = index;
			mode = 1;
			break;
		-- Taste Gruen startet Download
		elseif (msg == RC['green']) then
			selected_stream_id = index;
			mode = 2;
			break;
		elseif (msg == RC['up'] or msg == RC['page_up']) then
			ct1:scroll{dir="up"};
		elseif (msg == RC['down'] or msg == RC['page_down']) then
			ct1:scroll{dir="down"};
		end
	-- Taste Exit oder Menü beendet das Fenster
	until msg == RC['home'] or msg == RC['setup'] or i == t;

	if msg == RC['setup'] then
		return MENU_RETURN["EXIT_ALL"]
	end
end

--herunterladen des Bildes
function getPicture(_picture)
	local fname = "/tmp/netzkino_cover.jpg";
	if Curl == nil then
		Curl = curl.new()
	end
	Curl:download { url = _picture, A="Mozilla/5.0;", followRedir = true, o = fname }
end

--Stream starten
function stream_movie(_id)
	local index = tonumber(_id);
	local stream_name = conv_utf8(movies[index].stream);
	video = video.new()
	video:PlayFile(conv_utf8(movies[index].title), "https://pmd.netzkino-seite.netzkino.de/" .. stream_name ..".mp4");
end

--Stream downloaden
function download_stream(_id)

	local index = tonumber(_id);
	local stream_name = conv_utf8(movies[index].stream);

	local cf = io.open(config_file, "r")
	if cf then
		for line in cf:lines() do
			d_path = line:match("download_path=(.-);");
		end
		cf:close();
	else
		local nc = io.open("/var/tuxbox/config/neutrino.conf", "r")
		if nc then
			for l in nc:lines() do
				local key, val = l:match("^([^=#]+)=([^\n]*)")
				if (key) then
					if key == "network_nfs_recordingdir" then
						if (val == nil) then
							d_path ="/media/sda1/movies/";
						else
							d_path = val;
						end
					end
				end
			end
			nc:close()
		end
	end

	local movie_file = d_path .. "/" .. conv_utf8(movies[index].title) .. ".mp4" ;
	local inhalt = "Netzkino HD: Download " .. conv_utf8(movies[index].title) .. " - Bitte warten...";
	local info_text = ctext.new{x=30, y=20, dx=900, dy=10, text=inhalt};
	info_text:paint()

	if Curl == nil then
		Curl = curl.new()
	end
	local ret = Curl:download { url = "https://pmd.netzkino-seite.netzkino.de/" .. stream_name .. ".mp4", A="Mozilla/5.0;", followRedir = true, connectTimeout = 86400, o = movie_file }

	info_text:hide();
	local download_text = ctext.new{x=30, y=20, dx=900, dy=50};

	if ret == CURL.OK then
		download_text:setText{text="[" .. ret .. "] " .. "Der Stream wurde erfolgreich heruntergeladen. OK zum verlassen."};
	else
		download_text:setText{text="[" .. ret .. "] " .. "Unbekannter Zustand oder Fehler. Versuche Mirror Server.\n" .. inhalt};
		download_text:paint();
		local ret = Curl:download { url = "http://pmd.netzkino-and.netzkino.de/" .. stream_name .. ".mp4", A="Mozilla/5.0;", followRedir = true, connectTimeout = 86400, o = movie_file }
		download_text:hide();
		if ret == CURL.OK then
			download_text:setText{text="[" .. ret .. "] " .. "Der Stream wurde erfolgreich heruntergeladen. OK zum verlassen."};
		else
			download_text:setText{text="[" .. ret .. "] " .. "Unbekannter Zustand oder Fehler. Bitte überprüfen sie die Datei. OK zum verlassen."};
		end
	end

	download_text:paint();

	repeat
		msg, data = n:GetInput(500)
	until msg == RC['home'] or msg == RC['setup'] or msg == RC['ok'];

	download_text:hide();
end

-- UTF8 in Umlaute wandeln
function conv_utf8(_string)
	if _string ~= nil then
		_string = string.gsub(_string,"\\u0026","&");
		_string = string.gsub(_string,"\\u00a0"," ");
		_string = string.gsub(_string,"\\u00b0","°");
		_string = string.gsub(_string,"\\u00b4","´");
		_string = string.gsub(_string,"\\u00c4","Ä");
		_string = string.gsub(_string,"\\u00d6","Ö");
		_string = string.gsub(_string,"\\u00dc","Ü");
		_string = string.gsub(_string,"\\u00df","ß");
		_string = string.gsub(_string,"\\u00e1","á");
		_string = string.gsub(_string,"\\u00e4","ä");
		_string = string.gsub(_string,"\\u00e8","è");
		_string = string.gsub(_string,"\\u00e9","é");
		_string = string.gsub(_string,"\\u00f3","ó");
		_string = string.gsub(_string,"\\u00f4","ô");
		_string = string.gsub(_string,"\\u00f6","ö");
		_string = string.gsub(_string,"\\u00f8","ø");
		_string = string.gsub(_string,"\\u00fb","û");
		_string = string.gsub(_string,"\\u00fc","ü");
		_string = string.gsub(_string,"\\u2013","–");
		_string = string.gsub(_string,"\\u2018","'");
		_string = string.gsub(_string,"\\u2019","'");
		_string = string.gsub(_string,"\\u201a","'");
		_string = string.gsub(_string,"\\u201b","'");
		_string = string.gsub(_string,"\\u201c","“");
		_string = string.gsub(_string,"\\u201d","\"");
		_string = string.gsub(_string,"\\u201e","„");
		_string = string.gsub(_string,"\\u201f","\"");
		_string = string.gsub(_string,"\\u2026","…");
		_string = string.gsub(_string,"&#038;","&");
		_string = string.gsub(_string,"&#039;","'");
		_string = string.gsub(_string,"&#8211;","–");
		_string = string.gsub(_string,"&#8212;","—");
		_string = string.gsub(_string,"&#8216;","‘");
		_string = string.gsub(_string,"&#8217;","’");
		_string = string.gsub(_string,"&#8230;","…");
		_string = string.gsub(_string,"&#8243;","″");
		_string = string.gsub(_string,"&amp;","&");
		_string = string.gsub(_string,"<[^>]*>","");
		_string = string.gsub(_string,"\\/","/");
		_string = string.gsub(_string,"\\n","");
	end
	return _string
end

--Main
init();
get_categories();
os.execute("rm /tmp/netzkino_*.*");
os.execute("rm /tmp/lua*.png");
collectgarbage();
