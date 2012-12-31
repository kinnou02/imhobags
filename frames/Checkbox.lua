local Addon, private = ...

setfenv(1, private)
Ux = Ux or { }
Ux.Checkbox = { }

-- Private methods
-- ============================================================================

-- Public methods
-- ============================================================================

function Checkbox_RealWidth(self)
	return self:GetWidth() + self.text:GetWidth()
end

function Ux.Checkbox.New(parent, text, side)
	local frame = UI.CreateFrame("RiftCheckbox", "", parent)
	frame.text = UI.CreateFrame("Text", "", frame)
	frame.text:SetPoint("TOP" .. ((side == "LEFT" and "RIGHT") or "LEFT"), frame, "TOP" .. side)
	frame.text:SetText(text)
	
	function frame.text.Event:LeftDown()
		self.clicking = true
	end
	function frame.text.Event:LeftUp()
		if(self.clicking) then
			frame:SetChecked(not frame:GetChecked())
		end
		self.clicking = false
	end
	function frame.text.Event:LeftUpoutside()
		self.clicking = false
	end
	return frame
end
