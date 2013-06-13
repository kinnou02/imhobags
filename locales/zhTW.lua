local private = select(2, ...)

if(Inspect.System.Language() ~= "Taiwanese" ) then
	return
end

setfenv(1, private)
L = { }
--@localization(locale="zhTW", format="lua_additive_table", table-name="L", handle-unlocalized="english", handle-subnamespaces="subtable")@
