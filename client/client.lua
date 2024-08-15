local Menu = exports.vorp_menu:GetMenuData()
local promptKey = 0xCEFD9220 -- E key
local storagePromptKey = 0x6319DB71 -- Up Arrow key
local unloadPromptKey = 0x05CA7C52 -- Down Arrow key
local returnPromptKey = 0x8AAA0AD4 -- Alt key
local prompts = {}
local storagePrompts = {}
local returnPrompts = {}
local rentedWagons = {}

local propSets = {
    wood = "pg_veh_logwagon_1",
    ore = "pg_delivery_Coal01x"
}

function SetupPrompt(location, text)
    local str = CreateVarString(10, 'LITERAL_STRING', text)
    local prompt = PromptRegisterBegin()
    PromptSetControlAction(prompt, promptKey)
    PromptSetText(prompt, str)
    PromptSetEnabled(prompt, false)
    PromptSetVisible(prompt, false)
    PromptSetHoldMode(prompt, true)
    PromptRegisterEnd(prompt)
    return prompt
end

function SetupStoragePrompt(promptText, key)
    local str = CreateVarString(10, 'LITERAL_STRING', promptText)
    local prompt = PromptRegisterBegin()
    PromptSetControlAction(prompt, key)
    PromptSetText(prompt, str)
    PromptSetEnabled(prompt, false)
    PromptSetVisible(prompt, false)
    PromptSetHoldMode(prompt, true)
    PromptRegisterEnd(prompt)
    return prompt
end

function GetItemLabelByName(type, itemName)
    for _, item in ipairs(Config.AllowedItems[type]) do
        if item.name == itemName then
            return item.label
        end
    end
    return itemName -- Fallback to name if label not found
end


Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)
        local playerCoords = GetEntityCoords(PlayerPedId())

        -- Rental prompts
        for _, location in ipairs(Config.Locations) do
            local distance = #(playerCoords - location.promptPosition)
            if distance < 2.0 then
                if not prompts[location] then
                    prompts[location] = SetupPrompt(location, Config.Locale.promptText)
                    --print("Prompt created for rental location.")
                end
                PromptSetEnabled(prompts[location], true)
                PromptSetVisible(prompts[location], true)
                if PromptHasHoldModeCompleted(prompts[location]) then
                    OpenWagonMenu(location.spawnPosition)
                end
            else
                if prompts[location] then
                    PromptSetEnabled(prompts[location], false)
                    PromptSetVisible(prompts[location], false)
                end
            end
        end

        -- Return prompts
        for _, location in ipairs(Config.ReturnLocations) do
            local distance = #(playerCoords - location.promptPosition)
            local vehicle = GetVehiclePedIsIn(PlayerPedId(), false)
            if DoesEntityExist(vehicle) then
                local vehicleNetId = VehToNet(vehicle)
                if distance < 2.0 and rentedWagons[vehicleNetId] then
                    if not returnPrompts[location] then
                        returnPrompts[location] = SetupStoragePrompt(Config.Locale.returnPromptText, returnPromptKey)
                        --print("Prompt created for return location.")
                    end
                    PromptSetEnabled(returnPrompts[location], true)
                    PromptSetVisible(returnPrompts[location], true)
                    if PromptHasHoldModeCompleted(returnPrompts[location]) then
                        ReturnWagon(location.refund)
                    end
                else
                    if returnPrompts[location] then
                        PromptSetEnabled(returnPrompts[location], false)
                        PromptSetVisible(returnPrompts[location], false)
                    end
                end
            end
        end

       -- Storage prompts for rented wagons
        for vehicleNetId, data in pairs(rentedWagons) do
            if data.type ~= "commute" then
                local vehicle = NetworkGetEntityFromNetworkId(vehicleNetId)
                if DoesEntityExist(vehicle) then
                    local vehicleCoords = GetEntityCoords(vehicle)
                    local distance = #(playerCoords - vehicleCoords)
                    if distance < 2.0 and IsVehicleStopped(vehicle) then
                        if not storagePrompts[vehicleNetId] then
                            local storePrompt = SetupStoragePrompt("Store items", storagePromptKey)
                            local unloadPrompt = SetupStoragePrompt("Unload items", unloadPromptKey)
                            storagePrompts[vehicleNetId] = {store = storePrompt, unload = unloadPrompt}
                           -- print("Storage prompts created for vehicle.")
                        end
                        PromptSetEnabled(storagePrompts[vehicleNetId].store, true)
                        PromptSetVisible(storagePrompts[vehicleNetId].store, true)
                        PromptSetEnabled(storagePrompts[vehicleNetId].unload, true)
                        PromptSetVisible(storagePrompts[vehicleNetId].unload, true)
                        if PromptHasHoldModeCompleted(storagePrompts[vehicleNetId].store) then
                            OpenStoreMenu(vehicle, data.type)
                        end
                        if PromptHasHoldModeCompleted(storagePrompts[vehicleNetId].unload) then
                            OpenRetrieveMenu(vehicle, data.type)
                        end
                    else
                        if storagePrompts[vehicleNetId] then
                            PromptSetEnabled(storagePrompts[vehicleNetId].store, false)
                            PromptSetVisible(storagePrompts[vehicleNetId].store, false)
                            PromptSetEnabled(storagePrompts[vehicleNetId].unload, false)
                            PromptSetVisible(storagePrompts[vehicleNetId].unload, false)
                        end
                    end
                end
            end
        end
    end
