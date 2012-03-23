local Addon, private = ...

local Command = Command
local Inspect = Inspect
local Utility = Utility

setfenv(1, private)
ItemHandler = { }

-- Private methods
-- ============================================================================

local function moveToBank(slot)
	if(Ux.BankItemWindow:isAvailable() and #Ux.BankItemWindow.empty > 0) then
		Command.Item.Move(slot, Ux.BankItemWindow.empty[1])
	end
end

local function moveToInventory(slot)
	if(Ux.BackpackItemWindow:isAvailable() and #Ux.BackpackItemWindow.empty > 0) then
		Command.Item.Move(slot, Ux.BackpackItemWindow.empty[1])
	end
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
