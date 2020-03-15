--[[
	Tierwelt TV-App
	Vers.: 0.4
	Copyright
        (C) 2020 fritz

        Addon Description:
        The addon evaluates Videos from the Tierwelt-live.de Homepage and 
        provides the videos for playing with the neutrino media player on.

        This addon is not endorsed, certified or otherwise approved in any 
        way by Doclights GmbH.

        The plugin respects Doclights's General Terms and Conditions of Use, 
        which prohibits the publishing or making publicly available of any 
        software, app or similar which allows the livestream / videos to 
        be fully or partially definitely and permanently downloaded.

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

        Copyright (C) for the linked videos and for the Tierwelt TV -Logo by Doclights GmbH, Hamburg or the respective owners!
        Copyright (C) for the Base64 encoder/decoder function by Alex Kloss <alexthkloss@web.de>, licensed under the terms of the LGPL
]]

local json = require "json"

-- Auswahl 
local subs = {
	{'channels/8', 'BBC Earth'},
	{'channels/9', 'Die Erde von oben'},
	{'channels/10', 'Tiere beobachten'},
	{'channels/11', 'Natur genießen'},
	{'playlists/15', 'Amerika'},
	{'playlists/16', 'Südamerika'},
	{'playlists/17', 'Afrika'},
	{'playlists/18', 'Asien'},
	{'playlists/19', 'Europa'},
	{'playlists/42', 'Australien'},
	{'playlists/32', 'Weite Welt'},
	{'playlists/21', 'Tiere im Fokus'},
	{'playlists/33', 'Menschen und Tiere'},
	{'playlists/46', 'Klassiker'},
	{'playlists/24', 'Expeditionen'},
	{'playlists/45', 'Kielings Welt'},
	{'playlists/38', 'Die Erde von oben'},
	{'playlists/28', 'Kates Tierwelt'},
	{'playlists/37', 'Geschichten aus den Wäldern'},
	{'playlists/27', 'Naturfilme'},
	{'playlists/34', 'Eisige Welten'},
	{'playlists/25', 'Making of'},
	{'playlists/22', 'Die Tierärzte'},
	{'playlists/23', 'Tipps vom Tierarzt'},
	{'playlists/14', 'Raubkatzen'},
	{'playlists/26', 'Wildnis Blog'},
	{'playlists/48', '#6 Fighting Extinction'},
	{'playlists/44', 'Filmauswahl Welt'}
}

--Objekte
function script_path()
	local str = debug.getinfo(2, "S").source:sub(2)
	return str:match("(.*/)")
end

