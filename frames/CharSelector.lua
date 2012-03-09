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

-- Public methods
-- ============================================================================

function Ux.CharSelector.New(parent, characters, current, callback)
	local frame = UI.CreateFrame("RiftButton", "", parent)
	frame.characters = characters
	frame:SetText(current)
	
	function frame.Event:LeftPress()
		self.menu:SetVisible(true)
		self.menu:SetWidth(math.max(self:GetWidth(), self.menu.contentWidth))
	end
	
	local menu = UI.CreateFrame("Frame", "", frame)
	frame.menu = menu
	menu:SetPoint("CENTER", frame, "CENTER")
	menu:SetBackgroundColor(0.6, 0.6, 0.6)
	menu.contentWidth = 0
	menu:SetVisible(false)
	menu.background = UI.CreateFrame("Frame", "", menu)
	menu.background:SetPoint("TOPLEFT", menu, "TOPLEFT", borderWidth + 1, borderWidth + 1)
	menu.background:SetPoint("BOTTOMRIGHT", menu, "BOTTOMRIGHT", -borderWidth, -borderWidth)
	menu.background:SetBackgroundColor(0, 0, 0)
	
	local prevAnchor = menu.background
	local prevPoint = "TOP"
	local height = 0
	for _, char in pairs(characters) do
		local back = UI.CreateFrame("Frame", "", menu)
		
		local label = UI.CreateFrame("Text", "", back)
		label:SetFontSize(14)
		label:SetPoint("CENTER", back, "CENTER", 0, 0)
		label:SetText(char)

		back:SetPoint("TOPLEFT", prevAnchor, prevPoint .. "LEFT")
		back:SetPoint("TOPRIGHT", prevAnchor, prevPoint .. "RIGHT")
		back:SetHeight(label:GetHeight())
		back:SetLayer(menu.background:GetLayer() + 1)
		prevPoint = "BOTTOM"
		prevAnchor = back
		
		menu.contentWidth = math.max(menu.contentWidth, label:GetFullWidth())
		height = height + label:GetHeight()
		
		function back.Event:MouseIn()
			back:SetBackgroundColor(1, 1, 1, 0.3)
		end
		function back.Event:MouseOut()
			back:SetBackgroundColor(1, 1, 1, 0)
		end
		function back.Event:LeftDown()
			back:SetBackgroundColor(1, 1, 1, 0)
			menu:SetVisible(false)
			frame:SetText(label:GetText())
			callback(label:GetText())
		end
	end
	menu:SetHeight(height + 2 * borderWidth)
	
	return frame
end
