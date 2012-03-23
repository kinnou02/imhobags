local Addon, private = ...

-- Builtins
local next = next
local pairs = pairs
local pcall = pcall
local setmetatable = setmetatable

-- Globals
local InspectItemDetail = Inspect.Item.Detail
local InspectTimeReal = Inspect.Time.Real

setfenv(1, private)
MailMatrix = { }

-- Private methods
-- ============================================================================

local function purge(matrix, mail, attachments)
	local t = matrix.mails[mail]
	if(t) then
		for i = 1, #t do
			local type = t[i]
			if(not attachments[type] and matrix.items[type]) then
				matrix.items[type][mail] = nil
				-- Delete empty entries or otherwise the table will grow indefinitely
				if(next(matrix.items[type]) == nil) then
					matrix.items[type] = nil
				end
			end
		end
	end
end

local function extractUnsortedCharacterItems(matrix)
	local items = { }
	local success = true
	for itemType, slots in pairs(matrix.items) do
		-- Because the mail window does not allow for item manipulation
		-- all stacks are condensed.

		-- If looking at other characters item information might not be available.
		-- In this case Inspect.Item.Detail throws an error and we need to remember
		-- to ask later.
		local result, detail = pcall(InspectItemDetail, itemType)
		success = success and result
		if(result) then
			for mail, count in pairs(slots) do
				local t = {
					name = detail.name,
					type = itemType,
					id = detail.type,
					category = detail.category,
					icon = detail.icon,					
					ImhoBags_mail = matrix.mails[mail],
					rarity = detail.rarity,
				}
				items[#items + 1] = { type = t, slots = 1, stack = count, mail = matrix.mails[mail] }
			end
		end
	end
	-- Get coin info
	for mail, data in pairs(matrix.mails) do
		if(data.coin) then
			local type = {
				ImhoBags_mail = data,
				name = Utils.FormatCoin(data.coin),
				icon = (data.coin >= 10000 and [[Data/\UI\item_icons\loot_platinum_coins.dds]]) or
					(data.coin >= 100 and [[Data/\UI\item_icons\loot_gold_coins.dds]]) or [[Data/\UI\item_icons\loot_silver_coins.dds]],
			}
			items[#items + 1] = { type = type, slots = 1, stack = 1 }
		end
	end
	return items, 0, success
end

-- Public methods
-- ============================================================================

local matrixMetaTable
function MailMatrix.New()
	local matrix = {
		items = {
--[[		[type] = {
				[mail] = count
			}
]]		},
		mails = {
--[[		[mail] = {
				[#] = type,
				subject = string,
				from = string,
				body = string,
				cod = number, -- may be nil
				coin = number, -- may be nil
]]		},
		lastUpdate = -1, -- Forced to -1 on save
	}
	return setmetatable(matrix, matrixMetaTable)
end

--[[
Merge a mail change into the matrix.
Also available as instance metamethod.
]]
function MailMatrix.MergeMail(matrix, mail)
	local attachments = { }
	local coin = nil
	if(mail.attachments) then
		for i = 1, #mail.attachments do
			local item = InspectItemDetail(mail.attachments[i])
			if(item.type) then -- Is nil for money
				item.type = Utils.FixItemType(item.type)
				attachments[item.type] = (attachments[item.type] or 0) + (item.stack or 1)
			else
				coin = item.coin
			end
		end
	end
	
	purge(matrix, mail.id, attachments)
	
	local t = matrix.mails[mail.id] or {
		from = mail.from,
		subject = mail.subject,
		body = mail.body,
	}
	for type in pairs(attachments) do
		t[#t + 1] = type
	end
	t.coin = coin
	t.cod = mail.cod
	matrix.mails[mail.id] = t

	for type, count in pairs(attachments) do
		if(not matrix.items[type]) then
			matrix.items[type] = { }
		end
		matrix.items[type][mail.id] = count
	end
	matrix.lastUpdate = InspectTimeReal() -- Inspect.Time.Frame() is not good enough and can cause multiple updates per frame
	log("update", "mail", mail.id, matrix.lastUpdate)
end

-- Remove mails from the matrix which no longer exist.
-- Also available as instance metamethod.
function MailMatrix.Purge(matrix, mails)
	local empty = { }
	for mail in pairs(matrix.mails) do
		if(not mails[mail]) then
			log("purge", "mail", mail, matrix.lastUpdate)
			purge(matrix, mail, empty)
			matrix.mails[mail] = nil
		end
	end
	matrix.lastUpdate = InspectTimeReal() -- Inspect.Time.Frame() is not good enough and can cause multiple updates per frame
end

--[[
Get the list of items for this container in one flat table and no particular sorting.
The returned list serves as staging base for further operations.
Also available as instance metamethod.
condensed: True to condense max stacks together into one displayed item (ignored for mails)
return: items, empty, success
	"success" determines whether all items could be retrieved successfully or
	whether the local item cache is incomplete and you have to try again later.
	This is common if requesting items from other characters than the player and
	you need to call the function later to retrieve the remaining items until succes becomes true.
	
	The other return values are as follows:
	
	items = { -- Array
		[#] = {
			type = result of Inspect.Item.Detail(type),-- Includes ImhoBags_mailSubject field for mail subject line,
			slots = number, -- always 1 for mails
			stack = #, -- displayed stack size
		}
	}
	empty = number
]]
function MailMatrix.GetUnsortedItems(matrix, condensed)
	return extractUnsortedCharacterItems(matrix)
end

-- Get the amount of items in this matrix of the given item type (including bags).
-- Also available as instance metamethod.
function MailMatrix.GetItemCount(matrix, itemType)
	local result = 0
	local entry = matrix.items[itemType]
	if(entry) then
		for slot, count in pairs(entry) do
			result = result + count
		end
	end
	return result
end

function MailMatrix.GetAllItemTypes(matrix, result, accountBoundOnly)
	if(accountBoundOnly) then
		for k in pairs(matrix.items) do
			local s, detail = pcall(InspectItemDetail, k)
			if(s and detail.bind == "account") then
				result[k] = true
			end
		end
	else
		for k in pairs(matrix.items) do
			result[k] = true
		end
	end
end

function MailMatrix.GetUnsortedMails(matrix, character)
	return matrix.mails
end

local matrixMetaTable = {
	__index = {
		GetAllItemTypes = MailMatrix.GetAllItemTypes,
		GetItemCount = MailMatrix.GetItemCount,
		GetUnsortedItems = MailMatrix.GetUnsortedItems,
		GetUnsortedMails = MailMatrix.GetUnsortedMails,
		MergeMail = MailMatrix.MergeMail,
		Purge = MailMatrix.Purge,
	}
}

function MailMatrix.ApplyMetaTable(matrix)
	if(not matrix) then
		return MailMatrix.New()
	else
		return setmetatable(matrix, matrixMetaTable)
	end
end
