local Core
if Config.Core.gettingCoreObject == "export" then
    Core = exports[Config.Core.core_resource_name][Config.Core.gettingObjectName]()
else
    CreateThread(function()
        TriggerEvent(Config.Core.gettingObjectName, function(obj) Core = obj end)
        while Core == nil do 
            Wait(250) 
        end
    end)
end

local nuiMsg = false

function drawText()
    if Config.Blip.showBlip then
        local blip = AddBlipForCoord(Config.Location)
        SetBlipSprite(blip, Config.Blip.id)
        SetBlipColour(blip, Config.Blip.color)
        SetBlipScale(blip, Config.Blip.scale)
        SetBlipDisplay(blip, 4)
        SetBlipAsShortRange(blip, true)

        BeginTextCommandSetBlipName("STRING")
        AddTextComponentSubstringPlayerName(Config.Blip.label)
        EndTextCommandSetBlipName(blip)
    end

    while true do
        local plyPed = PlayerPedId()
        local plyCoords = GetEntityCoords(plyPed)
        local dist = #(plyCoords - Config.Location)
        if dist < 2.0 then
            if not nuiMsg then 
                nuiMsg = true
                SendNUIMessage({action = "draw"}) 
            end
            if IsControlJustPressed(0, 38) then
                SendNUIMessage({action = "undraw"})
                changeCam()
                TriggerServerEvent("vehicles:server:openUI")
                TriggerEvent("change:time", true)
            end
        elseif dist > 25 then
            Wait(1000)
        else
            if nuiMsg then
                nuiMsg = false
                SendNUIMessage({action = "undraw"})
            end
        end
        Wait(0)
    end
end

CreateThread(drawText)

RegisterNetEvent("vehicles:client:openUI",function(data,daily,buyer)
    SetNuiFocus(true, true)
	if #data ~= 0 then
		for k,v in next,data do
			for m,j in next,Config.Vehicles do
				for i=1,#j.buttons do
					local btn = j.buttons[i]
					if btn.model == v.model then
						if v.stock then
							btn.maxStock = v.stock
						end
					end
				end
			end
		end
	else
		for m,j in next,Config.Vehicles do
			for i=1,#j.buttons do
				j.buttons[i].maxStock = "unlimited"
			end
		end
	end
    SendNUIMessage({
        action = "open",
        vehicles = Config.Vehicles,
        buttons = data,
        daily = daily,
        colors = Config.Colors,
        buyer = buyer,
        testDrive = Config.TestDrive
    })
end)

local vehicleSpawned = false
local newVehicle
local loadVeh = true
RegisterNUICallback("spawnVehicle", function(data,cb)
    if not loadVeh then return end
    if not spawnVehicle then
        loadVeh = false
        spawnVehicle = true 
        local hash = GetHashKey(data.model)
        RequestModel(hash) 
        while not HasModelLoaded(hash) do Wait(250) end
        loadVeh = true
        newVehicle = CreateVehicle(hash,686.29425, 577.81353, 129.85414, 261.46661, false, false)
        SetVehicleCustomPrimaryColour(newVehicle, 255, 255, 255)
        SetVehicleCustomSecondaryColour(newVehicle, 255, 255, 255)
        local vehicleInfo = {
            speed = string.format("%.0f",GetVehicleMaxSpeed(newVehicle) * 3.6),
            acceleration = string.format("%.1f",GetVehicleModelAcceleration(hash) * 10),
            braking = string.format("%.1f",GetVehicleModelMaxBraking(hash) * 10),
            traction = string.format("%.1f",GetVehicleModelMaxTraction(hash) * 10)
        }
        SendNUIMessage({action = "updateInfo", vehicleInfo = vehicleInfo})
    else
        loadVeh = false
        DeleteEntity(newVehicle)
        local hash = GetHashKey(data.model)
        RequestModel(hash)
        while not HasModelLoaded(hash) do Wait(250) end
        loadVeh = true
        newVehicle = CreateVehicle(hash,686.29425, 577.81353, 129.85414, 261.46661, false, false)
        SetVehicleCustomPrimaryColour(newVehicle, 255, 255, 255)
        SetVehicleCustomSecondaryColour(newVehicle, 255, 255, 255)
        local vehicleInfo = {
            speed = string.format("%.0f",GetVehicleMaxSpeed(newVehicle) * 3.6),
            acceleration = string.format("%.1f",GetVehicleModelAcceleration(hash) * 10),
            braking = string.format("%.1f",GetVehicleModelMaxBraking(hash) * 10),
            traction = string.format("%.1f",GetVehicleModelMaxTraction(hash) * 10)
        }
        SendNUIMessage({action = "updateInfo", vehicleInfo = vehicleInfo})
    end
end)

