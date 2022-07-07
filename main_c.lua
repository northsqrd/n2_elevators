local usingElevator = false
local elevators = {}
local nearbyElevators = {}

local menuPool = NativeUI.CreatePool()
local menuPosition = {x = 0, y = 0} -- Left-aligned menu
--local menuPosition = {x = 1420, y = 0} -- Right-aligned menu
local elevatorMenu = nil


RegisterNetEvent("n2_elevators:SendElevators", function(pElevators)
    elevators = pElevators
end)

local function DisplayHelpText(text, playSound)
    SetTextComponentFormat("STRING")
    AddTextComponentString(text)
    DisplayHelpTextFromStringLabel(0, 0, (playSound == true), -1)
end

local function UseElevator(coords)
    DoScreenFadeOut(400)
    while not IsScreenFadedOut() do Wait(0) end
    local playerPed = PlayerPedId()
    NetworkFadeOutEntity(playerPed, true, true)
    SetEntityCoords(playerPed, coords.xyz, false, false, false, true)
    SetEntityHeading(playerPed, coords.w)
    SetGameplayCamRelativeHeading(0.0)
    Wait(1200)
    NetworkFadeInEntity(playerPed, true)
    PlaySoundFrontend(-1, "FAKE_ARRIVE", "MP_PROPERTIES_ELEVATOR_DOORS", true)
    DoScreenFadeIn(400)
    Wait(600)
    usingElevator = false
    if elevatorMenu ~= nil then
        elevatorMenu:Visible(false)
        elevatorMenu:Clear()
        elevatorMenu = nil
    end
end

local function OpenElevatorMenu(elevatorId, floorId)
    usingElevator = true
    elevatorMenu = NativeUI.CreateMenu("Elevator", elevators[elevatorId].label, menuPosition.x, menuPosition.y)
    menuPool:Add(elevatorMenu)

    for k, v in pairs(elevators[elevatorId].locations) do
        local label = v.label

        if k == floorId then
            label = label .. " | Current"
        end

        local item = NativeUI.CreateItem(label, v.description)
        if k == floorId then
            item:Enabled(false)
            item:SetRightBadge(21)
        end
        elevatorMenu:AddItem(item)
    end

    menuPool:RefreshIndex()
    elevatorMenu:Visible(true)
    elevatorMenu:CurrentSelection(floorId-1)

    elevatorMenu.OnItemSelect = function(_, _, index)
        UseElevator(elevators[elevatorId].locations[index].dest)
    end

    CreateThread(function()
        while usingElevator do
            Wait(250)
            local pedCoords = GetEntityCoords(PlayerPedId())
            if (#(elevators[elevatorId].locations[floorId].dest.xyz - pedCoords) > 2) then
                usingElevator = false
                if elevatorMenu ~= nil then
                    elevatorMenu:Visible(false)
                    elevatorMenu:Clear()
                    elevatorMenu = nil
                end
            end
        end
    end)
end

CreateThread(function()
    TriggerServerEvent("n2_elevators:FetchElevators")
    while true do
        Wait(1000)
        local pedCoords = GetEntityCoords(PlayerPedId())
        nearbyElevators = {}
        for k, v in ipairs(elevators) do
            for i, j in ipairs(v.locations) do
                if #(pedCoords - j.dest.xyz) < 8.0 then
                    nearbyElevators[#nearbyElevators+1] = {
                        eleId = k,
                        floorId = i,
                    }
                end
            end
        end
    end
end)

CreateThread(function()
    while true do
        Wait(0)
        if not usingElevator and #nearbyElevators > 0 then
            local pedCoords = GetEntityCoords(PlayerPedId())
            for _, v in ipairs(nearbyElevators) do
                local coords = elevators[v.eleId].locations[v.floorId].dest.xyz
                DrawMarker(27, coords.x, coords.y, coords.z + 0.05, 0.0, 0.0, 0.0, 0.0, 180.0, 0.0, 1.5, 1.5, 1.5, 255, 255, 255, 180, false, false, 2, nil, nil, false)
                if #(pedCoords - coords) < 2.0 then
                    DisplayHelpText("Press ~INPUT_CONTEXT~ to use the elevator.", true)
                    if IsControlJustPressed(0, 51) then
                        OpenElevatorMenu(v.eleId, v.floorId)
                        PlaySoundFrontend(-1, "SELECT", "HUD_FRONTEND_DEFAULT_SOUNDSET", true)
                    end
                end
            end
        else
            Wait(1000)
        end
    end
end)

CreateThread(function()
    while true do
        Wait(0)
        menuPool:MouseControlsEnabled(false)
        menuPool:MouseEdgeEnabled(false)
        menuPool:ControlDisablingEnabled(false)
        menuPool:ProcessMenus()

        if usingElevator then
            if elevatorMenu ~= nil then
                if elevatorMenu:Visible() == false then
                    usingElevator = false
                    elevatorMenu:Clear()
                    elevatorMenu = nil
                end
            end
        end
    end
end)