function init()
	n = neutrino();
	p = {}
	func = {}
	pmid = 0
	stream = 1
        tmpPath = "/tmp"
	tierwelt_tv = decodeImage("data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAI4AAAAYCAYAAAAswsVWAAAABGdBTUEAALGPC/xhBQAAAAlwSFlzAAAOwgAADsIBFShKgAAAABh0RVh0U29mdHdhcmUAcGFpbnQubmV0IDQuMS4xYyqcSwAAD2VJREFUaEPtWnmQXVWdvoDEhKT3t9x7XycBCwcIpTiT0dIMVhAVEDAsScjSne5+d3n9OhsBHKZUkIKaUUFmCohTM5YOBQ4IAxSLpEChnAw6AmJAEZRMFppAL+8ub+l+6S293Pm+887rvNfpLRn/GGN/Vade37Pd3zm/73znd85tpRSBopy6r2FBvWdUnJMzK2uDZmV+Zm1NlWuE1qeM6C8zpnqgo6HinA+aIh9PN4U2ePHwY9l47TXvrF+gyy7m8OeGd1YpFUes6N+5rdpAplULfFtz3ET0Ac8I3zuyvX5X2lbv82z1R25S/z3+ftq1Q1cgaV5b3Zcz29QncxtDy2VXc/hzwcufVhakjMjO/i2xwE9oAYnjJfWd7obQ5e1rz1BlNYGujfOX7laU+fJRoHtN1Vld8chdB6FOMmsOs8Tv2qpq8o0LI3uWK6fLrD8dDG+OrTmyrX7Ys6E0CZ1q0+3Gwz/raQzdIKvMCL9B+85hu+qv5OMfBV0bq5emLfUex9IfTtuhL8nskwaepS1H2ufZesa39F90NyoLZdH/f/gNtZXppHooA6XxQBrXBnGSJE9sCGX1sloZOj6v1AXLlHnyUaCjsWaFb6u/lY/HAGXNIORe39b3z5TStv5rJx6+APW/moZNPUkooa291LlhUUh2d1LAt2KfBmlcP8Hx6W95Rl2FLFIeW6uc9v4aZcG+y5QPy6xp4VrabvTxbuk8TpYwt+/5pnaXa2tvgrR5hB39TnP4E7KbY+AaUQOC4ngJLeeZ+n0yW1Ey151xQX57LBBq04pfOmqzPtgTr7uJwbKsVoaUvfAL3c0LL5KPAqh7mpuI/D6YQnJdS72xFwTo31wv0uG2WJDF+5hySH0ynwkk6U+b4b/B4K7Po14hT38+kzi5tsLpiOObejxtac/k27QHOhPaGTJ7SqCfjiNbjs4hF1txfotzyDSyFXNpaY/gfQ/RB31tYm6/J7spA3x6StrUHuTiRf/Djq1+RRYpSrq57m8HENu4UBwSR2xVrfrhrpbQjY+BDLJaGVLXVK/qbgpdJx/H4RjRp92r5/2FfCyDZ9ZdRKb7pnoX1OfbMP7HMGaIkwaV6wFxH8QvAnAkS7u9y6hemjIjUd8MNztWdItjiVVxSqG3kwNTEYcOw+r+6cDmWBBsrw+wGywRDaaBa+m3YE6/U5hfKor+bgb9Zlv1ACrzc2z393iWvjOHX6jIes+Ofm4UJCIpepN6TnZTBr+pNga7fivty7stoY/KIji7Ofq7LJgntigQh8oDEo3lkzhdtUU+LquN48A69TeHrl144/7GihUyaxwfNIVe9Larn5SPZQhuU04NViofKqZ0Ql2LSeuRRr1Lo4KEcrpIKJfNBCjb8s9JgTZnpK3o+fJxVuiK1y5zrdCkJP9jgYrttamf7IR9MqsM0ykOFPpFqsYROPd9s7JWZk+J0rllgh+f7aGS07dQ+z1ybsUvfNEbV8MgWHsa7xahgBFeLbsah2Npl2IRD6TtWIC/XyWhZRGMb9V8GC22KKE4gjx6QLZ7dvgfZDWB3buVD/WuUZYh9jE6ryyfjPZL5p2bvXHpe05YWSSzpoWfUK8tEge/B9Mt+mJZNA7H0C5Jg8i0xbEij3DPl0XK22uVeVC4Fqw0bwASzK2ubzPGYOnv+Gbtp3aXkA8nxs+PYeUGNywJOjZV1GEFPkzJDnYsDtJG5DOY5FfEM+p0bVLPk80EsIrfZP+wsc9rjo5vz8I5lr6LZYUtoVAWgOQkJFT1TbEV0C78on1Hlxm+lu1EB8BE4pBoUIyvs8+M8EPBF9xihrANwZaXOzdos4rzsM3/uBgaeFBsmT0Oxk4gw7+RNCQGiSaLBG6DLSDcbRwD63gJNSmLCuhtqlozuI0TI09UNBgDSUPiPDMyIKuNg4ztXlf7ffk4Dn+L9uje1RWzPvmUEgeTdmCyQNwx1ctQZ4SOAbEfL+71JIVrqLdkYC8Hhvb74cRX8XuYdSnRaVNdKzoBslbsYq5cxlIY565BOIH7fnA9HGRpn3Vt9Rv9wsnsS/26bKb0IhhH/Qzno5dtTbUN2WLVdVvRs2DbW2LSE3ru0MaqGua7dtSAeo8d5mTbehrtX+Y4aSfzfDO6lfWISYhzCuKa2+nsUuKQfLQ5bemvUSlk82lRJA7belak3OkSKVPbiK1siOPD/Hk9m/Q6WaS8A/VD3uucs1wiNniM6o1tUz7sbY09MrSjYCSJ4yJRwsDUvKw2jg/WVLY6rdE75KNAdmv04kxS/enxnHpAiqPEScDxW469fZ6KOCm7+mN9bXqOE4NVuAur9Lx8YzTitkTXoa8RnAg5lhd4+836ReJwfDm0waT2epb6zXxS/8H72Mc9Qz+nH6TJcbHY2htsQ3iGdjXJSBv5Lqjbw+0rC3dYTly7EO8aYAwByRerNd1SsxjE28e5Q7uUZ0Su5pxkEU+kE9pv2AcI5OEUI+7GJhKHikpboIjrcUraT/IItTL1NuZ5ZvQiKi3bzoRSxUlZmi2zy4Ct8Ry8f3/h/dqAa0YsWaQ4jeGzqfSIf/D+cjUaR+5CpQaT9l8YdOBx8ugo/B5OaqOyyjiypvr0B0boevmopBIVnxncgsDJUr9VtgfOADqFK1VO2gG/tTYmi8YxFXHgwDt5GhjGKuwz6soI59j6HioO9ub2LrNWbDtHiVOQXTjhK1QtbCvCCf622koQ5m22gxKNZpurqkW+pd6JfkZpI50IZ7bLlXdKxta2FlUknQitY30vrm+hA2DzKOrezbwiMMZmqhodiXjiEpE3XYxjqq9k0Tft5iFBZs8abkJ9hsThtgdbTJldBvoLZHyOOw2C5DHU+1dZpECxb6JacYuEYl0ls49F5tb5n+29YYkPAtBJfFkQ3LQk8D+qlDn0kKm90WdFduQ2Vn0EsvvLHhqWUIfytrZRVpkVMGGrYHD2RIiDvBd6QGyuBjjqX6A6/8wEJ/8Tyt7jiof9uW4z+inWLxJH9IMtjXmleHuZMs+z1Xs50ew3k1AbOamw63mpHnn0OzaKLT1t1ZzPIBOr8HHWhVINM65hP1Cxe+gE1B3FtvaKeKZtpvpdkP0p1s+3sX9dxBxTEUc41NL/uxgcu/YSjfnHA/T7ZJE4iGMnJQ7hWbEEFs0QVRoL6vWOdTUi1sT7RxkKuFbMH1uljBN6Urira41MWyzPwUPqhgeS+kCnVd0gixVvdeVfZ1s1x7ejb9BpvZAy1OMq2vuLL8yf8chYCsjvlzFZmRNUnA6qA0+CY9sWB2PbCylAGpDxC9r15ew6ccIrEocKgQm5h3kT4VjqGpxChkW/lvoUtxOQcq/YKhLa1SBixyAXianeys8DmNRu8R5De57tBdEs7VEqE8dEZaE9RdsYfBfuU+ggEStNSxw8/+f/hTiw9wmeqmYijtsQ0jCPvVRjzPMI4r2V3c1VZ9JOEg+Hk/uLyjwtvHjdPw7CWK9V7eu4thanltBR+WqJ3O+0hB5iOe99EJXznmCks7l2m6wya7h27Ao48YSIA4f+D/PEyQ8BHga+fjwl9HU86ou20hGlxOHqZ95EpJui54OQ7SI+svRu14peiUkbxHvGnM3hRVCzR0gGx9b29ODURAkfQp84xbWwPZ2NwPaHhaBWH8Eqvr/UrrSpr0Of1zm2uroHJzu2mZ446k8Yj9HufDIaYf7xAAr6H7NRHAKLZlcGashF4ph6HDa9wPsdLKLR0kPGtPDN8FeHecqy1LzTWH1Byoo+wPx0Y/iyTrP2OcjZvdyrMYF0WtB18+KO20qOmLMFVu7lmNATIw4CYsr+MCa1Y5MyfhKYCmWKY+g7ZXYZxnA8heNflFvTYRw/Hysco9Wfsxy/rXRCT1IfwYK5Q5xWbH2IAbHoAIBddxeIh7jIVo85eU7EDFsVxhgTMYYTj10gGhwH0N+PqHCzIQ7E4UrGjCQPbHoNC3NQnOgs7QAPHrLa9OgyIjsHeZNsqhlne82FbjwiiNO348zEvobqn/QY0e/nUY4VFYzetLR/v6Icc/8yG8BJl8JA/wSJ8zVMyhiciJhDe4KfIvi/Q0ycfN54dtlHLyInbFWTEoeAwtyBcY3QJr6T5EDezSxzWsIrsC1n5YntiDxN/cxvUCpFY4DqR9KJMSVwqrKiF4/hpNQOu5y14UWp9QujOTu6XlafkjgEtsudtBcnP4wx9vcMysU4QSpZZVrA4Q/NljgEFsoAVUYsnII9DJafYTwnq0wPrKxn85A4TGBPrjHyxW6j5kHm57bW33pwdfVdGVt9my8YgCOcE9iiiuDlHibuhIhzMKFUwYl/oBSLOMPWOkCIJ6BgT+Lvt6gUINdLe+QlJQJASRwErtMQx2uuu4iO570GCcJ9PmMWbs8PMxaw9NeKE8t3M94pBsYE/waZXqLDuc3AFh+r9jn09Sic8CqDzcHNOnxfwHTEQbsGQXTYIdWtH2N6o3iUnwm+Ff3hcRHH1u/j+4QtSLB9yDW17bJ4ZuSuqf7aCE5TmaQ20nlV5aXu5vDDzHeNkN29uuL2NALmLByQs9S9zuXKrAYxGXidjfhgeERcPupe3yTEYZwxBHXjaQYDebZIHCHlzaHlUIPH+2HL6IQAGc7jxdvNxU8VnTj+Bjeg7PrFvBP5AfMmg1AsS/P5vrHCOweKF3t456kIHL/HD4m0WXwDArFFwxLkzPqzcVS/G2MaEsGxtI1/I28UgfYTsipiRn0F3neEWy5+D5YSJ9dWVYN4aBfDAl7+8eYbYcKvZntXhlDi0WAHb8vxXmvCre8kcDeF/pI35xwbE7baI05j5dmyeGbkrqiqSbfieA2D3ZbQU15Tze3Md+Lhtlyr1oPgMyBxfCNMtTnhj46UQF6+dTdHz+yKLwrTMbJoHKyTWs8Pnep5pZNaBB3dm1gUwqQvx+pf68e1a3oT2rm8hymVWHHbjfdkLf0T3qpj+ylFDkTJWtGzmLobF0ZKtwZ+c8oY1UtZ5jctiJV+PigF83n5CJKc68TVNb6hrnbs8ArmlX42YT3e1vrx2mUkaOm7CC6U3mbtXKjVhoxdv5JjnVhnKnC+shhzZpO2hFulzJ4S7PeQUafn2iIfYeKnGWTP3r/o4LSMpd5JWe8BeaAMv2Z+ylBvAYtHsJqDbEL7Q/tVVWeKBnOYQxFd8dDKXFIb6EnyyK3+inkpI/JNSPUIZG8slSzcXcxhDmWgnPZboQ1+Qn3Xb42+zjzPjuJ4hy0qoY+lrMi9ouIc5jAZ+G+lORkgpTZWf8w3ov+Ofdt1rjj9uO8V5nAyQVH+F4iSoOq22umLAAAAAElFTkSuQmCC")
