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

caption = "Browser"

n = neutrino()
m = menu.new{name="Chromium Webengine", icon="multimedia"}
locale = {}
locale["deutsch"] = {
        browser = "Browser",
        netflix = "Netflix",
        ard = "ARD Mediathek",
        zdf = "ZDF Mediathek",
        arte = "arte Mediathek",
        dreisat = "3sat Mediathek",
        youtube = "Youtube",
        options = "Einstellungen",
        resolution = "Auflösung ändern",
        scale = "Skalierung ändern",
        keymap = "Tastaturlayout ändern"
}

locale["english"] = {
        browser = "Browser",
        netflix = "Netflix",
        ard = "ARD Media library",
        zdf = "ZDF Media library",
        arte = "arte Media library",
        dreisat = "3sat Media library",
        youtube = "Youtube",
        options = "Options",
        resolution = "Change Resolution",
        scale = "Change scale",
        keymap = "Change keymap"
}

o = menu.new{name="Einstellungen", icon="settings"}
neutrino_conf = configfile.new()
neutrino_conf:loadConfig("/etc/neutrino/config/neutrino.conf")
lang = neutrino_conf:getString("language", "english")

if locale[lang] == nil then lang = "deutsch" end

function main()
        m:addItem{type="back"}
        m:addItem{type="separatorline"}
        m:addItem{type="forwarder", name=locale[lang].browser, icon="1", action="start_browser", directkey=RC["1"]};
        m:addItem{type="forwarder", name=locale[lang].netflix, icon="2", action="start_netflix", directkey=RC["2"]};
        m:addItem{type="forwarder", name=locale[lang].ard, icon="3", action="start_ardmediathek", directkey=RC["3"]};
        m:addItem{type="forwarder", name=locale[lang].zdf, icon="4", action="start_zdfmediathek", directkey=RC["4"]};
        m:addItem{type="forwarder", name=locale[lang].arte, icon="5", action="start_artemediathek", directkey=RC["5"]};
        m:addItem{type="forwarder", name=locale[lang].dreisat, icon="6", action="start_3satmediathek", directkey=RC["6"]};
        m:addItem{type="forwarder", name=locale[lang].youtube, icon="7", action="start_youtube", directkey=RC["7"]};
        m:addItem{type="separatorline"};
        m:addItem{type="forwarder", name=locale[lang].options, icon="menu", action="start_options", directkey=RC["setup"]};
        o:addItem{type="back"}
        o:addItem{type="chooser", name=locale[lang].resolution, icon="1", action="change_resolution", value=get_resolution(), options={"1080p", "720p", "480p"}, directkey=RC["1"]};
        o:addItem{type="chooser", name=locale[lang].scale, icon="2", action="change_scale", value=get_value("QT_SCALE_FACTOR"), options={"0.5", "1", "1.5", "2"}, directkey=RC["2"]};
        o:addItem{type="chooser", name=locale[lang].keymap, icon="3", action="change_keymap", value=get_value("XKB_DEFAULT_LAYOUT"), options={"de", "us", "fr", "ru", "cz", "pl", "nl"}, directkey=RC["3"]};
        m:exec()
end

function start_browser()
        m:hide()
        os.execute("systemctl start browser")
end

function start_netflix()
        m:hide()
        os.execute("systemctl start qtwebflix")
end

function start_ardmediathek()
        m:hide()
        os.execute("systemctl start ardmediathek")
end

function start_zdfmediathek()
        m:hide()
        os.execute("systemctl start zdfmediathek")
end

function start_artemediathek()
        m:hide()
        os.execute("systemctl start artemediathek")
end

function start_3satmediathek()
        m:hide()
        os.execute("systemctl start 3satmediathek")
end

function start_youtube()
        m:hide()
        os.execute("systemctl start youtube")
end

