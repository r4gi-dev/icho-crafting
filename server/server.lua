local function getIdentifier(src)
    for _,v in pairs(GetPlayerIdentifiers(src)) do
        if v:find("license:") then return v end
    end
end

local function getPlayerXP(src)
    local identifier = getIdentifier(src)
    local result = MySQL.single.await("SELECT * FROM crafting_xp WHERE identifier = ?", {identifier})
    if not result then
        MySQL.insert.await("INSERT INTO crafting_xp (identifier,xp,level) VALUES (?,?,?)", {identifier,0,1})
        return 0,1
    end
    return result.xp, result.level
end

local function addXP(src, amount)
    local identifier = getIdentifier(src)
    local xp, level = getPlayerXP(src)
    xp = xp + amount
    for lvl,req in pairs(Config.Levels) do
        if xp >= req then level = lvl end
    end
    MySQL.update.await("UPDATE crafting_xp SET xp=?, level=? WHERE identifier=?", {xp, level, identifier})
    TriggerClientEvent("icho_crafting:updateXP", src, xp, level)
end

-- コールバック登録
lib.callback.register("icho_crafting:getXP", function(source)
    return getPlayerXP(source)
end)

lib.callback.register("icho_crafting:getInventory", function(source)
    local items = exports.ox_inventory:GetPlayerItems(source)
    local inventory = {}
    for _,item in pairs(items) do
        inventory[item.name] = item.count
    end
    return inventory
end)

-- クラフト開始
RegisterNetEvent("icho_crafting:craftItem", function(item, amount)
    local src = source
    local recipe = Config.Recipes[item]
    if not recipe then return end

    local xp, level = getPlayerXP(src)
    if level < recipe.level then
        TriggerClientEvent("ox_lib:notify", src, {type="error", description="Level too low"})
        return
    end

    -- 必要素材チェック
    for mat, count in pairs(recipe.materials) do
        local have = exports.ox_inventory:Search(src,'count',mat)
        if have < (count * amount) then
            TriggerClientEvent("ox_lib:notify", src, {type="error", description="Missing materials"})
            return
        end
    end

    TriggerClientEvent("icho_crafting:startCraft", src, item, amount)
end)

-- クラフト終了
RegisterNetEvent("icho_crafting:finishCraft", function(item, amount)
    local src = source
    local recipe = Config.Recipes[item]
    if not recipe then return end

    -- 素材消費
    for mat, count in pairs(recipe.materials) do
        exports.ox_inventory:RemoveItem(src, mat, count * amount)
    end

    -- アイテム付与
    exports.ox_inventory:AddItem(src, recipe.item, recipe.amount * amount)

    -- XP追加
    addXP(src, recipe.xp * amount)
end)