-- Stel de generator in; schrijf nooit achteraf een ander nummer op een voertuig.
local function applyPattern()
    if Config.DefaultPlatePattern == false then return end
    local ok, err = pcall(TSPlate.generate, Config.PlateFormat)
    if not ok then
        print(('[ts_nlplates] Standaard kentekenpatroon niet ingesteld: %s'):format(err))
        return
    end
    SetDefaultVehicleNumberPlateTextPattern(-1, Config.PlateFormat)
    -- ESX kan voor de basisindices een eigen patroon instellen.
    for index = 0, 5 do
        SetDefaultVehicleNumberPlateTextPattern(index, Config.PlateFormat)
    end
end

applyPattern()

-- Laat de start-/spelerinitialisatie van ESX eerst afronden.
AddEventHandler('esx:playerLoaded', function()
    SetTimeout(0, applyPattern)
end)
AddEventHandler('onClientResourceStart', function(name)
    if name == 'es_extended' then SetTimeout(0, applyPattern) end
end)
