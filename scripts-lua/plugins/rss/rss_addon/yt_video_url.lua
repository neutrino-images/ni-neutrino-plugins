json = require "json"

function hex2char(hex)
  return string.char(tonumber(hex, 16))
end
function unescape_uri(url)
	if url == nil then return nil end
	return url:gsub("%%(%x%x)", hex2char)
end

function js_extract(data,patern)
	for  line  in  data:gmatch("(.-};)"  )  do
		local m = line:match(patern)                 
		if m then	
			return m
		end
	end
	return nil
end

-- Descramble the "n" parameter using the javascript code that does that
-- in the web page
function n_descramble( nparam, js )
    if not js then
        return nil
    end

    -- Look for the descrambler function's name
    -- a.C&&(b=a.get("n"))&&(b=Bpa[0](b),a.set("n",b),Bpa.length||iha(""))}};
    -- var Bpa=[iha];
    local callsite = js_extract( js, '[^;]*%.set%("n",[^};]*' )
    if not callsite then
        print( "Couldn't extract YouTube video throttling parameter descrambling function name" )
        return nil
    end

    -- Try direct function name from following clause
    local descrambler = string.match( callsite, '%.set%("n",.%),...?%.length||(...?)%(' )
    local itm = nil
    if not descrambler then
        -- Try from main call site
        descrambler = string.match( callsite, '[=%(,&|]([a-zA-Z0-9_$%[%]]+)%(.%),.%.set%("n",' )
        if descrambler then
            -- Check if this is only an intermediate variable
            itm = string.match( descrambler, '^([^%[%]]+)%[' )
            if itm then
                descrambler = nil
            end
        else
            -- Last chance: intermediate variable in following clause
            itm = string.match( callsite, '%.set%("n",.%),(...?)%.length' )
        end
    end

    if not descrambler and itm then
        -- Resolve intermediate variable
        descrambler = js_extract( js, 'var '..itm..'=%[(...?)[%],]' )
    end

    if not descrambler then
        print( "Couldn't extract YouTube video throttling parameter descrambling function name" )
        return nil
    end

    -- Fetch the code of the descrambler function
    -- lha=function(a){var b=a.split(""),c=[310282131,"KLf3",b,null,function(d,e){d.push(e)},-45817231, [data and transformations...] ,1248130556];c[3]=c;c[15]=c;c[18]=c;try{c[40](c[14],c[2]),c[25](c[48]),c[21](c[32],c[23]), [scripted calls...] ,c[25](c[33],c[3])}catch(d){return"enhanced_except_4ZMBnuz-_w8_"+a}return b.join("")};
    --local code = js_extract( js, "^"..descrambler.."=function%([^)]*%){(.-)};" )
	local code = js_extract( js, descrambler .. "=function%([^)]*%){(.-)};" )--my
	code = code:gsub('\n','')--my
    if not code then
        print( "Couldn't extract YouTube video throttling parameter descrambling code" )
        return nil
    end

    -- Split code into two main sections: 1/ data and transformations,
    -- and 2/ a script of calls
    local datac, script = string.match( code, "c=%[(.*)%];.-;try{(.*)}catch%(" )
    if ( not datac ) or ( not script ) then
        print( "Couldn't extract YouTube video throttling parameter descrambling rules" )
        return nil
    end

    -- Split "n" parameter into a table as descrambling operates on it
    -- as one of several arrays
    local n = {}
    for c in string.gmatch( nparam, "." ) do
        table.insert( n, c )
    end

    -- Helper
    local table_len = function( tab )
        local len = 0
        for i, val in ipairs( tab ) do
            len = len + 1
        end
        return len
    end

    -- Shared core section of compound transformations: it compounds
    -- the "n" parameter with an input string, character by character,
    -- using a Base64 alphabet as algebraic modulo group.
    -- var h=f.length;d.forEach(function(l,m,n){this.push(n[m]=f[(f.indexOf(l)-f.indexOf(this[m])+m+h--)%f.length])},e.split(""))
    local compound = function( ntab, str, alphabet )
        if ntab ~= n or
           type( str ) ~= "string" or
           type( alphabet ) ~= "string" then
            return true
        end
        local input = {}
        for c in string.gmatch( str, "." ) do
            table.insert( input, c )
        end

        local len = string.len( alphabet )
        for i, c in ipairs( ntab ) do
            if type( c ) ~= "string" then
                return true
            end
            local pos1 = string.find( alphabet, c, 1, true )
            local pos2 = string.find( alphabet, input[i], 1, true )
            if ( not pos1 ) or ( not pos2 ) then
                return true
            end
            local pos = ( pos1 - pos2 ) % len
            local newc = string.sub( alphabet, pos + 1, pos + 1 )
            ntab[i] = newc
            table.insert( input, newc )
        end
    end

    -- The data section contains among others function code for a number
    -- of transformations, most of which are basic array operations.
    -- We can match these functions' code to identify them, and emulate
    -- the corresponding transformations.
    local trans = {
        reverse = {
            func = function( tab )
                local len = table_len( tab )
                local tmp = {}
                for i, val in ipairs( tab ) do
                    tmp[len - i + 1] = val
                end
                for i, val in ipairs( tmp ) do
                    tab[i] = val
                end
            end,
            match = {
                -- function(d){d.reverse()}
                -- function(d){for(var e=d.length;e;)d.push(d.splice(--e,1)[0])}
                "^function%(d%)",
            }
        },
        append = {
            func = function( tab, val )
                table.insert( tab, val )
            end,
            match = {
                -- function(d,e){d.push(e)}
                "^function%(d,e%){d%.push%(e%)},",
            }
        },
        remove = {
            func = function( tab, i )
                if type( i ) ~= "number" then
                    return true
                end
                i = i % table_len( tab )
                table.remove( tab, i + 1 )
            end,
            match = {
                -- function(d,e){e=(e%d.length+d.length)%d.length;d.splice(e,1)}
                "^[^}]-;d%.splice%(e,1%)},",
            }
        },
        swap = {
            func = function( tab, i )
                if type( i ) ~= "number" then
                    return true
                end
                i = i % table_len( tab )
                local tmp = tab[1]
                tab[1] = tab[i + 1]
                tab[i + 1] = tmp
            end,
            match = {
                -- function(d,e){e=(e%d.length+d.length)%d.length;var f=d[0];d[0]=d[e];d[e]=f}
                -- function(d,e){e=(e%d.length+d.length)%d.length;d.splice(0,1,d.splice(e,1,d[0])[0])}
                "^[^}]-;var f=d%[0%];d%[0%]=d%[e%];d%[e%]=f},",
                "^[^}]-;d%.splice%(0,1,d%.splice%(e,1,d%[0%]%)%[0%]%)},",
            }
        },
        rotate = {
            func = function( tab, shift )
                if type( shift ) ~= "number" then
                    return true
                end
                local len = table_len( tab )
                shift = shift % len
                local tmp = {}
                for i, val in ipairs( tab ) do
                    tmp[( i - 1 + shift ) % len + 1] = val
                end
                for i, val in ipairs( tmp ) do
                    tab[i] = val
                end
            end,
            match = {
                -- function(d,e){for(e=(e%d.length+d.length)%d.length;e--;)d.unshift(d.pop())}
                -- function(d,e){e=(e%d.length+d.length)%d.length;d.splice(-e).reverse().forEach(function(f){d.unshift(f)})}
                "^[^}]-d%.unshift%(d.pop%(%)%)},",
                "^[^}]-d%.unshift%(f%)}%)},",
            }
        },
        -- Here functions with no arguments are not really functions,
        -- they're constants: treat them as such. These alphabets are
        -- passed to and used by the compound transformations.
        alphabet1 = {
            func = "0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ-_",
            match = {
                -- function(){for(var d=64,e=[];++d-e.length-32;){switch(d){case 91:d=44;continue;case 123:d=65;break;case 65:d-=18;continue;case 58:d=96;continue;case 46:d=95}e.push(String.fromCharCode(d))}return e}
                "^function%(%){[^}]-case 58:d=96;",
            }
        },
        alphabet2 = {
            func = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-_",
            match = {
                -- function(){for(var d=64,e=[];++d-e.length-32;)switch(d){case 46:d=95;default:e.push(String.fromCharCode(d));case 94:case 95:case 96:break;case 123:d-=76;case 92:case 93:continue;case 58:d=44;case 91:}return e}
                "^function%(%){[^}]-case 58:d%-=14;",
                "^function%(%){[^}]-case 58:d=44;",
            }
        },
        -- Compound transformations are based on a shared core section
        -- that compounds the "n" parameter with an input string,
        -- character by character, using a variation of a Base64
        -- alphabet as algebraic modulo group.
        compound = {
            func = compound,
            match = {
                -- function(d,e,f){var h=f.length;d.forEach(function(l,m,n){this.push(n[m]=f[(f.indexOf(l)-f.indexOf(this[m])+m+h--)%f.length])},e.split(""))}
                "^function%(d,e,f%)",
            }
        },
        -- These compound transformation variants first build their
        -- Base64 alphabet themselves, before using it.
        compound1 = {
            func = function( ntab, str )
                return compound( ntab, str, "0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ-_" )
            end,
            match = {
                -- function(d,e){for(var f=64,h=[];++f-h.length-32;)switch(f){case 58:f=96;continue;case 91:f=44;break;case 65:f=47;continue;case 46:f=153;case 123:f-=58;default:h.push(String.fromCharCode(f))} [ compound... ] }
                "^function%(d,e%){[^}]-case 58:f=96;",
            }
        },
        compound2 = {
            func = function( ntab, str )
                return compound( ntab, str,"ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-_" )
            end,
            match = {
                -- function(d,e){for(var f=64,h=[];++f-h.length-32;){switch(f){case 58:f-=14;case 91:case 92:case 93:continue;case 123:f=47;case 94:case 95:case 96:continue;case 46:f=95}h.push(String.fromCharCode(f))} [ compound... ] }
                -- function(d,e){for(var f=64,h=[];++f-h.length-32;)switch(f){case 46:f=95;default:h.push(String.fromCharCode(f));case 94:case 95:case 96:break;case 123:f-=76;case 92:case 93:continue;case 58:f=44;case 91:} [ compound... ] }
                "^function%(d,e%){[^}]-case 58:f%-=14;",
                "^function%(d,e%){[^}]-case 58:f=44;",
            }
        },
        -- Fallback
        unid = {
            func = function( )
                print( "Couldn't apply unidentified YouTube video throttling parameter transformation, aborting descrambling" )
                return true
            end,
            match = {
            }
        },
    }

    -- The data section actually mixes input data, reference to the
    -- "n" parameter array, and self-reference to its own array, with
    -- transformation functions used to modify itself. We parse it
    -- as such into a table.
    local data = {}
    datac = datac..","
    while datac ~= "" do
        local el = nil
        -- Transformation functions
        if string.match( datac, "^function%(" ) then
            for name, tr in pairs( trans ) do
                for i, match in ipairs( tr.match ) do
                    if string.match( datac, match ) then
                        el = tr.func
                        break
                    end
                end
                if el then
                    break
                end
            end
            if not el then
                el = trans.unid.func
                print( "Couldn't parse unidentified YouTube video throttling parameter transformation" )
            end

            -- Compounding functions use a subfunction, so we need to be
            -- more specific in how much parsed data we consume.
            if el == trans.compound.func or
               el == trans.compound1.func or
               el == trans.compound2.func then
                datac = string.match( datac, '^.-},e%.split%(""%)%)},(.*)$' )
            else
                datac = string.match( datac, "^.-},(.*)$" )
            end

        -- String input data
        elseif string.match( datac, '^"[^"]*",' ) then
            el, datac = string.match( datac, '^"([^"]*)",(.*)$' )
        -- Integer input data
        elseif string.match( datac, '^-?%d+,' ) then
            el, datac = string.match( datac, "^(.-),(.*)$" )
            el = tonumber( el )
        -- Reference to "n" parameter array
        elseif string.match( datac, '^b,' ) then
            el = n
            datac = string.match( datac, "^b,(.*)$" )
        -- Replaced by self-reference to data array after its declaration
        elseif string.match( datac, '^null,' ) then
            el = data
            datac = string.match( datac, "^null,(.*)$" )
        else
            print( "Couldn't parse unidentified YouTube video throttling parameter descrambling data" )
            el = false -- Lua tables can't contain nil values
            datac = string.match( datac, "^[^,]-,(.*)$" )
        end

        table.insert( data, el )
    end

    -- Debugging helper to print data array elements
    local prd = function( el, tab )
        if not el then
            return "???"
        elseif el == n then
            return "n"
        elseif el == data then
            return "data"
        elseif type( el ) == "string" then
            return '"'..el..'"'
        elseif type( el ) == "number" then
            el = tostring( el )
            if type( tab ) == "table" then
                el = el.." -> "..( el % table_len( tab ) )
            end
            return el
        else
            for name, tr in pairs( trans ) do
                if el == tr.func then
                    return name
                end
            end
            return tostring( el )
        end
    end

    -- The script section contains a series of calls to elements of
    -- the data section array onto other elements of it: calls to
    -- transformations, with a reference to the data array itself or
    -- the "n" parameter array as first argument, and often input data
    -- as a second argument. We parse and emulate those calls to follow
    -- the descrambling script.
    -- c[40](c[14],c[2]),c[25](c[48]),c[14](c[1],c[24],c[42]()), [...]
    for ifunc, itab, args in string.gmatch( script, "c%[(%d+)%]%(c%[(%d+)%]([^)]-)%)" ) do
        local iarg1 = string.match( args, "^,c%[(%d+)%]" )
        local iarg2 = string.match( args, "^,[^,]-,c%[(%d+)%]" )

        local func = data[tonumber( ifunc ) + 1]
        local tab = data[tonumber( itab ) + 1]
        local arg1 = iarg1 and data[tonumber( iarg1 ) + 1]
        local arg2 = iarg2 and data[tonumber( iarg2 ) + 1]

        -- Uncomment to debug transformation chain
        --print( '"n" parameter transformation: '..prd( func ).."("..prd( tab )..( arg1 ~= nil and ( ", "..prd( arg1, tab ) ) or "" )..( arg2 ~= nil and ( ", "..prd( arg2, tab ) ) or "" )..") "..ifunc.."("..itab..( iarg1 and ( ", "..iarg1 ) or "" )..( iarg2 and ( ", "..iarg2 ) or "" )..")" )
        --local nprev = table.concat( n )

        if type( func ) ~= "function" or type( tab ) ~= "table"
            or func( tab, arg1, arg2 ) then
            print( "Invalid data type encountered during YouTube video throttling parameter descrambling transformation chain, aborting" )
            print( "Couldn't descramble YouTube throttling URL parameter: data transfer will get throttled" )
            print( "Couldn't process youtube video URL, please check for updates to this script" )
            break
        end

        -- Uncomment to debug transformation chain
        --local nnew = table.concat( n )
        --if nprev ~= nnew then
        --    print( '"n" parameter transformation: '..nprev.." -> "..nnew )
        --end
    end

    return table.concat( n )
