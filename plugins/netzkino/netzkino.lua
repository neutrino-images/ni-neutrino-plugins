--Netzkino Plugin
--From Ezak for coolstream.to
--READ LICENSE on https://github.com/Ezak91/CST-Netzkino-HD-Plugin

--Objekte
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
end

--Kategorien anzeigen
function get_categories()
	local fname = "/tmp/netzkino_categories.txt";
    
	os.execute("wget -q -O " .. fname .. " 'http://www.netzkino.de/capi/get_category_index'" );

	local fp = io.open(fname, "r")
	if fp == nil then
		print("Error opening file '" .. fname .. "'.")
		os.exit(1)
	else
		local s = fp:read("*a")
		fp:close()
		
		i = 1;
		
		
		s = s:match("%[(.-)%]");		
		for categorie in string.gmatch(s, "%{(.-)%}") do
			categories[i] =
			{
				id = i;
				categorie_id = categorie:match("\"id\":(.-),");
				title = categorie:match("\"title\":\"(.-)\",");
			};
			i = i + 1;
		end
		
		page = 1;
		
		if categories[1].categorie_id ~= nil then
			get_categories_menu();
		end
		
	end	
end

-- Erstellen des Kategorien-Menü
function get_categories_menu()
	selected_categorie_id = 0;
	m_categories = menu.new{name="Netzkino HD Kategorien"};
	for index, categorie_detail in pairs(categories) do
		m_categories:addItem{type="forwarder", action="set_categorie", id=index, name=categorie_detail.title};
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
		print("Error opening file '" .. fname .. "'.")
		os.exit(1)
	else
		local s = fp:read("*a")
		fp:close()
		max_page = tonumber(s:match("\"pages\":(.-),"));
	
		i = 1;
						
		for movie in string.gmatch(s, "\"type\":\"post\"(.-)%]}}") do
			if string.find(movie, "\"custom_fields\":{}},") then
			else			
				movies[i] =
				{
					id = i;
					title = movie:match("\"title_plain\":\"(.-)\"");
					content = movie:match("\"content\":\"(.-)\"");
					cover = movie:match("\"full\":{\"url\":\"(.-)\"");
					stream = movie:match("\"Streaming\":%[\"(.-)\"");
				};
				i = i + 1;
			end
		end
		
		if movies[1].title ~= nil then
			get_movies_menu(index);
		end
	end		
end

--Auswahlmenü der Filme anzeigen
function get_movies_menu(_id)
	local index = tonumber(_id);
	local menu_title = "Netzkino HD: " .. categories[index].title;
	selected_movie_id = 0;
	
	m_movies = menu.new{name=menu_title};
	
	if page < max_page then
		m_movies:addItem{type="forwarder", name="Nächste Seite", action="set_movie", id="-2", icon="blau", directkey=RC["blue"]};
		m_movies:addKey{directkey=RC["right"], action="set_movie", id="-2"}
	end
	if page > 1 then
		m_movies:addItem{type="forwarder", name="Vorherige Seite", action="set_movie", id="-1", icon="gelb", directkey=RC["yellow"]};
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
	
	local window_title = "Netzkino HD " .. movies[index].title;
		
	w = cwindow.new{x=x, y=y, dx=dx, dy=dy, title=conv_utf8(window_title), icon="btn_play", btnRed="Film abspielen", btnGreen="Film downloaden" };

	ct1 = ctext.new{parent=w, x=240, y=25, dx=980, dy=380, text=conv_utf8(movies[index].content), mode = "ALIGN_TOP | ALIGN_SCROLL | DECODE_HTML"};
	
	ct2 = ctext.new{parent=w, x=500, y=450, dx=900, dy=10, text="Netzkino HD Plugin by Ezak for coolstream.to"};

	if movies[index].cover ~= nil then
		getPicture(conv_utf8(movies[index].cover));
		cpicture.new{parent=w, x=25, y=40, dx=190, dy=260, image="/tmp/netzkino_cover.jpg"}
	end

	w:paint();

	neutrinoExec(index);
	w:hide{no_restore="true"};
	if selected_stream_id == 0 then
		get_movies(last_categorie_id);
	elseif selected_stream_id ~= 0 and mode == 1 then
		stream_movie(selected_stream_id);
	elseif selected_stream_id ~= 0 and mode == 2 then
		download_stream(selected_stream_id);
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
		if (msg == RC['red']) then
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
	
	local inhalt = "Netzkino HD: Download " .. conv_utf8(movies[index].title) .. "   Bitte warten!!"; 
	local info_text = ctext.new{x=30, y=20, dx=900, dy=10, text=inhalt};
	info_text:paint()

	wget_ret = os.execute("wget -c -O " .. movie_file .. " 'http://pmd.netzkino-and.netzkino.de/" .. stream_name ..".mp4' &>/../tmp/netzkino_wget.log");
	
	info_text:hide{no_restore="true"};
	local download_text = ctext.new{x=30, y=20, dx=900, dy=10};
	
	local wlog = "/tmp/netzkino_wget.log";
	local wl = io.open(wlog, "r")
	if wl == nil then
		download_text:setText{text="Error opening file /tmp/netzkino_wget.log . OK für Ende"};
	else
		local s = wl:read("*a")
		wl:close()
		if string.find(s,"error") or string.find(s,"ERROR") then
			download_text:setText{text="Fehler beim Herunterladen des Streams. OK für Ende"};
		elseif string.find(s,"100%%") then
			download_text:setText{text="Der Stream wurde erfolgreich heruntergeladen. OK für Ende"};
		else
			download_text:setText{text="Unbekannter Zustand bitte überprüfen sie die Datei. OK für Ende"};
		end
	end
	
	download_text:paint();
	
	repeat
		msg, data = n:GetInput(500)
	until msg == RC['home'] or msg == RC['setup'] or msg == RC['ok'];	
	
	download_text:hide{no_restore="true"};
	
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
