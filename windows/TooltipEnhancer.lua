local Addon, private = ...

-- Builtins
local format = string.format
local formatn = string.formatn
local select = select

-- Globals
local Command = Command
local Event = Event
local Inspect = Inspect
local UI = UI
local UIParent = UIParent

setfenv(1, private)
Ux = Ux or { }

-- Private methods
-- ============================================================================

local verticalOffset = 10
local padding = 10

local window = UI.CreateFrame("Text", "ImhoBags_ItemCountTooltip", Ux.TooltipContext)
Ux.TooltipEnhancer = window

window:SetVisible(false)
window:SetFontSize(12)
window:SetBackgroundColor(0, 0, 0, 0.75)

local function showTooltip(tooltip)
	local left, top, right, bottom = UI.Native.Tooltip:GetBounds()
	local screenHeight = UIParent:GetHeight()
	local height = window:GetHeight()
	
	window:SetText(tooltip)
	window:SetVisible(true)
	window:ClearAll()
	window:SetPoint("BOTTOMLEFT", UI.Native.Tooltip, "TOPLEFT", padding, verticalOffset)
	window:SetPoint("BOTTOMRIGHT", UI.Native.Tooltip, "TOPRIGHT", -padding, verticalOffset)
end

local function buildLine(character, total, ...)
	local detail = ""
	if(total > select(2, ...)) then
		for i = 1, select("#", ...), 2 do
			local fmt, count = select(i, ...)
			if(count > 0) then
				detail = detail .. format(fmt, count)
			end
		end
	end
	return formatn(L.TooltipEnhancer.line, character, total, detail)
end

local function buildGuildLine(guild, total)
	local detail = ""
	for i = 2, #guild do
		local count = guild[i]
		if(count > 0) then
			detail = detail .. format("(Vault %i: %i)", i - 1, count)
		end
	end
	return formatn(L.TooltipEnhancer.line, guild[1], total, detail)
end

local function sum(character)
	local result = 0
	for i = 2, #character do
		result = result + character[i]
	end
	return result
end

local function tooltipTargetChanged(ttype, shown, buff)
	window:SetVisible(false)
	if(not Config.enhanceTooltips) then
		return
	end
	
	log("tooltip", ttype, shown, buff)
	if(not (ttype and shown)) then
		return
	end
	
	local itemType
	if(ttype == "item") then
		itemType = Inspect.Item.Detail(shown)
		-- When looting too quickly this may get called with an invalid item id
		if(not itemType) then
			return
		end
		itemType = itemType.type
	elseif(ttype == "itemtype") then
		itemType = shown
	else
		return
	end

	itemType = Inspect.Item.Detail(Utils.FixItemType(itemType))
	local counts = ItemDB.GetItemCounts(itemType)
	local guildCounts = ItemDB.GetGuildItemCounts(itemType)
	
	local tooltip = ""
	local total = 0
	local chars = 0
	for i = 1, #counts do
		local v = counts[i]
		local charTotal = sum(v)
		total = total + charTotal
		if(charTotal > 0) then
			chars = chars + 1
			tooltip = tooltip .. buildLine(v[1], charTotal,
				L.TooltipEnhancer.inventory, v[2],
				L.TooltipEnhancer.bank, v[3],
				L.TooltipEnhancer.mail, v[4],
				L.TooltipEnhancer.equipment, v[5],
				L.TooltipEnhancer.wardrobe, v[6]) .. "\n"
				-- Do not display currency as separate category as currency items cannot be in any other container
		end
	end
	local guilds = 0
	for i = 1, #guildCounts do
		local v = guildCounts[i]
		local guildTotal = sum(v)
		total = total + guildTotal
		if(guildTotal > 0) then
			chars = chars + 1
			tooltip = tooltip .. buildGuildLine(v, guildTotal) .. "\n"
		end
	end
	if(chars > 1 or guilds > 1) then
		tooltip = tooltip .. format(L.TooltipEnhancer.total, total)
	end

	if(chars > 0 or guilds > 0) then
		showTooltip(tooltip)
	end
end

Event.Tooltip[#Event.Tooltip + 1] = { tooltipTargetChanged, Addon.identifier, "TooltipEnhancer tooltipTargetChanged" }
