local Addon, private = ...

-- Builtins
local floor = math.floor
local format = string.format
local max = math.max
local sort = table.sort
local type = type
local unpack = unpack

-- Globals
local Command = Command
local Inspect = Inspect
local UICreateFrame = UI.CreateFrame

-- Locals
local vaultFontSize = 16
local vaultLabelColor = { 216 / 255, 203 / 255, 153 / 255 }

setfenv(1, private)
Ux = Ux or { }
Ux.GuildWindow = { }

-- Private methods
-- ============================================================================

local function setCharacter(self)
	-- TODO: once guild money is accessible
	self.coinMatrix = ItemDB.GetItemMatrix("none", "none")
end

local function createVaultDialog(self)
	self.vaultsBack = UICreateFrame("Texture", "", self)
	self.vaultsBack:SetTexture("ImhoBags", "textures/dialog.png")
	local left, top, right, bottom = self:getContentPadding()
	local borderLeft, borderTop, borderRight, borderBottom = self:GetTrimDimensions()
	self.vaultsBack:SetPoint("TOPRIGHT", self, "TOPLEFT", -borderLeft + 6, top)
	self.vaultsBack:SetWidth(166)
	
	local topleft = UICreateFrame("Texture", "", self.vaultsBack)
	topleft:SetTexture("ImhoBags", "textures/dialog_tl.png")
	topleft:SetPoint("BOTTOMRIGHT", self.vaultsBack, "TOPLEFT")
	
	local bottomleft = UICreateFrame("Texture", "", self.vaultsBack)
	bottomleft:SetTexture("ImhoBags", "textures/dialog_bl.png")
	bottomleft:SetPoint("TOPRIGHT", self.vaultsBack, "BOTTOMLEFT")
	
	local top = UICreateFrame("Texture", "", self.vaultsBack)
	top:SetTexture("ImhoBags", "textures/dialog_t.png")
	top:SetPoint("TOPLEFT", topleft, "TOPRIGHT")
	top:SetPoint("BOTTOMRIGHT", self.vaultsBack, "TOPRIGHT")
	
	local bottom = UICreateFrame("Texture", "", self.vaultsBack)
	bottom:SetTexture("ImhoBags", "textures/dialog_b.png")
	bottom:SetPoint("BOTTOMLEFT", bottomleft, "BOTTOMRIGHT")
	bottom:SetPoint("TOPRIGHT", self.vaultsBack, "BOTTOMRIGHT")
	
	local left = UICreateFrame("Texture", "", self.vaultsBack)
	left:SetTexture("ImhoBags", "textures/dialog_l.png")
	left:SetPoint("TOPLEFT", topleft, "BOTTOMLEFT")
	left:SetPoint("BOTTOMRIGHT", bottomleft, "TOPRIGHT")
end

local function getVaultButton(self, i)
	if(self.vaultButtons[i]) then
		return self.vaultButtons[i]
	else
		local btn = UICreateFrame("Texture", "", self.vaultsBack)
--		btn:SetTexture("ImhoBags", "textures/button.png")
		btn:SetWidth(163)
		btn:SetHeight(25)
		if(i > 1) then
			btn:SetPoint("TOPLEFT", self.vaultButtons[i - 1], "BOTTOMLEFT", 0, 3)
		else
			btn:SetPoint("TOPLEFT", self.vaultsBack, "TOPLEFT", 0, 0)
		end
		btn.label = UICreateFrame("Text", "", self)
		btn.label:SetLayer(btn:GetLayer() + 1)
--		btn.label:SetBackgroundColor(1, 0, 0)
		btn.label:SetFontSize(vaultFontSize)
		btn.label:SetFontColor(unpack(vaultLabelColor))
		btn.label:SetPoint("LEFTCENTER", btn, "LEFTCENTER", 15, 0)
		self.vaultButtons[i] = btn
		function btn.Event.LeftDown()
			self.vault = i
			self.getItemFailed = 0
			self.matrix, self.enemy = ItemDB.GetGuildMatrix(self.character, self.vault)
			self.lastUpdate = -1
			self:setCharacter()
		end
		return btn
	end
end

local function updateVaultButtons(self)
	local vaults = ItemDB.GetGuildVaults(self.character) or 0
	for i = 1, vaults do
		local btn = getVaultButton(self, i)
		btn:SetVisible(true)
		btn:SetTexture("ImhoBags", i == self.vault and "textures/button hot.png" or "textures/button.png")
		btn.label:SetText(format(L.Ux.guildVault, i))
	end
	for i = vaults + 1, #self.vaultButtons do
		self.vaultButtons[i]:SetVisible(false)
	end
	self.vaultsBack:SetVisible(vaults > 0)
	self.vaultsBack:SetHeight(vaults * 25 + (vaults - 1) * 3)
end

-- Protected methods
-- ============================================================================

local function update(self)
	-- Show number of empty slots
	local n = (type(self.empty) == "table" and #self.empty) or self.empty
	self.titleBar:SetEmptySlots(n)
	self.titleBar:SetMainLabel(format("%s: %s", self.character, format(L.Ux.guildVault, self.vault)))
	
	self.moneyFrame:SetVisible(false)
	self.coinFrame:SetWidth(0)
	self:base_update()
	updateVaultButtons(self)
end

-- Public methods
-- ============================================================================

local function GuildWindow_SetCharacter(self, character, location)
	if(character == "player") then
		character = Player.guild or "<none>"
	end
	if(character ~= self.character or location ~= self.location) then
		self.vault = 1
		self.getItemFailed = 0
		self.matrix, self.enemy = ItemDB.GetGuildMatrix(character, self.vault)
		self.character = character
		self.location = location
		self.lastUpdate = -1
		self:setCharacter()
	end
end

-- character translates to guild and location to vault index
function Ux.GuildWindow.New(title, character, location, itemSize, sorting)
	local self = Ux.ItemWindow.New(title or "", character, location, itemSize, sorting)
	
	self.guildButton:SetIcon([[Data/\UI\item_icons\bag20.dds]])
	function self.guildButton.LeftPress()
		Ux.ToggleItemWindow(self.character, "inventory")
	end
	
	self.coinFrame:SetVisible(false)
	self.titleBar:SetCharButtonSkin("guild")
	self.titleBar:SetCharButtonCallback(function() self.titleBar:ShowCharSelector(ItemDB.GetAvailableGuilds()) end)
	
	self.update = update

	self.setCharacter = setCharacter
	
	self.SetCharacter = GuildWindow_SetCharacter

	self.groupFunc = Group.Default.GetLocalizedShortCategoryWithJunkAndLootable
	self.groupSortFunc = Group.Default.SortByCategoryNameWithJunk
	self.sortFunc = Sort.Default.ByItemName
	
	createVaultDialog(self)
	self.vaultButtons = { }
	self.vault = 1
	
	self.location = "" -- Force an update
	self:SetCharacter(character, location)
	
	return self
end
