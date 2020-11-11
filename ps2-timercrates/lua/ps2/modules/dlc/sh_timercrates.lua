hook.Add( "PS2_ModulesLoaded", "DLC_TimerCrates", function( )

	local MODULE = Pointshop2.GetModule( "Pointshop 2 DLC" )
	table.insert( MODULE.Blueprints, {
		label = "Timer Crate",
		base = "base_timercrate",
		icon = "timercrates/timercrate.png",
		creator = "DTimerCrateCreator"
	} )
	
	MODULE.Settings.Server.TimerDropsTableSettings = {
		info = {
			label = "Timer Crate Settings",
			isManualSetting = true, --Ignored by AutoAddSettingsTable
		},
		TimerCratesData = {
			value = { },
			type = "table"
		},
	}
	
	MODULE.Settings.Server.BroadcastTimerCrateSettings = {
		info = {
			label = "Drops Chat Print Settings",
		},
		BroadcastRarity = {
			value = "Uncommon", 
			type = "option",
			label = "Broadcast minimum Rarity",
			tooltip = "Broadcast only unbox if the item is above this rarity treshold",
			possibleValues = {
				"Very Common",
				"Common",
				"Uncommon",
				"Rare",
				"Very Rare",
				"Extremely Rare"
			}
		},
		BroadcastUnbox = {
			value = true,
			label = "Broadcast unbox rewards in chat",
			tooltip = "Posts a message to chat whenever a player unboxes a timer crate."
		},
	}
	
	table.insert( MODULE.SettingButtons, {
		label = "Timer Crates Setup",
		icon = "timercrates/timercrateconf.png",
		control = "DPointshopTimerCratesConfigurator"
	} )
	
	print( "Loaded PS2-TimerCrates for Pointshop 2 v. " .. "1.0" )
end )

Pointshop2.TimerCrates = {}

function Pointshop2.Drops.GetTimerCrateClasses( )
	local classes = { }
	for _, itemClass in pairs( KInventory.Items ) do
		if subclassOf( KInventory.Items.base_timercrate, itemClass ) then
			table.insert( classes, itemClass )
		end
	end
	return classes
end