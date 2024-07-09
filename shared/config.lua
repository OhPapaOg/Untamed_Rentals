Config = {}

Config.Locations = {
    {promptPosition = vector3(1523.43, 451.57, 90.36), spawnPosition = vector4(1523.62, 459.71, 89.87, 88.02)}, -- Valentine
    {promptPosition = vector3(-234.93, 748.07, 117.75), spawnPosition = vector4(-241.17, 744.15, 116.43, 205.08)} -- Emerald Ranch
}

Config.ReturnLocations = {
    {promptPosition = vector3(-241.17, 744.15, 116.43), refund = 25}, -- Emerald Ranch
    {promptPosition = vector3(1523.11, 458.54, 89.84), refund = 25} -- Valentine
}

Config.Wagons = { -- You can add more commute but only one wood or ore wagon. Don't change Wood and Ore wagon models, it will cause issues. 
    {label = "Small Wagon", model = "cart02", price = 25, type = "commute"},
    {label = "Wood Wagon", model = "logwagon", price = 100, type = "wood", maxItems = 50},
    {label = "Ore Wagon", model = "coal_wagon", price = 100, type = "ore", maxItems = 50}
}

Config.AllowedItems = {
    wood = {
        {label = "Treelogs", name = "treelogs"},
        {label = "Planks", name = "planks"}
    },
    ore = {
        {label = "Ore", name = "ore"},
        {label = "Coal", name = "coal"}
    }
}

Config.Locale = {
    promptText = "Rent a Wagon",
    returnPromptText = "Return Wagon",
    invalidAmount = "Invalid amount",
    notEnoughMoney = "Not enough money",
    rentSuccess = "You have successfully rented a wagon",
    storeSuccess = "You have stored {amount} {itemType}",
    retrieveSuccess = "You have retrieved {amount} {itemType}",
    storeFail = "Cannot store items, storage full",
    retrieveFail = "Cannot retrieve items, insufficient amount",
    invalidVehicle = "Invalid vehicle",
    notEnoughItems = "Not enough items in inventory",
    warning = "Warning: Contents will be lost if wagon is destroyed or server resets",
    viewStorage = "{item} ({count})",
    returnSuccess = "You have returned the wagon and received ${refund} back"
}