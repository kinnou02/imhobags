local Addon, private = ...

if(Inspect.System.Language() ~= "French" ) then
	return
end

setfenv(1, private)
L = { }
--@localization(locale="frFR", format="lua_additive_table", table-name="L", handle-unlocalized="english", handle-subnamespaces="subtable")
