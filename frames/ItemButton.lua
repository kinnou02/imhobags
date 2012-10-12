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

local function ItemButton_MoveToGrid(self, target, x, y, spacing, duration)
	if(self.gridTarget == target and self.gridx == x and self.gridy == y) then
		return
	end
	self.gridx = x
	self.gridy = y
	self.gridTarget = target
	Animate.stop(self.moveAnimation)
	local currentx = self:GetLeft() - target:GetLeft()
	local currenty = self:GetTop() - target:GetBottom()
	local targetx = x * (self:GetWidth() + spacing)
	local targety = y * (self:GetHeight() + spacing)
	if(duration and duration > 0) then
		self.moveAnimation = Animate.easeOut({ currentx, currenty }, { targetx, targety }, duration,
			function(t) self:SetPoint("TOPLEFT", target, "BOTTOMLEFT", t[1], t[2]) end,
			function() self.moveAnimation = 0 end)
	else
		self.moveAnimation = 0
		self:SetPoint("TOPLEFT", target, "BOTTOMLEFT", targetx, targety)
	end
end

local function ItemButton_SetItem(self, item, slots, stack, available, duration)
	self.readonly = type(slots) ~= "table" -- Reflects whether the item matrix allows manipulation
	self.available = available -- Reflects whether the location is available to the player
	
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

local function ItemButton_Dispose(self, duration)
	local function dispose()
		cachedButtons[#cachedButtons + 1] = self
		self:SetVisible(false)
	end
	self.gridx = -1
	self.gridy = -1
	self.gridTarget = nil
	Animate.stop(self.moveAnimation)
	Animate.stop(self.fadeAnimation)
	self.moveAnimation = 0
	self.fadeAnimation = 0
	if(duration and duration > 0) then
		Animate.lerp(self:GetAlpha(), 0, self:GetAlpha() * duration, function(t) self:SetAlpha(t) end, dispose)
	else
		dispose()
	end
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
	end
end

function Ux.ItemButton.New(parent, available, duration)
	local button
	if(#cachedButtons == 0) then
		button = skinFactory(parent)
		button.moveAnimation = 0
		button.fadeAnimation = 0
		button.gridx = -1
		button.gridy = -1
		button.gridTarget = nil
		
		button:SetMouseMasking("limited")
		
		button.Dispose = ItemButton_Dispose
		button.MoveToGrid = ItemButton_MoveToGrid
		button.SetItem = ItemButton_SetItem
		button.SetLocked = SetLocked
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
	button.available = available
	if(duration and duration > 0) then
		button:SetAlpha(0)
		button.fadeAnimation = Animate.lerp(0, available and 1.0 or Const.ItemButtonUnavailableAlpha, duration, function(t) button:SetAlpha(t) end, function() button.fadeAnimation = 0 end)
	else
		button:SetAlpha(available and 1.0 or Const.ItemButtonUnavailableAlpha)
	end
	return button
end

ImhoEvent.Init[#ImhoEvent.Init + 1] = { function() skinFactory = Ux["ItemButton_" .. Config.itemButtonSkin].New end, Addon.identifier, "" }
