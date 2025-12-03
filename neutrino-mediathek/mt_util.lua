-- Common helper functions shared across the plugin

-- Accessibility markers (AD/UT/Originalton)
accessibilityHintKeywords = {
	-- Audiodeskription
	'audiodeskrip',
	'hoerfilm',
	'hörfilm',
	'hoerfassung',
	'hörfassung',
	'barrierefrei',
	-- Untertitel
	'untertitel',
	-- Originalton
	'o-ton',
	'oton',
	'originalton',
	-- Gebärdensprache
	'gebaerd',
	'gebard',
	'geb%C3%A4rd',
	'gebaerdensprache',
	'gebardensprache',
	'gebaerdensprach'
}

function trim(value)
	if not value then return nil end
	return (value:gsub('^%s+', ''):gsub('%s+$', ''))
end

function decodeHtmlEntities(value)
	if not value or value == '' then
		return value
	end
	-- Basic entity decoding for local metadata (EPG/XML)
	local decoded = value
	decoded = decoded:gsub('&amp;', '&')
	decoded = decoded:gsub('&lt;', '<')
	decoded = decoded:gsub('&gt;', '>')
	decoded = decoded:gsub('&quot;', '"')
	decoded = decoded:gsub('&apos;', "'")
	return decoded
end

function humanFileSize(bytes)
	if not bytes or bytes <= 0 then
		return '0 B'
	end
	local units = { 'B', 'KiB', 'MiB', 'GiB', 'TiB' }
	local idx = 1
	while bytes >= 1024 and idx < #units do
		bytes = bytes / 1024
		idx = idx + 1
	end
	return string.format('%.1f %s', bytes, units[idx])
end

function formatDuration(d)
	if not d then return '' end
	local h = math.floor(d/3600)
	d = d - h*3600
	local m = math.floor(d/60)
	d = d - m*60
	local s = d
	return string.format('%02d:%02d:%02d', h, m, s)
end

function parseDurationString(value)
	if not value then
		return nil
	end
	local hours, minutes, seconds = value:match('^(%d+):(%d+):(%d+)$')
	if hours and minutes and seconds then
		return tonumber(hours) * 3600 + tonumber(minutes) * 60 + tonumber(seconds)
	end
	local numeric = tonumber(value)
	if numeric then
		-- recordings created via download.lua store minutes in <length>
		if numeric > 1000 then
			return numeric
		end
		return numeric * 60
	end
	return nil
end

function parseThemeFromInfo(info)
	if not info then
		return nil
	end
	local theme = info:match('[Tt]hema:%s*(.-)\n')
	if not theme then
		theme = info:match('[Tt]heme:%s*(.-)\n')
	end
	if theme then
		return trim(theme)
	end
	return nil
end

function fileExists(path)
	if not path or path == '' then
		return false
	end
	local f = io.open(path, 'r')
	if f ~= nil then
		f:close()
		return true
	end
	return false
end

function directoryExists(path)
	if not path or path == '' then
		return false
	end
	local cmd = string.format("test -d %s && echo 1 || echo 0", string.format('%q', path))
	local pipe = io.popen(cmd)
	if not pipe then return false end
	local result = pipe:read('*l')
	pipe:close()
	return result == '1'
end

