local Addon, private = ...

local _G = _G
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

setfenv(1, private)
Ux = Ux or { }
Ux.ItemButton = { }

Ux.ItemButtonWidth = 50
Ux.ItemButtonHeight = 50
Ux.ItemButtonBorder = 2

-- Private methods
-- ============================================================================

local function mouseMove(self)
	self.moved = true
	self:ShowTooltip()
	if(self.pickingUp) then
		Command.Cursor(self.pickingUp)
		self.pickingUp = nil
	end
end

local function mouseOut(self)
	Command.Tooltip(nil)
	self.tooltip = false
end

local function mouseIn(self)
	self.tooltip = true
	self:ShowTooltip()
end

local function leftDown(self)
	self.moved = false
	if(self.notLocked) then
		self.pickingUp = Inspect.Item.Detail(self.slots[1]).id
	end
end

local function leftUp(self)
	local cursor, held = Inspect.Cursor()
	if(self.moved and cursor == "item" and self.notLocked) then
		Command.Item.Move(held, self.slots[1])
	elseif(self.pickingUp) then
		Command.Cursor(self.pickingUp)
		self.pickingUp = nil
	end
	self.moved = false
	self.commandTarget = nil
end

local function rightDown(self)
	if(self.notLocked) then
		self.commandTarget = self.slots[1]
	end
end

local function rightUp(self)
	if(self.commandTarget) then
		log("TODO", "use item")
	end
	self.commandTarget = nil
end

local function rightUpoutside(self)
	self.commandTarget = nil
end

-- Public methods
-- ============================================================================

local function ItemButton_SetItem(self, type, slots, stack, notLocked)
	self.type = type
	self.slots = slots
	self.stack = stack
	
	self.readonly = _G.type(slots) ~= "table" -- Reflects whether the item matrix allows manipulation
	self.notLocked = notLocked -- Reflects whether the location is available to the player
	
	self.icon:SetTexture("Rift", type.icon)
	
	self.stackText:SetText(tostring(stack))
	self.stackText:SetVisible(stack > 1)

	if(not self.readonly) then
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
		if(self.readonly) then
			target = self.type.type
		else
			target = Inspect.Item.Detail(self.slots[1]).id
		end
		Command.Tooltip(target)
		log("TODO", "position tooltip near button")
	end
end

function Ux.ItemButton.New(parent)
	local button
	if(#cachedButtons == 0) then
		button = UI.CreateFrame("Frame", "ImhoBags_ItemButton", parent)
		
		button:SetWidth(Ux.ItemButtonWidth)
		button:SetHeight(Ux.ItemButtonHeight)
		button:SetMouseMasking("limited")
		
		local border = Ux.ItemButtonBorder
		local backdrop = UI.CreateFrame("Frame", "", button)
		backdrop:SetBackgroundColor(0.0, 0.0, 0.0)
		backdrop:SetPoint("TOPLEFT", button, "TOPLEFT", border, border)
		backdrop:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", -border, -border)
		
		button.icon = UI.CreateFrame("Texture", "", backdrop)
		button.icon:SetAllPoints(backdrop)

		button.stackText = UI.CreateFrame("Text", "", button.icon)
		button.stackText:SetPoint("BOTTOMRIGHT", button.icon, "BOTTOMRIGHT", 0, 0)
		button.stackText:SetFontSize(13)
		button.stackText:SetBackgroundColor(0.0, 0.0, 0.0, 0.5)
--		button.stackText:SetLayer(button:GetLayer() + 1)
		
		button.slotsText = UI.CreateFrame("Text", "", button.icon)
		button.slotsText:SetPoint("BOTTOMRIGHT", button.stackText, "TOPRIGHT", 0, 0)
		button.slotsText:SetFontSize(10)
		button.slotsText:SetBackgroundColor(0.0, 0.0, 0.0, 0.5)
		button.slotsText:SetFontColor(0.8, 0.8, 0.8)
		button.slotsText:SetLayer(button:GetLayer() + 1)
--		button.slotsText:SetMouseMasking("limited")
		
		button.SetItem = ItemButton_SetItem
		button.Dispose = ItemButton_Dispose
		button.ShowTooltip = ItemButton_ShowTooltip
		
		button.Event.MouseMove = mouseMove
		button.Event.MouseOut = mouseOut
		button.Event.MouseIn = mouseIn
		button.Event.LeftDown = leftDown
		button.Event.LeftUp = leftUp
		button.Event.RightDown = rightDown
		button.Event.RightUp = rightUp
		button.Event.RightUpoutside = rightUpoutside
	else
		button = table.remove(cachedButtons)
		button:SetVisible(true)
		button:SetParent(parent)
	end
	return button
end
