Pointshop2.TimerCratePersistence = class( "Pointshop2.TimerCratePersistence" )
local TimerCratePersistence = Pointshop2.TimerCratePersistence 

TimerCratePersistence.static.DB = "Pointshop2"

TimerCratePersistence.static.model = {
	tableName = "ps2_timercratepersistence",
	fields = {
		itemPersistenceId = "int",
		material = "string",
		time = "int",
		itemMap = "luadata" --lazy way
	},
	belongsTo = {
		ItemPersistence = {
			class = "Pointshop2.ItemPersistence",
			foreignKey = "itemPersistenceId",
			onDelete = "CASCADE"
		}
	}
}

TimerCratePersistence:include( DatabaseModel )
TimerCratePersistence:include( Pointshop2.EasyExport )


function TimerCratePersistence.static.createOrUpdateFromSaveTable( saveTable, doUpdate )
	return Pointshop2.ItemPersistence.createOrUpdateFromSaveTable( saveTable, doUpdate )
	:Then( function( itemPersistence )
		if doUpdate then
			return TimerCratePersistence.findByItemPersistenceId( itemPersistence.id )
		else
			local timercrate = TimerCratePersistence:new( )
			timercrate.itemPersistenceId = itemPersistence.id
			return timercrate
		end
	end )
	:Then( function( timercrate )
		timercrate.material = saveTable.material
		timercrate.time = saveTable.time
		timercrate.itemMap = saveTable.itemMap
		return timercrate:save( )
	end )
end