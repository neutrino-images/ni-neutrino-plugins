-- Filtering and sorting helpers for Mediathek entries

local Filters = {}

function Filters.sortEntries(list)
	local mode = conf.sortMode
	local function compare(a, b)
		if mode == 'date_asc' then
			return (a.timestamp or 0) < (b.timestamp or 0)
		elseif mode == 'title_asc' then
			return (a.title or ''):lower() < (b.title or ''):lower()
		elseif mode == 'title_desc' then
			return (a.title or ''):lower() > (b.title or ''):lower()
		elseif mode == 'duration_desc' then
			return (a.durationSec or 0) > (b.durationSec or 0)
		elseif mode == 'duration_asc' then
			return (a.durationSec or 0) < (b.durationSec or 0)
		else -- date_desc default
			return (a.timestamp or 0) > (b.timestamp or 0)
		end
	end
	-- TODO: Handling duplicate timestamps/titles could be stabilized if needed
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
