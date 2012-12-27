local Addon, private = ...

-- Builtins
local concat = table.concat
local format = string.format
local formatn = string.formatn
local pairs = pairs
local select = select
local sort = table.sort

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
			detail = detail .. format("(%s %i)", format(L.Ux.guildVault, i - 1), count)
		end
	end
	return formatn(L.TooltipEnhancer.line, guild[1], total, detail)
end
--[[
local function sum(character)
	local result = 0
	for i = 2, #character do
		result = result + character[i]
	end
	return result
end
]]
local function sum(t)
	local s = 0
	for k, v in pairs(t) do
		s = s + v
	end
	return s
end

local function addDetail(count, fmt, tooltip)
	if(count > 0) then
		tooltip[#tooltip + 1] = format(fmt, count)
	end
end

local function formatCharacterLine(name, data, tooltip)
	local sum = sum(data)
	if(sum > 0) then
		tooltip[#tooltip + 1] = format(L.TooltipEnhancer.line, name, sum)
		tooltip[#tooltip + 1] = " "
		if(not (sum == data.inventory or sum == data.currency)) then
			for location, count in pairs(data) do
				if(count > 0) then
					tooltip[#tooltip + 1] = format(L.TooltipEnhancer[location], count)
				end
			end
		end
		tooltip[#tooltip + 1] = "\n"
	end
	return sum
end

local function tooltipTargetChanged(ttype, shown, buff)
	window:SetVisible(false)
	if(not Config.enhanceTooltips) then
		return
	end
	
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

	local counts = Item.Storage.GetCharacterItemCounts(itemType)
	local guildCounts = { }--ItemDB.GetGuildItemCounts(itemType)
	local names = { }
	for name in pairs(counts) do
		names[#names + 1] = name
	end
	sort(names)
	
	local tooltip = { }
	local total = 0
	local chars = 0
	for i = 1, #names do
		local data = counts[names[i]]
		local sum = formatCharacterLine(names[i], data, tooltip)
		if(sum > 0) then
			chars = chars + 1
			total = total + sum
		end
	end

	if(chars > 1--[[ or guilds > 1]]) then
		tooltip[#tooltip + 1] = format(L.TooltipEnhancer.total, total)
	end

	if(chars > 0 or guilds > 0) then
		showTooltip(concat(tooltip))
	end
end

Event.Tooltip[#Event.Tooltip + 1] = { tooltipTargetChanged, Addon.identifier, "TooltipEnhancer tooltipTargetChanged" }
