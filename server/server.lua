VorpCore = {}

TriggerEvent("getCore",function(core)
    VorpCore = core
end)

VorpInv = exports.vorp_inventory:vorp_inventoryApi()

local rentedWagons = {}
local wagonStorage = {}
local propSets = {
    wood = "pg_veh_logwagon_1",
    ore = "pg_delivery_Coal01x"
}

-- Function to get label by item name
function GetItemLabelByName(type, itemName)
    for _, item in ipairs(Config.AllowedItems[type]) do
        if item.name == itemName then
            return item.label
        end
    end
    return itemName -- Fallback to name if label not found
end

RegisterServerEvent('rentWagon')
AddEventHandler('rentWagon', function(wagon, price, spawnLocation, type, items, maxItems, refund)
    local _source = source
    local Character = VorpCore.getUser(_source).getUsedCharacter

    if Character.money >= price then
        Character.removeCurrency(0, price)
        TriggerClientEvent('spawnWagon', _source, wagon, spawnLocation, type, items, maxItems, refund)
        TriggerClientEvent('vorp:TipBottom', _source, Config.Locale.rentSuccess, 4000)
    else
        TriggerClientEvent('vorp:TipBottom', _source, Config.Locale.notEnoughMoney, 4000)
    end
end)

RegisterServerEvent('storeItems')
AddEventHandler('storeItems', function(netId, amount, itemType)
    local _source = source
    local vehicle = NetworkGetEntityFromNetworkId(netId)
    
    if not DoesEntityExist(vehicle) then
        TriggerClientEvent('vorp:TipBottom', _source, Config.Locale.invalidVehicle, 4000)
        return
    end

    local itemCount = VorpInv.getItemCount(_source, itemType)
    if itemCount < amount then
        TriggerClientEvent('vorp:TipBottom', _source, Config.Locale.notEnoughItems, 4000)
        return
    end

    if not wagonStorage[vehicle] then
        wagonStorage[vehicle] = {}
    end
    if not wagonStorage[vehicle][itemType] then
        wagonStorage[vehicle][itemType] = 0
    end

    local maxItems = 0
    for _, wagon in ipairs(Config.Wagons) do
        if GetHashKey(wagon.model) == GetEntityModel(vehicle) then
            maxItems = wagon.maxItems
            break
        end
    end

    if wagonStorage[vehicle][itemType] + amount <= maxItems then
        wagonStorage[vehicle][itemType] = wagonStorage[vehicle][itemType] + amount
        VorpInv.subItem(_source, itemType, amount)
        local itemLabel = GetItemLabelByName(rentedWagons[netId].type, itemType)
        local message = Config.Locale.storeSuccess:gsub("{amount}", amount):gsub("{itemType}", itemLabel)
        TriggerClientEvent('vorp:TipBottom', _source, message, 4000)
        UpdateWagonPropSet(_source, vehicle)
    else
        TriggerClientEvent('vorp:TipBottom', _source, Config.Locale.storeFail, 4000)
    end
end)

RegisterServerEvent('retrieveItems')
AddEventHandler('retrieveItems', function(netId, amount, selectedItem)
    local _source = source
    local vehicle = NetworkGetEntityFromNetworkId(netId)
    
    if not DoesEntityExist(vehicle) then
        TriggerClientEvent('vorp:TipBottom', _source, Config.Locale.invalidVehicle, 4000)
        return
    end
    
    if wagonStorage[vehicle] then
        if wagonStorage[vehicle][selectedItem] then
            if wagonStorage[vehicle][selectedItem] >= amount then
                wagonStorage[vehicle][selectedItem] = wagonStorage[vehicle][selectedItem] - amount
                VorpInv.addItem(_source, selectedItem, amount)
                local itemLabel = GetItemLabelByName(rentedWagons[netId].type, selectedItem)
                local message = Config.Locale.retrieveSuccess:gsub("{amount}", amount):gsub("{itemType}", itemLabel)
                TriggerClientEvent('vorp:TipBottom', _source, message, 4000)
                UpdateWagonPropSet(_source, vehicle)
                return
            end
        end
    end

    TriggerClientEvent('vorp:TipBottom', _source, Config.Locale.retrieveFail, 4000)
end)

RegisterServerEvent('getStoredItems')
AddEventHandler('getStoredItems', function(netId, itemType)
    local _source = source
    local vehicle = NetworkGetEntityFromNetworkId(netId)
    if not DoesEntityExist(vehicle) then
        TriggerClientEvent('vorp:TipBottom', _source, Config.Locale.invalidVehicle, 4000)
        return
    end
    local storageData = wagonStorage[vehicle] or {}
    TriggerClientEvent('showStoredItems', _source, netId, storageData)
end)

RegisterServerEvent('returnWagon')
AddEventHandler('returnWagon', function(netId, refund)
    local _source = source
    local vehicle = NetworkGetEntityFromNetworkId(netId)
    local Character = VorpCore.getUser(_source).getUsedCharacter

    if DoesEntityExist(vehicle) and rentedWagons[netId] and rentedWagons[netId].player == _source then
        rentedWagons[netId] = nil
        Character.addCurrency(0, refund)
        TriggerClientEvent('removeWagon', _source, netId)
        TriggerClientEvent('vorp:TipBottom', _source, Config.Locale.returnSuccess:gsub("{refund}", refund), 4000)
    else
        TriggerClientEvent('vorp:TipBottom', _source, Config.Locale.invalidVehicle, 4000)
    end
end)

function UpdateWagonPropSet(source, vehicle)
    local hasItems = false
    local propSet = nil
    local vehicleStorage = wagonStorage[vehicle]
    
    if vehicleStorage then
        for item, count in pairs(vehicleStorage) do
            if count > 0 then
                hasItems = true
                for _, allowedItem in ipairs(Config.AllowedItems.wood) do
                    if allowedItem.name == item then
                        propSet = propSets.wood
                    end
                end
                for _, allowedItem in ipairs(Config.AllowedItems.ore) do
                    if allowedItem.name == item then
                        propSet = propSets.ore
                    end
                end
                break
            end
        end
    end

    if hasItems and propSet then
        TriggerClientEvent('updateWagonPropSet', source, NetworkGetNetworkIdFromEntity(vehicle), propSet)
    else
        TriggerClientEvent('removeWagonPropSet', source, NetworkGetNetworkIdFromEntity(vehicle))
    end
end

AddEventHandler('entityRemoved', function(entity)
    if rentedWagons[entity] then
        TriggerClientEvent('removeWagon', rentedWagons[entity].player, NetworkGetNetworkIdFromEntity(entity))
        rentedWagons[entity] = nil
    end
end)

RegisterServerEvent('registerRentedWagon')
AddEventHandler('registerRentedWagon', function(vehicleNetId, type)
    local _source = source
    rentedWagons[vehicleNetId] = {player = _source, type = type}
end)

AddEventHandler('playerDropped', function(reason)
    local _source = source
    for vehicleNetId, data in pairs(rentedWagons) do
        if data.player == _source then
            TriggerClientEvent('removeWagon', _source, vehicleNetId)
            rentedWagons[vehicleNetId] = nil
        end
    end
end)
