local Addon, private = ...

local _G = _G
local ipairs = ipairs
local print = print
local table = table
local select = select
local string = string

local dump = dump

local Command = Command
local Event = Event
local Inspect = Inspect
local UI = UI

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
	local screenHeight = _G.UIParent:GetHeight()
	local height = window:GetHeight()
	
	window:SetText(tooltip)
	window:SetVisible(true)
	window:SetPoint("BOTTOMLEFT", UI.Native.Tooltip, "TOPLEFT", padding, verticalOffset)
	window:SetPoint("BOTTOMRIGHT", UI.Native.Tooltip, "TOPRIGHT", -padding, verticalOffset)
end

local function buildLine(character, total, ...)
	local detail = ""
	if(total > select(2, ...)) then
		for i = 1, select("#", ...), 2 do
			local fmt, count = select(i, ...)
			if(count > 0) then
				detail = detail .. string.format(fmt, count)
			end
		end
	end
	return string.format(L.TooltipEnhancer.line, character, total, detail)
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
	
	if(not (ttype and shown)) then
		return
	end
	
	local itemType
	if(ttype == "item") then
		itemType = Inspect.Item.Detail(shown).type
	elseif(ttype == "itemtype") then
		itemType = shown
	else
		return
	end

	local counts = ItemDB.GetItemCounts(itemType)
	
	local tooltip = ""
	local total = 0
	local chars = 0
	for k, v in ipairs(counts) do
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
		end
	end
	if(chars > 1) then
		tooltip = tooltip .. string.format(L.TooltipEnhancer.total, total)
	end

	if(chars > 0) then
		showTooltip(tooltip)
	end
end

table.insert(Event.Tooltip, { tooltipTargetChanged, Addon.identifier, "TooltipEnhancer tooltipTargetChanged" })
