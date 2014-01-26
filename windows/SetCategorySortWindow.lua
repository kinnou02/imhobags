local Addon, private = ...

-- Upvalue
local Library = Library

setfenv(1, private)
Ux = Ux or { }

local categoryOrderList = { }
local categoryList = { }
local ItemList
local list_aux = {
    borders = {},
    fields = {},
    category_names = {},
    sort_order = {},
}

-- Private methods
-- ============================================================================
local context = UI.CreateContext(Addon.identifier)
local frame = UI.CreateFrame("RiftWindow", "", context)
frame:SetVisible(false)
frame:SetTitle(L.Ux.WindowTitle.CategorySort)
frame:SetWidth(260)
frame:SetHeight(1000)
local border = frame:GetBorder()
Ux.SetCategorySortWindow = frame

local function onSetCategorySortWindowClose()
	for _,SortOrderTextFields in pairs(list_aux.sort_order) do
		SortOrderTextFields:SetKeyFocus(false)
	end
	if (_G.ImhoBags_WindowInfo.SetCategorySortWindow) then
		_G.ImhoBags_WindowInfo.SetCategorySortWindow.x = Ux.SetCategorySortWindow:GetLeft()
		_G.ImhoBags_WindowInfo.SetCategorySortWindow.y = Ux.SetCategorySortWindow:GetTop()
	end
	frame:FadeOut()
end
Ux.RiftWindowCloseButton.New(frame, onSetCategorySortWindowClose)

local SetCategorySortWindow_Contents = Ux.SetCategorySortWindow:GetContent()

local itemListFrame = UI.CreateFrame("Frame",Addon.identifier .. "_itemListFrame", SetCategorySortWindow_Contents)
itemListFrame:SetPoint("TOPLEFT", SetCategorySortWindow_Contents, "TOPLEFT", 2, 40)
itemListFrame:SetPoint("BOTTOMRIGHT", SetCategorySortWindow_Contents, "BOTTOMRIGHT", -1, -40)

local instructions = UI.CreateFrame("Text", Addon.identifier .. "_instructions", SetCategorySortWindow_Contents)
instructions:SetPoint("TOPLEFT", SetCategorySortWindow_Contents, "TOPLEFT", 2, 2)
instructions:SetText(L.Ux.SetCategorySortWindow.instructions)

-----------------
-- Attach events to the window's border
border:EventAttach(Event.UI.Input.Mouse.Left.Down, function(self)
	local mouse = Inspect.Mouse()
	self.mouseOffsetX = mouse.x - Ux.SetCategorySortWindow:GetLeft()
	self.mouseOffsetY = mouse.y - Ux.SetCategorySortWindow:GetTop()
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
		Ux.SetCategorySortWindow:SetPoint("TOPLEFT", UIParent, "TOPLEFT", mouse.x - self.mouseOffsetX, mouse.y - self.mouseOffsetY)
	end
end, "")
--
-----------------

-----------------
-- Set-up "Apply" button and attach callback event on left click
local ApplyButton = UI.CreateFrame("RiftButton", Addon.identifier .. "_ApplyButton", SetCategorySortWindow_Contents)
ApplyButton:SetPoint("BOTTOMCENTER", SetCategorySortWindow_Contents, "BOTTOMCENTER")
ApplyButton:SetText("Apply")

