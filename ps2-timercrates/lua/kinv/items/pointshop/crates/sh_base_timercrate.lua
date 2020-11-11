--[[
This Script is made by Instinkt https://steamcommunity.com/id/InstinktServers and is under GPL-3.0 License.
--]]

ITEM.PrintName = "Pointshop 2 Timer Crate Base"
ITEM.baseClass = "base_single_use"

ITEM.material = ""
ITEM.time = 0
ITEM.category = "Misc"
ITEM.itemMap = {} --Maps chance to item factory
ITEM.NotifyText = "%s wurde entsperrt. Viel Spaß."

function ITEM:initialize( id )
	KInventory.Items.base_pointshop_item.initialize( self, id )

	self.saveFields = self.saveFields or {}
	self.timeLeft = self.timeLeft or self.class.time
	table.insert( self.saveFields, "timeLeft" )

end

function ITEM.static:GetPointshopIconControl( )
	return "DPointshopMaterialIcon"
end

function ITEM.static:GetPointshopLowendIconControl( )
	return "DPointshopMaterialIcon"
end

function ITEM.static.getPersistence( )
	return Pointshop2.TimerCratePersistence
end

function ITEM.static.generateFromPersistence( itemTable, persistenceItem )
	ITEM.super.generateFromPersistence( itemTable, persistenceItem.ItemPersistence )
	itemTable.material = persistenceItem.material
	itemTable.time = persistenceItem.time * 60
	itemTable.itemMap = persistenceItem.itemMap
	local sortedChances = table.Copy(itemTable.itemMap)
	table.SortByMember( sortedChances, "chance", true )
	itemTable.itemMapSorted = sortedChances
end

function ITEM.static.GetPointshopIconDimensions( )
	return Pointshop2.GenerateIconSize( 2, 4 )
end

function ITEM.static.GetPointshopDescriptionControl( )
	return "DTimerCrateItemDescription"
end

function ITEM.static:GetCumulatedChances( )
	local sum = 0
	for k, v in pairs( self.itemMap ) do
		sum = sum + v.chance
	end
	return sum
end


function ITEM:CanBeUsed( )
	if self.timeLeft <= 0 then
		return true
	end
	return false
end

function ITEM:OnUse( )
	local ply = self:GetOwner( )

	return self:Unbox()
	:Then( function( )
		KLogf( 4, "Player %s unboxed a timer crate", ply:Nick( ) )
	end, function( errid, err )
		KLogf( 2, "Error unboxing timer crate item: %s", err )
	end )
end

function ITEM:OnEquip( )
	
	if SERVER then
		timer.Create( "PS2_SaveItemDrain" .. self.id, 5, 0, function( )
			if not self or not IsValid( self:GetOwner( ) ) or self.timeLeft <= 0 then 
				return 
			end
			self:save( )
		end )
	end

	timer.Create( "PS2_ItemDrain" .. self.id, 1, 0, function( )
		
		if not self or not IsValid( self:GetOwner( ) ) or self:GetOwner():GetNWBool( "playerafk", false ) then 
			return 
		end
		
		if self.timeLeft <= 0 then
			if CLIENT and !self.Notified and self:GetOwner() == LocalPlayer() then
				print (self.PrintName)
				local notification = vgui.Create( "KNotificationPanel" )
				notification:setText( string.format(self.NotifyText, self.PrintName) )
				notification:setIcon( "icon16/information.png" )
				notification:SetSkin( Pointshop2.Config.DermaSkin )
				notification.duration = 30
					
				LocalPlayer( ).notificationPanel:addNotification(notification)
				self.Notified = true
			end
			return
		end
	
		
		
		self.timeLeft = self.timeLeft - 1
	end )
	
end

function ITEM:OnHolster( )
	timer.Remove( "PS2_ItemDrain" .. self.id )
	timer.Remove( "PS2_SaveItemDrain" .. self.id )
end

