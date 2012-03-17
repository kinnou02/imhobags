local Addon, private = ...

local math = math
local pairs = pairs
local table = table

local dump  = dump
local Event = Event
local Inspect = Inspect
local UI = UI

setfenv(1, private)
Ux = Ux or { }
Ux.CharSelector = { }

local borderWidth = 2

-- Private methods
-- ============================================================================

local function showMenu(self)
	self.menu:SetVisible(true)
	self.menu:SetWidth(math.max(self:GetWidth(), self.menu.contentWidth))
end

local function getButton(self, i)
	if(self.menu.buttons[i]) then
		return self.menu.buttons[i]
	else
		local btn = UI.CreateFrame("Frame", "", self.menu)
		local label = UI.CreateFrame("Text", "", btn)
		label:SetFontSize(14)
		label:SetPoint("CENTER", btn, "CENTER")
		label:SetText("X")
		btn.label = label
		
		if(i == 1) then
			btn:SetPoint("TOPLEFT", self.menu.background, "TOPLEFT")
			btn:SetPoint("TOPRIGHT", self.menu.background, "TOPRIGHT")
		else
			btn:SetPoint("TOPLEFT", self.menu.buttons[i - 1], "BOTTOMLEFT")
			btn:SetPoint("TOPRIGHT", self.menu.buttons[i - 1], "BOTTOMRIGHT")
		end

		btn:SetLayer(self.menu.background:GetLayer() + 1)
		
		function btn.Event:MouseIn()
			btn:SetBackgroundColor(1, 1, 1, 0.3)
		end
		function btn.Event:MouseOut()
			btn:SetBackgroundColor(1, 1, 1, 0)
		end
		function btn.Event.LeftDown()
			btn:SetBackgroundColor(1, 1, 1, 0)
			self.menu:SetVisible(false)
			self:SetText(label:GetText())
			self.callback(label:GetText())
		end
		table.insert(self.menu.buttons, btn)
		return btn
	end
end

local function updateMenu(self)
	local chars = ItemDB.GetAvailableCharacters()
	
	local width, height = 0, 0
	for i = 1, #chars do
		local btn = getButton(self, i)
		btn.label:SetText(chars[i])
		btn:SetVisible(true)
		btn:SetHeight(btn.label:GetFullHeight())
		
		height = height + btn:GetHeight()
		width = width + btn.label:GetFullWidth()
	end
	for i = #chars + 1, #self.menu.buttons do
		self.menu.buttons[i]:SetVisible(false)
	end
	self.menu:SetWidth(math.max(width, self:GetWidth()))
	self.menu:SetHeight(height + 2 * borderWidth)
end

-- Public methods
-- ============================================================================

function Ux.CharSelector.New(parent, current, callback)
	local frame = UI.CreateFrame("RiftButton", "", parent)
	frame:SetText(current)
	frame.callback = callback
	
	frame.Event.LeftPress = showMenu
	
	local menu = UI.CreateFrame("Frame", "", parent)
	menu:SetLayer(100)
	frame.menu = menu
	menu:SetPoint("CENTER", frame, "CENTER")
	menu:SetBackgroundColor(0.6, 0.6, 0.6)
	menu.contentWidth = 0
	menu:SetVisible(false)
	menu.background = UI.CreateFrame("Frame", "", menu)
	menu.background:SetPoint("TOPLEFT", menu, "TOPLEFT", borderWidth + 1, borderWidth + 1)
	menu.background:SetPoint("BOTTOMRIGHT", menu, "BOTTOMRIGHT", -borderWidth, -borderWidth)
	menu.background:SetBackgroundColor(0, 0, 0)
	
	menu.buttons = { }
	
	updateMenu(frame)
	
	table.insert(ImhoEvent.Config, { function(name)
		if(name == "showEnemyFaction") then
			updateMenu(frame)
		end
	end, Addon.identifier, "Ux.CharSelector_updateMenu" })
	
	return frame
end
