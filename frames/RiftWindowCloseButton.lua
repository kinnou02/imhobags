local Addon, private = ...

setfenv(1, private)
Ux = Ux or { }
Ux.RiftWindowCloseButton = { }

function Ux.RiftWindowCloseButton.New(parent, closeTarget, fade)
	local btn = UI.CreateFrame("RiftButton", "", parent)
	btn:SetSkin("close")
	btn:SetPoint("TOPRIGHT", parent:GetBorder(), "TOPRIGHT", -8, 16)
	if(type(closeTarget) == "function") then
		btn:EventAttach(Event.UI.Button.Left.Press, closeTarget, "")
	elseif(fade) then
		btn:EventAttach(Event.UI.Button.Left.Press, function() closeTarget:FadeOut() end, "")
	else
		btn:EventAttach(Event.UI.Button.Left.Press, function() closeTarget:SetVisible(false) end, "")
	end
	return btn
end
