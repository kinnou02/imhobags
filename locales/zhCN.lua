local private = select(2, ...)

if(Inspect.System.Language() ~= "Chinese" ) then
	return
end

setfenv(1, private)
L = { }
--@localization(locale="zhCN", format="lua_additive_table", table-name="L", handle-unlocalized="english", handle-subnamespaces="subtable")@