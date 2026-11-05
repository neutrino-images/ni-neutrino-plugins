-- NI-CleverTanken v0.6.7 - NI-Neutrino Lua
-- Tankerkoenig data: CC BY 4.0 - https://creativecommons.tankerkoenig.de
local n=neutrino()
local json=require('cjson')
local CA='/etc/ssl/certs/ca-certificates.crt'
local TMP='/tmp/ni_clevertanken.json'
local ZIPTMP='/tmp/ni_clevertanken_plz.json'
local CONF='/var/tuxbox/config/clevertanken.conf'
local DEMO='00000000-0000-0000-0000-000000000002'
local cfg={apikey=DEMO,location='Berlin (Demo)',lat=52.521,lng=13.438,radius=1.5,fuel='diesel',sort='price'}
local fuels={'diesel','e5','e10'}
-- Dezimalkoordinaten aus PLZ-Daten strikt pruefen; keine stillschweigende Korrektur.
local function coordinate(value,limit)
  local s=tostring(value or '')
  if not s:match('^%-?%d+%.?%d*$') then return nil end
  -- cjson verarbeitet JSON-Zahlen mit Punkt unabhaengig von der C-Locale.
  local ok,num=pcall(json.decode,s)
  if not ok or type(num)~='number' or num~=num or math.abs(num)>limit then return nil end
  return num
end
local function decimal(n,precision)
  return string.format('%.'..precision..'f',n):gsub(',','.')
end
local function load_config()
  local f=io.open(CONF,'r'); if not f then return end
  for line in f:lines() do
    local k,v=line:match('^%s*([%w_]+)%s*=%s*(.-)%s*$')
    if k and cfg[k]~=nil then
      if k=='lat' then cfg[k]=coordinate(v,90) or tonumber(v) or cfg[k]
       elseif k=='lng' then cfg[k]=coordinate(v,180) or tonumber(v) or cfg[k]
       elseif k=='radius' then cfg[k]=tonumber(v) or cfg[k]
      else cfg[k]=v end
    end
  end
  f:close()
  if cfg.radius<1 then cfg.radius=1 elseif cfg.radius>25 then cfg.radius=25 end
  cfg.sort='price' -- feste Sortierung, auch bei alter Konfiguration
  if cfg.fuel~='diesel' and cfg.fuel~='e5' and cfg.fuel~='e10' then cfg.fuel='diesel' end
end
local function save_config()
  local f=io.open(CONF,'w'); if not f then return false end
  for _,k in ipairs({'apikey','location','lat','lng','radius','fuel'}) do
    f:write(k,'=',tostring(cfg[k]),'\n')
  end
  f:close(); return true
end
load_config()
local function osd_size()
  local f=io.open('/sys/class/graphics/fb0/virtual_size','r')
  if f then local s=f:read('*l') or '';f:close();local w=tonumber(s:match('^(%d+),'))
    if w and w>=640 and w<1700 then return 1280,720 end end
  return 1920,1080
end
local W,H=osd_size()
local compact=W<1700
local ww,wh=compact and 1140 or 1480,compact and 610 or 860
local perpage=compact and 7 or 10
local function shellquote(s) return "'"..tostring(s):gsub("'", "'\\''").."'" end
-- Dauerhafter Cache pro Standort, Radius und Kraftstoff.
-- Global mindestens 60 s zwischen echten Tankerkoenig-API-Aufrufen;
-- derselbe Datensatz wird maximal alle 300 s erneut angefordert.
local CACHE='/var/tuxbox/config/clevertanken_cache.json'
local GLOBAL_WAIT=60
local SAME_WAIT=300
local function cache_key()
  return table.concat({decimal(cfg.lat,5),decimal(cfg.lng,5),decimal(cfg.radius,1),cfg.fuel,cfg.apikey},'|')
end
local function load_cache()
  local f=io.open(CACHE,'rb')
  if not f then return {last_request=0,entries={}} end
  local raw=f:read('*a');f:close()
  local ok,data=pcall(json.decode,raw or '')
  if not ok or type(data)~='table' then return {last_request=0,entries={}} end
  if type(data.entries)~='table' then data.entries={} end
  data.last_request=tonumber(data.last_request) or 0
  return data