end

function js_descramble( sig, js )
	local descrambler = js_extract( js, "[=%(,&|](...?.?)%(decodeURIComponent%(.%.s%)%)" )
	if descrambler == nil then print("decodeURIComponent error") return sig end
	local rules = js_extract( js, descrambler.."=function%([^)]*%){(.-)};" )
	if rules == nil then return sig end
	local helper = rules:match(";(..)%...%(" )
	if helper == nil then return sig end
	local transformations = js_extract( js, "[ ,]"..helper.."={(.-)};" )
	if transformations == nil then return sig end

	-- Parse the helper object to map available transformations
	local trans = {}
	for meth,code in string.gmatch( transformations, "(..):function%([^)]*%){([^}]*)}" ) do
		-- a=a.reverse()
		if string.match( code, "%.reverse%(" ) then
			trans[meth] = "reverse"
		-- a.splice(0,b)
		elseif string.match( code, "%.splice%(") then
			trans[meth] = "slice"
		-- var c=a[0];a[0]=a[b%a.length];a[b]=c
		elseif string.match( code, "var c=" ) then
			trans[meth] = "swap"
		else
			print("Couldn't parse unknown youtube video URL signature transformation")
		end
	end

	-- Parse descrambling rules, map them to known transformations
	-- and apply them on the signature
	local missing = false
	for meth,idx in string.gmatch( rules, "..%.(..)%([^,]+,(%d+)%)" ) do
		idx = tonumber( idx )
		if trans[meth] == "reverse" then
			sig = string.reverse( sig )
		elseif trans[meth] == "slice" then
			sig = string.sub( sig, idx + 1 )
		elseif trans[meth] == "swap" then
			if idx > 1 then
				sig = string.gsub( sig, "^(.)("..string.rep( ".", idx - 1 )..")(.)(.*)$", "%3%2%1%4" )
			elseif idx == 1 then
				sig = string.gsub( sig, "^(.)(.)", "%2%1" )
			end
		else
			print("Couldn't apply unknown youtube video URL signature transformation")
			missing = true
		end
	end
	if missing then
		print( "Couldn't process youtube video URL, please check for updates to this script" )
	end
	return sig
