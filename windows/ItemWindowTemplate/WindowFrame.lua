local Addon, private = ...

-- Builtin
local floor = math.floor
local max = math.max

-- Globals
local Command = Command
local Event = Event
local Inspect = Inspect
local UI = UI
local UIParent = UIParent

-- Locals

setfenv(1, private)
Ux.ItemWindowTemplate = Ux.ItemWindowTemplate or { }

-- Private methods
-- ============================================================================

local function createHelpButton(self)
	local helpBtn = UI.CreateFrame("Frame", "", self)
	helpBtn:SetPoint("BOTTOMLEFT", self:GetContent(), "TOPLEFT", -4, -6)
	helpBtn:SetWidth(36)
	helpBtn:SetHeight(36)
	helpBtn.Event.MouseIn = function(self) self.icon:SetTexture("Rift", "AATree_I3A.dds") end
	helpBtn.Event.MouseOut = function(self) self.icon:SetTexture("Rift", "AATree_I38.dds") end
	helpBtn.Event.LeftUpoutside = function(self) self.icon:SetTexture("Rift", "AATree_I38.dds") end
	helpBtn.Event.LeftDown = function(self)
		self.icon:SetTexture("Rift", "AATree_I3F.dds")
	end
	helpBtn.Event.LeftUp = function(self)
		self.icon:SetTexture("Rift", "AATree_I3A.dds")
		Ux.ToggleConfigWindow()
	end
	helpBtn.icon = UI.CreateFrame("Texture", "", self)
	helpBtn.icon:SetPoint("CENTER", helpBtn, "CENTER")
	helpBtn.icon:SetWidth(38)
	helpBtn.icon:SetHeight(38)
	helpBtn.icon:SetTexture("Rift", "AATree_I38.dds")
end

local function closeButton_LeftPress(self)
	local window = self:GetParent()
	window:SetVisible(false)
	window.titleBar:ClearKeyFocus()
	window:onClose()
	log("TODO", "close the native frame(s)")
end

