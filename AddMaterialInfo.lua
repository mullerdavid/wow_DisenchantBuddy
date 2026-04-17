---@class DisenchantBuddy
local DisenchantBuddy = select(2, ...)

local L = DisenchantBuddy.L
local Colors = {
    STANDARD = "|cffffffff",
    GOOD = "|cff1eff00",
    RARE = "|cff0070dd",
    EPIC = "|cffa335ee",
}

---@class ItemLevelRange
---@field minItemLevel number
---@field maxItemLevel number

---Builds the item level ranges for each enchanting material by probing the disenchant result
---functions across all item levels. Only materials whose item ID is defined in the Materials
---table for the active expansion are included. Iteration stops automatically once all probe
---functions return nil, which naturally caps the loop at the expansion's highest item level.
---@return table<number, {uncommon: ItemLevelRange?, rare: ItemLevelRange?, epic: ItemLevelRange?}>
local function buildItemLevelRanges()
    local ranges = {}
    local qualityProbes = {
        {fn = DisenchantBuddy.GetMaterialsForUncommonArmor, quality = "uncommon"},
        {fn = DisenchantBuddy.GetMaterialsForUncommonWeapons, quality = "uncommon"},
        {fn = DisenchantBuddy.GetMaterialsForRareItem, quality = "rare"},
        {fn = DisenchantBuddy.GetMaterialsForEpicItem, quality = "epic"},
    }

    for itemLevel = 1, math.huge do
        local anyResult = false
        for _, probe in ipairs(qualityProbes) do
            local results = probe.fn(itemLevel)
            if results then
                anyResult = true
                for _, result in ipairs(results) do
                    local id = result.itemId
                    if id then
                        if (not ranges[id]) then
                            ranges[id] = {}
                        end
                        local q = ranges[id][probe.quality]
                        if (not q) then
                            ranges[id][probe.quality] = {minItemLevel = itemLevel, maxItemLevel = itemLevel}
                        else
                            if itemLevel < q.minItemLevel then q.minItemLevel = itemLevel end
                            if itemLevel > q.maxItemLevel then q.maxItemLevel = itemLevel end
                        end
                    end
                end
            end
        end
        if (not anyResult) then
            break
        end
    end
    return ranges
end

---@type table<number, {uncommon: ItemLevelRange?, rare: ItemLevelRange?, epic: ItemLevelRange?}>
local itemLevelRangesByMaterial = buildItemLevelRanges()


---Adds the item level ranges to an enchanting material's tooltip
---@param tooltip GameTooltip
---@param itemId number
function DisenchantBuddy.AddMaterialInfo(tooltip, itemId)
    if (not itemLevelRangesByMaterial[itemId]) then
        return
    end

    tooltip:AddLine(L["Disenchanted from:"])
    local ranges = itemLevelRangesByMaterial[itemId]
    local uncommon = ranges.uncommon
    if (uncommon) then
        tooltip:AddDoubleLine(Colors.GOOD .. "  Item Level|r",
            uncommon.minItemLevel .. "-" .. uncommon.maxItemLevel)
    end
    local rare = ranges.rare
    if (rare) then
        tooltip:AddDoubleLine(Colors.RARE .. "  Item Level|r",
            rare.minItemLevel .. "-" .. rare.maxItemLevel)
    end
    local epic = ranges.epic
    if (epic) then
        tooltip:AddDoubleLine(Colors.EPIC .. "  Item Level|r",
            epic.minItemLevel .. "-" .. epic.maxItemLevel)
    end
    tooltip:Show()
end
