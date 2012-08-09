local Addon, private = ...

-- Builtins
local getmetatable = getmetatable
local max = math.max
local tinsert = table.insert
local tremove = table.remove

-- Globals
local Command = Command
local Inspect = Inspect
local UICreateFrame = UI.CreateFrame
local UIParent = UIParent

-- Locals
local spacing = 2
local characterFramesCache = { }

setfenv(1, private)
Ux = Ux or { }

-- Private methods
-- ============================================================================

local function createDialog(self)
	self:SetTexture("ImhoBags", "textures/dialog.png")

	local topleft = UICreateFrame("Texture", "", self)
	topleft:SetTextureAsync("ImhoBags", "textures/dialog_tl.png")
	topleft:SetPoint("BOTTOMRIGHT", self, "TOPLEFT")
	
	local topright = UICreateFrame("Texture", "", self)
	topright:SetTextureAsync("ImhoBags", "textures/dialog_tr.png")
	topright:SetPoint("BOTTOMLEFT", self, "TOPRIGHT")
	
	local bottomleft = UICreateFrame("Texture", "", self)
	bottomleft:SetTextureAsync("ImhoBags", "textures/dialog_bl.png")
	bottomleft:SetPoint("TOPRIGHT", self, "BOTTOMLEFT")
	
	local bottomright = UICreateFrame("Texture", "", self)
	bottomright:SetTextureAsync("ImhoBags", "textures/dialog_br.png")
	bottomright:SetPoint("TOPLEFT", self, "BOTTOMRIGHT")
	
	local top = UICreateFrame("Texture", "", self)
	top:SetTextureAsync("ImhoBags", "textures/dialog_t.png")
	top:SetPoint("TOPLEFT", topleft, "TOPRIGHT")
	top:SetPoint("BOTTOMRIGHT", topright, "BOTTOMLEFT")
	
	local bottom = UICreateFrame("Texture", "", self)
	bottom:SetTextureAsync("ImhoBags", "textures/dialog_b.png")
	bottom:SetPoint("BOTTOMLEFT", bottomleft, "BOTTOMRIGHT")
	bottom:SetPoint("TOPRIGHT", bottomright, "TOPLEFT")
	
	local left = UICreateFrame("Texture", "", self)
	left:SetTextureAsync("ImhoBags", "textures/dialog_l.png")
	left:SetPoint("TOPLEFT", topleft, "BOTTOMLEFT")
	left:SetPoint("BOTTOMRIGHT", bottomleft, "TOPRIGHT")

	local right = UICreateFrame("Texture", "", self)
	right:SetTextureAsync("ImhoBags", "textures/dialog_r.png")
	right:SetPoint("TOPLEFT", topright, "BOTTOMLEFT")
	right:SetPoint("BOTTOMRIGHT", bottomright, "TOPRIGHT")
end