end
local function save_cache(data)
  local f=io.open(CACHE..'.tmp','wb')
  if not f then return end
  f:write(json.encode(data));f:close()
  os.rename(CACHE..'.tmp',CACHE)
end
local function fetch()
  if not coordinate(decimal(cfg.lat,5),90) or not coordinate(decimal(cfg.lng,5),180) then
    return nil,'Ungueltige Koordinaten. Bitte Standort per PLZ neu waehlen.'
  end
  local now=os.time()
  local cache=load_cache()
  local key=cache_key()
  local entry=cache.entries[key]
  local previous=entry and type(entry.stations)=='table' and entry.stations or nil
  local since_global=now-cache.last_request
  local since_same=entry and now-(tonumber(entry.ts) or 0) or SAME_WAIT
  if since_same>=0 and since_same<SAME_WAIT and previous then
    return previous,nil,false,'Cache: erneute Abfrage in '..(SAME_WAIT-since_same)..' s'
  end
  if since_global>=0 and since_global<GLOBAL_WAIT then
    local note='API-Schutz: naechste Anfrage in '..(GLOBAL_WAIT-since_global)..' s'
    if previous then return previous,nil,false,note..' (gespeicherte Preise)' end
    return nil,note,false,note
  end
  if cfg.apikey=='' then return nil,'API-Key fehlt (Konfiguration).' end
  local url='https://creativecommons.tankerkoenig.de/json/list.php?lat='..decimal(cfg.lat,5)..'&lng='..decimal(cfg.lng,5)..'&rad='..decimal(cfg.radius,1)..'&sort='..cfg.sort..'&type='..cfg.fuel..'&apikey='..cfg.apikey
  -- Zeitstempel vor dem Netzaufruf setzen, auch bei Fehlern (keine Anfrageflut).
  cache.last_request=now
  save_cache(cache)
  os.remove(TMP)
  local cmd='curl -4 -sS -L --fail --connect-timeout 12 --max-time 25 --cacert '..shellquote(CA)..' -o '..shellquote(TMP)..' '..shellquote(url)
  local rc=os.execute(cmd)
  local f=io.open(TMP,'rb');local raw=f and f:read('*a') or nil
  if f then f:close() end;os.remove(TMP)
  if rc~=0 and rc~=true then return nil,'Download fehlgeschlagen (curl).' end
  if not raw or raw=='' then return nil,'Leere API-Antwort.' end
  local ok,data=pcall(json.decode,raw)
  if not ok or type(data)~='table' then return nil,'Ungueltige JSON-Antwort.' end
  if data.ok~=true then return nil,tostring(data.message or data.status or 'API-Fehler') end
  if type(data.stations)~='table' then return nil,'Keine Tankstellenliste erhalten.' end
  cache.entries[key]={ts=os.time(),stations=data.stations}
  -- Veraltete Cache-Eintraege nach 24 Stunden entfernen.
  for k,v in pairs(cache.entries) do
    if type(v)~='table' or os.time()-(tonumber(v.ts) or 0)>86400 then cache.entries[k]=nil end
  end
  save_cache(cache)
  return data.stations,nil,true,'Aktuelle Preise geladen'
end
-- Lokale Preishistorie: je Tankstelle/Kraftstoff ein Messwert pro Abruf.
-- Keine Hintergrundabfragen; Vergleich nur bei passenden Messungen vom Vortag.
local HISTORY='/var/tuxbox/config/clevertanken_history.tsv'
local MAX_HISTORY_AGE=8*86400
local function station_id(s)
  return tostring(s.id or '')
