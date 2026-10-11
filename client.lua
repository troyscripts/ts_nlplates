local resource = GetCurrentResourceName()
local dictionary = resource .. '_textures'
local replacements = {}

local function removeTextures()
    for _, name in ipairs(replacements) do
        RemoveReplaceTexture('vehshare', name)
    end
    replacements = {}
end

CreateThread(function()
    local txd = CreateRuntimeTxd(dictionary)
    local loaded = {}
    for _, entry in ipairs(Config.Textures) do
        if not loaded[entry.style] then
            local diffuse = CreateRuntimeTextureFromImage(txd, entry.style,
                ('textures/%s.png'):format(entry.style))
            local normal = CreateRuntimeTextureFromImage(txd, entry.style .. '_n',
                ('textures/%s_n.png'):format(entry.style))
            if not diffuse or diffuse == 0 or not normal or normal == 0 then
                removeTextures()
                print(('[%s] FOUT: texture %s kon niet geladen worden.'):format(resource, entry.style))
                return
            end
            loaded[entry.style] = true
        end
        AddReplaceTexture('vehshare', entry.original, dictionary, entry.style)
        replacements[#replacements + 1] = entry.original
        AddReplaceTexture('vehshare', entry.original .. '_n', dictionary, entry.style .. '_n')
        replacements[#replacements + 1] = entry.original .. '_n'
    end
    print(('[%s] %s | config %s | Nederlandse plaattextures geladen; kentekens behouden.')
        :format(resource, GetResourceMetadata(resource, 'version', 0), Config.Version))
end)

AddEventHandler('onClientResourceStop', function(stoppedResource)
    if stoppedResource == resource then removeTextures() end
end)

if Config.DebugCommand then
    RegisterCommand(Config.DebugCommand, function()
        local vehicle = GetVehiclePedIsIn(PlayerPedId(), false)
        if vehicle == 0 then
            print(('[%s] Stap in een voertuig en voer het commando opnieuw uit.'):format(resource))
            return
        end
        print(('[%s] Kenteken: %s | plaatindex: %s'):format(resource,
            GetVehicleNumberPlateText(vehicle), GetVehicleNumberPlateTextIndex(vehicle)))
    end, false)
end
