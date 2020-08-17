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
    'P1559' -- Native name
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
		result[v] = true
	end
	return result
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
end

-- Get all properties that are overriden by the template
function getOverridenProperties(args)
	properties = {}
	
	for key, value in pairs(args) do
		if (key:find("^p_")) then -- If the property name starts with 'p_'
			key = string.sub(key, 3) -- remove the prefix 'p_'
			local result, _ = string.gsub(key, "_", " ") -- change underscore into space
			properties[result] = value
    	end
	end
	
	return properties
end

local p = {}

function p.databox(frame)
    local args = frame:getParent().args
    local itemId = nil
    local show_english_properties = true
    
    if args.item then
        itemId = args.item
    end
    
    if args.only_kurdish_properties then
    	show_english_properties = false
    end
    
    local overriden_properties = {} getOverridenProperties(args)
    
    if not args.black_list then args.black_list = '' end
    local hidden_properties = mw.text.split(args.black_list, "%s*,%s*")
	
    local lang = mw.language.getContentLanguage()
    local item = mw.wikibase.getEntity(itemId)

    if item == nil then
        mw.addWarning("Wikidata item not found")
        return ""
    end

    local databoxRoot = mw.html.create('div')
        :addClass('infobox')
        :css({
            float = 'left',
            border = '1px solid #aaa',
            ['max-width'] = '300px',
            padding = '0 0.4em',
            margin = '0 0 0.4em 0.4em',
        })

    -- Title
    databoxRoot:tag('div')
        :css({
            ['text-align'] = 'center',
            ['background-color'] = '#f5f5f5',
            padding = '0.5em 0',
            margin = '0.5em 0',
            ['font-size'] = '120%',
            ['font-weight'] = 'bold',
        })
        :wikitext(item:getLabel() or mw.title.getCurrentTitle().text)

	-- Native name P1559
	local nativeName = item:getBestStatements('P1559')
	if #nativeName >= 1 then
		local nativeName = nativeName[1].mainsnak.datavalue.value
		if nativeName.language ~= 'ckb' then -- Don't show native name if the native name was in Kurdish
			local langName = mw.language.fetchLanguageName(nativeName.language, 'ckb')

			databoxRoot:tag('div')
	        :css({
	            ['text-align'] = 'center',
	            ['background-color'] = '#f5f5f5',
	            padding = '0.5em 0',
	            margin = '0.5em 0',
	            ['font-size'] = '80%',
	            ['font-weight'] = 'bold',
	        })
	        :wikitext('بە  [[' .. langName ..']]: ' .. nativeName.text)
		end
	end

     --Image
    local images = item:getBestStatements('P18')
    if #images >= 1 then
        databoxRoot
            :tag('div')
            :wikitext('[[File:' .. images[1].mainsnak.datavalue.value .. '|frameless|250px]]')
    end

    --Table
    local dataTable = databoxRoot
        :tag('table')
        :css({
            ['text-align'] = 'right',
            ['dir'] = 'rtl',
            ['font-size'] = '90%',
            ['word-break'] = 'break-word',
            ['width'] = '100%',
            ['table-layout'] = 'fixed',
        })
 
    local properties = mw.wikibase.orderProperties(item:getProperties())
    local property_blacklist_hash = valuesToKeys(mergeTables(property_blacklist, hidden_properties))

    property_blacklist_hash['P31'] = true --Special property
    local edit_message = mw.message.new('vector-view-edit'):plain()
  
    for _, property in pairs(properties) do
        local datatype = item.claims[property][1].mainsnak.datatype

        local english_label = mw.wikibase.getLabelByLang(property, 'en')
        local kurdish_label = mw.wikibase.getLabelByLang(property, 'ckb')

        if datatype ~= 'commonsMedia' and datatype ~= 'external-id' and
           datatype ~= 'quantity' and datatype ~= 'wikibase-property' and
           datatype ~= 'geo-shape' and datatype ~= 'tabular-data' and
           (not property_blacklist_hash[property] and not property_blacklist_hash[english_label]) and
           (show_english_properties or kurdish_label ~= nil) and
           #item:getBestStatements(property) <= 5 then
           	
            local propertyValue = item:formatStatements(property) -- label, value

			local overriden = true
            local value = overriden_properties[english_label]
            if (value == nil) then
            	value = propertyValue.value
            	overriden = false
            elseif (value:find("^[Q]%d+") ~= nil) then -- Is a wikidata ID
            	value = '[[' .. mw.wikibase.getSitelink(value) .. ']]'
            end
			
			if (property ~= 'P625') then -- coordinate location
            	value = toKurdishNumbers(value)
            end

            row = dataTable:tag('tr')
                :tag('th')
                    :attr('scope', 'row')
                    :wikitext(lang:ucfirst(propertyValue.label)):done()
                :tag('td')
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
        databoxRoot:wikitext(frame:extensionTag('mapframe', mw.text.jsonEncode(geojson), {
            height = 300,
            width = 300,
            frameless = 'frameless',
            align = 'center',
            latitude = latitude,
            longitude = longitude,
            zoom = 6 -- 100 km
        }))
    end

	databoxRoot:wikitext('<div style="border-style: solid; border-color:gray; border-width: 1px 0 0 0; margin-top: 2em; text-align: center;"> [https://www.wikidata.org/wiki/' .. item.id .. ' دەستکاری زانیارییەکان بکە لە ویکیدراوە]</div>')
     
     return tostring(databoxRoot)
end

return p
