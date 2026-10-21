-- NI-XStreamity 0.20.7 - Live TV, Favoriten per Farbtaste
-- Lua 5.2 / cjson / curl
local config_path = '/var/tuxbox/config/xstreamity.conf'
local startup_needs_setup = false
local function trim(s) return (s:gsub('^%s+', ''):gsub('%s+$', '')) end
local function read_config(path)
  local f, err = io.open(path, 'r')
  if not f then return nil, 'Konfiguration fehlt: ' .. tostring(err) end
  local cfg = {}
  for line in f:lines() do
    if not line:match('^%s*[#;]') then
      local k, v = line:match('^%s*([%w_]+)%s*=%s*(.-)%s*$')
      if k then cfg[k] = trim(v) end
    end
  end
  f:close()
  for _, k in ipairs({'server', 'username', 'password'}) do
    if not cfg[k] or cfg[k] == '' then return nil, 'Eintrag fehlt: ' .. k end
  end
  if not cfg.server:match('^https?://') or cfg.server:find('[\r\n]') then
    return nil, 'Ungueltige Serveradresse'
  end
  cfg.server = cfg.server:gsub('/+$', '')
  return cfg
end
local function encode(s)
  return (s:gsub('([^%w%-_%.~])', function(c) return string.format('%%%02X', c:byte()) end))
end
local function shellquote(s)
  return "'" .. tostring(s):gsub("'", "'\\''") .. "'"
end
local json = require('cjson')
local function api_request(cfg, action, category_id, vod_id, series_id, stream_id, epg_limit)
  local url = cfg.server .. '/player_api.php?username=' .. encode(cfg.username)
      .. '&password=' .. encode(cfg.password)
  if action then url = url .. '&action=' .. encode(action) end
  if category_id then url = url .. '&category_id=' .. encode(category_id) end
  if vod_id then url = url .. '&vod_id=' .. encode(vod_id) end
  if series_id then url = url .. '&series_id=' .. encode(series_id) end
  if stream_id then url = url .. '&stream_id=' .. encode(stream_id) end
  if epg_limit then url = url .. '&limit=' .. encode(tostring(epg_limit)) end
  -- Avoid putting secrets into shell command strings or process arguments:
  -- Use a private temporary curl config file instead.
  local mk = io.popen('mktemp /tmp/ni-xstreamity.XXXXXX', 'r')
  if not mk then return nil, 'mktemp konnte nicht gestartet werden' end
  local tmp = mk:read('*l')
  mk:close()
  if not tmp or tmp == '' then return nil, 'Keine temporaere Datei moeglich' end
  local f, err = io.open(tmp, 'w')
  if not f then os.remove(tmp); return nil, 'Temporaere Datei nicht moeglich: ' .. tostring(err) end
  -- curl config uses quoted strings with backslash and double quote escaping.
  local safe_url = url:gsub('\\', '\\\\'):gsub('"', '\\"')
  f:write('url = "', safe_url, '"\n')
  f:close()
  local cmd = 'curl --silent --show-error --fail --location --max-time 25 --connect-timeout 8 --globoff --config ' .. shellquote(tmp) .. ' 2>/dev/null'
  local pipe = io.popen(cmd, 'r')
  if not pipe then os.remove(tmp); return nil, 'curl konnte nicht gestartet werden' end
  local body = pipe:read('*a')
  local ok = pipe:close()
  os.remove(tmp)
  if not ok or body == '' then return nil, 'Keine gueltige HTTP-Antwort (Server/Netzwerk pruefen)' end
  local parsed, data = pcall(json.decode, body)
  if not parsed or type(data) ~= 'table' then return nil, 'Antwort ist kein gueltiges JSON' end
  return data
end

-- NI-XStreamity 0.20.7 - single active menu / state-machine navigation.
-- Requires Neutrino Lua n_gui for graphical operation.
local cfg, categories, category_by_id
local server_status = "Unbekannt"
local account_status = "Unbekannt"
local expiry_status = nil
local state = 'home'
local settings = nil
local settings_message = 'Noch nicht getestet'
local selected_category_id = nil
local stream_cache = {}
local vod_categories = {}
local vod_error = nil
local vod_category_by_id = {}
local selected_vod_category_id = nil
local vod_movie_cache = {}
local active_vod_menu = nil
local active_vod_movies_by_id = nil
local active_vod_rows = nil
local selected_vod_info_movie = nil
local active_vod_info_menu = nil
local vod_info_cache = {}
local series_categories, series_category_by_id = {}, {}
local selected_series_category_id, selected_series, selected_season
local series_list_cache, series_info_cache = {}, {}
local active_series_menu, active_series_rows, active_series_lookup
local active_series_list_menu, active_series_list_rows
local active_episode_lookup
local player
local active_stream_menu = nil
local active_stream_rows = nil -- zero-based menu index -> stream id
local add_wrapped_info
local selected_epg_stream = nil
local epg_cache = {}
local legacy_favorites_path = '/var/tuxbox/config/xstreamity_favorites.json'
local favorites_path = legacy_favorites_path
local profiles_path = '/var/tuxbox/config/xstreamity_servers.json'
local profiles, active_profile_id, editing_new_profile = {}, 1, false
local profiles_error = nil
local function atomic_json_write(path, data)
  local ok, encoded = pcall(json.encode, data)
  if not ok then return false, 'JSON-Kodierung fehlgeschlagen' end
  local mk = io.popen('mktemp ' .. shellquote(path .. '.XXXXXX'), 'r')
  if not mk then return false, 'Temporäre Datei nicht moeglich' end
  local tmp = mk:read('*l'); mk:close()
  if not tmp or tmp == '' then return false, 'Temporäre Datei nicht moeglich' end
  local f = io.open(tmp, 'w')
  if not f then os.remove(tmp); return false, 'Datei nicht beschreibbar' end
  f:write(encoded, '\n'); f:close()
  os.execute('chmod 600 ' .. shellquote(tmp))
  if not os.rename(tmp, path) then os.remove(tmp); return false, 'Speichern fehlgeschlagen' end
  return true
end
local function profile_by_id(id)
  for _, p in ipairs(profiles) do if p.id == id then return p end end
end
local function profile_favorites_path(id)
  if id == 1 then return legacy_favorites_path end
  return '/var/tuxbox/config/xstreamity_favorites_' .. tostring(id) .. '.json'
end
local function save_profiles()
  if profiles_error then return false, profiles_error end
  return atomic_json_write(profiles_path, {version=1, active=active_profile_id, servers=profiles})