local function createTitleBar(self, location, config)
	self.titleBar = Ux.ItemWindowTemplate.TitleBar(self, location)
	self.titleBar:SetLayer(100)
	self.titleBar:SetFilterCallback(function(filter) self.container:SetSearchFilter(filter) end)
	if(location == "guildbank") then
		self.titleBar:SetCharButtonCallback(function() self.titleBar:ShowCharSelector(ItemDB.GetAvailableGuilds()) end)
		self.titleBar:SetCharButtonSkin("guild")
	else
		self.titleBar:SetCharButtonCallback(function() self.titleBar:ShowCharSelector(Item.Storage.GetCharacterNames()) end)
		self.titleBar:SetCharButtonSkin("player")
	end
	self.titleBar:SetCharSelectorCallback(function(char)
		self:SetCharacter(char)
		self.titleBar:FadeOut()
	end)
	self.titleBar:SetSizeSelectorCallback(function(n)
		self.container:SetItemSize(n)
	end)
	self.titleBar:SetLocationCallback(function(loc)
		if(loc == "guildbank") then
			Ux.ToggleGuildWindow(self.character)
		else
			Ux.ToggleItemWindow(self.character, loc)
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
		self.mouseOffsetX = floor(mouse.x - self.window:GetLeft())
		self.mouseOffsetY = floor(mouse.y - self.window:GetTop())
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
	btn.Event.MouseIn = function(self)
		if(isInsideResizeButton(self)) then
			self:SetTexture("Rift", self.offset and "chat_resize_(click).png.dds" or "chat_resize_(over).png.dds")
		end
	end
	btn.Event.MouseOut = function(self) self:SetTexture("Rift", self.offset and "chat_resize_(click).png.dds" or "chat_resize_(normal).png.dds") end
	btn.Event.LeftUp = function(self) self:SetTexture("Rift", "chat_resize_(over).png.dds") self.offset = nil end
	btn.Event.LeftUpoutside = function(self) self:SetTexture("Rift", "chat_resize_(normal).png.dds") self.offset = nil end
	btn.Event.LeftDown = function()
		if(isInsideResizeButton(btn)) then
			btn:SetTexture("Rift", "chat_resize_(click).png.dds")
			btn.offset = self:GetRight() - Inspect.Mouse().x
		end
	end
	btn.Event.MouseMove = function()
		if(btn.offset) then
			self:SetWidth(max(Const.ItemWindowMinWidth, Inspect.Mouse().x - self:GetLeft() + btn.offset))
			self.container:SetNeedsLayout()
		elseif(isInsideResizeButton(btn)) then
			btn:SetTexture("Rift", "chat_resize_(over).png.dds")
		else
			btn:SetTexture("Rift", "chat_resize_(normal).png.dds")
		end
	end
end

local function containerDisplayChanged(container, values)
	local self = container:GetParent()
	if(values.height) then
		Animate.stop(self.heightAnimation)
		self.heightAnimation = Animate.easeOut(self:GetHeight(), max(Const.ItemWindowMinHeight, values.height), Const.AnimationsDuration,
			function(h) self:SetHeight(h) end, function() self.heightAnimation = 0 end)
	end
	if(values.empty) then
		self.titleBar:SetEmptySlots(values.empty)
	end
end

local function createNativeHook(self, native)
	if(native) then
		function native.Event.Loaded(native)
			if(Config.autoOpen) then
				if(native:GetLoaded()) then
					self:SetCharacter(Player.name)
					self:SetVisible(true)
				else
					self:SetVisible(false)
				end
				log("TODO", "disable native frame(s)")
			end
		end
	end
end

-- Public methods
-- ============================================================================

local function SetCharacter(self, character)
	local alliances = Item.Storage.GetCharacterAlliances()
	if(alliances[character]) then
		self.container:SetCharacter(character)
		self.titleBar:SetAlliance(alliances[character])
		self.titleBar:SetMainLabel(character)
	end
end

function Ux.ItemWindowTemplate.WindowFrame(location, config, native)
	local context = UI.CreateContext(Addon.identifier)
	local self = UI.CreateFrame("RiftWindow", "WindowFrame." .. location, context)
	self:SetTitle("")
	self:SetVisible(false)
	
	self:SetController("content")
	self:SetWidth(max(Const.ItemWindowMinWidth, config.width or (Const.ItemWindowDefaultColumns * (Const.ItemButtonDefaultSize + Const.ItemWindowCellSpacing))))
	self:SetHeight(Const.ItemWindowMinHeight)
	local x = config.x or (UIParent:GetWidth() - self:GetWidth()) / 2
	local y = config.y or (UIParent:GetHeight() - self:GetHeight()) / 2
	self:SetPoint("TOPLEFT", UIParent, "TOPLEFT", x, y)
	
	self.container = ItemContainer.Display(self, location, config, containerDisplayChanged)
	self.container:SetPoint("TOPLEFT", self, "TOPLEFT")
	self.container:SetPoint("TOPRIGHT", self, "TOPRIGHT")
	self.container:SetLayer(2)
	
	Ux.RiftWindowCloseButton.New(self, closeButton_LeftPress)
	createHelpButton(self)
	createTitleBar(self, location, config)
	createResizeButton(self)
	createNativeHook(self, native)
	
	local content = self:GetContent()
	content.window = self
	content.Event.MouseMove = mouseMove
	content.Event.LeftDown = leftDown
	content.Event.LeftUp = leftUp
	content.Event.LeftUpoutside = leftUpoutside
	local border = self:GetBorder()
	border.window = self
	border.Event.MouseMove = mouseMove
	border.Event.LeftDown = leftDown
	border.Event.LeftUp = leftUp
	border.Event.LeftUpoutside = leftUpoutside

	self.heightAnimation = 0
	self.config = config
	
	self.SetCharacter = SetCharacter
	self.GetItemSize = function(self) return self.container:GetItemSize() end
	self.GetLayout = function(self) return self.container:GetLayout() end
	self.GetSortMethod = function(self) return self.container:GetSortMethod() end
	self.GetGroupMethod = function(self) return self.container:GetGroupMethod() end

	self.onClose = function() self:SetVisible(false) end

	return self
end
--[[
ImhoEvent.Init[#ImhoEvent.Init + 1] = { function()
	local test = Ux.ItemWindowTemplate.WindowFrame("inventory", {
		sort = "slot",
		layout = "bags",
		itemSize = 40,
	}, UI.Native.BagInventory1)
	Item.Dispatcher.RunSlot("inventory")
end, Addon.identifier, "" }
]]