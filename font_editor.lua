-- created by http://steamcommunity.com/id/MrGash2/
-- just load the file clientside and type font_editor in your console

local Default_Bases = {
	"Arial",
	"Akbar",
	"csd",
	"Roboto",
	"Roboto Bk",
	"Roboto Cn",
	"Roboto Lt",
	"Roboto Th",
}

local WordWrap = function() end
local Display_Text = "This is an example text! Hello, world!"
local Display_Conv = Display_Text
local Background_Color = Color( 50, 50, 50, 255 )
local Text_Color = Color( 255, 255, 255, 255 )

local Disabled = Material( "icon16/delete.png" )
local Enabled = Material( "icon16/accept.png" )
local stop = Material( "icon16/stop.png" )

local Font_Count = 1

-- Descriptions grabbed from the FontData Structure wiki page.
local Var_Info = {
	font = [[The font source. This must be the actual name of the font, not a file name.

	Font files are stored in resource/fonts/]],
	size = [[The font height in pixels]],
	weight = [[The font boldness]],
	blursize = [[The strength of the font blurring.

	Must be > 0 to work.]],
	scanlines = [[The \"scanline\" interval

	Must be > 1 to work. 
	This setting is per blursize per font - so if you create a font using \"Arial\" 
	without scanlines, you cannot create an Arial font using scanlines with the same blursize]],
	antialias = [[Smooth the font]],
	underline = [[Add an underline to the font]],
	italic = [[Make the font italic]],
	strikeout = [[Add a strike through]],
	symbol = [[Enables the use of symbolic fonts such as Webdings]],
	rotary = [[Seems to add a line in the middle of each letter]],
	shadow = [[Add shadow casting to the font]],	
	additive = [[Additive rendering]],
	outline = [[Add a black outline to the font"]],
}

local Settings = {
	font = "Arial",
	size = 13,
	weight = 500,
	blursize = 0,
	scanlines = 0,
	antialias = true,
	underline = false,
	italic = false,
	strikeout = false,
	symbol = false,
	rotary = false,
	shadow = false,
	additive = false,
	outline = false
}
local Original_Settings = table.Copy( Settings )

surface.CreateFont( "Font Editor" .. Font_Count, Settings )
surface.CreateFont( "Font Editor Title B", {
	font = "Roboto Lt",
	size = 20,
	weight = 500,
	blursize = 4,
	scanlines = 4
} )
surface.CreateFont( "Font Editor Title F", {
	font = "Roboto Lt",
	size = 20,
	weight = 500,
	shadow = true,
} )

surface.CreateFont( "LayerFont B", {
	font = "Roboto Bk",
	size = 22,
	weight = 300,
	blursize = 2,
} )

surface.CreateFont( "LayerFont F", {
	font = "Roboto Bk",
	size = 22,
	weight = 100,
} )

local function AdjustSettings( var, val, par )
	local New = table.Copy( Settings )
	New[ var ] = val

	local safe, _ = pcall( surface.CreateFont, "fEditor-Test", New )

	if safe then
		Font_Count = Font_Count + 1

		surface.CreateFont( "Font Editor" .. Font_Count, New )
		Settings[ var ] = val
		Display_Conv = WordWrap( Display_Text, ( par:GetWide() ) - 20, "Font Editor" .. Font_Count )
	else
		chat.AddText( Color( 255, 33, 33 ), "Font Editor", color_white, ": There was an error creating the font." )
	end
end

local function AddOption( name, var, default, par )
	default = default ~= nil and default or Settings[ var ]

	local pan = vgui.Create( "DPanel" )
	pan:SetSize( par:GetWide() - 8, 28 )

	local pan_h = 24
	function pan:Paint( w, h )
		surface.SetDrawColor( Color( 230, 230, 230, 255 ) )
		surface.DrawRect( 0, 0, w, pan_h )
	end

	local tooltip = Var_Info[ var ] and Var_Info[ var ] .. "\n\nDefault: " .. tostring( Original_Settings[ var ] ) or nil
	local hint = vgui.Create( "DImageButton", pan )
	hint:SetSize( 16, 16 )
	hint:SetPos( 4, pan_h/2 - hint:GetTall()/2 )
	hint:SetImage( "icon16/help.png" )
	hint:SetTooltip( tooltip )
	hint.DoClick = function() end
	if not Var_Info[ var ] then
		hint:SetWide( -6 )
	end

	local label = vgui.Create( "DLabel", pan )
	label:SetFont( "Default" )
	label:SetTextColor( Color( 75, 75, 75, 255 ) )
	label:SetText( name )
	label:SizeToContents()
	label:SetPos( 4 + hint:GetWide() + 4, pan_h/2 - label:GetTall()/2 )

	local option
	if var == "font" then
		option = vgui.Create( "DComboBox", pan )

		local set
		for k, v in pairs( default ) do
			if not set then option:SetValue( v ) set = true end
			option:AddChoice( v )
		end
		option:AddChoice( "Custom..." )

		function option:OnSelect( index, value )
			if value ~= "Custom..." then
				AdjustSettings( var, value, par )
			else
				Derma_StringRequest( "Please enter the name of the font you wish to add.", "Please note: This is NOT the file name.", "Arial", 
				function( text )
					if table.HasValue( Default_Bases, text ) then return end

					option:AddChoice( text )
					option:SetValue( text )

					AdjustSettings( var, value, par )
				end, function() end, "Submit", "Cancel" )
			end
		end
	elseif var == "text" then
		option = vgui.Create( "DTextEntry", pan )

		option:SetText( Display_Text )
		function option:OnEnter()
			local text = self:GetValue()

			Display_Text = text
			Display_Conv = text
		end
	elseif type( Original_Settings[ var ] ) == "number" then
		option = vgui.Create( "DButton", pan )
		option:SetText( tostring( default ) )
		function option:DoClick()
			Derma_StringRequest( "Defining: " .. name, "Try insane numbers at your own risk.", tostring( Settings[ var ] ), 
			function( num )
				local num = tonumber( num )
				if not num or num < 0 then
					chat.AddText( Color( 255, 33, 33 ), "Font Editor", color_white, ": Number must be valid and cannot be lower than 0." )
					return
				end

				option:SetText( tostring( num ) )
				AdjustSettings( var, num, par )
			end, function() end, "Submit", "Cancel" )	
		end
	elseif type( Original_Settings[ var ] ) == "boolean" then
		option = vgui.Create( "DButton", pan )
		option:SetText( "" )

		function option:DoClick()
			local bool = not Settings[ var ]

			AdjustSettings( var, bool, par )
		end

		function option:PaintOver( w, h )
			surface.SetDrawColor( color_white )
			surface.SetMaterial( Settings[ var ] and Enabled or Disabled )
			surface.DrawTexturedRect( w/2 - 16/2, h/2 - 16/2, 16, 16 )
		end
	end

	local owid = math.min( pan:GetWide() - ( 4 + hint:GetWide() + 4 + label:GetWide() + 4 + 4 ), pan:GetWide() * 0.4 )
	option:SetSize( owid, pan_h - 4 )
	option:SetPos( pan:GetWide() - option:GetWide() - 4, pan_h/2 - option:GetTall()/2 )

	function pan:PerformLayout( w, h )
		local owid = math.min( pan:GetWide() - ( 4 + hint:GetWide() + 4 + label:GetWide() + 4 + 4 ), pan:GetWide() * 0.4 )
		option:SetSize( owid, pan_h - 4 )
		option:SetPos( pan:GetWide() - option:GetWide() - 4, pan_h/2 - option:GetTall()/2 )
	end

	return pan
end

local Layers = {}
local LayCount = 0
local LayerMenu

local function DoLayers( frame )
	if IsValid( LayerMenu ) then
		if not LayerMenu:IsVisible() then
			LayerMenu:SetVisible( true )
		end
		return
	end

	local x, y, w, h = frame:GetBounds()
	LayerMenu = vgui.Create( "DFrame" )
	LayerMenu:SetSize( 160, 200 )
	LayerMenu:SetTitle( "" )
	LayerMenu.DrawText = "Layer Control"
	LayerMenu.Paint = frame.Paint
	LayerMenu:SetPos( x + w + 4, y + ( h - LayerMenu:GetTall() ) )
	LayerMenu:MakePopup()
	LayerMenu:SetDeleteOnClose( false )

	LayerMenu.btnClose.Paint = function( LayerMenu, w, h )
		surface.SetDrawColor( color_white )
		surface.SetMaterial( stop )
		surface.DrawTexturedRect( 0, 0, w, h )
	end

	local oT = LayerMenu.Think
	function LayerMenu:Think()
		if not IsValid( frame ) then
			self:Remove()
		end

		oT( self )
	end

	local pos = 22/2 - 16/2
	LayerMenu.btnClose:SetSize( 16, 16 )
	LayerMenu.btnClose:SetPos( LayerMenu:GetWide() - 16 - pos, pos )
	LayerMenu.btnMaxim:SetSize( 0, 0 )
	LayerMenu.btnMinim:SetSize( 0, 0 )
	LayerMenu.lblTitle:SetPos( 0, 0 )
	LayerMenu.lblTitle:SetSize( 0, 0 )

	function LayerMenu:PerformLayout( w, h )
		self.btnClose:SetPos( w - 16 - pos, pos )
		self.btnClose:SetSize( 16, 16 )

		self.btnMaxim:SetSize( 0, 0 )
		self.btnMinim:SetSize( 0, 0 )
		
		self.lblTitle:SetPos( 0, 0 )
		self.lblTitle:SetSize( 0, 0 )
	end

	-- aaaa
	local Order = vgui.Create( "DPanelList", LayerMenu )
	Order:SetSize( LayerMenu:GetWide() - 4, LayerMenu:GetTall() - 22 - 2 - 24 - 2 - 2 )
	Order:SetPos( 2, 22 + 2 )
	Order:EnableVerticalScrollbar()
	function Order:Paint( w, h )
		surface.SetDrawColor( 50, 50, 50, 180 )
		surface.DrawRect( 0, 0, w, h )
	end

	local Add = Material( "icon16/database_add.png" )
	local Bar = vgui.Create( "DButton", LayerMenu )
	Bar:SetSize( LayerMenu:GetWide() - 4, 24 )
	Bar:SetPos( 2, LayerMenu:GetTall() - Bar:GetTall() - 2 )
	Bar:SetText( "" )
	Bar:SetTooltip( "Add current font as a layer.\n\nNote: You will not be able to edit this later - only delete." )
	function Bar:PaintOver( w, h )
		surface.SetDrawColor( color_white )
		surface.SetMaterial( Add )
		surface.DrawTexturedRect( w/2 - 16/2, h/2 - 16/2, 16, 16 )
	end

	function Bar:DoClick()
		LayCount = LayCount + 1

		local slide_h = 24
		local slide = vgui.Create( "DButton" )
		slide:SetText( "" )
		slide.DoClick = function() end
		slide:SetSize( Order:GetWide(), 26 )
		slide.ID = LayCount
		function slide:Paint( w, h )
			surface.SetDrawColor( Color( 230, 230, 230, 255 ) )
			surface.DrawRect( 0, 0, w, slide_h )

			local tH = draw.GetFontHeight( "LayerFont F" )
			local text = "Layer " .. self.ID
			local x, y = 4, slide_h/2 - tH/2 - 1

			draw.SimpleText( text, "LayerFont B", x - 1, y, Color( 25, 25, 25, 140 ) )
			draw.SimpleText( text, "LayerFont B", x + 1, y, Color( 25, 25, 25, 140 ) )
			draw.SimpleText( text, "LayerFont B", x, y - 1, Color( 25, 25, 25, 140 ) )
			draw.SimpleText( text, "LayerFont B", x, y + 1, Color( 25, 25, 25, 140 ) )
			draw.SimpleText( text, "LayerFont B", x, y, Color( 25, 25, 25, 255 ) )
			draw.SimpleText( text, "LayerFont F", x, y, Color( 255, 255, 255, 255 ) )
		end

		local delete = Material( "icon16/cross.png" )
		local del = vgui.Create( "DButton", slide )
		del:SetText( "" )
		del:SetSize( 20, 20 )
		del:SetTooltip( "Delete this layer" )
		del:SetPos( slide:GetWide() - del:GetWide() - 2, slide_h/2 - del:GetTall()/2 )
		function del:PaintOver( w, h )
			surface.SetDrawColor( color_white )
			surface.SetMaterial( delete )
			surface.DrawTexturedRect( w/2 - 16/2, h/2 - 16/2, 16, 16 )
		end
		function del:DoClick()
			Layers[ slide.ID ] = nil

			slide:Remove()
			Order:InvalidateLayout()
		end

		function slide:PerformLayout( w, h )
			del:SetPos( self:GetWide() - del:GetWide() - 2, slide_h/2 - del:GetTall()/2 )
		end

		Layers[ LayCount ] = {
			Text_Color = Text_Color,
			Font_Count = Font_Count,
		}

		for k, v in pairs( Settings ) do
			Layers[ LayCount ][ k ] = v
		end

		local str = "Settings:\n\n"
		for k, v in pairs( Settings ) do
			str = str .. k .. ": " .. tostring( v ) .. "\n"
		end
		str = str .. "\nColor: " .. ( Text_Color.r .. ", " .. Text_Color.g .. ", " .. Text_Color.b .. ", " .. Text_Color.a ) .. "\n"

		slide:SetTooltip( str )

		function slide:Think()
			if not Layers[ self.ID ] then
				self:Remove()
				Order:InvalidateLayout()
			end
		end

		Order:AddItem( slide )
	end
end

concommand.Add( "font_editor", function()

	local frame = vgui.Create( "DFrame" )
	frame:SetSize( 640, 420 )
	frame:Center()
	frame:SetTitle( "" )
	frame:MakePopup()

	function frame:Paint( w, h )
		surface.SetDrawColor( Color( 60, 60, 60, 200 ) )
		surface.DrawRect( 0, 0, w, h )

		surface.SetDrawColor( Color( 50, 50, 50, 255 ) )
		surface.DrawRect( 0, 0, w, 22 )

		draw.SimpleText( self.DrawText or "Font Editor", "Font Editor Title B", 4, 1, Color( 255, 170, 130, 255 ) )
		draw.SimpleText( self.DrawText or "Font Editor", "Font Editor Title F", 4, 1, color_white )
	end

	frame.btnClose.Paint = function( frame, w, h )
		surface.SetDrawColor( color_white )
		surface.SetMaterial( stop )
		surface.DrawTexturedRect( 0, 0, w, h )
	end

	local pos = 22/2 - 16/2
	frame.btnClose:SetSize( 16, 16 )
	frame.btnClose:SetPos( frame:GetWide() - 16 - pos, pos )
	frame.btnMaxim:SetSize( 0, 0 )
	frame.btnMinim:SetSize( 0, 0 )
	frame.lblTitle:SetPos( 0, 0 )
	frame.lblTitle:SetSize( 0, 0 )

	function frame:PerformLayout( w, h )
		self.btnClose:SetPos( w - 16 - pos, pos )
		self.btnClose:SetSize( 16, 16 )

		self.btnMaxim:SetSize( 0, 0 )
		self.btnMinim:SetSize( 0, 0 )
		
		self.lblTitle:SetPos( 0, 0 )
		self.lblTitle:SetSize( 0, 0 )
	end

	local oscroll = vgui.Create( "DPanelList", frame )
	oscroll:SetSize( frame:GetWide() * 0.38, frame:GetTall() - ( 22 + 4 + 4 ) )
	oscroll:SetPadding( 0 )
	oscroll:SetPos( 4, 22 + 4 )
	oscroll:EnableVerticalScrollbar()
	function oscroll:Paint( w, h )
	end

	local textview = vgui.Create( "DPanel", frame )
	textview:SetSize( frame:GetWide() - ( 4 + oscroll:GetWide() + 4 + 4 ), oscroll:GetTall() )
	textview:SetPos( 4 + oscroll:GetWide() + 4, 22 + 4 )
	function textview:Paint( w, h )
		surface.SetDrawColor( Background_Color )
		surface.DrawRect( 0, 0, w, h )

		if type( Display_Conv ) == "string" then
			Display_Conv = WordWrap( Display_Text, w - 20, "Font Editor" .. Font_Count )
		else
			local height = draw.GetFontHeight( "Font Editor" .. Font_Count )

			for a, b in pairs( Layers ) do
				local y = h/2 - height/2 - ( ( #Display_Conv - 1 ) * ( height/2 + 2 ) )
				for k, v in ipairs( Display_Conv ) do
					draw.SimpleText( v, "Font Editor" .. b.Font_Count, w/2, y, b.Text_Color, TEXT_ALIGN_CENTER )

					y = y + height + 2
				end
			end

			local y = h/2 - height/2 - ( ( #Display_Conv - 1 ) * ( height/2 + 2 ) )
			for k, v in ipairs( Display_Conv ) do
				draw.SimpleText( v, "Font Editor" .. Font_Count, w/2, y, Text_Color, TEXT_ALIGN_CENTER )

				y = y + height + 2
			end
		end
	end

	local color_panel = vgui.Create( "DPanel", textview )
	color_panel:SetSize( 25 + 4 + 25 + 4 + 25, 25 )
	color_panel:SetPos( 4, textview:GetTall() - color_panel:GetTall() - 4 )
	color_panel.Paint = function() end

	local function ColorMenu( vtype, dtext )
		local menu = vgui.Create( "DFrame" )
		menu:SetSize( 300, 200 )
		menu:SetTitle( "" )
		menu.DrawText = dtext
		menu.Paint = frame.Paint
		menu:Center()
		menu:MakePopup()

		menu.btnClose.Paint = function( menu, w, h )
			surface.SetDrawColor( color_white )
			surface.SetMaterial( stop )
			surface.DrawTexturedRect( 0, 0, w, h )
		end

		local pos = 22/2 - 16/2
		menu.btnClose:SetSize( 16, 16 )
		menu.btnClose:SetPos( menu:GetWide() - 16 - pos, pos )
		menu.btnMaxim:SetSize( 0, 0 )
		menu.btnMinim:SetSize( 0, 0 )
		menu.lblTitle:SetPos( 0, 0 )
		menu.lblTitle:SetSize( 0, 0 )

		function menu:PerformLayout( w, h )
			self.btnClose:SetPos( w - 16 - pos, pos )
			self.btnClose:SetSize( 16, 16 )

			self.btnMaxim:SetSize( 0, 0 )
			self.btnMinim:SetSize( 0, 0 )
			
			self.lblTitle:SetPos( 0, 0 )
			self.lblTitle:SetSize( 0, 0 )
		end

		local mixer = vgui.Create( "DColorMixer", menu )
		mixer:Dock( FILL )
		mixer:SetPalette( true )
		mixer:SetAlphaBar( true )
		mixer:SetWangs( true )
		mixer:SetColor( vtype == "text" and Text_Color or Background_Color )

		function mixer:ValueChanged( color )
			if vtype == "text" then
				Text_Color = color
			else
				Background_Color = color
			end
		end
	end

	local text_color = vgui.Create( "DButton", color_panel )
	text_color:SetSize( 25, 25 )
	text_color:SetPos( 0, 0 )
	text_color:SetText( "" )
	function text_color:PaintOver( w, h )
		surface.SetDrawColor( Text_Color )
		surface.DrawRect( 2, 2, w - 4, h - 4 )
	end
	function text_color:DoClick()
		ColorMenu( "text", "Modify Text Color" )
	end

	local bg_color = vgui.Create( "DButton", color_panel )
	bg_color:SetSize( 25, 25 )
	bg_color:SetPos( text_color:GetWide() + 4, 0 )
	bg_color:SetText( "" )
	function bg_color:PaintOver( w, h )
		surface.SetDrawColor( Background_Color )
		surface.DrawRect( 2, 2, w - 4, h - 4 )
	end
	function bg_color:DoClick()
		ColorMenu( "bg", "Modify Background Color" )
	end

	local layers = Material( "icon16/layers.png" )
	local layerm = vgui.Create( "DButton", color_panel )
	layerm:SetSize( 25, 25 )
	layerm:SetPos( text_color:GetWide() + 4 + bg_color:GetWide() + 4, 0 )
	layerm:SetText( "" )
	function layerm:PaintOver( w, h )
		surface.SetDrawColor( color_white )
		surface.SetMaterial( layers )
		surface.DrawTexturedRect( w/2 - 16/2, h/2 - 16/2, 16, 16 )
	end
	function layerm:DoClick()
		DoLayers( frame )
	end

	local function OP( name, var, default )
		oscroll:AddItem( AddOption( name, var, default, oscroll ) )
	end

	OP( "Display Text", "text", Display_Text )
	OP( "Font Base", "font", Default_Bases )
	OP( "Size", "size" )
	OP( "Boldness", "weight" )
	OP( "Blur Size", "blursize" )
	OP( "Scanlines", "scanlines" )
	OP( "Anti-Alias", "antialias" )
	OP( "Underlined", "underline" )
	OP( "Italic", "italic" )
	OP( "Strikethrough", "strikeout" )
	OP( "Symbol", "symbol" )
	OP( "Dropshadow", "shadow" )
	OP( "Additive Rendering", "additive" )
	OP( "Outline", "outline" )

	local export = vgui.Create( "DButton" )
	export:SetText( "Output to Console" )
	export:SetHeight( 24 )

	local function gt( var, lay )
		local value = lay and Layers[ lay ][ var ] or Settings[ var ]
		if ( var ~= "font" and var ~= "size" and var ~= "weight" ) and value == Original_Settings[ var ] then return end

		print( "\t" .. var .. " = " .. ( type(value) == "string" and "\"" .. value .. "\"" or tostring( value ) ) .. "," )
	end

	function export:DoClick()
		MsgC( Color( 255, 77, 77 ), "\nFont Editor Output", color_white, " ***\n" )
		if table.Count( Layers ) > 0 then
			MsgC( color_white, "Layers stored: " .. table.Count( Layers ) .. " ***\n" )
			for k, v in pairs( Layers ) do
				print( "surface.CreateFont( \"Layer" .. tostring( k ) .. "\", {" )
				gt( "font", k )
				gt( "size", k )
				gt( "weight", k )
				gt( "blursize", k )
				gt( "scanlines", k )
				gt( "antialias", k )
				gt( "underline", k )
				gt( "italic", k )
				gt( "strikeout", k )
				gt( "symbol", k )
				gt( "shadow", k )
				gt( "additive", k )
				gt( "outline", k )
				print( "} )" )	
				MsgC( color_white, "--\n" )
			end
		end

		print( "surface.CreateFont( \"UniqueFontNameHere\", {" )
		gt( "font" )
		gt( "size" )
		gt( "weight" )
		gt( "blursize" )
		gt( "scanlines" )
		gt( "antialias" )
		gt( "underline" )
		gt( "italic" )
		gt( "strikeout" )
		gt( "symbol" )
		gt( "shadow" )
		gt( "additive" )
		gt( "outline" )
		print( "} )" )
		MsgC( Color( 255, 77, 77 ), "Font Editor Output", color_white, " ***\n\n" )
	end
	oscroll:AddItem( export )
	
end )

-- Word wrapping, yay. /wrists

local function get_width( str, font )
	surface.SetFont( font )
	local w, h = surface.GetTextSize( str )
	return w
end

WordWrap = function( str, true_match_width, font, modded_width )
	local breakup = string.Explode( " ", str )
	local storage = {}
	local current_line = 1

	local match_width = modded_width and modded_width[ current_line ] or true_match_width

	if get_width( str, font ) <= match_width then
		return { str }
	end

	local function newtab( t )
		local n = {}
		for k,v in pairs( t ) do
			n[ #n + 1 ] = v
		end

		return n
	end

	local function loopy( up )
		for k, v in pairs( up ) do
			if not storage[ current_line ] then
				storage[ current_line ] = ""

				if get_width( v, font ) > match_width then
					-- break it up, yeee.
					local solo = string.ToTable( v )
					local s = ""
					for a, char in pairs( solo ) do
						if get_width( s .. char, font ) > match_width then
							local rest = string.sub( v, a, #v )
							up[ k ] = rest

							storage[ current_line ] = s
							current_line = current_line + 1
							match_width = modded_width and modded_width[ current_line ] or true_match_width

							local reset = newtab( up )
							return loopy( reset )
						else
							s = s .. char
						end
					end
				else
					-- define that line with our first word.
					storage[ current_line ] = v
					up[ k ] = nil
				end
			else -- already did a word.
				local current_text = storage[ current_line ]

				if get_width( current_text .. " " .. v, font ) > match_width then
					current_line = current_line + 1
					match_width = modded_width and modded_width[ current_line ] or true_match_width

					local reset = newtab( up )
					return loopy( reset )
				else
					storage[ current_line ] = current_text .. " " .. v
					up[ k ] = nil
				end
			end
		end
	end

	loopy( breakup )

	return storage
end
