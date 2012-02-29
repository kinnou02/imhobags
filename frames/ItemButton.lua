local addon = (...).data

local _G = _G
local print = print
local table = table
local tostring = tostring
local type = type

local dump = dump

local Command = Command
local Inspect = Inspect
local UI = UI

-- Frames vannot be deleted, keep a cache and only create new frames if the cache is empty
-- Calling Dispose() on a button moves it back to the cache
local cachedButtons = { }

setfenv(1, addon)
Ux = Ux or { }

ItemButtonWidth = 48
ItemButtonHeight = 48

local function button_SetItem(self, type, slots, stack)
	self.type = type
	self.slots = slots
	self.stack = stack
	
	self.icon:SetTexture("Rift", type.icon)
	
	self.stackText:SetText(tostring(stack))
	self.stackText:SetVisible(stack > 1)

	if(_G.type(slots) == "table") then
		slots = #slots
	end
	self.slotsText:SetText(tostring(slots))
	self.slotsText:SetVisible(slots > 1)
	
	self:SetBackgroundColor(Utils.RarityColor(type.rarity))
end

local function button_Dispose(self)
	table.insert(cachedButtons, self)
	self:SetVisible(false)
end

local function button_MouseIn(self)
	local target
	if(type(self.slots) == "table") then
		target = Inspect.Item.Detail(self.slots[1]).id
	else
		target = self.type.type
	end
	Command.Tooltip(target)
end

local function button_MouseOut(self)
	Command.Tooltip(nil)
end

function Ux.CreateItemButton(parent)
	local button
	if(#cachedButtons == 0) then
		button = UI.CreateFrame("Frame", "ImhoBags_ItemButton", parent)
		
		button:SetWidth(ItemButtonWidth)
		button:SetHeight(ItemButtonHeight)
		
		button.icon = UI.CreateFrame("Texture", "", button)
		button.icon:SetPoint("CENTER", button, "CENTER")
		button.icon:SetHeight(button:GetHeight() - 2)
		button.icon:SetWidth(button:GetWidth() - 2)
		
		button.stackText = UI.CreateFrame("Text", "", button)
		button.stackText:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", -1, -2)
		button.stackText:SetFontSize(13)
		button.stackText:SetBackgroundColor(0.0, 0.0, 0.0, 0.5)
		button.stackText:SetLayer(button:GetLayer() + 1)
		
		button.slotsText = UI.CreateFrame("Text", "", button)
		button.slotsText:SetPoint("BOTTOMRIGHT", button.stackText, "TOPRIGHT", 0, 0)
		button.slotsText:SetFontSize(10)
		button.slotsText:SetBackgroundColor(0.0, 0.0, 0.0, 0.5)
		button.slotsText:SetFontColor(0.8, 0.8, 0.8)
		button.slotsText:SetLayer(button:GetLayer() + 1)
		
		button.SetItem = button_SetItem
		button.Dispose = button_Dispose
		button.Event.MouseIn = button_MouseIn
		button.Event.MouseOut = button_MouseOut
	else
		button = table.remove(cachedButtons)
		button:SetVisible(true)
	end
	return button
end
