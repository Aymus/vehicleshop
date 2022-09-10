Config = {}
Config.Core = {
name = "QBCore",
gettingCoreObject = "export", -- event/export
gettingObjectName = "GetCoreObject", -- the event name / export name for getting the core object.
core_resource_name = "qb-core" -- the core resource name.
}
Config.Location = vector3(-33.07752, -1102.078, 26.422332) -- The location of the vehicleshop.

Config.BoughtVehicleSpawnLocation = {coords= vector3(-53.75075, -1111.026, 25.828771),heading = 72.2} -- The location where the purchased/testdrive vehicle will be spawned.

Config.Blip = {
  id = 326,
  color = 3,
  scale = 0.8,
  label = "Vehicle Shop",
  showBlip = true
}

------------------------------------------------------------------------------------------------------------------------
-- Vehicle Stock
------------------------------------------------------------------------------------------------------------------------

Config.Hour = 20 -- The time when new vehicles will be added to the stock.
Config.NumOfVehicles = 5 -- The amount of vehicles that will be added to the stock.

-- Every day the stock renewing itself with 5 (Config.NumOfVehicles = 5) new vehicles at 12:00 p.m. (Config.Hour = 12).
-- In order for the stock to work you need to call the Config.SetDefaultStockEvent function, Otherwise the stock will be UNLIMITED. 

------------------------------------------------------------------------------------------------------------------------
-- Test Drive
------------------------------------------------------------------------------------------------------------------------

Config.TestDrive = {
    testDriveTimer = 120, -- Duration of the test drive (seconds).
    testDriveCost = 5000, -- The price of the test drive.
}

------------------------------------------------------------------------------------------------------------------------
-- Categories And Vehicles
------------------------------------------------------------------------------------------------------------------------

Config.Vehicles = {
    { -- A category that shows the vehicles that added into stock today. DONT TOUCH IF YOU WANT THIS OPTION/CATEGORY.
      title = "daily vehicles", -- Title of category.
      buttons = {} -- DONT TOUCH!
    },

    -- Examples:

    {
      title = "compacts", -- Title of category.
      buttons = {
        {name = "Panto", costs = 5000, model = "panto"},
      }
    },
    {
      title = "sports", -- Title of category.
      buttons = {
        {name = "Carbonizzare", costs = 57000, model = "carbonizzare", maxStock = 10},
      }
    },
    {
      title = "MOTORCYCLES", -- Title of category.
      buttons = {
        {name = "Akuma", costs = 15000, model = "akuma", maxStock = 15},
      }
    }
}
-- Explanation of the buttons:
--[[
    name = vehicle's label (The name which is displayed in the vehicle menu).
    costs = vehicle's price.
    model = vehicle's model.
    stock = The maximum stock a vehicle can reach (Explanation from above).
]]

------------------------------------------------------------------------------------------------------------------------
-- Color selection:
------------------------------------------------------------------------------------------------------------------------

-- Full list of colors - https://wiki.rage.mp/index.php?title=Vehicle_Colors
Config.Colors = {
  {r = 255, g = 255, b = 246, colorName = "Beyaz", gtaColor = 111},
  {r = 13, g = 17, b = 22, colorName = "Siyah", gtaColor = 0},
  {r = 194, g = 196, b = 198, colorName = "Gri", gtaColor = 5},
  {r = 255, g = 207, b = 32, colorName = "Sarı", gtaColor = 88},
  {r = 18, g = 56, b = 60, colorName = "Yeşil", gtaColor = 51},
  {r = 207, g = 31, b = 33, colorName = "Kırmızı", gtaColor = 39},
  {r = 71, g = 87, b = 143, colorName = "Mavi", gtaColor = 64},
  {r = 242, g = 31, b = 153, colorName = "Pembe", gtaColor = 135},
  {r = 102, g = 184, b = 31, colorName = "Açık Yeşil", gtaColor = 55},
  {r = 110, g = 163, b = 198, colorName = "Açık Mavi", gtaColor = 74},
}
-- Explanation of color selection:
--[[
    r,g,b = (The color rgb values according to your gta color).
    colorName = color's name (put whatever you want).
    gtaColor = the color number from gta list.
]]

------------------------------------------------------------------------------------------------------------------------
-- Functions:
------------------------------------------------------------------------------------------------------------------------

-- Client:
Config.BuyVehicleFunc = function(Core,vehicleEntity,vehicleName)
  --[[
    This function is called when the purchased vehicle's entity is created and after the player has paid for the vehicle. 
    Parameters:
      @Core: The current core object.
      @vehicleEntity: The purchased vehicle's entity after it's been created.
      @vehicleName: The model listed in Config.Vehicles.
    
    Example for implementation:
    ]]
    local vehicleProps = Core.Functions.GetVehicleProperties(vehicleEntity)
    local model = GetEntityModel(vehicleEntity)
    vehicleProps.displayName = vehicleName
    TriggerEvent("vehiclekeys:client:SetOwner", GetVehicleNumberPlateText(vehicleEntity), vehicleEntity)
    TriggerServerEvent('rn-vehicleshop:setVehicleOwned', vehicleProps)
end

Config.TestDriveFunc = function(Core,vehicleEntity)
  --[[
    This function is called when the test drive vehicle's entity is created and after the player has paid for the test drive. 
    Parameters:
      @Core: The current core object.
      @vehicleEntity: The purchased vehicle's entity after it's been created.
    
    Example for implementation (Probably for hotwire add keys event/export):
    ]]
    TriggerEvent("vehiclekeys:client:SetOwner", GetVehicleNumberPlateText(vehicleEntity), vehicleEntity)
end

-- Server:
Config.GetPlayerMoney = function(playerId,Core)
  --[[
    This function is used for getting the player's money.
    Parameters:
      @playerId: The player server id/source.
      @Core: The current core object.
    
    Example for Qbus implementation is down below.
    ]]
    if type(playerId) == "number" then
        local player = Core.Functions.GetPlayer(playerId)
        if player then
            return player.PlayerData.money["cash"]
        end
    end
end

Config.RemovePlayerMoney = function(playerId, amount, Core)
  --[[
    This function is used for paying for the vehicle/testdrive.
    Parameters:
      @playerId: The player server id/source.
      @amount: the amount to pay.
      @Core: The current core object.
    
    Example for Qbus implementation is down below.
    ]]
    local player = Core.Functions.GetPlayer(playerId)
    if player then
        player.Functions.RemoveMoney("cash", amount)
    end
end

Config.GetPlayerNameFunc = function(playerId,Core)
  --[[
    This function is used for getting the character's name.
    Parameters:
      @playerId: The player server id/source.
      @Core: The current core object.
    
    Example for Qbus implementation is down below.
    ]]
    local player = Core.Functions.GetPlayer(playerId)
    return player.PlayerData.charinfo.firstname .. " " .. player.PlayerData.charinfo.lastname 
end

Config.ResetStockEvent = {
    name = "rn-vehicleshop:resetstock", -- This event resets the vehicles' stock. [*Server Side*],
    safe_for_net = false --[[
        true = allows you to trigger the event from a client side script and from a server side script.
        false =  allows you to trigger the event from a server side script only.
    ]]
}
   
Config.SetDefaultStockEvent = {
  name = "rn-vehicleshop:setDefaultStock", -- This event generates the stock.json file with values from the config.lua [*It is recommended to do it on first launch.]
  safe_for_net = true --[[
    true = allows you to trigger the event from a client side script and from a server side script.
    false =  allows you to trigger the event from a server side script only.
  ]]
}