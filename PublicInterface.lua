local Addon, private = ...

-- The public interface table
ImhoBags = {
	Event = {
		Item = {
			Standard = {
			}
		}
	}
}

-- The internal table for triggering events
private.Trigger.Item = {
	Standard = {
	}
}

private.Trigger.Item.Standard.Right, ImhoBags.Event.Item.Standard.Right = Utility.Event.Create("ImhoBags", "Event.Item.Standard.Right")
private.Trigger.Item.Standard.Left, ImhoBags.Event.Item.Standard.Left = Utility.Event.Create("ImhoBags", "Event.Item.Standard.Left")
private.Trigger.Item.Standard.Drag, ImhoBags.Event.Item.Standard.Drag = Utility.Event.Create("ImhoBags", "Event.Item.Standard.Drag")
private.Trigger.Item.Standard.Drop, ImhoBags.Event.Item.Standard.Drop = Utility.Event.Create("ImhoBags", "Event.Item.Standard.Drop")

table.insert(ImhoBags.Event.Item.Standard.Right, { function(params) print("Right", params.id) end, "ImhoBags", "" })
table.insert(ImhoBags.Event.Item.Standard.Left, { function(params) print("Left", params.id) end, "ImhoBags", "" })
table.insert(ImhoBags.Event.Item.Standard.Drag, { function(params) print("Drag", params.id) end, "ImhoBags", "" })
table.insert(ImhoBags.Event.Item.Standard.Drop, { function(params) print("Drop", params.id) end, "ImhoBags", "" })
