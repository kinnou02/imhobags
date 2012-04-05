local Addon, private = ...

local max = math.max
local type = type

local UICreateFrame = UI.CreateFrame

setfenv(1, private)
Ux = Ux or { }
Ux.OptionSelector = { }

local borderWidth = 2

-- Private methods
-- ============================================================================

local function getButton(self, i)
	if(self.menu.buttons[i]) then
		return self.menu.buttons[i]
	else
		local btn = UICreateFrame("Frame", "", self.menu)
		local label = UICreateFrame("Text", "", btn)
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
			self.callback(label:GetText())
		end
		self.menu.buttons[#self.menu.buttons + 1] = btn
		return btn
	end
end

local function updateMenu(self)
	local options
	if(type(self.options) == "function") then
		options = self.options()
	else
		options = self.options
	end
	
	local width, height = 0, 0
	for i = 1, #options do
		local btn = getButton(self, i)
		btn.label:SetText(options[i])
		btn:SetVisible(true)
		btn:SetHeight(btn.label:GetHeight())
		
		height = height + btn:GetHeight()
		width = max(width, btn.label:GetWidth())
	end
	for i = #options + 1, #self.menu.buttons do
		self.menu.buttons[i]:SetVisible(false)
	end
	self.menu:SetWidth(max(width + 10, self:GetWidth()))
	self.menu:SetHeight(height + 2 * borderWidth)
end

local function showMenu(self)
	if(self.menu:GetVisible()) then
		self.menu:SetVisible(false)
	else
		updateMenu(self)
		self.menu:SetVisible(true)
		self.menu:SetWidth(max(self:GetWidth(), self.menu:GetWidth()))
	end
end

-- Public methods
-- ============================================================================

function Ux.OptionSelector.New(parent, icon, options, callback)
	local self = Ux.IconButton.New(parent, icon)
	self.callback = callback
	self.options = options
	
	self.LeftPress = showMenu
	self.UpdateMenu = updateMenu
	
	local menu = UICreateFrame("Frame", "", parent)
	menu:SetLayer(100)
	self.menu = menu
	menu:SetPoint("CENTER", self, "CENTER")
	menu:SetBackgroundColor(0.6, 0.6, 0.6)
	menu:SetVisible(false)
	menu.background = UICreateFrame("Frame", "", menu)
	menu.background:SetPoint("TOPLEFT", menu, "TOPLEFT", borderWidth + 1, borderWidth + 1)
	menu.background:SetPoint("BOTTOMRIGHT", menu, "BOTTOMRIGHT", -borderWidth, -borderWidth)
	menu.background:SetBackgroundColor(0, 0, 0)
	
	menu.buttons = { }
	
	updateMenu(self)
	
	ImhoEvent.Config[#ImhoEvent.Config + 1] = { function(name)
		updateMenu(self, options)
	end, Addon.identifier, "Ux.OptionSelector_updateMenu" }
	
	return self
end
