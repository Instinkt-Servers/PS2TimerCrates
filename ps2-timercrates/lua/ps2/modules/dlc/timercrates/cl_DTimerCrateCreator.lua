local PANEL = {}

function PANEL:Init( )
	self:SetSkin( Pointshop2.Config.DermaSkin )
	
	self:addSectionTitle( "Icon Settings" )
	
	/*
		Table Element
	*/
	
	
	self.selectMatElem = vgui.Create( "DPanel" )
	self.selectMatElem:SetTall( 64 )
	self.selectMatElem:SetWide( self:GetWide( ) )
	function self.selectMatElem:Paint( ) end
	
	self.materialPanel = vgui.Create( "DImage", self.selectMatElem )
	self.materialPanel:SetSize( 64, 64 )
	self.materialPanel:Dock( LEFT )
	self.materialPanel:SetMouseInputEnabled( true )
	self.materialPanel:SetTooltip( "Click to Select" )
	self.materialPanel:SetMaterial( "timercrates/timercrate.png" )
	local frame = self
	function self.materialPanel:OnMousePressed( )
		--Open model selector
		local window = vgui.Create( "DMaterialSelector" )
		window:Center( )
		window:MakePopup( )
		window:DoModal()
		Pointshop2View:getInstance( ):requestMaterials( "pointshop2" )
		:Done( function( files )
			window:SetMaterials( "pointshop2", files )
		end )
		function window:OnChange( )
			frame.manualEntry:SetText( window.matName )
			frame.materialPanel:SetMaterial( window.matName )
		end
	end
	
	local rightPnl = vgui.Create( "DPanel", self.selectMatElem )
	rightPnl:Dock( FILL )
	function rightPnl:Paint( )
	end

	self.manualEntry = vgui.Create( "DTextEntry", rightPnl )
	self.manualEntry:Dock( TOP )
	self.manualEntry:DockMargin( 5, 0, 5, 5 )
	self.manualEntry:SetText( "timercrates/timercrate.png" )
	self.manualEntry:SetTooltip( "Click on the icon or manually enter the material path here and press enter" )
	function self.manualEntry:OnEnter( )
		frame.materialPanel:SetMaterial( self:GetText( ) )
	end

	self.infoPanel = vgui.Create( "DInfoPanel", self )
	self.infoPanel:SetSmall( true )
	self.infoPanel:Dock( TOP )
	self.infoPanel:SetInfo( "Materials Location", 
[[To add a material to the selector, put it into this folder: 
addons/ps2_drops/materials/pointshop2
Don't forget to upload the material to your fastdl, too!]] )
	self.infoPanel:DockMargin( 5, 5, 5, 5 )
	
	local cont = self:addFormItem( "Material", self.selectMatElem )
	cont:SetTall( 64 )
	
	timer.Simple( 0, function( )
		self:Center( )
	end )
	
	self:addSectionTitle( "Timer Crate Settings" )
	self.openTableBtn = vgui.Create( "DButton" )
	self.openTableBtn:SetText( "Manage Timer Crate Contents" )
	hook.Add( "Think", self.openTableBtn, function() self.openTableBtn:SetSkin( Pointshop2.Config.DermaSkin ) end )
	self.openTableBtn:ApplySchemeSettings( )
	self.openTableBtn:PerformLayout( )
	self.openTableBtn:SetSize( 200, 50 )
	function self.openTableBtn.DoClick( )
		self.settingsDialog = vgui.Create( "DTimerCrateSettingsDialog" )
		self.settingsDialog:MakePopup( )
		self.settingsDialog:Center( )
		self.settingsDialog:DoModal()
		if self.savedTimerCrateMappings then
			self.settingsDialog:Load( self.savedTimerCrateMappings )
		end
		function self.settingsDialog.OnSave( dialog, data )
			self.settingsDialog:Remove( )
			self.savedTimerCrateMappings = data
		end
	end
	self.tctimer = vgui.Create( "DNumberWang", self )
	self.tctimer:SetWide( 50 )
	self:addFormItem( "Open Timer (Minutes)", self.tctimer )
	
	local cont = self:addFormItem( "Settings", self.openTableBtn )
end

function PANEL:OnClose( )
	if IsValid( self.settingsDialog ) then
		self.settingsDialog:Close( )
	end
end

function PANEL:SaveItem( saveTable )
	self.BaseClass.SaveItem( self, saveTable )
	
	saveTable.material = self.manualEntry:GetText( )
	saveTable.time = self.tctimer:GetValue()
	saveTable.itemMap = self.savedTimerCrateMappings
end

function PANEL:EditItem( persistence, itemClass )
	self.BaseClass.EditItem( self, persistence.ItemPersistence, itemClass )
	
	self.manualEntry:SetText( persistence.material )
	self.tctimer:SetValue(persistence.time)
	self.materialPanel:SetMaterial( persistence.material )
	self.savedTimerCrateMappings = persistence.itemMap
end

function PANEL:Validate( saveTable )
	local succ, err = self.BaseClass.Validate( self, saveTable )
	if not succ then
		return succ, err
	end
	
	if not self.savedTimerCrateMappings then
		return false, "The timer crate is emtpy! Please add some items!"
	end
	
	return true
end

vgui.Register( "DTimerCrateCreator", PANEL, "DItemCreator" )