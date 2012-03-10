local Addon, private = ...

-- Builtins
local ipairs = ipairs
local next = next
local pairs = pairs
local pcall = pcall
local setmetatable = setmetatable
local string = string
local table = table

-- Globals
local dump = dump

local Inspect = Inspect

setfenv(1, private)
MailMatrix = { }

-- Private methods
-- ============================================================================

local function purge(matrix, mail, attachments)
	if(matrix.mails[mail]) then
		for _, type in ipairs(matrix.mails[mail]) do
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
		local result, detail = pcall(Inspect.Item.Detail, itemType)
		success = success and result
		if(result) then
			for mail, count in pairs(slots) do
				table.insert(items, { type = detail, slots = 1, stack = count })
				items[#items].type.ImhoBags_mailSubject = matrix.mails[mail].subject
			end
		end
	end
	-- Get coin info
	-- Won't work right now as coin attachments don't get tooltips
	for mail, data in pairs(matrix.mails) do
		if(data.coin) then
			local type = {
				ImhoBags_mailSubject = data.subject,
				name = Utils.FormatCoin(data.coin),
				icon = (data.coin > 10000 and [[Data/\UI\item_icons\loot_platinum_coins.dds]]) or
					(data.coin > 100 and [[Data/\UI\item_icons\loot_gold_coins.dds]]) or [[Data/\UI\item_icons\loot_silver_coins.dds]],
			}
			table.insert(items, { type = type, slots = 1, stack = data.coin })
		end
	end
	return items, 0, success
end

-- Public methods
-- ============================================================================

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
				subject = "sender: subject"
]]		},
		lastUpdate = -1, -- Forced to -1 on save
	}
	return setmetatable(matrix, MailMatrix_matrixMetaTable)
end

--[[
Merge a mail change into the matrix.
Also available as instance metamethod.
]]
function MailMatrix.MergeMail(matrix, mail)
	local attachments = { }
	local coin = nil
	for _, item in ipairs(mail.attachments) do
		item = Inspect.Item.Detail(item)
		if(item.type) then -- Is nil for money
			attachments[item.type] = (attachments[item.type] or 0) + (item.stack or 1)
		else
			coin = item.coin
		end
	end
	
	purge(matrix, mail.id, attachments)
	if(next(attachments) == nil) then
		log("deleting mail")
		matrix.mails[mail.id] = nil
		matrix.subjects[mail.id] = nil
		return
	end
	
	local t = matrix.mails[mail.id] or {
		subject = string.format("%s: %s", mail.from, mail.subject),
		body = mail.body,
		coin = coin,
	}
	for type in pairs(attachments) do
		table.insert(t, type)
	end
	matrix.mails[mail.id] = t

	for type, count in pairs(attachments) do
		if(not matrix.items[type]) then
			matrix.items[type] = { }
		end
		matrix.items[type][mail.id] = count
	end
	matrix.lastUpdate = Inspect.Time.Real() -- Inspect.Time.Frame() is not good enough and can cause multiple updates per frame
	log("update", "mail", mail.id, matrix.lastUpdate)
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

function MailMatrix.GetAllItemTypes(matrix, result)
	for k in pairs(matrix.items) do
		result[k] = true
	end
end

local MailMatrix_matrixMetaTable = {
	__index = {
		GetAllItemTypes = MailMatrix.GetAllItemTypes,
		GetItemCount = MailMatrix.GetItemCount,
		GetUnsortedItems = MailMatrix.GetUnsortedItems,
		MergeMail = MailMatrix.MergeMail,
	}
}

function MailMatrix.ApplyMetaTable(matrix)
	if(not matrix) then
		return MailMatrix.New()
	else
		return setmetatable(matrix, MailMatrix_matrixMetaTable)
	end
end
