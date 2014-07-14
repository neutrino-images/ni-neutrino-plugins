--Netzkino Plugin
--From Ezak for coolstream.to
--READ LICENSE on https://github.com/Ezak91/CST-Netzkino-HD-Plugin

caption = "Netzkino HD"
local JSON = require "JSON.lua"

--Objekte
function script_path()
	local str = debug.getinfo(2, "S").source:sub(2)
	return str:match("(.*/)")
end

function init()
	categories = {};
	movies = {};
	n = neutrino();
	page = 1;
	max_page = 1;
	last_categorie_id = 1;
	selected_categorie_id = 0;
	selected_movie_id = 0;
	selected_stream_id = 0;
	mode = 0;
	config_file = "/var/tuxbox/config/netzkino.conf";
	wget_busy_file = "/tmp/.netzkino_wget.busy"
end

--Kategorien anzeigen
function get_categories()
	local fname = "/tmp/netzkino_categories.txt";
    
	os.execute("wget -q -O " .. fname .. " 'http://www.netzkino.de/capi/get_category_index'" );

	local fp = io.open(fname, "r")
	if fp == nil then
		error("Error opening file '" .. fname .. "'.")
	else
		local s = fp:read("*a")
		fp:close()

		local j_table = JSON:decode(s)
		local j_categories = j_table.categories
		local j = 1;
		for i = 1, #j_categories do
			local cat = j_categories[i];
			if cat ~= nil then
				-- Kategorie 9 (Blog) -> keine Streams
				if cat.id ~= 9 then
					categories[j] =
					{
						id           = j;
						categorie_id = cat.id;
						title        = cat.title;
						post_count   = cat.post_count;
					};
					j = j + 1;
				end
			end
		end
		
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
	selected_categorie_id = 0;
	m_categories = menu.new{name=""..caption.." Kategorien"};
	for index, categorie_detail in pairs(categories) do
		local count = "(" .. categorie_detail.post_count .. ")"
		m_categories:addItem{type="forwarder", value=count, action="set_categorie", id=index, name=categorie_detail.title};
	end
	m_categories:exec()
	if tonumber(selected_categorie_id) ~= 0 then
		get_movies(selected_categorie_id);
	end
end

-- Setzen der ausgewählten Kategorie
function set_categorie(_id)
	selected_categorie_id = tonumber(_id);
	return MENU_RETURN["EXIT_ALL"];
end

-- Filme zur Kategorie laden (variabel Pro Seite)
function get_movies(_id)
	local fname = "/tmp/netzkino_movies.txt";
	local index = tonumber(_id);
	local page_nr = tonumber(page);
	movies = {};

	last_categorie_id = index;

	local sh = n:FontHeight(FONT.MENU)
	local items = math.floor(580/sh - 4);
	os.execute("wget -q -O " .. fname .. " 'http://www.netzkino.de/capi/get_category_posts&id=" .. categories[index].categorie_id .. "&count=" .. items .. "d&page=" .. page_nr .. "&custom_fields=Streaming'");

	local fp = io.open(fname, "r")
	if fp == nil then
		error("Error opening file '" .. fname .. "'.")
	else
		local s = fp:read("*a")
		fp:close()

		local j_table = JSON:decode(s)
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
	
	m_movies = menu.new{name=menu_title};

	if max_page > 1 then
		local aktPage = tostring(page);
		local maxPage = tostring(max_page);
		local sText = "Seite " .. aktPage .. " von " .. maxPage
		m_movies:addItem{type="subhead", name=sText};
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
	for index, movie_detail in pairs(movies) do
		m_movies:addItem{type="forwarder", action="set_movie", id=index, name=conv_utf8(movie_detail.title)};
	end
	m_movies:exec()	
	-- Zurück zum Kategorien-Menü
	if selected_movie_id == 0 then
		get_categories();
	-- Vorherige Seite laden
	elseif selected_movie_id == -1 then
		page = page - 1;
		get_movies(last_categorie_id);
	-- Nächste Seite laden
	elseif selected_movie_id == -2 then
		page = page + 1;
		get_movies(last_categorie_id);
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
	local wget_busy = io.open(wget_busy_file, "r")
	if wget_busy then
		wget_busy:close()
		w = cwindow.new{x=x, y=y, dx=dx, dy=dy, title=conv_utf8(window_title), icon="mp_play", btnRed="Film abspielen" };
	else
		w = cwindow.new{x=x, y=y, dx=dx, dy=dy, title=conv_utf8(window_title), icon="mp_play", btnRed="Film abspielen", btnGreen="Film downloaden" };
	end
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

	neutrinoExec(index);
	w:hide{no_restore="true"};
	if selected_stream_id == 0 then
		get_movies(last_categorie_id);
	elseif selected_stream_id ~= 0 and mode == 1 then
		stream_movie(selected_stream_id);
		collectgarbage();
		get_movies(last_categorie_id);
	elseif selected_stream_id ~= 0 and mode == 2 then
		download_stream(selected_stream_id);
		collectgarbage();
		get_movies(last_categorie_id)
	end
