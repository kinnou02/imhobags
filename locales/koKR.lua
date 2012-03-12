local private = select(2, ...)

if(Inspect.System.Language() ~= "Korean" ) then
	return
end

setfenv(1, private)
L = { }
--@localization(locale="koKR", format="lua_additive_table", table-name="L", handle-unlocalized="english", handle-subnamespaces="subtable")@