end
local function load_profiles()
  local f = io.open(profiles_path, 'r')
  if not f then
    profiles = {{id=1, name='Server 1', server=cfg.server, username=cfg.username, password=cfg.password}}
    active_profile_id = 1
    return true
  end
  local raw = f:read('*a'); f:close()
  local ok, data = pcall(json.decode, raw)
  if not ok or type(data) ~= 'table' or type(data.servers) ~= 'table' or #data.servers == 0 then
    profiles_error = 'Serverprofile-Datei ungueltig (wird nicht ueberschrieben)'
    return false
  end
  local found, ids = {}, {}
  for _, p in ipairs(data.servers) do
    if type(p) ~= 'table' or type(p.id) ~= 'number' or p.id < 1 or p.id % 1 ~= 0 or ids[p.id]
       or type(p.server) ~= 'string' or type(p.username) ~= 'string' or type(p.password) ~= 'string'
       or type(p.name) ~= 'string' then
      profiles_error = 'Serverprofile-Daten ungueltig (werden nicht ueberschrieben)'
      return false
    end
    ids[p.id] = true
    found[#found+1] = p
  end
  profiles = found
  active_profile_id = tonumber(data.active) or 1
  local active = profile_by_id(active_profile_id)
  if not active then active_profile_id = profiles[1].id; active = profiles[1] end
  cfg = {server=active.server, username=active.username, password=active.password}
  return true
end
local function reset_server_cache()
  categories, category_by_id, stream_cache = {}, {}, {}
  vod_categories, vod_category_by_id, vod_movie_cache, vod_info_cache = {}, {}, {}, {}
  series_categories, series_category_by_id, series_list_cache, series_info_cache = {}, {}, {}, {}
  epg_cache = {}
  server_status, account_status, expiry_status = 'Unbekannt', 'Unbekannt', nil
end
local favorites = {}
local favorites_index = {}
local favorites_writable = true
local function load_favorites()
  favorites, favorites_index, favorites_writable = {}, {}, true
  favorites_path = profile_favorites_path(active_profile_id)
  local f = io.open(favorites_path, 'r')
  if not f then return end
  local raw = f:read('*a'); f:close()
  local ok, data = pcall(json.decode, raw)
  if not ok or type(data) ~= 'table' then
    print('NI-XStreamity: Favoriten-Datei ungueltig, wird nicht ueberschrieben')
    favorites_writable = false
    return false
  end
  for _, s in ipairs(data) do
    if type(s) == 'table' and tostring(s.stream_id or ''):match('^%d+$')
        and type(s.name) == 'string' then
      local id = tostring(s.stream_id)
      if not favorites_index[id] then
        local entry = {stream_id=id, name=s.name, container_extension=s.container_extension}
        favorites[#favorites+1] = entry
        favorites_index[id] = entry
      end
    end
  end
  return true
end
local function save_favorites()
  if not favorites_writable then return false end
  local path = favorites_path .. '.tmp'
  local f, err = io.open(path, 'w')
  if not f then print('NI-XStreamity: Favoriten nicht speicherbar: ' .. tostring(err)); return false end
  local ok, data = pcall(json.encode, favorites)
  if not ok then f:close(); os.remove(path); return false end
  f:write(data, '\n'); f:close()
  os.execute('chmod 600 ' .. shellquote(path))
  if not os.rename(path, favorites_path) then
    os.remove(path)
    print('NI-XStreamity: Favoriten konnten nicht gespeichert werden')
    return false
  end
  return true
end


local function clean(s)
  return tostring(s or ''):gsub('[\r\n\t]', ' ')
end

-- Status and categories are refreshed together. A failed request must not
-- prevent opening the GUI: it should display the problem and offer a retry.
local sorted_categories
local function api_categories()
  local a, e = api_request(cfg)
  if not a then
    server_status = 'Nicht erreichbar'
    account_status = 'Unbekannt'
    expiry_status = nil
    return nil, e
  end
  server_status = 'Online (API antwortet)'
  local info = type(a.user_info) == 'table' and a.user_info or {}
  local active = tonumber(info.auth) == 1 and tostring(info.status or ''):lower() == 'active'
  account_status = active and 'Aktiv' or ('Nicht aktiv (' .. clean(info.status or 'unbekannt') .. ')')
  expiry_status = nil
  local expiry = tonumber(info.exp_date)
  if expiry and expiry > 0 then
    local ok, date = pcall(os.date, '%d.%m.%Y', expiry)
    if ok and date then expiry_status = date end
  end
  if not active then return nil, 'Xtream-Zugang ist nicht aktiv' end
  local c, ce = api_request(cfg, 'get_live_categories')
  if not c then return nil, ce end
  if type(c) ~= 'table' then return nil, 'Kategorien-Antwort ist keine Liste' end
  return c
end

local function refresh_categories()
  local new_categories, err = api_categories()
  if new_categories then
    categories = sorted_categories(new_categories)
    category_by_id = {}
    for _, c in ipairs(categories) do
      category_by_id[tostring(c.category_id)] = c
    end
    stream_cache = {}
    print('NI-XStreamity: ' .. #categories .. ' Kategorien geladen')
  else
    categories = {}
    category_by_id = {}
    stream_cache = {}
    print('NI-XStreamity: Statuspruefung: ' .. clean(err))
  end
end

-- Edit credentials in memory; write only on explicit save.
local function settings_valid(s)
  if not s or not s.server or not s.username then return false end
  local password = s.password_changed and s.password or cfg.password
  if type(password) ~= 'string' or password == '' or #password > 256
      or password:find('[\r\n]') then return false end
  local server = trim(s.server):gsub('/+$', '')
  local username = trim(s.username)
  if server == '' or username == '' or #server > 256 or #username > 128 then return false end
  if server:find('[\r\n]') or username:find('[\r\n]') then return false end
  -- Restrict server to an HTTP(S) origin; avoid URL userinfo and query fragments.
  if not server:match('^https?://[%w%.%-]+:?%d*$') then return false end
  return true
end

local function save_settings(s)
  if not settings_valid(s) then return false, 'Ungueltige Serveradresse, Benutzername oder Passwort' end
  local server = trim(s.server):gsub('/+$', '')
  local username = trim(s.username)
  -- Use a private temp file in the same directory, then atomic rename.
  local mk = io.popen('mktemp ' .. shellquote(config_path .. '.XXXXXX'), 'r')
  if not mk then return false, 'Temporäre Datei nicht moeglich' end
  local tmp = mk:read('*l')
  mk:close()
  if not tmp or tmp == '' then return false, 'Temporäre Datei nicht moeglich' end
  local f = io.open(tmp, 'w')
  if not f then os.remove(tmp); return false, 'Konfigurationsdatei nicht beschreibbar' end
  local password = s.password_changed and s.password or cfg.password
  f:write('server=', server, '\nusername=', username, '\npassword=', password, '\n')
  f:close()
  os.execute('chmod 600 ' .. shellquote(tmp))
  if not os.rename(tmp, config_path) then
    os.remove(tmp)
    return false, 'Speichern fehlgeschlagen'
  end
  cfg.server, cfg.username, cfg.password = server, username, password
  return true
end

local function is_german(name)
  local u = clean(name):upper()
  return u:match('^%s*|DE|') or u:match('^%s*DE%s*[%-%|]')
      or u:find('GERMANY', 1, true) or u:find('DEUTSCHLAND', 1, true)
end

sorted_categories = function(input)
  local de, other = {}, {}
  for _, c in ipairs(input) do
    if type(c) == 'table' and tostring(c.category_id or ''):match('^%d+$') then
      if is_german(c.category_name) then de[#de+1] = c
      else other[#other+1] = c end
    end
  end
  -- Preserve the server's original order inside each group.
  for _, c in ipairs(other) do de[#de+1] = c end
  return de
end

local function stream_url(s)
  local id = tostring(s.stream_id or '')
  if not id:match('^%d+$') then return nil end
  local ext = tostring(s.container_extension or 'ts'):lower()
  if ext ~= 'ts' and ext ~= 'm3u8' and ext ~= 'mp4' then ext = 'ts' end
  return cfg.server .. '/live/' .. encode(cfg.username) .. '/' .. encode(cfg.password)
    .. '/' .. id .. '.' .. ext
end

-- IMPORTANT: callbacks only set the next state. No nested menu:exec() calls.
function xs06_category(k, v)
  local id = tostring(k or '')
  if category_by_id[id] then
    selected_category_id = id
    state = 'streams'
    return MENU_RETURN.EXIT_ALL
  end
  return MENU_RETURN.REPAINT
end

function xs08_favorites(k, v)
  selected_category_id = '__favorites__'
  state = active_stream_menu and 'open_favorites' or 'streams'
  return MENU_RETURN.EXIT_ALL
end

-- The action is registered as a global function by Neutrino's Lua binding.
-- For green, resolve the selected menu row instead of using addKey's fixed id.
function xs09_green(k, v)
  if not active_stream_menu or not active_stream_rows then return MENU_RETURN.REPAINT end
  local pos = active_stream_menu:getSelected()
  local id = active_stream_rows[pos]
  if not id then return MENU_RETURN.REPAINT end
  local s = xs_stream_by_id and xs_stream_by_id[id]
  if not s then return MENU_RETURN.REPAINT end
  local old = favorites_index[id]
  if old then
    for i, entry in ipairs(favorites) do
      if tostring(entry.stream_id) == id then table.remove(favorites, i); break end
    end
    favorites_index[id] = nil
    print('NI-XStreamity: Favorit entfernt: ' .. clean(s.name))
  else
    local entry = {stream_id=id, name=clean(s.name), container_extension=s.container_extension}
    favorites[#favorites+1] = entry
    favorites_index[id] = entry
    print('NI-XStreamity: Favorit hinzugefuegt: ' .. clean(s.name))
  end
  if not save_favorites() then
    print('NI-XStreamity: Achtung, Favoritenaenderung nicht gespeichert')
  end
  -- Close menu so the favorite markers and favorite list can be rebuilt.
  state = 'rebuild_streams'
  return MENU_RETURN.EXIT_ALL
end

-- v0.20.2: BLUE opens the selected live channel's EPG via get_simple_data_table.
function xs19_epg_key()
  if not active_stream_menu or not active_stream_rows then return MENU_RETURN.REPAINT end
  local ok, pos = pcall(function() return active_stream_menu:getSelected() end)
  if not ok then return MENU_RETURN.REPAINT end
  local id = active_stream_rows[pos]
  local channel = id and xs_stream_by_id and xs_stream_by_id[id]
  if not channel then return MENU_RETURN.REPAINT end
  selected_epg_stream = {stream_id=id, name=channel.name}
  state = 'live_epg'
  return MENU_RETURN.EXIT_ALL
end

function xs19_epg_back()
  state = 'streams'
  return MENU_RETURN.EXIT_ALL
end

-- Xtream short-EPG text is commonly base64 encoded.
local function xs19_decode_base64(value)
  if type(value) ~= 'string' then return '' end
  if value == '' then return '' end
  if not value:match('^[A-Za-z0-9+/=\r\n]+$') or (#(value:gsub('%s','')) % 4 ~= 0) then return value end
  local alphabet = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/'
  local bits, count, out = 0, 0, {}
  for c in value:gmatch('[^=\r\n]') do
    local n = alphabet:find(c, 1, true)
    if not n then return value end
    bits = bits * 64 + (n - 1)
    count = count + 6
    if count >= 8 then
      count = count - 8
      local byte = math.floor(bits / (2 ^ count))
      out[#out+1] = string.char(byte % 256)
      bits = bits % (2 ^ count)
    end
  end
  return table.concat(out)
end

local selected_epg_entry = nil
local epg_entries = {}

function xs191_epg_select(k)
  local index = tonumber(k)
  if not index or not epg_entries[index] then return MENU_RETURN.REPAINT end
  selected_epg_entry = epg_entries[index]
  state = 'live_epg_detail'
  return MENU_RETURN.EXIT_ALL
end

function xs191_epg_detail_back()
  state = 'live_epg'
  return MENU_RETURN.EXIT_ALL
end

local function xs191_epg_time(entry)
  local start = clean(entry.start or entry.start_timestamp or '')
  local finish = clean(entry['end'] or entry.stop or entry.stop_timestamp or '')
  local when = start:sub(1, 16)
  if #finish >= 16 then when = when .. ' - ' .. finish:sub(12, 16) end
  return when
end

local function xs191_epg_detail_menu()
  local entry = selected_epg_entry
  if not entry then state = 'live_epg'; return end
  local title = xs19_decode_base64(entry.title or ''):gsub('[\r\n]', ' ')
  local desc = xs19_decode_base64(entry.description or ''):gsub('[\r\n]', ' ')
  local m = menu.new{name='EPG: ' .. (title ~= '' and title or 'Ohne Titel')}
  m:addItem{type='forwarder', name='Zurueck zur EPG-Liste', action='xs191_epg_detail_back'}
  m:addItem{type='separatorline'}
  m:addItem{type='subhead', name=xs191_epg_time(entry)}
  m:addItem{type='separatorline'}
  if desc ~= '' then add_wrapped_info(m, 'Beschreibung', desc)
  else m:addItem{type='subhead', name='Keine Beschreibung vorhanden'} end
  m:exec()
  if state == 'live_epg_detail' then state = 'live_epg' end
end

-- Live EPG: keep the full API response cached for later Catch-up support.
-- Compare provider's displayed local end time to receiver local time.
-- ISO-like YYYY-MM-DD HH:MM:SS sorts lexicographically.
local function xs194_is_current_or_future(entry, now)
  local finish = entry['end'] or entry.stop
  if type(finish) == 'string' then
    local day, clock = finish:match('^(%d%d%d%d%-%d%d%-%d%d)[ T](%d%d:%d%d)')
    if day and clock then
      local local_end = day .. ' ' .. (clock:len() == 5 and (clock .. ':00') or clock)
      return local_end > now
    end
  end
  -- If no parseable local time is present, retain the entry instead of losing data.
  return true
end

local function xs19_epg_menu()
  local channel = selected_epg_stream
  if not channel then state = 'streams'; return end
  local id = tostring(channel.stream_id)
  local data = epg_cache[id]
  local err
  if not data then
    data, err = api_request(cfg, 'get_simple_data_table', nil, nil, nil, id)
    if type(data) == 'table' then epg_cache[id] = data else data = nil end
  end
  local m = menu.new{name='EPG: ' .. clean(channel.name)}
  m:addItem{type='forwarder', name='Zurueck zur Senderliste', action='xs19_epg_back'}
  m:addItem{type='separatorline'}
  epg_entries = {}
  if not data then
    m:addItem{type='subhead', name='EPG konnte nicht geladen werden: ' .. clean(err)}
  else
    local listings = type(data.epg_listings) == 'table' and data.epg_listings or {}
    -- Providers can return a list directly or wrap it in epg_listings.
    if #listings == 0 and #data > 0 then listings = data end
    local now = os.date('%Y-%m-%d %H:%M:%S')
    local visible = {}
    for _, entry in ipairs(listings) do
      if type(entry) == 'table' and xs194_is_current_or_future(entry, now) then
        visible[#visible+1] = entry
      end
    end
    -- Sorting is only necessary if provider order is unusual; the string start
    -- field is in the same format as displayed by the original EPG menu.
    table.sort(visible, function(a, b)
      return tostring(a.start or '') < tostring(b.start or '')
    end)
    m:addItem{type='subhead', name=tostring(#visible) .. ' aktuelle/kommende Sendungen'}
    m:addItem{type='separatorline'}
    for i, entry in ipairs(visible) do
      if i > 100 then break end
      local title = xs19_decode_base64(entry.title or ''):gsub('[\r\n]', ' ')
      epg_entries[i] = entry
      m:addItem{type='forwarder', name=xs191_epg_time(entry) .. '  ' .. (title ~= '' and title or 'Ohne Titel'),
        action='xs191_epg_select', id=tostring(i)}
    end
    if #visible == 0 then m:addItem{type='subhead', name='Keine aktuellen oder kommenden Sendungen gefunden'} end
    print('NI-XStreamity: get_simple_data_table: ' .. #listings .. ' Eintraege fuer Sender-ID ' .. id)
  end
  m:exec()
  if state == 'live_epg' then state = 'streams' end
end

function xs06_stream(k, v)
  local id = tostring(k or '')
  local s = xs_stream_by_id and xs_stream_by_id[id]
  if not s then return MENU_RETURN.REPAINT end
  local url = stream_url(s)
  if not url then
    print('NI-XStreamity: Ungueltige Stream-ID')
    return MENU_RETURN.REPAINT
  end
  if not player then
    local ok, result = pcall(function() return video.new() end)
    if not ok or not result then
      print('NI-XStreamity: Videoplayer nicht verfuegbar')
      return MENU_RETURN.REPAINT
    end
    player = result
  end
  local title = clean(s.name)
  print('NI-XStreamity: Starte ' .. title)
  -- Hide the active channel menu before entering the synchronous player.
  -- Playback still runs INSIDE the callback, as in working version 0.6.1.
  if active_stream_menu then
    local hidden, hide_err = pcall(function() active_stream_menu:hide() end)
    if not hidden then print('NI-XStreamity: Menue konnte nicht ausgeblendet werden') end
  end
  -- Match 0.5: start playback synchronously inside n_gui callback.
  local ok, status = pcall(function()
    return player:PlayFile(title, url, 'NI-XStreamity Live-TV', title)
  end)
  if not ok then
    print('NI-XStreamity: Wiedergabefehler (URL verborgen)')
  elseif PLAYSTATE and status == PLAYSTATE.LEAVE_ALL then
    state = 'exit'
    return MENU_RETURN.EXIT_ALL
  end
  return MENU_RETURN.REPAINT
end

function xs06_back(k, v)
  state = (state == 'streams') and (selected_category_id == '__favorites__' and 'home' or 'categories') or (state == 'categories' and 'home' or 'exit')
  return MENU_RETURN.EXIT_ALL
end

local function add_back(m, label)
  -- 'back' is handled natively by n_gui, including EXIT/Home.
  -- A forwarder is used for explicit Back, so the state is changed before exit.
  m:addItem{type='forwarder', name=label, action='xs06_back', id='back'}
  m:addItem{type='separatorline'}
end

function xs10_refresh(k, v)
  state = 'refresh'
  return MENU_RETURN.EXIT_ALL
end

-- Neutrino invokes keyboardinput callbacks globally with (id, value).
function xs11_changed(id, value)
  if settings and (id == 'server' or id == 'username' or id == 'password') then
    if id == 'password' then
      local new_password = tostring(value or '')
      -- An empty editor is not a request to erase the saved password.
      if new_password == '' then
        state = 'settings_rebuild'
        return MENU_RETURN.EXIT_ALL
      end
      settings.password = new_password
      settings.password_changed = true
    else
      settings[id] = tostring(value or '')
    end
    settings_message = 'Aenderungen noch nicht gespeichert'
    state = 'settings_rebuild'
    return MENU_RETURN.EXIT_ALL
  end
  return MENU_RETURN.REPAINT
end

function xs11_open_settings()
  editing_new_profile = false
  settings = {server=cfg.server, username=cfg.username, password_changed=false}
  settings_message = 'Noch nicht getestet'
  state = 'settings'
  return MENU_RETURN.EXIT_ALL
end

-- A separate editor menu keeps the credentials out of the settings overview.
-- The native keyboardinput widget itself still displays its current value;
-- Neutrino has no separate display-value parameter for this widget.
function xs113_edit_field(id)
  if id ~= 'server' and id ~= 'username' and id ~= 'password' then return MENU_RETURN.REPAINT end
  state = 'edit_' .. id
  return MENU_RETURN.EXIT_ALL
end

function xs113_editor_back()
  state = 'settings_rebuild'
  return MENU_RETURN.EXIT_ALL
end

function xs11_test_settings()
  if not settings_valid(settings) then
    settings_message = 'Ungueltige Serveradresse, Benutzername oder Passwort'
  else
    local test_cfg = {server=trim(settings.server):gsub('/+$', ''),
      username=trim(settings.username), password=settings.password_changed and settings.password or cfg.password}
    local data = api_request(test_cfg)
    if not data then
      settings_message = 'Test fehlgeschlagen: Server nicht erreichbar'
    else
      local info = type(data.user_info) == 'table' and data.user_info or {}
      local active = tonumber(info.auth) == 1 and tostring(info.status or ''):lower() == 'active'
      settings_message = active and 'Test erfolgreich: Zugang aktiv' or 'Server erreichbar, Zugang nicht aktiv'
    end
  end
  state = 'settings_rebuild'
  return MENU_RETURN.EXIT_ALL
end

function xs11_save_settings()
  if not settings_valid(settings) then
    settings_message = 'Ungueltige Serveradresse, Benutzername oder Passwort'
    state = 'settings_rebuild'
    return MENU_RETURN.EXIT_ALL
  end
  if profiles_error then
    settings_message = profiles_error
    state = 'settings_rebuild'
    return MENU_RETURN.EXIT_ALL
  end
  local newcfg = {server=trim(settings.server):gsub('/+$', ''),
    username=trim(settings.username),
    password=settings.password_changed and settings.password or cfg.password}
  if editing_new_profile then
    local max_id = 0
    for _, p in ipairs(profiles) do if p.id > max_id then max_id = p.id end end
    local new_id = max_id + 1
    local name = 'Server ' .. tostring(new_id)
    profiles[#profiles+1] = {id=new_id, name=name, server=newcfg.server,
      username=newcfg.username, password=newcfg.password}
    local old_id = active_profile_id
    active_profile_id = new_id
    local ok, err = save_profiles()
    if not ok then
      active_profile_id = old_id; table.remove(profiles)
      settings_message = err; state = 'settings_rebuild'
      return MENU_RETURN.EXIT_ALL
    end
  else
    local active = profile_by_id(active_profile_id)
    if not active then
      settings_message = 'Aktives Serverprofil nicht gefunden'; state = 'settings_rebuild'
      return MENU_RETURN.EXIT_ALL
    end
    local previous = {server=active.server, username=active.username, password=active.password}
    active.server, active.username, active.password = newcfg.server, newcfg.username, newcfg.password
    local ok, err = save_profiles()
    if not ok then
      active.server, active.username, active.password = previous.server, previous.username, previous.password
      settings_message = err; state = 'settings_rebuild'
      return MENU_RETURN.EXIT_ALL
    end
    -- Legacy config is kept in sync only for the original profile.
    if active_profile_id == 1 then
      local saved, saveerr = save_settings(settings)
      if not saved then
        settings_message = saveerr; state = 'settings_rebuild'
        return MENU_RETURN.EXIT_ALL
      end
    end
  end
  cfg = newcfg
  editing_new_profile = false
  settings = nil
  startup_needs_setup = false
  reset_server_cache()
  load_favorites()
  state = 'refresh'
  return MENU_RETURN.EXIT_ALL
end

function xs11_cancel_settings()
  settings = nil
  editing_new_profile = false
  state = startup_needs_setup and 'exit' or 'home'
  return MENU_RETURN.EXIT_ALL
end

local function settings_menu()
  local m = menu.new{name='NI-XStreamity 0.20.7 - Server-Einstellungen'}
  m:addItem{type='forwarder', name='Zurueck (ohne Speichern)',
    action='xs11_cancel_settings', id='cancel'}
  m:addItem{type='separatorline'}
  m:addItem{type='forwarder', name='Serveradresse bearbeiten',
    action='xs113_edit_field', id='server'}
  m:addItem{type='forwarder', name='Benutzername bearbeiten',
    action='xs113_edit_field', id='username'}
  m:addItem{type='forwarder', name='Passwort aendern',
    action='xs113_edit_field', id='password', value='********'}
  m:addItem{type='subhead', name=settings.password_changed
    and 'Neues Passwort vorgemerkt (nicht gespeichert)' or 'Passwort unveraendert'}
  m:addItem{type='separatorline'}
  m:addItem{type='forwarder', name='Verbindung testen',
    action='xs11_test_settings', id='test'}
  m:addItem{type='forwarder', name='Einstellungen speichern',
    action='xs11_save_settings', id='save'}
  m:addItem{type='subhead', name='Status: ' .. clean(settings_message)}
  m:exec()
  -- Native EXIT: discard draft and return to categories.
  if state == 'settings' then xs11_cancel_settings() end
end

local function editor_menu(field)
  local is_server = (field == 'server')
  local is_password = (field == 'password')
  local label = is_server and 'Serveradresse' or (is_password and 'Passwort' or 'Benutzername')
  local m = menu.new{name='NI-XStreamity 0.20.7 - ' .. label}
  m:addItem{type='forwarder', name='Zurueck zu Einstellungen',
    action='xs113_editor_back', id='back'}
  m:addItem{type='separatorline'}
  if is_password then
    -- Never prefill the password (including a pending replacement).
    -- masked=1 is supported by the patched NI-Neutrino Lua binding.
    m:addItem{type='keyboardinput', name='Neues Passwort eingeben',
      value='', size=256, masked=1, action='xs11_changed', id='password'}
  else
    m:addItem{type='keyboardinput', name=label .. ' eingeben',
      value=settings[field], size=is_server and 256 or 128,
      action='xs11_changed', id=field}
  end
  m:exec()
  -- EXIT in the editor returns to settings without discarding the draft.
  if state == 'edit_' .. field then state = 'settings_rebuild' end
end

-- VOD step 3: categories, movie lists and synchronous playback.
function xs13_open_live()
  state = 'categories'
  return MENU_RETURN.EXIT_ALL
end

function xs13_open_vod()
  state = 'vod_load'
  return MENU_RETURN.EXIT_ALL
end

function xs13_vod_back()
  state = 'home'
  return MENU_RETURN.EXIT_ALL
end

function xs13_vod_category(id, value)
  id = tostring(id or '')
  if not vod_category_by_id[id] then return MENU_RETURN.REPAINT end
  selected_vod_category_id = id
  state = 'vod_movies'
  return MENU_RETURN.EXIT_ALL
end

function xs131_vod_movies_back()
  state = 'vod_categories'
  return MENU_RETURN.EXIT_ALL
end

local function vod_movie_url(movie)
  local id = tostring(movie.stream_id or '')
  if not id:match('^%d+$') then return nil end
  -- Xtream VOD uses the movie endpoint, NOT /live/.
  local ext = tostring(movie.container_extension or ''):lower()
  if ext == '' then ext = 'mp4' end
  -- Restrict to known safe extensions; never allow path separators in the URL.
  if ext ~= 'mp4' and ext ~= 'mkv' and ext ~= 'avi' and ext ~= 'ts' and ext ~= 'm3u8' then
    return nil
  end
  return cfg.server .. '/movie/' .. encode(cfg.username) .. '/' .. encode(cfg.password)
    .. '/' .. id .. '.' .. ext
end

-- Shared synchronous player for movie lists and the movie information view.
local function play_vod_movie(movie, source_menu)
  if not movie then return MENU_RETURN.REPAINT end
  local url = vod_movie_url(movie)
  if not url then
    print('NI-XStreamity: Ungueltige Film-ID oder Dateiendung')
    return MENU_RETURN.REPAINT
  end
  if not player then
    local ok, result = pcall(function() return video.new() end)
    if not ok or not result then
      print('NI-XStreamity: Videoplayer nicht verfuegbar')
      return MENU_RETURN.REPAINT
    end
    player = result
  end
  local title = clean(movie.name)
  print('NI-XStreamity: Starte VOD ' .. title)
  -- Keep playback inside the Neutrino callback, as in working v0.14.
  if source_menu then
    local hidden = pcall(function() source_menu:hide() end)
    if not hidden then print('NI-XStreamity: Filmmenue konnte nicht ausgeblendet werden') end
  end
  local ok, status = pcall(function()
    return player:PlayFile(title, url, 'NI-XStreamity Filme (VOD)', title)
  end)
  if not ok then
    print('NI-XStreamity: VOD-Wiedergabefehler (URL verborgen)')
  elseif PLAYSTATE and status == PLAYSTATE.LEAVE_ALL then
    state = 'exit'
    return MENU_RETURN.EXIT_ALL
  end
  -- STOP is handled by Neutrino; return to the invoking menu.
  return MENU_RETURN.REPAINT
end

function xs131_vod_movie(id, value)
  local movie = active_vod_movies_by_id and active_vod_movies_by_id[tostring(id or '')]
  return play_vod_movie(movie, active_vod_menu)
end

-- First selectable row in the info view: OK starts the displayed movie.
function xs15_vod_info_play()
  return play_vod_movie(selected_vod_info_movie, active_vod_info_menu)
end

-- BLUE opens movie details for the currently highlighted movie (zero-based row).
function xs14_vod_info_key()
  if not active_vod_menu or not active_vod_rows then return MENU_RETURN.REPAINT end
  local ok, pos = pcall(function() return active_vod_menu:getSelected() end)
  if not ok then return MENU_RETURN.REPAINT end
  local id = active_vod_rows[pos]
  local movie = id and active_vod_movies_by_id and active_vod_movies_by_id[id]
  if not movie then return MENU_RETURN.REPAINT end
  selected_vod_info_movie = movie
  state = 'vod_info'
  return MENU_RETURN.EXIT_ALL
end

function xs14_vod_info_back()
  state = 'vod_movies'
  return MENU_RETURN.EXIT_ALL
end

local function info_text(v)
  if type(v) == 'table' then return '' end
  return clean(v or '')
end

-- Keep long plot descriptions readable within the Neutrino menu width.
add_wrapped_info = function(m, label, value)
  local text = info_text(value):gsub('%s+', ' ')
  if text == '' then return end
  if label then m:addItem{type='subhead', name=label} end
  while #text > 0 do
    local chunk
    if #text <= 63 then chunk, text = text, ''
    else
      local segment = text:sub(1, 63)
      local split = segment:match('^.*()%s+') or 63
      chunk = text:sub(1, split):gsub('%s+$', '')
      text = text:sub(split + 1):gsub('^%s+', '')
    end
    m:addItem{type='subhead', name=chunk}
  end
end

-- Film detail overlay: uses the same cwindow/cpicture/ctext widgets as Netzkino.
-- The existing n_gui menu is retained as a fallback for older images.
local function vod_info_fallback(movie, data, err)
  local m = menu.new{name='Filminfo: ' .. clean(movie.name)}
  m:addItem{type='forwarder', name='Film starten (OK)', action='xs15_vod_info_play', id='play'}
  m:addItem{type='forwarder', name='Zurueck zur Filmliste', action='xs14_vod_info_back', id='back'}
  m:addItem{type='separatorline'}
  if not data then
    m:addItem{type='subhead', name='Informationen nicht verfuegbar: ' .. clean(err)}
  else
    local info = type(data.info) == 'table' and data.info or {}
    local movie_data = type(data.movie_data) == 'table' and data.movie_data or {}
    add_wrapped_info(m, 'Titel', info.name or movie.name)
    add_wrapped_info(m, 'Erscheinungsjahr', info.releaseDate or info.releasedate or movie.year)
    add_wrapped_info(m, 'Genre', info.genre)
    add_wrapped_info(m, 'Bewertung', info.rating or movie.rating)
    add_wrapped_info(m, 'Laufzeit', info.duration)
    add_wrapped_info(m, 'Regie', info.director)
    add_wrapped_info(m, 'Besetzung', info.actors or info.cast)
    add_wrapped_info(m, 'Handlung', info.plot or info.description or movie_data.plot)
  end
  active_vod_info_menu = m
  m:exec()
  active_vod_info_menu = nil
end

local function vod_info_value(v)
  if type(v) ~= 'string' and type(v) ~= 'number' then return '' end
  return clean(v):gsub('%s+', ' ')
end

local function vod_info_cover_url(info, movie, movie_data)
  -- Some providers return an empty cover_big but a valid movie_image.
  -- Others only provide stream_icon in get_vod_streams.
  local candidates = {info.cover_big, info.movie_image, info.cover,
    info.stream_icon, movie.stream_icon, movie.cover, movie_data.stream_icon,
    movie_data.cover_big, movie_data.movie_image, movie_data.cover}
  for i = 1, 10 do
    local url = candidates[i]
    if type(url) == 'string' and url ~= '' then
      url = trim(url)
      if url:sub(1, 2) == '//' then url = 'https:' .. url end
      if url:match('^https?://') and not url:find('[%c]') then return url end
    end
  end
  return nil
end

local function download_vod_cover(url, id)
  if not url then
    print('NI-XStreamity: Cover-Diagnose: Keine Cover-URL in API-Daten')
    return nil
  end
  -- Never print the URL: providers may include tokens or credentials.
  local host = url:match('^https?://([^/%?#]+)') or ''
  if host == '' then
    print('NI-XStreamity: Cover-Diagnose: URL ohne gueltigen Host')
    return nil
  end
  local path = '/tmp/ni_xstreamity_cover_' .. id .. '.img'
  local mk = io.popen('mktemp /tmp/ni-xs-cover.XXXXXX', 'r')
  if not mk then print('NI-XStreamity: Cover-Diagnose: mktemp fehlgeschlagen'); return nil end
  local config = mk:read('*l'); mk:close()
  if not config or config == '' then return nil end
  local f = io.open(config, 'w')
  if not f then os.remove(config); return nil end
  f:write('url = "', url:gsub('\\', '\\\\'):gsub('"', '\\"'), '"\n')
  f:close()
  os.execute('chmod 600 ' .. shellquote(config))
  -- Verify HTTPS using the CA bundle installed on the receiver.
  -- No --insecure: certificate validation remains enabled.
  -- Capture only numeric HTTP and curl exit codes, not server responses or URLs.
  -- curl --write-out works on the installed curl 8.7.1.
  local cmd = 'curl --cacert /etc/ssl/certs/ca-certificates.crt --silent --location --fail --max-time 20 --connect-timeout 8 --globoff '
    .. '--max-filesize 5000000 --config ' .. shellquote(config)
    .. ' --output ' .. shellquote(path)
    .. ' --write-out ' .. shellquote('%{http_code}') .. ' 2>/dev/null'
  local pipe = io.popen(cmd, 'r')
  local http, ok, why, code = '', false, nil, nil
  if pipe then
    http = (pipe:read('*a') or ''):match('(%d%d%d)%s*$') or '000'
    ok, why, code = pipe:close()
  end
  os.remove(config)
  local curlcode = ok and 0 or (type(code) == 'number' and code or -1)
  print('NI-XStreamity: Cover-Diagnose: HTTP=' .. http .. ' curl=' .. curlcode)
  if ok then
    local imagefile = io.open(path, 'rb')
    if imagefile then
      local header = imagefile:read(12) or ''
      imagefile:close()
      local ext = nil
      if header:sub(1,3) == string.char(255,216,255) then ext = 'jpg'
      elseif header:sub(1,8) == string.char(137,80,78,71,13,10,26,10) then ext = 'png' end
      if ext then
        local target = '/tmp/ni_xstreamity_cover_' .. id .. '.' .. ext
        os.remove(target)
        if os.rename(path, target) then
          print('NI-XStreamity: Cover geladen (' .. ext .. ')')
          return target
        end
        print('NI-XStreamity: Cover-Diagnose: Umbenennen fehlgeschlagen')
      else
        print('NI-XStreamity: Cover-Diagnose: Bild ist weder JPEG noch PNG')
      end
    else
      print('NI-XStreamity: Cover-Diagnose: Ausgabedatei fehlt')
    end
  end
  os.remove(path)
  return nil
end

local function vod_info_overlay(movie, data, id)
  if not cwindow or not cwindow.new or not ctext or not ctext.new
      or not cpicture or not cpicture.new or not RC then return false end
  local info = type(data) == 'table' and type(data.info) == 'table' and data.info or {}
  local movie_data = type(data) == 'table' and type(data.movie_data) == 'table' and data.movie_data or {}
  -- Xtream providers differ greatly in which VOD metadata fields they return.
  -- Prefer non-empty values and fall back to movie_data / stream list.
  local function first_value(...)
    for i = 1, select('#', ...) do
      local value = select(i, ...)
      if type(value) == 'string' or type(value) == 'number' then
        local cleaned = vod_info_value(value)
        if cleaned ~= '' and cleaned ~= 'null' then return cleaned end
      end
    end
    return ''
  end
  local title = first_value(info.name, movie_data.name, movie.name)
  local year = first_value(info.releaseDate, info.releasedate, info.release_date,
    info.year, movie_data.releaseDate, movie_data.releasedate, movie_data.year, movie.year)
  local genre = first_value(info.genre, info.genres, movie_data.genre, movie.genre)
  local rating = tonumber(first_value(info.rating, info.rating_5based, movie_data.rating, movie.rating))
  local duration = first_value(info.duration, info.runtime, movie_data.duration, movie_data.runtime)
  local director = first_value(info.director, movie_data.director)
  local actors = first_value(info.actors, info.cast, movie_data.actors, movie_data.cast)
  local plot = first_value(info.plot, info.description, info.storyline, info.overview,
    movie_data.plot, movie_data.description, movie.plot, movie.description)
  local details = {}
  if year ~= '' then details[#details+1] = 'Erscheinung: ' .. year end
  if genre ~= '' then details[#details+1] = 'Genre: ' .. genre end
  if rating then details[#details+1] = string.format('Bewertung: %.1f / 10', rating) end
  if duration ~= '' then details[#details+1] = 'Laufzeit: ' .. duration end
  if director ~= '' then details[#details+1] = 'Regie: ' .. director end
  if actors ~= '' then details[#details+1] = 'Besetzung: ' .. actors end
  if plot ~= '' then details[#details+1] = '\nHandlung:\n' .. plot end
  if #details == 0 or (#details == 1 and rating and plot == '') then
    details[#details+1] = '\nWeitere Filminformationen werden vom Anbieter nicht geliefert.'
  end
  -- Log field names only, never field values, URLs or credentials.
  if plot == '' then
    local function keys(t)
      local result = {}
      for k in pairs(t) do result[#result+1] = tostring(k) end
      table.sort(result)
      return table.concat(result, ', ')
    end
    print('NI-XStreamity: Filminfo-Felder info: ' .. keys(info))
    print('NI-XStreamity: Filminfo-Felder movie_data: ' .. keys(movie_data))
  end

  local cover = download_vod_cover(vod_info_cover_url(info, movie, movie_data), id)
  local win, txt
  local ok, reason = pcall(function()
    local width, height = 1500, 760
    win = cwindow.new{x=160, y=100, dx=width, dy=height,
      title='NI-XStreamity: ' .. title, btnRed='Film starten (OK)', btnGreen='Zurueck (EXIT)'}
    local reserved = win:headerHeight() + win:footerHeight()
    txt = ctext.new{parent=win, x=310, y=22, dx=width-340,
      dy=height-reserved-45, text=table.concat(details, '\n'),
      mode='ALIGN_TOP | ALIGN_SCROLL'}
    if cover then
      cpicture.new{parent=win, x=22, y=35, dx=260, dy=390, image=cover}
    end
    win:paint()
  end)
  if not ok then
    print('NI-XStreamity: Coveransicht nicht verfuegbar: ' .. tostring(reason))
    if win then pcall(function() win:hide() end) end
    if cover then os.remove(cover) end
    return false
  end
  -- This is a synchronous input loop, just like the Netzkino movie overlay.
  local n = neutrino()
  while true do
    local msg = n:GetInput(500)
    if msg == RC.ok or msg == RC.red then
      win:hide()
      local result = play_vod_movie(movie, nil)
      if cover then os.remove(cover) end
      if state ~= 'exit' then state = 'vod_movies' end
      return true
    elseif msg == RC.home or msg == RC.setup or msg == RC.exit or msg == RC.green then
      break
    elseif msg == RC.up or msg == RC.page_up then
      txt:scroll{dir='up'}
    elseif msg == RC.down or msg == RC.page_down then
      txt:scroll{dir='down'}
    end
  end
  win:hide()
  if cover then os.remove(cover) end
  state = 'vod_movies'
  return true
end

local function vod_info_menu()
  local movie = selected_vod_info_movie
  if not movie then state = 'vod_movies'; return end
  local id = tostring(movie.stream_id or '')
  local data, err = vod_info_cache[id], nil
  if not data then
    data, err = api_request(cfg, 'get_vod_info', nil, id)
    if data then vod_info_cache[id] = data end
  end
  local ok, handled = pcall(vod_info_overlay, movie, data, id)
  if not ok then print('NI-XStreamity: Filmansicht: ' .. tostring(handled)) end
  if not ok or not handled then vod_info_fallback(movie, data, err) end
  if state == 'vod_info' then state = 'vod_movies' end
end

function xs22_profiles_open()
  state = 'profiles'
  return MENU_RETURN.EXIT_ALL
end
function xs22_profiles_back()
  state = 'home'
  return MENU_RETURN.EXIT_ALL
end
function xs22_profile_select(id)
  local new_id = tonumber(id)
  local p = profile_by_id(new_id)
  if not p or profiles_error then return MENU_RETURN.REPAINT end
  if new_id ~= active_profile_id then
    local old_id = active_profile_id
    active_profile_id = new_id
    local ok, err = save_profiles()
    if not ok then
      active_profile_id = old_id
      print('NI-XStreamity: Serverwechsel fehlgeschlagen: ' .. tostring(err))
      return MENU_RETURN.REPAINT
    end
    cfg = {server=p.server, username=p.username, password=p.password}
    reset_server_cache()
    load_favorites()
    state = 'refresh'
  else
    state = 'home'
  end
  return MENU_RETURN.EXIT_ALL
end
function xs22_profile_new()
  if profiles_error then return MENU_RETURN.REPAINT end
  editing_new_profile = true
  settings = {server='http://example.com', username='example', password_changed=true, password=''}
  settings_message = 'Neuen Server eingeben und speichern'
  state = 'settings'
  return MENU_RETURN.EXIT_ALL
end
local function profiles_menu()
  local m = menu.new{name='NI-XStreamity 0.20.7 - Serverauswahl'}
  m:addItem{type='forwarder', name='Zurueck zum Hauptmenue', action='xs22_profiles_back'}
  m:addItem{type='separatorline'}
  if profiles_error then
    m:addItem{type='subhead', name=profiles_error}
  else
    for _, p in ipairs(profiles) do
      m:addItem{type='forwarder', name=(p.id == active_profile_id and '* ' or '  ') ..
        p.name .. ' (' .. p.server .. ')', id=tostring(p.id), action='xs22_profile_select'}
    end
    m:addItem{type='separatorline'}
    m:addItem{type='forwarder', name='Neuen Server hinzufuegen', action='xs22_profile_new'}
  end
  m:exec()
  if state == 'profiles' then state = 'home' end
end

local function home_menu()
  local m = menu.new{name='NI-XStreamity 0.20.7'}
  m:addItem{type='forwarder', name='Beenden', action='xs06_back', id='exit'}
  m:addItem{type='separatorline'}
  local active = profile_by_id(active_profile_id)
  m:addItem{type='subhead', name='Profil: ' .. (active and active.name or 'Unbekannt')}
  m:addItem{type='subhead', name='Server: ' .. server_status}
  m:addItem{type='subhead', name='Zugang: ' .. account_status}
  if expiry_status then m:addItem{type='subhead', name='Ablauf: ' .. expiry_status} end
  m:addItem{type='forwarder', name='Serverstatus aktualisieren', action='xs10_refresh', id='refresh'}
  m:addItem{type='forwarder', name='Server-Einstellungen', action='xs11_open_settings', id='settings'}
  m:addItem{type='forwarder', name='Server wechseln / hinzufuegen', action='xs22_profiles_open', id='profiles'}
  m:addItem{type='separatorline'}
  m:addItem{type='forwarder', name='Live-TV', action='xs13_open_live', id='live'}
  m:addItem{type='forwarder', name='Filme (VOD)', action='xs13_open_vod', id='vod'}
  m:addItem{type='forwarder', name='Serien (VOD)', action='xs17_open_series', id='series'}
  m:addItem{type='forwarder', name='Mediathek (Catch-up)', action='xs20_open', id='catchup'}
  m:addKey{directkey=RC.yellow, id='favorites', action='xs08_favorites'}
  m:addItem{type='forwarder', name='Meine Favoriten (' .. #favorites .. ')', action='xs08_favorites', id='favorites'}
  m:exec()
  if state == 'home' then state = 'exit' end
end

local function load_vod_categories()
  vod_categories = {}
  vod_category_by_id = {}
  vod_movie_cache = {}
  vod_info_cache = {}
  vod_error = nil
  local data, err = api_request(cfg, 'get_vod_categories')
  if not data then
    vod_error = err or 'VOD-Kategorien konnten nicht geladen werden'
    print('NI-XStreamity: VOD-Kategorien: ' .. clean(vod_error))
    return
  end
  if type(data) ~= 'table' then
    vod_error = 'VOD-Antwort ist keine Kategorienliste'
    return
  end
  vod_categories = sorted_categories(data)
  for _, c in ipairs(vod_categories) do
    vod_category_by_id[tostring(c.category_id)] = c
  end
  print('NI-XStreamity: ' .. #vod_categories .. ' VOD-Kategorien geladen')
end

local function vod_categories_menu()
  local m = menu.new{name='NI-XStreamity 0.20.7 - Filme (VOD)'}
  m:addItem{type='forwarder', name='Zurueck zum Hauptmenue', action='xs13_vod_back', id='back'}
  m:addItem{type='separatorline'}
  if vod_error then
    m:addItem{type='subhead', name='Fehler: ' .. clean(vod_error)}
  elseif #vod_categories == 0 then
    m:addItem{type='subhead', name='Keine Filmkategorien gefunden'}
  else
    m:addItem{type='subhead', name=tostring(#vod_categories) .. ' Filmkategorien gefunden'}
    m:addItem{type='separatorline'}
    for _, c in ipairs(vod_categories) do
      m:addItem{type='forwarder', name=clean(c.category_name),
        id=tostring(c.category_id), action='xs13_vod_category'}
    end
  end
  m:exec()
  if state == 'vod_categories' then state = 'home' end
end

local function vod_movies_menu()
  local id = selected_vod_category_id
  local category = vod_category_by_id[id]
  if not category then state = 'vod_categories'; return end
  local movies = vod_movie_cache[id]
  local err
  if not movies then
    movies, err = api_request(cfg, 'get_vod_streams', id)
    if movies and type(movies) == 'table' then
      vod_movie_cache[id] = movies
    else
      movies = nil
      err = err or 'Ungueltige Filmliste'
    end
  end
  local m = menu.new{
    name='Filme: ' .. clean(category.category_name),
    btnBlue='Filminfo / Vorschau   |   OK: Film starten'
  }
  m:addItem{type='forwarder', name='Zurueck zu Filmkategorien',
    action='xs131_vod_movies_back', id='back'}
  m:addItem{type='separatorline'}
  local movie_lookup = {}
  local row_to_movie = {}
  local row_index = 2 -- Back forwarder and separator
  m:addKey{directkey=RC.blue, id='info', action='xs14_vod_info_key'}
  if not movies then
    m:addItem{type='subhead', name='Fehler: ' .. clean(err)}
  else
    local count = 0
    for _, movie in ipairs(movies) do
      if type(movie) == 'table' then
        local movie_id = tostring(movie.stream_id or '')
        local name = clean(movie.name)
        if movie_id:match('^%d+$') and name ~= '' then
          movie_lookup[movie_id] = movie
          m:addItem{type='forwarder', name=name,
            action='xs131_vod_movie', id=movie_id}
          row_to_movie[row_index] = movie_id
          row_index = row_index + 1
          count = count + 1
        end
      end
    end
    if count == 0 then m:addItem{type='subhead', name='Keine Filme gefunden'} end
    print('NI-XStreamity: ' .. count .. ' Filme in ' .. clean(category.category_name))
  end
  active_vod_menu = m
  active_vod_movies_by_id = movie_lookup
  active_vod_rows = row_to_movie
  m:exec()
  active_vod_menu = nil
  active_vod_movies_by_id = nil
  active_vod_rows = nil
  -- Native EXIT should return to VOD categories as well.
  if state == 'vod_movies' then state = 'vod_categories' end
end

local function category_menu()
  local m = menu.new{name='NI-XStreamity 0.20.7 - Live TV'}
  add_back(m, 'Zurueck zum Hauptmenue')
  m:addKey{directkey=RC.yellow, id='favorites', action='xs08_favorites'}
  m:addItem{type='forwarder', name='Meine Favoriten (' .. #favorites .. ')', action='xs08_favorites', id='favorites'}
  m:addItem{type='separatorline'}
  for _, c in ipairs(categories) do
    m:addItem{type='forwarder', name=clean(c.category_name),
      id=tostring(c.category_id), action='xs06_category'}
  end
  m:exec()
  -- n_gui native EXIT can close the menu without calling a callback.
  if state == 'categories' then state = 'home' end
end

local function streams_for(id)
  if stream_cache[id] then return stream_cache[id] end
  local data, err = api_request(cfg, 'get_live_streams', id)
  if not data or type(data) ~= 'table' then return nil, err or 'Ungueltige Senderliste' end
  stream_cache[id] = data
  return data
end

-- v0.20: Catch-up discovery only. Playback will follow after provider testing.
local catchup_category_id = nil
local catchup_rows = {}
local catchup_lookup = {}
local catchup_active_menu = nil
local catchup_selected = nil
local catchup_count = 0

local function xs20_archive_enabled(stream)
  local flag = stream.tv_archive
  return flag == 1 or flag == true or tostring(flag or '') == '1'
end

function xs20_open()
  state = 'catchup_categories'
  return MENU_RETURN.EXIT_ALL
end

function xs20_back_home()
  state = 'home'
  return MENU_RETURN.EXIT_ALL
end

function xs20_back_categories()
  state = 'catchup_categories'
  return MENU_RETURN.EXIT_ALL
end

function xs20_select_category(id)
  id = tostring(id or '')
  if not category_by_id[id] then return MENU_RETURN.REPAINT end
  catchup_category_id = id
  state = 'catchup_channels'
  return MENU_RETURN.EXIT_ALL
end

function xs20_select_channel(id)
  catchup_selected = catchup_lookup[tostring(id or '')]
  if not catchup_selected then return MENU_RETURN.REPAINT end
  state = 'catchup_programs'
  return MENU_RETURN.EXIT_ALL
end

function xs20_diagnostic_back()
  state = 'catchup_channels'
  return MENU_RETURN.EXIT_ALL
end

local function xs20_categories_menu()
  local m = menu.new{name='NI-XStreamity 0.20.7 - Mediathek (Test)'}
  m:addItem{type='forwarder', name='Zurueck zum Hauptmenue', action='xs20_back_home'}
  m:addItem{type='separatorline'}
  m:addItem{type='subhead', name='Catch-up-Sender nach Kategorie pruefen'}
  for _, c in ipairs(categories or {}) do
    m:addItem{type='forwarder', name=clean(c.category_name),
      id=tostring(c.category_id), action='xs20_select_category'}
  end
  m:exec()
  if state == 'catchup_categories' then state = 'home' end
end

local function xs20_channels_menu()
  local id = catchup_category_id
  local category = category_by_id[id]
  if not category then state = 'catchup_categories'; return end
  local streams, err = streams_for(id)
  local m = menu.new{name='Catch-up: ' .. clean(category.category_name)}
  m:addItem{type='forwarder', name='Zurueck zu Kategorien', action='xs20_back_categories'}
  m:addItem{type='separatorline'}
  catchup_lookup = {}
  catchup_count = 0
  if type(streams) ~= 'table' then
    m:addItem{type='subhead', name='Sender konnten nicht geladen werden: ' .. clean(err)}
  else
    for _, stream in ipairs(streams) do
      if type(stream) == 'table' and xs20_archive_enabled(stream) then
        local sid = tostring(stream.stream_id or '')
        if sid:match('^%d+$') then
          catchup_count = catchup_count + 1
          catchup_lookup[sid] = stream
          local days = tonumber(stream.tv_archive_duration) or 0
          local suffix = days > 0 and (' (' .. days .. ' Tage)') or ''
          m:addItem{type='forwarder', name=clean(stream.name) .. suffix,
            id=sid, action='xs20_select_channel'}
        end
      end
    end
    if catchup_count == 0 then
      m:addItem{type='subhead', name='Keine als Catch-up markierten Sender gefunden'}
    end
  end
  print('NI-XStreamity: Catch-up-Kategorie: ' .. catchup_count .. ' Sender mit tv_archive=1')
  m:exec()
  catchup_lookup = {}
  if state == 'catchup_channels' then state = 'catchup_categories' end
end


-- v0.20.2: finished broadcasts within the advertised archive window.
local catchup_programs = {}
local catchup_selected_program = nil
local catchup_play_menu_active = nil
local function xs201_local_timestamp(value)
  if type(value) ~= 'string' then return nil end
  local y, mo, d, h, mi, sec = value:match('^(%d%d%d%d)%-(%d%d)%-(%d%d)[ T](%d%d):(%d%d):?(%d?%d?)')
  if not y then return nil end
  return os.time{year=tonumber(y),month=tonumber(mo),day=tonumber(d),
    hour=tonumber(h),min=tonumber(mi),sec=tonumber(sec) or 0}
end

local function xs201_epoch(entry, field)
  local numeric = tonumber(entry[field .. '_timestamp'])
  if numeric and numeric > 1000000000 then return numeric end
  return xs201_local_timestamp(entry[field])
end

function xs201_select_program(id)
  local entry = catchup_programs[tonumber(id)]
  if not entry then return MENU_RETURN.REPAINT end
  catchup_selected_program = entry
  state = 'catchup_play'
  return MENU_RETURN.EXIT_ALL
end

function xs201_programs_back()
  state = 'catchup_channels'
  return MENU_RETURN.EXIT_ALL
end

local function xs201_programs_menu()
  local channel = catchup_selected
  if not channel then state = 'catchup_channels'; return end
  local sid = tostring(channel.stream_id or '')
  local data, err = api_request(cfg, 'get_simple_data_table', nil, nil, nil, sid)
  local m = menu.new{name='Archiv: ' .. clean(channel.name)}
  m:addItem{type='forwarder', name='Zurueck zu Catch-up-Sendern', action='xs201_programs_back'}
  m:addItem{type='separatorline'}
  catchup_programs = {}
  if type(data) ~= 'table' then
    m:addItem{type='subhead', name='EPG nicht verfuegbar: ' .. clean(err)}
  else
    local listings = type(data.epg_listings) == 'table' and data.epg_listings or data
    local now = os.time()
    local days = tonumber(channel.tv_archive_duration) or 0
    local oldest = now - math.max(days, 0) * 86400
    local candidates = {}
    for _, e in ipairs(listings) do
      if type(e) == 'table' then
        local start = xs201_epoch(e, 'start')
        local finish = xs201_epoch(e, 'end')
        if start and finish and finish > start and finish <= now and start >= oldest then
          candidates[#candidates+1] = {entry=e, start=start, finish=finish}
        end
      end
    end
    table.sort(candidates, function(a,b) return a.start > b.start end)
    m:addItem{type='subhead', name=tostring(#candidates) .. ' vergangene Sendungen im Archivzeitraum'}
    m:addItem{type='separatorline'}
    for i, item in ipairs(candidates) do
      if i > 100 then break end
      catchup_programs[i] = item
      local title = xs19_decode_base64(item.entry.title or '')
      m:addItem{type='forwarder',
        name=os.date('%d.%m. %H:%M',item.start) .. ' - ' ..
          os.date('%H:%M',item.finish) .. ' ' .. clean(title),
        id=tostring(i), action='xs201_select_program'}
    end
    if #candidates == 0 then
      m:addItem{type='subhead', name='Keine abgeschlossenen Sendungen im Archivzeitraum'}
    end
    print('NI-XStreamity: Catch-up: ' .. #candidates .. ' archivierte EPG-Eintraege')
  end
  m:exec()
  if state == 'catchup_programs' then state = 'catchup_channels' end
end

function xs201_play_back()
  state = 'catchup_programs'
  return MENU_RETURN.EXIT_ALL
end

function xs201_play_start()
  local item = catchup_selected_program
  local channel = catchup_selected
  if not item or not channel then return MENU_RETURN.REPAINT end
  local sid = tostring(channel.stream_id or '')
  if not sid:match('^%d+$') then return MENU_RETURN.REPAINT end
  local duration = math.ceil((item.finish - item.start) / 60)
  if duration < 1 or duration > 1440 then
    print('NI-XStreamity: Catch-up: ungueltige Sendungsdauer')
    return MENU_RETURN.REPAINT
  end
  -- Xtream timeshift endpoint. Provider may require a different format.
  local start = os.date('%Y-%m-%d:%H-%M', item.start)
  local url = cfg.server .. '/timeshift/' .. encode(cfg.username) .. '/' ..
    encode(cfg.password) .. '/' .. tostring(duration) .. '/' .. start .. '/' .. sid .. '.ts'
  if not player then
    local ok, p = pcall(function() return video.new() end)
    if not ok or not p then return MENU_RETURN.REPAINT end
    player = p
  end
  local title = clean(xs19_decode_base64(item.entry.title or 'Archivsendung'))
  -- As with series playback, hide the currently open Neutrino menu first.
  if catchup_play_menu_active then
    pcall(function() catchup_play_menu_active:hide() end)
  end
  print('NI-XStreamity: Catch-up Wiedergabeversuch: ' .. title .. ' (' .. duration .. ' Min.)')
  local ok, result = pcall(function()
    return player:PlayFile(title, url, 'NI-XStreamity Catch-up', title)
  end)
  if not ok then print('NI-XStreamity: Catch-up Wiedergabefehler (URL verborgen)') end
  if PLAYSTATE and result == PLAYSTATE.LEAVE_ALL then
    state = 'exit'
    return MENU_RETURN.EXIT_ALL
  end
  state = 'catchup_programs'
  return MENU_RETURN.EXIT_ALL
end

local function xs201_play_menu()
  local item = catchup_selected_program
  if not item then state = 'catchup_programs'; return end
  local title = clean(xs19_decode_base64(item.entry.title or 'Archivsendung'))
  local m = menu.new{name='Catch-up: ' .. title}
  m:addItem{type='forwarder', name='Sendung abspielen (OK)',
    action='xs201_play_start'}
  m:addItem{type='forwarder', name='Zurueck zur Sendungsliste',
    action='xs201_play_back'}
  m:addItem{type='separatorline'}
  m:addItem{type='subhead', name=os.date('%d.%m.%Y %H:%M', item.start) ..
    ' - ' .. os.date('%H:%M', item.finish)}
  add_wrapped_info(m, 'Beschreibung', xs19_decode_base64(item.entry.description or ''))
  catchup_play_menu_active = m
  m:exec()
  catchup_play_menu_active = nil
  if state == 'catchup_play' then state = 'catchup_programs' end
end

local function xs20_diagnostic_menu()
  local channel = catchup_selected
  if not channel then state = 'catchup_channels'; return end
  local m = menu.new{name='Catch-up: ' .. clean(channel.name)}
  m:addItem{type='forwarder', name='Zurueck zur Senderliste', action='xs20_diagnostic_back'}
  m:addItem{type='separatorline'}
  m:addItem{type='subhead', name='Sender-ID: ' .. clean(channel.stream_id)}
  m:addItem{type='subhead', name='tv_archive: ' .. clean(channel.tv_archive)}
  m:addItem{type='subhead', name='tv_archive_duration: ' .. clean(channel.tv_archive_duration)}
  m:addItem{type='separatorline'}
  m:addItem{type='subhead', name='Catch-up-Erkennung erfolgreich. Wiedergabe folgt in einer spaeteren Version.'}
  m:exec()
  if state == 'catchup_diagnostic' then state = 'catchup_channels' end
end

local function streams_menu()
  local id = selected_category_id
  local is_favorites = (id == '__favorites__')
  local c = category_by_id[id]
  if not c and not is_favorites then state = 'categories'; return end
  local data, err
  if is_favorites then data = favorites else data, err = streams_for(id) end
  local m = menu.new{
    name=is_favorites and 'Meine Favoriten' or ('Sender: ' .. clean(c.category_name)),
    btnGreen='Favorit +/-', btnYellow='Meine Favoriten', btnBlue='EPG anzeigen'
  }
  add_back(m, 'Zurueck zu Kategorien')
  -- Menu index 0 is the Back forwarder, index 1 the separator.
  -- Track all subsequent rows explicitly so getSelected() maps correctly.
  local row_index = 2
  local row_to_stream = {}
  m:addKey{directkey=RC.green, id='toggle', action='xs09_green'}
  m:addKey{directkey=RC.blue, id='epg', action='xs19_epg_key'}
  m:addKey{directkey=RC.yellow, id='favorites', action='xs08_favorites'}
  xs_stream_by_id = {}
  if not data then
    m:addItem{type='subhead', name='Fehler: ' .. clean(err)}
    row_index = row_index + 1
  else
    local count = 0
    for _, s in ipairs(data) do
      if type(s) == 'table' then
        local sid, name = tostring(s.stream_id or ''), clean(s.name)
        if sid:match('^%d+$') and name ~= '' and not name:match('^%s*####') then
          xs_stream_by_id[sid] = s
          m:addItem{type='forwarder', name=(favorites_index[sid] and '* ' or '') .. name,
            id=sid, action='xs06_stream'}
          row_to_stream[row_index] = sid
          row_index = row_index + 1
          count = count + 1
        end
      end
    end
    if count == 0 then m:addItem{type='subhead', name='Keine Sender gefunden'} end
  end
  active_stream_menu = m
  active_stream_rows = row_to_stream
  m:exec()
  active_stream_menu = nil
  active_stream_rows = nil
  if state == 'open_favorites' then
    state = 'streams'
  elseif state == 'streams' then
    state = is_favorites and 'home' or 'categories'
  elseif state == 'rebuild_streams' then
    state = 'streams'
  end
end

-- v0.17: Series categories -> series -> seasons -> episodes.
-- All callbacks change state only; avoid nested n_gui menu:exec calls.
function xs17_open_series()
  state = 'series_load'
  return MENU_RETURN.EXIT_ALL
end
function xs17_home()
  state = 'home'
  return MENU_RETURN.EXIT_ALL
end
function xs17_categories_back()
  state = 'series_categories'
  return MENU_RETURN.EXIT_ALL
end
function xs17_series_back()
  state = 'series_list'
  return MENU_RETURN.EXIT_ALL
end
function xs17_seasons_back()
  state = 'series_seasons'
  return MENU_RETURN.EXIT_ALL
end
function xs17_select_category(id)
  id = tostring(id or '')
  if not series_category_by_id[id] then return MENU_RETURN.REPAINT end
  selected_series_category_id = id
  state = 'series_list'
  return MENU_RETURN.EXIT_ALL
end
function xs17_select_series(id)
  selected_series = active_series_lookup and active_series_lookup[tostring(id or '')]
  if not selected_series then return MENU_RETURN.REPAINT end
  state = 'series_seasons'
  return MENU_RETURN.EXIT_ALL
end
-- Blue key in the series list opens the selected series' information.
function xs18_series_info_key()
  if not active_series_list_menu or not active_series_list_rows then return MENU_RETURN.REPAINT end
  local ok, pos = pcall(function() return active_series_list_menu:getSelected() end)
  if not ok then return MENU_RETURN.REPAINT end
  local id = active_series_list_rows[pos]
  local series = id and active_series_lookup and active_series_lookup[id]
  if not series then return MENU_RETURN.REPAINT end
  selected_series = series
  state = 'series_info'
  return MENU_RETURN.EXIT_ALL
end
function xs17_select_season(id)
  selected_season = tonumber(id)
  if selected_season == nil then return MENU_RETURN.REPAINT end
  state = 'series_episodes'
  return MENU_RETURN.EXIT_ALL
end
local function xs17_episode_url(ep)
  local id = tostring(ep.id or '')
  if not id:match('^%d+$') then return nil end
  local ext = tostring(ep.container_extension or 'mp4'):lower()
  if ext ~= 'mp4' and ext ~= 'mkv' and ext ~= 'avi' and ext ~= 'ts' and ext ~= 'm3u8' then return nil end
  return cfg.server .. '/series/' .. encode(cfg.username) .. '/' .. encode(cfg.password)
    .. '/' .. id .. '.' .. ext
end
function xs17_play_episode(id)
  local ep = active_episode_lookup and active_episode_lookup[tostring(id or '')]
  if not ep then return MENU_RETURN.REPAINT end
  local url = xs17_episode_url(ep)
  if not url then print('NI-XStreamity: Episode ohne gueltige ID/Endung'); return MENU_RETURN.REPAINT end
  if not player then
    local ok, p = pcall(function() return video.new() end)
    if not ok or not p then print('NI-XStreamity: Player nicht verfuegbar'); return MENU_RETURN.REPAINT end
    player = p
  end
  if active_series_menu then pcall(function() active_series_menu:hide() end) end
  local title = clean(ep.title or ep.name or 'Episode')
  print('NI-XStreamity: Starte Episode ' .. title)
  local ok, result = pcall(function() return player:PlayFile(title, url, 'NI-XStreamity Serien', title) end)
  if not ok then print('NI-XStreamity: Episoden-Wiedergabefehler (URL verborgen)')
  elseif PLAYSTATE and result == PLAYSTATE.LEAVE_ALL then
    state = 'exit'; return MENU_RETURN.EXIT_ALL
  end
  return MENU_RETURN.REPAINT
end
local function xs17_load_categories()
  series_categories, series_category_by_id = {}, {}
  series_list_cache, series_info_cache = {}, {}
  local data, err = api_request(cfg, 'get_series_categories')
  if type(data) == 'table' then
    series_categories = sorted_categories(data)
    for _, c in ipairs(series_categories) do
      series_category_by_id[tostring(c.category_id)] = c
    end
    print('NI-XStreamity: ' .. #series_categories .. ' Serienkategorien geladen')
  else
    print('NI-XStreamity: Serienkategorien fehlgeschlagen: ' .. clean(err))
  end
end
local function xs17_categories_menu()
  local m = menu.new{name='NI-XStreamity 0.19 - Serien'}
  m:addItem{type='forwarder', name='Zurueck zum Hauptmenue', action='xs17_home'}
  m:addItem{type='separatorline'}
  m:addItem{type='subhead', name=tostring(#series_categories) .. ' Serienkategorien'}
  for _, c in ipairs(series_categories) do
    m:addItem{type='forwarder', name=clean(c.category_name), id=tostring(c.category_id), action='xs17_select_category'}
  end
  m:exec()
  if state == 'series_categories' then state = 'home' end
end
local function xs17_list_menu()
  local cid = selected_series_category_id
  local data = series_list_cache[cid]
  if not data then
    local err
    data, err = api_request(cfg, 'get_series', cid)
    if type(data) == 'table' then series_list_cache[cid] = data
    else print('NI-XStreamity: Serienliste fehlgeschlagen: ' .. clean(err)); data = {} end
  end
  local m = menu.new{name='Serien: ' .. clean((series_category_by_id[cid] or {}).category_name)}
  m:addItem{type='forwarder', name='Zurueck zu Serienkategorien', action='xs17_categories_back'}
  m:addItem{type='separatorline'}
  local lookup, rows = {}, {}
  local row_index = 2 -- back row + separator
  m:addKey{directkey=RC.blue, id='series_info', action='xs18_series_info_key'}
  for _, item in ipairs(data) do
    local id = tostring(item.series_id or '')
    if id:match('^%d+$') then
      lookup[id] = item
      m:addItem{type='forwarder', name=clean(item.name), id=id, action='xs17_select_series'}
      rows[row_index] = id
      row_index = row_index + 1
    end
  end
  print('NI-XStreamity: ' .. #data .. ' Serien in Kategorie')
  active_series_lookup = lookup
  active_series_list_menu, active_series_list_rows = m, rows
  m:exec()
  active_series_list_menu, active_series_list_rows = nil, nil
  active_series_lookup = nil
  if state == 'series_list' then state = 'series_categories' end
end
local function xs17_get_info()
  local id = tostring(selected_series and selected_series.series_id or '')
  if not id:match('^%d+$') then return nil end
  if not series_info_cache[id] then
    local data, err = api_request(cfg, 'get_series_info', nil, nil, id)
    if type(data) ~= 'table' then
      print('NI-XStreamity: Serieninfo fehlgeschlagen: ' .. clean(err))
      return nil
    end
    series_info_cache[id] = data
  end
  return series_info_cache[id]
end
-- v0.18: series info uses the proven VOD cwindow, cpicture and ctext widgets.
-- Show-only overlay: OK/green/EXIT returns to series list, no nested menu exec.
local function xs18_series_info_menu()
  local series = selected_series
  if not series then state = 'series_list'; return end
  local id = tostring(series.series_id or '')
  if not id:match('^%d+$') then state = 'series_list'; return end
  local data = series_info_cache[id]
  if not data then
    local result, err = api_request(cfg, 'get_series_info', nil, nil, id)
    if type(result) == 'table' then
      data = result
      series_info_cache[id] = data
    else
      print('NI-XStreamity: Serieninfo fehlgeschlagen: ' .. clean(err))
      data = {}
    end
  end
  local info = type(data.info) == 'table' and data.info or {}
  local function first(...)
    for i=1, select('#', ...) do
      local v = select(i, ...)
      if type(v) == 'string' or type(v) == 'number' then
        local s = vod_info_value(v)
        if s ~= '' and s ~= 'null' then return s end
      end
    end
    return ''
  end
  local title = first(info.name, series.name)
  local year = first(info.releaseDate, info.releasedate, info.release_date, info.year, series.year)
  local genre = first(info.genre, series.genre)
  local rating = tonumber(first(info.rating, series.rating))
  local director = first(info.director, series.director)
  local cast = first(info.cast, info.actors, series.cast)
  local plot = first(info.plot, info.description, info.overview, series.plot, series.description)
  local details = {}
  if year ~= '' then details[#details+1] = 'Erscheinung: ' .. year end
  if genre ~= '' then details[#details+1] = 'Genre: ' .. genre end
  if rating then details[#details+1] = string.format('Bewertung: %.1f / 10', rating) end
  if director ~= '' then details[#details+1] = 'Regie: ' .. director end
  if cast ~= '' then details[#details+1] = 'Besetzung: ' .. cast end
  if plot ~= '' then details[#details+1] = '\nHandlung:\n' .. plot end
  if #details == 0 then details[1] = 'Keine weiteren Serieninformationen vorhanden.' end
  local url = vod_info_cover_url(info, series, {})
  local cover = download_vod_cover(url, id)
  if not (cwindow and cwindow.new and ctext and ctext.new and cpicture and cpicture.new and RC) then
    if cover then os.remove(cover) end
    print('NI-XStreamity: Serieninfo-GUI nicht verfuegbar')
    state = 'series_list'; return
  end
  local win, txt
  local ok, reason = pcall(function()
    local width, height = 1500, 760
    win = cwindow.new{x=160, y=100, dx=width, dy=height,
      title='NI-XStreamity: ' .. title, btnGreen='Zurueck (EXIT)'}
    local reserved = win:headerHeight() + win:footerHeight()
    txt = ctext.new{parent=win, x=310, y=22, dx=width-340,
      dy=height-reserved-45, text=table.concat(details, '\n'),
      mode='ALIGN_TOP | ALIGN_SCROLL'}
    if cover then
      cpicture.new{parent=win, x=22, y=35, dx=260, dy=390, image=cover}
    end
    win:paint()
  end)
  if not ok then
    print('NI-XStreamity: Serieninfo-Anzeige: ' .. tostring(reason))
  else
    local n = neutrino()
    while true do
      local msg = n:GetInput(500)
      if msg == RC.home or msg == RC.setup or msg == RC.exit
          or msg == RC.green or msg == RC.ok then break
      elseif msg == RC.up or msg == RC.page_up then
        txt:scroll{dir='up'}
      elseif msg == RC.down or msg == RC.page_down then
        txt:scroll{dir='down'}
      end
    end
  end
  if win then pcall(function() win:hide() end) end
  if cover then os.remove(cover) end
  state = 'series_list'
end

local function xs17_season_numbers(data)
  local nums, seen = {}, {}
  local episodes = type(data.episodes) == 'table' and data.episodes or {}
  for k, list in pairs(episodes) do
    if type(list) == 'table' then
      local n = tonumber(k)
      if n and not seen[n] then seen[n] = true; nums[#nums+1] = n end
    end
  end
  table.sort(nums)
  return nums
end
local function xs17_seasons_menu()
  local data = xs17_get_info()
  local m = menu.new{name='Staffeln: ' .. clean(selected_series and selected_series.name)}
  m:addItem{type='forwarder', name='Zurueck zu Serien', action='xs17_series_back'}
  m:addItem{type='separatorline'}
  local nums = data and xs17_season_numbers(data) or {}
  for _, n in ipairs(nums) do
    m:addItem{type='forwarder', name='Staffel ' .. n, id=tostring(n), action='xs17_select_season'}
  end
  if #nums == 0 then m:addItem{type='subhead', name='Keine Staffeln in der API-Antwort'} end
  print('NI-XStreamity: ' .. #nums .. ' Staffeln gefunden')
  m:exec()
  if state == 'series_seasons' then state = 'series_list' end
end
local function xs17_episodes_menu()
  local data = xs17_get_info()
  local eps = data and type(data.episodes) == 'table' and data.episodes or {}
  local list = eps[tostring(selected_season)] or eps[selected_season] or {}
  local m = menu.new{name='Staffel ' .. tostring(selected_season) .. ': ' .. clean(selected_series and selected_series.name)}
  m:addItem{type='forwarder', name='Zurueck zu Staffeln', action='xs17_seasons_back'}
  m:addItem{type='separatorline'}
  active_episode_lookup = {}
  for i, ep in ipairs(list) do
    local id = tostring(ep.id or '')
    if id:match('^%d+$') then
      active_episode_lookup[id] = ep
      local num = tonumber(ep.episode_num) or i
      m:addItem{type='forwarder', name=string.format('%02d - %s', num, clean(ep.title or ep.name or 'Episode')),
        id=id, action='xs17_play_episode'}
    end
  end
  if #list == 0 then m:addItem{type='subhead', name='Keine Episoden gefunden'} end
  print('NI-XStreamity: ' .. #list .. ' Episoden in Staffel ' .. tostring(selected_season))
  active_series_menu = m
  m:exec()
  active_series_menu, active_episode_lookup = nil, nil
  if state == 'series_episodes' then state = 'series_seasons' end
end

local function run_gui()
  local ok = pcall(require, 'n_gui')
  if not ok or not menu or not menu.new or not MENU_RETURN then
    return nil, 'Neutrino-Menuebibliothek nicht verfuegbar'
  end
  state = startup_needs_setup and 'settings' or 'home'
  if startup_needs_setup then
    settings = {server=cfg.server, username=cfg.username, password_changed=false}
    settings_message = 'Bitte Serverdaten eingeben und speichern'
  end
  while state ~= 'exit' do
    if state == 'refresh' then
      refresh_categories()
      state = 'home'
    elseif state == 'home' then home_menu()
    elseif state == 'profiles' then profiles_menu()
    elseif state == 'vod_load' then
      load_vod_categories()
      state = 'vod_categories'
    elseif state == 'vod_categories' then vod_categories_menu()
    elseif state == 'vod_movies' then vod_movies_menu()
    elseif state == 'vod_info' then vod_info_menu()
    elseif state == 'series_load' then xs17_load_categories(); state = 'series_categories'
    elseif state == 'series_categories' then xs17_categories_menu()
    elseif state == 'series_list' then xs17_list_menu()
    elseif state == 'series_info' then xs18_series_info_menu()
    elseif state == 'series_seasons' then xs17_seasons_menu()
    elseif state == 'series_episodes' then xs17_episodes_menu()
    elseif state == 'categories' then category_menu()
    elseif state == 'catchup_categories' then xs20_categories_menu()
    elseif state == 'catchup_channels' then xs20_channels_menu()
    elseif state == 'catchup_diagnostic' then xs20_diagnostic_menu()
    elseif state == 'catchup_programs' then xs201_programs_menu()
    elseif state == 'catchup_play' then xs201_play_menu()
    elseif state == 'live_epg' then xs19_epg_menu()
    elseif state == 'live_epg_detail' then xs191_epg_detail_menu()
    elseif state == 'edit_server' then editor_menu('server')
    elseif state == 'edit_username' then editor_menu('username')
    elseif state == 'edit_password' then editor_menu('password')
    elseif state == 'settings' or state == 'settings_rebuild' then
      state = 'settings'
      settings_menu()
    elseif state == 'streams' or state == 'rebuild_streams' then
      state = 'streams'
      streams_menu()
    else state = 'exit' end
  end
  return true
end

local function main()
  local err
  cfg, err = read_config(config_path)
  local needs_setup = not cfg
  startup_needs_setup = needs_setup
  if needs_setup then
    -- Keep defaults in memory only. Do not create or overwrite a config file
    -- until the user explicitly chooses "Einstellungen speichern".
    print('NI-XStreamity: ' .. tostring(err) .. ' - Server-Einstellungen oeffnen')
    cfg = {server='http://example.com', username='example', password='example'}
    server_status = 'Nicht konfiguriert'
    account_status = 'Nicht konfiguriert'
    categories, category_by_id = {}, {}
  end
  if not needs_setup then
    load_profiles()
  else
    profiles = {{id=1, name='Server 1', server=cfg.server, username=cfg.username, password=cfg.password}}
  end
  load_favorites()
  if not needs_setup then refresh_categories() end
  print('NI-XStreamity 0.20.7: Server ' .. server_status .. ', Zugang ' .. account_status)
  if type(neutrino) == 'function' and type(SCREEN) == 'table' then
    return run_gui()
  end
  print('Konsolenmodus: GUI ueber Neutrino-Pluginmenue starten.')
  for i, c in ipairs(sorted_categories(categories)) do
    if i > 15 then break end
    print(string.format('%3d. %s [ID: %s]', i, clean(c.category_name), tostring(c.category_id)))
  end
  return true
end

local ok, success, err = pcall(main)
if not ok then
  print('NI-XStreamity 0.20.7: Lua-Fehler: ' .. tostring(success))
elseif not success then
  print('NI-XStreamity 0.20.7: FEHLER: ' .. tostring(err))
end