local function ApplyButton_leftclick()
	local used = { }
	local new_categoryOrderList = { } 
	local new_categoryList = { } 
	
	for _, textField in pairs(list_aux.sort_order) do
		local textFieldParent = textField:GetParent()
		local category_name = textFieldParent:GetText()
		local category_order = textField:GetText()
		--print("category_name: " .. category_name .. " -> " .. category_order)
		
		-----------------
		-- sanity checks
		if (category_order == nil or tonumber(category_order) == nill or tonumber(category_order) < 1 or tonumber(category_order) > #categoryList) then
			local message = string.format(L.Ux.SetCategorySortWindow.catSortOrderNotValidMsg1, category_name, category_order, #categoryList)
			Ux.DoPopup(1,message)
			textField:SetText("")
			textField:SetKeyFocus(false)
			return
		end
		if (used[category_order] == true) then
			local message = string.format(L.Ux.SetCategorySortWindow.catSortOrderNotValidMsg2, category_name, category_order, #categoryList)
			Ux.DoPopup(1,message)
			textField:SetText("")
			textField:SetKeyFocus(false)
			return
		end
		--
		-----------------
		
		new_categoryOrderList[category_name] = tonumber(category_order)
		used[category_order] = true
		textField:SetKeyFocus(false)
	end
	
	categoryList = Group.Default.SortCategoryNames(categoryList, new_categoryOrderList)
	categoryOrderList = new_categoryOrderList
	ItemList.u.buffers = categoryOrderList
	ItemList:display(categoryList)
	
	-- Save
	Config.categoryList = categoryList
	Config.categoryOrderList = categoryOrderList
	
	-- Apply to item windows
	for window_location,window in pairs(Ux.ItemWindow) do
		log(string.format("DEBUG: updating layout for '%s'",tostring(window_location)))
		-- For Reference (and for testing), the 'container' for the main inventory window is Ux.ItemWindow["inventory"].container
		if window.container then
			window.container:SetNeedsLayout()
		end
	end

end
ApplyButton:EventAttach(Event.UI.Input.Mouse.Left.Click, ApplyButton_leftclick, "SetCategorySortwindow_apply")
--
-----------------


-----------------
--
local function SortOrder_TextFieldChanged(self)
	local order = self:GetText()
	local parent = self:GetParent()
	local category = parent:GetText()
	
	if (orer == nil) then
		return
	end
	
	if (tonumber(order) > #categoryList) then
		local message = string.format(L.Ux.SetCategorySortWindow.catSortOrderNotValidMsg1, category, order, #categoryList)
		Ux.DoPopup(1,message)
		self:SetText("1")
		self:SetKeyFocus(false)
	end
end

local function MakeListItem(tab, frame, i)
  tab.u.borders[i] = UI.CreateFrame("Frame", "list" .. i, frame)
  tab.u.borders[i]:SetPoint("TOPLEFT", frame, "TOPLEFT", 1, 1)
  tab.u.borders[i]:SetBackgroundColor(0.3, 0.3, 0.3, 0.8)
  tab.u.borders[i]:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -1, -1)
  tab.u.borders[i]:SetMouseMasking('limited')

  tab.u.fields[i] = UI.CreateFrame("Frame", "list" .. i, tab.u.borders[i])
  tab.u.fields[i]:SetPoint("TOPLEFT", tab.u.borders[i], "TOPLEFT", 2, 2)
  tab.u.fields[i]:SetPoint("BOTTOMRIGHT", tab.u.borders[i], "BOTTOMRIGHT", -2, -2)
  tab.u.fields[i]:SetBackgroundColor(0.1, 0.1, 0.1, 0.8)
  tab.u.fields[i]:SetMouseMasking('limited')

  tab.u.category_names[i] = UI.CreateFrame("Text", Addon.identifier, tab.u.fields[i])
  tab.u.category_names[i]:SetPoint("TOPLEFT", tab.u.fields[i], "TOPLEFT", 2, 2)
  tab.u.category_names[i]:SetFontColor(0.9, 0.9, 0.9, 1)
  tab.u.category_names[i]:SetMouseMasking('limited')
  tab.u.category_names[i]:SetFontSize(16)
  tab.u.category_names[i]:SetWidth(150)
  
  tab.u.sort_order[i] = UI.CreateFrame("RiftTextfield",Addon.identifier, tab.u.category_names[i])
	tab.u.sort_order[i]:SetPoint("TOPLEFT", tab.u.category_names[i], "TOPRIGHT", 0, 4)
	tab.u.sort_order[i]:SetBackgroundColor(0, 0, 0, 0.5)
	tab.u.sort_order[i]:SetWidth(28)
	tab.u.sort_order[i]:EventAttach(Event.UI.Textfield.Change, SortOrder_TextFieldChanged, "SetCategorySortWindow_TextFieldChange")
end

local function ShowListItem(frametable, i, itemtable, itemindex, selected)
	local category = itemtable[itemindex]
	
	if category then
		local sort_order = categoryOrderList[category]
		if not sort_order then
			print("No details for category " .. category)
		end
		frametable.u.category_names[i]:SetText(tostring(category))
		frametable.u.sort_order[i]:SetText(tostring(sort_order))
		
		if selected then
			frametable.u.borders[i]:SetBackgroundColor(0.5, 0.5, 0.3, 0.8)
		else
			frametable.u.borders[i]:SetBackgroundColor(0.3, 0.3, 0.3, 0.8)
		end
	else
		frametable.u.category_names[i]:SetText('')
		frametable.u.sort_order[i]:SetText('')
		frametable.u.borders[i]:SetBackgroundColor(0.3, 0.3, 0.3, 0.8)
	end
end

local function SelectListItem(frametable, frameindex, itemtable, itemindex)
  local tab = frametable
  if not tab then
    return
  end
  item = itemtable[itemindex]
  if item then
   	-- UNUSED
  end
end

-----------------
-- Initial setup (performed when addon first loaded)

-- Note: This routine could also be used for a RESET
if #categoryList < 1 then
	local nameFound = false
	for key, name in pairs(L.CategoryName) do
		for _,v in pairs(categoryList) do
			if (v == name) then
				nameFound = true
			end
		end
		if not nameFound then
			if (name ~= L.CategoryName.empty and name ~= L.CategoryName.sellable and name ~= L.CategoryName.wardrobe) then
				table.insert(categoryList,name)
			end
		end
		nameFound = false
	end
end

-- Note: This routine could also be used for a RESET
if #categoryOrderList < 1 then
	table.sort(categoryList)
	local order = 1
	for _, name in pairs(categoryList) do
		categoryOrderList[name] = order
		order = order + 1
	end
end

ItemList = Library.LibItemList.create(itemListFrame, Addon.identifier, list_aux, #categoryList, 'RIGHT', MakeListItem, ShowListItem, SelectListItem)
ItemList.u.buffers = categoryOrderList
ItemList:display(categoryList)
--
-----------------

-- Public methods
-- ============================================================================

function frame:Show()
	local info = _G.ImhoBags_WindowInfo.SetCategorySortWindow
	if(info) then
		Ux.SetCategorySortWindow:SetPoint("TOPLEFT", UIParent, "TOPLEFT", info.x, info.y)
	else
		Ux.centerWindow(Ux.SetCategorySortWindow)
		_G.ImhoBags_WindowInfo.SetCategorySortWindow = {
			x = Ux.SetCategorySortWindow:GetLeft(),
			y = Ux.SetCategorySortWindow:GetTop(),
		}
	end
	frame:FadeIn()
end

function frame:Toggle()
	if(not self:GetVisible()) then
		if #Config.categoryList > 0 then
			categoryList = Config.categoryList
			categoryOrderList = Config.categoryOrderList
		end
		ItemList.u.buffers = categoryOrderList
		ItemList:display(categoryList)
		self:Show()
	elseif(self:FadingOut()) then
		self:Show()
	else
		_G.ImhoBags_WindowInfo.SetCategorySortWindow.x = Ux.SetCategorySortWindow:GetLeft()
		_G.ImhoBags_WindowInfo.SetCategorySortWindow.y = Ux.SetCategorySortWindow:GetTop()
		for _,SortOrderTextFields in pairs(list_aux.sort_order) do
			SortOrderTextFields:SetKeyFocus(false)
		end		
		self:FadeOut()
	end
end
