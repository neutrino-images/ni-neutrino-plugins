-- The Tuxbox Copyright
--
-- Copyright 2018 The Tuxbox Project. All rights reserved.
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

-- The views and conclusions contained in the software and documentation are those of the
-- authors and should not be interpreted as representing official policies, either expressed
-- or implied, of the Tuxbox Project.

caption = "STB-Backup"

local posix = require "posix"
n = neutrino()
fh = filehelpers.new()

bootfile = "/boot/STARTUP"
devbase = "/dev/mmcblk0p"

locale = {}

locale["deutsch"] = {
	current_boot_partition = "Die aktuelle Startpartition ist: ",
	choose_partition = "\n\nWelche Partition soll gesichert werden?",
	start_partition1 = "Image aus der Partition ",
	start_partition2 = " sichern?",
	backup_image = "Image aus Partition ",
	backup_is_saved = " wird gesichert \n\nBitte warten...",
	backup_successful = "Sicherung erfolgreich",
	backup_no_space = "Es wird mindestens 1G freier Speicherplatz auf der Festplatte benötigt",
	prepare_system = "System wird vorbereitet ... Bitte warten",
}

locale["english"] = {
	current_boot_partition = "The current start partition is: ",
	choose_partition = "\n\nWhat partition should be saved?",
	start_partition1 = "Create backup of partition ",
	start_partition2 = "?",
	backup_image = "Image backup of partition ",
	backup_is_saved = " will be created \n\nPlease stand by...",
	backup_successful = "Image backup succeeded",
	backup_no_space = "You need at least 1G of free space on your HDD",
	prepare_system = "System is getting prepared ... please stand by",
}

neutrino_conf = configfile.new()
neutrino_conf:loadConfig("/etc/neutrino/config/neutrino.conf")
lang = neutrino_conf:getString("language", "english")

if locale[lang] == nil then
	lang = "english"
end

timing_menu = neutrino_conf:getString("timing.menu", "0")

for line in io.lines(bootfile) do
        i, j = string.find(line, devbase)
        current_root = tonumber(string.sub(line,j+1,j+2))
end

function create_backupfile()
	file = io.open("/tmp/backup.sh", "w")
	file:write("#!/bin/sh", "\n")
	file:write("", "\n")
	file:write("systemctl stop nmb", "\n")
	file:write("systemctl stop udpxy", "\n")
	file:write("systemctl stop nfs-server", "\n")
	file:write("systemctl stop nfs-mountd", "\n")
	file:write("systemctl stop nfs-ststd", "\n")
	file:write("systemctl stop oscam", "\n")
	file:write("systemctl stop cccam", "\n")
	file:write("systemctl stop gbox", "\n")
	file:write("systemctl stop webmin", "\n")
	file:write("systemctl stop rpcbind.socket", "\n")
	file:write("systemctl stop rpcbind", "\n")
	file:write("systemctl stop proftpd", "\n")
	file:write("systemctl stop minidlna", "\n")
	file:write("systemctl stop autofs", "\n")
	file:write("systemctl stop ntpdate", "\n")
	file:write("systemctl -q stop etckeeper", "\n")
	file:write("systemctl stop dbus.socket", "\n")
	file:write("systemctl stop dbus", "\n")
	file:write("systemctl stop telnet", "\n")
	file:write("systemctl stop sshd.socket", "\n")
	file:write("systemctl stop mnt-partition_1.automount", "\n")
	file:write("systemctl stop mnt-partition_2.automount", "\n")
	file:write("systemctl stop mnt-partition_3.automount", "\n")
	file:write("systemctl stop mnt-partition_4.automount", "\n")
	file:write("systemctl stop mnt-partition_1.mount", "\n")
	file:write("systemctl stop mnt-partition_2.mount", "\n")
	file:write("systemctl stop mnt-partition_3.mount", "\n")
	file:write("systemctl stop mnt-partition_4.mount", "\n")
	file:write("mkdir -p /tmp/tmproot", "\n")
	file:write("mkdir -p /tmp/tmproot/media/hdd", "\n")
	file:write("mkdir -p /tmp/tmproot/lib/systemd/system/multi-user.target.wants", "\n")
	file:write("mount -t tmpfs none /tmp/tmproot", "\n")
	file:write("cp -ax / /tmp/tmproot", "\n")
	file:write("rm -rf /tmp/tmproot/lib/systemd/system/mnt-partition*", "\n")
	file:write("rm -rf /tmp/tmproot/lib/systemd/system/multi-user.target.wants/mnt-partition*", "\n")
	file:write("rm -rf /tmp/tmproot/lib/systemd/system/mount@.service", "\n")
	file:write("rm -rf /tmp/tmproot/lib/systemd/system/local-fs.target.wants/mount@.service", "\n")
	file:write("cp -rf /tmp/tmproot/lib/systemd/system/backup@.service /tmp/tmproot/lib/systemd/system/backup@" .. backup_partition .. ".service", "\n")
	file:write("ln -sf /lib/systemd/system/backup@" .. backup_partition .. ".service /tmp/tmproot/lib/systemd/system/multi-user.target.wants/", "\n")
	file:write("systemctl switch-root --force /tmp/tmproot", "\n")
	file:close()
	file = os.execute('chmod +x "/tmp/backup.sh"')
end

function basename(str)
        local name = string.gsub(str, "(.*/)(.*)", "%2")
        return name
end

function get_imagename(root)
        local glob = require "posix".glob
        for _, j in pairs(glob('/boot/*', 0)) do
                for line in io.lines(j) do
                        if (j ~= bootfile) then
                                if line:match(devbase .. root) then
                                        imagename = basename(j)
                                end
                        end
                end
        end
        return imagename
end

chooser_dx = n:scale2Res(600)
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
	btnRed = get_imagename(3),
	btnGreen = get_imagename(5),
	btnYellow = get_imagename(7),
	btnBlue = get_imagename(9)
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
	backup_partition = 1
	root = 3
	colorkey = true
elseif (msg == RC['green']) then
	backup_partition = 2
	root = 5
	colorkey = true
elseif (msg == RC['yellow']) then
	backup_partition = 3
	root = 7
	colorkey = true
elseif (msg == RC['blue']) then
	backup_partition = 4
	root = 9
	colorkey = true
end

until msg == RC['home'] or colorkey or backup_image or i == t

chooser:hide()


if colorkey then
	res = messagebox.exec {
	title = caption,
	icon = "settings",
	text = locale[lang].start_partition1 .. get_imagename(root) .. locale[lang].start_partition2,
	timeout = 0,
	buttons={ "yes", "no" }
	}
	if res == "yes" then
		if (root == current_root) then
			local ret = hintbox.new { title = caption, icon = "settings", text = locale[lang].prepare_system };
			ret:paint()
			create_backupfile()
			local file = assert(io.popen("/tmp/backup.sh", 'r'))
		else
			local file = assert(io.popen("systemctl start backup@" .. backup_partition, 'r'))
		end
	return
	end
end
