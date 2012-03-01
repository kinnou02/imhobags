local addon = (...).data

local _G = _G
local print = print
local table = table
local tostring = tostring
local type = type

local dump = dump

local Command = Command
local Event = Event
local Inspect = Inspect
local UI = UI

-- Frames vannot be deleted, keep a cache and only create new frames if the cache is empty
-- Calling Dispose() on a button moves it back to the cache
local cachedButtons = { }

setfenv(1, addon)
Ux = Ux or { }
Ux.ItemButton = { }

Ux.ItemButtonWidth = 50
Ux.ItemButtonHeight = 50
Ux.ItemButtonBorder = 2

-- Private methods
-- ============================================================================

local function ItemButton_SetItem(self, type, slots, stack)
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

local function ItemButton_Dispose(self)
	table.insert(cachedButtons, self)
	self:SetVisible(false)
end

local function ItemButton_ShowTooltip(self)
	if(self.tooltip) then
		local target
		if(type(self.slots) == "table") then
			target = Inspect.Item.Detail(self.slots[1]).id
		else
			target = self.type.type
		end
		Command.Tooltip(target)
		-- TODO: position tooltip near button
	end
end

local function ItemButton_MouseMove(self)
	ItemButton_ShowTooltip(self)
	if(self.pickingUp) then
		Command.Cursor(self.pickingUp)
		self.pickingUp = nil
	end
end

local function ItemButton_MouseOut(self)
	Command.Tooltip(nil)
	self.tooltip = false
end

local function ItemButton_MouseIn(self)
	self.tooltip = true
	ItemButton_ShowTooltip(self)
end

local function ItemButton_LeftDown(self)
	if(type(self.slots) == "table") then
		self.pickingUp = Inspect.Item.Detail(self.slots[1]).id
	end
end

local function ItemButton_LeftUp(self)
	local cursor, held = Inspect.Cursor()
	if(not self.pickingUp and cursor == "item" and type(self.slots) == "table") then
		Command.Item.Move(held, self.slots[1])
	elseif(self.pickingUp) then
		Command.Cursor(self.pickingUp)
		self.pickingUp = nil
	end
	self.commandTarget = nil
end

local function ItemButton_RightDown(self)
	if(type(self.slots) == "table") then
		self.commandTarget = self.slots[1]
	end
end

local function ItemButton_RightUp(self)
	if(self.commandTarget) then
		-- TODO: use item
	end
	self.commandTarget = nil
end

local function ItemButton_RightUpoutside(self)
	self.commandTarget = nil
end

-- Public methods
-- ============================================================================

function Ux.ItemButton.New(parent)
	local button
	if(#cachedButtons == 0) then
		button = UI.CreateFrame("Frame", "ImhoBags_ItemButton", parent)
		
		button:SetWidth(Ux.ItemButtonWidth)
		button:SetHeight(Ux.ItemButtonHeight)
		button:SetMouseMasking("limited")
		
		local border = Ux.ItemButtonBorder
		button.icon = UI.CreateFrame("Texture", "", button)
		button.icon:SetPoint("TOPLEFT", button, "TOPLEFT", border, border)
		button.icon:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", -border, -border)
		
		button.stackText = UI.CreateFrame("Text", "", button)
		button.stackText:SetPoint("BOTTOMRIGHT", button.icon, "BOTTOMRIGHT", 0, 0)
		button.stackText:SetFontSize(13)
		button.stackText:SetBackgroundColor(0.0, 0.0, 0.0, 0.5)
		button.stackText:SetLayer(button:GetLayer() + 1)
		
		button.slotsText = UI.CreateFrame("Text", "", button)
		button.slotsText:SetPoint("BOTTOMRIGHT", button.stackText, "TOPRIGHT", 0, 0)
		button.slotsText:SetFontSize(10)
		button.slotsText:SetBackgroundColor(0.0, 0.0, 0.0, 0.5)
		button.slotsText:SetFontColor(0.8, 0.8, 0.8)
		button.slotsText:SetLayer(button:GetLayer() + 1)
		button.slotsText:SetMouseMasking("limited")
		
		button.SetItem = ItemButton_SetItem
		button.Dispose = ItemButton_Dispose
		button.ShowTooltip = ItemButton_ShowTooltip
		
		button.Event.MouseMove = ItemButton_MouseMove
		button.Event.MouseOut = ItemButton_MouseOut
		button.Event.MouseIn = ItemButton_MouseIn
		button.Event.LeftDown = ItemButton_LeftDown
		button.Event.LeftUp = ItemButton_LeftUp
		button.Event.RightDown = ItemButton_RightDown
		button.Event.RightUp = ItemButton_RightUp
		button.Event.RightUpoutside = ItemButton_RightUpoutside
	else
		button = table.remove(cachedButtons)
		button:SetVisible(true)
		button:SetParent(parent)
	end
	return button
end
