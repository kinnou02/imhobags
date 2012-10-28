local Addon, private = ...

-- Buildints
local format = string.format
local max = math.max
local min = math.min
local pairs = pairs

-- Globals
local Event = Event
local InspectGuildBankCoin = Inspect.Guild.Bank.Coin
local InspectGuildBankList = Inspect.Guild.Bank.List
local InspectGuildRankDetail = Inspect.Guild.Rank.Detail
local InspectGuildRosterDetail = Inspect.Guild.Roster.Detail
local InspectInteraction = Inspect.Interaction
local UICreateFrame = UI.CreateFrame
local UtilityItemSlotGuild = Utility.Item.Slot.Guild
local UtilityItemSlotParse = Utility.Item.Slot.Parse

-- Locals
local index2slot = { [0] = "sg00" }
local slot2index = { }
local formats = {
	activeVault = "vfx_ui_mob_tag_0%i_mini.png.dds",
	inactiveVault = "vfx_ui_mob_tag_0%i_mini_disabled.png.dds",
}

setfenv(1, private)
ItemContainer = ItemContainer or { }

-- Private methods
-- ============================================================================

local function slot(index)
	local slot = index2slot[index]
	if(not slot) then
		slot = UtilityItemSlotGuild(index)
		index2slot[index] = slot
	end
	return slot
end

local function index(slot)
	local index = slot2index[slot]
	if(not index) then
		local container, bag = UtilityItemSlotParse(slot)
		index = bag
		index2slot[slot] = index
	end
	return index
end

local function setVaultNameText(self, name, slot)
	self.vaultName:SetText(name)
	self.vaultName.slot = slot
	local access = self.vaultAccess[slot] or { }
	
	if(access.access == "deposit") then
		self.vaultName:SetFontColor(0.8, 0.8, 0)
	elseif(access.access == "full") then
		self.vaultName:SetFontColor(96 / 255, 213 / 255, 1 / 255)
	else
		self.vaultName:SetFontColor(239 / 255, 0.1, 0.1)
	end
end

local function setVault(self, index)
	for i = 1, #self.vaultButtons do
		local slot = slot(i)
		if(self.vaultAccess[slot]) then
			self.vaultButtons[i]:SetTexture("Rift", format(i == index and formats.activeVault or formats.inactiveVault, i))
		end
	end
	self.vault = index
	if(index > 0) then
		setVaultNameText(self, self.vaultButtons[index].name, slot(index))
	end
	self.vaultCallback(self.vault)
end

local function createVaultButton(parent, index)
	local self = UICreateFrame("Texture", "", parent)
	self:SetTexture("Rift", format(formats.inactiveVault, index))
	self:SetWidth(0)
	self:SetHeight(16)
	self:AnimateWidth(Const.AnimationsDuration, "linear", 16)
	self.access = UICreateFrame("Texture", "", self)
	self.access:SetAllPoints()
	self.access:SetTexture("Rift", "vfx_ui_mob_tag_no_mini_disabled.png.dds")
	self.slot = slot(index)

	function self.Event:MouseMove()
		setVaultNameText(parent, parent.vaultButtons[index].name or "", self.slot)
	end
	function self.Event:MouseOut()
		setVaultNameText(parent, parent.vaultButtons[parent.vault].name or "", slot(parent.vault))
	end
	function self.Event:LeftClick()
		setVault(parent, index)
	end
	
	return self
end

local function setVaults(self, vaults)
	local maxn = 0
	
	for slot, name in pairs(vaults) do
		local index = index(slot)
		local btn = self.vaultButtons[index]
		if(not btn) then
			btn = createVaultButton(self, index)
			self.vaultButtons[index] = btn
			maxn = max(maxn, index)
			if(index == 1) then
				btn:SetPoint("LEFTCENTER", self, "LEFTCENTER", 10, 0)
			end
		elseif(not btn:GetVisible()) then
			btn:SetWidth(0)
			btn:SetVisible(true)
			btn:AnimateWidth(Const.AnimationsDuration, "linear", 16)
		end
		btn.name = name
	end
	
	for i = max(2, self.numVaults + 1), maxn do
		self.vaultButtons[i]:SetPoint("LEFTCENTER", self.vaultButtons[i - 1], "RIGHTCENTER")
	end

	for i = maxn + 1, self.numVaults do
		local btn = self.vaultButtons[i]
		btn:AnimateWidth(Const.AnimationsDuration, "linear", 0, function() btn:SetVisible(false) end)
	end
	
	if(maxn > 0) then
		self.vaultName:SetPoint("LEFTCENTER", self.vaultButtons[maxn], "RIGHTCENTER", 10, 0)
	end
	self.numVaults = maxn
end

local function setVaultAccess(self, access)
	for i = 1, self.numVaults do
		local slot = slot(i)
		local rights = access[slot]
		if(rights) then
			self.vaultButtons[i].access:SetVisible(false)
		else
			self.vaultButtons[i].access:SetVisible(true)
		end
	end
	self.vaultAccess = access
	setVaultNameText(self, self.vaultName:GetText(), self.vaultName.slot)
