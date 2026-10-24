-- Heizölpreise v1.0.1 for NI-Neutrino
-- Based on satbaby's Heizölpreise v0.6, GPL-2.0-or-later
local n=neutrino()
local CA='/etc/ssl/certs/ca-certificates.crt'
local TMP='/tmp/ni_heizoel24.html'
local countries={de={url='https://www.heizoel24.de/heizoelpreise',name='Deutschland'},at={url='https://www.heizoel24.at/heizoelpreise',name='Österreich'}}
local function get_page(url)
  local cmd='curl -4 -sS -L --fail --connect-timeout 12 --max-time 30 --cacert '..CA..' -o '..TMP..' '..url
  os.remove(TMP)
  local result=os.execute(cmd)
  local f=io.open(TMP,'rb')
  local html=f and f:read('*a') or nil
  if f then f:close() end
  os.remove(TMP)
  if result~=0 and result~=true then return nil,'Download fehlgeschlagen (curl).' end
  if not html or #html<1000 then return nil,'Keine vollständige Antwort erhalten.' end
  return html
end
local function parse(html,country)
  local h1=html:find('<h1 class="title-strap',1,true)
  local start=h1 and html:find('Heizölpreise aktuell für '..country,h1,true)
  if not start then return nil,'Preisüberschrift nicht gefunden.' end
  local chunk=html:sub(start,start+3500)
  local date=chunk:match('100l%s+(%d%d?%.%d%d?%.%d%d)')
  local price=chunk:match('class="display%-3 font%-weight%-bold.-<span[^>]*>([%d%.]+,%d%d)</span>')
  local change=chunk:match('class="font%-weight%-bold"[^>]*>([+%-]?%d+[,.]%d+%%)</span>%s+zum Vortag')
  if not price then return nil,'Tagespreis nicht gefunden (HTML geändert?).' end
  return {date=date or 'unbekannt',price=price,change=change or 'nicht verfügbar'}
end
-- OSD-Aufloesung: fb0/virtual_size ist auf manchen Boxen die
-- virtuelle (z.B. doppelt hohe) Speicherflaeche, NICHT die sichtbare OSD-Hoehe.
-- Daher NICHT als Fensterkoordinate verwenden!
-- Fuer die beiden getesteten OSD-Modi sichere Voreinstellung anhand der Breite.
-- Bei abweichender OSD-Aufloesung hier beide Werte manuell eintragen.
local OSD_WIDTH_OVERRIDE=0
local OSD_HEIGHT_OVERRIDE=0
local function osd_size()
  if OSD_WIDTH_OVERRIDE>0 and OSD_HEIGHT_OVERRIDE>0 then
    return OSD_WIDTH_OVERRIDE,OSD_HEIGHT_OVERRIDE
  end
  local f=io.open('/sys/class/graphics/fb0/virtual_size','r')
  if f then
    local line=f:read('*l') or ''
    f:close()
    local w=tonumber(line:match('^(%d+),'))
    -- Nur die Breite als Hinweis verwenden; die virtuelle Hoehe ignorieren.
    if w and w>=640 and w<1700 then return 1280,720 end
  end
  return 1920,1080
end
local OSD_W,OSD_H=osd_size()
local compact=(OSD_W<1700 or OSD_H<900)
local function centered_window(w,h)
  return math.max(0,math.floor((OSD_W-w)/2)),math.max(0,math.floor((OSD_H-h)/2))
