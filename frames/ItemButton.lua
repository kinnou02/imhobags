local Addon, private = ...

-- Frames cannot be deleted, keep a cache and only create new frames if the cache is empty
-- Calling Dispose() on a button moves it back to the cache
local cachedButtons = { }
local usedButtons = { }
local createButton
-- Specialized animation template for SetPoint(self, point, target, point, x, y)
local moveAnimationTemplate = LibAnimate.CreateTemplate({ false, false, false, false, "easeOutCubic", "easeOutCubic" })

setfenv(1, private)
Ux = Ux or { }
Ux.ItemButton = { }

-- Private methods
-- ============================================================================

local skinFactory

local leftDownPoint = { x = 0, y = 0 }


local mouseMoves = { }
local function mouseMove(self)
	-- create the thread (a function)
  local mouseMoveInstance = coroutine.create( 
  	function (self)
			if Inspect.System.Watchdog() < 0.02 then
				coroutine.yield()
			end
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
	)

  -- Run the thread.  If it is suspended immediately, then add it to 'dispatches' for handling at the System.Update.Begin event.
	coroutine.resume(mouseMoveInstance,self)
	if coroutine.status(mouseMoveInstance) == 'suspended' then
  	mouseMoves[#mouseMoves + 1] = mouseMoveInstance
  end
  
  -- See systemUpdateBegin() for handling of suspended threads
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
	self:SetDepressed(false)
	self:SetHighlighted(false)
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
	if(self.item and self.available) then
		ItemHandler.Standard.Right(self.dropTarget)
	end
end

local function storageLoaded(handle)
	skinFactory = Ux["ItemButton_" .. Config.itemButtonSkin].New
	-- Preload buttons to avoid the Watchdog later
	for i = 1, Const.ItemButtonWarmupCache do
		local button = createButton(Ux.Context)
		button:SetVisible(false)
		cachedButtons[button] = true
	end
end

local function configChanged(handle, k, v)
	if(k == "showBoundIcon") then
		for button in pairs(usedButtons) do
			button.bind:SetVisible(v)
		end
	end
end

local function systemUpdateBegin(self)
	if (#mouseMoves > 0) then
		for i = 1, #mouseMoves do
			local thread = mouseMoves[i]
			if thread and type(thread) == 'thread' then
				local status = coroutine.status(thread)
				--print(string.format("DEBUG:  #mouseMoves: %d -- type(thread): %s -- status: %s -- i: %d",#mouseMoves,type(thread), tostring(status), i))
				if status == 'suspended' then
					coroutine.resume(thread)
				elseif status == 'dead' then
					table.remove(mouseMoves,i)
				end
			end
		end
  end
end

-- Public methods
-- ============================================================================

local function MoveToGrid(self, target, x, y, spacing, duration)
	if(self.gridTarget == target and self.gridx == x and self.gridy == y) then
		return
	end
	self.gridx = x
	self.gridy = y
	self.gridTarget = target
	self.moveAnimation:Stop()
	local currentx = self:GetLeft() - target:GetLeft()
	local currenty = self:GetTop() - target:GetBottom()
	local targetx = x * (self:GetWidth() + spacing)
	local targety = y * (self:GetHeight() + spacing)
	if(duration and duration > 0) then
		self.moveAnimation:Start(duration, { self, "TOPLEFT", target, "BOTTOMLEFT", currentx, currenty }, { nil, nil, nil, nil, targetx, targety })
	else
		self:SetPoint("TOPLEFT", target, "BOTTOMLEFT", targetx, targety)
	end
end

local function SetItem(self, item, slots, stack, available, locked)
	local isTable = type(slots) == "table"
--	self.locked = locked or not isTable -- Reflects whether the item is movable with mouse actions
	self.available = available -- Reflects whether the item is available to the player
	
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
	self.dropTarget = isTable and slots[1] or slots
end

local function Dispose(self, duration)
	self.gridx = -1
	self.gridy = -1
	self.gridTarget = nil
	self.moveAnimation:Stop()
	self.fadeAnimation:Stop()
	self.fadeAnimation = self:AnimateAlpha(self:GetAlpha() * (duration or 0), "linear", 0, function()
		usedButtons[self] = nil
		cachedButtons[self] = true
		self:SetVisible(false)
	end)
end

local function ShowTooltip(self)
	if(self.tooltip) then
		local target
		if type(self.item) == "table" then
			if(not self.item.type) then
				local mouse = Inspect.Mouse()
				Ux.TooltipEnhancer:ClearAll()
				Ux.TooltipEnhancer:SetText(self.item.name)
				Ux.TooltipEnhancer:SetVisible(true)
				Ux.TooltipEnhancer:SetPoint("BOTTOMRIGHT", UIParent, "TOPLEFT", mouse.x, mouse.y)
	--		elseif(self.locked) then
	--			target = self.item.type
			else
				target = self.item.id or self.item.type
			end
		end
		Command.Tooltip(target)
	end
end

local function SetLocked(self, locked)
--	self.locked = locked
end

function Ux.ItemButton.New(parent, available, duration)
	local button = next(cachedButtons)
	if(not button) then
		button = createButton(parent)
	else
		cachedButtons[button] = nil
		button:SetVisible(true)
		button:SetParent(parent)
	end
	usedButtons[button] = true
	button.available = available
	button:SetAlpha(0)
	button.fadeAnimation = button:AnimateAlpha(duration, "linear", available and 1.0 or Const.ItemButtonUnavailableAlpha)
	return button
end

createButton = function(parent)
	local self = skinFactory(parent)
	self.moveAnimation = LibAnimate.CreateAnimation(moveAnimationTemplate, self.SetPoint, Const.AnimationsDuration)
	self.fadeAnimation = LibAnimate.CreateEmptyAnimation()
	self.gridx = -1
	self.gridy = -1
	self.gridTarget = nil
	
	self:SetMouseMasking("limited")
	
	self.Dispose = Dispose
	self.MoveToGrid = MoveToGrid
	self.SetItem = SetItem
	self.SetLocked = SetLocked
	self.ShowTooltip = ShowTooltip
	
	self:EventAttach(Event.UI.Input.Mouse.Cursor.Move, mouseMove, "")
	self:EventAttach(Event.UI.Input.Mouse.Cursor.Out,  mouseOut, "")
	self:EventAttach(Event.UI.Input.Mouse.Cursor.In, mouseIn, "")
	self:EventAttach(Event.UI.Input.Mouse.Left.Down, leftDown, "")
	self:EventAttach(Event.UI.Input.Mouse.Left.Up, leftUp, "")
	self:EventAttach(Event.UI.Input.Mouse.Left.Upoutside, leftUpoutside, "")
	self:EventAttach(Event.UI.Input.Mouse.Right.Down, rightDown, "")
	self:EventAttach(Event.UI.Input.Mouse.Right.Up, rightUp, "")
	self:EventAttach(Event.UI.Input.Mouse.Right.Upoutside, rightUpoutside, "")
	self:EventAttach(Event.UI.Input.Mouse.Right.Click, rightClick, "")
	
	return self
end

Command.Event.Attach(Event.ImhoBags.Private.StorageLoaded, storageLoaded, "ItemButton.storageLoaded")
Command.Event.Attach(Event.ImhoBags.Private.Config, configChanged, "ItemButton.configChanged")
Command.Event.Attach(Event.System.Update.Begin, function() systemUpdateBegin(self) end, "ItemButton.systemUpdateBegin")