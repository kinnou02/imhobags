local Addon, private = ...

setfenv(1, private)
Ux.ItemWindowTemplate = Ux.ItemWindowTemplate or { }

-- Private methods
-- ============================================================================

local function createHelpButton(self)
	local helpBtn = UI.CreateFrame("Frame", "", self)
	helpBtn:SetPoint("BOTTOMLEFT", self:GetContent(), "TOPLEFT", -4, -6)
	helpBtn:SetWidth(36)
	helpBtn:SetHeight(36)
	helpBtn:EventAttach(Event.UI.Input.Mouse.Cursor.In, function(self) self.icon:SetTexture("Rift", "AATree_I3A.dds") end, "")
	helpBtn:EventAttach(Event.UI.Input.Mouse.Cursor.Out, function(self) self.icon:SetTexture("Rift", "AATree_I38.dds") end, "")
	helpBtn:EventAttach(Event.UI.Input.Mouse.Left.Upoutside, function(self) self.icon:SetTexture("Rift", "AATree_I38.dds") end, "")
	helpBtn:EventAttach(Event.UI.Input.Mouse.Left.Down, function(self) self.icon:SetTexture("Rift", "AATree_I3F.dds") end, "")
	helpBtn:EventAttach(Event.UI.Input.Mouse.Left.Up, function(self) self.icon:SetTexture("Rift", "AATree_I3A.dds") end, "")
	helpBtn:EventAttach(Event.UI.Input.Mouse.Left.Click, function() Ux.ToggleConfigWindow() end, "")
	helpBtn.icon = UI.CreateFrame("Texture", "", self)
	helpBtn.icon:SetPoint("CENTER", helpBtn, "CENTER")
	helpBtn.icon:SetWidth(38)
	helpBtn.icon:SetHeight(38)
	helpBtn.icon:SetTexture("Rift", "AATree_I38.dds")
end

local function closeButton_LeftPress(self)
	local window = self:GetParent()
	window.titleBar:ClearKeyFocus()
	window:onClose()
	log("TODO", "close the native frame(s)")
end

local function createTitleBar(self, location, config)
	self.titleBar = Ux.ItemWindowTemplate.TitleBar(self, location)
	self.titleBar:SetLayer(100)
	self.titleBar:SetFilterCallback(function(filter) self.container:SetSearchFilter(filter) end)
	if(location == "guildbank") then
		self.titleBar:SetCharButtonCallback(function() self.titleBar:ShowCharSelector(Item.Storage.GetGuildNames()) end)
		self.titleBar:SetCharButtonSkin("guild")
	else
		self.titleBar:SetCharButtonCallback(function() self.titleBar:ShowCharSelector(Item.Storage.GetCharacterNames()) end)
		self.titleBar:SetCharButtonSkin("player")
	end
	self.titleBar:SetCharSelectorCallback(function(char)
		if(location == "guildbank") then
			self:SetGuild(char)
		else
			self:SetCharacter(char)
		end
		self.titleBar:FadeOut()
	end)
	self.titleBar:SetSizeSelectorCallback(function(n)
		self.container:SetItemSize(n)
	end)
	self.titleBar:SetLocationCallback(function(loc)
		if(self.location == "guildbank") then
			Ux.ShowItemWindow(Player.name, loc)
		else
			Ux.ShowItemWindow(self.character, loc)
		end
	end)
	self.titleBar:SetSortSelectorCallback(function(sort)
		self.titleBar:SetSortSelectorValue(sort)
		self.container:SetSortMethod(sort)
	end)
	self.titleBar:SetLayoutSelectorCallback(function(layout)
		self.titleBar:SetLayoutSelectorValue(layout)
		self.container:SetLayout(layout)
	end)
	self.titleBar:SetEmptySlotsCallback(function(sort)
		self.config.showEmptySlots = not self.config.showEmptySlots
		self.container:SetShowEmptySlots(self.config.showEmptySlots)
	end)

	self.titleBar:SetSortSelectorValue(config.sort or Const.ItemWindowDefaultSort)
	self.titleBar:SetLayoutSelectorValue(config.layout or Const.ItemWindowDefaultLayout)
	self.titleBar:SetSizeSelectorValue(config.itemSize or Const.ItemButtonDefaultSize)
	self.titleBar:SetMainLabel(Player.name)
	self.titleBar:SetAlliance(Player.alliance)
end

local function mouseMove(self)
	if(self.mouseOffsetX) then
		local mouse = Inspect.Mouse()
		self.window:SetPoint("TOPLEFT", UIParent, "TOPLEFT", mouse.x - self.mouseOffsetX, mouse.y - self.mouseOffsetY)
	end
