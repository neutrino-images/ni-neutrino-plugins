
--[[ The Tuxbox Copyright

 Copyright 2019 Markus Volk

 Redistribution and use in source and binary forms, with or without modification, 
 are permitted provided that the following conditions are met:

 Redistributions of source code must retain the above copyright notice, this list
 of conditions and the following disclaimer. Redistributions in binary form must
 reproduce the above copyright notice, this list of conditions and the following
 disclaimer in the documentation and/or other materials provided with the distribution.

 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS ``AS IS`` AND ANY EXPRESS OR IMPLIED
 WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
 AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
 HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
 EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
 SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
 OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
 SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

 The views and conclusions contained in the software and documentation are those of the
 authors and should not be interpreted as representing official policies, either expressed
 or implied, of the Tuxbox Project.]]

caption = "Logo Updater"

locale = {}
locale["deutsch"] = {
fetch_source = "Die aktuellen Logos werden geladen",
fetch_failed = "Download fehlgeschlagen",
copy_logos = "Die Logos werden ins Logoverzeichnis kopiert",
copy_failed = "Kopieren fehlgeschlagen",
copy_eventlogos = "Die Event-Logos werden ins Logoverzeichnis kopiert",
copy_popuplogos = "Die Popup-Logos werden ins Logoverzeichnis kopiert",
link_logos = "Es werden benötigte Links erstellt",
link_failed = "Erstellen der Links fehlgeschlagen",
cleanup = "Temporäre Dateien werden gelöscht",
cleanup_failed = "Temporäre Dateien konnten nicht entfernt werden",
menu_options = "Einstellungen",
menu_update = "Update starten",
yes = "ja",
no = "nein",
cfg_popup = "Popup Logos installieren",
cfg_event = "Event Logos installieren",
cfg_git = "Git für den Download verwenden",
cfg_keep = "Bestehende Dateien behalten",
}
locale["english"] = {
fetch_source = "The latest logos are getting downloaded",
fetch_failed = "Download failed",
copy_logos = "Copy logos to its destination",
copy_failed = "Copying data failed",
copy_eventlogos = "Copying eventlogos",
copy_popuplogos = "Copying popuplogos",
link_logos = "Creating needed links",
link_failed = "Linking failed",
cleanup = "Cleanup temporary files",
cleanup_failed = "Cleanup data failed",
menu_options = "Options",
menu_update = "Start update",
yes = "yes",
no = "no",
cfg_popup = "Install popup logos",
cfg_event = "Install event logos",
cfg_git = "Use git for downloading",
cfg_keep = "Keep existing files"
}

n = neutrino()
neutrino_conf = "/var/tuxbox/config/neutrino.conf" 
tmp = "/tmp/logoupdate"
icondir = "/share/tuxbox/neutrino/icons"
logo_source = tmp .. "/logos"
logo_event_source = tmp .. "/logos-events"
logo_popup_source = tmp .. "/logos-popup"
logolinker = tmp .. "/logo-links/logo-linker.sh"
logo_intro = tmp .. "/logo-intro/lua-version"
logodb = tmp .. "/logo-links/logo-links.db"
logoupdater_cfg = "/var/tuxbox/config/logoupdater.cfg"

function exists(file)
	local ok, err, exitcode = os.rename(file, file)
	if not ok then
		if exitcode == 13 then
		-- Permission denied, but it exists
		return true
		end
	end
	return ok, err
end

function isdir(path)
	return exists(path .. "/")
end

function create_logoupdater_cfg()
	file = io.open(logoupdater_cfg, "w")
	file:write("eventlogos=1", "\n")
	file:write("popuplogos=0", "\n")
	file:write("use_git=0", "\n")
	file:write("keep_files=0", "\n")
	file:close()
end

if (exists(logoupdater_cfg) ~= true) then
	create_logoupdater_cfg()
end

