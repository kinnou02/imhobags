--[[

  LibItemList:  Scrollable item lists.

]]--


Library = Library or {}
local addoninfo, lil = ...
Library.LibItemList = lil

lil.printf = Library.printf.printf

function lil.check_scrollbar(frametable)
  if not frametable or type(frametable) ~= 'table' then
    lil.printf("check_scrollbar: Called without a valid table.")
    return
  end
  if not frametable.scrollbar then
    lil.printf("check_scrollbar: Called without a scrollbar.")
    return
  end
  if not frametable.data or #frametable.data <= #frametable then
    frametable.scrollbar:SetEnabled(false)
    frametable.scrollbar:SetRange(0, 1)
    frametable.scrollbar:SetPosition(0)
    frametable.offset = 0
    return
  end
  frametable.offset = frametable.offset or 0
  frametable.scrollbar:SetEnabled(true)
  frametable.scrollbar:SetRange(0, #frametable.data - #frametable)
end

function lil.display(frametable, tab)
  if tab then
    frametable.data = tab
  end
  if frametable.data and #frametable.data >= 1 then
    frametable:check_scrollbar()
    frametable.offset = math.floor(frametable.scrollbar:GetPosition())
    for idx = 1, #frametable do
      local index = idx + frametable.offset
      frametable.show(frametable, idx, frametable.data, index, index == frametable.selected)
    end
  end
end

function lil.select(frametable, idx)
  local index = idx + (frametable.offset or 0)
  frametable.selected = index
  if frametable.select then
    frametable.select(frametable, idx, frametable.data, index)
  else
    frametable.show(frametable, idx, frametable.data, index, true)
  end
end

function lil.create(frame, addon, initial, count, point, setup, show, select)
  local frametable = { u = initial, frame = frame, addon = addon }
  local w = frame:GetWidth()
  local h = frame:GetHeight()
  local line_height = math.floor((h - count + 1) / count)
  local scroll_side = 'TOP' .. point
  local other_side

  if w < 20 or h < 20 or h < count * 3 then
    lil.printf("Provided frame not large enough.")
    return
  end
  if count < 1 then
    lil.printf("Count must be at least 1.")
    return
  end
  if point == 'LEFT' then
    other_side = 'TOPRIGHT'
  elseif point == 'RIGHT' then
    other_side = 'TOPLEFT'
  else
    lil.printf("Point must be LEFT or RIGHT.")
    return
  end
  frametable.scrollbar = UI.CreateFrame('RiftScrollbar', addon, frame)
  frametable.scrollbar:SetPoint('TOP' .. point, frame, 'TOP' .. point)
  frametable.scrollbar:SetHeight(h)
  w = w - frametable.scrollbar:GetWidth() - 2
  frame:EventAttach(Event.UI.Input.Mouse.Wheel.Back, function() frametable.scrollbar:Nudge(3) end, "wheel_back")
  frame:EventAttach(Event.UI.Input.Mouse.Wheel.Forward, function() frametable.scrollbar:Nudge(-3) end, "wheel_forward")
  frametable.scrollbar:EventAttach(Event.UI.Scrollbar.Change, function() frametable:display() end, "scrollbar")

  frametable.select = select
  frametable.show = show
  frametable.offset = 0
  for idx = 1, count do
    frametable[idx] = UI.CreateFrame('Frame', addon, frame)
    if idx == 1 then
      frametable[idx]:SetPoint(other_side, frame, other_side)
    else
      frametable[idx]:SetPoint('TOPRIGHT', frametable[idx - 1], 'BOTTOMRIGHT', 0, 1)
    end
    frametable[idx]:SetWidth(w)
    frametable[idx]:SetHeight(line_height)
    frametable[idx]:EventAttach(Event.UI.Input.Mouse.Left.Click, function() lil.select(frametable, idx) end, "left_click")
    setup(frametable, frametable[idx], idx)
  end
  frametable.display = lil.display
  frametable.check_scrollbar = lil.check_scrollbar
  frametable:check_scrollbar()
  return frametable
end
