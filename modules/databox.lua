-- Please DO NOT edit this page unless you know what you are doing.
-- Maintainer: User:Encrypt0r 


-- https://www.mediawiki.org/wiki/Extension:Scribunto/Lua_reference_manual
-- https://www.mediawiki.org/wiki/Extension:Wikibase_Client/Lua

local property_blacklist = {
    'P360', --is a list of
    'P4224', --category contains
    'P935', -- Commons gallery
    'P1472', -- Commons Creator page
    'P1612', -- Commons Institution page
    'P373', -- Commons category
    'P3722', -- Commons maps category
    'P1151', -- topic's main Wikimedia portal
    'P1424', -- topic's main template
    'P910', -- topic's main category
    'P1200', -- bodies of water basin category
    'P1792', -- category of associated people
    'P1464', -- category for people born here
    'P1465', -- category for people who died here
    'P1791', -- category of people buried here
    'P1740', -- category for films shot at this location
    'P2033', -- Category for pictures taken with camera
    'P2517', -- category for recipients of this award
    'P4195', -- category for employees of the organization
    'P1754', -- category related to list
    'P301', -- category's main topic
    'P971', -- category combines topics
    'P3876', -- category for alumni of educational institution
    'P1753', -- list related to category
    'P3921', -- Wikidata SPARQL query equivalent
    'P1204', -- Wikimedia portal's main topic
    'P1423', -- template's main topic
    'P1709', -- equivalent class
    'P3950', -- narrower external class
    'P2888', -- exact match
    'P1382', -- coincident with
    'P527', -- has part
    'P2670', -- has parts of the class
    'P3113', -- does not have part
    'P2737', -- union of
    'P2738', -- disjoint union of
    'P2445', -- metasubclass of
    'P1963', -- properties for this type
    'P3176', -- uses property
    'P1889', -- different from
    'P460', -- said to be the same as
    'P2959', -- permanent duplicated item
    'P2860', -- cites
    'P5125', -- wikimedia outline
    'P5008', -- on focus list of Wikimedia project
    'P2559', -- Wikidata usage instructions
    'P1343', -- described by source
    'P972', --  catalogu
    'P1282', -- OSM tag or key
    'P4839', -- Wolfram Language entity code
    'P6104', -- Maintained by Wikiproject
    'P5996', -- Category for films in this language
    
    'P735', -- Given name
    'P734', -- Family name
    'P1559', -- Native name
    'P21', -- Sex or gender
    'P373', -- Commons category
    'P910', -- topic's main category
    'P1792', -- category of associated people
    'P1464', -- category for people born here
    'P2184', -- history of topic
    'P1438', -- Jewish Encyclopedia ID
    'P206', -- located in or next to body of water
    'P7867', -- category for maps
    'P8402', -- Open Data portal
    'P1448', -- official name
    'P569', -- date of birth
	'P570', -- date of death
	'P19', -- place of birth
	'P20', -- place of death
	'P27', -- country of citizenship
	'P2747', -- Filmiroda rating
	'P1552', -- has quality
	'P7561', -- category for the interior of the item
	'P1196', -- manner of death
	'P6365', -- member category
	'P465', -- sRGB color hex triplet
	'P487', -- Unicode character
	'P7084', -- related category
	'P1814', -- name in kana
}

-- Merge two tables and return a new table
function mergeTables(first, second)
    result = {}
    
    for k,v in pairs(first) do
    	table.insert(result, v)
    end
    
    for k,v in pairs(second) do
    	table.insert(result, v)
    end
    
    return result
end

-- Turn index based tables into key based tables
function valuesToKeys(array)
	local result = {}
	for _, v in pairs(array) do
		result[v:upper()] = true
	end
	return result
end

function getBirthStatement(lang, date_of_birth, date_of_death, place_of_birth)
	local birth_time = ''
	if date_of_death then
		birth_time = formatDate(lang, date_of_birth.time)
	else
		local date_of_birth_parts = mw.text.split(formatDate(lang, date_of_birth.time, nil, 'Y-m-j'), '-')

		birth_time = string.format('{{ڕۆژی لەدایکبوون و تەمەن|%s|%s|%s}}', 
			date_of_birth_parts[1], date_of_birth_parts[2], date_of_birth_parts[3])
	end
	local birth = birth_time

	if place_of_birth then
		local birth_location = mw.wikibase.getSitelink(place_of_birth.id, 'ckbwiki')
		
		local link = true
		if not birth_location then
			 birth_location = mw.wikibase.getSitelink(place_of_birth.id, 'enwiki')
			 link = false
		end
		
		if birth_location then
			if link then birth_location = '[[' .. birth_location .. ']]' end
			 
			birth = birth .. '<br>' .. birth_location
	
			local birth_country = getBestStatementById(place_of_birth.id, 'P17')
			if birth_country then
				birth_country = mw.wikibase.getSitelink(birth_country.id, 'ckbwiki')
				local link = true
				if not birth_country then
					 birth_country = mw.wikibase.getSitelink(birth_country.id, 'enwiki')
					 link = false
				end
				
				if link then birth_country = '[[' .. birth_country .. ']]' end
	
				birth = birth .. '، ' .. birth_country
			end
		end
	end
	
	return birth
