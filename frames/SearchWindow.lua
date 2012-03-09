local Addon, private = ...

local ipairs = ipairs
local math = math
local pairs = pairs
local pcall = pcall
local string = string
local table = table
local tostring = tostring

local dump  = dump
local UIParent = UIParent

local Command = Command
local Event = Event
local Inspect = Inspect
local UI = UI

setfenv(1, private)
Ux = Ux or { }

local displayItemsCount = 24

-- Private methods
-- ============================================================================

local frame = UI.CreateFrame("RiftWindow", "", Ux.Context)
local content = frame:GetContent()
local border = frame:GetBorder()
Ux.SearchWindow = frame
frame:SetVisible(false)

Ux.RiftWindowCloseButton.New(frame, frame)

function border.Event:LeftDown()
	local mouse = Inspect.Mouse()
	self.mouseOffsetX = mouse.x - frame:GetLeft()
	self.mouseOffsetY = mouse.y - frame:GetTop()
end

function border.Event:LeftUp()
	self.mouseOffsetX, self.mouseOffsetY = nil, nil
end

function border.Event:LeftUpoutside()
	self.mouseOffsetX, self.mouseOffsetY = nil, nil
end

function border.Event:MouseMove()
	local mouse = Inspect.Mouse()
	if(self.mouseOffsetX) then
		frame:SetPoint("TOPLEFT", UIParent, "TOPLEFT", mouse.x - self.mouseOffsetX, mouse.y - self.mouseOffsetY)
	end
end

local filter = Ux.Textfield.New(frame, "RIGHT", L.Ux.search)
filter:SetPoint("TOPLEFT", content, "TOPLEFT", 4, 0)
filter:SetPoint("BOTTOMRIGHT", content, "TOPRIGHT", -4, 24)
function filter.text.Event:KeyFocusGain()
	if(self:GetText() == L.Ux.search) then
		self:SetText("")
	end
end

function filter.text.Event:KeyFocusLoss()
	if(self:GetText() == "") then
		self:SetText(L.Ux.search)
	end
end

local scrollbar
local display = { }
local buttons = { }
local items = { }

local function update()
	local offset = math.floor(scrollbar:GetPosition())
	for k, v in ipairs(buttons) do
		local index = k + offset
		if(index > #display) then
			v:SetVisible(false)
		else
			v:SetVisible(true)
			local item = display[index]
			v.text:SetText(item[2])
			v.text:SetFontColor(Utils.RarityColor(item[3]))
			v.icon:SetTexture("Rift", item[4])
			v.type = item[5]
		end
	end
end

local function applySearchFilter()
	local strfind = string.find
	local tinsert = table.insert
	
	local s = string.lower(filter.text:GetText())
	if(s == "") then
		for k, v in ipairs(items) do
			display[k] = v
		end
	else
		display = { }
		for k, v in ipairs(items) do
			if(strfind(v[1], s, 1, plain)) then
				tinsert(display, v)
			end
		end
	end

	if(#display > displayItemsCount) then
		scrollbar:SetVisible(true)
		scrollbar:SetRange(0, #display - displayItemsCount)
	else
		scrollbar:SetRange(0, 1)
		scrollbar:SetVisible(false)
	end
	scrollbar:SetPosition(0)

	update()
end

function filter.text.Event:TextfieldChange()
	applySearchFilter()
end

scrollbar = UI.CreateFrame("RiftScrollbar", "", frame)
scrollbar:SetPoint("TOPRIGHT", filter, "BOTTOMRIGHT", 0, 2)
scrollbar:SetPoint("BOTTOMRIGHT", content, "BOTTOMRIGHT", -4, -4)
scrollbar.Event.ScrollbarChange = update

local prevAnchor = filter
local prevAnchorOffset = -10
local top = filter:GetHeight()
for i = 1, displayItemsCount do
	local entry = UI.CreateFrame("Frame", "", frame)
	entry:SetPoint("TOPLEFT", prevAnchor, "BOTTOMLEFT", 0, 0)
	entry:SetPoint("TOPRIGHT", prevAnchor, "BOTTOMRIGHT", prevAnchorOffset, 0)
	prevAnchorOffset = 0
	prevAnchor = entry
	table.insert(buttons, entry)

	local text = UI.CreateFrame("Text", "", entry)
	text:SetText("x")
	entry:SetHeight(text:GetHeight())
	
	local icon = UI.CreateFrame("Texture", "", entry)
	icon:SetPoint("LEFTCENTER", entry, "LEFTCENTER")
	icon:SetWidth(entry:GetHeight())
	icon:SetHeight(entry:GetHeight())
	
	text:SetPoint("LEFTCENTER", icon, "RIGHTCENTER")
	text:SetPoint("RIGHTCENTER", entry, "RIGHTCENTER")
	
	entry.icon = icon
	entry.text = text
	
	function entry.Event:MouseMove()
		Command.Tooltip(self.type)
		-- Temporary fix while tooltip is displayed in top-left
		Ux.TooltipEnhancer:ClearAll();
		Ux.TooltipEnhancer:SetPoint("TOPLEFT", frame, "BOTTOMLEFT", 6, -4)
		Ux.TooltipEnhancer:SetPoint("TOPRIGHT", frame, "BOTTOMRIGHT", -6, -4)
	end
	
	function entry.Event:MouseOut()
		Command.Tooltip(nil)
	end
end

-- Public methods
-- ============================================================================

function frame:Show()
	frame:SetVisible(true)
	filter.text:SetText("")
	filter.text:SetKeyFocus(true)
	
	local strlower = string.lower
	local tinsert = table.insert
	
	local itemTypes = ItemDB.GetAllItemTypes()
	items = { }
	display = { }
	for k in pairs(itemTypes) do
		local result, detail = pcall(Inspect.Item.Detail, k)
		if(result) then
			local n = string.gsub(detail.name, "\n", "")
			tinsert(items, { strlower(n), n, detail.rarity, detail.icon, k })
			tinsert(display, items[#items])
		end
	end
	table.sort(items, function(a, b) return a[1] < b[1] end)
	applySearchFilter()
end