function get_value(str)
        for line in io.lines("/etc/environment") do
                if line:match(str .. "=") then
                        local i,j = string.find(line, str .. "=")
                        value = (string.sub(line, j+1, #line))
                        return value
                end
        end
end

function change_resolution(k,v)
        local env_lines = {}
        for line in io.lines("/etc/environment") do
                if v == "1080p" then
                        if string.find(line, "QT_QPA_EGLFS_WIDTH=") then
                                line = line:gsub(get_value("QT_QPA_EGLFS_WIDTH"), "1920")
                        elseif string.find(line, "QT_QPA_EGLFS_HEIGHT=") then
                                line = line:gsub(get_value("QT_QPA_EGLFS_HEIGHT"), "1080")
                        end
                elseif v == "720p" then
                        if string.find(line, "QT_QPA_EGLFS_WIDTH=") then
                                line = line:gsub(get_value("QT_QPA_EGLFS_WIDTH"), "1280")
                        elseif string.find(line, "QT_QPA_EGLFS_HEIGHT=") then
                                line = line:gsub(get_value("QT_QPA_EGLFS_HEIGHT"), "720")
                        end
                elseif v == "480p" then
                        if string.find(line, "QT_QPA_EGLFS_WIDTH=") then
                                line = line:gsub(get_value("QT_QPA_EGLFS_WIDTH"), "640")
                        elseif string.find(line, "QT_QPA_EGLFS_HEIGHT=") then
                                line = line:gsub(get_value("QT_QPA_EGLFS_HEIGHT"), "480")
                        end
                end
                table.insert(env_lines, line)
        end
        file = io.open("/etc/environment", 'w')
        for _, v in ipairs(env_lines) do
                file:write(v, "\n")
        end
        file:close()
end

function change_scale(k,v)
        local env_lines = {}
        for line in io.lines("/etc/environment") do
                if v == "0.5" then
                        if string.find(line, "QT_SCALE_FACTOR=") then
                                line = line:gsub(get_value("QT_SCALE_FACTOR"), "0.5")
                        end
                elseif v == "1" then
                        if string.find(line, "QT_SCALE_FACTOR=") then
                                line = line:gsub(get_value("QT_SCALE_FACTOR"), "1")
                        end
                elseif v == "1.5" then
                        if string.find(line, "QT_SCALE_FACTOR=") then
                                line = line:gsub(get_value("QT_SCALE_FACTOR"), "1.5")
                        end
                elseif v == "2" then
                        if string.find(line, "QT_SCALE_FACTOR=") then
                                line = line:gsub(get_value("QT_SCALE_FACTOR"), "2")
                        end
                end
                table.insert(env_lines, line)
        end
        file = io.open("/etc/environment", 'w')
        for _, v in ipairs(env_lines) do
                file:write(v, "\n")
        end
        file:close()
end

function change_keymap(k,v)
        local env_lines = {}
        for line in io.lines("/etc/environment") do
                if v == "de" then
                        if string.find(line, "XKB_DEFAULT_LAYOUT=") then
                                line = line:gsub(get_value("XKB_DEFAULT_LAYOUT"), "de")
                        end
                elseif v == "us" then
                        if string.find(line, "XKB_DEFAULT_LAYOUT=") then
                                line = line:gsub(get_value("XKB_DEFAULT_LAYOUT"), "us")
                        end
                elseif v == "fr" then
                        if string.find(line, "XKB_DEFAULT_LAYOUT=") then
                                line = line:gsub(get_value("XKB_DEFAULT_LAYOUT"), "fr")
                        end
                elseif v == "ru" then
                        if string.find(line, "XKB_DEFAULT_LAYOUT=") then
                                line = line:gsub(get_value("XKB_DEFAULT_LAYOUT"), "ru")
                        end
                elseif v == "cz" then
                        if string.find(line, "XKB_DEFAULT_LAYOUT=") then
                                line = line:gsub(get_value("XKB_DEFAULT_LAYOUT"), "cz")
                        end
                elseif v == "pl" then
                        if string.find(line, "XKB_DEFAULT_LAYOUT=") then
                                line = line:gsub(get_value("XKB_DEFAULT_LAYOUT"), "pl")
                        end
                elseif v == "nl" then
                        if string.find(line, "XKB_DEFAULT_LAYOUT=") then
                                line = line:gsub(get_value("XKB_DEFAULT_LAYOUT"), "nl")
                        end
                end
                table.insert(env_lines, line)
        end
        file = io.open("/etc/environment", 'w')
        for _, v in ipairs(env_lines) do
                file:write(v, "\n")
        end
        file:close()
end

function get_resolution()
for line in io.lines("/etc/environment") do
        if line:match("QT_QPA_EGLFS_WIDTH") then
                local i,j = string.find(line, "QT_QPA_EGLFS_WIDTH=")
                value = tonumber((string.sub(line, j+1, #line)))
                if value == 1920 then return "1080p" end
                if value == 1280 then return "720p" end
                if value == 640 then return "480p" end
                end
        end
end

function start_options()
        m:hide()
        o:exec()
        o:hide()
end

main()