end)

function OpenStoreMenu(vehicle, type)
    local elements = {}
    for _, item in ipairs(Config.AllowedItems[type]) do
        table.insert(elements, {label = item.label, value = item.name})
    end

    Menu.Open("default", GetCurrentResourceName(), "store_items_menu", {
        title = "Store Items",
        align = "top-right",
        elements = elements
    }, function(data, menu)
        menu.close()
        local selectedItem = data.current.value
        local input = Input("Enter amount to store", "", 5)
        local amount = tonumber(input)

        if amount and amount > 0 then
            TriggerServerEvent('storeItems', VehToNet(vehicle), amount, selectedItem)
        else
            TriggerEvent('vorp:TipBottom', Config.Locale.invalidAmount, 4000)
        end
    end, function(data, menu)
        menu.close()
    end)
end

function OpenRetrieveMenu(vehicle, type)
    TriggerServerEvent('getStoredItems', VehToNet(vehicle), type)
end

RegisterNetEvent('showStoredItems')
AddEventHandler('showStoredItems', function(netId, items)
    local vehicle = NetToVeh(netId)
    items = items or {}

    local elements = {}
    for item, count in pairs(items) do
        local itemLabel = GetItemLabelByName(rentedWagons[netId].type, item)
        table.insert(elements, {label = itemLabel .. " (" .. count .. ")", value = item, count = count})
    end

    Menu.Open("default", GetCurrentResourceName(), "stored_items_menu", {
        title = "Wagon Storage",
        align = "top-right",
        elements = elements
    }, function(data, menu)
        menu.close()
        local selectedItem = data.current.value
        local selectedCount = data.current.count
        local input = Input("Enter amount to retrieve", tostring(selectedCount), 5)
        local amount = tonumber(input)

        if amount and amount > 0 and amount <= selectedCount then
            TriggerServerEvent('retrieveItems', VehToNet(vehicle), amount, selectedItem)
        else
            TriggerEvent('vorp:TipBottom', Config.Locale.invalidAmount, 4000)
        end
    end, function(data, menu)
        menu.close()
    end)
end)

function Input(promptTitle, defaultText, maxLength)
    AddTextEntry('FMMC_KEY_TIP1', promptTitle)
    DisplayOnscreenKeyboard(1, "FMMC_KEY_TIP1", "", defaultText, "", "", "", maxLength)
    while UpdateOnscreenKeyboard() ~= 1 and UpdateOnscreenKeyboard() ~= 2 do
        Citizen.Wait(0)
    end
    local result = GetOnscreenKeyboardResult()
    if result then
        return result
    else
        return nil
    end
end

function OpenWagonMenu(spawnLocation)
    Menu.CloseAll()
    local elements = {}

    for _, wagon in ipairs(Config.Wagons) do
        table.insert(elements, {
            label = wagon.label .. " - $" .. wagon.price,
            value = wagon.model,
            price = wagon.price,
            spawnLocation = spawnLocation,
            type = wagon.type,
            items = wagon.items or {},
            maxItems = wagon.maxItems or 0
        })
    end

    Menu.Open("default", GetCurrentResourceName(), "wagon_menu", {
        title = "Rent a Wagon",
        align = "top-right",
        desc = Config.Locale.warning,
        elements = elements
    }, function(data, menu)
        local selectedWagon = data.current.value
        local price = data.current.price
        local spawnLocation = data.current.spawnLocation
        local type = data.current.type
        local items = data.current.items
        local maxItems = data.current.maxItems
        TriggerServerEvent('rentWagon', selectedWagon, price, spawnLocation, type, items, maxItems)
        menu.close()
    end, function(data, menu)
        menu.close()
    end)