RegisterNUICallback("buyVehicle", function(data,cb)
	if type(data.details.stock) ~= "string" then if data.details.stock <= 0 then return cb("nomoney") end end
	Core.Functions.TriggerCallback("vehicleshop:getMoney",function(bool)
		if bool then
            SendNUIMessage({action = "buyvehicle"})
			TriggerServerEvent("rn-vehicleshop:removeStock",data.details.model)
			DeleteEntity(newVehicle)
			closeVehicleShopAfterBuy()
			inShop = false
			local vehDetails = data.details
			local modelHash = GetHashKey(vehDetails.model)
			RequestModel(modelHash) 
			while not HasModelLoaded(modelHash) do Wait(250) end 
			local boughtVeh = CreateVehicle(modelHash, Config.BoughtVehicleSpawnLocation.coords,Config.BoughtVehicleSpawnLocation.heading, true, true)
			SetVehicleColours(boughtVeh, vehDetails.gtaColor, vehDetails.gtaColor)
			Config.BuyVehicleFunc(Core,boughtVeh,vehDetails.model)
		end
	end, data.details.numberprice)
end)

RegisterNUICallback("testDrive", function(data,cb)
    Core.Functions.TriggerCallback("vehicleshop:getMoney",function(bool)
        if bool then
            SendNUIMessage({action = "testdriver"})
            DeleteEntity(newVehicle)
            closeVehicleShopTestDrive()
            local vehDetails = data.details
            local modelHash = GetHashKey(vehDetails.model)
            RequestModel(modelHash) 
            while not HasModelLoaded(modelHash) do Wait(250) end 
            local boughtVeh = CreateVehicle(modelHash, Config.BoughtVehicleSpawnLocation.coords,Config.BoughtVehicleSpawnLocation.heading, true, true)
            NetworkRegisterEntityAsNetworked(boughtVeh)
            TaskWarpPedIntoVehicle(PlayerPedId(),boughtVeh,-1)
            Config.TestDriveFunc(Core,boughtVeh)
            local netID = NetworkGetNetworkIdFromEntity(boughtVeh)
            local time = data.timer
            while time >= 0 do
                Wait(1000)
                time = time - 1
            end
            
            SendNUIMessage({action = "hideTimer"})
            DoScreenFadeOut(1000)
            Wait(2000)
            TriggerServerEvent("vehicleshop:testdrive", netID)
            SetEntityCoords(PlayerPedId(), vector3(-31.46917, -1104.683, 26 - 0.5))
            DoScreenFadeIn(500)
        end
    end, Config.TestDrive.testDriveCost)

end)

RegisterNUICallback("changeColor", function(data,cb)
    SetVehicleCustomPrimaryColour(newVehicle, data.colorR, data.colorG, data.colorB)
    SetVehicleCustomSecondaryColour(newVehicle, data.colorR, data.colorG, data.colorB)
end)

RegisterNUICallback("changePos", function(data,cb)
    SetEntityHeading(newVehicle, tonumber(data.data))
end)

RegisterNUICallback("closeVehicleShop", function(data,cb)
    nuiMsg = false
    inShop = false
    DeleteEntity(newVehicle)
    closeVehicleShop()
end)



RegisterNUICallback("deletevehicle", function(data,cb)
    isRotatingMouseDown = false
    DeleteEntity(newVehicle)
end)