local function createCharacterFrame(self, name)
	if(#characterFramesCache > 0) then
		local frame = tremove(characterFramesCache)
		frame.nameLabel:SetText(name)
		frame:SetVisible(true)
		return frame
	end
	
	local frame = UICreateFrame("Frame", "", self)
	
	frame.inventoryButton = Ux.IconButton.New(frame, [[Data/\UI\item_icons\bag20.dds]], L.Ux.WindowTitle.inventory)
	function frame.inventoryButton.LeftPress()
		self:SetVisible(false)
		frame.inventoryButton.Event:MouseOut()
		Ux.ToggleItemWindow(name, "inventory")
	end

	frame.bankButton = Ux.IconButton.New(frame, [[Data/\UI\item_icons\chest2.dds]], L.Ux.WindowTitle.bank)
	function frame.bankButton.LeftPress()
		self:SetVisible(false)
		frame.bankButton.Event:MouseOut()
		Ux.ToggleItemWindow(name, "bank")
	end

	frame.mailButton = Ux.IconButton.New(frame, [[Data/\UI\item_icons\collection_of_love_letters.dds]], L.Ux.WindowTitle.mail)
	function frame.mailButton.LeftPress()
		self:SetVisible(false)
		frame.mailButton.Event:MouseOut()
		Ux.ToggleItemWindow(name, "mail")
	end

	frame.equipmentButton = Ux.IconButton.New(frame, [[Data/\UI\item_icons\1h_sword_065b.dds]], L.Ux.WindowTitle.equipment)
	function frame.equipmentButton.LeftPress()
		self:SetVisible(false)
		frame.equipmentButton.Event:MouseOut()
		Ux.ToggleItemWindow(name, "equipment")
	end

	frame.wardrobeButton = Ux.IconButton.New(frame, [[Data/\UI\item_icons\festival_hat_03.dds]], L.Ux.WindowTitle.wardrobe)
	function frame.wardrobeButton.LeftPress()
		self:SetVisible(false)
		frame.wardrobeButton.Event:MouseOut()
		Ux.ToggleItemWindow(name, "wardrobe")
	end

	frame.currencyButton = Ux.IconButton.New(frame, [[Data/\UI\item_icons\loot_gold_coins.dds]], L.Ux.WindowTitle.currency)
	function frame.currencyButton.LeftPress()
		self:SetVisible(false)
		frame.currencyButton.Event:MouseOut()
		Ux.ToggleItemWindow(name, "currency")
	end
	
	frame.guildButton = Ux.IconButton.New(frame, Player.alliance == "defiant" and [[Data/\UI\item_icons\GuildCharter_Defiants.dds]] or
		[[Data/\UI\item_icons\GuildCharter_Guardians.dds]], L.Ux.Tooltip.guild)
	function frame.guildButton.LeftPress()
		self:SetVisible(false)
		frame.guildButton.Event:MouseOut()
		Ux.ToggleGuildWindow(name)
	end
	
	frame.nameLabel = UICreateFrame("Text", "", frame)
	frame.nameLabel:SetText(name)
	frame.nameLabel:SetFontSize(16)
	
	frame:SetWidth(7 * (frame.inventoryButton:GetWidth() + spacing) + frame.nameLabel:GetWidth())
	frame:SetHeight(frame.inventoryButton:GetHeight())
	
	return frame
end

local function clearCorners(self)
	self:ClearPoint("TOPLEFT")
	self:ClearPoint("TOPRIGHT")
	self:ClearPoint("BOTTOMLEFT")
	self:ClearPoint("BOTTOMRIGHT")
end

local function disposeCharacterFrame(frame)
	clearCorners(frame)
	frame:SetVisible(false)
	characterFramesCache[#characterFramesCache + 1] = frame
end

local function layoutCharacterFrame(self, direction)
	local anchor1 = direction == "LEFT" and "RIGHTCENTER" or "LEFTCENTER"
	local anchor2 = direction .. "CENTER"
	local spacing = direction == "LEFT" and -spacing or spacing
	
	self.inventoryButton:ClearPoint("LEFTCENTER")
	self.inventoryButton:ClearPoint("RIGHTCENTER")
	self.bankButton:ClearPoint("LEFTCENTER")
	self.bankButton:ClearPoint("RIGHTCENTER")
	self.mailButton:ClearPoint("LEFTCENTER")
	self.mailButton:ClearPoint("RIGHTCENTER")
	self.equipmentButton:ClearPoint("LEFTCENTER")
	self.equipmentButton:ClearPoint("RIGHTCENTER")
	self.wardrobeButton:ClearPoint("LEFTCENTER")
	self.wardrobeButton:ClearPoint("RIGHTCENTER")
	self.currencyButton:ClearPoint("LEFTCENTER")
	self.currencyButton:ClearPoint("RIGHTCENTER")
	self.guildButton:ClearPoint("LEFTCENTER")
	self.guildButton:ClearPoint("RIGHTCENTER")
	self.nameLabel:ClearPoint("LEFTCENTER")
	self.nameLabel:ClearPoint("RIGHTCENTER")
	
	self.inventoryButton:SetPoint(anchor1, self, anchor1)
	self.bankButton:SetPoint(anchor1, self.inventoryButton, anchor2, spacing, 0)
	self.mailButton:SetPoint(anchor1, self.bankButton, anchor2, spacing, 0)
	self.equipmentButton:SetPoint(anchor1, self.mailButton, anchor2, spacing, 0)
	self.wardrobeButton:SetPoint(anchor1, self.equipmentButton, anchor2, spacing, 0)
	self.currencyButton:SetPoint(anchor1, self.wardrobeButton, anchor2, spacing, 0)
	self.guildButton:SetPoint(anchor1, self.currencyButton, anchor2, spacing, 0)
	self.nameLabel:SetPoint(anchor1, self.guildButton, anchor2)
end

local function createToolsFrame(self)
	local frame = UICreateFrame("Frame", "", self)
	
	frame.configButton = Ux.IconButton.New(frame, [[Data/\UI\item_icons\small_student_experiment.dds]], L.Ux.Tooltip.config)
	function frame.configButton.LeftPress()
		self:SetVisible(false)
		frame.configButton.Event:MouseOut()
		Ux.ToggleConfigWindow()
	end

	frame.bankButton = Ux.IconButton.New(frame, [[Data/\UI\item_icons\chest2.dds]], L.Ux.WindowTitle.bank)
	function frame.bankButton.LeftPress()
		self:SetVisible(false)
		frame.bankButton.Event:MouseOut()
		Ux.ToggleItemWindow(name, "bank")
	end

end

local function layoutMenu(self, horizontal, vertical)
	local anchor1 = vertical == "TOP" and "BOTTOM" or "TOP"
	local anchor2 = vertical
	
	anchor1 = anchor1 .. (horizontal == "LEFT" and "RIGHT" or "LEFT")
	anchor2 = anchor2 .. (horizontal == "LEFT" and "RIGHT" or "LEFT")
	
	clearCorners(self.player)
	layoutCharacterFrame(self.player, horizontal)
	self.player:SetPoint(anchor1, self, anchor1)
	
	clearCorners(self.playerSeparator)
	self.playerSeparator:SetPoint(anchor1, self.player, anchor2)
	
	local width = self.player:GetWidth()
	local previous = self.playerSeparator
	for i = 1, #self.chars do
		local char = self.chars[i]
		clearCorners(char)
		layoutCharacterFrame(char, horizontal)
		char:SetPoint(anchor1, previous, anchor2)
		previous = char
		width = max(width, char:GetWidth())
	end
	
	clearCorners(self.configSeparator)
	self.configSeparator:SetPoint(anchor1, previous, anchor2)
	
	self.configSeparator:SetWidth(width)
	self.playerSeparator:SetWidth(width)
	self:SetWidth(width)
	
	local height = self.player:GetHeight() + self.playerSeparator:GetHeight() + #self.chars * self.player.inventoryButton:GetHeight()
	self:SetHeight(height)
end

local function updateCharacters(self)
	local chars = ItemDB.GetAvailableCharacters()
	
	for i = 1, #self.chars do
		disposeCharacterFrame(self.chars[i])
	end
	
	for i = 1, #chars do
		if(chars[i] == Player.name) then
			tremove(chars, i)
			break
		end
	end
	
	for i = 1, #chars do
		self.chars[i] = createCharacterFrame(self, chars[i])
	end

	for i = #chars + 1, #self.chars do
		self.chars[i] = nil
	end
end

local function configChanged(self, name, value)
	if(name == "showEnemyFaction") then
		updateCharacters(self)
		if(self:GetVisible()) then
			layoutMenu(self, self.horizontal, self.vertical)
		end
	end
end

-- Public methods
-- ============================================================================

local function MenuWindow_SetVisible(self, visible)
	if(visible) then
		local mouse = Inspect.Mouse()
		local horizontal = mouse.x < UIParent:GetWidth() / 2 and "RIGHT" or "LEFT"
		local vertical = mouse.y < UIParent:GetHeight() / 2 and "BOTTOM" or "TOP"
		
		if(horizontal ~= self.horizontal or vertical ~= self.vertical) then
			self.horizontal = horizontal
			self.vertical = vertical
			layoutMenu(self, horizontal, vertical)
		end

		local anchor = (vertical == "TOP" and "BOTTOM" or "TOP") .. (horizontal == "LEFT" and "RIGHT" or "LEFT")

		clearCorners(self)
		clearCorners(self.closeButton)
		
		self:SetPoint(anchor, UIParent, "TOPLEFT", mouse.x, mouse.y)
		self.closeButton:SetPoint(vertical .. horizontal, self, anchor)
	end
	getmetatable(self).__index.SetVisible(self, visible)
end

function Ux.MenuWindow()
	Command.System.Watchdog.Quiet()
	
	local self = UICreateFrame("Texture", "Menu Window", Ux.Context)
	createDialog(self)
	
	self.closeButton = UICreateFrame("RiftButton", "close", self)
	self.closeButton:SetSkin("close")
	self.closeButton:SetLayer(10)
	self.closeButton:SetWidth(20)
	self.closeButton:SetHeight(self.closeButton:GetWidth())
	function self.closeButton.Event.LeftPress()
		self:SetVisible(false)
	end
	
	self.player = createCharacterFrame(self, Player.name)
	
	self.playerSeparator = UICreateFrame("Texture", "playerSeparator", self)
	self.playerSeparator:SetTexture("ImhoBags", "textures/hr1.png")
	self.playerSeparator:SetHeight(6)
	
	self.configSeparator = UICreateFrame("Texture", "configSeparator", self)
	self.configSeparator:SetTexture("ImhoBags", "textures/hr1.png")
	self.configSeparator:SetHeight(6)
	
	self.chars = { }
	updateCharacters(self)
	
	self.SetVisible = MenuWindow_SetVisible
	
	ImhoEvent.Config[#ImhoEvent.Config + 1] = { function(...) configChanged(self, ...) end, Addon.identifier, "MenuWindow_configChanged" }

	self:SetVisible(true)
	Ux.MenuWindow = self
	return self
end

--Ux.MenuWindow()
