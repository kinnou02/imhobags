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

-- Private methods
-- ============================================================================

local skinFactory

local leftDownPoint = { x = 0, y = 0 }

local function mouseMove(self)
	self:ShowTooltip()
	if(self.available and self.leftDown) then
		local mouse = Inspect.Mouse()
		local distance = (leftDownPoint.x - mouse.x) * (leftDownPoint.x - mouse.x) + (leftDownPoint.y - mouse.y) * (leftDownPoint.y - mouse.y)
		if(distance >= Const.ItemButtonDragDistance) then
			ItemHandler.Standard.Drag(self.dropTarget)
			self.leftDown = false
			self:SetDepressed(false)
		end
	end
	if(self.item or (Inspect.Cursor()) == "item") then
		self:ShowHighlight()
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
	if(self.rightDown or self.leftDown) then
		self:SetDepressed(true)
	end
	if(self.item or (Inspect.Cursor()) == "item") then
		self:SetHighlighted(true)
		if(self.item) then
			self.tooltip = true
			self:ShowTooltip()
		end
	end
end

local function leftDown(self)
	if(self.available) then
		if(Inspect.Cursor()) then
			ItemHandler.Standard.Drop(self.dropTarget)
		elseif(self.item) then
			self:SetDepressed(true)
			self.leftDown = true
			leftDownPoint = Inspect.Mouse()
		end
	end
end

local function leftUp(self)
	if(self.leftDown) then
		ItemHandler.Standard.Left(self.dropTarget)
	elseif(Inspect.Cursor()) then
		ItemHandler.Standard.Drop(self.dropTarget)
	end
	self.leftDown = false
	self:SetDepressed(false)
end

local function leftUpoutside(self)
	self.leftDown = false
end

local function rightDown(self)
	if(self.item and self.available) then
		self:SetDepressed(true)
		self.rightDown = true
	end
end

local function rightUp(self)
	self:SetDepressed(false)
	self.rightDown = false
end

local function rightUpoutside(self)
	self.rightDown = false
end

local function rightClick(self)
	ItemHandler.Standard.Right(self.dropTarget)
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

local function ItemButton_SetItem(self, item, slots, stack, available, locked)
	local isTable = type(slots) == "table"
	self.locked = locked or not isTable -- Reflects whether the item matrix allows manipulation
	self.available = available -- Reflects whether the location is available to the player
	
	if(not item) then
		self:SetStack(1)
		self:SetSlots(1)
		self:SetBound(false, nil)
		self:SetIcon("")
		self:SetRarity("empty")
		self:SetFiltered(false)
	else
		if(not self.item or self.item.icon ~= item.icon) then
			self:SetIcon(item.icon)
		end
		if(not self.item or self.item.rarity ~= item.rarity) then
			self:SetRarity(item.rarity)
		end
		self:SetStack(stack)
		self:SetSlots(isTable and #slots or 1)
		self:SetBound(Config.showBoundIcon and item.bound, item.bind)
	end
	self.item = item
	self.slots = slots
	self.stack = stack
	self.dropTarget = item and item.id or (isTable and slots[1] or slots)
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
		elseif(self.locked) then
			target = self.item.type
		else
			target = self.dropTarget
		end
		Command.Tooltip(target)
	end
end

local function SetLocked(self, locked)
	self.locked = locked
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
		button.Event.LeftClick = leftClick
		button.Event.RightDown = rightDown
		button.Event.RightUp = rightUp
		button.Event.RightUpoutside = rightUpoutside
		button.Event.RightClick = rightClick
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