end

local jsdata = nil
function getN(url,js)
	if url == nil then return url end
	if jsdata == nil then return url end
	-- The "n" parameter is scrambled too, and needs to be descrambled
	-- and replaced in place, otherwise the data transfer gets throttled
	-- down to between 40 and 80 kB/s, below real-time playability level.
	local n = string.match( url, "[?&]n=([^&]+)" )
	if n then
		if Curl == nil then
			Curl = curl.new()
		end
		n = Curl:decodeUri( n )
		local dn = n_descramble( n, js )
		if dn then
			url = string.gsub( url, "([?&])n=[^&]+", "%1n=".. Curl:encodeUri( dn ), 1 )
		else
			print( "Couldn't descramble YouTube throttling URL parameter: data transfer will get throttled" )
			print( "Couldn't process youtube video URL, please check for updates to this script" )
		end
	end
	return url
end

local fh = filehelpers.new()
function getJSdata(js_url)
	local jsname = "/tmp/._js_data"
	if jsdata == nil then
		if fh:exist(jsname , "f") then
			jsdata = read_file(jsname)
		end
	end
	if js_url and jsdata ==  nil then
		getdata("https://www.youtube.com" .. js_url, jsname)
		if fh:exist(jsname , "f") then
			jsdata = read_file(jsname)
		end
	end
	if jsdata then
		return jsdata
	end
	return nil
