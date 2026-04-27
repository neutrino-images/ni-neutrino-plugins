--  Version 0.3.2 (Cache + verbesserte Gültigkeitsprüfung) 27/Apr/2026 by jokel

local json = require "json"

local cache_file = "/tmp/streamlink_cache.json"
local cache = {}

-- Cache laden
do
    local f = io.open(cache_file, "r")
    if f then
        local content = f:read("*a")
        f:close()
        if content and content ~= "" then
            cache = json:decode(content) or {}
        end
    end
end

-- Shell-Befehl ausführen
local function pop(cmd)
    local f = assert(io.popen(cmd, "r"))
    local s = f:read("*a")
    f:close()
    return s
end

-- Prüfen, ob Stream-URL gültig ist.
local function is_valid_stream(url)
    local cmd = string.format('curl -kLs --range 0-100 %q', url)
    local data = pop(cmd)

    if not data or data == "" then
        return false
    end

    -- EXPLIZIT ungültig (Pluto expired)
    if data:match("#EXT%-X%-ENDLIST") then
        return false
    else
  		return true
    end
end

local url = arg[1]
if not url then
    print("Keine URL übergeben")
    return nil
end

-- Cache prüfen + Gültigkeit testen
if cache[url] then
    local cached = cache[url]

    if is_valid_stream(cached) then
        -- print(cached)
        return json:encode({ url = cached })
    else
        -- nur diesen EINEN Eintrag löschen
        cache[url] = nil

        -- Cache-Datei aktualisieren
        local f = io.open(cache_file, "w")
        if f then
            f:write(json:encode_pretty(cache))
            f:close()
        end
    end
end

-- Redirects (stvp/plu)
local final_url = url
if url:match("stvp") or url:match("plu") then
    local cmd = string.format(
        "curl -kLs -o /dev/null -w %%{url_effective} %q",
        url
    )
    final_url = pop(cmd):gsub("%s+$", "")
end

if not final_url or final_url == "" then
    return nil
end

-- Streamlink
local qualities = "1080p,720p,3300k,3100k,2300k,2100k,best"
local cmd = string.format(
    "streamlink %q %s --stream-url",
    final_url,
    qualities
)

local stream_url = pop(cmd):gsub("%s+$", "")
if not stream_url or stream_url == "" then
    return nil
end

-- In Cache speichern
cache[url] = stream_url
local f = io.open(cache_file, "w")
if f then
    f:write(json:encode_pretty(cache))
    f:close()
end

-- Ausgabe
print(stream_url)
return json:encode({ url = stream_url })