function DrawText3Ds(x, y, z, text)
    SetTextScale(0.35, 0.35)
    SetTextFont(4)
    SetTextProportional(1)
    SetTextColour(255, 255, 255, 215)
    SetTextEntry("STRING")
    SetTextCentre(true)
    AddTextComponentString(text)
    SetDrawOrigin(x,y,z, 0)
    DrawText(0.0, 0.0)
    local factor = (string.len(text)) / 370
    DrawRect(0.0, 0.0+0.0125, 0.017+ factor, 0.03, 0, 0, 0, 75)
    ClearDrawOrigin()
end
local inShop = false
-- vector3(-54.00951, -1111.288, 26.435819)
function changeCam()
    DoScreenFadeOut(500)
    Wait(1000)
    inShop = true
    SetEntityCoords(PlayerPedId(), vector3(682.93658, 568.3125, 156.26586))
    FreezeEntityPosition(PlayerPedId(), true)
    if not DoesCamExist(cam) then
        cam = CreateCam('DEFAULT_SCRIPTED_CAMERA', true)
    end
    SetCamActive(cam, true)
    SetCamRot(cam,vector3(-10.0,0.0, 161.3), true)
    SetCamFov(cam,50.0)
    SetCamCoord(cam, vector3(689.50085, 586.50915, 132))
    PointCamAtCoord(cam,vector3(689.50085, 586.50915, 132))
    RenderScriptCams(true, false, 2500.0, true, true)
    DoScreenFadeIn(1000)
    Wait(1000)
end

RegisterNUICallback("returnCam",function(data,cb)
    local ticket = ron 
    local fov = 50.0
    local currentHeading = GetEntityHeading(newVehicle)
    if ticket < 50.0 then 
        while ticket <= fov do
            Wait(20)
            ticket = ticket + 1
            SetCamFov(cam,ticket)
        end
    elseif ticket > 50.0 then 
        while ticket >= fov do
            Wait(20)
            ticket = ticket - 1
            SetCamFov(cam,ticket)
        end
    end
    if currentHeading > 98.53339 and not (currentHeading > 261.46661) then
        while currentHeading <= 261.46661 do 
            Wait(1)
            currentHeading = currentHeading + 1
            SetEntityHeading(newVehicle, currentHeading)
        end
    elseif currentHeading >= 261.46661 then 
        while currentHeading >= 261.46661 do 
            Wait(1)
            currentHeading = currentHeading - 1
            SetEntityHeading(newVehicle, currentHeading)
        end
    else
        while currentHeading > -98.53339 do  
            Wait(1)
            currentHeading = currentHeading - 1
            SetEntityHeading(newVehicle, currentHeading)
        end

    end
    ron = 50.0
end)

local lastX
local isRotatingMouseDown = false
RegisterNUICallback("mousedown",function(data,cb)
    local found,coords,mouseon = GetEntityMouseOn(cam)
    if not found then return false end
    if spawnVehicle and mouseon  == newVehicle then
        isRotatingMouseDown = true
        local currentEntityHeading = GetEntityHeading(newVehicle)
        lastX = GetNuiCursorPosition()
        local currentX = lastX
        CreateThread(function()
            while isRotatingMouseDown do
                currentX = GetNuiCursorPosition()
                local diff = (currentX-lastX) * 0.3
                local newheading
                if diff < 0 then
                    newheading = currentEntityHeading+diff
                elseif diff > 0 then
                    newheading = currentEntityHeading+diff
                end
                if newheading and currentEntityHeading ~= newheading then
                    SetEntityHeading(newVehicle,newheading + 0.0)
                    currentEntityHeading = newheading
                end
                lastX = currentX
                Wait(0)
            end
        end)
    end
    cb("ok")
end)

RegisterNUICallback("mouseup",function(data,cb)
    isRotatingMouseDown = false
    cb("ok")
end)

RegisterNUICallback("downscroll",function(data,cb) 
    zoom(cam,"ScrollDown")
end)

RegisterNUICallback("upscroll",function(data,cb) 
    zoom(cam,"Scrollup")
end)

RegisterNUICallback("blur",function(data,cb) 
    SetTimecycleModifier('hud_def_blur')
end)

AddEventHandler("onResourceStop",function(res)
  if res ~= GetCurrentResourceName() or inShop == false then return end
  SetEntityCoords(PlayerPedId(),Config.Location)
  FreezeEntityPosition(PlayerPedId(),false)
end)