function ITEM:GetChanceTable()
	local sumTbl = {} -- Table with accumulated weights
	local sum = 0
	for k, info in ipairs( self.itemMap ) do
		local factoryClass = getClass( info.factoryClassName )
		if not factoryClass then
			KLogf(2, "[WARN] Timer Crate %s invalid factory %s", self.timercrate:GetPrintName(), info.factoryClassName)
			continue
		end

		local instance = factoryClass:new( )
		instance.settings = info.factorySettings
		if not instance:IsValid( ) then
 			KLogf( 2, "[WARN] Timer Crate %s factory %s IsValid() false: %s", self:GetPrintName(), info.factoryClassName, instance:GetShortDesc( ) )
			continue
		end

		-- Here we iterate over each of the items a factory can generate, and multiply it's
		-- relative weight inside the factory with the factory's weight to get the items global weight.
		local factoryWeight = info.chance
		local chanceMap = instance:GetChanceTable()
		local factoryItemWeightsSum = LibK._.reduce(
			LibK._.pluck(chanceMap, 'chance'), 0, function(sum, item)
				return sum + item
			end )
		
		for _, chanceInfo in ipairs(chanceMap) do
			local itemOrInfo, chance = chanceInfo.itemOrInfo, chanceInfo.chance
			
			local weight = factoryWeight * ( chance / factoryItemWeightsSum )
			if not LibK.isProperNumber(weight) then
				print( factoryWeight, chance, factoryItemWeightsSum,chance / factoryItemWeightsSum, weight )
				LibK.GLib.Error("BaseTimerCrate:GetChanceTable - Invalid item weight!")
			end
			sum = sum + weight
			-- Chance represents the actual chance, display
			table.insert(sumTbl, { sum = sum, itemOrInfo = itemOrInfo, chance = weight, displayChance = factoryWeight })
		end
	end

	return sumTbl, sum
end
-- Modified from original single use as everything is now wrapped in a transaction
function ITEM:InternalOnUse( )
	--Avoid double use
	if self.used or not self:CanBeUsed( ) then
		return
	end

	local succ, err = pcall( self.OnUse, self )
	if not succ then
		LibK.GLib.Error( Format( "[ERROR] Item %s Use failed: %s", self.class.name, err ) )
		return
	end
	self.used = true

	local ply = self:GetOwner( )
	Promise.Resolve()
	:Then(function() 
		-- Pcall returns either the argument or the returned value
		-- By wrapping the return value in a promise here we make sure
		-- that if a promise is returned we wait on it.
		return err
	end):Then( function( )
		KLogf( 4, "Player %s used an item", ply:Nick( ) )
	end, function( errid, err )
		LibK.GLib.Error( Format( "Error using item: %s %s", tostring(errid), tostring(err) ) )
	end )
end

function ITEM:PickRandomItems(iterations)
	local sumTbl, sum = self:GetChanceTable()
	--Pick element
	local function getRandomItem()
		local r = math.random() * sum
		local itemOrInfo
		for _, info in ipairs( sumTbl ) do
			if info.sum >= r then
				itemOrInfo = info.itemOrInfo
				itemOrInfo._chance = info.chance / sum
				itemOrInfo._displayChance = info.displayChance
				break
			end
		end

		return itemOrInfo
	end

	local itemsPicked = {}
	for i = 1, iterations do
		local item = getRandomItem()
		table.insert(itemsPicked, item)
	end
	return itemsPicked
end

