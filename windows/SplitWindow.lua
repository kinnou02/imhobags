local Addon, private = ...

-- Builtins
local floor = math.floor
local getmetatable = getmetatable
local max = math.max
local min = math.min
local string = string
local tonumber = tonumber
local tostring = tostring

-- Globals
local Command = Command
local dump = dump
local Inspect = Inspect
local UICreateFrame = UI.CreateFrame
local UIParent = UIParent

-- Locals
local maxStackWidth = 56

setfenv(1, private)
Ux = Ux or { }

-- Private methods
-- ============================================================================

local self = UICreateFrame("Texture", "SplitWindow", Ux.TooltipContext)
Ux.SplitWindow = self
local item

self:SetWidth(235)
self:SetHeight(210)
self:SetTexture("ImhoBags", "textures/SplitWindow.png")
self:SetPoint("TOPLEFT", UIParent, "CENTER")
self:SetVisible(false)

local close = UICreateFrame("RiftButton", "", self)
close:SetSkin("close")
close:SetPoint("CENTER", self, "TOPLEFT", 214, 22)

local title = UICreateFrame("Text", "", self)
title:SetText("Gegenstand teilen")
title:SetPoint("CENTER", self, "TOPLEFT", 117, 26)
title:SetFontSize(14)
title:SetFontColor(206 / 255, 202 / 255, 182 / 255)

local icon = Ux.ItemButton_pretty.New(self)
icon:SetPoint("TOPLEFT", self, "TOPLEFT", 27, 48)
icon:SetBound(false)

local name = UICreateFrame("Text", "", self)
name:SetFontSize(14)
name:SetPoint("TOPLEFT", self, "TOPLEFT", 82, 47)

local stackMax = UICreateFrame("Text", "", self)
stackMax:SetFontSize(14)
stackMax:SetPoint("TOPLEFT", self, "TOPLEFT", 136, 117)

local hiddenStack = UICreateFrame("Text", "", self)
hiddenStack:SetVisible(false)

local stack = UICreateFrame("RiftTextfield", "", self)
stack:SetPoint("TOPLEFT", self, "TOPLEFT", 76, 118)
stack:SetWidth(maxStackWidth)

local slider = UICreateFrame("RiftSlider", "", self)
slider:SetPoint("CENTER", self, "TOPLEFT", 118, 158)
slider:SetWidth(173)

local ok = UICreateFrame("RiftButton", "", self)
ok:SetPoint("CENTER", self, "TOPLEFT", 120, 179)
ok:SetText("O.K.")

function close.Event.LeftPress()
	self:SetVisible(false)
end

function icon.Event.MouseIn()
	Command.Tooltip(item.id)
end

function icon.Event.MouseOut()
	Command.Tooltip(nil)
end

function slider.Event.SliderGrab()
	stack:SetText(tostring(floor(slider:GetPosition())))
end

function slider.Event.SliderChange()
	stack:SetText(tostring(floor(slider:GetPosition())))
end

function stack.Event.KeyType(stack, typed)
	if(typed == "\r" or typed == "\n") then
		stack:SetKeyFocus(false)
		ok.Event.LeftPress()
	end
end

function stack.Event.KeyFocusLoss()
	local n  = tonumber(stack:GetText())
	if(not n) then
		stack:SetText("1")
	else
		stack:SetText(tostring(min(item.stack - 1, max(1, n))))
	end
end

function ok.Event.LeftPress()
	Command.Item.Split(item.id, tonumber(stack:GetText()))
	Command.Tooltip(nil)
	self:SetVisible(false)
end

function self:SetVisible(v)
	stack:SetKeyFocus(v)
	getmetatable(self).__index.SetVisible(self, v)
end

-- Public methods
-- ============================================================================

function self:ShowForItem(id)
	item = Inspect.Item.Detail(id)
	if(not item or (item.stack or 1) < 2 or (item.stackMax or 1) < 2) then
		return
	end
	local mouse = Inspect.Mouse()
	self:SetPoint("TOPLEFT", UIParent, "TOPLEFT", mouse.x - 120, mouse.y - 179)
	
	stackMax:SetText("/" .. (item.stack - 1))
	stack:SetText("1")
	
	icon:SetIcon(item.icon)
	icon:SetRarity(item.rarity)
	name:SetFontColor(Utils.RarityColor(item.rarity))
	name:SetText(item.name)
	
	if(item.stack > 2) then
		slider:SetRange(1, item.stack - 1)
		slider:SetPosition(1)
	end
	slider:SetEnabled(item.stack > 2)
	
	self:SetVisible(true)
end
