mtLeftMenu_x	= SCREEN.OFF_X + 10
mtLeftMenu_w	= math.floor(N:scale2Res(240))
subMenuTop	= math.floor(N:scale2Res(10))
subMenuLeft	= math.floor(N:scale2Res(8))
subMenuSpace	= math.floor(N:scale2Res(16))
subMenuHight	= math.floor(N:scale2Res(26))
mtRightMenu_x	= mtLeftMenu_x + 8 + mtLeftMenu_w
mtRightMenu_w	= SCREEN.END_X - mtRightMenu_x-8
mtRightMenu_select	= 1
mtRightMenu_list_start	= 0
mtRightMenu_list_total	= 0
mtRightMenu_view_page	= 1
mtRightMenu_max_page	= 1

leftInfoBox_x	= 0
leftInfoBox_y	= 0
leftInfoBox_w	= 0
leftInfoBox_h	= 0

mtList		= {}
mtBuffer	= {}
titleList	= {}
themeList	= {}

-- local recordings state
local localRecordingsActive = false
local localRecordingsEntries = {}
local localRecordingsRawEntries = {}
local localRecordingsMenuIndex = nil
local localRecordingsLastPath = nil
local localRecordingsMode = false

-- load shared helpers
local Filters = dofile(pluginScriptPath .. '/mt_filters.lua')
dofile(pluginScriptPath .. '/mt_util.lua')

local sortEntries = Filters.sortEntries
local requiresFullBuffer = Filters.requiresFullBuffer
local matchesSearchFilters = Filters.matchesSearchFilters
local entryMatchesFilters = Filters.entryMatchesFilters

-- TODO: Accessibility filter is applied both when buffering (mtBuffer) and when paging (mtList);
-- consider consolidating to a single pass to reduce work and keep totals consistent.

local function getCachePaths()
	local configPath = (CONF_PATH or '/var/tuxbox/config/') .. H.scriptBase() .. '_local_recordings.json'
	local tmpPath = pluginTmpPath .. '/local_recordings.json'
	if conf and conf.localRecordingsCachePersistent == 'on' then
		return configPath, tmpPath
	end
	return tmpPath, configPath
end

function isLocalRecordingsMode()
	return localRecordingsMode
end

local function joinPath(base, leaf)
	if base == nil or base == '' then
		return leaf or ''
	end
	if leaf == nil or leaf == '' then
		return base
	end
	if string.sub(base, -1) == '/' then
		return base .. leaf
	end
	return base .. '/' .. leaf
end

local function isRecordingPath(path)
	if not path or path == '' then
		return false
	end
	local lower = string.lower(path)
	return lower:match('%.ts$') ~= nil or lower:match('%.mp4$') ~= nil or lower:match('%.mkv$') ~= nil
end

-- Directories to skip during scans (case-insensitive, exact folder name)
-- Default blacklist for directory scanning; can be overridden via conf.localRecordingsDirBlacklist (comma/semicolon separated)
local defaultScanDirBlacklist = { 'archive', 'archives', '.git', 'git2' }
local scanDirBlacklist = nil
local scanDirBlacklistRaw = nil

function resetScanDirBlacklistCache()
	scanDirBlacklist = nil
	scanDirBlacklistRaw = nil
end

local function buildScanDirBlacklist(raw)
	local set = {}
	local function addEntry(name)
		name = trim(name or '')
		if name == '' then
			return
		end
		if string.find(name, '/') then
			H.printf("[neutrino-mediathek] ignore invalid blacklist entry (contains /): %s", tostring(name))
			return
		end
		set[string.lower(name)] = true
	end

	if raw and raw ~= '' then
		for part in string.gmatch(raw, '([^,;]+)') do
			addEntry(part)
		end
	else
		for _, name in ipairs(defaultScanDirBlacklist) do
			addEntry(name)
		end
	end
	return set
end

local function getScanDirBlacklist()
	local raw = conf and conf.localRecordingsDirBlacklist
	if scanDirBlacklist == nil or scanDirBlacklistRaw ~= raw then
		scanDirBlacklist = buildScanDirBlacklist(raw)
		scanDirBlacklistRaw = raw
	end
	return scanDirBlacklist
end

local function isBlacklistedDir(path)
	if not path or path == '' then
		return false
	end
	local name = path:match("([^/]+)$") or path
	return getScanDirBlacklist()[string.lower(name)] == true
end

local function readLocalRecordingMetadata(tsPath, pre)
	local metadata = {
		path = tsPath
	}
	metadata.size = pre and pre.size or nil
	metadata.mtime = pre and pre.mtime or nil
	if not metadata.size or not metadata.mtime then
		metadata.size, metadata.mtime = getFileAttributes(tsPath)
	end

	local xmlPaths = { tsPath .. '.xml' }
	if tsPath:sub(-3):lower() == '.ts' then
		table.insert(xmlPaths, tsPath:sub(1, -4) .. '.xml')
	end

	for _, candidate in ipairs(xmlPaths) do
		if fileExists(candidate) then
			local fh = io.open(candidate, 'r')
			if fh then
				local content = fh:read('*a')
				fh:close()
				if content then
					metadata.title = decodeHtmlEntities(trim(content:match('<epgtitle>(.-)</epgtitle>')))
					metadata.channel = decodeHtmlEntities(trim(content:match('<channelname>(.-)</channelname>')))
					metadata.description = decodeHtmlEntities(trim(content:match('<info1>(.-)</info1>')))
					local info2 = content:match('<info2>(.-)</info2>')
					metadata.theme = decodeHtmlEntities(trim(parseThemeFromInfo(info2)))
					local length = trim(content:match('<length>(.-)</length>'))
					metadata.durationSec = parseDurationString(length)
				end
			end
			break
		end
	end

	return metadata
end

createLocalRecordingEntry = function(tsPath, pre)
	local metadata = readLocalRecordingMetadata(tsPath, pre)
	if not metadata then
		return nil
	end
	local base = tsPath:match('([^/]+)$') or tsPath
	local title = metadata.title or base:gsub('%.[Tt][Ss]$', '')
	local timestamp = metadata.mtime or os.time()
	local durationSec = metadata.durationSec or 0
	local descParts = {}
	if metadata.description and metadata.description ~= '' then
		table.insert(descParts, metadata.description)
	end
	table.insert(descParts, string.format(l.localRecordingsDescription, tsPath, humanFileSize(metadata.size)))
	return {
		channel = metadata.channel or l.menuLocalRecordings,
		-- In Lokalmode: erste Spalte = Titel, zweite Spalte = Pfad
		theme = title,
		title = tsPath,
		date = os.date(l.formatDate, timestamp),
		time = os.date(l.formatTime, timestamp),
		duration = formatDuration(durationSec),
		durationSec = durationSec,
		timestamp = timestamp,
		geo = '',
		description = table.concat(descParts, '\n\n'),
		url = tsPath,
		url_small = tsPath,
		url_hd = tsPath,
		parse_m3u8 = '',
		isLocalRecording = true,
		fileSize = metadata.size,
		fileMtime = metadata.mtime
	}
	end

local function parseFindLine(line)
	-- format: /path/file|12345|1700000000.123
	local p, s, t = line:match("^(.-)|(%d+)|([%d%.]+)$")
	if not p or not s or not t then
		return nil
	end
	return {
		path = p,
		size = tonumber(s),
		mtime = math.floor(tonumber(t) or 0)
	}
end

