local media = {}
function media.getAddonMedia(url)
	local data = getdata(url)
	if data then
		local skipto = data.find(data, '<div class="section">')
		if skipto and #data > skipto then
			data = string.sub(data,skipto,#data)
		end
		local addText = "\n"
		for sat in data:gmatch('<p>(.-)</ul>') do
			sat = sat:gsub('</ul>', "\n")
			sat = sat:gsub('<.->', "")
			sat = sat:gsub('&deg;',"°")
			sat = xml_entities(sat)
			addText = addText .. sat .."\n"
		end
		if #addText == 1 then
			for sat in data:gmatch('<p>(.-)</div>') do
				sat = sat:gsub('</ul>', "\n")
				sat = sat:gsub('<.->', "")
				sat = sat:gsub('&deg;',"°")
				sat = xml_entities(sat)
				addText = addText .. sat .."\n"
			end
		end			
		media.addText = addText
	end
end
return media
