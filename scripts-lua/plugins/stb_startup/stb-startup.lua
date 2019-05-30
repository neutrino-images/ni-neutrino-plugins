-- The Tuxbox Copyright
--
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

on = "ein"; off = "aus"

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
		if exists(partitions_by_name .. "/" .. v) then
			mkdir("/tmp/testmount/" .. v)
			mount(partitions_by_name .. "/" .. v,"/tmp/testmount/" .. v)
		end
	end
	if not has_gpt_layout() then
		link("/tmp/testmount/linuxrootfs/linuxrootfs1","/tmp/testmount/userdata/linuxrootfs1")
	end
end

function umount_filesystems()
	for _,v in ipairs(partlabels) do
		if exists(partitions_by_name .. "/" .. v) then
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
	elseif fh:exist("/sbin/init", "f") then
		local file = assert(io.popen("sync && init 6"))
	else
		local file = assert(io.popen("reboot"))
	end
end

function basename(str)
	local name = string.gsub(str, "(.*/)(.*)", "%2")
	return name
end

function get_value(str,part,etcdir)
	if is_mounted("/tmp/testmount/userdata") then
		for line in io.lines("/tmp/testmount/userdata/linuxrootfs" .. part  .. etcdir .. "/image-version") do
			if line:match(str .. "=") then
				local i,j = string.find(line, str .. "=")
				value = string.sub(line, j+1, #line)
			end
		end
	elseif is_mounted("/tmp/testmount/rootfs" .. part) then
		for line in io.lines("/tmp/testmount/rootfs" .. part  .. etcdir .. "/image-version") do
			if line:match(str .. "=") then
				local i,j = string.find(line, str .. "=")
				value = string.sub(line, j+1, #line)
			end
		end
	end
	return value
end

function get_imagename(root)
	if exists("/tmp/testmount/userdata/linuxrootfs" .. root .. "/etc/image-version") or
	exists("/tmp/testmount/rootfs" .. root  .. "/etc/image-version") then
		imagename = get_value("distro", root, "/etc") .. " " .. get_value("imageversion", root, "/etc")
	elseif exists("/tmp/testmount/userdata/linuxrootfs" .. root .. "/var/etc/image-version") or
	exists("/tmp/testmount/rootfs" .. root  .. "/var/etc/image-version") then
		imagename = get_value("distro", root, "/var/etc") .. " " .. get_value("imageversion", root, "/var/etc")
	else
		local glob = require "posix".glob
		for _, j in pairs(glob('/boot/*', 0)) do
			for line in io.lines(j) do
				if (j ~= bootfile) and (j ~= nil) and not line:match("boxmode=12") then
					if line:match(devbase .. image_to_devnum(root)) then
						imagename = basename(j)
					end
				end
			end
		end
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
	if (devbase == "linuxrootfs") then
		return false
	end
	return true
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

function get_cfg_value(str)
	for line in io.lines(tuxbox_config .. "/stb-startup.conf") do
		if line:match(str .. "=") then
			local i,j = string.find(line, str .. "=")
			r = tonumber(string.sub(line, j+1, #line))
		end
	end
	return r
end

function create_cfg()
	file = io.open(tuxbox_config .. "/stb-startup.conf", "w")
	file:write("boxmode_12=0", "\n")
	file:close()
end

function write_cfg(k, v, str)
	local a
	if (v == on) then a = 1 else a = 0 end
	local cfg_content = {}
	for line in io.lines(tuxbox_config .. "/stb-startup.conf") do
		if line:match(str .. "=") then
			table.insert (cfg_content, (string.reverse(string.gsub(string.reverse(line), string.sub(string.reverse(line), 1, 1), a, 1))))
		else
			table.insert (cfg_content, line)
		end
	end
	file = io.open(tuxbox_config .. "/stb-startup.conf", 'w')
	for i, v in ipairs(cfg_content) do
		file:write(v, "\n")
	end
	io.close(file)
end

function set(k, v, str)
	write_cfg(k, v, "boxmode_12")
end

function main()
	caption = "STB-Startup"
	partlabels = {"linuxrootfs","userdata","rootfs1","rootfs2","rootfs3","rootfs4"}
	bootfile = "/boot/STARTUP"
	n = neutrino()
	fh = filehelpers.new()

	locale = {}
	locale["deutsch"] = {
		current_boot_partition = "Die aktuelle Startpartition ist: ",
		choose_partition = "\n\nBitte wählen Sie die neue Startpartition aus",
		start_partition = "Rebooten und die gewählte Partition starten?",
		empty_partition = "Das gewählte Image ist nicht vorhanden",
		options = "Einstellungen",
		boxmode = "Boxmode 12"
	}

	locale["english"] = {
		current_boot_partition = "The current boot partition is: ",
		choose_partition = "\n\nPlease choose the new boot partition",
		start_partition = "Reboot and start the chosen partition?",
		empty_partition = "No image available",
		options = "Options",
		boxmode = "Boxmode 12"
	}

	tuxbox_config = "/var/tuxbox/config"
	neutrino_conf = configfile.new()
	neutrino_conf:loadConfig(tuxbox_config .. "/neutrino.conf")
	lang = neutrino_conf:getString("language", "english")

	if locale[lang] == nil then
		lang = "english"
	end

	if isdir("/dev/disk/by-partlabel") then
		partitions_by_name = "/dev/disk/by-partlabel"
	elseif isdir("/dev/block/by-name") then
		partitions_by_name = "/dev/block/by-name"
	end

	if exists(partitions_by_name .. "/rootfs1") then
		devbase = "/dev/mmcblk0p"
	else
		devbase = "linuxrootfs"
	end

	for line in io.lines("/proc/cmdline") do
		_, j = string.find(line, devbase)
		if (j ~= nil) then
			current_root = devnum_to_image(tonumber(string.sub(line,j+1,j+1)))
		end
	end

	if not exists(tuxbox_config .. "/stb-startup.conf") and has_boxmode() then
		create_cfg()
	end

	mount_filesystems()

	timing_menu = neutrino_conf:getString("timing.menu", "0")

	chooser_dx = n:scale2Res(700)
	chooser_dy = n:scale2Res(200)
	chooser_x = SCREEN.OFF_X + (((SCREEN.END_X - SCREEN.OFF_X) - chooser_dx) / 2)
	chooser_y = SCREEN.OFF_Y + (((SCREEN.END_Y - SCREEN.OFF_Y) - chooser_dy) / 2)

	chooser = cwindow.new {
		x = chooser_x,
		y = chooser_y,
		dx = chooser_dx,
		dy = chooser_dy,
		title = caption,
		icon = "settings",
		has_shadow = true,
		btnRed = get_imagename(1) .. is_active(1),
		btnGreen = get_imagename(2) .. is_active(2),
		btnYellow = get_imagename(3) .. is_active(3),
		btnBlue = get_imagename(4) .. is_active(4)
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
			menu = menu.new{name=locale[lang].options}
			menu:addItem{type="back"}
			menu:addItem{type="separatorline"}
			if (get_cfg_value("boxmode_12") == 1) then
				menu:addItem{type="chooser", action="set", options={on, off}, icon=setup, directkey=RC["setup"], name=locale[lang].boxmode}
			elseif (get_cfg_value("boxmode_12") == 0) then
				menu:addItem{type="chooser", action="set", options={off, on}, icon=setup, directkey=RC["setup"], name=locale[lang].boxmode}
			end
			menu:exec()
			chooser:paint()
		end
	until msg == RC['home'] or colorkey or i == t
	chooser:hide()

	if colorkey then
		if exists("/tmp/testmount/userdata/" .. devbase .. root) then
			-- found image folder
		elseif isdir("/tmp/testmount/rootfs" .. root .. "/usr") then
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
		for _, j in pairs(glob('/boot/*', 0)) do
			for line in io.lines(j) do
				if (j ~= bootfile) and (j ~= nil) and not line:match("boxmode=12") and not line:match("android") then
					if line:match(devbase .. image_to_devnum(root)) then
						startup_file = j
					end
				end
			end
		end
		for line in io.lines(startup_file) do
			if has_boxmode() then
				line = line:gsub(string.sub(line, string.find(line, " '")+2, string.find(line, "root=")-1), "")
			end
			if has_boxmode() and get_cfg_value("boxmode_12") == 1 then
				table.insert(startup_lines, (line:gsub(" '", " 'brcm_cma=520M@248M brcm_cma=192M@768M "):gsub("boxmode=1'", "boxmode=12'")))
			else
				table.insert(startup_lines, line)
			end
		end
		file = io.open(bootfile, 'w')
		for _, v in ipairs(startup_lines) do
			file:write(v, "\n")
		end
		file:close()
		reboot()
	end
	umount_filesystems()
	return
end

main()