end
local function show(country)
  local html,err=get_page(countries[country].url)
  local data
  if html then data,err=parse(html,countries[country].name) end
  local ww,wh=compact and 1100 or 1380,compact and 480 or 500
  local wx,wy=centered_window(ww,wh)
  local win=cwindow.new{x=wx,y=wy,dx=ww,dy=wh,
    title='Heizölpreise 1.0.1 - '..countries[country].name,
    btnBlue='Bundesländer',
    btnRed='Land wechseln',btnGreen='Schliessen'}
  local function label(x,y,width,height,value,font,color)
    ctext.new{parent=win,x=x,y=y,dx=width,dy=height,
      text=value,font_text=font or FONT.MENU,color_text=color or COL.WHITE}
  end
  local content_width=ww-100
  if data then
    local trend=COL.WHITE
    local arrow='='
    if data.change:sub(1,1)=='-' then
      trend=COL.GREEN
      arrow='v'
    elseif data.change:sub(1,1)=='+' then
      trend=COL.RED
      arrow='^'
    end
    label(48,34,content_width,45,'HEIZOEL  |  '..countries[country].name,FONT.MENU_TITLE)
    label(48,105,content_width,85,data.price..' EUR',FONT.MENU_TITLE)
    label(48,180,content_width,40,'Durchschnittspreis je 100 Liter',FONT.MENU)
    label(48,240,content_width,55,arrow..'  '..data.change..' zum Vortag',FONT.MENU_TITLE,trend)
    label(48,315,content_width,36,'Stand: '..data.date..'    |    Quelle: HeizOel24',FONT.MENU)
    label(48,348,content_width,34,'Durchschnittswert - kein individuelles Angebot',FONT.MENU)
  else
    label(48,60,content_width,50,'Preisdaten konnten nicht geladen werden.',FONT.MENU_TITLE,COL.RED)
    label(48,135,content_width,95,tostring(err),FONT.MENU)
    label(48,240,content_width,70,countries[country].url,FONT.MENU)
  end
  win:paint()
  -- Jede Abbruchtaste beendet die Eingabeschleife explizit.
  -- Die aufrufende Hauptschleife entscheidet anschließend über das Skriptende.
  local action='quit'
  while true do
    local msg=n:GetInput(500)
    if msg==RC.red then action='switch';break end
    if msg==RC.blue then action='regions';break end
    if msg==RC.home or msg==RC.exit or msg==RC.setup
       or msg==RC.green or msg==RC.ok then
      action='quit'
      break
    end
  end
  win:hide()
  win=nil
  return action
end
-- Alle 16 Bundesländer alphabetisch sortiert.
local regions_de={
  {name='Baden-Württemberg',slug='baden-wuerttemberg'},
  {name='Bayern',slug='bayern'},
  {name='Berlin',slug='berlin'},
  {name='Brandenburg',slug='brandenburg'},
  {name='Bremen',slug='bremen'},
  {name='Hamburg',slug='hamburg'},
  {name='Hessen',slug='hessen'},
  {name='Mecklenburg-Vorpommern',slug='mecklenburg-vorpommern'},
  {name='Niedersachsen',slug='niedersachsen'},
  {name='Nordrhein-Westfalen',slug='nordrhein-westfalen'},
  {name='Rheinland-Pfalz',slug='rheinland-pfalz'},
  {name='Saarland',slug='saarland'},
  {name='Sachsen',slug='sachsen'},
  {name='Sachsen-Anhalt',slug='sachsen-anhalt'},
  {name='Schleswig-Holstein',slug='schleswig-holstein'},
  {name='Thüringen',slug='thueringen'},
}
-- Österreichische Bundesländer alphabetisch sortiert.
local regions_at={
  {name='Burgenland',slug='burgenland'},
  {name='Kärnten',slug='kaernten'},
  {name='Niederösterreich',slug='niederoesterreich'},
  {name='Oberösterreich',slug='oberoesterreich'},
  {name='Salzburg',slug='salzburg'},
  {name='Steiermark',slug='steiermark'},
  {name='Tirol',slug='tirol'},
  {name='Vorarlberg',slug='vorarlberg'},
  {name='Wien',slug='wien'},
}
local function parse_region(html,name)
  local heading='Heizölpreise für '..name
  local h1=html:find('<h1',1,true)
  local start=h1 and html:find(heading,h1,true)
  if not start then return nil,'Überschrift nicht gefunden' end
  local chunk=html:sub(start,start+3500)
  local date=chunk:match('100l%s+(%d%d?%.%d%d?%.%d%d)')
  local price=chunk:match('class="display%-3 font%-weight%-bold.-<span[^>]*>([%d%.]+,%d%d)</span>')
  local change=chunk:match('class="font%-weight%-bold"[^>]*>([+%-]?%d+[,.]%d+%%)</span>%s+zum Vortag')
  if not price then return nil,'Preis nicht gefunden' end
  return {price=price,date=date or '?',change=change or '?'}
