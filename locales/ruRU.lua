local Addon, private = ...

if(Inspect.System.Language() ~= "Russian" ) then
	return
end

setfenv(1, private)
L = { }
--@localization(locale="ruRU", format="lua_additive_table", table-name="L", handle-unlocalized="english", handle-subnamespaces="subtable")@