end

local function leftDown(self)
	if(Inspect.Cursor()) then
		self.window.container:DropCursorItem()
	else
		local mouse = Inspect.Mouse()
		self.mouseOffsetX = math.floor(mouse.x - self.window:GetLeft())
		self.mouseOffsetY = math.floor(mouse.y - self.window:GetTop())
	end
end

local function leftUpoutside(self)
	self.mouseOffsetX, self.mouseOffsetY = nil, nil
end

local function leftUp(self)
	if(Inspect.Cursor()) then
		self.window.container:DropCursorItem()
	end
	leftUpoutside(self)
end

local function isInsideResizeButton(self)
	local mouse = Inspect.Mouse()
	return mouse.x - self:GetLeft() >= self:GetBottom() - mouse.y
end

local function createResizeButton(self)
	local btn = UI.CreateFrame("Texture", "", self)
	
	btn:SetTexture("Rift", "chat_resize_(normal).png.dds")
	btn:SetPoint("BOTTOMRIGHT", self, "BOTTOMRIGHT", 8, 8)
	btn.offset = nil
	btn:EventAttach(Event.UI.Input.Mouse.Cursor.In, function(self)
		if(isInsideResizeButton(self)) then
			self:SetTexture("Rift", self.offset and "chat_resize_(click).png.dds" or "chat_resize_(over).png.dds")
		end
	end, "")
	btn:EventAttach(Event.UI.Input.Mouse.Cursor.Out, function(self) self:SetTexture("Rift", self.offset and "chat_resize_(click).png.dds" or "chat_resize_(normal).png.dds") end, "")
	btn:EventAttach(Event.UI.Input.Mouse.Left.Up, function(self) self:SetTexture("Rift", "chat_resize_(over).png.dds") self.offset = nil end, "")
	btn:EventAttach(Event.UI.Input.Mouse.Left.Upoutside, function(self) self:SetTexture("Rift", "chat_resize_(normal).png.dds") self.offset = nil end, "")
	btn:EventAttach(Event.UI.Input.Mouse.Left.Down, function()
		if(isInsideResizeButton(btn)) then
			btn:SetTexture("Rift", "chat_resize_(click).png.dds")
			btn.offset = self:GetRight() - Inspect.Mouse().x
		end
	end, "")
	btn:EventAttach(Event.UI.Input.Mouse.Cursor.Move, function()
		if(btn.offset) then
			self:SetWidth(math.max(Const.ItemWindowMinWidth, Inspect.Mouse().x - self:GetLeft() + btn.offset))
			self.container:SetNeedsLayout()
		elseif(isInsideResizeButton(btn)) then
			btn:SetTexture("Rift", "chat_resize_(over).png.dds")
		else
			btn:SetTexture("Rift", "chat_resize_(normal).png.dds")
		end
	end, "")
end

local function containerDisplayChanged(container, values)
	local self = container:GetParent()
	if(values.height) then
		self.heightAnimation:Stop()
		self.heightAnimation = self:AnimateHeight(Const.AnimationsDuration, "easeOutCubic",
			math.max(Const.ItemWindowMinHeight, self.containerOffset + values.height))
	end
	if(values.empty) then
		self.titleBar:SetEmptySlots(values.empty)
	end
end

local function createNativeHook(self, native, location)
	if(native) then
		native:EventAttach(Event.UI.Native.Loaded, function(native)
			if(Config.autoOpen) then
				if(native:GetLoaded()) then
					if(location == "guildbank") then
						self:SetGuild(Player.guild)
					else
						self:SetCharacter(Player.name)
					end
					self:FadeIn()
				else
					self:FadeOut()
				end
				log("TODO", "disable native frame(s)")
			end
		end, "")
	end
end

local function createBackground(self)
	local background = UI.CreateFrame("Texture", "", self)
	background:SetPoint("CENTER", self, "CENTER")
	background:SetTexture("Rift", Player.alliance == "defiant" and "Guild_Defiant_bg.png.dds" or "Guild_Guardian_bg.png.dds")
	background:SetAlpha(0.3)
	self.background = background
	
	local fn = function(self)
		local size = math.min(self:GetWidth(), self:GetHeight())
		self.window.background:SetWidth(size)
		self.window.background:SetHeight(size)
	end
	self:GetContent():EventAttach(Event.UI.Layout.Size, fn, "")
	fn(self:GetContent())
end

local function guildVaultSelected(self, vault)
	self.container:SetGuild(self.character, vault)
end

