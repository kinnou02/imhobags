local Addon, private = ...local ipairs = ipairslocal pairs = pairslocal string = stringlocal table = tablelocal UI = UI-- Frames cannot be deleted, keep a cache and only create new frames if the cache is emptylocal cachedLabels = { }setfenv(1, private)Ux = Ux or { }Ux.MailWindow = { }-- Private methods-- ============================================================================local function createLabel(self)	local label = UI.CreateFrame("Text", "", self)	label:SetText("")	label:SetWordwrap(true)	label:SetFontSize(14)	label:SetBackgroundColor(1, 1, 1, 0.1)	function label:Dispose()		self:SetVisible(false)		table.insert(cachedLabels, self)	end	function label:SetInfo(sell, slots)	end	-- Button for showing mail body	label.readButton = UI.CreateFrame("Texture", "", label)	label.readButton:SetWidth(22)	label.readButton:SetHeight(22)	label.readButton:SetTexture("Rift", [[Data/\UI\item_icons\charcoal_and_parchment.dds]])	label.readButton:SetPoint("TOPRIGHT", label, "TOPRIGHT")	label.readButton:SetAlpha(0.7)	function label.readButton.Event:MouseIn() self:SetAlpha(1.0) end	function label.readButton.Event:MouseOut() self:SetAlpha(0.7) end	function label.readButton.Event.LeftDown()		self:showBodyText(label.body)	end	-- CoD label	label.cod = UI.CreateFrame("Text", "", label)	label.cod:SetText(L.Ux.cashOnDelivery .. ": ")	label.cod:SetFontSize(12)	label.cod:SetFontColor(1.0, 1.0, 0)	label.cod:SetPoint("BOTTOMLEFT", label, "BOTTOMLEFT")	-- CoD money	label.codMoney = Ux.MoneyFrame.New(label.cod)	label.codMoney:SetPoint("LEFTCENTER", label.cod, "RIGHTCENTER")	return labelendlocal function getGroupLabel(self, mail)	local label	if(#cachedLabels == 0) then		label = createLabel(self)	else		label = table.remove(cachedLabels)		label:SetVisible(true)		label:SetParent(self)	end	label:SetText(string.format("%s: %s", mail[2].from, mail[2].subject))	if(mail[2].cod) then		label.cod:SetVisible(true)		label.codMoney:SetCoin(mail[2].cod)		label:SetHeight(label:GetFullHeight() + label.cod:GetFullHeight())	else		label.cod:SetVisible(false)		label:SetHeight(label:GetFullHeight())	end	label.body = mail[2].body	label.readButton:SetVisible(label.body and label.body ~= "")	return labelendlocal empty = { }local function sortGroups(self)	local function getItems(mail)		for k, v in pairs(self.groupKeys) do			if(v == mail) then				return k			end		end		return empty	end		self.sortedMails = { }	for mail, data in pairs(self.mails) do		table.insert(self.sortedMails, { self.mailSortKey(data), data, getItems(data) })	end	table.sort(self.sortedMails, function(a, b) return a[1] < b[1] end)endlocal function sortItems(self)	for _, group in ipairs(self.groups) do		table.sort(group, function(a, b) return self.sortFunc(a.type, b.type) end)	endendlocal function getGroups(self)	self.groups, self.groupKeys = ItemDB.GetGroupedItems(self.items, self.groupFunc)	self.mails = self.matrix:GetUnsortedMails()	sortGroups(self)	sortItems(self)endlocal function iterateGroups(self)	local i, n = 1, #self.sortedMails	local f = function(self)		if(i > n) then			return nil		else			local mail = self.sortedMails[i]			i = i + 1			return mail, mail[3]		end	end	return f, selfendlocal function leftUp(self)endlocal function setCharacter(self)	self.bodyFrame:SetText("")	self.bodyFrame:SetVisible(false)endlocal function onClose(self)	self.bodyFrame:SetText("")	self.bodyFrame:SetVisible(false)endlocal function showBodyText(self, text)		if(not self.bodyFrame:GetVisible()) then		self.bodyFrame:SetText(text)		self.bodyFrame:SetVisible(true)	else		if(self.bodyFrame:GetText() == text) then			self.bodyFrame:SetVisible(false)		else			self.bodyFrame:SetText(text)		end	endendlocal function applySearchFilter(self)	self:base_applySearchFilter()		-- Search in mail subject and body	if(self.searchString == "") then		for _, label in ipairs(self.groupLabels) do			label:SetBackgroundColor(1, 1, 1, 0.1)		end	else		for _, label in ipairs(self.groupLabels) do			if(string.find(label:GetText(), self.searchString) or string.find(label.body, self.searchString)) then				label:SetBackgroundColor(0, 1, 0, 0.1)			else				label:SetBackgroundColor(1, 1, 1, 0.1)			end		end	endend-- Public methods-- ============================================================================function Ux.MailWindow.New(title, character, location, condensed, native)	local self = Ux.ItemWindowBase.New(title, character, "mail", true, nil)		self.mailButton:SetIcon([[Data/\UI\item_icons\bag20.dds]])	function self.mailButton.LeftPress()		Ux.ToggleItemWindow(self.charSelector:GetText(), "inventory")	end		self.condensedCeck:SetVisible(false)	self.filter:SetPoint("BOTTOMRIGHT", self.condensedCeck, "TOPRIGHT", 0, 23)		local left, top, right, bottom = self:GetTrimDimensions()	-- Create side window with mail body text	self.bodyFrame = UI.CreateFrame("Text", "", self)	self.bodyFrame:SetFontSize(13)	self.bodyFrame:SetWordwrap(true)	self.bodyFrame:SetVisible(false)	self.bodyFrame:SetWidth(300)	self.bodyFrame:SetHeight(300)	self.bodyFrame:SetBackgroundColor(0, 0, 0, 0.8)	self.bodyFrame:SetPoint("TOPLEFT", self, "TOPRIGHT", -5, top + 5)	self.showBodyText = showBodyText	self.base_applySearchFilter = self.applySearchFilter	self.applySearchFilter = applySearchFilter	self.onClose = onClose	self.getGroups = getGroups	self.leftUp = leftUp	self.setCharacter = setCharacter	self.getGroupLabel = getGroupLabel	self.iterateGroups = iterateGroups	self.groupFunc = Group.Default.GetMail	self.groupSortFunc = Group.Default.SortByCategoryKey	self.sortFunc = Sort.Default.ByItemName	self.mailSortKey = function(mail) return string.lower(mail.from .. ": " .. mail.subject) end		self:SetCharacter(character, "mail")		return selfend