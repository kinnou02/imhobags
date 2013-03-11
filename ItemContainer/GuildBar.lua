local Addon, private = ...

-- Upvalue
local InspectGuildBankCoin = Inspect.Guild.Bank.Coin
local InspectGuildBankList = Inspect.Guild.Bank.List
local InspectGuildRankDetail = Inspect.Guild.Rank.Detail
local InspectGuildRosterDetail = Inspect.Guild.Roster.Detail
local InspectInteraction = Inspect.Interaction
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
			self.vaultButtons[i]:SetTexture("Rift", string.format(i == index and formats.activeVault or formats.inactiveVault, i))
		end
	end
	self.vault = index
	if(index > 0) then
		setVaultNameText(self, self.vaultButtons[index].name, slot(index))
	end
	self.vaultCallback(self.vault)
end

local function createVaultButton(parent, index)
	local self = UI.CreateFrame("Texture", "", parent)
	self:SetTexture("Rift", string.format(formats.inactiveVault, index))
	self:SetWidth(0)
	self:SetHeight(16)
	self:AnimateWidth(Const.AnimationsDuration, "linear", 16)
	self.access = UI.CreateFrame("Texture", "", self)
	self.access:SetAllPoints()
	self.access:SetTexture("Rift", "vfx_ui_mob_tag_no_mini.png.dds")
	self.slot = slot(index)

	self:EventAttach(Event.UI.Input.Mouse.Cursor.Move, function()
		setVaultNameText(parent, parent.vaultButtons[index].name or "", self.slot)
	end, "")
	self:EventAttach(Event.UI.Input.Mouse.Cursor.Out, function()
		setVaultNameText(parent, parent.vaultButtons[parent.vault].name or "", slot(parent.vault))
	end, "")
	self:EventAttach(Event.UI.Input.Mouse.Left.Click, function()
		if(parent.vaultAccess[self.slot]) then
			setVault(parent, index)
		end
	end, "")
	
	return self
end

local function setVaults(self, vaults)
	local maxn = 0
	local max = math.max
	
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
	local access = InspectGuildRankDetail(rank).vaultAccess or { }
	setVaultAccess(self, access)
	if(not access[slot(self.vault)]) then
		selectFirstAvailableVault(self)
	end
end

local function eventGuildBankChange(self, vaults)
	setVaults(self, vaults)
	local member = InspectGuildRosterDetail(Player.name)
	if(member) then
		applyRank(self, member.rank)
	end
end

local function eventGuildRank(self, ranks)
	if(self.guild == Player.guild) then
		local member = InspectGuildRosterDetail(Player.name)
		if(member and ranks[member.rank]) then
			applyRank(self, member.rank)
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
	Command.Event.Attach(Event.Interaction, function(handle, ...) eventInteraction(self, ...) end, "ItemContainer.GuildBar.eventInteraction")
	Command.Event.Attach(Event.Guild.Bank.Change, function(handle, ...) eventGuildBankChange(self, ...) end, "ItemContainer.GuildBar.eventGuildBankChange")
	Command.Event.Attach(Event.Guild.Bank.Coin, function(handle, ...) eventGuildBankCoin(self, ...) end, "ItemContainer.GuildBar.eventGuildBankCoin")
	Command.Event.Attach(Event.Guild.Rank, function(handle, ...) eventGuildRank(self, ...) end, "ItemContainer.GuildBar.eventGuildRank")
	Command.Event.Attach(Event.Guild.Roster.Detail.Rank, function(handle, ...) eventGuildRosterDetailRank(self, ...) end, "ItemContainer.GuildBar.eventGuildRosterDetailRank")
	Command.Event.Attach(Event.ImhoBags.Private.Guild, function(handle, old, new)
		self:SetGulid(new)
	end, "ItemContainer.GuildBar.guildChanged")
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
	local self = UI.CreateFrame("Texture", "", parent)
	self:SetTexture("Rift", "QuestBarOver.png.dds")
	self:SetHeight(24)
	
	self.vaultName = UI.CreateFrame("Text", "", self)
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
	
	Command.Event.Attach(Event.ImhoBags.Private.Init, function() init(self) end, "ItemContainer.GuildBar.init")
	
	return self
end
