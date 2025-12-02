-- Filtering and sorting helpers for Mediathek entries

local Filters = {}

function Filters.sortEntries(list)
	local mode = conf.sortMode
	-- remember original order for stable sorting on equal keys
	local origIndex = {}
	for i, entry in ipairs(list) do
		origIndex[entry] = i
	end

	local function cmpKey(aVal, bVal, a, b, asc)
		if aVal == bVal then
			return (origIndex[a] or 0) < (origIndex[b] or 0)
		end
		if asc then
			return aVal < bVal
		end
		return aVal > bVal
	end

	local modes = {
		date_asc      = function(a, b) return cmpKey(a.timestamp or 0, b.timestamp or 0, a, b, true) end,
		date_desc     = function(a, b) return cmpKey(a.timestamp or 0, b.timestamp or 0, a, b, false) end,
		title_asc     = function(a, b) return cmpKey((a.title or ''):lower(), (b.title or ''):lower(), a, b, true) end,
		title_desc    = function(a, b) return cmpKey((a.title or ''):lower(), (b.title or ''):lower(), a, b, false) end,
		duration_asc  = function(a, b) return cmpKey(a.durationSec or 0, b.durationSec or 0, a, b, true) end,
		duration_desc = function(a, b) return cmpKey(a.durationSec or 0, b.durationSec or 0, a, b, false) end,
	}

	local compare = modes[mode] or modes.date_desc
	table.sort(list, compare)
end

function Filters.requiresFullBuffer()
	if conf.allThemes ~= 'on' or conf.allTitles ~= 'on' then
		return true
	end
	if conf.sortMode ~= 'date_desc' then
		return true
	end
	if conf.geoMode ~= 'all' or conf.qualityFilter ~= 'all' then
		return true
	end
	return false
end

function Filters.matchesSearchFilters(apiEntry)
	if conf.allThemes ~= 'on' then
		if (apiEntry.theme or '') ~= (conf.theme or '') then
			return false
		end
	end

	if conf.allTitles == 'on' then
		return true
	end

	local needle = conf.title or ''
	local hayTitle = apiEntry.title or ''
	local hayDescr = apiEntry.description or ''

	if conf.ignoreCase == 'on' then
		needle = needle:upper()
		hayTitle = hayTitle:upper()
		hayDescr = hayDescr:upper()
	end

	if conf.partialTitle ~= 'on' then
		return hayTitle == needle
	end

	if string.find(hayTitle, needle, 1, true) ~= nil then
		return true
	end

	if conf.inDescriptionToo == 'on' and string.find(hayDescr, needle, 1, true) ~= nil then
		return true
	end

	return false
end

function Filters.entryMatchesFilters(entry)
	if conf.hideAccessibilityHints == 'on' and isAccessibilityHintEntry(entry) then
		return false
	end
	local geo = entry.geo or ''
	if conf.geoMode == 'no_geo' and geo ~= '' then
		return false
	elseif conf.geoMode == 'only_geo' and geo == '' then
		return false
	end
	local hasHD = entry.url_hd ~= nil and entry.url_hd ~= ''
	local hasSD = entry.url ~= nil and entry.url ~= ''
	if conf.qualityFilter == 'require_hd' and not hasHD then
		return false
	elseif conf.qualityFilter == 'require_sd' and not hasSD then
		return false
	end
	return true
end

return Filters