local findSupportsPrintfFlag = nil
local function findSupportsPrintf()
	if findSupportsPrintfFlag ~= nil then
		return findSupportsPrintfFlag
	end
	-- Try a minimal find command; success means printf is supported
	local ok = os.execute("find /dev/null -maxdepth 0 -printf '' >/dev/null 2>&1")
	findSupportsPrintfFlag = (ok == true or ok == 0)
	return findSupportsPrintfFlag
end

collectRecordingMeta = function(basePath, out)
	if not directoryExists(basePath) then
		H.printf("[neutrino-mediathek] collectRecordingMeta: basePath missing %s", tostring(basePath))
		return false
	end

	local usePrintf = findSupportsPrintf()
	local findCmd
	if usePrintf then
		findCmd = string.format([[
			find %s -path '*/lost+found' -prune -o -type f \
				\( -iname '*.ts' -o -iname '*.mp4' -o -iname '*.mkv' \) \
				-printf '%%p|%%s|%%T@\\n' 2>/dev/null
		]], string.format('%q', basePath))
	else
		-- BusyBox find fallback without -printf
		findCmd = string.format([[
			find %s -path '*/lost+found' -prune -o -type f \
				\( -iname '*.ts' -o -iname '*.mp4' -o -iname '*.mkv' \) \
				-print 2>/dev/null
		]], string.format('%q', basePath))
	end

	local pipe = io.popen(findCmd)
	local usedFastPath = false
	if pipe then
		for line in pipe:lines() do
			local meta = nil
			if usePrintf then
				meta = parseFindLine(line)
			else
				-- only path available, stat in Lua
				if line and line ~= '' then
					local size, mtime = getFileAttributes(line)
					if size and mtime then
						meta = {path=line, size=size, mtime=mtime}
					end
				end
			end
			if meta and meta.path then table.insert(out, meta) end
			usedFastPath = true
		end
		pipe:close()
		if usedFastPath then
			H.printf("[neutrino-mediathek] collectRecordingMeta: fast path entries=%d", #out)
			if #out > 0 then
				return true
			end
		end
	end
	H.printf("[neutrino-mediathek] collectRecordingMeta: fast path empty, fallback to ls/stat")

	-- Fallback: recursive ls/stat (slower)
	local cmd = string.format("ls -1A %s 2>/dev/null", string.format('%q', basePath))
	local pipe2 = io.popen(cmd)
	if not pipe2 then
		H.printf("[neutrino-mediathek] collectRecordingMeta: ls failed for %s", tostring(basePath))
		return false
	end
	for entry in pipe2:lines() do
		if entry ~= '.' and entry ~= '..' and entry ~= 'lost+found' then
			local fullPath = joinPath(basePath, entry)
			if directoryExists(fullPath) then
				collectRecordingMeta(fullPath, out)
			elseif isRecordingPath(entry) then
				local size, mtime = getFileAttributes(fullPath)
				if size and mtime then
					table.insert(out, {path=fullPath, size=size, mtime=mtime})
				end
			end
		end
	end
	pipe2:close()
	H.printf("[neutrino-mediathek] collectRecordingMeta: fallback entries=%d", #out)
	return (#out > 0)
end

collectRecordingMetaIterative = function(basePath, out, progress)
	if not directoryExists(basePath) then
		H.printf("[neutrino-mediathek] collectRecordingMetaIterative: basePath missing %s", tostring(basePath))
		return 0
	end

	local usePrintf = findSupportsPrintf()
	local dirs = { basePath }
	local dirIndex = 1
	local processedDirs = 0
	local totalDirs = 1

	local function updateProgress(currentDir)
		if progress then
			local max = (totalDirs > 0) and totalDirs or 1
			progress:update(processedDirs, max, string.format(l.localRecordingsScanningDir or l.localRecordingsScanning, currentDir or '', processedDirs, max))
		end
	end

	while dirIndex <= #dirs do
		local currentDir = dirs[dirIndex]
		dirIndex = dirIndex + 1
		processedDirs = processedDirs + 1

		local quotedDir = string.format('%q', currentDir)
		local fileCmd
		if usePrintf then
			fileCmd = string.format([[
				find %s -maxdepth 1 -type f \
					\( -iname '*.ts' -o -iname '*.mp4' -o -iname '*.mkv' \) \
					-printf '%%p|%%s|%%T@\\n' 2>/dev/null
			]], quotedDir)
		else
			fileCmd = string.format([[
				find %s -maxdepth 1 -type f \
					\( -iname '*.ts' -o -iname '*.mp4' -o -iname '*.mkv' \) \
					-print 2>/dev/null
			]], quotedDir)
		end

		local pipe = io.popen(fileCmd)
		if pipe then
			for line in pipe:lines() do
				local meta = nil
				if usePrintf then
					meta = parseFindLine(line)
				else
					if line and line ~= '' then
						local size, mtime = getFileAttributes(line)
						if size and mtime then
							meta = {path=line, size=size, mtime=mtime}
						end
					end
				end
				if meta and meta.path then
					table.insert(out, meta)
				end
			end
			pipe:close()
		end

		local subdirCmd = string.format([[
			find %s -maxdepth 1 -mindepth 1 -type d ! -name 'lost+found' -print 2>/dev/null
		]], quotedDir)
		local subdirPipe = io.popen(subdirCmd)
		if subdirPipe then
			for subdir in subdirPipe:lines() do
				if not isBlacklistedDir(subdir) then
					totalDirs = totalDirs + 1
					table.insert(dirs, subdir)
				else
					H.printf("[neutrino-mediathek] collectRecordingMetaIterative: skip blacklisted dir %s", tostring(subdir))
				end
			end
			subdirPipe:close()
		end

		updateProgress(currentDir)
	end

	H.printf("[neutrino-mediathek] collectRecordingMetaIterative: scanned %d directories, entries=%d", processedDirs, #out)
	return processedDirs
end

collectTsFilesRecursive = function(basePath, out)
	if not directoryExists(basePath) then
		return
	end

	-- Fast path: one find call with stat output
	local findCmd = string.format([[
		find %s -path '*/lost+found' -prune -o -type f \
			\( -iname '*.ts' -o -iname '*.mp4' -o -iname '*.mkv' \) \
			-printf '%%p|%%s|%%T@\\n' 2>/dev/null
	]], string.format('%q', basePath))
	local pipe = io.popen(findCmd)
	local usedFastPath = false
	if pipe then
		for line in pipe:lines() do
			usedFastPath = true
			local meta = parseFindLine(line)
			if meta and meta.path then
				local recEntry = createLocalRecordingEntry(meta.path, meta)
				if recEntry then
					table.insert(out, recEntry)
				end
			end
		end
		pipe:close()
		if usedFastPath then
			return
		end
	end

	-- Fallback: recursive ls (slower, but works without find -printf)
	local cmd = string.format("ls -1A %s 2>/dev/null", string.format('%q', basePath))
	local pipe2 = io.popen(cmd)
	if not pipe2 then
		return
	end
	for entry in pipe2:lines() do
		if entry ~= '.' and entry ~= '..' and entry ~= 'lost+found' then
			local fullPath = joinPath(basePath, entry)
			if directoryExists(fullPath) then
				collectTsFilesRecursive(fullPath, out)
			elseif isRecordingPath(entry) then
				local recEntry = createLocalRecordingEntry(fullPath)
				if recEntry then
					table.insert(out, recEntry)
				end
			end
		end
	end
	pipe2:close()
end

function playOrDownloadVideo(playOrDownload)
	if not mtList[mtRightMenu_select] then
		return
	end
	local entry = mtList[mtRightMenu_select]
	local flag_max = false
	local flag_normal = false
	local flag_min = false
	if (entry.url_hd ~= '') then
		flag_max = true end
	if (entry.url ~= '') then
		flag_normal = true end
	if (entry.url_small ~= '') then
		flag_min = true end

	if entry.isLocalRecording then
		if playOrDownload ~= true then
			messagebox.exec{title=pluginName, text=l.localRecordingsDownloadBlocked, buttons={'ok'}}
			return
		end
		if not fileExists(entry.url) then
			messagebox.exec{title=pluginName, text=string.format(l.localRecordingsMissingFile, entry.url or ''), buttons={'ok'}}
			return
		end
	end

	local quality = ''
	if (playOrDownload == true) then
		quality = conf.streamQuality
	else
		quality = conf.downloadQuality
	end
	local url = ''
	-- conf=max: 1. max, 2. normal, 3. min
	if (quality == 'max') then
		if (flag_max == true) then
			url = entry.url_hd
		elseif (flag_normal == true) then
			url = entry.url
		else
			url = entry.url_small
		end
	-- conf=min: 1. min, 2. normal, 3. max
	elseif (quality == 'min') then
		if (flag_min == true) then
			url = entry.url_small
		elseif (flag_normal == true) then
			url = entry.url
		else
			url = entry.url_hd
		end
	-- conf=normal: 1. normal, 2. max, 3. min
	else
		if (flag_normal == true) then
			url = entry.url
		elseif (flag_max == true) then
			url = entry.url_hd
		else
			url = entry.url_small
		end
	end

	local screen = saveFullScreen()
	hideMtWindow()
	if (playOrDownload == true) then
		playMovie(url, entry.title, entry.theme, url, true)
	else
		downloadMovie(url, entry.channel, entry.title, entry.description, entry.theme, entry.duration, entry.date, entry.time)
	end
	restoreFullScreen(screen, true)
end

function paint_mtItemLine(count)
	_item_x = mtRightMenu_x + 8
	_itemLine_y = itemLine_y + subMenuHight*count
	local bgCol  = 0
	local txtCol = 0
	local select
	if (count == mtRightMenu_select) then select=true else select=false end

	if (select == true) then
		txtCol = COL.MENUCONTENTSELECTED_TEXT
		bgCol  = COL.MENUCONTENTSELECTED_PLUS_0
	elseif ((count % 2) == 0) then
		txtCol = COL.MENUCONTENTDARK_TEXT
		bgCol  = COL.MENUCONTENTDARK_PLUS_0
	else
		txtCol = COL.MENUCONTENT_TEXT
		bgCol  = COL.MENUCONTENT_PLUS_0
	end
	N:PaintBox(rightItem_x, _itemLine_y, rightItem_w, subMenuHight, bgCol)

	local function paintItem(vH, txt, center)
		local _x = 0
		if (center == 0) then _x=6 end
		local w = math.floor(((rightItem_w / 100) * vH))
		if (vH > 20) then txt = adjustStringLen(txt, w-_x*2, fontLeftMenu1) end
		N:RenderString(useDynFont, fontLeftMenu1, txt, _item_x+_x, _itemLine_y+subMenuHight, txtCol, w, subMenuHight, center)
		_item_x = _item_x + w
	end

	local function paintGeoIndicator(entry)
		local vH = 5
		local w = math.floor(((rightItem_w / 100) * vH))
		if (entry.geo ~= nil and entry.geo ~= '') then
			if geoIcon ~= nil then
				local size = math.min(w-4, subMenuHight-4)
				local ix = _item_x + math.floor((w - size)/2)
				local iy = _itemLine_y + math.floor((subMenuHight - size)/2)
				N:DisplayImage(geoIcon, ix, iy, size, size, 1)
			else
				local txt = 'X'
				N:RenderString(useDynFont, fontLeftMenu1, txt, _item_x, _itemLine_y+subMenuHight, txtCol, w, subMenuHight, 1)
			end
		end
		_item_x = _item_x + w
	end

	if (count <= #mtList) then
		if localRecordingsMode then
			paintItem(34,	mtList[count].theme,	0)
			paintItem(40,	mtList[count].title,	0)
			paintItem(12,	mtList[count].date,	1)
			paintItem(14,	mtList[count].duration,	1)
		else
			paintItem(29,	mtList[count].theme,	0)
			paintItem(40,	mtList[count].title,	0)
			paintItem(11,	mtList[count].date,	1)
			paintItem(6,	mtList[count].time,	1)
			paintItem(9,	mtList[count].duration,	1)
		end
		if not localRecordingsMode then
			paintGeoIndicator(mtList[count])
		end
	end
end

function paintMtRightMenu()
	local bg_col		= COL.MENUCONTENT_PLUS_0
	local frameColor	= COL.FRAME_PLUS_0
	local textColor		= COL.MENUCONTENT_TEXT

	G.paintSimpleFrame(mtRightMenu_x, mtMenu_y, mtRightMenu_w, mtMenu_h, frameColor, 0)

	local x		= mtRightMenu_x + 8
	local y		= mtMenu_y+subMenuTop
	rightItem_w	= mtRightMenu_w-subMenuLeft*2
	local item_x	= x
	rightItem_x	= x

	local function paintHeadLine()
		local function paintHead(vH, txt)
			local paint = true
			if (vH < 0) then
				vH = math.abs(vH)
				paint = false
			end
			local w = math.floor(((rightItem_w / 100) * vH))
			N:RenderString(useDynFont, fontLeftMenu1, txt, item_x, y+subMenuHight, textColor, w, subMenuHight, 1)
			item_x = item_x + w
			if (paint == true) then
				N:paintVLine(item_x, y, subMenuHight, frameColor)
			end
		end
		
		G.paintSimpleFrame(x, y, rightItem_w, subMenuHight, frameColor, 0)
		if localRecordingsMode then
			paintHead(34,	l.headerTitle)
			paintHead(40,	l.localRecordingsHeaderPath)
			paintHead(12,	l.headerDate)
			paintHead(14,	l.headerDuration)
		else
			paintHead(29,	l.headerTheme)
			paintHead(40,	l.headerTitle)
			paintHead(11,	l.headerDate)
			paintHead(6,	l.headerTime)
			paintHead(9,	l.headerDuration)
		end
		if not localRecordingsMode then
			paintHead(-5,	l.headerGeo)
		end
	end

	local function bufferEntries()
		local el = {}
		local channel = conf.channel
		el['channel'] = channel

		local timeMode = timeMode_normal
		if (conf.seeFuturePrograms == 'on') then
			timeMode = timeMode_future
		end
		el['timeMode'] = timeMode

		local period = 0
		if (conf.seePeriod == 'all') then
			period = -1
		else
			period = tonumber(conf.seePeriod)
			if (period == nil) then
				period = 7
				conf.seePeriod = period
			end
		end
		el['epoch'] = period

		local minDuration = conf.seeMinimumDuration * 60
		el['duration'] = minDuration

		local refTime = 0
		el['refTime'] = refTime

		local start = 0
		local limit = 1000

		local j = 1
		mtBuffer = {}
		local actentries = 0
		local maxentries = 999999
		local noDataOverall = false
		local progress = createProgressWindow(l.searchTitleInfoMsg)

		while (actentries < maxentries) do
			local displayStart = start
			local sendData = getSendDataHead(queryMode_listVideos)
			el['limit'] = limit
			el['start'] = start
			sendData['data'] = {}
			sendData['data'] = el
			local post = J:encode(sendData)

			local dataFile = createCacheFileName(post, 'json')
			post = C:setUriData('data1', post)
			local s, err
			for _, apiUrl in ipairs(buildApiUrls(actionCmd_sendPostData)) do
				s, err = getJsonData2(apiUrl, dataFile, post, queryMode_listVideos)
				if s then break end
			end
			if not s then
				if progress then progress:close() end
				messagebox.exec{title=pluginName, text=l.networkError, buttons={'ok'}}
				return false
			end
--	H.printf("\nretData:\n%s\n", tostring(s))

				local j_table = {}
				j_table, err = decodeJson(s)
				if (j_table == nil) then
					if progress then progress:close() end
					messagebox.exec{title=pluginName, text=l.jsonError, buttons={'ok'}}
					os.execute('rm -f ' .. dataFile)
					return false
				end
				local noData = false
				if checkJsonError(j_table) == false then
					os.execute('rm -f ' .. dataFile)
					if (j_table.err ~= 2) then
						if progress then progress:close() end
						return false
					end
					noData = true
				end

				if (noData == true) then
					noDataOverall = true
					maxentries = 0
				else
					for i=1, #j_table.entry do
						if matchesSearchFilters(j_table.entry[i]) then
							local entry = buildEntry(j_table.entry[i])
							if entryMatchesFilters(entry) then
								mtBuffer[j] = entry
								j = j + 1
							end
						end
					end
					start = start + limit
					maxentries = j_table.head.total
					actentries = actentries + limit
				end

				local totalentries = maxentries
				if (totalentries == 999999) then
					totalentries = l.searchTitleInfoAll
				end
				local endentries = displayStart+limit-1
				if (endentries > maxentries) then
					endentries = maxentries
				end
				if progress then
					local current = (maxentries > 0) and math.min(actentries, maxentries) or actentries
					local maxForBar = (maxentries > 0) and maxentries or math.max(current, 1)
					progress:update(current, maxForBar, string.format(l.searchTitleInfoMsg, displayStart, endentries, tostring(totalentries)))
				end
			end -- while
			if progress then progress:close() end
			j = j - 1
			if conf.hideAccessibilityHints == 'on' then
				mtBuffer = filterAccessibilityVariants(mtBuffer)
			end
			mtBuffer_list_total = #mtBuffer

		if (noDataOverall == true) or (mtBuffer_list_total <= 0) then
			mtBuffer_list_total = 1
			mtBuffer = {}
			mtBuffer[1] = {
				channel = '',
				theme = '',
				title = l.titleNotFound,
				date = '',
				time = '',
				duration = '',
				durationSec = 0,
				timestamp = 0,
				geo = '',
				description = '',
				url = '',
				url_small = '',
				url_hd = '',
				parse_m3u8 = ''
			}
		else
			sortEntries(mtBuffer)
		end

		selectionChanged = false
--		paintAnInfoBoxAndWait(string.format(l.titleRead, mtBuffer_list_total), WHERE.CENTER, 3)
	end

	itemLine_y = mtMenu_y+subMenuTop+2
	_item_x = 0
	paintHeadLine()

	local i = 1
	while (itemLine_y+subMenuHight*i < mtMenu_h+mtMenu_y-subMenuHight) do
		i = i + 1
	end
	mtRightMenu_count = i-1
	if mtRightMenu_count < 1 then
		mtRightMenu_count = 1
	end

	if (localRecordingsMode == true) then
		local total = #localRecordingsEntries
		mtRightMenu_list_total = total
		if total <= 0 then
			mtRightMenu_list_total = 1
			mtList = {}
			mtList[1] = {
				channel = '',
				theme = '',
				title = string.format(l.localRecordingsNoEntries, conf.localRecordingsPath or '-'),
				date = '',
				time = '',
				duration = '',
				durationSec = 0,
				timestamp = 0,
				geo = '',
				description = '',
				url = '',
				url_small = '',
				url_hd = '',
				parse_m3u8 = ''
			}
		else
			if mtRightMenu_list_start >= total then
				if total > mtRightMenu_count then
					mtRightMenu_list_start = total - mtRightMenu_count
				else
					mtRightMenu_list_start = 0
				end
				mtRightMenu_view_page = math.floor(mtRightMenu_list_start / mtRightMenu_count) + 1
			end
			if (#mtList > 0) then
				while (#mtList > 0) do table.remove(mtList) end
			end
			mtList = {}
			local maxBuffer = total - mtRightMenu_list_start
			if maxBuffer > mtRightMenu_count then
				maxBuffer = mtRightMenu_count
			end
			if maxBuffer < 1 then
				maxBuffer = 1
			end
			for idx=1, maxBuffer do
				local sourceIndex = mtRightMenu_list_start + idx
				if sourceIndex <= total then
					mtList[idx] = cloneEntry(localRecordingsEntries[sourceIndex])
				end
			end
		end

		for idx=1, mtRightMenu_count do
			paint_mtItemLine(idx)
		end

		if mtRightMenu_list_total <= 0 then
			mtRightMenu_list_total = 1
		end
		mtRightMenu_max_page = math.max(1, math.ceil(mtRightMenu_list_total/mtRightMenu_count))
		paintLeftInfoBox(string.format(l.menuPageOfPage, mtRightMenu_view_page, mtRightMenu_max_page))
		return
	end

	local useBuffer = requiresFullBuffer()
	if useBuffer == false then -- No dedicated theme or title selected and no advanced filter
		local el = {}
		local channel = conf.channel
		el['channel'] = channel

		local timeMode = timeMode_normal
		if (conf.seeFuturePrograms == 'on') then
			timeMode = timeMode_future
		end
		el['timeMode'] = timeMode

		local period = 0
		if (conf.seePeriod == 'all') then
			period = -1
		else
			period = tonumber(conf.seePeriod)
			if (period == nil) then
				period = 7
				conf.seePeriod = period
			end
		end
		el['epoch'] = period

		local minDuration = conf.seeMinimumDuration * 60
		el['duration'] = minDuration

		local start = mtRightMenu_list_start
		el['start'] = start

		local limit = mtRightMenu_count
		-- when filtering (z. B. Accessibility-Hints), more items help to fill the page
		if conf.hideAccessibilityHints == 'on' then
			limit = mtRightMenu_count * 2
		end
		el['limit'] = limit

		local refTime = 0
		el['refTime'] = refTime

		local sendData = getSendDataHead(queryMode_listVideos)
		sendData['data'] = {}
		sendData['data'] = el
		local post = J:encode(sendData)
	
		local cacheKey = post
		post = C:setUriData('data1', post)
		local j_table, respErr = loadJsonResponse(cacheKey, buildApiUrls(actionCmd_sendPostData), queryMode_listVideos, post)
		if not j_table then
			return false
		end
		local noData = (respErr == 'nodata') or (j_table.err == 2)

		if (noData == true) then
			mtRightMenu_list_total = 0
			mtRightMenu_max_page = 0
			if (#mtList > 1) then
				while (#mtList > 1) do table.remove(mtList) end
			end
			mtList[1] = {}
			mtList[1].channel	= ''
			mtList[1].theme		= ''
			mtList[1].title		= l.titleNotFound
			mtList[1].date		= ''
			mtList[1].time		= ''
			mtList[1].duration	= ''
			mtList[1].durationSec	= 0
			mtList[1].timestamp	= 0
			mtList[1].geo		= ''
			mtList[1].description	= ''
			mtList[1].url		= ''
			mtList[1].url_small	= ''
			mtList[1].url_hd	= ''
			mtList[1].parse_m3u8	= ''
		else
			mtRightMenu_list_total = j_table.head.total

			if (#mtList > #j_table.entry) then
				while (#mtList > #j_table.entry) do table.remove(mtList) end
			end
			for i=1, #j_table.entry do
				mtList[i] = buildEntry(j_table.entry[i])
			end
			-- Remove accessibility-marked duplicates when a normal variant exists
			if conf.hideAccessibilityHints == 'on' then
				local before = #mtList
				mtList = filterAccessibilityVariants(mtList)
				local removed = before - #mtList
				if removed > 0 then
					-- Adjust total/maximum page if we dropped entries on this page
					local remaining_estimate = 0
					if j_table.head and j_table.head.total then
						local served = mtRightMenu_list_start + before
						local total = j_table.head.total
						if served < total then
							remaining_estimate = total - served
						end
					end
					mtRightMenu_list_total = mtRightMenu_list_start + #mtList + remaining_estimate
				end
			end
		end
	else -- Use buffered list (search results or advanced filters)
		if (selectionChanged == true) then
			bufferEntries()
		end
		mtRightMenu_list_total = mtBuffer_list_total

		if mtRightMenu_list_total <= 0 then
			mtRightMenu_list_total = 1
		end

		if mtRightMenu_list_start >= mtRightMenu_list_total then
			if mtRightMenu_list_total > mtRightMenu_count then
				mtRightMenu_list_start = mtRightMenu_list_total - mtRightMenu_count
			else
				mtRightMenu_list_start = 0
			end
			mtRightMenu_view_page = math.floor(mtRightMenu_list_start / mtRightMenu_count) + 1
		end

		if (#mtList > 0) then
			while (#mtList > 0) do table.remove(mtList) end
		end
		mtList = {}
		local maxBuffer = mtRightMenu_count
		local remaining = mtBuffer_list_total - mtRightMenu_list_start
		if remaining < maxBuffer then
			maxBuffer = remaining
		end
		if maxBuffer < 1 then
			maxBuffer = 1
		end
		for i=1, maxBuffer do
			local sourceIndex = mtRightMenu_list_start + i
			if sourceIndex <= mtBuffer_list_total then
				mtList[i] = cloneEntry(mtBuffer[sourceIndex])
			end
		end
	end -- Either with theme or title selected or not

	for i=1, mtRightMenu_count do
		paint_mtItemLine(i)
	end
	-- TODO: parse_m3u8 is propagated but currently unused; if no longer needed, clean up.

	mtRightMenu_max_page = math.ceil(mtRightMenu_list_total/mtRightMenu_count)
	paintLeftInfoBox(string.format(l.menuPageOfPage, mtRightMenu_view_page, mtRightMenu_max_page))
end

function paintLeftInfoBox(txt)
G.paintSimpleFrame(leftInfoBox_x, leftInfoBox_y, leftInfoBox_w, leftInfoBox_h, COL.FRAME_PLUS_0, COL.MENUCONTENT_PLUS_1)
	N:RenderString(useDynFont, fontLeftMenu2, txt, leftInfoBox_x, leftInfoBox_y+subMenuHight, COL.MENUCONTENT_TEXT, leftInfoBox_w, subMenuHight, 1)
end

function paintMtLeftMenu()
	updateLocalRecordingsMenuEntry()
	local frameColor	= COL.FRAME_PLUS_0
	local textColor		= COL.MENUCONTENT_TEXT

	local txtCol = COL.MENUCONTENT_TEXT
	local bgCol  = COL.MENUCONTENT_PLUS_0

	buttonCol_w, buttonCol_h = N:GetSize(btnBlue)	-- any color is good

	-- left frame
	G.paintSimpleFrame(mtLeftMenu_x, mtMenu_y, mtLeftMenu_w, mtMenu_h, frameColor, 0)

	-- infobox
	leftInfoBox_x = mtLeftMenu_x+subMenuLeft
	leftInfoBox_y = mtMenu_y+mtMenu_h-subMenuHight-subMenuLeft
	leftInfoBox_w = mtLeftMenu_w-subMenuLeft*2
	leftInfoBox_h = subMenuHight
	paintLeftInfoBox('')

	local y = 0
	local buttonCol_x = 0
	local buttonCol_y = 0

	local function paintLeftItem(txt1, txt2, btn, enabled)
		local icon = resolveIconRef(btn) or btnBlue
		if (enabled == true) then
			txtCol = COL.MENUCONTENT_TEXT
			bgCol  = COL.MENUCONTENT_PLUS_0
		else
			txtCol = COL.MENUCONTENTINACTIVE_TEXT
			bgCol  = COL.MENUCONTENTINACTIVE
		end
		G.paintSimpleFrame(mtLeftMenu_x+subMenuLeft, y, mtLeftMenu_w-subMenuLeft*2, subMenuHight, frameColor, bgCol)
		N:paintVLine(mtLeftMenu_x+subMenuLeft+subMenuHight, y, subMenuHight, frameColor)
		N:RenderString(useDynFont, fontLeftMenu1, txt1, math.floor(mtLeftMenu_x+subMenuLeft+subMenuHight+subMenuHight/3), y+subMenuHight, txtCol, mtLeftMenu_w-subMenuHight-subMenuLeft*2, subMenuHight, 0)

		buttonCol_x = math.floor(mtLeftMenu_x+subMenuLeft+(subMenuHight-buttonCol_w)/2)
		buttonCol_y = y+math.floor((subMenuHight-buttonCol_h)/2)
		N:DisplayImage(icon, buttonCol_x, buttonCol_y, buttonCol_w, buttonCol_h, 1)

		y = y + subMenuHight
		local crCount = 0
		for i=1, #txt2 do
			if string.sub(txt2, i, i) == '\n' then
				crCount = crCount + 1
			end
		end
--		paintAnInfoBoxAndWait("CRs: " .. crCount, WHERE.CENTER, 3)
		if crCount == 0 then
			G.paintSimpleFrame(mtLeftMenu_x+subMenuLeft, y, mtLeftMenu_w-subMenuLeft*2, subMenuHight, frameColor, bgCol)
			N:RenderString(useDynFont, fontLeftMenu2, txt2, mtLeftMenu_x+subMenuLeft, y+subMenuHight, txtCol, mtLeftMenu_w-subMenuLeft*2, subMenuHight, 1)
		else
			crCount = crCount + 1
			txt2 = txt2 .. '\n'
			G.paintSimpleFrame(mtLeftMenu_x+subMenuLeft, y, mtLeftMenu_w-subMenuLeft*2, crCount*subMenuHight, frameColor, bgCol)
			for i=1, crCount do
				local s, e = string.find(txt2, '\n')
--				paintAnInfoBoxAndWait("s: " .. s .. " e: " .. e, WHERE.CENTER, 3)
				if s ~= nil then
					local txt = string.sub(txt2, 1, s-1)
					txt2 = string.sub(txt2, e+1)
--					paintAnInfoBoxAndWait("Teil: " .. txt, WHERE.CENTER, 3)
					N:RenderString(useDynFont, fontLeftMenu2, txt, mtLeftMenu_x+subMenuLeft, y+subMenuHight, txtCol, mtLeftMenu_w-subMenuLeft*2, subMenuHight, 0)
					y = y + subMenuHight
				end
			end
		end
	end

	-- items
	local i = 0
	y = mtMenu_y+subMenuTop
	for i=1, #leftMenuEntry do
		if (leftMenuEntry[i][4] == true) then
			paintLeftItem(leftMenuEntry[i][1], leftMenuEntry[i][2], leftMenuEntry[i][3], leftMenuEntry[i][5])
			y = y + subMenuHight + subMenuSpace
		end
	end
end

function paintMtWindow(menuOnly)
	if (menuOnly == false) then
		h_mtWindow:paint{do_save_bg=true}
	end

	local hh	= h_mtWindow:headerHeight()
	local fh	= h_mtWindow:footerHeight()
	mtMenu_y	= SCREEN.OFF_Y + hh + 14
	mtMenu_h	= SCREEN.END_Y - mtMenu_y - hh - fh + 18

	paintMtLeftMenu()
	paintMtRightMenu()
end

function hideMtWindow()
	h_mtWindow:hide()
	N:PaintBox(0, 0, SCREEN.X_RES, SCREEN.Y_RES, COL.BACKGROUND)
end

function newMtWindow()
	if h_mtWindow == nil then
		local x = SCREEN.OFF_X
		local y = SCREEN.OFF_Y
		local w = SCREEN.END_X - x
		local h = SCREEN.END_Y - y

		local transp = false
		local bgCol = COL.MENUCONTENT_PLUS_0
		if (transp == true) then
			bgCol = bit32.band(0x00FFFFFF, bgCol)
			bgCol = bit32.bor(0xA0000000, bgCol)
		end
		h_mtWindow = cwindow.new{x=x, y=y, dx=w, dy=h, color_body=bgCol, show_footer=false, name=pluginName .. ' - v' .. pluginVersion, icon=pluginIcon}
	end
	paintMtWindow(false)
end

function formatTitle(allTitles, title)
	local space_x = math.floor(N:scale2Res(6))
	local frame_w = leftInfoBox_w - 2*space_x
	local f_title = l.formatAllTitles
	if allTitles == 'off' then
		f_title = title
		if conf.partialTitle == 'on' then f_title = '... ' .. f_title .. ' ...' end
	end
	f_title = adjustStringLen(f_title, frame_w-6, fontLeftMenu2)
	return f_title
end

function formatTheme(allThemes, theme)
	local space_x = math.floor(N:scale2Res(6))
	local frame_w = leftInfoBox_w - 2*space_x
	local f_theme = l.formatAllThemes
	if allThemes == 'off' then
		f_theme = theme
	end
	f_theme = adjustStringLen(f_theme, frame_w-6, fontLeftMenu2)
	return f_theme
end

function formatseePeriod()
	local period = ''
	local s = '- '
	if (conf.seeFuturePrograms == 'on') then
		s = '+/- '
	end
	if (conf.seePeriod == 'all') then
		period = l.formatSeePeriodAll
	elseif (conf.seePeriod == '1') then
		period = s .. l.formatSeePeriod1Day
	else
		period = s .. conf.seePeriod .. ' ' .. l.formatSeePeriodDays
	end
	return period
end

function formatMinDuration(duration)
	return tostring(duration) .. ' ' .. l.formatDurationMin
end

sortModeLabels = {
	date_desc = function() return l.menuSortDateDesc end,
	date_asc = function() return l.menuSortDateAsc end,
	title_asc = function() return l.menuSortTitleAsc end,
	title_desc = function() return l.menuSortTitleDesc end,
	duration_desc = function() return l.menuSortDurationDesc end,
	duration_asc = function() return l.menuSortDurationAsc end,
}

sortModeOrder = {
	'date_desc',
	'date_asc',
	'title_asc',
	'title_desc',
	'duration_desc',
	'duration_asc'
}

geoModeLabels = {
	all = function() return l.geoFilterAll end,
	no_geo = function() return l.geoFilterNoGeo end,
	only_geo = function() return l.geoFilterOnlyGeo end,
}

geoModeOrder = {'all', 'no_geo', 'only_geo'}

qualityModeLabels = {
	all = function() return l.qualityFilterAll end,
	require_hd = function() return l.qualityFilterHD end,
	require_sd = function() return l.qualityFilterSD end,
}

qualityModeOrder = {'all', 'require_hd', 'require_sd'}

function formatSortMode()
	local fn = sortModeLabels[conf.sortMode]
	if fn then return fn() end
	return l.menuSortDateDesc
end

function formatGeoMode()
	local fn = geoModeLabels[conf.geoMode]
	if fn then return fn() end
	return l.geoFilterAll
end

function formatQualityMode()
	local fn = qualityModeLabels[conf.qualityFilter]
	if fn then return fn() end
	return l.qualityFilterAll
end

buildEntry = function(apiEntry)
	return {
		channel = apiEntry.channel,
		theme = apiEntry.theme,
		title = apiEntry.title,
		date = os.date(l.formatDate, apiEntry.date_unix),
		time = os.date(l.formatTime, apiEntry.date_unix),
		duration = formatDuration(apiEntry.duration),
		durationSec = apiEntry.duration,
		timestamp = apiEntry.date_unix or 0,
		geo = apiEntry.geo or '',
		description = apiEntry.description or '',
		url = apiEntry.url or '',
		url_small = apiEntry.url_small or '',
		url_hd = apiEntry.url_hd or '',
		parse_m3u8 = apiEntry.parse_m3u8
	}
end

cloneEntry = function(src)
	if not src then return nil end
	return {
		channel = src.channel,
		theme = src.theme,
		title = src.title,
		date = src.date,
		time = src.time,
		duration = src.duration,
		durationSec = src.durationSec,
		timestamp = src.timestamp,
		geo = src.geo,
		description = src.description,
		url = src.url,
		url_small = src.url_small,
		url_hd = src.url_hd,
		parse_m3u8 = src.parse_m3u8,
		isLocalRecording = src.isLocalRecording,
		fileSize = src.fileSize,
		fileMtime = src.fileMtime
	}
end

rebuildLocalRecordingsEntries = function()
	local minDurationSec = (conf.seeMinimumDuration or 0) * 60
	local filtered = {}
	for _, entry in ipairs(localRecordingsRawEntries) do
		local durationOk = (minDurationSec <= 0) or ((entry.durationSec or 0) >= minDurationSec)
		if durationOk and matchesSearchFilters(entry) then
			local copy = cloneEntry(entry)
			if copy then
				copy.isLocalRecording = true
				table.insert(filtered, copy)
			end
		end
	end
	sortEntries(filtered)
	localRecordingsEntries = filtered
	localRecordingsActive = (#localRecordingsEntries > 0)
end

saveLocalRecordingsCache = function(entries)
	if not entries then return end
	local primaryCacheFile, fallbackCacheFile = getCachePaths()
	local payload = {
		version = 1,
		path = conf.localRecordingsPath,
		scanTime = os.time(),
		entries = entries
	}
	local ok, encoded = pcall(function() return J:encode(payload) end)
	if not ok or not encoded then
		H.printf("[neutrino-mediathek] failed to encode local recordings cache: %s", tostring(encoded))
		return
	end

	local function tryWrite(path)
		local dir = path:match("(.+)/[^/]+$")
		if dir and dir ~= '' then
			os.execute(string.format("mkdir -p %q", dir))
		end
		local fh = io.open(path, 'w')
		if not fh then
			return false
		end
		fh:write(encoded)
		fh:close()
		return true
	end

	if tryWrite(primaryCacheFile) then
		H.printf("[neutrino-mediathek] wrote local recordings cache to %s (%d entries)", primaryCacheFile, #entries)
		return
	end
	if tryWrite(fallbackCacheFile) then
		H.printf("[neutrino-mediathek] wrote local recordings cache to %s (%d entries)", fallbackCacheFile, #entries)
		return
	end
	H.printf("[neutrino-mediathek] failed to write local recordings cache to %s and %s", primaryCacheFile, fallbackCacheFile)
end

loadCachedLocalRecordings = function()
	local primaryCacheFile, fallbackCacheFile = getCachePaths()
	local primaryCacheFile, fallbackCacheFile = getCachePaths()
	local paths = { primaryCacheFile, fallbackCacheFile }
	for _, path in ipairs(paths) do
		local fh = io.open(path, 'r')
		if fh then
			local content = fh:read('*a')
			fh:close()
			if content and content ~= '' then
				local ok, data = pcall(function() return J:decode(content) end)
				if ok and type(data) == 'table' and data.version == 1 and data.path == conf.localRecordingsPath and type(data.entries) == 'table' then
					local entries = {}
					for _, entry in ipairs(data.entries) do
						if type(entry) == 'table' and entry.url then
							entry.isLocalRecording = true
							table.insert(entries, entry)
						end
					end
					if #entries > 0 then
						localRecordingsRawEntries = entries
						localRecordingsLastPath = data.path
						rebuildLocalRecordingsEntries()
						mtRightMenu_list_start = 0
						mtRightMenu_view_page = 1
						mtRightMenu_select = 1
						H.printf("[neutrino-mediathek] loaded local recordings cache from %s (%d entries)", path, #entries)
						return true
					end
				end
			end
		end
	end
	return false
end

function getLocalRecordingsStats()
	local stats = {
		enabled = (conf.localRecordingsEnabled == 'on'),
		path = conf.localRecordingsPath or '',
		activeEntries = #localRecordingsEntries,
		cachedEntries = 0,
		cachePath = nil,
		cacheSize = 0,
		cacheSizeHuman = '0 B',
		cacheMtime = nil
	}
	local primaryCacheFile, fallbackCacheFile = getCachePaths()
	local paths = { primaryCacheFile, fallbackCacheFile }
	for _, path in ipairs(paths) do
		local size, mtime = getFileAttributes(path)
		if size and size > 0 then
			stats.cachePath = path
			stats.cacheSize = size
			stats.cacheSizeHuman = humanFileSize(size)
			stats.cacheMtime = mtime
			local fh = io.open(path, 'r')
			if fh then
				local content = fh:read('*a')
				fh:close()
				if content and content ~= '' then
					local ok, data = pcall(function() return J:decode(content) end)
					if ok and type(data) == 'table' and type(data.entries) == 'table' then
						stats.cachedEntries = #data.entries
					end
				end
			end
			break
		end
	end
	return stats
end

function localRecordingsEntryEnabled()
	if localRecordingsMode then
		return true
	end
	if conf.localRecordingsEnabled ~= 'on' then
		return false
	end
	return directoryExists(conf.localRecordingsPath)
end

function formatLocalRecordingsState()
	if localRecordingsMode then
		return l.localRecordingsStateActive
	end
	if conf.localRecordingsEnabled ~= 'on' then
		return l.localRecordingsDisabled
	end
	if not directoryExists(conf.localRecordingsPath) then
		return string.format(l.localRecordingsPathMissing, conf.localRecordingsPath or '-')
	end
	return l.localRecordingsStateIdle
end

function updateLocalRecordingsMenuEntry()
	if not leftMenuEntry or not localRecordingsMenuIndex then
		return
	end
	local entry = leftMenuEntry[localRecordingsMenuIndex]
	if not entry then
		return
	end
	entry[2] = formatLocalRecordingsState()
	entry[5] = localRecordingsEntryEnabled()
end

function ensureLocalRecordingsReady(showWarning)
	if conf.localRecordingsEnabled ~= 'on' then
		if showWarning then
			messagebox.exec{title=pluginName, text=l.localRecordingsDisabled, buttons={'ok'}}
		end
		return false
	end
	local path = conf.localRecordingsPath or ''
	if not directoryExists(path) then
		if showWarning then
			messagebox.exec{title=pluginName, text=string.format(l.localRecordingsPathMissing, path), buttons={'ok'}}
		end
		return false
	end
	return true
end

function scanLocalRecordings()
	local path = conf.localRecordingsPath or ''
	local progress = createProgressWindow(l.localRecordingsScanning)
	if progress then progress:update(0, 1, l.localRecordingsScanning) end
	H.printf("[neutrino-mediathek] scanLocalRecordings: path=%s", tostring(path))
	if not directoryExists(path) then
		if progress then progress:close() end
		return false, string.format(l.localRecordingsPathMissing, path)
	end

	local metas = {}
	local scannedDirs = collectRecordingMetaIterative(path, metas, progress) or 0
	H.printf("[neutrino-mediathek] scanLocalRecordings: scanned %d dirs, collected %d candidates", scannedDirs, #metas)
	if #metas == 0 then
		if progress then progress:close() end
		H.printf("[neutrino-mediathek] scanLocalRecordings: no files found under %s", tostring(path))
		return false, string.format(l.localRecordingsNoEntries, path)
	end

	local previous = {}
	if localRecordingsLastPath == path then
		for _, entry in ipairs(localRecordingsRawEntries) do
			if entry.url then
				previous[entry.url] = entry
			end
		end
	end

	local entries = {}
	local reused = 0
	local totalWork = math.max(scannedDirs, 1) + #metas
	if progress then
		progress:update(scannedDirs, totalWork, string.format(l.localRecordingsProcessingFiles or l.localRecordingsScanning, 0, #metas))
	end
	for idx, meta in ipairs(metas) do
		local cached = previous[meta.path]
		if cached and cached.fileSize == meta.size and cached.fileMtime == meta.mtime then
			local copy = cloneEntry(cached)
			if copy then
				table.insert(entries, copy)
				reused = reused + 1
			end
		else
			local recEntry = createLocalRecordingEntry(meta.path, meta)
			if recEntry then
				table.insert(entries, recEntry)
			end
		end
		if progress then
			local currentWork = scannedDirs + idx
			progress:update(currentWork, totalWork, string.format(l.localRecordingsProcessingFiles or l.localRecordingsScanning, idx, #metas))
		end
	end

	if #entries == 0 then
		if progress then progress:close() end
		return false, string.format(l.localRecordingsNoEntries, path)
	end

	H.printf("[neutrino-mediathek] local recordings: %d entries under %s (reused %d, scanned %d)", #entries, path, reused, #metas)
	localRecordingsRawEntries = entries
	localRecordingsLastPath = path
	saveLocalRecordingsCache(entries)
	rebuildLocalRecordingsEntries()
	mtRightMenu_list_start = 0
	mtRightMenu_view_page = 1
	mtRightMenu_select = 1
	if progress then progress:close() end
	return true
end

function deactivateLocalRecordings(forceReload)
	if localRecordingsActive or localRecordingsMode then
		localRecordingsActive = false
		localRecordingsEntries = {}
		localRecordingsLastPath = nil
		mtRightMenu_list_start = 0
		mtRightMenu_view_page = 1
		mtRightMenu_select = 1
		if forceReload == true then
			selectionChanged = true
		end
	end
	updateLocalRecordingsMenuEntry()
end

function refreshLocalRecordingsView(forceRescan)
	if not localRecordingsMode then
		return
	end
	local needsRescan = forceRescan ~= false
	if (not needsRescan) and (#localRecordingsRawEntries == 0) then
		needsRescan = true
	end
	if not needsRescan and #localRecordingsRawEntries > 0 then
		rebuildLocalRecordingsEntries()
		updateLocalRecordingsMenuEntry()
		paintMtLeftMenu()
		paintMtRightMenu()
		return
	end
	if not ensureLocalRecordingsReady(needsRescan) then
		updateLocalRecordingsMenuEntry()
		paintMtLeftMenu()
		return
	end
	local ok, err = scanLocalRecordings()
	if not ok then
		if needsRescan then
			messagebox.exec{title=pluginName, text=err, buttons={'ok'}}
		end
		updateLocalRecordingsMenuEntry()
		paintMtLeftMenu()
		return
	end
	updateLocalRecordingsMenuEntry()
	paintMtLeftMenu()
	paintMtRightMenu()
end

function count_active_downloads()
	local count = 0
	local command = "find /tmp -maxdepth 1 -name '.mediathek_dl_*.sh' | wc -l"
	local handle = io.popen(command)

	if handle then
		count = tonumber(handle:read("*a")) or 0
		handle:close()
	end

	return count
end

function startMediathek(useLocalRecordings)
	if useLocalRecordings == nil then
		useLocalRecordings = false
	end

	local useLocal = (useLocalRecordings == true)
	localRecordingsMode = useLocal
	localRecordingsEntries = {}
	localRecordingsMenuIndex = nil
	leftMenuEntry = {}

	if useLocal then
		local usedCache = loadCachedLocalRecordings()
		if not usedCache then
			if not ensureLocalRecordingsReady(true) then
				localRecordingsMode = false
				return false
			end
			local ok, err = scanLocalRecordings()
			if not ok then
				messagebox.exec{title=pluginName, text=err, buttons={'ok'}}
				localRecordingsMode = false
				return false
			end
		end
	else
		deactivateLocalRecordings(false)
	end

	local function fillLeftMenuEntry(e1, e2, e3, e4, e5)
		local i = #leftMenuEntry + 1
		leftMenuEntry[i]	= {}
		leftMenuEntry[i][1]	= e1
		leftMenuEntry[i][2]	= e2
		leftMenuEntry[i][3]	= e3
		leftMenuEntry[i][4]	= e4
		leftMenuEntry[i][5]	= e5
		return i
	end

	fillLeftMenuEntry(l.menuTitle,		formatTitle(conf.allTitles, conf.title),	iconRef('btnRed'),    true, true)
	fillLeftMenuEntry(l.menuChannel,	conf.channel,					iconRef('btnGreen'),  true, true)
	fillLeftMenuEntry(l.menuTheme,		formatTheme(conf.allThemes, conf.theme),	iconRef('btnYellow'), true, true)
	fillLeftMenuEntry(l.menuSeePeriod,	formatseePeriod(),				iconRef('btnBlue'),   true, true)
	fillLeftMenuEntry(l.menuMinDuration,	formatMinDuration(conf.seeMinimumDuration),	iconRef('btn1'),      true, true)
	fillLeftMenuEntry(l.menuSort,		formatSortMode(),				iconRef('btn2'),      true, true)
	fillLeftMenuEntry(l.menuGeoFilter,	formatGeoMode(),				iconRef('btn3'),      true, true)
	fillLeftMenuEntry(l.menuQualityFilter,	formatQualityMode(),				iconRef('btn4'),      true, true)
	localRecordingsMenuIndex = fillLeftMenuEntry(l.menuLocalRecordings, formatLocalRecordingsState(), iconRef('btnGreen'), true, localRecordingsEntryEnabled())

	if useLocal then
		leftMenuEntry[2][4] = false
		leftMenuEntry[3][4] = false
		leftMenuEntry[4][4] = false
		leftMenuEntry[7][4] = false
		leftMenuEntry[8][4] = false
		leftMenuEntry[localRecordingsMenuIndex][4] = true
	else
		leftMenuEntry[localRecordingsMenuIndex][4] = false
	end

	if useLocal then
		updateLocalRecordingsMenuEntry()
		selectionChanged = false
	else
		selectionChanged = true
	end

	newMtWindow()
	local topRightBox = nil

	repeat
		local msg, data = N:GetInput(500)

		if (msg == RC.down) then
			local select_old = mtRightMenu_select
			local aktSelect = (mtRightMenu_view_page - 1)*mtRightMenu_count + mtRightMenu_select
			if (aktSelect < mtRightMenu_list_total) then
				mtRightMenu_select = mtRightMenu_select + 1
				if (mtRightMenu_select > mtRightMenu_count) then
					if (mtRightMenu_view_page < mtRightMenu_max_page) then
						mtRightMenu_select = 1
						msg = RC.right
					else
						mtRightMenu_select = select_old
					end
				else
					paint_mtItemLine(select_old)
					paint_mtItemLine(mtRightMenu_select)
				end
			else
				mtRightMenu_select = select_old
			end
		end
		if ((msg == RC.right) or (msg == RC.page_down)) then
			if (mtRightMenu_list_total > mtRightMenu_count) then
				local old_mtRightMenu_list_start = mtRightMenu_list_start
				mtRightMenu_list_start = mtRightMenu_list_start + mtRightMenu_count
				if (mtRightMenu_list_start < mtRightMenu_list_total) then
					mtRightMenu_view_page = mtRightMenu_view_page + 1

					local aktSelect = (mtRightMenu_view_page - 1)*mtRightMenu_count + mtRightMenu_select
					if (aktSelect > mtRightMenu_list_total) then
						mtRightMenu_select = mtRightMenu_list_total-(mtRightMenu_max_page - 1)*mtRightMenu_count
					end
					paintMtRightMenu()
				else
					mtRightMenu_list_start = old_mtRightMenu_list_start
				end
			end
		end

		if (msg == RC.up) then
			local select_old = mtRightMenu_select
			mtRightMenu_select = mtRightMenu_select - 1
			if (mtRightMenu_select < 1) then
				if (mtRightMenu_view_page > 1) then
					mtRightMenu_select = mtRightMenu_count
					msg = RC.left
				else
					mtRightMenu_select = select_old
				end
			else
				paint_mtItemLine(select_old)
				paint_mtItemLine(mtRightMenu_select)
			end
		end
		if ((msg == RC.left) or (msg == RC.page_up)) then
			if (mtRightMenu_list_total > mtRightMenu_count) then
				local old_mtRightMenu_list_start = mtRightMenu_list_start
				mtRightMenu_list_start = mtRightMenu_list_start - mtRightMenu_count
				if (mtRightMenu_list_start >= 0) then
					mtRightMenu_view_page = mtRightMenu_view_page - 1
					paintMtRightMenu()
				else
					mtRightMenu_list_start = old_mtRightMenu_list_start
				end
			end
		end

		if (msg == RC.info) then
			paintMovieInfo()
		elseif (msg == RC.red) then
			titleMenu()
		elseif (msg == RC.yellow) then
			if not localRecordingsMode then
				themeMenu()
			end
		elseif (msg == RC.blue) then
			if not localRecordingsMode then
				periodOfTimeMenu()
			end
		elseif (msg == RC['1']) then
			minDurationMenu()
		elseif (msg == RC['2']) then
			sortMenu()
		elseif (msg == RC['3']) then
			if not localRecordingsMode then
				geoFilterMenu()
			end
		elseif (msg == RC['4']) then
			if not localRecordingsMode then
				qualityFilterMenu()
			end
		elseif (msg == RC.green) then
			if localRecordingsMode then
				refreshLocalRecordingsView(true)
			else
				channelMenu()
			end
		elseif (msg == RC.ok) then
			playOrDownloadVideo(true)
		elseif (msg == RC.record) then
			playOrDownloadVideo(false)
		end
		-- exit plugin
		checkKillKey(msg)

		local countDLRunning = tonumber(count_active_downloads())
		if (countDLRunning > 0) then
			G.hideInfoBox(topRightBox)
			if (countDLRunning == 1) then
				topRightBox = paintTopRightInfoBox(l.statusDLRunning1)
			else
				topRightBox = paintTopRightInfoBox(string.format(l.statusDLRunningN, countDLRunning))
			end
		else
			G.hideInfoBox(topRightBox)
		end

	until msg == RC.home or forcePluginExit == true

	localRecordingsMode = false
	deactivateLocalRecordings(false)
	return true
end
