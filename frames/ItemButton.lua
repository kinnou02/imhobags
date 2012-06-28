local Addon, private = ...

-- Builtins
local type = type

-- Globals
local Command = Command
local Inspect = Inspect
local UIParent = UIParent

-- Frames cannot be deleted, keep a cache and only create new frames if the cache is empty
-- Calling Dispose() on a button moves it back to the cache
local cachedButtons = { }

setfenv(1, private)
Ux = Ux or { }
Ux.ItemButton = { }

Ux.ItemButtonSizeDefault = 50
Ux.ItemButtonSizeJunk = 30
Ux.ItemButtonDragDistance = 15

-- Private methods
-- ============================================================================

local skinFactory

local leftDownPoint = { x = 0, y = 0 }

local function mouseMove(self)
	self:ShowTooltip()
	self:ShowHighlight()
	if(self.pickingUp) then
		local mouse = Inspect.Mouse()
		local distance = (leftDownPoint.x - mouse.x) * (leftDownPoint.x - mouse.x) + (leftDownPoint.y - mouse.y) * (leftDownPoint.y - mouse.y)
		if(distance > Ux.ItemButtonDragDistance * Ux.ItemButtonDragDistance) then
			ItemHandler.Standard.Drag(self.pickingUp)
			self.pickingUp = nil
		end
	end
end

local function mouseOut(self)
	self:SetDepressed(false)
	Command.Tooltip(nil)
	Ux.TooltipEnhancer:SetVisible(false)
	self.tooltip = false
	self:SetHighlighted(false)
end

local function mouseIn(self)
	self.tooltip = true
	self:ShowTooltip()
	self:SetHighlighted(true)
end

local function leftDown(self)
	local mouse = Inspect.Mouse()
	leftDownPoint.x = mouse.x
	leftDownPoint.y = mouse.y
	self:SetDepressed(true)
	if(self.available) then
		if(Inspect.Cursor() == "item") then
			ItemHandler.Standard.Drop(self.item.id)
		elseif(not Inspect.Cursor()) then
			self.pickingUp = self.item.id
		end
	end
end

local function leftUp(self)
	self:SetDepressed(false)
	if(self.pickingUp) then
		ItemHandler.Standard.Left(self.pickingUp)
		self.pickingUp = nil
	elseif(Inspect.Cursor() == "item" and self.available) then
		ItemHandler.Standard.Drop(self.item.id)
	end
	self.commandTarget = nil
end

local function leftUpoutside(self)
	self.pickingUp = nil
end

local function rightDown(self)
	self:SetDepressed(true)
	if(self.available) then
		self.commandTarget = self.item.id
	end
end

local function rightUp(self)
	self:SetDepressed(false)
	if(self.commandTarget) then
		ItemHandler.Standard.Right(self.commandTarget)
	end
	self.commandTarget = nil
end

local function rightUpoutside(self)
	self.commandTarget = nil
end

-- Public methods
-- ============================================================================

local function ItemButton_SetItem(self, item, slots, stack, available)
	self.readonly = type(slots) ~= "table" -- Reflects whether the item matrix allows manipulation
	self.available = available -- Reflects whether the location is available to the player
	self:SetAvailable(available)
	
	if(not self.item or self.item.icon ~= item.icon) then
		self:SetIcon(item.icon)
	end
	if(not self.item or self.item.rarity ~= item.rarity) then
		self:SetRarity(item.rarity)
	end
	self:SetStack(stack)
	self:SetSlots(not self.readonly and #slots or slots)
	self:SetBound(Config.showBoundIcon and item.bound, item.bind)

	self.item = item
	self.slots = slots
	self.stack = stack
end

local function ItemButton_Dispose(self)
	cachedButtons[#cachedButtons + 1] = self
	self:SetVisible(false)
end

local function ItemButton_ShowTooltip(self)
	if(self.tooltip) then
		local target
		if(not self.item.type) then
			local mouse = Inspect.Mouse()
			Ux.TooltipEnhancer:ClearAll()
			Ux.TooltipEnhancer:SetText(self.item.name)
			Ux.TooltipEnhancer:SetVisible(true)
			Ux.TooltipEnhancer:SetPoint("BOTTOMRIGHT", UIParent, "TOPLEFT", mouse.x, mouse.y)
		elseif(self.readonly) then
			target = self.item.type
		else
			target = self.item.id
		end
		Command.Tooltip(target)
		log("TODO", "position tooltip near button")
	end
end

function Ux.ItemButton.New(parent)
	local button
	if(#cachedButtons == 0) then
		button = skinFactory(parent)
		
		button:SetMouseMasking("limited")
		
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
		button = cachedButtons[#cachedButtons]
		cachedButtons[#cachedButtons] = nil
		button:SetVisible(true)
		button:SetParent(parent)
	end
	return button
end

ImhoEvent.Init[#ImhoEvent.Init + 1] = { function() skinFactory = Ux["ItemButton_" .. Config.itemButtonSkin].New end, Addon.identifier, "" }
