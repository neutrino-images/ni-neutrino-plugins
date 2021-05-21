-- The Tuxbox Copyright
--
-- Copyright 2021 GetAway (get-away@t-online.de)
-- Copyright 2018 - 2019 Markus Volk (f_l_k@t-online.de)
-- Copyright 2018 Sven Hoefer, Don de Deckelwech
-- Redistribution and use in source and binary forms, with or without modification, 
-- are permitted provided that the following conditions are met:
--
-- Redistributions of source code must retain the above copyright notice, this list
-- of conditions and the following disclaimer. Redistributions in binary form must
-- reproduce the above copyright notice, this list of conditions and the following
-- disclaimer in the documentation and/or other materials provided with the distribution.
--
-- THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS ``AS IS`` AND ANY EXPRESS OR IMPLIED
-- WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
-- AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
-- HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
-- EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
-- SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
-- HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
-- OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
-- SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
--
-- The views and conclusions contained in the software and documentation are those of the
-- authors and should not be interpreted as representing official policies, either expressed
-- or implied, of the Tuxbox Project.

version = "v1.20f"

on = "ein"; off = "aus"

function exists(file)
	return fh:exist(file, "f")
end

function isdir(path)
	return fh:exist(path, "d")
end

function islink(path)
	return fh:exist(path, "l")
end

function mkdir(path)
	fh:mkdir(path)
end

function rmdir(path)
	fh:rmdir(path)
end

function mount(dev,destination)
	local provider = fh:readlink("/bin/mount")
	if (provider == nil) or not string.match(provider, "busybox") then
		os.execute("mount -l " .. dev .. " " .. destination)
	else
		os.execute("mount " .. dev .. " " .. destination)
	end
end

function umount(path)
	local provider = fh:readlink("/bin/umount")
	if (provider == nil) or not string.match(provider, "busybox") then
		os.execute("umount -l " .. path)
	else
		os.execute("umount " .. path)
	end
end

function link(source,destination)
	fh:ln(source,destination,"sf")
end

function is_mounted(path)
	for line in io.lines("/proc/self/mountinfo") do
		if line:match(path) then
			return true
		end
	end
end

function mount_filesystems()
	for _,v in ipairs(partlabels) do
		if islink(partitions_by_name .. "/" .. v) then
			mkdir("/tmp/testmount/" .. v)
			mount(partitions_by_name .. "/" .. v,"/tmp/testmount/" .. v)
		end
	end
	if not has_gpt_layout() then
		if is_mounted("/tmp/testmount/linuxrootfs") then
			link("/tmp/testmount/linuxrootfs/linuxrootfs1","/tmp/testmount/linuxrootfs1")
		else
			link("/tmp/testmount/userdata/linuxrootfs1","/tmp/testmount/linuxrootfs1")
		end
		link("/tmp/testmount/userdata/linuxrootfs2","/tmp/testmount/linuxrootfs2")
		link("/tmp/testmount/userdata/linuxrootfs3","/tmp/testmount/linuxrootfs3")
		link("/tmp/testmount/userdata/linuxrootfs4","/tmp/testmount/linuxrootfs4")
	end
end

function umount_filesystems()
	for _,v in ipairs(partlabels) do
		if islink(partitions_by_name .. "/" .. v) then
			umount("/tmp/testmount/" .. v)
		end
		if is_mounted("/tmp/testmount/" .. v) then
			print("umount failed")
			return false
		end
	end
	rmdir("/tmp/testmount")
end

function sleep(n)
	os.execute("sleep " .. tonumber(n))
end

function reboot()
	umount_filesystems()
	if exists("/bin/systemctl") then
		local file = assert(io.popen("systemctl reboot"))
	elseif exists("/sbin/init") then
		local file = assert(io.popen("sync && init 6"))
	else
		local file = assert(io.popen("reboot"))
	end
end

function basename(str)
	local name = string.gsub(str, "(.*/)(.*)", "%2")
	return name
end