local function createGuildBar(self, location)
	if(location == "guildbank") then
		self.guildBar = ItemContainer.GuildBar(self, function(vault) guildVaultSelected(self, vault) end)
		self.guildBar:SetPoint("TOPLEFT", self, "TOPLEFT", 0, -3)
		self.guildBar:SetPoint("TOPRIGHT", self, "TOPRIGHT", 0, -3)
		self.container:SetPoint("TOPLEFT", self.guildBar, "BOTTOMLEFT")
		self.container:SetPoint("TOPRIGHT", self.guildBar, "BOTTOMRIGHT")
		self.containerOffset = self.guildBar:GetHeight()
	else
		self.container:SetPoint("TOPLEFT", self, "TOPLEFT")
		self.container:SetPoint("TOPRIGHT", self, "TOPRIGHT")
		self.containerOffset = 0
	end
end

-- Public methods
-- ============================================================================

local function SetCharacter(self, character)
	local alliances = Item.Storage.GetCharacterAlliances()
	if(alliances[character]) then
		self.character = character
		self.container:SetCharacter(character)
		self.titleBar:SetAlliance(alliances[character])
		self.titleBar:SetMainLabel(character)
--		self.background:SetTexture("Rift", alliances[character] == "defiant" and "Guild_Defiant_bg.png.dds" or "Guild_Guardian_bg.png.dds")
	end
end

local function SetGuild(self, guild)
	self.character = guild
	self.container:SetGuild(guild)
	self.titleBar:SetAlliance(Player.alliance)
	self.titleBar:SetMainLabel(guild or "?")
end

local function FillConfig(self, config)
	config.x = self:GetLeft()
	config.y = self:GetTop()
	config.width = self:GetWidth()
	config.condensed = self.condensed
	return self.container:FillConfig(config)
end

-- HACK: Inspect.Item.List("inventory") does not return all items if called too early after /reloadui
local function SetVisible(self, visible)
	Item.Dispatcher.RunSlot(self.location)
	if(self.location == "equipment") then
		Item.Dispatcher.RunSlot("wardrobe")
	end
	self.SetVisible = nil
	self:SetVisible(visible)
end

function Ux.ItemWindowTemplate.WindowFrame(location, config, native)
	local context = UI.CreateContext(Addon.identifier)
	local self = UI.CreateFrame("RiftWindow", "WindowFrame." .. location, context)
	self:SetTitle("")
	self:SetVisible(false)
	
	self:SetController("content")
	self:SetWidth(math.max(Const.ItemWindowMinWidth, config.width or (Const.ItemWindowDefaultColumns * (Const.ItemButtonDefaultSize + Const.ItemWindowCellSpacing))))
	self:SetHeight(Const.ItemWindowMinHeight)
	local x = config.x or (UIParent:GetWidth() - self:GetWidth()) / 2
	local y = config.y or (UIParent:GetHeight() - self:GetHeight()) / 2
	self:SetPoint("TOPLEFT", UIParent, "TOPLEFT", x, y)
	
	self.container = ItemContainer.Display(self, location, config, containerDisplayChanged)
	self.container:SetLayer(2)
	
	self.config = config
	self.character = Player.Name
	self.heightAnimation = LibAnimate.CreateEmptyAnimation()
	self.location = location
	
	self.FillConfig = FillConfig
	self.SetCharacter = SetCharacter
	self.SetGuild = SetGuild
	self.SetVisible = SetVisible
	
	self.onClose = function() self:FadeOut() end

	local content = self:GetContent()
	content.window = self
	content:EventAttach(Event.UI.Input.Mouse.Cursor.Move, mouseMove, "")
	content:EventAttach(Event.UI.Input.Mouse.Left.Down, leftDown, "")
	content:EventAttach(Event.UI.Input.Mouse.Left.Up, leftUp, "")
	content:EventAttach(Event.UI.Input.Mouse.Left.Upoutside, leftUpoutside, "")
	local border = self:GetBorder()
	border.window = self
	border:EventAttach(Event.UI.Input.Mouse.Cursor.Move, mouseMove, "")
	border:EventAttach(Event.UI.Input.Mouse.Left.Down, leftDown, "")
	border:EventAttach(Event.UI.Input.Mouse.Left.Up, leftUp, "")
	border:EventAttach(Event.UI.Input.Mouse.Left.Upoutside, leftUpoutside, "")

	Ux.RiftWindowCloseButton.New(self, closeButton_LeftPress)
	createHelpButton(self)
	createTitleBar(self, location, config)
	createResizeButton(self)
	createNativeHook(self, native, location)
	createGuildBar(self, location)
--	createBackground(self)
	
	return self
end
