-- The Tuxbox Copyright
--
-- Copyright 2018 Markus Volk, Sven Hoefer, Don de Deckelwech
-- STB-Startup for HD51/H7/BRE2ZE4K
--
-- Changed, now also for VU+ SOLO 4K, VU+ DUO 4K, VU+ DUO 4K SE, VU+ ULTIMO 4K, VU+ UNO 4K, VU+ UNO 4K SE, VU+ ZERO 4K, E4HD 4K ULTRA and Protek 4K UHD
-- by BPanther 29/Jul/2023
--
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

caption = "STB-Startup v1.27 - "
bmbox = 0

n = neutrino()
fh = filehelpers.new()

devbase = "/dev/mmcblk0p"
bootfile = "/boot/STARTUP"

for line in io.lines(bootfile) do
	i, j = string.find(line, devbase)
	current_root = tonumber(string.sub(line,j+1,j+2))
end

vuproc = assert(io.popen("cat /proc/stb/info/vumodel"))
vumodel = vuproc:read('*line')
vuproc:close()

bmproc = assert(io.popen("cat /proc/stb/info/model"))
boxmodel = bmproc:read('*line')
bmproc:close()

if vumodel == "solo4k" or vumodel == "uno4k" or vumodel == "uno4kse" or vumodel == "ultimo4k" then
	root1 = 5
	root2 = 7
	root3 = 9
	root4 = 11
elseif vumodel == "duo4k" or vumodel == "duo4kse" then
	root1 = 10
	root2 = 12
	root3 = 14
	root4 = 16
elseif vumodel == "zero4k" then
	root1 = 8
	root2 = 10
	root3 = 12
	root4 = 14
elseif boxmodel == "hd51" or boxmodel == "h7" or boxmodel == "bre2ze4k" then
	root1 = 3
	root2 = 5
	root3 = 7
	root4 = 9
	vumodel = boxmodel
	bmbox = 1
elseif boxmodel == "e4hd" or boxmodel == "protek4k" then
	root1 = 3
	root2 = 5
	root3 = 7
	root4 = 9
	vumodel = boxmodel
else
	return
end

locale = {}

locale["deutsch"] = {
	current_boot_partition = "Die aktuelle Startpartition ist: ",
	choose_partition = "\n\nBitte wählen Sie die neue Startpartition aus.",
	start_partition = "Auf die gewählte Partition umschalten ?",
	reboot_partition = "Jetzt neustarten ?",
	empty_partition = "Die gewählte Partition ist leer !",
	on = "ein",
	off = "aus",
	react = "Gewünschte Partition nach Umstellung neu aktivieren."
}

locale["english"] = {
	current_boot_partition = "The current boot partition is: ",
	choose_partition = "\n\nPlease choose the new boot partition.",
	start_partition = "Switch to the choosen partition ?",
	reboot_partition = "Reboot now ?",
	empty_partition = "The selected partition is empty !",
	on = "on",
	off = "off",
	react = "Select partition again after changing boxmode."
}

function count_root()
	local cnt = 4
	local f = assert(io.popen("parted /dev/mmcblk0 print | grep -c rootfs"))
	if f then
		cnt = tonumber(f:read('*line'))
		f:close()
	end
	return cnt
end

function sleep (a)
	local sec = tonumber(os.clock() + a);
	while (os.clock() < sec) do
	end
end

function reboot()
	local file = assert(io.popen("which systemctl >> /dev/null"))
	running_init = file:read('*line')
	file:close()
	if running_init == "/bin/systemctl" then
		local file = assert(io.popen("systemctl reboot"))
	else
		local file = assert(io.popen("sync && init 6"))
	end
end

function basename(str)
	local name = string.gsub(str, "(.*/)(.*)", "%2")
	return name
end

function mount(dev,destination)
	local provider = fh:readlink("/bin/mount")
	fh:mkdir("/tmp/testmount/")
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
	if not fh:exist("/tmp/testmount/tmp", "d") then
		fh:rmdir("/tmp/testmount")
	end
end

rtp = 0
rr = 0
function is_active(root)
	rr = rr + 1
	if (current_root == root) then
		rtp = rr
		active = " *"
	else
		active = ""
	end
	return active
end

