local Addon, private = ...

local type = type

local UI = UI

setfenv(1, private)
Ux = Ux or { }
Ux.RiftWindowCloseButton = { }

function Ux.RiftWindowCloseButton.New(parent, closeTarget)
	local btn = UI.CreateFrame("RiftButton", "", parent)
	btn:SetSkin("close")
	btn:SetPoint("TOPRIGHT", parent, "TOPRIGHT", -8, 15)
	if(type(closeTarget) == "function") then
		btn.Event.LeftPress = closeTarget
	else
		function btn.Event:LeftPress()
			closeTarget:SetVisible(false)
		end
	end
	return btn
end
