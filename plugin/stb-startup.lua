-- The Tuxbox Copyright
--
-- Copyright 2026 Thilo Graf (dbt@novatux.de)
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

local version = "v2.2"

local on = "ein"; local off = "aus"

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

local function read_file_lines(path)
	local lines = {}
	local f = io.open(path, "r")
	if f == nil then
		return lines
	end
	for line in f:lines() do
		table.insert(lines, line)
	end
	f:close()
	return lines
end

local function write_lines(path, lines)
	local f = io.open(path, "w")
	if f == nil then
		return false
	end
	local ok = true
	for _, line in ipairs(lines) do
		if not f:write(line, "\n") then
			ok = false
			break
		end
	end
	if not f:close() then
		ok = false
	end
	return ok
end

function has_partition_label(label)
	if partitions_by_name == nil then
		return false
	end
	return islink(partitions_by_name .. "/" .. label)
end

function build_partition_device_map()
	local map = {}
	for _, line in ipairs(read_file_lines("/proc/cmdline")) do
		local spec = line:match("blkdevparts=([^%s]+)")
		if spec ~= nil then
			for devspec in spec:gmatch("[^;]+") do
				local dev, parts = devspec:match("([^:]+):(.+)")
				if dev ~= nil and parts ~= nil then
					local prefix = "/dev/" .. dev
					if dev:match("^mmcblk") or dev:match("^nvme") or dev:match("^loop") then
						prefix = prefix .. "p"
					end
					local idx = 0
					for entry in parts:gmatch("[^,]+") do
						idx = idx + 1
						local name = entry:match("%(([^)]+)%)")
						if name ~= nil and name ~= "" then
							map[name] = prefix .. tostring(idx)
						end
					end
				end
			end
			break
		end
	end
	return map
end

function get_partition_device(label)
	if has_partition_label(label) then
		return partitions_by_name .. "/" .. label
	end
	if partition_device_map ~= nil then
		return partition_device_map[label]
	end
	return nil
end

function mount(dev,destination)
	local provider = fh:readlink("/bin/mount")
	if (provider == nil) or not string.match(provider, "busybox") then
		os.execute(string.format("mount -l %q %q", dev, destination))
	else
		os.execute(string.format("mount %q %q", dev, destination))
	end
end

function umount(path)
	local provider = fh:readlink("/bin/umount")
	if (provider == nil) or not string.match(provider, "busybox") then
		os.execute(string.format("umount -l %q", path))
	else
		os.execute(string.format("umount %q", path))
	end
end

function link(source,destination)
	fh:ln(source,destination,"sf")
end

function is_mounted(path)
	for _, line in ipairs(read_file_lines("/proc/self/mountinfo")) do
		local mount_point = line:match("^%d+ %d+ %S+ %S+ (%S+)")
		if mount_point == path then
			return true
		end
	end
	return false
end

function mount_filesystems()
	if not isdir("/tmp/testmount") then
		mkdir("/tmp/testmount")
	end
	for _,v in ipairs(partlabels) do
		local dev = get_partition_device(v)
		if dev ~= nil then
			if not isdir("/tmp/testmount/" .. v) then
				mkdir("/tmp/testmount/" .. v)
			end
			mount(dev, "/tmp/testmount/" .. v)
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
		if get_partition_device(v) ~= nil then
			umount("/tmp/testmount/" .. v)
		end
		if is_mounted("/tmp/testmount/" .. v) then
			print("umount failed: " .. v)
			return false
		end
	end
	if isdir("/tmp/testmount") then
		rmdir("/tmp/testmount")
	end
	return true
end

function sleep(n)
	local seconds = math.floor(tonumber(n) or 0)
	os.execute(string.format("sleep %d", seconds))
end

function reboot()
	umount_filesystems()
	if exists("/bin/systemctl") then
		os.execute("systemctl reboot")
	elseif exists("/sbin/init") then
		os.execute("sync && init 6")
	else
		os.execute("umount -f -a -r")
		os.execute("reboot")
	end
end

function basename(str)
	local name = string.gsub(str, "(.*/)(.*)", "%2")
	return name
end