function get_cfg_value(str)
	for line in io.lines(logoupdater_cfg) do
		if line:match(str .. "=") then
			local i,j = string.find(line, str .. "=")
			r = tonumber(string.sub(line, j+1, #line))
		end
	end
	return r
end

if (get_cfg_value("use_git") == 1) then
	logo_url = "https://github.com/neutrino-images/ni-logo-stuff"
else
	logo_url = "https://codeload.github.com/neutrino-images/ni-logo-stuff/zip/master"
end

function nconf_value(str)
	for line in io.lines(neutrino_conf) do
		if line:match(str .. "=") then
			local i,j = string.find(line, str .. "=")
			value = string.sub(line, j+1, #line)
		end
	end
	return value
end

lang = nconf_value("language")
if locale[lang] == nil then
	lang = "english"
end
logodir = nconf_value("logo_hdd_dir")
timing_menu = nconf_value("timing.menu")

function sleep(a) 
	local sec = tonumber(os.clock() + a); 
	while (os.clock() < sec) do 
	end 
end

function show_error(msg)
	ret = hintbox.new { title = caption, icon = "settings", text = msg };
	ret:paint();
	sleep(3);
	ret:hide();
end

function start_update()
	chooser:hide()
	if (isdir(tmp) == true) then os.execute("rm -rf " .. tmp) end
	local ret = hintbox.new { title = caption, icon = "settings", text = locale[lang].fetch_source };
	ret:paint();
	if (get_cfg_value("use_git") == 1) then 
		ok ,err, exitcode = os.execute("git clone " .. logo_url .. " " .. tmp)
	else
		ok ,err, exitcode = os.execute("curl " .. logo_url .. " -o " .. tmp .. ".zip")
		if (exists(tmp) ~= true) then
			os.execute("mkdir " .. tmp)
		end
		os.execute("unzip -x " .. tmp .. ".zip -d " .. tmp)
		local glob = require "posix".glob
		for _, j in pairs(glob(tmp .. "/*", 0)) do
			os.execute("mv -f " .. j .. "/* " .. tmp)
		end
		os.execute("rm -rf " .. tmp .. ".zip")
	end

	if (exitcode ~= 0) then
		ret:hide()
		show_error(locale[lang].fetch_failed)
		return
	else
		ret:hide();
	end

	os.execute("rsync -rlpgoD --size-only " .. logo_intro .. "/logoupdater_" .. nconf_value("osd_resolution") .. ".png " .. icondir .. "/logoupdater.png")
	
	local ret = hintbox.new { title = caption, icon = "settings", text = locale[lang].copy_logos };
	ret:paint();
	local delete = ""
	if (get_cfg_value("keep_files") == 0) then delete = "--delete " end 
	local ok,err,exitcode = os.execute("rsync -rlpgoD --size-only " .. delete .. logo_source .. "/ " .. logodir)
	sleep(1);
	if (exitcode ~= 0) then
		ret:hide()
		show_error(locale[lang].copy_failed)
		return
	else
		ret:hide();
	end

	if (get_cfg_value("eventlogos") == 1) then
		local ret = hintbox.new { title = caption, icon = "settings", text = locale[lang].copy_eventlogos };
		ret:paint();
		local ok,err,exitcode = os.execute("rsync -rlpgoD --size-only " .. delete .. logo_event_source .. "/* " .. logodir)
		sleep(1);
		if (exitcode ~= 0) then
			ret:hide()
			show_error(locale[lang].copy_failed)
			return
		else
			ret:hide();
		end
	end

	if (get_cfg_value("popuplogos") == 1) then
		local ret = hintbox.new { title = caption, icon = "settings", text = locale[lang].copy_popuplogos };
		ret:paint();
		local ok,err,exitcode = os.execute("rsync -rlpgoD --size-only " .. delete .. logo_popup_source .. "/* " .. logodir)
		sleep(1);
		if (exitcode ~= 0) then
			ret:hide()
			show_error(locale[lang].copy_failed)
			return
		else
			ret:hide();
		end
	end

	local ret = hintbox.new { title = caption, icon = "settings", text = locale[lang].link_logos };
	ret:paint();
	-- todo: implement lua-filesystem to improve linking performance
	local ok,err,exitcode = os.execute(logolinker .. " " .. logodb .. " " .. logodir)
	if (exitcode ~= 0) then
		ret:hide()
		show_error(locale[lang].link_failed)
		return
	else
		ret:hide();
	end	

	local ret = hintbox.new { title = caption, icon = "settings", text = locale[lang].cleanup };
	ret:paint();
	local ok,err,exitcode = os.execute("rm -rf " .. tmp)
	sleep(1);
	if (exitcode ~= 0) then
		ret:hide()
		show_error(locale[lang].cleanup_failed)
		return
	else
		ret:hide();
	end
end

function write_cfg(k, v, str)
	local a
	if (v == locale[lang].yes) then a = 1 else a = 0 end
	local cfg_content = {}
	for line in io.lines(logoupdater_cfg) do
		if line:match(str .. "=") then
			nline = string.reverse(string.gsub(string.reverse(line), string.sub(string.reverse(line), 1, 1), a, 1))
			table.insert (cfg_content, nline)
		else
			table.insert (cfg_content, line)
		end
	end
	file = io.open(logoupdater_cfg, 'w')
	for i, v in ipairs(cfg_content) do
		file:write(v, "\n")
	end
	io.close(file)
end

function eventlogos_cfg(k, v, str)
	write_cfg(k, v, "eventlogos")
end

function popuplogos_cfg(k, v, str) 
	write_cfg(k, v, "popuplogos")
end

function use_git_cfg(k, v, str) 
	write_cfg(k, v, "use_git")
end

function keep_files_cfg(k, v, str) 
	write_cfg(k, v, "keep_files")
end


function options ()
	chooser:hide()
	menu = menu.new{name=locale[lang].menu_options}
	menu:addItem{type="back"}
	menu:addItem{type="separatorline"}
	opt = {locale[lang].yes ,locale[lang].no}	
	if (get_cfg_value("eventlogos") == 1) then
		menu:addItem{type="chooser", action="eventlogos_cfg", options={opt[1], opt[2]}, id="ID1", icon=1, directkey=RC["1"], name=locale[lang].cfg_event}
	elseif (get_cfg_value("eventlogos") == 0) then
		menu:addItem{type="chooser", action="eventlogos_cfg", options={opt[2], opt[1]}, id="ID1", icon=1, directkey=RC["1"], name=locale[lang].cfg_event}
	end
	if (get_cfg_value("popuplogos") == 1) then
		menu:addItem{type="chooser", action="popuplogos_cfg", options={opt[1], opt[2]}, id="ID2", icon=2, directkey=RC["2"], name=locale[lang].cfg_popup}
	elseif (get_cfg_value("popuplogos") == 0) then
		menu:addItem{type="chooser", action="popuplogos_cfg", options={opt[2], opt[1]}, id="ID2", icon=2, directkey=RC["2"], name=locale[lang].cfg_popup}
	end
	if (get_cfg_value("use_git") == 1) then
		menu:addItem{type="chooser", action="use_git_cfg", options={opt[1], opt[2]}, id="ID3", icon=3, directkey=RC["3"], name=locale[lang].cfg_git}
	elseif (get_cfg_value("use_git") == 0) then
		menu:addItem{type="chooser", action="use_git_cfg", options={opt[2], opt[1]}, id="ID3", icon=3, directkey=RC["3"], name=locale[lang].cfg_git}
	end
	if (get_cfg_value("keep_files") == 1) then
		menu:addItem{type="chooser", action="keep_files_cfg", options={opt[1], opt[2]}, id="ID4", icon=4, directkey=RC["4"], name=locale[lang].cfg_keep}
	elseif (get_cfg_value("keep_files") == 0) then
		menu:addItem{type="chooser", action="keep_files_cfg", options={opt[2], opt[1]}, id="ID4", icon=4, directkey=RC["4"], name=locale[lang].cfg_keep}
	end
	menu:exec()
	main()
end

function main()
	chooser_dx = n:scale2Res(560)
	chooser_dy = n:scale2Res(350)
	chooser_x = SCREEN.OFF_X + (((SCREEN.END_X - SCREEN.OFF_X) - chooser_dx) / 2)
	chooser_y = SCREEN.OFF_Y + (((SCREEN.END_Y - SCREEN.OFF_Y) - chooser_dy) / 2)

	chooser = cwindow.new {
	x = chooser_x,
	y = chooser_y,
	dx = chooser_dx,
	dy = chooser_dy,
	icon = "settings",
	has_shadow = true,
	btnGreen = locale[lang].menu_update,
	btnRed = locale[lang].menu_options
	}
	picture = cpicture.new {
	parent = chooser,
	image="logoupdater",
	}
	chooser:paint()
	i = 0
	d = 500 -- ms
	t = (timing_menu * 1000) / d
	if t == 0 then
		t = -1 -- no timeout
	end
	colorkey = nil
	repeat
		i = i + 1
		msg, data = n:GetInput(d)
		if (msg == RC['red']) then
			options()
			colorkey = true
		elseif (msg == RC['green']) then
			start_update()
			colorkey = true
		end
	until msg == RC['home'] or colorkey or i == t
	chooser:hide()
end

main()