function get_value(str,root,etcdir)
	local value = ""
	if is_mounted("/tmp/testmount/userdata") then
		for line in io.lines("/tmp/testmount/linuxrootfs" .. root  .. etcdir .. "/image-version") do
			if line:match(str .. "=") then
				local i,j = string.find(line, str .. "=")
				value = string.sub(line, j+1, #line)
			end
		end
	elseif is_mounted("/tmp/testmount/rootfs" .. root) then
		for line in io.lines("/tmp/testmount/rootfs" .. root  .. etcdir .. "/image-version") do
			if line:match(str .. "=") then
				local i,j = string.find(line, str .. "=")
				value = string.sub(line, j+1, #line)
			end
		end
	end
	return value
end

function get_imagename(root)
	local etc_isdir = false
	local imagename = ""
	local imageversion = ""
	local tmp_version = ""
	local tmp_name = ""

	local etc = "/etc"
	if isdir("/tmp/testmount/linuxrootfs" .. root .. etc) or isdir("/tmp/testmount/rootfs" .. root .. etc) then
		etc_isdir = true
	end

	if etc_isdir and (exists("/tmp/testmount/linuxrootfs" .. root .. "/etc/image-version") or exists("/tmp/testmount/rootfs" .. root  .. "/etc/image-version")) then
		tmp_name = get_value("distro", root, etc)
		if tmp_name == "" then
			tmp_name = get_value("creator", root, etc)
		end
		tmp_version = get_value("imageversion", root, etc)
		if tmp_version == "" then
			tmp_version = get_value("version", root, etc)
		end
	elseif exists("/tmp/testmount/linuxrootfs" .. root .. "/var/etc/image-version") or exists("/tmp/testmount/rootfs" .. root  .. "/var/etc/image-version") then
		etc = "/var/etc"
		tmp_name = get_value("distro", root, etc)
		if tmp_name == "" then
			tmp_name = get_value("creator", root, etc)
		end
		tmp_version = get_value("imageversion", root, etc)
		if tmp_version == "" then
			tmp_version = get_value("version", root, etc)
		end
	end

	imagename = tmp_name .. " " .. tmp_version

	if imagename == " " then
		local glob = require "posix".glob
		imagename = "NOT FOUND"
		for _, j in pairs(glob(boot .. '/*', 0)) do
			if not isdir(j) and not islink(j) then
				for line in io.lines(j) do
					io.write(string.format("j =  %s \n", j))
					if (j ~= boot .. "/STARTUP") and (j ~= nil) and not line:match("boxmode=12") and not line:match("android") then
						if line:match(devbase .. image_to_devnum(root)) then
							imagename = basename(j)
						end
					end
				end
			end
		end
-- 		io.write(string.format("boot .. '/*' = [ %s ], imagename = [ %s ]\n", boot .. '/*', imagename))
-- 	else
-- 		io.write(string.format("boot = [ %s ], imagename = [ %s ]\n", boot, imagename))
	end
	return imagename
end

function is_active(root)
	if (current_root == root) then
		active = " *"
	else
		active = ""
	end
	return active
end

function has_gpt_layout()
	io.write(string.format("devbase = [ %s ]\n", devbase))
	if (devbase ~= "linuxrootfs") then
		return true
	else
		return false
	end
end

function has_boxmode()
	for line in io.lines("/proc/cpuinfo") do
		if line:match("Broadcom") then
			return true
		end
	end
	return false
end

function devnum_to_image(root)
	if (has_gpt_layout()) then
		if (root == 3) then ret = 1 end
		if (root == 5) then ret = 2 end
		if (root == 7) then ret = 3 end
		if (root == 9) then ret = 4 end
	else
		ret = root
	end
	return ret
end

function image_to_devnum(root)
	if (has_gpt_layout()) then
		if (root == 1) then ret = 3 end
		if (root == 2) then ret = 5 end
		if (root == 3) then ret = 7 end
		if (root == 4) then ret = 9 end
	else
		ret = root
	end
	return ret
end

function get_cfg_value(str, part)
	for line in io.lines("/tmp/testmount/".. devbase .. part .. tuxbox_cfg[part] .. "/stb-startup.conf") do
		if line:match(str .. "=") then
			local i,j = string.find(line, str .. "=")
			r = tonumber(string.sub(line, j+1, #line))
		end
	end
	return r
end

function tableOnOff(part)
	t = {off, on}
	if tuxbox_cfg[part] == nil then
		return t
	end

	local cfg_enabled = off
	if exists("/tmp/testmount/" .. devbase .. part .. tuxbox_cfg[part] .. "/stb-startup.conf") then
		if (get_cfg_value("boxmode_12", part, tuxbox_cfg[part]) == 1) then
			t = {on, off}
		end
	end
	return t
end

function create_cfg(part)
	file = io.open("/tmp/testmount/" .. devbase .. part .. tuxbox_cfg[part] .. "/stb-startup.conf", "w")
	file:write("boxmode_12=0", "\n")
	file:close()
end

function write_cfg(k, v, str)
	local part = tonumber(k)
	local a
	if (v == on) then a = 1 else a = 0 end
	local cfg_content = {}
	for line in io.lines("/tmp/testmount/".. devbase .. part .. tuxbox_cfg[part] .. "/stb-startup.conf") do
		if line:match(str .. "=") then
			table.insert (cfg_content, (string.reverse(string.gsub(string.reverse(line), string.sub(string.reverse(line), 1, 1), a, 1))))
		else
			table.insert (cfg_content, line)
		end
	end
	file = io.open("/tmp/testmount/".. devbase .. part .. tuxbox_cfg[part] .. "/stb-startup.conf", 'w')
	for i, v in ipairs(cfg_content) do
		file:write(v, "\n")
	end
	io.close(file)
end

function get_cmdline_value(str)
	for line in io.lines("/proc/cmdline") do
		if line:match(str) then
			return true
		end
	end
	return false
end

function set(k, v)
	write_cfg(k, v, "boxmode_12")
end

function get_tuxbox_cfgdir(part)
	if isdir("/tmp/testmount/" .. devbase .. part .. tuxbox_config) then
		return tuxbox_config
	elseif exists("/tmp/testmount/" .. devbase .. part .. tuxbox_config) then
		return fh:readlink("/tmp/testmount/" .. devbase .. part .. tuxbox_config)
	elseif isdir("/tmp/testmount/" .. devbase .. part .. "/etc/neutrino/config") then
		return "/etc/neutrino/config"
	else
		return ""
	end
end

function get_boot_path()
	path_boot = "/tmp/testmount/boot"
	path_boot_options = "/tmp/testmount/bootoptions"
	ret = path_boot_options
	if islink(partitions_by_name .. "/boot") then
		ret = path_boot
	end
	return ret
end

function get_devbase()
	local devbase
	if isdir("/dev/disk/by-partlabel") then
		partitions_by_name = "/dev/disk/by-partlabel"
	elseif isdir("/dev/block/by-name") then
		partitions_by_name = "/dev/block/by-name"
	end
	io.write(string.format("partitions_by_name = [ %s ]\n", partitions_by_name))
	if islink(partitions_by_name .. "/rootfs1") then
		for line in io.lines("/proc/cmdline") do
			if line:match("root=") then
				local _,j = string.find(line, "root=")
				devbase = string.sub(line, j+1, j+13)
			end
		end
	else
		devbase = "linuxrootfs"
	end
	return devbase
end

function main()
	caption = "STB-Startup" .. " " .. version
	partlabels = {"linuxrootfs","userdata","rootfs1","rootfs2","rootfs3","rootfs4","boot","bootoptions"}
	n = neutrino()
	fh = filehelpers.new()

	locale = {}
	locale["deutsch"] = {
		current_boot_partition = "Die aktuelle Startpartition ist: ",
		choose_partition = "\n\nBitte wählen Sie die neue Startpartition aus",
		start_partition = "Rebooten und die gewählte Partition starten?",
		empty_partition = "Das gewählte Image ist nicht vorhanden",
		options = "Einstellungen",
		boxmode = "Boxmode 12",
		image = "Imagewechsel",
		boxmode = "Boxmodewechsel",
		image_and_boxmode = "Image- und Boxmodewechsel",
		hinttext = " %s in STARTUP geschrieben!!\n\nReboot des Images >> %s <<\n\nmit Boxmode %s in %s Sek."
	}

	locale["english"] = {
		current_boot_partition = "The current boot partition is: ",
		choose_partition = "\n\nPlease choose the new boot partition",
		start_partition = "Reboot and start the chosen partition?",
		empty_partition = "No image available",
		options = "Options",
		boxmode = "Boxmode 12",
		image = "Wrote Image changing",
		boxmode = "Wrote Image changing",
		image_and_boxmode = "Wrote Image- and Boxmode changing",
		hinttext = " %s to STARTUP!!\n\nReboot of Image >> %s <<\n\nwith Boxmode %s in %s sec."
	}

	tuxbox_config = "/var/tuxbox/config"
	neutrino_conf = configfile.new()
	neutrino_conf:loadConfig(tuxbox_config .. "/neutrino.conf")
	lang = neutrino_conf:getString("language", "english")

	if locale[lang] == nil then
		lang = "english"
	end

	devbase = get_devbase()
	boot = get_boot_path()

	for line in io.lines("/proc/cmdline") do
		_, j = string.find(line, devbase)
		if (j ~= nil) then
			current_root = devnum_to_image(tonumber(string.sub(line,j+1,j+1)))
		end
	end

	mount_filesystems()

	timing_menu = neutrino_conf:getString("timing.menu", "0")

	chooser_dx = n:scale2Res(800)
	chooser_dy = n:scale2Res(200)
	chooser_x = SCREEN.OFF_X + (((SCREEN.END_X - SCREEN.OFF_X) - chooser_dx) / 2)
	chooser_y = SCREEN.OFF_Y + (((SCREEN.END_Y - SCREEN.OFF_Y) - chooser_dy) / 2)

	local imagename = {}
	tuxbox_cfg = {}
	for n=1, 4 do
		imagename[n] = get_imagename(n) .. is_active(n)
		tuxbox_cfg[n] = get_tuxbox_cfgdir(n)
		if tuxbox_cfg[n] ~= "" and not exists("/tmp/testmount/" .. devbase .. n .. tuxbox_cfg[n] .. "/stb-startup.conf") and has_boxmode() then
			create_cfg(n)
		end
	end

	local current_mode = off
	local cfg_mode = off
	if (get_cmdline_value("boxmode=12")) then
		current_mode = on
	end
	if (get_cfg_value("boxmode_12", current_root, tuxbox_cfg[current_root]) == 1) then
		cfg_mode = on
	end
	--print(current_mode, cfg_mode, current_root)
	if (current_mode ~= cfg_mode) then
		write_cfg(current_root, current_mode, "boxmode_12")
	end

	chooser = cwindow.new {
		x = chooser_x,
		y = chooser_y,
		dx = chooser_dx,
		dy = chooser_dy,
		title = caption,
		icon = "settings",
		has_shadow = true,
		btnRed = imagename[1],
		btnGreen = imagename[2],
		btnYellow = imagename[3],
		btnBlue = imagename[4],
		btnSetup = "Boxmode"
	}

	chooser_text = ctext.new {
		parent = chooser,
		x = OFFSET.INNER_MID,
		y = OFFSET.INNER_SMALL,
		dx = chooser_dx - 2*OFFSET.INNER_MID,
		dy = chooser_dy - chooser:headerHeight() - chooser:footerHeight() - 2*OFFSET.INNER_SMALL,
		text = locale[lang].current_boot_partition .. get_imagename(current_root) .. locale[lang].choose_partition,
		font_text = FONT.MENU,
		mode = "ALIGN_CENTER"
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
				root = 1
			colorkey = true
		elseif (msg == RC['green']) then
				root = 2
			colorkey = true
		elseif (msg == RC['yellow']) then
				root = 3
			colorkey = true
		elseif (msg == RC['blue']) then
				root = 4
			colorkey = true
		elseif has_boxmode() and (msg == RC['setup']) then
			chooser:hide()
			menu = menu.new{icon="settings", name=locale[lang].options}
			menu:addItem{type="back"}
			menu:addItem{type="separatorline", name="Boxmode 12"}
			menu:addItem{type="chooser", action="set", id="1", options=tableOnOff(1), enabled=isdir("/tmp/testmount/" .. devbase .. "1" .. tuxbox_cfg[1]), directkey=RC["red"], name=imagename[1]}
			menu:addItem{type="chooser", action="set", id="2", options=tableOnOff(2), enabled=isdir("/tmp/testmount/" .. devbase .. "2" .. tuxbox_cfg[2]), directkey=RC["green"], name=imagename[2]}
			menu:addItem{type="chooser", action="set", id="3", options=tableOnOff(3), enabled=isdir("/tmp/testmount/" .. devbase .. "3" .. tuxbox_cfg[3]), directkey=RC["yellow"], name=imagename[3]}
			menu:addItem{type="chooser", action="set", id="4", options=tableOnOff(4), enabled=isdir("/tmp/testmount/" .. devbase .. "4" .. tuxbox_cfg[4]), directkey=RC["blue"], name=imagename[4]}
			menu:exec()
			chooser:paint()
		end
	until msg == RC['home'] or colorkey or i == t
	chooser:hide()

	if colorkey then
		if islink("/tmp/testmount/" .. devbase .. root) then
			-- found image folder
		elseif isdir("/tmp/testmount/rootfs" .. root) then
			-- found image folder
		else
			local ret = hintbox.new { title = caption, icon = "settings", text = locale[lang].empty_partition };
			ret:paint();
			umount_filesystems()
			sleep(3)
			return
		end
		res = messagebox.exec {
		title = caption,
		icon = "settings",
		text = locale[lang].start_partition,
		timeout = 0,
		buttons={ "yes", "no" }
		}
	end

	if res == "yes" then
		local glob = require "posix".glob
		local startup_lines = {}

		io.write(string.format("boot =  %s \n", boot))
		for _, j in pairs(glob(boot .. '/*')) do
			for line in io.lines(j) do
				if (j ~= boot .. "/STARTUP") and (j ~= nil) and not line:match("boxmode=12") and not line:match("android") then
					if line:match(devbase .. image_to_devnum(root)) then
						startup_file = j
					end
				end
			end
		end
		for line in io.lines(startup_file) do
			if has_boxmode() then
				-- remove existing brcm_cma entries
				line = line:gsub(string.sub(line, string.find(line, " '")+2, string.find(line, "root=")-1), "")
				-- re-add new brcm_cma and boxmode entries
				if get_cfg_value("boxmode_12", root, tuxbox_cfg[root]) == 1 then
					line = line:gsub(" '", " 'brcm_cma=520M@248M brcm_cma=192M@768M ")
					line = line:gsub(string.sub(line, string.find(line, "boxmode=")+8), "12'")
					cfg_mode = on
					mode = "12"
				else
					line = line:gsub(string.sub(line, string.find(line, "boxmode=")+8), "1'")
					cfg_mode = off
					mode = "1"
				end
			else
				cfg_mode = off
				mode = "1"
			end
			table.insert(startup_lines, line)
		end

		file = io.open(boot .. "/STARTUP", 'w')
		for _, v in ipairs(startup_lines) do
			file:write(v, "\n")
		end
		file:close()

		if (current_root ~= root and current_mode ~= cfg_mode ) then
			txt = locale[lang].image_and_boxmode
		elseif (current_root ~= root) then
			txt = locale[lang].image
		else
			txt = locale[lang].boxmode
		end
		local stime = 5
		hbtext = string.format(locale[lang].hinttext, txt, imagename[root], mode, tostring(stime))
		local hb = hintbox.new{ title="Info", text=hbtext, icon="info", has_shadow=true, show_footer=false}
		hb:paint()
		sleep(stime)
		hb:hide()
		reboot()
	end
	umount_filesystems()
	return
end

main()
