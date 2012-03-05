local Addon, private = ...

-- Builtins
local ipairs = ipairs
local next = next
local pairs = pairs
local pcall = pcall
local table = table
local setmetatable = setmetatable

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
--			[mail] = { types }
		},
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
	for _, item in ipairs(mail.attachments) do
		item = Inspect.Item.Detail(item)
		if(item.type) then -- Is nil for money
			attachments[item.type] = (attachments[item.type] or 0) + (item.stack or 1)
		end
	end
	
	purge(matrix, mail.id, attachments)
	local t = { }
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

-- Remove mails from the matrix which no longer exist
function MailMatrix.Purge(matrix, mails)
	local empty = { }
	for mail in pairs(matrix.mails) do
		if(mails[mail] == nil) then
			log("purge", "mail", mail, matrix.lastUpdate)
			purge(matrix, mail, empty)
			matrix.mails[mail] = nil
		end
	end
	matrix.lastUpdate = Inspect.Time.Real() -- Inspect.Time.Frame() is not good enough and can cause multiple updates per frame
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

local MailMatrix_matrixMetaTable = {
	__index = {
		GetItemCount = MailMatrix.GetItemCount,
		MergeMail = MailMatrix.MergeMail,
		Purge = MailMatrix.Purge,
	}
}

function MailMatrix.ApplyMetaTable(matrix)
	if(not matrix) then
		return MailMatrix.New()
	else
		return setmetatable(matrix, MailMatrix_matrixMetaTable)
	end
end
