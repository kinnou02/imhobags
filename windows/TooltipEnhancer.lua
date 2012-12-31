local Addon, private = ...

-- Upvalue
local format = string.format
local gsub = string.gsub

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

local function sumCharacter(t)
	local s = 0
	for k, v in pairs(t) do
		s = s + v
	end
	return s
end

local function sumGuild(t)
	local s = 0
	for i = 2, #t, 2 do
		s = s + t[i]
	end
	return s
end

local function formatCharacterLine(name, data, tooltip)
	local sum = sumCharacter(data)
	local function replacer(location)
		if(data[location] ~= 0) then
			return format(L.TooltipEnhancer[location], data[location])
		else
			return ""
		end
	end
	
	if(sum > 0) then
		tooltip[#tooltip + 1] = format("%s: %i", name, sum)
		if(not (sum == data.inventory or sum == data.currency)) then
			tooltip[#tooltip + 1] = gsub(" |inventory|bank|equipment|wardrobe|quest|currency", "|(%l+)", replacer)
		end
		tooltip[#tooltip + 1] = "\n"
	end
	return sum
end

local function formatGuildLine(name, data, tooltip)
	local sum = sumGuild(data)
	if(sum > 0) then
		tooltip[#tooltip + 1] = format("%s: %i ", name, sum)
		for i = 1, #data, 2 do
			if(data[i + 1] > 0) then
				tooltip[#tooltip + 1] = format("(%s %i)", data[i], data[i + 1])
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

	local tooltip = { }
	local total = 0
	local lines = 0
	local counts = Item.Storage.GetCharacterItemCounts(itemType)
	local names = { }
	for name in pairs(counts) do
		names[#names + 1] = name
	end
	table.sort(names)
	
	for i = 1, #names do
		local data = counts[names[i]]
		local sum = formatCharacterLine(names[i], data, tooltip)
		if(sum > 0) then
			lines = lines + 1
			total = total + sum
		end
	end

	counts = Item.Storage.GetGuildItemCounts(itemType)
	names = { }
	for name in pairs(counts) do
		names[#names + 1] = name
	end
	table.sort(names)

	for i = 1, #names do
		local data = counts[names[i]]
		local sum = formatGuildLine(names[i], data, tooltip)
		if(sum > 0) then
			lines = lines + 1
			total = total + sum
		end
	end
	
	if(lines > 0) then
		if(lines > 1) then
			tooltip[#tooltip + 1] = format("= %i", total)
		end
		showTooltip(table.concat(tooltip))
	end
end

Event.Tooltip[#Event.Tooltip + 1] = { tooltipTargetChanged, Addon.identifier, "TooltipEnhancer tooltipTargetChanged" }