end

function ReturnWagon(refund)
    local playerPed = PlayerPedId()
    local vehicle = GetVehiclePedIsIn(playerPed, false)
    if DoesEntityExist(vehicle) then
        local vehicleNetId = VehToNet(vehicle)
        if rentedWagons[vehicleNetId] and rentedWagons[vehicleNetId].player == playerPed then
            TriggerServerEvent('returnWagon', vehicleNetId, refund)
            rentedWagons[vehicleNetId] = nil
            if storagePrompts[vehicleNetId] then
                PromptSetEnabled(storagePrompts[vehicleNetId].store, false)
                PromptSetVisible(storagePrompts[vehicleNetId].store, false)
                PromptSetEnabled(storagePrompts[vehicleNetId].unload, false)
                PromptSetVisible(storagePrompts[vehicleNetId].unload, false)
                storagePrompts[vehicleNetId] = nil
            end
        else
            TriggerEvent('vorp:TipBottom', Config.Locale.invalidVehicle, 4000)
        end
    end
end

RegisterNetEvent('spawnWagon')
AddEventHandler('spawnWagon', function(wagon, spawnLocation, type, items, maxItems)
    local model = GetHashKey(wagon)
    RequestModel(model)

    while not HasModelLoaded(model) do
        Citizen.Wait(0)
    end

    local vehicle = CreateVehicle(model, spawnLocation.x, spawnLocation.y, spawnLocation.z, spawnLocation.w, true, false)
    SetPedIntoVehicle(PlayerPedId(), vehicle, -1)
    local vehicleNetId = VehToNet(vehicle)
    rentedWagons[vehicleNetId] = {model = wagon, player = PlayerPedId(), type = type, items = items, maxItems = maxItems}

    -- Notify the server about the spawned wagon
    TriggerServerEvent('registerRentedWagon', vehicleNetId, type)
end)

RegisterNetEvent('removeWagon')
AddEventHandler('removeWagon', function(vehicleNetId)
    local vehicle = NetworkGetEntityFromNetworkId(vehicleNetId)
    if DoesEntityExist(vehicle) then
        DeleteVehicle(vehicle)
        rentedWagons[vehicleNetId] = nil
        if storagePrompts[vehicleNetId] then
            PromptSetEnabled(storagePrompts[vehicleNetId].store, false)
            PromptSetVisible(storagePrompts[vehicleNetId].store, false)
            PromptSetEnabled(storagePrompts[vehicleNetId].unload, false)
            PromptSetVisible(storagePrompts[vehicleNetId].unload, false)
            storagePrompts[vehicleNetId] = nil
        end
    end
end)

RegisterNetEvent('updateWagonPropSet')
AddEventHandler('updateWagonPropSet', function(netId, propSet)
    local vehicle = NetToVeh(netId)
    if DoesEntityExist(vehicle) then
        Citizen.InvokeNative(0x75F90E4051CC084C, vehicle, GetHashKey(propSet))
    end
end)

RegisterNetEvent('removeWagonPropSet')
AddEventHandler('removeWagonPropSet', function(netId)
    local vehicle = NetToVeh(netId)
    if DoesEntityExist(vehicle) then
        for _, propSet in pairs(propSets) do
            Citizen.InvokeNative(0xDA6D8B2E11E3A9C9, vehicle, GetHashKey(propSet))
        end
    end
end)

AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() == resourceName then
        -- Remove all rented wagons
        for vehicleNetId, _ in pairs(rentedWagons) do
            local vehicle = NetworkGetEntityFromNetworkId(vehicleNetId)
            if DoesEntityExist(vehicle) then
                DeleteVehicle(vehicle)
            end
        end
        rentedWagons = {}

        -- Remove all prompts
        for _, prompt in pairs(prompts) do
            PromptDelete(prompt)
        end
        prompts = {}

        for _, storagePrompt in pairs(storagePrompts) do
            PromptDelete(storagePrompt.store)
            PromptDelete(storagePrompt.unload)
        end
        storagePrompts = {}

        for _, returnPrompt in pairs(returnPrompts) do
            PromptDelete(returnPrompt)
        end
        returnPrompts = {}
    end
end)

