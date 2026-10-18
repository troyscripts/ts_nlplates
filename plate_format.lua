TSPlate = {}
function TSPlate.normalize(value)
    return type(value) == 'string' and value:match('^%s*(.-)%s*$'):upper() or ''
end
function TSPlate.generate(format)
    assert(type(format) == 'string' and #format > 0 and #format <= 8,
        'Config.PlateFormat moet 1 tot 8 tekens bevatten')
    assert(format:match('^[A1 ]+$') and format:find('[A1]'),
        'Gebruik alleen A, 1 en spaties in Config.PlateFormat')
    assert(format:sub(1, 1) ~= ' ' and format:sub(-1) ~= ' ', 'Geen spatie aan begin/einde')
    return (format:gsub('[A1]', function(token)
        if token == '1' then return tostring(math.random(0, 9)) end
        return string.char(math.random(65, 90))
    end))
end
