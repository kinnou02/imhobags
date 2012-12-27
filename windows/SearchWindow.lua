local Addon, private = ...

local assert = assert
local coroutine = coroutine
local floor = math.floor
local format = string.format
local pairs = pairs
local pcall = pcall
local sort = table.sort
local strfind = string.find
local strgsub = string.gsub
local strlower = string.lower
local strupper = string.upper

local Command = Command
local Event = Event
local Inspect = Inspect
local InspectItemDetail = Inspect.Item.Detail
local InspectTimeReal = Inspect.Time.Real
local UI = UI
local UIParent = UIParent

setfenv(1, private)
Ux = Ux or { }

local displayItemsCount = 24
local applyFilterAfterCoroutine = false
local updater

-- Private methods
-- ============================================================================

local context = UI.CreateContext(Addon.identifier)
local frame = UI.CreateFrame("RiftWindow", "", context)
local content = frame:GetContent()
local border = frame:GetBorder()
local filter
Ux.SearchWindow = frame
frame:SetVisible(false)
frame:SetTitle(L.Ux.WindowTitle.search)

Ux.RiftWindowCloseButton.New(frame, function() filter.text:SetKeyFocus(false) frame:SetVisible(false) end)

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

filter = Ux.Textfield.New(frame, "RIGHT", L.Ux.search)
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
	local offset = floor(scrollbar:GetPosition())
	for i = 1, #buttons do
		local button = buttons[i]
		local index = i + offset
		if(index > #display) then
			button:SetVisible(false)
		else
			button:SetVisible(true)
			local item = display[index]
			button.text:SetText(item[1])
			button.text:SetFontColor(Item.Type.Color(item[2]))
			button.icon:SetTextureAsync("Rift", item[3])
			button.type = item[4]
		end
	end
end

local function applySearchFilter()
	local pattern = filter.text:GetText()
	if(pattern == "" or pattern == L.Ux.search) then
		for i = 1, #items do
			display[i] = items[i]
		end
	else
		-- Make a case-insensitive search pattern
		pattern = strgsub(filter.text:GetText(), "%a", function(s)
			return format("[%s%s]", strlower(s), strupper(s))
		end)
		display = { }
		for i = 1, #items do
			local item = items[i]
			if(strfind(item[1], pattern)) then
				display[#display + 1] = item
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
	if(updater == nil) then
		applySearchFilter()
	else
		applyFilterAfterCoroutine = true
	end
end

scrollbar = UI.CreateFrame("RiftScrollbar", "", frame)
scrollbar:SetPoint("TOPRIGHT", filter, "BOTTOMRIGHT", 0, 2)
scrollbar:SetPoint("BOTTOMRIGHT", content, "BOTTOMRIGHT", -4, -4)
scrollbar.Event.ScrollbarChange = update
scrollbar:SetLayer(10)

local prevAnchor = filter
local prevAnchorOffset = -15
local top = filter:GetHeight()
for i = 1, displayItemsCount do
	local entry = UI.CreateFrame("Frame", "", frame)
	entry:SetPoint("TOPLEFT", prevAnchor, "BOTTOMLEFT", 0, 0)
	entry:SetPoint("TOPRIGHT", prevAnchor, "BOTTOMRIGHT", prevAnchorOffset, 0)
	prevAnchorOffset = 0
	prevAnchor = entry
	buttons[#buttons + 1] = entry

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
		self:SetBackgroundColor(0, 0, 0, 0.5)
	end
	entry.Event.MouseIn = entry.Event.MouseMove
	
	function entry.Event:MouseOut()
		Command.Tooltip(nil)
		self:SetBackgroundColor(0, 0, 0, 0)
	end
end

local function eventSystemUpdateBegin()
	if(updater ~= nil) then
		local ok, error = coroutine.resume(updater)
		if(coroutine.status(updater) == "dead") then
			updater = nil
			if(applyFilterAfterCoroutine) then
				applyFilterAfterCoroutine = false
				applySearchFilter()
			end
		end
		assert(ok, error)
	end
end

local function updateItemList(itemTypes)
	local now = InspectTimeReal()
	items = { }
	display = { }
	for k in pairs(itemTypes) do
		local result, detail = pcall(InspectItemDetail, k)
		if(result) then
			local n = strgsub(detail.name, "\n", "")
			items[#items + 1] = { n, detail.rarity, detail.icon, k }
			display[#display + 1] = items[#items]
		end
		if(InspectTimeReal() - now > 0.01) then
			coroutine.yield()
			now = InspectTimeReal()
		end
	end
	coroutine.yield()
	sort(items, function(a, b) return a[1] < b[1] end)
end

local function updateProc()
	local itemTypes = Item.Storage.GetAllItemTypes()
	coroutine.yield()
	updateItemList(itemTypes)
	coroutine.yield()
	applySearchFilter()
end

local function update()
	updater = coroutine.create(updateProc)
end

function content.Event:WheelBack()
	scrollbar:NudgeDown()
end

function content.Event:WheelForward()
	scrollbar:NudgeUp()
end

Event.System.Update.Begin[#Event.System.Update.Begin + 1] = {
	eventSystemUpdateBegin,
	Addon.identifier,
	"SearchWindow_eventSystemUpdateBegin"
}

-- Public methods
-- ============================================================================

function frame:Show()
	frame:SetVisible(true)
	filter.text:SetText("")
	filter.text:SetKeyFocus(true)
	
	update()
end

function frame:Toggle()
	if(frame:GetVisible()) then
		frame:SetVisible(false)
	else
		frame:Show()
	end
end
