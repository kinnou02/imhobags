local Addon, private = ...

-- Upvalue

setfenv(1, private)
Ux = Ux or { }

function Ux.DoPopup(numbtn, message, callFunc)
	local popupWindow = { }
	
	if Ux.PopupWindow then
		Ux.PopupWindow:SetVisible(true)
		Ux.PopupWindow.messagetxt:SetText(message)
	else
		local context = UI.CreateContext(Addon.identifier)
		context:SetStrata("modal")
		popupWindow = UI.CreateFrame("RiftWindow", "", context)
		popupWindow:SetPoint("CENTER",UIParent, "CENTER")
		popupWindow:SetWidth(400)
		popupWindow:SetHeight(400)
		
		popupWindow.contents = popupWindow:GetContent()

		popupWindow.okbtn = UI.CreateFrame("RiftButton", "popupOK", popupWindow.contents)
    popupWindow.okbtn:SetText(L.Ux.PopupWindow.ok)
    popupWindow.okbtn:SetPoint("BOTTOMRIGHT", popupWindow.contents, "BOTTOMCENTER", 5, 0)
    popupWindow.okbtn:SetEnabled(true)
    
   	popupWindow.cancelbtn = UI.CreateFrame("RiftButton", "popupCancel", popupWindow.contents)
    popupWindow.cancelbtn:SetText(L.Ux.PopupWindow.cancel)
    popupWindow.cancelbtn:SetPoint("BOTTOMLEFT", popupWindow.contents, "BOTTOMCENTER", -2, 0)
    popupWindow.cancelbtn:SetEnabled(true)
	
    popupWindow.messagetxt = UI.CreateFrame("Text", "popupMessage", popupWindow.contents)
    popupWindow.messagetxt:SetText(message)
    popupWindow.messagetxt:SetFontSize(16)
    popupWindow.messagetxt:SetPoint("TOPLEFT", popupWindow.contents, "TOPLEFT", 0, 2)
    popupWindow.messagetxt:SetFontColor(0.85,0.80,0.62,1)
    popupWindow.messagetxt:SetWidth(380)
    popupWindow.messagetxt:SetVisible(true)
    
    Ux.PopupWindow = popupWindow
	end

	
  if numbtn == 1 then
    Ux.PopupWindow.okbtn:ClearAll()
    Ux.PopupWindow.okbtn:SetPoint("BOTTOMCENTER", Ux.PopupWindow.contents, "BOTTOMCENTER")
    Ux.PopupWindow.cancelbtn:SetEnabled(false)
    Ux.PopupWindow.cancelbtn:SetVisible(false)
  end

  function Ux.PopupWindow.okbtn.Event:LeftPress()
    Ux.PopupWindow:SetVisible(false)
    if callFunc then
			callFunc()
    else
			return
    end
  end
  
  function Ux.PopupWindow.cancelbtn.Event:LeftPress()
		Ux.PopupWindow:SetVisible(false)
  end
end