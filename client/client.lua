local currentRecipes = {}
local craftingOpen = false
local currentPoint = nil

-- プレイヤーのインベントリ取得
local function GetInventory()
    local items = exports.ox_inventory:GetPlayerItems()
    local inv = {}
    for _, item in pairs(items) do
        inv[item.name] = item.count
    end
    return inv
end

-- インベントリ更新をNUIに送る
local function SendInventoryToUI()
    if not craftingOpen then return end
    SendNUIMessage({action="updateInventory", inventory=GetInventory()})
end

RegisterNetEvent('ox_inventory:updateInventory', function()
    SendInventoryToUI()
end)

-- クラフト開始 (progressBar)
RegisterNetEvent("icho_crafting:startCraft", function(item, amount)
    local recipe = Config.Recipes[item]
    if not recipe then return end

    for i = 1, amount do
        local success = lib.progressBar({
            duration = recipe.time,
            label = string.format("Crafting %s (%d/%d)", recipe.label, i, amount),
            useWhileDead = false,
            canCancel = true,
            disable = {move=true, car=true, combat=true},
            anim = {dict="mini@repair", clip="fixing_a_ped"},
            onTick = function(progress)
                -- progressは0.0～1.0でバーの進行度
                -- 必要ならUIに送ってリアルタイム更新も可能
                SendNUIMessage({
                    action = "updateCraftProgress",
                    current = i,
                    total = amount,
                    progress = progress
                })
            end
        })

        if success then
            TriggerServerEvent("icho_crafting:finishCraft", item, 1)
        else
            break
        end
    end

    -- 完了後にインベントリ更新
    SendInventoryToUI()
end)

-- クラフト台を開く
local function OpenCrafting(point)
    craftingOpen = true
    currentPoint = point
    currentRecipes = {}
    for _, rName in pairs(point.recipes) do
        if Config.Recipes[rName] then table.insert(currentRecipes, Config.Recipes[rName]) end
    end

    lib.callback("icho_crafting:getXP", false, function(xp, level)
        SendNUIMessage({
            action="open",
            recipes=currentRecipes,
            inventory=GetInventory(),
            xp=xp,
            level=level
        })
    end)

    SetNuiFocus(true,true)
end

-- UI閉じる
RegisterNUICallback("close", function(_, cb)
    craftingOpen = false
    currentPoint = nil
    SetNuiFocus(false,false)
    cb("ok")
end)

-- UIからクラフト実行
RegisterNUICallback("craft", function(data, cb)
    if not data.amount or data.amount < 1 then data.amount = 1 end
    TriggerServerEvent("icho_crafting:craftItem", data.item, data.amount)
    cb("ok")
end)

-- ESCキーで閉じる
CreateThread(function()
    while true do
        Wait(0)
        if craftingOpen and IsControlJustReleased(0, 322) then -- ESC
            SendNUIMessage({action="close"})
            craftingOpen = false
            SetNuiFocus(false,false)
        end
    end
end)

-- 画面右側に「Eキーでクラフトメニューを開く」ポップを表示
CreateThread(function()
    while true do
        Wait(0)
        local ped = PlayerPedId()
        local pos = GetEntityCoords(ped)
        local nearPoint = nil

        for _, point in pairs(Config.CraftingPoints) do
            local dist = #(pos - point.coords)
            if dist < 2.5 then
                nearPoint = point
                break
            end
        end

        if nearPoint then
            -- ox_libのポップ表示
            lib.showTextUI("[E] Open Craft Menu")

            -- Eキーで開く
            if IsControlJustReleased(0, 38) then
                OpenCrafting(nearPoint)
            end
        else
            lib.hideTextUI()
        end
    end
end)