end

function getDeathStatement(lang, date_of_birth, date_of_death, place_of_death)
	local date_of_birth_parts = mw.text.split(formatDate(lang, date_of_birth.time, nil, 'Y-m-j'), '-')
	local date_of_death_parts = mw.text.split(formatDate(lang, date_of_death.time, nil, 'Y-m-j'), '-')

	local death_time = string.format('{{ڕێکەوتی مەرگ و تەمەن|%s|%s|%s|%s|%s|%s}}', 
		date_of_death_parts[1], date_of_death_parts[2], date_of_death_parts[3],
		date_of_birth_parts[1], date_of_birth_parts[2], date_of_birth_parts[3])
	
	if place_of_death then
		local death_location = mw.wikibase.getSitelink(place_of_death.id, 'ckbwiki')
		
		local link = true
		if not death_location then
			death_location = mw.wikibase.getSitelink(place_of_death.id, 'enwiki')
			link = false
		end
		
		if death_location then
			if link then death_location = '[[' .. death_location .. ']]' end
				
			death = death_time .. '<br>' .. death_location
		
			local death_country = getBestStatementById(place_of_death.id, 'P17')
			if death_country then
				death_country = mw.wikibase.getSitelink(death_country.id, 'ckbwiki')
				
				local link = true
				if not death_country then
					 death_country = mw.wikibase.getSitelink(death_country.id, 'enwiki')
					 link = false
				end
				
				if link then death_country = '[[' .. death_country .. ']]' end
				
				death = death .. '، ' .. death_country
			end
		end
	end

	return death
end

-- Convert Arabic numbers (0123456789) to Kurdish numbers (٠١٢٣٤٥٦٧٨٩)
function toKurdishNumbers(text)
	return text:gsub('0', '٠')
			  :gsub('1', '١')
			  :gsub('2', '٢')
			  :gsub('3', '٣')
			  :gsub('4', '٤')
			  :gsub('5', '٥')
			  :gsub('6', '٦')
			  :gsub('7', '٧')
			  :gsub('8', '٨')
			  :gsub('9', '٩')
			  :gsub('square kilometre', 'کیلۆمەتر دووجا')
			  :gsub('kilometre', 'کیلۆمەتر')
end

function formatDate(lang, dateString, fallback, format)
	if not format then format = 'jی xg Y' end
	
	-- formatDate only supports positive (AD) dates
	if dateString:sub(1, 1) == '-' then return fallback or dateString end
	
	-- Work-around for a bug in Scribunto, more info: https://phabricator.wikimedia.org/T261072
	dateString = dateString:gsub('%-00%-00T', '-01-01T')
	
	return lang:formatDate(format, dateString, false)
end

function isEnglish(text)
	return string.find(text, '[abcdefghijklmnopqrstuvwxyz]') ~= nil
end

-- Returns the best statements for the first property this item has
function getBestStatement(item, ...)
	for i,v in ipairs(arg) do
        local statements = item:getBestStatements(v)
        if len(statements) >= 1 and statements[1] then
        	return statements[1].mainsnak.datavalue.value
        end
	end

	return nil
end

-- Returns the best statements for the first property this item has
function getBestStatementById(id, ...)
	for i,v in ipairs(arg) do
        local statements = mw.wikibase.getBestStatements( id, v)
        if len(statements) >= 1 and statements[1] then
        	return statements[1].mainsnak.datavalue.value
        end
	end

	return nil
end

-- Gets the length of a table
-- https://stackoverflow.com/a/2705804/7003797
function len(t)
  local count = 0
  for _ in pairs(t) do count = count + 1 end
  return count
end

-- checks if a string is empty
function isEmpty(s)
  return s == nil or s == ''
end

local module_properties = { ['item'] = true, ['بەند'] = true, ['پێڕستی ڕەش'] = true, ['تەنیا کوردی'] = true }
-- Get all properties that are overriden by the template
function getOverridenProperties(args)
	properties = {}
	
	for key, value in pairs(args) do
		if (not module_properties[key]) then -- If it was not a module property
			properties[key:upper()] = value
    	end
	end
	
	return properties
