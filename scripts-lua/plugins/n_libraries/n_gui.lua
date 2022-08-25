--[[
	GUI functions for lua
	Copyright (C) 2014-2016, Michael Liebmann 'micha-bbg'

	License: GPL

	This program is free software; you can redistribute it and/or
	modify it under the terms of the GNU General Public
	License as published by the Free Software Foundation; either
	version 2 of the License, or (at your option) any later version.

	This program is distributed in the hope that it will be useful,
	but WITHOUT ANY WARRANTY; without even the implied warranty of
	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
	General Public License for more details.

	You should have received a copy of the GNU General Public
	License along with this program; if not, write to the
	Free Software Foundation, Inc., 51 Franklin St, Fifth Floor,
	Boston, MA  02110-1301, USA.
]]

local VERSION = 20200923.01

--[[
load the modul:
---------------
local gui = require "n_gui"

functions:
----------
modulName()
checkModulVersion(version)
paintMiniInfoBox(txt, [w], [h])
paintInfoBox(txt, [w], [h])
hideInfoBox(h)
paintFrame(x, y, w, h, f, c, [radius], [bg])
paintSimpleFrame(x, y, w, h, c, [bg])
]]

local gui = {VERSION = VERSION}
local G = gui
local bor = bit and bit.bor
	or bit32 and bit32.bor
	or load[[return function(a, b) return a | b end]]()

function G.modulName()
	return "n_gui"
end

function G.checkModulVersion(version)
	if version > VERSION then
		error(string.format("\nModul '%s' version >= %.02f is required, existing version is %.02f", G.modulName(), version, VERSION))
	end
end

function G.paintMiniInfoBox(txt, w, h)
	local dx, dy
	if not w then dx = 250 else dx = w end
	if not h then dy = 50 else dy = h end
	local x = ((SCREEN.END_X - SCREEN.OFF_X) - dx) / 2
	local y = ((SCREEN.END_Y - SCREEN.OFF_Y) - dy) / 2

	local text = COL.MENUCONTENTSELECTED_TEXT
	local body = COL.MENUCONTENTSELECTED_PLUS_0
	x = math.floor(x)
	y = math.floor(y)
	dy = math.floor(dy)
	dx = math.floor(dx)

	local ib = cwindow.new{color_body=body, x=x, y=y, dx=dx, dy=dy, has_shadow=true, shadow_mode=1, show_footer=false, show_header=false}
	if (txt ~= "") then
		ctext.new{color_text=text, color_body=body, parent=ib, x=15, y=2, dx=dx-30, dy=dy-ib:headerHeight()-4, text=txt, font_text=FONT.MENU_TITLE, mode="ALIGN_CENTER"}
	end
	ib:paint()
	return ib
end

function G.paintInfoBox(txt, w, h)
	local dx, dy
	if not w then dx = 450 else dx = w end
	if not h then dy = 120 else dy = h end
	local x = ((SCREEN.END_X - SCREEN.OFF_X) - dx) / 2
	local y = ((SCREEN.END_Y - SCREEN.OFF_Y) - dy) / 2
	x = math.floor(x)
	y = math.floor(y)
	dy = math.floor(dy)
	dx = math.floor(dx)

	local ib = cwindow.new{x=x, y=y, dx=dx, dy=dy, title="Information", icon="information", has_shadow=true, shadow_mode=1, show_footer=false}
	ctext.new{parent=ib, x=30, y=2, dx=dx-60, dy=dy-ib:headerHeight()-4, text=txt, font_text=FONT.MENU, mode="ALIGN_CENTER"}
	ib:paint()
	return ib
end

function G.hideInfoBox(h)
	if h ~= nil then
		h:hide()
		h = nil
	end
end

function G.paintFrame(x, y, w, h, f, c, radius, bg)
	if N == nil then N = n end
	if (not radius) then radius = CORNER.RADIUS_LARGE end
	if (not bg) then bg = 0 end
	x = math.floor(x)
	y = math.floor(y)
	w = math.floor(w)
	h = math.floor(h)
	if (bg > 0) then
		-- background
		N:PaintBox(x, y, w, h, bg, radius, bor(CORNER.TOP_LEFT, CORNER.TOP_RIGHT))
	end
	-- top
	N:PaintBox(x-f, y-f, w+f*2, f, c, radius, bor(CORNER.TOP_LEFT, CORNER.TOP_RIGHT))
	-- right
	N:PaintBox(x+w, y, f, h, c)
	-- bottom
	N:PaintBox(x-f, y+h, w+f*2, f, c, radius, bor(CORNER.BOTTOM_LEFT, CORNER.BOTTOM_RIGHT))
	-- left
	N:PaintBox(x-f, y, f, h, c)
end

function G.paintSimpleFrame(x, y, w, h, c, bg)
	if N == nil then N = n end
	if (not bg) then bg = 0 end
	x = math.floor(x)
	y = math.floor(y)
	w = math.floor(w)
	h = math.floor(h)
	if (bg > 0) then
		-- background
		N:PaintBox(x, y, w, h, bg)
	end
	-- top
	N:paintHLine(x, w, y, c)
	-- right
	N:paintVLine(x+w, y, h, c)
	-- bottom
	N:paintHLine(x, w, y+h, c)
	-- left
	N:paintVLine(x, y, h, c)
end

return gui