function get_value(str,root,etcdir)
	local value = ""
	local testmount = ""
	if is_mounted("/tmp/testmount/userdata") then
		testmount = "/tmp/testmount/linuxrootfs" .. root
	elseif is_mounted("/tmp/testmount/rootfs" .. root) then
		testmount = "/tmp/testmount/rootfs" .. root
	else
		return value
	end

	-- image-version file
	if exists(testmount .. etcdir .. "/image-version") then
		local marker = str .. "="
		for _, line in ipairs(read_file_lines(testmount .. etcdir .. "/image-version")) do
			local _, j = string.find(line, marker, 1, true)
			if j ~= nil then
				value = string.sub(line, j+1, #line)
			end
		end
	end
	-- default neutrino .version file
	if value == "" and exists(testmount .. "/.version") then
		local marker = str .. "="
		for _, line in ipairs(read_file_lines(testmount .. "/.version")) do
			local _, j = string.find(line, marker, 1, true)
			if j ~= nil then
				value = string.sub(line, j+1, #line)
			end
		end
	end
	-- BlackHole image
	if value == "" and exists(testmount .. etcdir .. "/bhversion") then
		for _, line in ipairs(read_file_lines(testmount .. etcdir .. "/bhversion")) do
			if string.find(line, str, 1, true) ~= nil then
				value = line
			end
		end
	end

	return value
end

function get_imagename(root)
	local imagename = ""
	local tmp_version = ""
	local tmp_name = ""

	local etc = "/etc"
	if isdir("/tmp/testmount/linuxrootfs" .. root .. etc) or isdir("/tmp/testmount/rootfs" .. root .. etc) then
		-- do nothing
	else
		etc = "/var/etc"
	end

	tmp_name = get_value("distro", root, etc)
	if tmp_name == "" then
		tmp_name = get_value("creator", root, etc)
		if tmp_name:match("VTi") then
			-- shorten VTi
			tmp_name = "VTi"
		elseif tmp_name:match("BPanther") then
			-- shorten BPanther
			tmp_name = "BP"
		end
		-- BlackHole image
		if tmp_name == "" then
			tmp_name = get_value("BlackHole", root, etc)
		end
	end
	tmp_version = get_value("imageversion", root, etc)
	if tmp_version == "" then
		tmp_version = get_value("version", root, etc)
		local v = ""
		if tmp_name == "VTi" then
			-- get VTi version
			v = string.sub(tmp_version, 2, 3)
			v = v .. "." .. string.sub(tmp_version, 4, 4)
			v = v .. "." .. string.sub(tmp_version, 5, 5)
			tmp_version = v
		elseif tmp_name == "BP" then
			-- get BP version
			tmp_version = get_value("git", root, etc)
		elseif tmp_name:match("BlackHole") then
			-- do nothing
		elseif tmp_name ~= "" then
			-- get neutrino version
			v = string.sub(tmp_version, 2, 2)
			v = v .. "." .. string.sub(tmp_version, 3, 4)
			tmp_version = v
		end
	end

	imagename = tmp_name .. " " .. tmp_version

	if imagename == " " then
		local glob = require "posix".glob
		imagename = "NOT FOUND"
		for _, j in pairs(glob(boot .. '/*', 0) or {}) do
			if not isdir(j) and not islink(j) then
				for _, line in ipairs(read_file_lines(j)) do
					if (j ~= boot .. "/STARTUP") and (j ~= nil) and not line:match("boxmode=12") and not line:match("android") then
						if line:match(devbase .. image_to_devnum(root)) then
							imagename = basename(j)
						end
					end
				end
			end
		end
	end
	return imagename
end

function is_active(root)
	local active = ""
	if (current_root == root) then
		active = " *"
	end
	return active
end

function has_gpt_layout()
	return devbase ~= "linuxrootfs"
end

function table_count(t)
	local cnt = 0
	for _ in pairs(t) do
		cnt = cnt + 1
	end
	return cnt
end

function register_startup_slot(caps, entry)
	if entry.slot == nil then
		return
	end
	if caps.slot_files[entry.slot] == nil then
		caps.slot_files[entry.slot] = {}
	end
	table.insert(caps.slot_files[entry.slot], entry)
	caps.slots[entry.slot] = true
	if entry.mode ~= nil then
		caps.boxmode_present = true
		if caps.slot_modes[entry.slot] == nil then
			caps.slot_modes[entry.slot] = {}
		end
		caps.slot_modes[entry.slot][entry.mode] = true
	end
	if entry.rootpart ~= nil then
		caps.rootpart_to_slot[entry.rootpart] = entry.slot
	end
end

function parse_slot_from_name(name)
	local slot = name:match("STARTUP_LINUX_(%d+)")
	if slot ~= nil then
		return tonumber(slot)
	end
	slot = name:match("STARTUP_(%d+)")
	if slot ~= nil then
		return tonumber(slot)
	end
	return nil
end

function parse_slot_from_content(content)
	local slot = content:match("rootsubdir=linuxrootfs(%d+)")
	if slot ~= nil then
		return tonumber(slot)
	end
	if devbase == "linuxrootfs" then
		slot = content:match("linuxrootfs(%d+)")
		if slot ~= nil then
			return tonumber(slot)
		end
	end
	return nil
end

function parse_rootpart(content)
	local rootpart = content:match("root=/dev/mmcblk%d+p(%d+)")
	if rootpart ~= nil then
		return tonumber(rootpart)
	end
	return nil
end

function parse_mode(content)
	local mode = content:match("boxmode=(%d+)")
	if mode ~= nil then
		return tostring(mode)
	end
	return nil
end

function detect_startup_capabilities()
	local glob = require "posix".glob
	local caps = {
		entries = {},
		slots = {},
		slot_files = {},
		slot_modes = {},
		rootpart_to_slot = {},
		boxmode_present = false,
		boxmode_switchable = false,
		boxmode12_switchable = false
	}
	local unresolved = {}
	local files = glob(boot .. "/STARTUP*", 0) or {}
	table.sort(files)
	for _, path in ipairs(files) do
		if not isdir(path) and not islink(path) then
			local lines = read_file_lines(path)
			if #lines > 0 then
				local content = table.concat(lines, " ")
				local entry = {
					path = path,
					name = basename(path),
					lines = lines,
					content = content,
					mode = parse_mode(content),
					slot = parse_slot_from_name(basename(path)),
					rootpart = parse_rootpart(content),
					android = content:match("android") ~= nil
				}
				if entry.slot == nil then
					entry.slot = parse_slot_from_content(content)
				end
				table.insert(caps.entries, entry)
				if entry.slot ~= nil then
					register_startup_slot(caps, entry)
				else
					table.insert(unresolved, entry)
				end
			end
		end
	end

	for _, entry in ipairs(unresolved) do
		if entry.rootpart ~= nil and caps.rootpart_to_slot[entry.rootpart] ~= nil then
			entry.slot = caps.rootpart_to_slot[entry.rootpart]
		elseif entry.rootpart ~= nil then
			entry.slot = devnum_to_image(entry.rootpart)
		end
		register_startup_slot(caps, entry)
	end

	for _, mode_set in pairs(caps.slot_modes) do
		local mode_count = table_count(mode_set)
		if mode_count > 1 then
			caps.boxmode_switchable = true
		end
		if mode_set["1"] ~= nil and mode_set["12"] ~= nil then
			caps.boxmode12_switchable = true
		end
	end

	return caps
end

function detect_current_mode()
	for _, line in ipairs(read_file_lines("/proc/cmdline")) do
		local mode = parse_mode(line)
		if mode ~= nil then
			return mode
		end
	end
	return nil
end

function detect_current_slot(caps)
	for _, line in ipairs(read_file_lines("/proc/cmdline")) do
		local slot = line:match("rootsubdir=linuxrootfs(%d+)")
		if slot ~= nil then
			return tonumber(slot)
		end
		local rootpart = line:match("root=/dev/mmcblk%d+p(%d+)")
		if rootpart ~= nil then
			local part = tonumber(rootpart)
			if caps.rootpart_to_slot[part] ~= nil then
				return caps.rootpart_to_slot[part]
			end
			return devnum_to_image(part)
		end
		local _, j = string.find(line, devbase)
		if j ~= nil then
			local suffix = string.match(string.sub(line, j+1), "^(%d+)")
			if suffix ~= nil then
				return devnum_to_image(tonumber(suffix))
			end
		end
	end
	return nil
end

function slot_has_mode(caps, slot, mode)
	if caps.slot_modes[slot] == nil then
		return false
	end
	return caps.slot_modes[slot][tostring(mode)] ~= nil
end

function select_slot_mode(caps, slot, preferred_mode)
	if preferred_mode ~= nil and slot_has_mode(caps, slot, preferred_mode) then
		return tostring(preferred_mode)
	end
	if caps.slot_modes[slot] == nil then
		return nil
	end
	local fallback
	for mode in pairs(caps.slot_modes[slot]) do
		if fallback == nil then
			fallback = mode
		end
		if mode == "1" then
			return mode
		end
	end
	return fallback
end

function select_startup_entry(caps, slot, preferred_mode)
	local candidates = caps.slot_files[slot]
	if candidates == nil then
		return nil
	end

	local function pick(mode, avoid_android)
		for _, entry in ipairs(candidates) do
			if (mode == nil or entry.mode == mode) and (not avoid_android or not entry.android) then
				return entry
			end
		end
		return nil
	end

	local mode = preferred_mode
	if mode ~= nil then
		local e = pick(tostring(mode), true) or pick(tostring(mode), false)
		if e ~= nil then
			return e
		end
	end

	for _, entry in ipairs(candidates) do
		if entry.name == "STARTUP" and not entry.android then
			return entry
		end
	end
	return pick(nil, true) or pick(nil, false)
end

function has_boxmode()
	return startup_caps ~= nil and startup_caps.boxmode_present
end

function can_switch_boxmode_12()
	return startup_caps ~= nil and startup_caps.boxmode12_switchable
end

function truncate_text(text, maxlen)
	if text == nil then
		return ""
	end
	if string.len(text) <= maxlen then
		return text
	end
	return string.sub(text, 1, maxlen - 1) .. "…"
end

function get_slot_modes_text(caps, slot)
	if caps == nil or caps.slot_modes[slot] == nil then
		return "-"
	end
	local modes = {}
	for mode in pairs(caps.slot_modes[slot]) do
		table.insert(modes, tostring(mode))
	end
	table.sort(modes, function(a, b) return tonumber(a) < tonumber(b) end)
	return table.concat(modes, "/")
end

function select_slot(id, value)
	local selected = tonumber(id) or tonumber(value)
	if selected ~= nil then
		root = selected
		colorkey = true
		return MENU_RETURN.EXIT_ALL
	end
	return MENU_RETURN.REPAINT
end

function devnum_to_image(root)
	local ret = root
	if (has_gpt_layout()) then
		if (root == 3) then ret = 1 end
		if (root == 5) then ret = 2 end
		if (root == 7) then ret = 3 end
		if (root == 9) then ret = 4 end
	end
	return ret
end

function image_to_devnum(root)
	local ret = root
	if (has_gpt_layout()) then
		if (root == 1) then ret = 3 end
		if (root == 2) then ret = 5 end
		if (root == 3) then ret = 7 end
		if (root == 4) then ret = 9 end
	end
	return ret
end

function get_cfg_path()
	return tuxbox_config .. "/stb-startup.conf"
end

function get_cfg_value(str)
	local cfg_path = get_cfg_path()
	if not exists(cfg_path) then
		return nil
	end
	local r = nil
	for _, line in ipairs(read_file_lines(cfg_path)) do
		local value = line:match("^" .. str .. "=(%d+)$")
		if value ~= nil then
			r = tonumber(value)
		end
	end
	return r
end

function create_cfg()
	return write_lines(get_cfg_path(), {"boxmode_12=1"})
end

function write_cfg(_, v, str)
	local a = "0"
	if (v == on) then a = "1" end
	local cfg_path = get_cfg_path()
	if not exists(cfg_path) and not create_cfg() then
		return false
	end
	local cfg_content = {}
	local found = false
	for _, line in ipairs(read_file_lines(cfg_path)) do
		if line:match("^" .. str .. "=") then
			table.insert(cfg_content, str .. "=" .. a)
			found = true
		else
			table.insert(cfg_content, line)
		end
	end
	if not found then
		table.insert(cfg_content, str .. "=" .. a)
	end
	return write_lines(cfg_path, cfg_content)
end

function set(k, v, str)
	write_cfg(k, v, "boxmode_12")
end

function get_boot_path()
	local path_boot = "/tmp/testmount/boot"
	local path_boot_options = "/tmp/testmount/bootoptions"
	local ret = path_boot_options
	if get_partition_device("boot") ~= nil then
		ret = path_boot
	end
	return ret
end

function get_devbase()
	local devbase = "linuxrootfs"
	partitions_by_name = nil
	if isdir("/dev/disk/by-partlabel") then
		partitions_by_name = "/dev/disk/by-partlabel"
	elseif isdir("/dev/block/by-name") then
		partitions_by_name = "/dev/block/by-name"
	end
	if get_partition_device("rootfs1") ~= nil then
		for _, line in ipairs(read_file_lines("/proc/cmdline")) do
			local rootdev = line:match("root=([^%s]+)")
			if rootdev ~= nil then
				local rootbase = rootdev:match("(.+p)%d+$")
				if rootbase ~= nil then
					devbase = rootbase
					break
				end
			end
		end
	end
	return devbase
end

function main()
	caption = "STB-Startup" .. " " .. version
	partlabels = {"linuxrootfs","userdata","rootfs1","rootfs2","rootfs3","rootfs4","boot","bootoptions"}
	neutrino()
	fh = filehelpers.new()
	partition_device_map = build_partition_device_map()

	locale = {}
		locale["deutsch"] = {
			current_boot_partition = "Die aktuelle Startpartition ist: ",
			choose_partition = "\n\nBitte wählen Sie die neue Startpartition aus",
			start_partition = "Rebooten und die gewählte Partition starten?",
			empty_partition = "Das gewählte Image ist nicht vorhanden",
			boot_unavailable = "Boot-Partition konnte nicht gemountet werden",
			startup_write_failed = "STARTUP konnte nicht geschrieben werden",
			options = "Einstellungen",
			select_slot = "Startpartition wählen",
			boxmode12 = "Boxmode 12",
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
			boot_unavailable = "Unable to mount boot partition",
			startup_write_failed = "Unable to write STARTUP",
			options = "Options",
			select_slot = "Select boot slot",
			boxmode12 = "Boxmode 12",
			image = "Image switch",
			boxmode = "Boxmode switch",
			image_and_boxmode = "Wrote Image- and Boxmode changing",
			hinttext = " %s to STARTUP!!\n\nReboot of Image >> %s <<\n\nwith Boxmode %s in %s sec."
		}

	tuxbox_config = "/var/tuxbox/config"
	if type(DIR) == "table" and type(DIR.CONFIGDIR) == "string" and DIR.CONFIGDIR ~= "" then
		tuxbox_config = DIR.CONFIGDIR
	elseif not isdir(tuxbox_config) and isdir("/etc/neutrino/config") then
		tuxbox_config = "/etc/neutrino/config"
	end
	neutrino_conf = configfile.new()
	neutrino_conf:loadConfig(tuxbox_config .. "/neutrino.conf")
	lang = neutrino_conf:getString("language", "english")

	if locale[lang] == nil then
		lang = "english"
	end

	devbase = get_devbase()
	boot = get_boot_path()

	mount_filesystems()
	if not isdir(boot) then
		local ret = hintbox.new { title = caption, icon = "settings", text = locale[lang].boot_unavailable };
		ret:paint();
		sleep(3)
		ret:hide()
		umount_filesystems()
		return
	end
	startup_caps = detect_startup_capabilities()
	startup_caps.current_mode = detect_current_mode()
	current_root = detect_current_slot(startup_caps)
	if current_root == nil then
		current_root = 1
	end
	if startup_caps.current_mode == nil then
		startup_caps.current_mode = select_slot_mode(startup_caps, current_root, nil)
	end

	if not exists(tuxbox_config .. "/stb-startup.conf") and has_boxmode() then
		create_cfg()
	end

	local imagename = {}
	local imagename_full = {}
	for slot=1, 4 do
		imagename_full[slot] = get_imagename(slot)
		imagename[slot] = truncate_text(imagename_full[slot], 44) .. is_active(slot)
	end

	local current_mode = off
	local current_mode_num = startup_caps.current_mode or "1"
	if current_mode_num == "12" then
		current_mode = on
	end
	local cfg_mode = current_mode
	if can_switch_boxmode_12() then
		if (get_cfg_value("boxmode_12") == 1) then
			cfg_mode = on
		else
			cfg_mode = off
		end
		-- keep the persisted toggle in sync with the currently running mode
		if (current_mode ~= cfg_mode) then
			write_cfg(current_root, current_mode, "boxmode_12")
			cfg_mode = current_mode
		end
	end

	colorkey = nil
	root = nil
	local res = nil

	local menu = menu.new{name=caption, icon="settings"}
	menu:addItem{type="back"}
	menu:addItem{type="separatorline", name=locale[lang].current_boot_partition .. imagename_full[current_root]}
	menu:addItem{type="separatorline", name=locale[lang].select_slot}
	for slot=1,4 do
		local mode_text = get_slot_modes_text(startup_caps, slot)
		local entry_name = "Slot " .. tostring(slot) .. " [" .. mode_text .. "] " .. imagename[slot]
		menu:addItem{
			type="forwarder",
			name=entry_name,
			action="select_slot",
			id=tostring(slot),
			directkey=RC[tostring(slot)],
			hint=imagename_full[slot]
		}
	end
	menu:addItem{type="separatorline", name=locale[lang].options}
	if has_boxmode() then
		if can_switch_boxmode_12() then
			if (get_cfg_value("boxmode_12") == 1) then
				menu:addItem{type="chooser", action="set", options={on, off}, directkey=RC["setup"], name=locale[lang].boxmode12}
			else
				menu:addItem{type="chooser", action="set", options={off, on}, directkey=RC["setup"], name=locale[lang].boxmode12}
			end
		else
			local static_mode = startup_caps.current_mode or "-"
			menu:addItem{type="forwarder", enabled=false, name=locale[lang].boxmode12 .. ": " .. static_mode}
		end
	end
	menu:exec()

	if colorkey then
		if islink("/tmp/testmount/" .. devbase .. root) then
			-- found image folder
		elseif isdir("/tmp/testmount/rootfs" .. root) then
			-- found image folder
		else
			local ret = hintbox.new { title = caption, icon = "settings", text = locale[lang].empty_partition };
			ret:paint();
			sleep(3)
			ret:hide()
			umount_filesystems()
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
		local startup_lines = {}
		local preferred_mode = nil
		if can_switch_boxmode_12() then
			if get_cfg_value("boxmode_12") == 1 then
				preferred_mode = "12"
			else
				preferred_mode = "1"
			end
		elseif has_boxmode() then
			preferred_mode = select_slot_mode(startup_caps, root, startup_caps.current_mode)
		end

		local startup_entry = select_startup_entry(startup_caps, root, preferred_mode)
		if startup_entry == nil then
			local ret = hintbox.new { title = caption, icon = "settings", text = locale[lang].empty_partition };
			ret:paint();
			sleep(3)
			ret:hide()
			umount_filesystems()
			return
		end

		for _, line in ipairs(startup_entry.lines) do
			table.insert(startup_lines, line)
		end
		local mode = startup_entry.mode or preferred_mode or current_mode_num

		if not write_lines(boot .. "/STARTUP", startup_lines) then
			local ret = hintbox.new { title = caption, icon = "settings", text = locale[lang].startup_write_failed };
			ret:paint();
			sleep(3)
			ret:hide()
			umount_filesystems()
			return
		end

		local txt
		if (current_root ~= root and tostring(current_mode_num) ~= tostring(mode)) then
			txt = locale[lang].image_and_boxmode
		elseif (current_root ~= root) then
			txt = locale[lang].image
		else
			txt = locale[lang].boxmode
		end
		local stime = 5
		local hbtext = string.format(locale[lang].hinttext, txt, imagename[root], mode, tostring(stime))
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