end

local media = {}
function media.getVideoUrl(yurl)
	local itags = {[37]='1920x1080',[96]='1920x1080',[22]='1280x720',[95]='1280x720',[94]='854x480',[35]='854x480',
		[18]='640x360',[93]='640x360',[34]='640x360',[5]='400x240',[6]='450x270',[36]='320x240',
		[92]='320x240',[17]='176x144',[13]='176x144',
		[85]='1920x1080p',[84]='1280x720',[83]='854x480',[82]='640x360'
	}

	local itags_audio = {[140]='m4a',[251]='opus',[250]='opus',[249]='opus'} -- 251,250,249 opus, bad audio sync
	local itags_vp9_60 = {[315]='3840x2160',[308]='2560x1440',[303]='1920x1080',[302]='1280x720'}
	local itags_vp9_30 = {[313]='3840x2160',[271]='2560x1440',[248]='1920x1080',[247]='1280x720',[244]='854x480'}
	local itags_vp9_HDR = {[337]='3840x2160',[336]='2560x1440',[335]='1920x1080',[334]='1280x720',[333]='854x480'}
	local itags_avc1_60 = {[299]='1920x1080',[298]='1280x720'}
	local itags_avc1_30 = {[137]='1920x1080',[136]='1280x720',[135]='854x480'}
	local itags_av01 = {[401]='3840x2160',[400]='2560x1440',[399]='1920x1080',[398]='1280x720',[397]='854x480'}
	-- disable or enable format
	local vp9_60 = true --webm
	local vp9_30 = true --webm
	local vp9_HDR = false --webm, HDR dont work on HD51
	local avc1_60 = true -- mp4
	local avc1_30 = true -- mp4
	local video_url = nil
	media.VideoUrl = nil

	if yurl == nil then return end

	if yurl:find("www.youtube.com/user/") then --check user link
		local youtube_user = getdata(yurl)
		if youtube_user == nil then return end
		local youtube_live_url = youtube_user:match('"url":"(/watch.-)"') or youtube_user:match('feature=c4.-href="(/watch.-)">')
		if youtube_live_url == nil then return end
		yurl = 'https://www.youtube.com' .. youtube_live_url
	end

	local h = hintbox.new{caption="Please Wait ...", text="I'm Thinking."}
	if h then
		h:paint()
	end
	local maxRes = getMaxVideoRes()
	local count,countx = 0,0
	local tmp_res = 0
	local stop = false
	local stop2 = false
	local urls = {}
	local have_itags = {}
	for i = 1,6 do
		countx = 0
		local data = getdata(yurl)
		local age_formats = false
		if data:find('LOGIN_REQUIRED') and youtube_dev_id then
			local id = yurl:match("/watch%?v=([%w+%p+]+)")
			if id then
				local postdat='{"context": {"client": {"clientName": "TVHTML5_SIMPLY_EMBEDDED_PLAYER", "clientVersion": "2.0", "hl": "en"}, "thirdParty": {"embedUrl": "https://www.youtube.com/"}}, "videoId": "' .. id .. '", "playbackContext": {"contentPlaybackContext": {"html5Preference": "HTML5_PREF_WANTS", "signatureTimestamp": 19103}}, "contentCheckOk": "True", "racyCheckOk": "True"}'
				local header_opt ={'content-type:application/json'}
				data = getdata('https://www.youtube.com/youtubei/v1/player?key=' .. youtube_dev_id, nil, postdat, 0, header_opt)
				if data then age_formats = true end
			end
		end

		if data then
			local m3u_url = data:match('hlsManifestUrl.:.(https:.-m3u8)') or data:match('hlsManifestUrl..:..(https:\\.-m3u8)') or data:match('hlsvp.:.(https:\\.-m3u8)')
			if m3u_url == nil then
				m3u_url = data:match('hlsManifestUrl.:.(https%%3A%.-m3u8)') or data:match('hlsManifestUrl..:..(https%%3A%%2F%%2F.-m3u8)') or data:match('hlsvp=(https%%3A%%2F%%2F.-m3u8)')
				if m3u_url then
					m3u_url = unescape_uri(m3u_url)
				end
			end
			if m3u_url then
				m3u_url = m3u_url:gsub("\\", "")
				video_url = getVideoUrlM3U8(m3u_url)
				if video_url and #video_url > 8 then
					media.VideoUrl=video_url
				end
				if video_url then
					if h then
						h:hide()
					end
					return
				end
			end
			local myurl = nil
			local url_map = data:match('"url_encoded_fmt_stream_map":"(.-)<div' ) or data:match('"url_encoded_fmt_stream_map":"(.-)"' )
			if url_map == nil then
				url_map = data:match('url_encoded_fmt_stream_map=(.-)$' )
				if url_map then url_map=unescape_uri(url_map) end
			end
			local player_map = data:match("ytplayer.config%s-=%s-({.-});")
			local map_urls = {}
			local ucount = 0
			if player_map or age_formats then
				local formats_data = nil
				if player_map then
					formats_data = data:match('"formats%p-:(%[{.-}])')
				end
				if age_formats then
					formats_data = data:match('"formats":%s(%[.-])')
				end
				if formats_data then
					formats_data = formats_data:gsub('\\\\\\"','')
					if formats_data:find('\\"itag\\":') then
						formats_data = formats_data:gsub('\\"','"')
					end
					local formats = json:decode (formats_data)
					if formats then
						for k, v in pairs(formats) do
							if v.itag and have_itags[v.itag] ~= true then
								have_itags[v.itag] = true
								ucount = ucount + 1
								if v.signatureCipher then
									map_urls[ucount] = v.signatureCipher
								elseif v.url then
									map_urls[ucount] = "url=" .. v.url
								elseif cipher then --unnecessary?
									map_urls[ucount] = v.cipher
								end
							end
						end
						local adaptiveFormats_data = nil
						if player_map then
							adaptiveFormats_data = data:match('"adaptiveFormats%p-:(%[{.-}])')
						end
						if age_formats then
							adaptiveFormats_data = data:match('"adaptiveFormats":%s(%[.-])')
						end
						if adaptiveFormats_data then
							adaptiveFormats_data = adaptiveFormats_data:gsub('\\\\\\"','')
							if adaptiveFormats_data:find('\\"itag\\":') then
								adaptiveFormats_data = adaptiveFormats_data:gsub('\\"','"')
							end
							local adaptiveFormats = json:decode (adaptiveFormats_data)
							if adaptiveFormats then
								for k, purl in pairs(adaptiveFormats) do
									if purl.itag and have_itags[purl.itag] ~= true then
										have_itags[purl.itag] = true
										ucount = ucount + 1
										if purl.signatureCipher then
											map_urls[ucount] = purl.signatureCipher
										elseif purl.url then
											map_urls[ucount] = "url=" .. purl.url
										elseif purl.cipher then --unnecessary?
											map_urls[ucount] = purl.cipher
										end
									end
								end
							end
						end
					end
				end
			end
			if url_map then
				url_map=url_map:gsub('"adaptive_fmts":"',"")
				for murl in url_map:gmatch( "[^,]+" ) do
					if murl and #murl > 100 and murl:find("itag") and murl:find("url=") then
						local itag = murl:match('itag=(%d+)') or murl:match('itag%%3D(%d+)')
						if itag and have_itags[itag] ~= true then
							have_itags[itag] = true
							ucount = ucount + 1
							map_urls[ucount]=murl
						end
					end
				end
			end
			if jsdata ==  nil then
				local js_url= data:match('<script%s+src="([/%w%p]+base%.js)"')
				jsdata = getJSdata(js_url)
			end
			for k, url in pairs(map_urls) do
				local have_itag = false
				local itagnum = 0
				local myitag = nil

				myitag = url:match('itag=(%d+)') or url:match('itag%%3D(%d+)')
				url=url:gsub('xtags=',"")
				url=url:gsub('fps=%d+',"")
				if myitag ~= nil then
					itagnum = tonumber(myitag)
					if itags[itagnum] then
						have_itag = true
					elseif revision == 1 and
							((vp9_30 and itags_vp9_30[itagnum]) or (vp9_60 and itags_vp9_60[itagnum])
					         or (avc1_60 and itags_avc1_60[itagnum]) or (avc1_30 and itags_avc1_30[itagnum])
					        or (vp9_HDR and itags_vp9_HDR[itagnum])) or itags_audio[itagnum] then
						have_itag = true
					end
				end
				if have_itag then
					if url:sub(1, 4) == 'url=' then
						myurl=url:match('url=(.-)$')
					else
						local tmp = url:match('(s=.-)url') or url:match('(.-)url')
						if tmp == nil then tmp = "" end
						local tmp_url = url:match('url=(.-)$')
						myurl= tmp_url .. "&" .. tmp
					end
					local s=myurl:match('6s=([%%%-%=%w+_]+)') or myurl:match('&s=([%%%-%=%w+_]+)') or myurl:match('^s=([%%%-%=%w+_]+)')
					if jsdata and s and (#s > 99 and #s < 160) then
						local s2=unescape_uri(s)
						local signature =js_descramble( s2, jsdata )
						if signature then
							s = s:gsub("[%+%?%-%*%(%)%.%[%]%^%$%%]","%%%1")
							signature = signature:gsub("[%%]","%%%%")
							myurl = myurl:gsub('s=' .. s ,'sig=' .. signature)
						end
						myurl=myurl:gsub("itag=" .. myitag, "")
					end
					myurl=myurl:gsub("\\u0026", "&")
					myurl=unescape_uri(myurl)
					myurl=myurl:gsub("&&", "&")

					myurl=myurl:gsub("\\", "")
					myurl=myurl:gsub('"', "")
					myurl=myurl:gsub('}', "")
					myurl=myurl:gsub(']', "")
					if select(2,myurl:gsub('&lmt=%d+', "")) == 2 then myurl=myurl:gsub('&lmt=%d+', "",1) end
					if select(2,myurl:gsub('&clen=%d+', "")) == 2 then myurl=myurl:gsub('&clen=%d+', "",1) end
					urls[itagnum] = myurl
					countx = countx + 1
				end
			end
		end
		local res = 0
		local sIdes = {}
		for k in pairs(urls) do table.insert(sIdes, k) end
		table.sort(sIdes)

		for _, k in ipairs(sIdes) do
			local video = urls[k]
			if itags[k] then
				tmp_res = tonumber(itags[k]:match('(%d+)x'))
				if tmp_res > res and tmp_res <= maxRes then
					count = count + 1
					video_url = video
					res = tmp_res
					media.UrlVideoAudio = ""
				end
			elseif avc1_30 and itags_avc1_30[k] then
				tmp_res = tonumber(itags_avc1_30[k]:match('(%d+)x'))
				if tmp_res > res and tmp_res <= maxRes then
					count = count + 1
					video_url = video
					res = tmp_res
					media.UrlVideoAudio = urls[140] or urls[251] or urls[250] or urls[249]
				end
			elseif avc1_60 and itags_avc1_60[k] then
				tmp_res = tonumber(itags_avc1_60[k]:match('(%d+)x'))
				if tmp_res > res and tmp_res <= maxRes then
					count = count + 1
					video_url = video
					res = tmp_res
					media.UrlVideoAudio = urls[140] or urls[251] or urls[250] or urls[249]
				end
			elseif vp9_30 and itags_vp9_30[k] then
				tmp_res = tonumber(itags_vp9_30[k]:match('(%d+)x'))
				if tmp_res > res and tmp_res <= maxRes then
					count = count + 1
					video_url = video
					res = tmp_res
					media.UrlVideoAudio = urls[140] or urls[251] or urls[250] or urls[249]
				end
			elseif vp9_60 and itags_vp9_60[k] then
				tmp_res = tonumber(itags_vp9_60[k]:match('(%d+)x'))
				if tmp_res > res and tmp_res <= maxRes then
					count = count + 1
					video_url = video
					res = tmp_res
					media.UrlVideoAudio = urls[140] or urls[251] or urls[250] or urls[249]
				end
			elseif vp9_HDR and itags_vp9_HDR[k] then
				tmp_res = tonumber(itags_vp9_HDR[k]:match('(%d+)x'))
				if tmp_res > res and tmp_res <= maxRes then
					count = count + 1
					video_url = video
					res = tmp_res
					media.UrlVideoAudio = urls[140] or urls[251] or urls[250] or urls[249]
				end
			end
			if maxRes == res then stop = true break end
			if maxRes > 1920 and tmp_res == 1920 then stop2 = true end
		end
		if stop or stop2 or (countx==0 and i>2) then
			print("TRY",i,count)
			break
		end
	end
	if video_url and #video_url > 8 then
		if jsdata then
			video_url = getN(video_url,jsdata)
		end
		media.VideoUrl=video_url
	end
	if h then
		h:hide()
	end
end

return media
