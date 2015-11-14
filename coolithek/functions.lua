
ret = nil -- global return value
function key_home(a)
	ret = MENU_RETURN.EXIT
	return ret
end

function key_setup(a)
	ret = MENU_RETURN.EXIT_ALL
	return ret
end

function hideMenu(menu)
	if menu ~= nil then menu:hide() end
end

function dummy()
end

