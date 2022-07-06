RegisterNetEvent("n2_elevators:FetchElevators", function()
    local src = source
    TriggerClientEvent("n2_elevators:SendElevators", src, Config.Elevators)
end)