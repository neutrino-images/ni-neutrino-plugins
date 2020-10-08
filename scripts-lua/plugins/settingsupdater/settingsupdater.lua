--[[ The Tuxbox Copyright
 Copyright 2019 Markus Volk, Horsti58
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

caption = "Settings Updater"

local on = "ein"
local off = "aus"

locale = {}
locale["deutsch"] = {
fetch_source = "Die aktuellen Senderlisten werden geladen",
fetch_failed = "Download fehlgeschlagen",
write_settings = "Die ausgewählten Senderlisten werden geschrieben",
cleanup = "Temporäre Dateien werden gelöscht",
cleanup_failed = "Temporäre Dateien konnten nicht entfernt werden",
menu_options = "Einstellungen",
menu_update = "Update starten",
cfg_install_a = "Senderliste ",
cfg_install_b = " installieren",
cfg_ubouquets = "uBouquets installieren",
cfg_git = "Git für den Download verwenden",
last_update = "Letztes Update: ",
update_available = "Aktualisierung verfügbar"
}
locale["english"] = {
fetch_source = "The latest settings are getting downloaded",
fetch_failed = "Download failed",
write_settings = "Writing the selected settings  to its destination",
cleanup = "Cleanup temporary files",
cleanup_failed = "Cleanup data failed",
menu_options = "Options",
menu_update = "Start update",
cfg_install_a = "Install ",
cfg_install_b = " settings",
cfg_ubouquets = "Install ubouqets",
cfg_git = "Use git for downloading",
last_update = "Last update: ",
update_available = "Update available"
}

n = neutrino()
fh = filehelpers.new()
tmp = "/tmp/settingupdate"
neutrino_conf_base = "/var/tuxbox/config"
icondir = "/share/tuxbox/neutrino/icons"
neutrino_conf = neutrino_conf_base .. "/neutrino.conf"
zapitdir = neutrino_conf_base .. "/zapit"
setting_intro = tmp .. "/lua"
settingupdater_cfg = neutrino_conf_base .. "/settingupdater.cfg"

function exists(file)                                                                     
        return fh:exist(file, "f")                                   
end                                                                  
                                                                     
function isdir(path)                                                 
        return fh:exist(path, "d")                                   
end

function create_settingupdater_cfg()
	file = io.open(settingupdater_cfg, "w")
	file:write("28.2E=0", "\n")
	file:write("26.0E=0", "\n")
	file:write("23.5E=0", "\n")
	file:write("19.2E=1", "\n")
	file:write("16.0E=0", "\n")
	file:write("13.0E=0", "\n")
	file:write("9.0E=0", "\n")
	file:write("7.0E=0", "\n")
	file:write("4.8E=0", "\n")
	file:write("0.8W=0", "\n")
	file:write("Vodafone=0", "\n")
	file:write("use_git=0", "\n")
	file:close()
end

if (exists(settingupdater_cfg) ~= true) then
	create_settingupdater_cfg()
end

function last_updated()
	if exists(zapitdir .. "/services.xml") then
		for line in io.lines(zapitdir .. "/services.xml") do
			if line:match(",") and line:match(":") then
				local _,mark_begin = string.find(line, ",")
				local _,mark_end = string.find(line, ":")
				date = string.sub(line,mark_begin+6, mark_end-3)
				found = true
			end
		end
	end
	if not found then date = "" end
	return date
end

function check_for_update()
	if not isdir(tmp) then os.execute("mkdir -p " .. tmp) end
	os.execute("curl https://raw.githubusercontent.com/horsti58/lua-data/master/start/services.xml -o " .. tmp .. "/version_online")
	for line in io.lines(tmp .. "/version_online") do
		if line:match(",") and line:match(":") then
			local _,mark_begin = string.find(line, ",")
			local _,mark_end = string.find(line, ":")
			online_date = string.sub(line,mark_begin+6, mark_end-3)
 		end
	end
	if last_updated() ~= online_date then
		os.execute("rm -rf " .. tmp)
		return true
	end
	os.execute("rm -rf " .. tmp)
end

function get_cfg_value(str)
	for line in io.lines(settingupdater_cfg) do
		if line:match(str .. "=") then
			local i,j = string.find(line, str .. "=")
			r = tonumber(string.sub(line, j+1, #line))
		end
	end
	return r
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

timing_menu = nconf_value("timing.menu")

function sleep(n)
	os.execute("sleep " .. tonumber(n))
end

function show_msg(msg)
	ret = hintbox.new { title = caption, icon = "settings", text = msg };
	ret:paint();
	sleep(1);
	ret:hide();
end

function execute_command(command)
    local tmpfile = '/tmp/lua_execute_tmp_file'
    local exit = os.execute(command .. ' > ' .. tmpfile .. ' 2> ' .. tmpfile .. '.err')

    local stdout_file = io.open(tmpfile)
    local stdout = stdout_file:read("*all")

    local stderr_file = io.open(tmpfile .. '.err')
    local stderr = stderr_file:read("*all")

    stdout_file:close()
    stderr_file:close()

    return exit, stdout, stderr
end

function start_update()
	chooser:hide()
	if (isdir(tmp) == true) then os.execute("rm -rf " .. tmp) end
	local ret = hintbox.new { title = caption, icon = "settings", text = locale[lang].fetch_source };
	ret:paint();
	if (get_cfg_value("use_git") == 1) then
		setting_url = "https://github.com/horsti58/lua-data"
		success = execute_command("git clone " .. setting_url .. " " .. tmp)
	else
		setting_url = "https://codeload.github.com/horsti58/lua-data/zip/master"
		success = execute_command("curl " .. setting_url .. " -o " .. tmp .. ".zip")
		if (exists(tmp) ~= true) then
			os.execute("mkdir " .. tmp)
		end
		os.execute("unzip -x " .. tmp .. ".zip -d " .. tmp)
		local glob = require "posix".glob
		for _, j in pairs(glob(tmp .. "/*")) do
			os.execute("mv -f " .. j .. "/* " .. tmp)
		end
		os.execute("rm -rf " .. tmp .. ".zip")
	end

	if not success then
		ret:hide()
		show_msg(locale[lang].fetch_failed)
		return
	else
		ret:hide();
	end
	local success = execute_command("rsync -rlpgoD --size-only " .. setting_intro .. "/settingupdater_" .. nconf_value("osd_resolution") .. ".png " .. icondir .. "/settingupdater.png")
	if not success then
		ret:hide()
		print("rsync missing?")
		os.execute("cp -f " .. setting_intro .. "/settingupdater_" .. nconf_value("osd_resolution") .. ".png " .. icondir .. "/settingupdater.png")
	else
		ret:hide();
	end
	local ret = hintbox.new { title = caption, icon = "settings", text = locale[lang].write_settings};
	ret:paint();
	local positions ={}
	table.insert (positions, "start")
	if (get_cfg_value("28.2E") == 1) then table.insert (positions, "28.2E"); have_sat = 1 end
	if (get_cfg_value("26.0E") == 1) then table.insert (positions, "26.0E"); have_sat = 1 end
	if (get_cfg_value("23.5E") == 1) then table.insert (positions, "23.5E"); have_sat = 1 end
	if (get_cfg_value("19.2E") == 1) then table.insert (positions, "19.2E"); have_sat = 1 end
	if (get_cfg_value("16.0E") == 1) then table.insert (positions, "16.0E"); have_sat = 1 end
	if (get_cfg_value("13.0E") == 1) then table.insert (positions, "13.0E"); have_sat = 1 end
	if (get_cfg_value("9.0E") == 1) then table.insert (positions, "9.0E"); have_sat = 1 end
	if (get_cfg_value("7.0E") == 1) then table.insert (positions, "7.0E"); have_sat = 1 end
	if (get_cfg_value("4.8E") == 1) then table.insert (positions, "4.8E"); have_sat = 1 end
	if (get_cfg_value("0.8W") == 1) then table.insert (positions, "0.8W"); have_sat = 1 end
	if (get_cfg_value("Vodafone") == 1) then table.insert (positions, "UnityMedia"); have_cable = 1 end
	table.insert (positions, "end")

	bouquets = io.open(zapitdir .. "/bouquets.xml", 'w')
	services = io.open(zapitdir .. "/services.xml", 'w')
 	if have_sat == 1 then satellites = io.open(neutrino_conf_base .. "/satellites.xml", 'w') end
	if have_cable == 1 then cables = io.open(neutrino_conf_base .. "/cables.xml", 'w') end

	for i, v in ipairs(positions) do
		for line in io.lines(tmp .. "/" .. v .. "/bouquets.xml") do
			bouquets:write(line, "\n")
		end
		for line in io.lines(tmp .. "/" .. v .. "/services.xml") do
			services:write(line, "\n")
		end
		if exists(tmp .. "/" .. v .. "/satellites.xml") and have_sat == 1 then
			for line in io.lines(tmp .. "/" .. v .. "/satellites.xml") do
				satellites:write(line, "\n")
			end
		end
		if exists(tmp .. "/" .. v .. "/cables.xml") and have_cable == 1 then
			for line in io.lines(tmp .. "/" .. v .. "/cables.xml") do
				cables:write(line, "\n")
			end
		end
	end

	bouquets:close()
	services:close()
	if have_sat == 1 then satellites:close() end
	if have_cable == 1 then cables:close() end
	os.execute("pzapit -c ")
	sleep(1)
	ret:hide()
	local ret = hintbox.new { title = caption, icon = "settings", text = locale[lang].cleanup };
	ret:paint()
	local success = execute_command("rm -r " .. tmp)
	sleep(1);
	if not success then
		ret:hide()
		show_msg(locale[lang].cleanup_failed)
		return
	else
		ret:hide()
	end
end

function write_cfg(k, v, str)
	if (v == on) then a = 1 else a = 0 end
	local cfg_content = {}
	for line in io.lines(settingupdater_cfg) do
		if line:match(str .. "=") then
			nline = string.reverse(string.gsub(string.reverse(line), string.sub(string.reverse(line), 1, 1), a, 1))
			table.insert (cfg_content, nline)
		else
			table.insert (cfg_content, line)
		end
	end
	file = io.open(settingupdater_cfg, 'w')
	for i, v in ipairs(cfg_content) do
		file:write(v, "\n")
	end
	io.close(file)
end

function astra_gb_cfg(k, v, str)
	write_cfg(k, v, "28.2E")
end

function badr_cfg(k, v, str)
	write_cfg(k, v, "26.0E")
end

function astra_nl_cfg(k, v, str)
	write_cfg(k, v, "23.5E")
end

function astra_cfg(k, v, str)
	write_cfg(k, v, "19.2E")
end

function eutelsatc_cfg(k, v, str)
	write_cfg(k, v, "16.0E")
end

function hotbird_cfg(k, v, str)
	write_cfg(k, v, "13.0E")
end

function eutelsata_cfg(k, v, str)
	write_cfg(k, v, "9.0E")
end

function eutelsatb_cfg(k, v, str)
	write_cfg(k, v, "7.0E")
end

function astraa_cfg(k, v, str)
	write_cfg(k, v, "4.8E")
end

function thor_cfg(k, v, str)
	write_cfg(k, v, "0.8W")
end

function kab_cfg(k, v, str)
	write_cfg(k, v, "Vodafone")
end

function use_git_cfg(k, v, str)
	write_cfg(k, v, "use_git")
end

function options ()
	chooser:hide()
	menu = menu.new{name=locale[lang].menu_options}
	menu:addItem{type="back"}
	menu:addItem{type="separatorline"}
	if (get_cfg_value("28.2E") == 1) then
		menu:addItem{type="chooser", action="astra_gb_cfg", options={on, off}, icon=1, directkey=RC["1"], name=locale[lang].cfg_install_a .. " 28.2E " .. locale[lang].cfg_install_b}
	elseif (get_cfg_value("28.2E") == 0) then
		menu:addItem{type="chooser", action="astra_gb_cfg", options={off, on}, icon=1, directkey=RC["1"], name=locale[lang].cfg_install_a .. " 28.2E " .. locale[lang].cfg_install_b}
	end
	if (get_cfg_value("26.0E") == 1) then
		menu:addItem{type="chooser", action="badr_cfg", options={on, off}, icon=2, directkey=RC["2"], name=locale[lang].cfg_install_a .. " 26.0E " .. locale[lang].cfg_install_b}
	elseif (get_cfg_value("26.0E") == 0) then
		menu:addItem{type="chooser", action="badr_cfg", options={off, on}, icon=2, directkey=RC["2"], name=locale[lang].cfg_install_a .. " 26.0E " .. locale[lang].cfg_install_b}
	end
	if (get_cfg_value("23.5E") == 1) then
		menu:addItem{type="chooser", action="astra_nl_cfg", options={on, off}, icon=3, directkey=RC["3"], name=locale[lang].cfg_install_a .. " 23.5E " .. locale[lang].cfg_install_b}
	elseif (get_cfg_value("23.5E") == 0) then
		menu:addItem{type="chooser", action="astra_nl_cfg", options={off, on}, icon=3, directkey=RC["3"], name=locale[lang].cfg_install_a .. " 23.5E " .. locale[lang].cfg_install_b}
	end
	if (get_cfg_value("19.2E") == 1) then
		menu:addItem{type="chooser", action="astra_cfg", options={on, off}, icon=4, directkey=RC["4"], name=locale[lang].cfg_install_a .. " 19.2E " .. locale[lang].cfg_install_b}
	elseif (get_cfg_value("19.2E") == 0) then
		menu:addItem{type="chooser", action="astra_cfg", options={off, on}, icon=4, directkey=RC["4"], name=locale[lang].cfg_install_a .. " 19.2E " .. locale[lang].cfg_install_b}
	end
	if (get_cfg_value("16.0E") == 1) then
		menu:addItem{type="chooser", action="eutelsatc_cfg", options={on, off}, icon=5, directkey=RC["5"], name=locale[lang].cfg_install_a .. " 16.0E " .. locale[lang].cfg_install_b}
	elseif (get_cfg_value("16.0E") == 0) then
		menu:addItem{type="chooser", action="eutelsatc_cfg", options={off, on}, icon=5, directkey=RC["5"], name=locale[lang].cfg_install_a .. " 16.0E " .. locale[lang].cfg_install_b}
	end
	if (get_cfg_value("13.0E") == 1) then
		menu:addItem{type="chooser", action="hotbird_cfg", options={on, off}, icon=6, directkey=RC["6"], name=locale[lang].cfg_install_a .. " 13.0E " .. locale[lang].cfg_install_b}
	elseif (get_cfg_value("13.0E") == 0) then
		menu:addItem{type="chooser", action="hotbird_cfg", options={off, on}, icon=6, directkey=RC["6"], name=locale[lang].cfg_install_a .. " 13.0E " .. locale[lang].cfg_install_b}
	end
	if (get_cfg_value("9.0E") == 1) then
		menu:addItem{type="chooser", action="eutelsata_cfg", options={on, off}, icon=7, directkey=RC["7"], name=locale[lang].cfg_install_a .. " 9.0E " .. locale[lang].cfg_install_b}
	elseif (get_cfg_value("9.0E") == 0) then
		menu:addItem{type="chooser", action="eutelsata_cfg", options={off, on}, icon=7, directkey=RC["7"], name=locale[lang].cfg_install_a .. " 9.0E " .. locale[lang].cfg_install_b}
	end
	if (get_cfg_value("7.0E") == 1) then
		menu:addItem{type="chooser", action="eutelsatb_cfg", options={on, off}, icon=8, directkey=RC["8"], name=locale[lang].cfg_install_a .. " 7.0E " .. locale[lang].cfg_install_b}
	elseif (get_cfg_value("7.0E") == 0) then
		menu:addItem{type="chooser", action="eutelsatb_cfg", options={off, on}, icon=8, directkey=RC["8"], name=locale[lang].cfg_install_a .. " 7.0E " .. locale[lang].cfg_install_b}
	end
	if (get_cfg_value("4.8E") == 1) then
		menu:addItem{type="chooser", action="astraa_cfg", options={on, off}, icon=9, directkey=RC["9"], name=locale[lang].cfg_install_a .. " 4.8E " .. locale[lang].cfg_install_b}
	elseif (get_cfg_value("4.8E") == 0) then
		menu:addItem{type="chooser", action="astraa_cfg", options={off, on}, icon=9, directkey=RC["9"], name=locale[lang].cfg_install_a .. " 4.8E " .. locale[lang].cfg_install_b}
	end
	if (get_cfg_value("0.8W") == 1) then
		menu:addItem{type="chooser", action="thor_cfg", options={on, off}, icon=0, directkey=RC["0"], name=locale[lang].cfg_install_a .. " 0.8W " .. locale[lang].cfg_install_b}
	elseif (get_cfg_value("0.8W") == 0) then
		menu:addItem{type="chooser", action="thor_cfg", options={off, on}, icon=0, directkey=RC["0"], name=locale[lang].cfg_install_a .. " 0.8W " .. locale[lang].cfg_install_b}
	end
	if (get_cfg_value("Vodafone") == 1) then
		menu:addItem{type="chooser", action="kab_cfg", options={on, off}, icon=yellow, directkey=RC["yellow"], name=locale[lang].cfg_install_a .. " Kabel " .. locale[lang].cfg_install_b}
	elseif (get_cfg_value("Vodafone") == 0) then
		menu:addItem{type="chooser", action="kab_cfg", options={off, on}, icon=yellow, directkey=RC["yellow"], name=locale[lang].cfg_install_a .. " Kabel " .. locale[lang].cfg_install_b}
	end
	if (get_cfg_value("use_git") == 1) then
		menu:addItem{type="chooser", action="use_git_cfg", options={on, off}, icon=blue, directkey=RC["blue"], name=locale[lang].cfg_git}
	elseif (get_cfg_value("use_git") == 0) then
		menu:addItem{type="chooser", action="use_git_cfg", options={off, on}, icon=blue, directkey=RC["blue"], name=locale[lang].cfg_git}
	end
	menu:exec()
	main()
end

if check_for_update() then show_msg(locale[lang].update_available) end

function main()
	chooser_dx = n:scale2Res(560)
	chooser_dy = n:scale2Res(350)
	chooser_x = SCREEN.OFF_X + (((SCREEN.END_X - SCREEN.OFF_X) - chooser_dx) / 2)
	chooser_y = SCREEN.OFF_Y + (((SCREEN.END_Y - SCREEN.OFF_Y) - chooser_dy) / 2)

	chooser = cwindow.new {
	caption = locale[lang].last_update .. last_updated(),
	x = chooser_x,
	y = chooser_y,
	dx = chooser_dx,
	dy = chooser_dy,
	icon = "settings",
	has_shadow = true,
	btnGreen = locale[lang].menu_update,
	btnRed = locale[lang].menu_options
	}

	image = icondir .. "/settingupdater.png"
	chooser:setBodyImage{image_path=image}

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