end

function add_stream(t,u,f,r)
  p[#p+1]={title=t,url=u,from=f,rubrik=r,access=stream}
end

function getdata(Url,outputfile)
	if Url == nil then return nil end
	if Curl == nil then
		Curl = curl.new()
	end
	local ret, data = Curl:download{url=Url,A="Mozilla/5.0;",followRedir=true,o=outputfile }
	if ret == CURL.OK then
		return data
	else
		return nil
	end
end

-- ####################################################################
-- Base64 encoder/decoder function

-- character table string
local b='ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/'

-- decode
function dec(data)
	data = string.gsub(data, '[^'..b..'=]', '')
	return (data:gsub('.', function(x)
    	if (x == '=') then return '' end
    	local r,f='',(b:find(x)-1)
    	for i=6,1,-1 do r=r..(f%2^i-f%2^(i-1)>0 and '1' or '0') end
    	return r;
	end):gsub('%d%d%d?%d?%d?%d?%d?%d?', function(x)
    	if (#x ~= 8) then return '' end
    	local c=0
    	for i=1,8 do c=c+(x:sub(i,i)=='1' and 2^(8-i) or 0) end
    	return string.char(c)
	end))
end

function decodeImage(b64Image)
	local imgTyp = b64Image:match("data:image/(.-);base64,")
	local repData = "data:image/" .. imgTyp .. ";base64,"
	local b64Data = string.gsub(b64Image, repData, "");

	local tmpImg = os.tmpname()
	local retImg = tmpImg .. "." .. imgTyp

	local f = io.open(retImg, "w+")
	f:write(dec(b64Data))
	f:close()
--	os.remove(tmpImg) -- only for testing

	return retImg
end

-- ####################################################################

-- Convert special characters
function conv_str(_string)
	if _string == nil then return _string end
        _string = string.gsub(_string,'\\','');
	_string = string.gsub(_string,"&amp;","&");
	_string = string.gsub(_string,"&quot;","'");
	_string = string.gsub(_string,"%s+%s+", "")
	return _string
end

function fill_playlist(id) --- > begin playlist
	p = {}
	for i,v in  pairs(subs) do
		if v[1] == id then
			sm:hide()
			nameid = v[2]	
			local data  = getdata('https://d36olg7tmj6zg3.cloudfront.net/20200304160755/restapi/' .. id .. '.json',nil)
			if data then
				for  item in data:gmatch('{.-"subtitle"(.-duration_in_ms.-)"slug"')  do
					title,description,pk = item:match('"title":.-"(.-)", .-"teaser":.-"(.-)",.-"pk": (.-),') 

					if title == nameid then
                                            title,description,pk  = item:match('"media".-"description".-"title":.-"(.-)", .-"teaser":.-"(.-)",.-"pk": (.-),')
                                        end  

					if pk and title then
						add_stream( conv_str(title),"https://d36olg7tmj6zg3.cloudfront.net/20200304160755/restapi/media/" .. pk .. ".json", conv_str(description), nameid )
					end
				end
			end
			select_playitem()
		end
	end
end --- > end of playlist

-- Duration
function msec_to_min(_string)
	local seconds = tonumber(_string/1000) -- json therefore returns time in msec
		if seconds <= 0 then
		return "00:00:00";
	else
		hours = string.format("%02.f", math.floor(seconds/3600));
		mins = string.format("%02.f", math.floor(seconds/60 - (hours*60)));
		secs = string.format("%02.f", math.floor(seconds - hours*3600 - mins *60));
--		return hours..":"..mins..":"..secs -- hours, minutes and seconds are displayed
		return " " ..mins.. " Min." -- only minutes are displayed, default
	end
end

local epg = ""
local title = ""

function epgInfo (xres, yres, aspectRatio, framerate)
	if #epg < 1 then return end
	local dx = 700;
	local dy = 400;
	local x = 290;
	local y = 0;

	local hw = n:getRenderWidth(FONT['MENU'],title) + 20
	if hw > 400 then
		dy = hw
	end
	if dy >  SCREEN.END_X - SCREEN.OFF_X - 20 then
		dy = SCREEN.END_X - SCREEN.OFF_X - 20
	end
	local wh = cwindow.new{x=x, y=y, dx=dx, dy=dy, title="", icon=tierwelt_tv, has_shadow="true", show_header="true", show_footer="false"};  -- with out footer
	dy = dy + wh:headerHeight()

	local ct = ctext.new{parent=wh, x=20, y=0, dx=0, dy=dy, text = epg, font_text=FONT['MENU'], mode = "ALIGN_SCROLL | DECODE_HTML"};
 	h = ct:getLines() * n:FontHeight(FONT['MENU'])
	h = (ct:getLines() +4) * n:FontHeight(FONT['MENU'])
	if h > SCREEN.END_Y - SCREEN.OFF_Y -20 then
		h = SCREEN.END_Y - SCREEN.OFF_Y -20
	end
 	wh:setDimensionsAll(x,y,dx,h)
        ct:setDimensionsAll(20,0,dx-40,h)
	wh:setCenterPos{3}
	wh:paint()

	repeat
		msg, data = n:GetInput(500)
		if msg == RC.up or msg == RC.page_up then
			ct:scroll{dir="up"};
		elseif msg == RC.down or msg == RC.page_down then
			ct:scroll{dir="down"};
		end
	until msg == RC.ok or msg == RC.home
	wh:hide()
end

function set_pmid(id)
  pmid=tonumber(id);
  return MENU_RETURN["EXIT_ALL"];
end

function select_playitem()
    local m=menu.new{name="", icon=tierwelt_tv}

  for i,r in  ipairs(p) do
    m:addItem{type="forwarder", action="set_pmid", id=i, icon="streaming", name=r.title, hint=r.from, hint_icon="hint_reload"}
  end

  repeat
    pmid=0
    m:exec()
    if pmid==0 then
      return
    end

    local vPlay = nil
    local url=func[p[pmid].access](p[pmid].url)
    if url~=nil then
      if  vPlay  ==  nil  then
	vPlay  =  video.new()
      end

	local js_data = getdata(url,nil)
	local video_url,title = js_data:match('"uuid":.-"(.-)".-"title": "(.-)",')
	local duration_in_ms = js_data:match('"duration_in_ms": (.-),')
        duration = "Dauer: " .. msec_to_min(duration_in_ms)
	epg1 = p[pmid].from
	title = p[pmid].title

	if video_url then 
		epg = 'Rubrik ' .. p[pmid].rubrik .. ': ' .. conv_str(title) .. '\n\n' .. conv_str(epg1) .. '\n\n' .. duration
		vPlay:setInfoFunc("epgInfo")
                url = 'https://cdn-media.tierwelt-live.de/' .. video_url ..'_twl_720p.m4v' -- 360p = _twl_0500_16x9.m4v, 480p = _twl_480p.m4v, 720p = _twl_720p.m4v
	        vPlay:PlayFile("Tierwelt TV",url," " .. conv_str(title), " " .. duration );
	else
		print("Video URL not found")
	end

   end
  until false

end
function godirectkey(d)
	if d  == nil then return d end
	local  _dkey = ""
	if d == 1 then
		_dkey = RC.red
	elseif d == 2 then
		_dkey = RC.green
	elseif d == 3 then
		_dkey = RC.yellow
	elseif d == 4 then
		_dkey = RC.blue
	elseif d < 14 then
		_dkey = RC[""..d - 4 ..""]
	elseif d == 14 then
		_dkey = RC["0"]
	else
		-- rest
		_dkey = ""
	end
	return _dkey
end

function selectmenu()
	sm = menu.new{name="", icon=tierwelt_tv}
	sm:addItem{type="separator"}
	sm:addItem{type="back"}
	sm:addItem{type="separatorline"}
	local d = 0 -- directkey
	for i,v in  ipairs(subs) do
		d = d + 1
		local dkey = godirectkey(d)
		sm:addItem{type="forwarder", name=v[2], action="fill_playlist",id=v[1], hint=' Beiträge aus der Rubrik: ' ..v[2], directkey=dkey }
	end
	sm:exec()
end

--Main
init()
func={
  [stream]=function (x) return x end,
}

selectmenu()
os.execute("rm /tmp/lua*.png");
