local Addon, private = ...

-- Locals
local groupCache = { }
-- Specialized animation template for (self, target, x, y, width)
local moveAnimationTemplate = LibAnimate.CreateTemplate({ false, false, "easeOutCubic", "easeOutCubic", "easeOutCubic" })

setfenv(1, private)
ItemContainer = ItemContainer or { }

-- Private methods
-- ============================================================================

local function moveAnimationFunction(self, target, x, y, width)
	self:SetPoint("TOPLEFT", target, "TOPLEFT", x, y)
	self:SetWidth(width)
end

-- Public methods
-- ============================================================================

local function MoveToGrid(self, line, x, y, dx, dy, spacing, width, duration)
	local targetx = x * (dx + spacing)
	local targety = y * (dy + spacing) + line * self:GetHeight()
	local currentx = self:GetLeft() - self:GetParent():GetLeft()
	local currenty = self:GetTop() - self:GetParent():GetTop()
	self.width = width
	self.moveAnimation:Stop()
	if(duration and duration > 0) then
		self.moveAnimation:Start(duration, { self, self:GetParent(), currentx, currenty, self:GetWidth() }, { nil, nil, targetx, targety, width })
	else
		moveAnimationFunction(self, self:GetParent(), targetx, targety, width)
	end
end

local function Rearrange(self, duration, dx, spacing)
	local x, y = 0, 0
	local columns = math.floor((self.width + spacing) / (dx + spacing))
	for i = 1, #self.buttons do
		local button = self.buttons[i]
		button:MoveToGrid(self, x, y, spacing, duration)
		x = x + 1
		if(x >= columns) then
			x = 0
			y = y + 1
		end
	end
end

local function SetButtons(self, duration, alive, prealive, buttons, dx, spacing)
	-- Don't use Rearrange as some buttons may be new
	local x, y = 0, 0
	local columns = math.floor((self.width + spacing) / (dx + spacing))
	for i = 1, #buttons do
		local button = buttons[i]
		-- Buttons which were not alive previously are moved instantly
		button:MoveToGrid(self, x, y, spacing, prealive[button] and duration)
		x = x + 1
		if(x >= columns) then
			x = 0
			y = y + 1
		end
	end
	-- Hide buttons which are no longer alive
	for i = 1, #self.buttons do
		local button = self.buttons[i]
		if(not alive[button]) then
			button:Dispose(duration)
		end
	end
	self.buttons = buttons
end

local function Dispose(self, duration, alive)
	local cache = groupCache[self.factory]
	
	self.moveAnimation:Stop()
	self.fadeAnimation:Stop()
	alive = alive or { }
	for i = 1, #self.buttons do
		local button = self.buttons[i]
		if(not alive[button]) then
			button:Dispose(duration)
		end
	end
	self.buttons = { }
	self.fadeAnimation = self:AnimateAlpha(self:GetAlpha() * (duration or 0), "linear", 0, function()
		self:SetVisible(false)
		cache[self] = true
	end)
end

local empty = { }
function ItemContainer.Group(parent, factory, duration)
	groupCache[factory] = groupCache[factory] or { }
	
	local cache = groupCache[factory]
	local self = next(cache)
	if(not self) then
		self = factory(parent)
		self.buttons = { }
		self.moveAnimation = LibAnimate.CreateAnimation(moveAnimationTemplate, moveAnimationFunction)
		self.factory = factory
		
		self.SetPosition = SetPosition
		self.SetButtons = SetButtons
		self.Dispose = Dispose
		self.Rearrange = Rearrange
		self.MoveToGrid = MoveToGrid
	else
		cache[self] = nil
		self:SetVisible(true)
		self:SetParent(parent)
	end
	self:SetAlpha(0)
	self.fadeAnimation = self:AnimateAlpha(duration, "linear", 1)
	return self
end
