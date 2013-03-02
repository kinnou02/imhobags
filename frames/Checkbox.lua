local Addon, private = ...

setfenv(1, private)
Ux = Ux or { }
Ux.Checkbox = { }

-- Private methods
-- ============================================================================

-- Public methods
-- ============================================================================

function Ux.Checkbox.New(parent, text, side)
	local frame = UI.CreateFrame("RiftCheckbox", "", parent)
	frame.text = UI.CreateFrame("Text", "", frame)
	frame.text:SetPoint("TOP" .. ((side == "LEFT" and "RIGHT") or "LEFT"), frame, "TOP" .. side)
	frame.text:SetText(text)
	
	frame.text:EventAttach(Event.UI.Input.Mouse.Left.Click, function()
		frame:SetChecked(not frame:GetChecked())
	end, "")
	return frame
end
