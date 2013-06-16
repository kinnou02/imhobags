local Addon, private = ...

-- Upvalue
local InspectItemDetail = Inspect.Item.Detail
local InspectTimeReal = Inspect.Time.Real

setfenv(1, private)
Ux = Ux or { }

local displayItemsCount = 24
local applyFilterAfterCoroutine = false
local updater
local applySearchFilter

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

Ux.RiftWindowCloseButton.New(frame, function() filter.text:SetKeyFocus(false) frame:FadeOut() end)

border:EventAttach(Event.UI.Input.Mouse.Left.Down, function(self)
	local mouse = Inspect.Mouse()
	self.mouseOffsetX = mouse.x - frame:GetLeft()
	self.mouseOffsetY = mouse.y - frame:GetTop()
end, "")

border:EventAttach(Event.UI.Input.Mouse.Left.Up, function(self)
	self.mouseOffsetX, self.mouseOffsetY = nil, nil
end, "")

border:EventAttach(Event.UI.Input.Mouse.Left.Upoutside, function(self)
	self.mouseOffsetX, self.mouseOffsetY = nil, nil
end, "")

border:EventAttach(Event.UI.Input.Mouse.Cursor.Move, function(self)
	local mouse = Inspect.Mouse()
	if(self.mouseOffsetX) then
		frame:SetPoint("TOPLEFT", UIParent, "TOPLEFT", mouse.x - self.mouseOffsetX, mouse.y - self.mouseOffsetY)
	end
end, "")

filter = Ux.Textfield.New(frame, "RIGHT", L.Ux.search, function() applySearchFilter() end)
filter:SetPoint("TOPLEFT", content, "TOPLEFT", 4, 0)
filter:SetPoint("BOTTOMRIGHT", content, "TOPRIGHT", -4, 24)
filter.text:EventAttach(Event.UI.Input.Key.Focus.Gain, function(self)
	if(self:GetText() == L.Ux.search) then
		self:SetText("")
	end
end, "")

filter.text:EventAttach(Event.UI.Input.Key.Focus.Loss, function(self)
	if(self:GetText() == "") then
		self:SetText(L.Ux.search)
	end
end, "")

local scrollbar
local display = { }
local buttons = { }
local items = { }

local function update()
	local offset = math.floor(scrollbar:GetPosition())
	for i = 1, #buttons do
		local button = buttons[i]
		local index = i + offset
		if(index > #display) then
			button:FadeOut()
		else
			button:FadeIn()
			local item = display[index]
			button.text:SetText(item[1])
			button.text:SetFontColor(Item.Type.Color(item[2]))
			button.icon:SetTextureAsync("Rift", item[3])
			button.type = item[4]
		end
	end
end

applySearchFilter = function()
	local pattern = filter.text:GetText()
	if(pattern == "" or pattern == L.Ux.search) then
		for i = 1, #items do
			display[i] = items[i]
		end
	else
		-- Make a case-insensitive search pattern
		local format = string.format
		local strlower = string.lower
		local strupper = string.upper
		pattern = string.gsub(filter.text:GetText(), "%a", function(s)
			return format("[%s%s]", strlower(s), strupper(s))
		end)
		display = { }
		local strfind = string.find
		for i = 1, #items do
			local item = items[i]
			if(strfind(item[1], pattern)) then
				display[#display + 1] = item
			end
		end
	end

	scrollbar:SetRange(0, math.max(0, #display - displayItemsCount))
	scrollbar:SetPosition(0)
	scrollbar:SetEnabled(#display - displayItemsCount > 0)

	update()
end

filter.text:EventAttach(Event.UI.Textfield.Change, function()
	if(updater == nil) then
		applySearchFilter()
	else
		applyFilterAfterCoroutine = true
	end
end, "")

scrollbar = UI.CreateFrame("RiftScrollbar", "", frame)
scrollbar:SetPoint("TOPRIGHT", filter, "BOTTOMRIGHT", 0, 2)
scrollbar:SetPoint("BOTTOMRIGHT", content, "BOTTOMRIGHT", -4, -4)
scrollbar:EventAttach(Event.UI.Scrollbar.Change, update, "")
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
	
	local f = function(self)
		Command.Tooltip(self.type)
		-- Temporary fix while tooltip is displayed in top-left
		Ux.TooltipEnhancer:ClearAll();
		Ux.TooltipEnhancer:SetPoint("TOPLEFT", frame, "BOTTOMLEFT", 6, -4)
		Ux.TooltipEnhancer:SetPoint("TOPRIGHT", frame, "BOTTOMRIGHT", -6, -4)
		self:SetBackgroundColor(0, 0, 0, 0.5)
	end
	entry:EventAttach(Event.UI.Input.Mouse.Cursor.Move, f, "")
	entry:EventAttach(Event.UI.Input.Mouse.Cursor.In, f, "")
	
	entry:EventAttach(Event.UI.Input.Mouse.Cursor.Out, function(self)
		Command.Tooltip(nil)
		self:SetBackgroundColor(0, 0, 0, 0)
	end, "")
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
	local gsub = string.gsub
	for k in pairs(itemTypes) do
		local result, detail = pcall(InspectItemDetail, k)
		if(result) then
			local n = gsub(detail.name, "\n", "")
			items[#items + 1] = { n, detail.rarity, detail.icon, k }
			display[#display + 1] = items[#items]
		end
		if(InspectTimeReal() - now > 0.01) then
			coroutine.yield()
			now = InspectTimeReal()
		end
	end
	coroutine.yield()
	table.sort(items, function(a, b) return a[1] < b[1] end)
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

content:EventAttach(Event.UI.Input.Mouse.Wheel.Back, function()
	scrollbar:NudgeDown()
end, "")

content:EventAttach(Event.UI.Input.Mouse.Wheel.Forward, function()
	scrollbar:NudgeUp()
end, "")

Command.Event.Attach(Event.System.Update.Begin, eventSystemUpdateBegin, "SearchWindow_eventSystemUpdateBegin")

-- Public methods
-- ============================================================================

function frame:Show()
	frame:FadeIn()
	filter.text:SetText("")
	filter.text:SetKeyFocus(true)
	
	update()
end

function frame:Toggle()
	if(not self:GetVisible()) then
		self:Show()
	elseif(self:FadingOut()) then
		self:Show()
	else
		self:FadeOut()
	end
end