function getFileAttributes(path)
	if not path or path == '' then
		return nil, nil
	end
	local quoted = string.format('%q', path)

	local function try(cmd, parser)
		local pipe = io.popen(cmd)
		if not pipe then
			return nil, nil
		end
		local line = pipe:read('*l')
		pipe:close()
		if not line or line == '' then
			return nil, nil
		end
		return parser(line)
	end

	-- Try multiple stat/ls variants to support GNU, BSD, and BusyBox.
	local attempts = {
		{
			cmd = string.format("stat -c '%%s %%Y' %s 2>/dev/null", quoted),
			parse = function(line)
				local size, mtime = line:match('^(%d+)%s+(%d+)$')
				if size and mtime then
					return tonumber(size), tonumber(mtime)
				end
				return nil, nil
			end
		},
		{
			cmd = string.format("stat -f '%%z %%m' %s 2>/dev/null", quoted),
			parse = function(line)
				local size, mtime = line:match('^(%d+)%s+(%d+)$')
				if size and mtime then
					return tonumber(size), tonumber(mtime)
				end
				return nil, nil
			end
		},
		{
			cmd = string.format("ls -ln --time-style=+%%s %s 2>/dev/null", quoted),
			parse = function(line)
				local fields = {}
				for field in line:gmatch('%S+') do
					fields[#fields+1] = field
				end
				local size = tonumber(fields[5])
				local mtime = tonumber(fields[6])
				if size and mtime then
					return size, mtime
				end
				return nil, nil
			end
		},
		{
			cmd = string.format("ls -ln --full-time %s 2>/dev/null", quoted),
			parse = function(line)
				local fields = {}
				for field in line:gmatch('%S+') do
					fields[#fields+1] = field
				end
				local size = tonumber(fields[5])
				local date = fields[6]
				local timeStr = fields[7]
				if not (size and date and timeStr) then
					return nil, nil
				end
				local y, m, d = date:match('^(%d+)%-(%d+)%-(%d+)$')
				local hh, mi, ss = timeStr:match('^(%d+):(%d+):(%d+)')
				if not (hh and mi and ss) then
					hh, mi, ss = timeStr:match('^(%d+):(%d+):(%d+)%.')
				end
				if not (y and m and d and hh and mi and ss) then
					return nil, nil
				end
				local mtime = os.time{
					year = tonumber(y),
					month = tonumber(m),
					day = tonumber(d),
					hour = tonumber(hh),
					min = tonumber(mi),
					sec = tonumber(ss)
				}
				if size and mtime then
					return size, mtime
				end
				return nil, nil
			end
		}
	}

	for _, attempt in ipairs(attempts) do
		local size, mtime = try(attempt.cmd, attempt.parse)
		if size and mtime then
			return size, mtime
		end
	end

	return nil, nil
end

function normalizeAccessibilityText(value)
	if not value then return '' end
	local trimmed = trim(value)
	if not trimmed or trimmed == '' then
		return ''
	end
	local normalized = trimmed:gsub('%s+', ' '):lower()
	normalized = normalized:gsub('ä', 'ae'):gsub('ö', 'oe'):gsub('ü', 'ue'):gsub('ß', 'ss')
	return normalized
end

function containsAccessibilityMarker(field)
	if not field or field == '' then
		return false
	end
	local lower = normalizeAccessibilityText(field)
	for _, keyword in ipairs(accessibilityHintKeywords) do
		if lower:find(keyword, 1, true) then
			return true
		end
	end
	for paren in lower:gmatch("%b()") do
		for _, keyword in ipairs(accessibilityHintKeywords) do
			if paren:find(keyword, 1, true) then
				return true
			end
		end
		if paren:find("%f[%w]ad%f[%W]") or paren:find("%f[%w]ut%f[%W]") then
			return true
		end
	end
	return false
end

function isAccessibilityHintEntry(entry)
	if not entry then return false end
	if containsAccessibilityMarker(entry.title) or containsAccessibilityMarker(entry.theme) then
		return true
	end
	if containsAccessibilityMarker(entry.description) then
		return true
	end
	return false
end

local function deriveAccessibilityBase(entry)
	local baseTitle = entry.title or ''
	-- remove parenthesized parts to align variants
	baseTitle = baseTitle:gsub("%b()", " ")
	baseTitle = normalizeAccessibilityText(baseTitle)
	baseTitle = baseTitle:gsub('%s+', ' '):gsub(' %- ', ' '):gsub(' %-', ' ')
	return string.format("%s|%s", normalizeAccessibilityText(entry.channel or ''), trim(baseTitle) or '')
end

local function parseDate(dateStr, timeStr)
	if not dateStr or dateStr == '' then
		return 0
	end
	local d, m, y = dateStr:match("^(%d%d)%.(%d%d)%.(%d%d%d%d)$")
	d, m, y = tonumber(d), tonumber(m), tonumber(y)
	if not (d and m and y) then
		return 0
	end
	local h, min = 0, 0
	if timeStr and timeStr:match("^(%d%d):(%d%d)$") then
		h, min = timeStr:match("^(%d%d):(%d%d)$")
		h, min = tonumber(h), tonumber(min)
	end
	local t = os.time({year = y, month = m, day = d, hour = h or 0, min = min or 0, sec = 0})
	return t or 0
end

function filterAccessibilityVariants(list)
	if not list or #list == 0 then
		return list
	end
	local groups = {}
	for _, entry in ipairs(list) do
		local key = deriveAccessibilityBase(entry)
		if not groups[key] then
			groups[key] = {normal = {}, marked = {}}
		end
		if isAccessibilityHintEntry(entry) then
			table.insert(groups[key].marked, entry)
		else
			table.insert(groups[key].normal, entry)
		end
	end
	local filtered = {}
	for _, g in pairs(groups) do
		if #g.normal > 0 then
			for _, e in ipairs(g.normal) do table.insert(filtered, e) end
		else
			for _, e in ipairs(g.marked) do table.insert(filtered, e) end
		end
	end
	-- Keep filtered list ordered by date/time (newest first)
	table.sort(filtered, function(a, b)
		return parseDate(a.date, a.time) > parseDate(b.date, b.time)
	end)
	return filtered
end
