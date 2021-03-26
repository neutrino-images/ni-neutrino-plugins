-- The Tuxbox Copyright
--
-- Copyright 2018 Markus Volk, Sven Hoefer, Don de Deckelwech
-- Changed for VU+ SOLO 4K, VU+ DUO 4K, VU+ ULTIMO 4K, VU+ UNO 4K, VU+ UNO 4K SE and VU+ ZERO 4K
-- by BPanther 03/Dec/2019
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

caption = "STB-Startup v1.04 - VU+ "

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
else
	return
end

locale = {}

locale["deutsch"] = {
	current_boot_partition = "Die aktuelle Startpartition ist: ",
	choose_partition = "\n\nBitte wählen Sie die neue Startpartition aus.",
	start_partition = "Auf die gewählte Partition umschalten ?",
	reboot_partition = "Jetzt neustarten ?",
	empty_partition = "Die gewählte Partition ist leer !"
}

locale["english"] = {
	current_boot_partition = "The current boot partition is: ",
	choose_partition = "\n\nPlease choose the new boot partition.",
	start_partition = "Switch to the choosen partition ?",
	reboot_partition = "Reboot now ?",
	empty_partition = "The selected partition is empty !"
}

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

function is_active(root)
	if (current_root == root) then
		active = " *"
	else
		active = ""
	end
	return active
end

function get_imagename(root)
	imagename = ""
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
		end
	elseif fh:exist("/tmp/testmount/.version", "f") then
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
	else
		for _, j in pairs(glob('/boot/*', 0)) do
			for line in io.lines(j) do
				if (j ~= bootfile) then
					if line:match(devbase .. root) then
						imagename = basename(j)
					end
				end
			end
		end
	end
	umount("/tmp/testmount")
	return imagename
end

neutrino_conf = configfile.new()
neutrino_conf:loadConfig("/var/tuxbox/config/neutrino.conf")
lang = neutrino_conf:getString("language", "english")
if locale[lang] == nil then
	lang = "english"
end
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
	title = caption .. vumodel:upper(),
	icon = "settings",
	has_shadow = true,
	btnRed = get_imagename(root1) .. is_active(root1),
	btnGreen = get_imagename(root2) .. is_active(root2),
	btnYellow = get_imagename(root3) .. is_active(root3),
	btnBlue = get_imagename(root4) .. is_active(root4)
}

chooser_text = ctext.new {
	parent = chooser,
	x = OFFSET.INNER_MID,
	y = OFFSET.INNER_SMALL,
	dx = chooser_dx - 2*OFFSET.INNER_MID,
	dy = chooser_dy - chooser:headerHeight() - chooser:footerHeight() - 2*OFFSET.INNER_SMALL,
	text = locale[lang].current_boot_partition .. get_imagename(current_root) .. locale[lang].choose_partition,
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
		colorkey = true
	elseif (msg == RC['green']) then
		root = root2
		colorkey = true
	elseif (msg == RC['yellow']) then
		root = root3
		colorkey = true
	elseif (msg == RC['blue']) then
		root = root4
		colorkey = true
	end
until msg == RC['home'] or colorkey or i == t

chooser:hide()

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
	local glob = require "posix".glob
	for _, j in pairs(glob('/boot/*', 0)) do
		for line in io.lines(j) do
			if line:match(devbase .. root) then
				if (j ~= bootfile) then
					local file = io.open(bootfile, "w")
					file:write(line .. "\n")
					file:close()
				end
			end
		end
	end
	res = messagebox.exec {
		title = caption .. vumodel:upper(),
		icon = "settings",
		text = locale[lang].reboot_partition,
		timeout = 0,
		buttons={ "yes", "no" },
		default = "no"
	}
	if res == "yes" then
		reboot()
	end
end

return