end

local function setCoin(self, coin)
	self.coinFrame:SetCoin(coin)
end

local function eventGuildBankCoin(self, coin)
	if(self.guild == Player.guild) then
		setCoin(self, coin)
	end
end

local function eventInteraction(self, interaction, status)
	if(interaction == "guildbank" and status and self.guild == Player.guild) then
		setCoin(self, InspectGuildBankCoin())
	end
end

local function selectFirstAvailableVault(self)
	for i = 1, #self.vaultButtons do
		local slot = slot(i)
		if(self.vaultAccess[slot]) then
			setVault(self, i)
			return
		end
	end
	setVault(self, 0)
end

local function applyRank(self, rank)
	local access = InspectGuildRankDetail(rank).vaultAccess
	setVaultAccess(self, access)
	if(not access[slot(self.vault)]) then
		selectFirstAvailableVault(self)
	end
end

local function eventGuildBankChange(self, vaults)
	setVaults(self, vaults)
	applyRank(self, InspectGuildRosterDetail(Player.name).rank)
end

local function eventGuildRank(self, ranks)
	if(self.guild == Player.guild) then
		local rank = InspectGuildRosterDetail(Player.name).rank
		if(ranks[rank]) then
			applyRank(self, rank)
		end
	end
end

local function eventGuildRosterDetailRank(self, ranks)
	if(self.guild == Player.guild) then
		local rank = ranks[Player.name]
		if(rank) then
			applyRank(self, rank)
		end
	end
end

local function hookGulidEvents(self)
	Event.Interaction[#Event.Interaction + 1] = {
		function(...) eventInteraction(self, ...) end,
		Addon.identifier,
		"ItemContainer.GuildBar.eventInteraction"
	}
	Event.Guild.Bank.Change[#Event.Guild.Bank.Change + 1] = {
		function(...) eventGuildBankChange(self, ...) end,
		Addon.identifier,
		"ItemContainer.GuildBar.eventGuildBankChange"
	}
	Event.Guild.Bank.Coin[#Event.Guild.Bank.Coin + 1] = {
		function(...) eventGuildBankCoin(self, ...) end,
		Addon.identifier,
		"ItemContainer.GuildBar.eventGuildBankCoin"
	}
	Event.Guild.Rank[#Event.Guild.Rank + 1] = {
		function(...) eventGuildRank(self, ...) end,
		Addon.identifier,
		"ItemContainer.GuildBar.eventGuildRank"
	}
	Event.Guild.Roster.Detail.Rank[#Event.Guild.Roster.Detail.Rank + 1] = {
		function(...) eventGuildRosterDetailRank(self, ...) end,
		Addon.identifier,
		"ItemContainer.GuildBar.eventGuildRosterDetailRank"
	}
	Event.ImhoBags.Private.Guild[#Event.ImhoBags.Private.Guild + 1] = {
		function(old, new) self:SetGulid(new) end,
		Addon.identifier,
		"ItemContainer.GuildBar.guildChanged"
	}
end

local function init(self)
	self:SetGuild(Player.guild)
	hookGulidEvents(self)
end

-- Public methods
-- ============================================================================

local function SetGuild(self, guild)
	self.guild = guild
	if(guild) then
		if(guild == Player.guild) then
			setVaults(self, InspectGuildBankList())
			local roster = InspectGuildRosterDetail(Player.name)
			if(roster) then
				applyRank(self, roster.rank)
			end
			if(InspectInteraction("guildbank")) then
				setCoin(self, InspectGuildBankCoin())
			else
				setCoin(self, Item.Storage.GetGuildCoins()[guild] or 0)
			end
		else
			setVaults(self, Item.Storage.GetGuildVaults(guild))
			setVaultAccess(self, Item.Storage.GetGuildVaultAccess(guild))
			setCoin(self, Item.Storage.GetGuildCoins()[guild] or 0)
			eventInteraction(self, "guildbank", false)
		end
	else
		setVaults(self, { })
		setCoin(self, 0)
	end
	selectFirstAvailableVault(self)
end

function ItemContainer.GuildBar(parent, vaultCallback)
	local self = UICreateFrame("Texture", "", parent)
	self:SetTexture("Rift", "QuestBarOver.png.dds")
	self:SetHeight(24)
	
	self.vaultName = UICreateFrame("Text", "", self)
	self.vaultName:SetPoint("LEFTCENTER", self, "LEFTCENTER")
	self.vaultName:SetFontSize(14)
	self.vaultName.slot = "sg00"
	
	self.coinFrame = Ux.MoneyFrame.New(self)
	self.coinFrame:SetPoint("RIGHTCENTER", self, "RIGHTCENTER", -5, 0)
	
	self.vaultButtons = { }
	self.numVaults = 0
	self.vaultAccess = { }
	self.vault = 0
	self.vaultCallback = vaultCallback
	
	self.SetGuild = SetGuild
	
	Event.ImhoBags.Private.Init[#Event.ImhoBags.Private.Init + 1] = { function() init(self) end, Addon.identifier, "GuildBar.init" }
	
	return self
end
