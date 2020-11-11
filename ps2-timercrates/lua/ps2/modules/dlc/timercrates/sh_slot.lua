Pointshop2.AddEquipmentSlot( "Timer Crate", function( item )
	--Check if the item is a Timer Crate
	return instanceOf( Pointshop2.GetItemClassByName( "base_timercrate" ), item )
end )