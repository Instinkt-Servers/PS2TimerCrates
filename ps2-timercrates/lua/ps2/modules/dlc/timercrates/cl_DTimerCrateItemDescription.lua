local PANEL = {}

local function pluralizeString(str, quantity)
	return str .. ((quantity ~= 1) and "" or "s")
end

local function getNumber( seconds )
	if ( seconds == nil ) then return 0 end
	if ( seconds < 60 ) then
		local t = math.floor( seconds )
		return t
	end

	if ( seconds < 60 * 60 ) then
		local t = math.floor( seconds / 60 )
		return t 
	end

	if ( seconds < 60 * 60 * 24 ) then
		local t = math.floor( seconds / (60 * 60) )
		return t
	end

	if ( seconds < 60 * 60 * 24 * 7 ) then
		local t = math.floor( seconds / (60 * 60 * 24) )
		return t
	end
	
	if ( seconds < 60 * 60 * 24 * 7 * 52 ) then
		local t = math.floor( seconds / (60 * 60 * 24 * 7) )
		return t 
	end

	local t = math.floor( seconds / (60 * 60 * 24 * 7 * 52) )
	return t
end

function PANEL:Init( )
	local itemDesc = self
	function self.buttonsPanel:AddUseButton( )
		self.useButton = vgui.Create( "DButton", self )
		local item = itemDesc.item and (KInventory.ITEMS[itemDesc.item.id] or itemDesc.item)
		local tctimer = item and item.timeLeft
		if not tctimer then
			KLogf( 3, "[ERROR] Invalid timer for item %s", tostring( itemDesc.itemClass ) )
		end
		self.useButton:SetText( string.NiceTime( tctimer ) .. " " .. pluralizeString( "remain", getNumber( tctimer ) ) .. "." )
		self.useButton:DockMargin( 0, 5, 0, 0 )
		self.useButton:Dock( TOP )
		function self.useButton:DoClick( )
			if itemDesc.item:UseButtonClicked( ) then
				self:SetDisabled( true )
			end
		end
		function self.useButton:Think( )
			item = itemDesc.item and (KInventory.ITEMS[itemDesc.item.id] or itemDesc.item)
			tctimer = item and item.timeLeft
			local canBeUsed = tctimer and tctimer <= 0
			if not canBeUsed then
				self:SetDisabled( true )
				self:SetText( string.NiceTime( tctimer ) .. " " .. pluralizeString( "remain", getNumber( tctimer ) ) .. "." )
			else
				self:SetText("Open")
				self:SetDisabled( false )
			end
		end
	end
end

function PANEL:AddTimerInfo( )
	if IsValid( self.singleUsePanel ) then
		self.singleUsePanel:Remove( )
	end
	
	self.singleUsePanel = vgui.Create( "DPanel", self )
	self.singleUsePanel:Dock( TOP )
	self.singleUsePanel:DockMargin( 0, 8, 0, 0 )
	Derma_Hook( self.singleUsePanel, "Paint", "Paint", "InnerPanelBright" )
	self.singleUsePanel:SetTall( 50 )
	self.singleUsePanel:DockPadding( 5, 5, 5, 5 )
	function self.singleUsePanel:PerformLayout( )
		self:SizeToChildren( false, true )
	end
	
	local tctime = self.itemClass.time
	if not tctime then
		KLogf( 3, "[WARN] Invalid timer for item %s", tostring( self.itemClass.PrintName ) )
	end
		
	local label = vgui.Create( "DLabel", self.singleUsePanel )
	label:SetText( "This item takes "..string.NiceTime(tctime) .. " to unlock." )
	label:Dock( TOP )
	label:SizeToContents( )
end

function PANEL:AddTimerCrateContentInfo( )
	if IsValid( self.timercrateContentPanel ) then
		self.timercrateContentPanel:Remove( )
	end
	
	self.timercrateContentPanel = vgui.Create( "DPanel", self )
	self.timercrateContentPanel:Dock( TOP )
	self.timercrateContentPanel:DockMargin( 0, 8, 0, 0 )
	Derma_Hook( self.timercrateContentPanel, "Paint", "Paint", "InnerPanelBright" )
	self.timercrateContentPanel:SetTall( 50 )
	self.timercrateContentPanel:DockPadding( 5, 5, 5, 5 )
	function self.timercrateContentPanel:PerformLayout( )
		self:SizeToChildren( false, true )
	end
	
	local label = vgui.Create( "DLabel", self.timercrateContentPanel )
	label:SetText( "Contains one of the following items:" )
	label:Dock( TOP )
	label:SizeToContents( )
	
	local pnl = vgui.Create( "DPanel", self.timercrateContentPanel )
	pnl:Dock( TOP )
	pnl:DockPadding( 5, 0, 5, 5 )
	pnl:DockMargin( 0, 5, 0, 0 )
	function pnl:Paint( w, h )
		surface.SetDrawColor( 200, 200, 200 )
		surface.DrawRect( 0, 0, w, h )
	end
	function pnl:PerformLayout( )
		self:SizeToChildren( false, true )
	end
	Derma_Hook( pnl, "Paint", "Paint", "InnerPanel" )

	for k, info in pairs( self.itemClass.itemMapSorted ) do
		local factoryClass = getClass( info.factoryClassName )
		if not factoryClass then continue end
		local factory = factoryClass:new( )
		factory.settings = info.factorySettings
		
		if not factory:IsValid( ) then
			continue
		end
		
		local label = vgui.Create( "DLabel", pnl )
		label:SetText( factory:GetShortDesc( ) )
		label:SetColor( Pointshop2.RarityColorMap[info.chance] )
		label:Dock( TOP )
		label:DockMargin( 0, 5, 0, 0 )
		label:SetFont( self:GetSkin( ).fontName )
		label:SizeToContents( )
	end
end

function PANEL:SetItem( item, noButtons )
	self.BaseClass.SetItem( self, item, noButtons )
	self:AddTimerInfo( )
	self:AddTimerCrateContentInfo( )
	if not noButtons then
		self.buttonsPanel:AddUseButton( )
	end
end

function PANEL:SetItemClass( itemClass )
	self.BaseClass.SetItemClass( self, itemClass )
	self:AddTimerInfo( )
	self:AddTimerCrateContentInfo( )
end

function PANEL:SelectionReset( )
	self.BaseClass.SelectionReset( self )
	if self.singleUsePanel then
		self.singleUsePanel:Remove( )
	end
	if self.timercrateContentPanel then
		self.timercrateContentPanel:Remove( )
	end
end

derma.DefineControl( "DTimerCrateItemDescription", "", PANEL, "DPointshopItemDescription" )