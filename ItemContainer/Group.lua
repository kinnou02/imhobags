local Addon, private = ...

-- Builtins
local floor = math.floor

-- Globals
local UICreateFrame = UI.CreateFrame

-- Locals
local groupCache = { }

setfenv(1, private)
ItemContainer = ItemContainer or { }

-- Private methods
-- ============================================================================

-- Public methods
-- ============================================================================

local function MoveToGrid(self, line, x, y, dx, dy, spacing, width, duration)
	Animate.stop(self.moveAnimation)
	local targetx = x * (dx + spacing)
	local targety = y * (dy + spacing) + line * self:GetHeight()
	self.width = width
	if(duration and duration > 0) then
		local currentx = self:GetLeft() - self:GetParent():GetLeft()
		local currenty = self:GetTop() - self:GetParent():GetTop()
		self.moveAnimation = Animate.easeOut({ currentx, currenty, self:GetWidth() }, { targetx, targety, width }, duration,
			function(t) self:SetPoint("TOPLEFT", self:GetParent(), "TOPLEFT", t[1], t[2]) self:SetWidth(t[3]) end,
			function() self.moveAnimation = 0 end)
	else
		self.moveAnimation = 0
		self:SetPoint("TOPLEFT", self:GetParent(), "TOPLEFT", targetx, targety)
		self:SetWidth(width)
	end
end

local function Rearrange(self, duration, dx, spacing)
	local x, y = 0, 0
	local columns = floor((self.width + spacing) / (dx + spacing))
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
	local columns = floor((self.width + spacing) / (dx + spacing))
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
	local function dispose()
		self:SetVisible(false)
		cache[#cache + 1] = self
	end
	
	Animate.stop(self.moveAnimation)
	Animate.stop(self.fadeAnimation)
	self.moveAnimation = 0
	self.fadeAnimation = 0
	alive = alive or { }
	for i = 1, #self.buttons do
		local button = self.buttons[i]
		if(not alive[button]) then
			button:Dispose(duration)
		end
	end
	self.buttons = { }
	if(duration and duration > 0) then
		Animate.lerp(self:GetAlpha(), 0, self:GetAlpha() * duration, function(t) self:SetAlpha(t) end, dispose)
	else
		dispose()
	end
end

local empty = { }
function ItemContainer.Group(parent, factory, duration)
	groupCache[factory] = groupCache[factory] or { }
	
	local self
	local cache = groupCache[factory]
	if(#cache > 0) then
		self = cache[#cache]
		cache[#cache] = nil
		self:SetVisible(true)
	else
		self = factory(parent)
		self.buttons = { }
		self.moveAnimation = 0
		self.fadeAnimation = 0
		self.factory = factory
		
		self.SetPosition = SetPosition
		self.SetButtons = SetButtons
		self.Dispose = Dispose
		self.Rearrange = Rearrange
		self.MoveToGrid = MoveToGrid
	end
	if(duration and duration > 0) then
		self:SetAlpha(0)
		self.fadeAnimation = Animate.lerp(0, 1, self:GetAlpha() * duration, function(t) self:SetAlpha(t) end, function() self.fadeAnimation = 0 end)
	else
		self:SetAlpha(1)
	end
	return self
end