end
local function show_regions(country)
  local regions=(country=='at') and regions_at or regions_de
  local rows={}
  for i,r in ipairs(regions) do
    local html,err=get_page(countries[country].url..'/'..r.slug)
    local data
    if html then data,err=parse_region(html,r.name) end
    rows[i]={name=r.name,data=data,err=err}
  end
  local ww,wh=compact and 1140 or 1480,compact and 610 or 860
  local wx,wy=centered_window(ww,wh)
  local page=1
  local per_page=compact and 8 or #rows
  local pages=math.ceil(#rows/per_page)
  local win
  local function label(x,y,w,h,s,color)
    ctext.new{parent=win,x=x,y=y,dx=w,dy=h,text=s,
      font_text=FONT.MENU,color_text=color or COL.WHITE}
  end
  local function draw_page()
    if win then win:hide() end
    local title='Heizölpreise 1.0.1 - '..countries[country].name..' - Bundesländer'
    if compact then title='Heizölpreise - '..countries[country].name..' - Bundesländer' end
    win=cwindow.new{x=wx,y=wy,dx=ww,dy=wh,title=title,btnBlue='Zurück'}
    if compact then
      label(35,25,590,40,'Bundesland')
      label(640,25,190,40,'EUR/100l')
      label(860,25,205,40,'Vortag')
      for slot=1,per_page do
        local row=rows[(page-1)*per_page+slot]
        if row then
          local y=80+(slot-1)*51
          local data=row.data
          local color=COL.WHITE
          if data and data.change:sub(1,1)=='-' then color=COL.GREEN
          elseif data and data.change:sub(1,1)=='+' then color=COL.RED end
          label(35,y,580,45,row.name)
          label(640,y,190,45,data and data.price or '---')
          label(860,y,205,45,data and data.change or '---',color)
        end
      end
      label(35,500,620,36,'HeizOel24 | EUR/100l | Seite '..page..'/'..pages)
      if pages>1 then
        label(715,500,380,36,'<  Seite wechseln  >')
      end
    else
      local per_column=(country=='at') and 5 or 8
      for col=0,1 do
        local x=35+col*725
        label(x,30,350,40,'Bundesland')
        label(x+365,30,150,40,'EUR/100l')
        label(x+530,30,160,40,'Vortag')
      end
      for i,row in ipairs(rows) do
        local col=math.floor((i-1)/per_column)
        local rownum=(i-1)%per_column
        local x=35+col*725
        local y=95+rownum*70
        local data=row.data
        local color=COL.WHITE
        if data and data.change:sub(1,1)=='-' then color=COL.GREEN
        elseif data and data.change:sub(1,1)=='+' then color=COL.RED end
        if row.name=='Mecklenburg-Vorpommern' then
          label(x,y-5,355,34,'Mecklenburg-')
          label(x,y+25,355,34,'Vorpommern')
        else
          label(x,y,355,48,row.name)
        end
        label(x+365,y,150,48,data and data.price or '---')
        label(x+530,y,160,48,data and data.change or '---',color)
      end
      label(35,690,1370,34,'Durchschnittspreis je 100 Liter  |  Quelle: HeizOel24')
    end
    win:paint()
  end
  draw_page()
  while true do
    local msg=n:GetInput(500)
    -- HOME/EXIT verlässt nur die Bundesländeransicht.
    -- Erst HOME/EXIT in der Hauptansicht beendet das gesamte Plugin.
    if msg==RC.blue or msg==RC.home or msg==RC.setup
       or msg==RC.exit or msg==RC.ok then break end
    if compact and pages>1 then
      if msg==RC.right or msg==RC.down then
        page=(page%pages)+1
        draw_page()
      elseif msg==RC.left or msg==RC.up then
        page=((page+pages-2)%pages)+1
        draw_page()
      end
    end
  end
  if win then win:hide(); win=nil end
end

local function main()
  local country='de'
  while true do
    local action=show(country)
    if action=='regions' then
      show_regions(country)
    elseif action=='switch' then
      country=(country=='de') and 'at' or 'de'
    else
      -- Kein weiteres Fenster und keine weitere Eingabeschleife:
      -- Lua kehrt sauber zu Neutrino zurück.
      return
    end
  end
end

main()