end

local p = {}

function p.databox(frame)
    local args = frame:getParent().args
    local itemId = nil
    local show_english_properties = true
    
    if args.item or args['بەند'] then
        itemId = args.item or args['بەند']
    end
    
    if args['تەنیا کوردی'] == true or args['تەنیا کوردی'] == 'بەڵێ' then
    	show_english_properties = false
    end
    
    local overriden_properties = getOverridenProperties(args)
    
    local hidden_properties = {}
    if args['پێڕستی ڕەش'] then
    	hidden_properties = mw.text.split(args['پێڕستی ڕەش'], "%s*[,،]%s*")
    end

    local lang = mw.language.getContentLanguage()
    local item = mw.wikibase.getEntity(itemId)

    if item == nil then
        mw.addWarning("Wikidata item not found")
        return ""
    end

    --Table
    local dataTable = mw.html.create('table')
    	:addClass('infobox vcard')
        :css({
            ['width'] = '22em'
        })

    -- Title
    dataTable:tag('tr'):tag('th')
    	:addClass('fn')
    	:attr('colspan', 2)
        :css({
            ['text-align'] = 'center',
            ['background-color'] = '#007BA7',
            ['padding'] = '0.5em 0',
            ['margin'] = '0.5em 0',
            ['font-size'] = '125%',
            ['color'] = '#ffffff',
            ['font-weight'] = 'bold',
        })
        :wikitext(item:getLabel() or mw.title.getCurrentTitle().text)

	-- Native name: P1559, Official name: P1448
	local officialName = getBestStatement(item, 'P1448', 'P1559')
	if officialName then
		if officialName.language ~= 'ckb' then -- Don't show official name if the official name was in Kurdish
			local langName = mw.language.fetchLanguageName(officialName.language, 'ckb')
			dataTable:tag('tr'):tag('th')
	    	:attr('colspan', 2)
	        :css({
	            ['text-align'] = 'center',
	            padding = '0.5em 0',
	            margin = '0.5em 0',
	            ['font-size'] = '90%',
	            ['font-weight'] = 'bold',
	            ['max-width'] = '180px'
	        })
	        :wikitext('بە  [[' .. langName ..']]: ' .. officialName.text)
		end
	end
	
    --Image
    local image = args['وێنە']
    if (image == nil) then
    	local images = item:getBestStatements('P18')
    	if #images >= 1 then
    		image = images[1].mainsnak.datavalue.value
    	end
    end
    
    if image ~= nil then
        dataTable:tag('tr'):tag('td')
            :attr('colspan', 2)
            :css({ ['text-align'] = 'center'})
            :wikitext('[[File:' .. image .. '|frameless|250px]]')
    end

    local properties = mw.wikibase.orderProperties(item:getProperties())
    local property_blacklist_hash = valuesToKeys(mergeTables(property_blacklist, hidden_properties))

    property_blacklist_hash['P31'] = true --Special property
    local edit_message = mw.message.new('vector-view-edit'):plain()
	
	-- Birth
	local date_of_birth = getBestStatement(item, 'P569')
	local date_of_death = getBestStatement(item, 'P570')
	local instance_of = getBestStatement(item, 'P31')
	local place_of_birth = getBestStatement(item, 'P19')
	local place_of_death = getBestStatement(item, 'P20')

	if instance_of and instance_of.id == 'Q5' and date_of_birth and date_of_birth.time:sub(1, 1) ~= '-' then -- human and birth date >= 0 AD
		local birth = getBirthStatement(lang, date_of_birth, date_of_death, place_of_birth)
		
		dataTable:tag('tr')
                :tag('th')
                    :attr('scope', 'row')
                    :css({
                    	['padding-top'] = '0.225em',
                    	['line-height'] = '1.1em',
                    	['padding-right'] = '0.65em'
                    })
                    :wikitext('لەدایکبوون'):done()
                :tag('td')
                	:css({ ['line-height'] = '1.4em', ['max-width'] = '180px' })
                    :wikitext(frame:preprocess(birth))
                    
        if date_of_death then
        	local death = getDeathStatement(lang, date_of_birth, date_of_death, place_of_death)
        	
        	dataTable:tag('tr')
                :tag('th')
                    :attr('scope', 'row')
                    :css({
                    	['padding-top'] = '0.225em',
                    	['line-height'] = '1.1em',
                    	['padding-right'] = '0.65em'
                    })
                    :wikitext('مردن'):done()
                :tag('td')
                	:css({ ['line-height'] = '1.4em', ['max-width'] = '180px' })
                    :wikitext(frame:preprocess(death))
	    end
	end
	
	
    for _, property in pairs(properties) do
        local datatype = item.claims[property][1].mainsnak.datatype

        local english_label = mw.wikibase.getLabelByLang(property, 'en'):upper()
        local kurdish_label = mw.wikibase.getLabelByLang(property, 'ckb')

		-- These properties have datatype of quantity, but we want to show them!
		if property == 'P1082' or -- population
		   property == 'P2046' or -- area
		   property == 'P2044' then -- elevation above sea level
		      datatype = 'number'
		   end
	
		overriden_value = overriden_properties[english_label] or overriden_properties[kurdish_label]

        if datatype ~= 'commonsMedia' and datatype ~= 'external-id' and
           datatype ~= 'quantity' and datatype ~= 'wikibase-property' and
           datatype ~= 'geo-shape' and datatype ~= 'tabular-data' and
           (not property_blacklist_hash[property] and not property_blacklist_hash[english_label] and not property_blacklist_hash[kurdish_label]) and
           (show_english_properties or kurdish_label ~= nil or overriden_value) and
           #item:getBestStatements(property) <= 5 then

            local propertyValue = item:formatStatements(property) -- label, value

			local overriden = true
            local value = overriden_value
            if (value == nil) then
            	if datatype == 'time' then
            		local dateString = getBestStatement(item, property).time
        			if property == 'P1317' or property == 'P2031' then -- floruit and work period (start)
        				value = formatDate(lang, dateString, propertyValue.value, 'Y')
        			else
        				value = formatDate(lang, dateString, propertyValue.value)
        			end
            	else
            		value = propertyValue.value
            	end
            	overriden = false
            elseif (value:find("^[Q]%d+") ~= nil) then -- Is a wikidata ID
            	value = '[[' .. mw.wikibase.getSitelink(value) .. ']]'
            end
			
			if (datatype == 'time' or datatype == 'number') then -- coordinate location
            	value = toKurdishNumbers(value)
			end
        	
        	row = dataTable:tag('tr')
                :tag('th')
                    :attr('scope', 'row')
                    :css({
                    	['padding-top'] = '0.225em',
                    	['line-height'] = '1.1em',
                    	['padding-right'] = '0.65em',
                    })
                    :wikitext(lang:ucfirst(propertyValue.label)):done()
                :tag('td')
                	:css({ ['line-height'] = '1.4em', ['max-width'] = '180px' })
                    :wikitext(frame:preprocess(value))
        end
    end
     
     --Map
    local coordinates_statements = item:getBestStatements('P625')
    if #coordinates_statements == 1 and coordinates_statements[1].mainsnak.datavalue and coordinates_statements[1].mainsnak.datavalue.value.globe == 'http://www.wikidata.org/entity/Q2' then
        --We build the call to mapframe
        local latitude = coordinates_statements[1].mainsnak.datavalue.value.latitude
        local longitude = coordinates_statements[1].mainsnak.datavalue.value.longitude
        local geojson = {
            type = 'Feature',
            geometry = {
                type = 'Point',
                coordinates = { longitude, latitude }
            },
            properties = {
                title = item:getLabel() or mw.title.getCurrentTitle().text,
                ['marker-symbol'] = 'marker',
                ['marker-color'] =  '#224422',
            }
        }
        
        dataTable:tag('tr'):tag('td')
            :attr('colspan', 2)
            :css({ ['text-align'] = 'center'})
            :wikitext(frame:extensionTag('mapframe', mw.text.jsonEncode(geojson), {
            height = 250,
            width = 250,
            frameless = 'frameless',
            align = 'center',
            latitude = latitude,
            longitude = longitude,
            zoom = 6 -- 100 km
        }))
    end
	
	local div_start = '<div style="border-style: solid; border-color:gray; border-width: 1px 0 0 0; margin-top: 2em; text-align: center;">'
	local pen_icon = '&nbsp;[[File:Wikidata-logo.svg|' .. edit_message .. '|22px|baseline|class=noviewer|link=https://www.wikidata.org/wiki/' .. item.id .. ']]'
	local edit_message_link = '[https://www.wikidata.org/wiki/' .. item.id .. ' لە ویکیدراوە دەستکاریی زانیارییەکان بکە]'
	dataTable:tag('tr'):tag('td')
            :attr('colspan', 2)
            :css({ ['text-align'] = 'center'})
            :wikitext(div_start .. edit_message_link .. pen_icon .. '</div>')
     
     return tostring(dataTable)
end

return p
