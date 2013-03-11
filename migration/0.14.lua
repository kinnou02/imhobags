local Addon, private = ...

local function migrateSavedVariables(handle, identifier)
	if(identifier ~= Addon.identifier) then
		return
	end

	if(ImhoBags_ItemStorage) then
		local version = ImhoBags_ItemStorage.version or 0.0
		if(version < 0.14) then
			ImhoBags_ItemStorage = nil
			Command.Console.Display("general", true, "<font color='#FFC000'>Incompatible item database: deleting all characters.</font>", true)
		end
	end

	if(ImhoBags_WindowInfo) then
		local info = ImhoBags_WindowInfo
		local version = info.version or 0.0
		if(version < 0.14) then
			info.ItemContainer = { }
			if(info.inventory) then
				info.ItemContainer.inventory = info.inventory
				info.inventory = nil
				info.BackpackItemWindow = nil
			elseif(info.BackpackItemWindow) then
				info.ItemContainer.inventory = info.BackpackItemWindow
				info.BackpackItemWindow = nil
				info.ItemContainer.inventory.sort = info.ItemContainer.inventory.sorting
			end
			
			if(info.bank) then
				info.ItemContainer.bank = info.bank
				info.bank = nil
				info.BankItemWindow = nil
			elseif(info.BankItemWindow) then
				info.ItemContainer.bank = info.BankItemWindow
				info.BankItemWindow = nil
				info.ItemContainer.bank.sort = info.ItemContainer.bank.sorting
			end
			
			if(info.currency) then
				info.ItemContainer.currency = info.currency
				info.currency = nil
				info.CurrencyItemWindow = nil
			elseif(info.CurrencyItemWindow) then
				info.ItemContainer.currency = info.CurrencyItemWindow
				info.CurrencyItemWindow = nil
				info.ItemContainer.currency.sort = info.ItemContainer.currency.sorting
			end
			
			if(info.equipment) then
				info.ItemContainer.equipment = info.equipment
				info.equipment = nil
				info.EquipmentItemWindow = nil
			elseif(info.EquipmentItemWindow) then
				info.ItemContainer.equipment = info.EquipmentItemWindow
				info.EquipmentItemWindow = nil
				info.ItemContainer.equipment.sort = info.ItemContainer.equipment.sorting
			end
			
			if(info.guildbank) then
				info.ItemContainer.guildbank = info.guildbank
				info.guildbank = nil
				info.GuildItemWindow = nil
			elseif(info.GuildItemWindow) then
				info.ItemContainer.guildbank = info.GuildItemWindow
				info.GuildItemWindow = nil
				info.ItemContainer.guildbank.sort = info.ItemContainer.guildbank.sorting
			end
			
			if(info.quest) then
				info.ItemContainer.quest = info.quest
				info.quest = nil
			end

			info.MailItemWindow = nil
			info.WardrobeItemWindow = nil
		end
	end
end

Command.Event.Attach(Event.Addon.SavedVariables.Load.End, migrateSavedVariables, "")
