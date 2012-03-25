local Addon, private = ...

-- Builtins
local pairs = pairs

-- Globals
local Command = Command
local Inspect = Inspect
local Utility = Utility

setfenv(1, private)
ItemHandler = { }

-- Private methods
-- ============================================================================

local function findTargetSlot(location, stack, max, type)
	local matrix = ItemDB.GetItemMatrix("player", location)
	for slot, count in pairs(matrix.items[type] or { }) do
		if(count + stack <= max) then
			return slot
		end
	end
	return nil
end

local function moveToLocation(window, slot)
	if(window:isAvailable()) then
		-- Find a slot where the item fits
		local item = Inspect.Item.Detail(slot)
		local target = findTargetSlot(window.location, item.stack or 1, item.stackMax or 1, item.type)
		if(target) then
			Command.Item.Move(slot, target)
		elseif(#window.empty > 0) then
			Command.Item.Move(slot, window.empty[1])
		end
	end
end

local function moveToBank(slot)
	moveToLocation(Ux.BankItemWindow, slot)
end

local function moveToInventory(slot)
	moveToLocation(Ux.BackpackItemWindow, slot)
end

-- Public methods
-- ============================================================================

function ItemHandler.UseItem(slot)
	local location = Utility.Item.Slot.Parse(slot)
	if(location == "inventory") then
		local interaction = Inspect.Interaction()
		if(interaction.bank) then
			moveToBank(slot)
--		elseif(interaction.guildbank) then
--			Command.Item.Move(slot, Utility.Item.Slot.Guild())
		end
	elseif(location == "bank") then
		moveToInventory(slot)
	end
end
