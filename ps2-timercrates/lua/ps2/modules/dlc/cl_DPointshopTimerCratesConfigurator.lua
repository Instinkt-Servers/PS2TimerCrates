local PANEL = {}

function PANEL:Init( )
	self:SetSkin( Pointshop2.Config.DermaSkin )
	self.settings = {}
	
	self:SetSize( 850, 600 )
	self:SetTitle( "Timer Crate Configuration" )
	
	self.infoPanel = vgui.Create( "DInfoPanel", self )
	self.infoPanel:Dock( TOP )
	self.infoPanel:SetInfo( "Timer Crate System", 
[[The timer crate system works like this: 
- Players purchase a timer crate from the store
- This crate will have a predefined set of items it could contain and a timer showing how long until it can be opened
- This item must be equipped in the Timer Crate slot to count down (time will not count down while afk)
- Once the timer has expired, the crate may be opened.
]] )
	self.infoPanel:DockMargin( 0, 5, 0, 0 )
	
	self.actualSettings = vgui.Create( "DSettingsPanel", self )
	self.actualSettings:Dock( TOP )
	self.actualSettings:AutoAddSettingsTable( { 
		BroadcastTimerCrateSettings = Pointshop2.GetModule( "Pointshop 2 DLC" ).Settings.Server.BroadcastTimerCrateSettings,
		TimerCrateTableSettings = Pointshop2.GetModule( "Pointshop 2 DLC" ).Settings.Server.TimerCrateTableSettings
	} )
	self.actualSettings:DockMargin( 0, 0, 0, 5 )
	self.actualSettings:SetWide( 250 )
	
	self.bottom = vgui.Create( "DPanel", self )
	self.bottom:Dock( BOTTOM )
	self.bottom:DockMargin( 5, 0, 5, 5 )
	self.bottom:SetTall( 40 )
	self.bottom:DockPadding( 5, 0, 0, 0 )
	Derma_Hook( self.bottom, "Paint", "Paint", "InnerPanelBright" )
	self.bottom:MoveToBack( )
	
	self.save = vgui.Create( "DButton", self.bottom )
	self.save:SetText( "Save" )
	self.save:SetImage( "pointshop2/floppy1.png" )
	self.save:SetWide( 180 )
	self.save.m_Image:SetSize( 16, 16 )
	self.save:Dock( RIGHT )
	function self.save.DoClick( )
		self:Save( )
	end
end

function PANEL:SetData( data )
	self.actualSettings:SetData( data )
end

function PANEL:Validate(data)

	return true
end

function PANEL:Save( )
	
	local valid, error = self:Validate(self.actualSettings.settings)
	if not valid then
		Derma_Message(error, "Invalid Configuration")
		return
	end

	Pointshop2View:getInstance( ):saveSettings( self.mod, "Server", self.actualSettings.settings )
	self:Remove( )
end

function PANEL:SetModule( mod )
	self.mod = mod
end

vgui.Register( "DPointshopTimerCratesConfigurator", PANEL, "DFrame" )
vgui.Register( "DPointshop2TimerCratesConfigurator", PANEL, "DFrame" )