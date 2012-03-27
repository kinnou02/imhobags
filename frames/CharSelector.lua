local Addon, private = ...

local max = math.max

local UICreateFrame = UI.CreateFrame

setfenv(1, private)
Ux = Ux or { }
Ux.CharSelector = { }

local borderWidth = 2

-- Private methods
-- ============================================================================

local function showMenu(self)
	self.menu:SetVisible(true)
	self.menu:SetWidth(max(self:GetWidth(), self.menu.contentWidth) + 10)
end

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
	self.menu:SetWidth(max(width, self:GetWidth()))
	self.menu:SetHeight(height + 2 * borderWidth)
end

-- Public methods
-- ============================================================================

function Ux.CharSelector.New(parent, current, callback)
	local self = Ux.IconButton.New(parent, [[Data/\UI\ability_icons\combat_survival.dds]])
	self.callback = callback
	
	self.LeftPress = showMenu
	
	local menu = UICreateFrame("Frame", "", parent)
	menu:SetLayer(100)
	self.menu = menu
	menu:SetPoint("CENTER", self, "CENTER")
	menu:SetBackgroundColor(0.6, 0.6, 0.6)
	menu.contentWidth = 0
	menu:SetVisible(false)
	menu.background = UICreateFrame("Frame", "", menu)
	menu.background:SetPoint("TOPLEFT", menu, "TOPLEFT", borderWidth + 1, borderWidth + 1)
	menu.background:SetPoint("BOTTOMRIGHT", menu, "BOTTOMRIGHT", -borderWidth, -borderWidth)
	menu.background:SetBackgroundColor(0, 0, 0)
	
	menu.buttons = { }
	
	updateMenu(self)
	
	ImhoEvent.Config[#ImhoEvent.Config + 1] = { function(name)
		if(name == "showEnemyFaction") then
			updateMenu(self)
		end
	end, Addon.identifier, "Ux.CharSelector_updateMenu" }
	
	return self
end
