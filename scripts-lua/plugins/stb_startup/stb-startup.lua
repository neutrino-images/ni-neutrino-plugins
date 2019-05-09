-- The Tuxbox Copyright
--
-- Copyright 2018 Markus Volk, Sven Hoefer, Don de Deckelwech
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

caption = "STB-Startup"

n = neutrino()
fh = filehelpers.new()

devbase = "linuxrootfs"
bootfile = "/boot/STARTUP"

for line in io.lines(bootfile) do
	i, j = string.find(line, devbase)
	if (j ~= nil) then
		current_root = tonumber(string.sub(line,j+1,j+1))
	end
end

locale = {}
locale["deutsch"] = {
	current_boot_partition = "Die aktuelle Startpartition ist: ",
	choose_partition = "\n\nBitte wählen Sie die neue Startpartition aus",
	start_partition = "Rebooten und die gewählte Partition starten?",
	empty_partition = "Das gewählte Image ist nicht vorhanden"
}
locale["english"] = {
	current_boot_partition = "The current boot partition is: ",
	choose_partition = "\n\nPlease choose the new boot partition",
	start_partition = "Reboot and start the chosen partition?",
	empty_partition = "No image available"
}

function sleep(n)
	os.execute("sleep " .. tonumber(n))
end

function reboot()
	local file = assert(io.popen("which systemctl >> /dev/null"))
	running_init = file:read('*line')
	file:close()
	if running_init == "/bin/systemctl" then
		local file = assert(io.popen("systemctl reboot"))
	else
		local file = assert(io.popen("reboot"))
	end
end

function basename(str)
	local name = string.gsub(str, "(.*/)(.*)", "%2")
	return name
end

function get_value(str, rootfs)
	for line in io.lines(rootfs .. "/etc/image-version") do
		if line:match(str .. "=") then
			local i,j = string.find(line, str .. "=")
			ret = string.sub(line, j+1, #line)
		end
	end
	return ret
end

function get_imagename(root)
	local rootfs = ""
	if (current_root ~= root) then
		rootfs = "mnt/userdata/linuxrootfs" .. root
	end
	if exists(rootfs  .. "/etc/image-version") then
		imagename = get_value("distro", rootfs) .. " " .. get_value("imageversion", rootfs)
	else
		local glob = require "posix".glob
		for _, j in pairs(glob('/boot/*', 0)) do
			for line in io.lines(j) do
				if (j ~= bootfile) or (j ~= nil) then
					if line:match(devbase .. root) then
						imagename = basename(j)
					end
				end
			end
		end
	end
	return imagename
end

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

function is_active(root)
	if (current_root == root) then
		active = " *"
	else
		active = ""
	end
	return active
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
	end
until msg == RC['home'] or colorkey or i == t
chooser:hide()

if colorkey then
	if isdir("/mnt/" .. devbase .. root) then
		-- found image folder
	elseif isdir("/mnt/userdata/" .. devbase .. root) then
		-- found image folder
	else
		local ret = hintbox.new { title = caption, icon = "settings", text = locale[lang].empty_partition };
		ret:paint();
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
			if (j ~= bootfile) or (j ~= nil) then
				if line:match(devbase .. root) then
					for line in io.lines(j) do
						table.insert(startup_lines, line)
					end
				end
			end
		end
	end
	file = io.open(bootfile, 'w')
	for i, v in ipairs(startup_lines) do
		file:write(v, "\n")
	end
	file:close()
	reboot()
end

return
