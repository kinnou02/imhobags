local Addon, private = ...

setfenv(1, private)
Ux = Ux or { }
Ux.RiftWindowCloseButton = { }

function Ux.RiftWindowCloseButton.New(parent, closeTarget)
	local btn = UI.CreateFrame("RiftButton", "", parent)
	btn:SetSkin("close")
	btn:SetPoint("TOPRIGHT", parent:GetBorder(), "TOPRIGHT", -8, 16)
	if(type(closeTarget) == "function") then
		btn.Event.LeftPress = closeTarget
	else
		function btn.Event:LeftPress()
			closeTarget:SetVisible(false)
		end
	end
	return btn
end