function get_cfg_value(str)
	for line in io.lines("/var/tuxbox/config/stb-startup.conf") do
		if line:match(str .. "=") then
			local i,j = string.find(line, str .. "=")
			r = tonumber(string.sub(line, j+1, #line))
		end
	end
	return r
end

function create_cfg()
	file = io.open("/var/tuxbox/config/stb-startup.conf", "w")
	file:write("boxmode_12=0", "\n")
	file:close()
end

function write_cfg(k, v, str)
	local a
	if (v == on) then a = 1 else a = 0 end
	local cfg_content = {}
	for line in io.lines("/var/tuxbox/config/stb-startup.conf") do
		if line:match(str .. "=") then
			table.insert (cfg_content, (string.reverse(string.gsub(string.reverse(line), string.sub(string.reverse(line), 1, 1), a, 1))))
		else
			table.insert (cfg_content, line)
		end
	end
	file = io.open("/var/tuxbox/config/stb-startup.conf", 'w')
	for i, v in ipairs(cfg_content) do
		file:write(v, "\n")
	end
	io.close(file)
end

function set(k, v, str)
	write_cfg(k, v, "boxmode_12")
end

if (bmbox == 1) and not fh:exist("/var/tuxbox/config/stb-startup.conf", "f") then
	create_cfg()
end

function get_imagename(root)
	imagename = ""
	imgversion= ""
	local glob = require "posix".glob
	local fh = filehelpers.new()
	mount("/dev/mmcblk0p" .. root, "/tmp/testmount")
	if fh:exist("/tmp/testmount/etc/image-version", "f") then
		for line in io.lines("/tmp/testmount/etc/image-version") do
			if line:match("distro" .. "=") then
				local i,j = string.find(line, "distro" .. "=")
				imagename = string.sub(line, j+1, #line)
			end
			if line:match("imageversion" .. "=") then
				local i,j = string.find(line, "imageversion" .. "=")
				imagename = imagename .. " " .. string.sub(line, j+1, #line)
			end
			if line:match("version" .. "=") then
				local i,j = string.find(line, "version" .. "=")
				imgversion = string.sub(line, j+2, j+3)
				imgversion = imgversion .. "." .. string.sub(line, j+4, j+4)
				imgversion = imgversion .. "." .. string.sub(line, j+5, j+5)
			end
			if imagename == "" and line:match("creator" .. "=") then
				local i,j = string.find(line, "creator" .. "=")
				if line == "creator=VTi <info@vuplus-support.org>" then
					line = "creator=VTi"
				end
				imagename = string.sub(line, j+1, #line)
			end
			if imagename == "VTi" and imgversion ~= "" then
				imagename = imagename .. " " .. imgversion
			end
		end
	end
	if imagename == "" and fh:exist("/tmp/testmount/.version", "f") then
		for line in io.lines("/tmp/testmount/.version") do
			if line:match("creator" .. "=") then
				local i,j = string.find(line, "creator" .. "=")
				imagename = string.sub(line, j+1, #line)
			end
			if line:match("git" .. "=") then
				local i,j = string.find(line, "git" .. "=")
				imagename = imagename .. " " .. string.sub(line, j+1, #line)
			end
		end
	end
	if imagename == "" then
		for _, j in pairs(glob('/boot/*', 0)) do
			for line in io.lines(j) do
				if (j ~= bootfile) then
					if bmbox == 1 then
						if get_cfg_value("boxmode_12") == 1 then
							boxmode = "boxmode=12'"
						else
							boxmode = "boxmode=1'"
						end
						if line:match(devbase .. root) and (j ~= nil) and line:match(boxmode) and not line:match("android") then
							imagename = basename(j)
						end
					elseif line:match(devbase .. root) and (j ~= nil) and not line:match("android") then
						imagename = basename(j)
					end
				end
			end
		end
		if imagename == "" then imagename = "???" end
	end
	umount("/tmp/testmount")
	imagename = string.sub(imagename, 0, 22) -- max. 22 chars
	return imagename
end

neutrino_conf = configfile.new()
neutrino_conf:loadConfig("/var/tuxbox/config/neutrino.conf")
lang = neutrino_conf:getString("language", "english")
if locale[lang] == nil then
	lang = "english"
end
on = locale[lang].on
off = locale[lang].off
timing_menu = neutrino_conf:getString("timing.menu", "0")

if bmbox == 1 then
	chooser_dx = n:scale2Res(900)
else
	chooser_dx = n:scale2Res(700)
end
chooser_dy = n:scale2Res(200)
chooser_x = SCREEN.OFF_X + (((SCREEN.END_X - SCREEN.OFF_X) - chooser_dx) / 2)
chooser_y = SCREEN.OFF_Y + (((SCREEN.END_Y - SCREEN.OFF_Y) - chooser_dy) / 2)

_btnRed = get_imagename(root1) .. is_active(root1)
_btnGreen = get_imagename(root2) .. is_active(root2)
if count_root() > 2 then
	_btnYellow = get_imagename(root3) .. is_active(root3)
end
if count_root() > 3 then
	_btnBlue = get_imagename(root4) .. is_active(root4)
end

if bmbox == 1 then
	chooser = cwindow.new {
		x = chooser_x,
		y = chooser_y,
		dx = chooser_dx,
		dy = chooser_dy,
		title = caption .. vumodel:upper(),
		icon = "settings",
		has_shadow = true,
		btnRed = _btnRed,
		btnGreen = _btnGreen,
		btnYellow = _btnYellow,
		btnBlue = _btnBlue,
		btnSetup = "Boxmode"
	}
else
	chooser = cwindow.new {
		x = chooser_x,
		y = chooser_y,
		dx = chooser_dx,
		dy = chooser_dy,
		title = caption .. vumodel:upper(),
		icon = "settings",
		has_shadow = true,
		btnRed = _btnRed,
		btnGreen = _btnGreen,
		btnYellow = _btnYellow,
		btnBlue = _btnBlue
	}
end

chooser_text = ctext.new {
	parent = chooser,
	x = OFFSET.INNER_MID,
	y = OFFSET.INNER_SMALL,
	dx = chooser_dx - 2*OFFSET.INNER_MID,
	dy = chooser_dy - chooser:headerHeight() - chooser:footerHeight() - 2*OFFSET.INNER_SMALL,
	text = locale[lang].current_boot_partition .. rtp .. "\n" .. get_imagename(current_root) .. locale[lang].choose_partition,
	font_text = FONT.MENU,
	text_mode = "ALIGN_CENTER"
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
		root = root1
		rootnum = 1
		colorkey = true
	elseif (msg == RC['green']) then
		root = root2
		rootnum = 2
		colorkey = true
	elseif (count_root() > 2 and msg == RC['yellow']) then
		root = root3
		rootnum = 3
		colorkey = true
	elseif (count_root() > 3 and msg == RC['blue']) then
		root = root4
		rootnum = 4
		colorkey = true
	elseif (bmbox == 1) and (msg == RC['setup']) then
		chooser:hide()
		menu = menu.new{icon="settings", name=locale[lang].options}
		menu:addItem{type="back"}
		menu:addItem{type="separatorline"}
		if (get_cfg_value("boxmode_12") == 1) then
			menu:addItem{type="chooser", action="set", options={on, off}, directkey=RC["setup"], name="Boxmode 12"}
		elseif (get_cfg_value("boxmode_12") == 0) then
			menu:addItem{type="chooser", action="set", options={off, on}, directkey=RC["setup"], name="Boxmode 12"}
		end
		menu:addItem{type="separatorline", name=locale[lang].react}
		menu:exec()
		chooser:paint()
	end
until msg == RC['home'] or colorkey or i == t

chooser:hide()

function make_cmdline(boxname, rn, rp)
	if boxname == "ultimo4k" then cmdline = "boot emmcflash0.kernel_" .. rn .. " 'root=/dev/mmcblk0p" .. rp .. " rootfstype=ext4 rootflags=data=journal rootwait rw coherent_pool=2M vmalloc=622m bmem=630m@394m bmem=383m@1665m bmem=443m@2625m'\n"
	elseif boxname == "duo4kse" then cmdline = "boot flash0.kernel_" .. rn ..  " 'libata.force=1:3.0G,2:3.0G,3:3.0G root=/dev/mmcblk0p" .. rp .. " rootfstype=ext4 rootflags=data=journal rootwait rw coherent_pool=2M vmalloc=622m bmem=630m@394m bmem=383m@1665m bmem=443m@2625m'\n"
	elseif boxname == "duo4k" then cmdline = "boot flash0.kernel_" .. rn ..   " 'root=/dev/mmcblk0p" .. rp .. " rootfstype=ext4 rootflags=data=journal rootwait rw coherent_pool=2M vmalloc=500m bmem=891m@1156m bmem=575m@3520m'\n"
	elseif boxname == "solo4k" then cmdline = "boot emmcflash0.kernel_" .. rn ..  " 'root=/dev/mmcblk0p" .. rp .. " rw rootwait rootflags=data=journal debug coherent_pool=2M brcm_cma=504M@0x10000000 brcm_cma=260M@0x2f800000 brcm_cma=1024M@0x80000000'\n"
	elseif boxname == "uno4k" then cmdline = "boot emmcflash0.kernel_" .. rn ..  " 'root=/dev/mmcblk0p" .. rp .. " rootfstype=ext4 rootflags=data=journal rootwait rw coherent_pool=2M vmalloc=633m bmem=637m@383m bmem=637m@2431m'\n"
	elseif boxname == "uno4kse" then cmdline = "boot emmcflash0.kernel_" .. rn ..  " 'root=/dev/mmcblk0p" .. rp .. " rootfstype=ext4 rootflags=data=journal rootwait rw coherent_pool=2M vmalloc=666m bmem=641m@350m bmem=641m@2430m'\n"
	elseif boxname == "zero4k" then cmdline = "boot flash0.kernel_" .. rn ..  " 'root=/dev/mmcblk0p" .. rp .. " rootfstype=ext4 rootflags=data=journal rootwait rw coherent_pool=2M rw bmem=699m@1317m'\n"
	elseif boxname == "hd51" or boxname == "h7" or boxname == "bre2ze4k" then
		if get_cfg_value("boxmode_12") == 1 then
			cmdline = "boot emmcflash0.kernel" .. rn ..  " 'brcm_cma=520M@248M brcm_cma=192M@768M root=/dev/mmcblk0p" .. rp .. " rw rootwait " .. boxname .. "_4.boxmode=12'\n"
		else
			cmdline = "boot emmcflash0.kernel" .. rn ..  " 'brcm_cma=440M@328M brcm_cma=192M@768M root=/dev/mmcblk0p" .. rp .. " rw rootwait " .. boxname .. "_4.boxmode=1'\n"
		end
	elseif boxname == "e4hd" or boxname == "protek4k" then
		cmdline = "boot emmcflash0.kernel" .. rn ..  " 'brcm_cma=504M@264M brcm_cma=192M@768M brcm_cma=1024M@2048M root=/dev/mmcblk0p" .. rp .. " rw rootwait " .. boxname .. "_4.boxmode=5'\n"
	end
	return cmdline
end

if colorkey then
	local file = assert(io.popen("blkid " .. devbase .. root .. " | grep TYPE"))
	local check_exist = file:read('*line')
	file:close()
	if (check_exist == nil) then
		c = 1
	else
		local file = assert(io.popen("cat /proc/mounts | grep " .. devbase .. root .. " | awk -F ' ' '{print $2}'"))
		local mounted_part = file:read('*line')
		file:close()
		if(mounted_part == nil) then
			mounted_part = ''
		end
		a,b,c = os.execute("test -d " .. mounted_part .. "/usr")
	end
	if (c == 1) then
		local ret = hintbox.new { title = caption .. vumodel:upper(), icon = "settings", text = locale[lang].empty_partition };
		ret:paint();
		sleep(3)
		return
	else
		res = messagebox.exec {
			title = caption .. vumodel:upper(),
			icon = "settings",
			text = locale[lang].start_partition,
			timeout = 0,
			width = 475,
			buttons={ "yes", "no" },
			default = "no"
		}
	end
end

if res == "yes" then
	local file = io.open(bootfile, "w")
	file:write(make_cmdline(vumodel, rootnum, root))
	file:close()
	res = messagebox.exec {
		title = caption .. vumodel:upper(),
		icon = "settings",
		text = locale[lang].reboot_partition,
		timeout = 0,
		width = 475,
		buttons={ "yes", "no" },
		default = "no"
	}
	if res == "yes" then
		reboot()
	end
end

return
