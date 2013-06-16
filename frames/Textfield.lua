local Addon, private = ...

setfenv(1, private)
Ux = Ux or { }
Ux.Textfield = { }

local borderWidth = 2

-- Private methods
-- ============================================================================

-- Public methods
-- ============================================================================

function Ux.Textfield.New(parent, clearAnchor, defaultString, clearCallback)
	local frame = UI.CreateFrame("Frame", "", parent)
	local text = UI.CreateFrame("RiftTextfield", "", frame)
	text:SetPoint("TOPLEFT", frame, "TOPLEFT", borderWidth, borderWidth)
	text:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -borderWidth, -borderWidth)
	
	frame:SetBackgroundColor(0.6, 0.6, 0.6)
	text:SetBackgroundColor(0, 0, 0, 0.5)
	text:SetText(defaultString or "")
	frame.text = text

	if(clearAnchor and defaultString) then
		local x = UI.CreateFrame("RiftButton", "", text)
		x:SetSkin("close")
		x:SetPoint(clearAnchor .. "TOP", text, clearAnchor .. "TOP")
		function x.Event:LeftPress()
			if(text:GetText() ~= defaultString) then
				text:SetText("")
				clearCallback()
				if(not text:GetKeyFocus()) then
					text:SetText(defaultString)
				end
			end
		end
		
		function text.Event:Size()
			x:SetHeight(text:GetHeight())
			x:SetWidth(x:GetHeight())
		end
	end

	return frame
end