function ITEM:Unbox( )
	local ply = self:GetOwner( )
	
	local seed = math.random(10000)
	math.randomseed(seed)
	local items = self:PickRandomItems( Pointshop2.Drops.WINNING_INDEX )
	local winningItem = items[Pointshop2.Drops.WINNING_INDEX]
	local rarity = Pointshop2.GetRarityInfoFromAbsolute(winningItem._displayChance)
	local timercrateId = self.id
	
	for k, v in pairs( ply.PS2_Slots ) do
		if v.slotName == "Timer Crate" then
			slot = v
		end
	end
	if slot.itemId and slot.itemId == timercrateId then
		Pointshop2Controller:unequipItem( ply, "Timer Crate" )
	end
	return Promise.Resolve()
	:Then(function()
		if winningItem.isInfoTable then
			return winningItem.createItem( true )
		else
			return winningItem:new( )
		end
	end)
	:Then(function(item)
		local price = item.class:GetBuyPrice( ply )
		item.purchaseData = {
			time = os.time( ),
			origin = "Timer Crate"
		}
		if price.points then
			item.purchaseData.amount = price.points
			item.purchaseData.currency = "points"
		elseif price.premiumPoints then
			item.purchaseData.amount = price.premiumPoints
			item.purchaseData.currency = "premiumPoints"
		else
			item.purchaseData.amount = 0
			item.purchaseData.currency = "points"
		end
		
		item.inventory_id = ply.PS2_Inventory.id
		item:preSave()
		if Pointshop2.DB.CONNECTED_TO_MYSQL then
			local transaction = LibK.TransactionMysql:new(Pointshop2.DB)
			transaction:begin()
			transaction:add(item:getSaveSql()) -- Create Item
			transaction:add(Format("DELETE FROM kinv_items WHERE id IN(%i)", self.id)) -- Remove crate
			return transaction:commit():Then(function()
				return Pointshop2.DB.DoQuery("SELECT LAST_INSERT_ID() as id")
			end ):Then(function(id)
				item.id = id[1].id
				return item
			end):Then(Promise.Resolve, function(err) 
				LibK.GLib.Error("BaseTimerCrate:Unbox - Error running sql " + tostring(err))
				return Pointshop2.DB.DoQuery("ROLLBACK"):Then( function()
					return Promise.Reject( "Error!" )
				end )
			end )
		else
			sql.Begin()
			-- Remove crate
			self:remove(true):Then(function()
				item.inventory_id = ply.PS2_Inventory.id
				return item:save()
			end):Then(function()
				sql.Commit()
			end, function(err)
				sql.Query("ROLLBACK")
				return Promise.Reject(err)
			end)
			return Promise.Resolve(item)
		end
	end )
	:Then( function( item )
		Pointshop2.Drops.DisplayCrateOpenDialog({
			ply = ply,
			crateItemId = timercrateId,
			seed = seed,
			wonItemId = item.id
		})
		
		KInventory.ITEMS[timercrateId] = nil
		Pointshop2.LogCacheEvent('REMOVE', 'unbox', timercrateId)
		ply.PS2_Inventory:notifyItemRemoved(timercrateId)
		
		ply.PS2_Inventory:notifyItemAdded( item )
		KLogf( 4, "Player %s unboxed %s, got item %s", ply:Nick( ), self:GetPrintName( ) or self.class.PrintName, item:GetPrintName( ) or item.class.PrintName )
		item:OnPurchased( )
		return Promise.Delay(10, item) -- Wait for animation before broadcasting the chat message
	end )
	:Fail( function( errid, err )
		KLogf( 2, "[ERROR UNBOX] Error: %s %s", tostring( errid ), tostring( err ) )
	end )
	:Done( function( item )
		if not Pointshop2.GetSetting( "Pointshop 2 DLC", "BroadcastDropsSettings.BroadcastUnbox" ) then
			return
		end

		local minimumBroadcastChance = table.KeyFromValue(Pointshop2.RarityMap, Pointshop2.GetSetting( "Pointshop 2 DLC", "BroadcastDropsSettings.BroadcastRarity" ))
		if rarity.chance > minimumBroadcastChance then
			return
		end

		net.Start( "PS2D_AddChatText" )
			net.WriteTable{
				Color( 151, 211, 255 ),
				"Player ",
				Color( 255, 255, 0 ),
				ply:Nick( ),
				Color( 151, 211, 255 ),
				" unboxed ",
				rarity.color,
				item:GetPrintName( ),
				Color( 151, 211, 255 ),
				"!"
			}
		net.Broadcast( )
	end )
end

/*
	Inventory icon
*/
function ITEM:getIcon( )
	self.icon = vgui.Create( "DPointshopMaterialInvIcon" )
	self.icon:SetItem( self )
	self.icon:SetSize( 64, 64 )
	return self.icon
end