end
local function load_history()
  local rows={}
  local f=io.open(HISTORY,'r')
  if not f then return rows end
  for line in f:lines() do
    local ts,id,fuel,price=line:match('^(%d+)\t([^\t]+)\t([^\t]+)\t([%d%.]+)$')
    ts=tonumber(ts);price=tonumber(price)
    if ts and id and fuel and price and os.time()-ts<=MAX_HISTORY_AGE then
      rows[#rows+1]={ts=ts,id=id,fuel=fuel,price=price}
    end
  end
  f:close()
  return rows
end
local function record_prices(stations)
  if not stations or cfg.apikey==DEMO then return end
  local rows=load_history()
  local now=os.time()
  for _,s in ipairs(stations) do
    local id=station_id(s)
    local price=tonumber(s.price)
    if id~='' and price and price>0 then
      rows[#rows+1]={ts=now,id=id,fuel=cfg.fuel,price=price}
    end
  end
  local f=io.open(HISTORY,'w')
  if not f then return end
  for _,r in ipairs(rows) do
    f:write(string.format('%d\t%s\t%s\t%.3f\n',r.ts,r.id,r.fuel,r.price))
  end
  f:close()
end
local function price_trend(s,history)
  if cfg.apikey==DEMO then return nil end
  local id=station_id(s)
  local current=tonumber(s.price)
  if id=='' or not current then return nil end
  local now=os.time()
  local yesterday=os.date('%Y-%m-%d',now-86400)
  local target=now-86400
  local best,bestgap=nil,3601
  for _,r in ipairs(history) do
    if r.id==id and r.fuel==cfg.fuel and os.date('%Y-%m-%d',r.ts)==yesterday then
      local gap=math.abs(r.ts-target)
      if gap<bestgap then best,bestgap=r,gap end
    end
  end
  if not best then return nil end
  local cents=(current-best.price)*100
  return (cents>=0 and math.floor(cents*10+0.5) or math.ceil(cents*10-0.5))/10
end
local function sort_stations(stations)
  if type(stations)~='table' then return end
  table.sort(stations,function(a,b)
    -- Offene Tankstellen mit gueltigem Preis zuerst, aufsteigend.
    local pa=(a.isOpen==true and tonumber(a.price)) or math.huge
    local pb=(b.isOpen==true and tonumber(b.price)) or math.huge
    if pa~=pb then return pa<pb end
    return (tonumber(a.dist) or math.huge)<(tonumber(b.dist) or math.huge)
  end)
end
local function prepare_stations(stations,is_fresh)
  if not stations then return nil end
  local history=load_history() -- vor dem aktuellen Messwert laden
  for _,s in ipairs(stations) do s._trend=price_trend(s,history) end
  -- Die Preishistorie bleibt unveraendert; nur die Anzeige wird gefiltert.
  if is_fresh then record_prices(stations) end
  local visible={}
  for _,s in ipairs(stations) do
    -- Nur Namen, die mit eigenstaendigem "TS" beginnen, ausblenden.
    -- Beispiele: "TS Morsbach", "TS-Gebhardshain".
    local name=tostring(s.name or '')
    if not name:match('^%s*[Tt][Ss][%s%-]') and not name:match('^%s*[Tt][Ss]$') then
      visible[#visible+1]=s
    end
  end
  sort_stations(visible)
  return visible
end
local function window(title,buttons)
  local args={x=math.floor((W-ww)/2),y=math.floor((H-wh)/2),dx=ww,dy=wh,title=title}
  for k,v in pairs(buttons or {}) do args[k]=v end
  return cwindow.new(args)
end
local function label(win,x,y,w,h,s,color)
  ctext.new{parent=win,x=x,y=y,dx=w,dy=h,text=tostring(s),font_text=FONT.MENU,color_text=color or COL.WHITE}
end
-- Standortkoordinaten: Zippopotam.us, bei unplausiblen Daten OSM Nominatim.
-- Deutschland-Grenzen verhindern auch vertauschte, aber numerisch gueltige Felder.
local function german_coords(lat,lng)
  return lat and lng and lat>=47 and lat<=55.2 and lng>=5.5 and lng<=15.6
end
local function postcode_json(url,user_agent)
  os.remove(ZIPTMP)
  local cmd='curl -4 -sS -L --fail --connect-timeout 12 --max-time 20 --cacert '..shellquote(CA)
  if user_agent then cmd=cmd..' -A '..shellquote(user_agent) end
  cmd=cmd..' -o '..shellquote(ZIPTMP)..' '..shellquote(url)
  local rc=os.execute(cmd)
  local f=io.open(ZIPTMP,'rb')
  local raw=f and f:read('*a') or nil
  if f then f:close() end
  os.remove(ZIPTMP)
  if rc~=0 and rc~=true or not raw or raw=='' then return nil end
  local ok,data=pcall(json.decode,raw)
  if not ok or type(data)~='table' then return nil end
  return data
end
local function lookup_postcode(plz)
  if not plz:match('^%d%d%d%d%d$') then return nil,'Bitte eine fuenfstellige PLZ eingeben.' end
  local data=postcode_json('https://api.zippopotam.us/de/'..plz)
  local places,seen={},{}
  local fallback_name=nil
  if data and type(data.places)=='table' then
    for _,place in ipairs(data.places) do
      local lat=coordinate(place.latitude,90)
      local lng=coordinate(place.longitude,180)
      local name=tostring(place['place name'] or '')
      if name~='' and not fallback_name then fallback_name=name end
      if german_coords(lat,lng) and name~='' then
        local key=name..'|'..decimal(lat,5)..'|'..decimal(lng,5)
        if not seen[key] then
          places[#places+1]={lat=lat,lng=lng,location=name..' ('..plz..')',name=name}
          seen[key]=true
        end
      end
    end
  end
  if #places>0 then return places end
  -- Nominatim ist nur Fallback, nicht fuer jede PLZ ein zweiter Aufruf.
  -- Hoechstens eine Anfrage pro Suche; User-Agent nach OSM-Nutzungsregeln.
  local url='https://nominatim.openstreetmap.org/search?postalcode='..plz..'&country=Germany&format=jsonv2&addressdetails=1&limit=5'
  local results=postcode_json(url,'NI-CleverTanken/0.6.7 (NI-Neutrino community plugin)')
  if type(results)=='table' then
    for _,item in ipairs(results) do
      local lat=coordinate(item.lat,90)
      local lng=coordinate(item.lon,180)
      local addr=type(item.address)=='table' and item.address or {}
      local country=tostring(addr.country_code or ''):lower()
      local result_plz=tostring(addr.postcode or '')
      -- Wenn die Antwort eine PLZ enthaelt, muss sie zur Suche passen.
      if german_coords(lat,lng) and (country=='' or country=='de')
         and (result_plz=='' or result_plz==plz) then
        local name=tostring(addr.city or addr.town or addr.village or addr.municipality
          or addr.suburb or fallback_name or '')
        if name=='' then name='Standort' end
        local key=name..'|'..decimal(lat,5)..'|'..decimal(lng,5)
        if not seen[key] then
          places[#places+1]={lat=lat,lng=lng,location=name..' ('..plz..')',name=name}
          seen[key]=true
        end
      end
    end
  end
  if #places==0 then return nil,'Keine gueltigen Koordinaten (auch OSM-Fallback fehlgeschlagen).' end
  return places
end

local digits={}
for i=0,9 do
  local k=RC[tostring(i)] or RC['key_'..i] or RC['num'..i]
  if k then digits[k]=tostring(i) end
end
-- Neutrino verwendet ueblicherweise RC.0 bis RC.9; Varianten werden oben abgefangen.
-- Bei mehreren Orten derselben PLZ den Standort mit den Pfeiltasten waehlen.
-- Es werden nur Orte angeboten, die der PLZ-Dienst tatsaechlich liefert.
local function select_place(places,plz)
  if #places==1 then return places[1] end
  local selected=1
  local rows=compact and 6 or 9
  local win
  local function draw()
    if win then win:hide();win=nil end
    win=window('NI-CleverTanken 0.6.7 - Ort auswaehlen',
      {btnRed='Zurueck',btnGreen='Uebernehmen'})
    label(win,35,35,ww-70,45,'PLZ '..plz..': '..#places..' Orte gefunden')
    label(win,35,95,ww-70,40,'Mit AUF/AB waehlen, OK oder GRUEN bestaetigen.')
    local page=math.floor((selected-1)/rows)
    for i=page*rows+1,math.min(#places,(page+1)*rows) do
      local y=155+(i-page*rows-1)*(compact and 49 or 57)
      local name=(i==selected and '> ' or '  ')..places[i].name
      label(win,35,y,ww-70,42,name,i==selected and COL.YELLOW or COL.WHITE)
    end
    label(win,35,wh-170,ww-70,36,
      'Ort '..selected..'/'..#places..' | Quelle: Zippopotam.us')
    win:paint()
  end
  draw()
  while true do
    local msg=n:GetInput(500)
    if msg==RC.exit or msg==RC.home or msg==RC.setup or msg==RC.red then
      if win then win:hide() end
      return nil
    elseif msg==RC.ok or msg==RC.green then
      if win then win:hide() end
      return places[selected]
    elseif msg==RC.down and selected<#places then
      selected=selected+1;draw()
    elseif msg==RC.up and selected>1 then
      selected=selected-1;draw()
    elseif msg==RC.right and selected<#places then
      selected=math.min(#places,selected+rows);draw()
    elseif msg==RC.left and selected>1 then
      selected=math.max(1,selected-rows);draw()
    end
  end
end

local function postcode_dialog()
  local plz=''
  local info='Fuenfstellige Postleitzahl eingeben.'
  local win
  local function draw()
    if win then win:hide();win=nil end
    win=window('NI-CleverTanken 0.6.7 - Standort suchen',
      {btnRed='Abbrechen',btnGreen='Suchen',btnYellow='Loeschen'})
    label(win,35,55,ww-70,55,'Postleitzahl: '..plz..string.rep('_',5-#plz),COL.YELLOW)
    label(win,35,145,ww-70,55,'Ziffern 0-9 eingeben; GELB: letzte Ziffer loeschen')
    label(win,35,225,ww-70,65,info)
    label(win,35,wh-180,ww-70,36,'Ortskoordinaten: Zippopotam.us / OpenStreetMap')
    win:paint()
  end
  draw()
  while true do
    local msg=n:GetInput(500)
    if msg==RC.exit or msg==RC.home or msg==RC.setup or msg==RC.red then break end
    local digit=digits[msg]
    if digit and #plz<5 then plz=plz..digit;draw()
    elseif msg==RC.yellow then plz=plz:sub(1,-2);draw()
    elseif msg==RC.green or msg==RC.ok then
      local places,err=lookup_postcode(plz)
      if places then
        if win then win:hide();win=nil end
        local result=select_place(places,plz)
        if result then
          local old={lat=cfg.lat,lng=cfg.lng,location=cfg.location}
          cfg.lat=result.lat;cfg.lng=result.lng;cfg.location=result.location
          if save_config() then return true end
          cfg.lat=old.lat;cfg.lng=old.lng;cfg.location=old.location
          info='Konfiguration konnte nicht gespeichert werden.'
        else
          info='Ortsauswahl abgebrochen; Standort unveraendert.'
        end
      else info=err end
      draw()
    end
  end
  if win then win:hide() end
  return false
end

-- Favoriten separat speichern; API-Key bleibt ausschliesslich in clevertanken.conf.
local FAVORITES='/var/tuxbox/config/clevertanken_favorites.json'
local MAX_FAVORITES=5
local function load_favorites()
  local f=io.open(FAVORITES,'rb')
  if not f then return {} end
  local raw=f:read('*a');f:close()
  local ok,items=pcall(json.decode,raw or '')
  if not ok or type(items)~='table' then return {} end
  local result={}
  for _,item in ipairs(items) do
    if #result>=MAX_FAVORITES then break end
    if type(item)=='table' and type(item.location)=='string'
       and item.location~='' and german_coords(coordinate(item.lat,90),coordinate(item.lng,180)) then
      result[#result+1]={location=item.location,lat=coordinate(item.lat,90),lng=coordinate(item.lng,180)}
    end
  end
  return result
end
local function save_favorites(items)
  local tmp=FAVORITES..'.tmp'
  local f=io.open(tmp,'wb')
  if not f then return false end
  local ok,raw=pcall(json.encode,items)
  if not ok then f:close();os.remove(tmp);return false end
  f:write(raw);f:close()
  if not os.rename(tmp,FAVORITES) then os.remove(tmp);return false end
  return true
end
local function same_favorite(a,b)
  return decimal(a.lat,5)==decimal(b.lat,5)
     and decimal(a.lng,5)==decimal(b.lng,5)
end
local function favorites_dialog()
  local items=load_favorites()
  local selected=1
  local info='OK: Standort uebernehmen | GRUEN: aktuellen Standort speichern'
  local confirm_delete=false
  local win
  local function draw()
    if win then win:hide();win=nil end
    win=window('NI-CleverTanken 0.6.7 - Favoriten',
      {btnRed='Zurueck',btnGreen='Speichern',btnYellow='Loeschen'})
    label(win,35,25,ww-70,40,'Gespeicherte Standorte: '..#items..'/'..MAX_FAVORITES)
    label(win,35,68,ww-70,35,'Aktuell: '..cfg.location)
    if #items==0 then
      label(win,35,140,ww-70,45,'Noch keine Favoriten gespeichert.')
    else
      for i,item in ipairs(items) do
        local y=140+(i-1)*(compact and 48 or 62)
        local mark=(i==selected and '> ' or '  ')
        local active=same_favorite(item,cfg) and '  [aktiv]' or ''
        label(win,35,y,ww-70,42,mark..item.location..active,
          i==selected and COL.YELLOW or COL.WHITE)
      end
    end
    label(win,35,wh-215,ww-70,40,info,confirm_delete and COL.YELLOW or COL.WHITE)
    label(win,35,wh-165,ww-70,35,'AUF/AB: Auswahl | GELB zweimal: Loeschen')
    win:paint()
  end
  draw()
  while true do
    local msg=n:GetInput(500)
    if msg==RC.exit or msg==RC.home or msg==RC.setup or msg==RC.red then
      if win then win:hide() end
      return false
    elseif msg==RC.up and selected>1 then
      selected=selected-1;confirm_delete=false;draw()
    elseif msg==RC.down and selected<#items then
      selected=selected+1;confirm_delete=false;draw()
    elseif msg==RC.green then
      confirm_delete=false
      if not german_coords(cfg.lat,cfg.lng) then
        info='Aktueller Standort hat ungueltige Koordinaten.'
      else
        local duplicate=false
        for _,item in ipairs(items) do
          if same_favorite(item,cfg) then duplicate=true;break end
        end
        if duplicate then info='Dieser Standort ist bereits gespeichert.'
        elseif #items>=MAX_FAVORITES then info='Maximal '..MAX_FAVORITES..' Favoriten moeglich.'
        else
          items[#items+1]={location=cfg.location,lat=cfg.lat,lng=cfg.lng}
          if save_favorites(items) then
            selected=#items;info='Favorit gespeichert.'
          else
            table.remove(items);info='Favoriten konnten nicht gespeichert werden.'
          end
        end
      end
      draw()
    elseif msg==RC.yellow then
      if #items>0 then
        if not confirm_delete then
          confirm_delete=true;info='GELB erneut druecken, um Favorit zu loeschen.'
        else
          local removed=table.remove(items,selected)
          if save_favorites(items) then
            selected=math.max(1,math.min(selected,#items))
            info='Favorit geloescht.'
          else
            table.insert(items,selected,removed)
            info='Loeschen fehlgeschlagen.'
          end
          confirm_delete=false
        end
        draw()
      end
    elseif msg==RC.ok and #items>0 then
      local item=items[selected]
      local old={lat=cfg.lat,lng=cfg.lng,location=cfg.location}
      cfg.lat=item.lat;cfg.lng=item.lng;cfg.location=item.location
      if save_config() then
        if win then win:hide() end
        return true
      end
      cfg.lat=old.lat;cfg.lng=old.lng;cfg.location=old.location
      info='Standort konnte nicht gespeichert werden.';confirm_delete=false;draw()
    end
  end
end

local function settings()
  local win
  local message='OK: PLZ-Suche | BLAU: Favoriten | API-Key in Konfigurationsdatei.'
  local function draw()
    if win then win:hide();win=nil end
    win=window('NI-CleverTanken 0.6.7 - Einstellungen',{btnRed='Zurueck',btnGreen='Radius +',btnYellow='Radius -',btnBlue='Favoriten'})
    label(win,35,30,ww-70,45,'Standort: '..cfg.location)
    label(win,35,90,ww-70,45,'Koordinaten: '..decimal(cfg.lat,5)..' / '..decimal(cfg.lng,5))
    label(win,35,150,ww-70,45,'Suchradius: '..cfg.radius..' km (1 bis 25 km)')
    label(win,35,210,ww-70,45,'Kraftstoff: '..cfg.fuel:upper())
    label(win,35,300,ww-70,75,message)
    if cfg.apikey==DEMO then label(win,35,wh-195,ww-70,40,'Demo-Schluessel: keine echten Preise',COL.RED) end
    win:paint()
  end
  draw()
  while true do
    local msg=n:GetInput(500)
    if msg==RC.home or msg==RC.exit or msg==RC.setup or msg==RC.red then break end
    if msg==RC.ok then
      if win then win:hide();win=nil end
      local changed=postcode_dialog()
      message=changed and 'Standort gespeichert.' or 'Standort unveraendert.'
      draw()
      msg=nil
    elseif msg==RC.blue then
      if win then win:hide();win=nil end
      local changed=favorites_dialog()
      message=changed and 'Favorit als Standort uebernommen.' or 'Favoritenverwaltung beendet.'
      draw()
      msg=nil
    elseif msg==RC.green then cfg.radius=math.min(25,cfg.radius+1)
    elseif msg==RC.yellow then cfg.radius=math.max(1,cfg.radius-1)
    else msg=nil end
    if msg then
      if save_config() then message='Einstellungen gespeichert.' else message='Speichern fehlgeschlagen: '..CONF end
      draw()
    end
  end
  if win then win:hide();win=nil end
end
local function details(station)
  if not station then return end
  local win=window('NI-CleverTanken 0.6.7 - Tankstellendetails',
                   {btnRed='Zurueck'})
  local function value(v)
    if v==nil or v=='' then return 'Keine Angabe' end
    return tostring(v)
  end
  local address=value(station.street)
  if station.houseNumber and tostring(station.houseNumber)~='' then
    address=address..' '..tostring(station.houseNumber)
  end
  local city=(station.postCode and tostring(station.postCode)..' ' or '')..value(station.place)
  local price=tonumber(station.price)
  local status=station.isOpen==true and 'Geöffnet' or 'Geschlossen'
  local fields={
    'Tankstelle: '..value(station.name),
    'Marke: '..value(station.brand),
    'Straße: '..address,
    'Ort: '..city,
    'Entfernung: '..(station.dist and string.format('%.1f km',tonumber(station.dist) or 0) or 'Keine Angabe'),
    'Kraftstoff: '..cfg.fuel:upper(),
    'Preis: '..(price and string.format('%.3f EUR/Liter',price) or 'Nicht verfuegbar'),
    'Status: '..status
  }
  local rowh=compact and 55 or 72
  for i,v in ipairs(fields) do
    local color=COL.WHITE
    if i==7 and price then color=COL.GREEN end
    if i==8 then color=station.isOpen==true and COL.GREEN or COL.RED end
    label(win,35,28+(i-1)*rowh,ww-70,rowh-5,v,color)
  end
  label(win,35,wh-88,ww-70,36,'Quelle: Tankerkoenig (CC BY 4.0)')
  win:paint()
  while true do
    local msg=n:GetInput(500)
    if msg==RC.home or msg==RC.exit or msg==RC.setup
       or msg==RC.red or msg==RC.ok then break end
  end
  win:hide()
end
local function main()
  local stations,err,fresh,notice=fetch()
  stations=prepare_stations(stations,fresh)
  local page=1;local selected=1;local win
  local function draw()
    if win then win:hide();win=nil end
    local pages=math.max(1,math.ceil((stations and #stations or 0)/perpage))
    if page>pages then page=pages end
    if stations and #stations>0 then selected=math.max(1,math.min(selected,#stations)) end
    win=window('NI-CleverTanken 0.6.7'..(cfg.apikey==DEMO and ' - DEMO' or ''),{btnRed='Schliessen',btnGreen='Aktualisieren',btnYellow='Kraftstoff',btnBlue='Einstellungen'})
    label(win,35,20,ww-70,45,cfg.location..'  |  '..cfg.fuel:upper()..'  |  Umkreis '..cfg.radius..' km')
    -- Spaltenkoepfe an denselben X-Positionen wie die Datenfelder.
    label(win,35,75,math.floor(ww*.53),40,'Tankstelle')
    label(win,math.floor(ww*.55),75,math.floor(ww*.24),40,'Preis / Trend')
    label(win,math.floor(ww*.79),75,ww-math.floor(ww*.79)-20,40,'Entfernung / Status')
    if not stations then label(win,35,145,ww-70,60,'Fehler: '..tostring(err),COL.RED)
    elseif #stations==0 then label(win,35,145,ww-70,60,'Keine Tankstellen gefunden.')
    else
      local rowh=compact and 50 or 52
      for slot=1,perpage do
        local s=stations[(page-1)*perpage+slot]
        if s then
          local y=125+(slot-1)*rowh
          local index=(page-1)*perpage+slot
          local chosen=(index==selected)
          local name=tostring(s.name or s.brand or 'Unbekannt')
          if #name>32 then name=name:sub(1,29)..'...' end
          label(win,35,y,math.floor(ww*.53),rowh-5,(chosen and "> " or "  ")..name,chosen and COL.YELLOW or COL.WHITE)
          local price=tonumber(s.price)
          local opened=(s.isOpen==true)
          local shown=price and string.format('%.3f EUR',price) or '---'
          local trend=s._trend
          if trend then
            if trend>0.05 then shown=shown..string.format('  ^ +%.1f ct',trend)
            elseif trend< -0.05 then shown=shown..string.format('  v %.1f ct',trend)
            else shown=shown..'  ='
            end
          end
          label(win,math.floor(ww*.55),y,math.floor(ww*.24),rowh-5,shown,
            trend and trend>0.05 and COL.RED or (opened and price and COL.GREEN or COL.WHITE))
          label(win,math.floor(ww*.79),y,ww-math.floor(ww*.79)-20,rowh-5,string.format('%.1f km  %s',tonumber(s.dist) or 0,opened and 'Offen' or 'Zu'))
        end
      end
    end
    -- Status und Datenquelle dauerhaft in zwei getrennten Zeilen anzeigen.
    -- Beide Zeilen liegen oberhalb der Farbtastenleiste.
    local footer_y=compact and (wh-150) or (wh-205)
    local status_text=(notice or 'Aktuelle Preise geladen')..' | Seite '..page..'/'..pages
    label(win,35,footer_y,ww-70,35,status_text)
    label(win,35,footer_y+43,ww-70,35,
      'Quelle: Tankerkoenig (CC BY 4.0) | Trend: Cent ggü. gestern (±1 h)')
    if cfg.apikey==DEMO then label(win,35,wh-48,ww-70,35,'Demo-Daten - keine realen Kraftstoffpreise') end
    win:paint()
  end
  draw()
  while true do
    local msg=n:GetInput(500)
    if msg==RC.home or msg==RC.exit or msg==RC.setup or msg==RC.red then break end
    if msg==RC.green then stations,err,fresh,notice=fetch();stations=prepare_stations(stations,fresh);page=1;selected=1;draw()
    elseif msg==RC.yellow then
      local i=1;for j,v in ipairs(fuels) do if v==cfg.fuel then i=j;break end end
      cfg.fuel=fuels[i%#fuels+1];save_config();stations,err,fresh,notice=fetch();stations=prepare_stations(stations,fresh);page=1;selected=1;draw()
    elseif msg==RC.blue then settings();stations,err,fresh,notice=fetch();stations=prepare_stations(stations,fresh);page=1;selected=1;draw()
    elseif msg==RC.ok then
      if stations and stations[selected] then
        win:hide();win=nil
        details(stations[selected])
        draw()
      end
    elseif msg==RC.down then
      if stations and selected<#stations then
        selected=selected+1
        page=math.floor((selected-1)/perpage)+1
        draw()
      end
    elseif msg==RC.up then
      if stations and selected>1 then
        selected=selected-1
        page=math.floor((selected-1)/perpage)+1
        draw()
      end
    elseif msg==RC.right or msg==RC.left then
      if stations and #stations>0 then
        local pages=math.ceil(#stations/perpage)
        page=math.max(1,math.min(pages,page+(msg==RC.right and 1 or -1)))
        selected=(page-1)*perpage+1
        draw()
      end
    end
  end
  if win then win:hide();win=nil end
end
main()