end

--herunterladen des Bildes
function getPicture(_picture)
	local fname = "/tmp/netzkino_cover.jpg";
	os.execute("wget -q -U Mozilla -O " .. fname .. " '" .. _picture .. "'");
end

--Fenster anzeigen und auf Tasteneingaben reagieren
function neutrinoExec(_id)
	local index = tonumber(_id);
	repeat
		msg, data = n:GetInput(500)
		-- Taste Rot installiert den Download
		if (msg == RC['ok']) or (msg == RC['red']) then
			selected_stream_id = index;
			mode = 1;
			msg = RC['home'];
		elseif (msg == RC['green']) then
			selected_stream_id = index;
			mode = 2;
			msg = RC['home'];
		elseif (msg == RC['up'] or msg == RC['page_up']) then
			ct1:scroll{dir="up"};
		elseif (msg == RC['down'] or msg == RC['page_down']) then
			ct1:scroll{dir="down"};
		end
	-- Taste Exit oder Menü beendet das Fenster
	until msg == RC['home'] or msg == RC['setup'];
end

--Stream starten
function stream_movie(_id)
	local index = tonumber(_id);
	local stream_name = conv_utf8(movies[index].stream);
	n:PlayFile(conv_utf8(movies[index].title), "http://pmd.netzkino-and.netzkino.de/" .. stream_name ..".mp4");
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
	
	local movie_file = "'" .. d_path .. "/" .. conv_utf8(movies[index].title) .. ".mp4'" ;

	local h = hintbox.new{caption=caption, text="Download: "..conv_utf8(movies[index].title)..""}
	h:paint()
	local i = 0
	repeat
		i = i + 1
		msg, data = n:GetInput(500)
	until msg == RC.ok or msg == RC.home or i == 4 -- 2 seconds
	h:hide()

	print(script_path() .. "netzkino_wget.sh " .. stream_name .. " " .. movie_file)
	os.execute(script_path() .. "netzkino_wget.sh " .. stream_name .. " " .. movie_file)
end


-- UTF8 in Umlaute wandeln
function conv_utf8(_string)
	if _string ~= nil then
		_string = string.gsub(_string,"\\u0026","&");
		_string = string.gsub(_string,"\\u00a0"," ");
		_string = string.gsub(_string,"\\u00b4","´");
		_string = string.gsub(_string,"\\u00c4","Ä");
		_string = string.gsub(_string,"\\u00d6","Ö");
		_string = string.gsub(_string,"\\u00dc","Ü");
		_string = string.gsub(_string,"\\u00df","ß");
		_string = string.gsub(_string,"\\u00e1","á");
		_string = string.gsub(_string,"\\u00e4","ä");
		_string = string.gsub(_string,"\\u00e8","è");
		_string = string.gsub(_string,"\\u00e9","é");
		_string = string.gsub(_string,"\\u00f4","ô");
		_string = string.gsub(_string,"\\u00f6","ö");
		_string = string.gsub(_string,"\\u00fb","û");
		_string = string.gsub(_string,"\\u00fc","ü");
		_string = string.gsub(_string,"\\u2013","–");
		_string = string.gsub(_string,"\\u201c","“");
		_string = string.gsub(_string,"\\u201e","„");
		_string = string.gsub(_string,"\\u2026","…");
		_string = string.gsub(_string,"&#038;","&");
		_string = string.gsub(_string,"&#8211;","–");
		_string = string.gsub(_string,"&#8212;","—");
		_string = string.gsub(_string,"&#8216;","‘");
		_string = string.gsub(_string,"&#8217;","’");
		_string = string.gsub(_string,"&#8230;","…");
		_string = string.gsub(_string,"&#8243;","″");
		_string = string.gsub(_string,"<[^>]*>","");
		_string = string.gsub(_string,"\\/","/");
		_string = string.gsub(_string,"\\n","");
		_string = string.gsub(_string,"\\u00df","ß"); 
		_string = string.gsub(_string,"&#8211;","-"); 
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
collectgarbage();
