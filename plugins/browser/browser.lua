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
local g = {}
locale = {}
locale["deutsch"] = {
locale_browser = "Browser",
locale_netflix = "Netflix",
locale_ard = "ARD Mediathek",
locale_zdf = "ZDF Mediathek",
locale_arte = "arte Mediathek",
locale_3sat = "3sat Mediathek",
locale_youtube = "Youtube"
}

neutrino_conf = configfile.new()
neutrino_conf:loadConfig("/etc/neutrino/config/neutrino.conf")
lang = neutrino_conf:getString("language", "english")

if locale[lang] == nil then lang = "deutsch" end

function main()
        m:addItem{type="back"}m:addItem{type="separatorline"}
        m:addItem{type="forwarder", name=locale[lang].locale_browser, icon="1", action="start_browser", directkey=RC["1"]};
        m:addItem{type="forwarder", name=locale[lang].locale_netflix, icon="2", action="start_netflix", directkey=RC["2"]};
        m:addItem{type="forwarder", name=locale[lang].locale_ard, icon="3", action="start_ardmediathek", directkey=RC["3"]};
        m:addItem{type="forwarder", name=locale[lang].locale_zdf, icon="4", action="start_zdfmediathek", directkey=RC["4"]};
        m:addItem{type="forwarder", name=locale[lang].locale_arte, icon="5", action="start_artemediathek", directkey=RC["5"]};
        m:addItem{type="forwarder", name=locale[lang].locale_3sat, icon="6", action="start_3satmediathek", directkey=RC["6"]};
        m:addItem{type="forwarder", name=locale[lang].locale_youtube, icon="7", action="start_youtube", directkey=RC["7"]};
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

main()

