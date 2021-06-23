--[[

	Addon to reduces minimap buttons and makes them accessible through a menu!
	
	Author: karlsnyder, vallantv (for Classic Version)
	
	Previous Authors: Tunhadil, Fixed by Pericles for patch 2.23 til 4.0, fixed by yossa for patch 4.0.1, updated for 4.2+ by karlsnyder
	
]]

BBB_Version = "0.0.1";

-- Setup some variable for debugging.
BBB_DebugFlag = 0;
BBB_DebugInfo = {};

BBB_DragFlag = 0;
BBB_ShowTimeout = -1;
BBB_CheckTime = 0;
BBB_IsShown = 0;
BBB_FuBar_MinimapContainer = "FuBarPlugin-MinimapContainer-2.0";

BBB_Buttons = {};
BBB_Exclude = {};

BBB_DefaultOptions = {
	["ButtonPos"] = {-18, -100},
	["AttachToMinimap"] = 1,
	["DetachedButtonPos"] = "CENTER",
	["CollapseTimeout"] = 1,
	["ExpandDirection"] = 1,
	["MaxButtonsPerLine"] = 0,
	["AltExpandDirection"] = 4
};

BACKDROP_MAXBUTTONS_OPTIONS = {
	edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
	tile = true,
	--tileEdge = true,
	tileSize = 8,
	edgeSize = 8
};

BACKDROP_TOOLTIP_OPTIONS = {
	bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
	edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
	tile = true,
	tileEdge = true,
	tileSize = 32,
	edgeSize = 32,
	insets = { left = 11, right = 12, top = 12, bottom = 11 },
};

-- Buttons to include with scanning for them first.  Currently unused.
BBB_Include = {};

-- Button names to always ignore.
BBB_Ignore = {
	[1] = "MiniMapTrackingFrame",
	[2] = "MiniMapMeetingStoneFrame",
	[3] = "MiniMapMailFrame",
	[4] = "MiniMapBattlefieldFrame",
	[5] = "MiniMapWorldMapButton",
	[6] = "MiniMapPing",
	[7] = "MinimapBackdrop",
	[8] = "MinimapZoomIn",
	[9] = "MinimapZoomOut",
	[10] = "BookOfTracksFrame",
	[11] = "GatherNote",
	[12] = "FishingExtravaganzaMini",
	[13] = "MiniNotePOI",
	[14] = "RecipeRadarMinimapIcon",
	[15] = "FWGMinimapPOI",
	[16] = "CartographerNotesPOI",
	[17] = "BBB_MinimapButtonFrame",
	[18] = "EnhancedFrameMinimapButton",
	[19] = "GFW_TrackMenuFrame",
	[20] = "GFW_TrackMenuButton",
	[21] = "TDial_TrackingIcon",
	[22] = "TDial_TrackButton",
	[23] = "MiniMapTracking",
	[24] = "GatherMatePin",
	[25] = "HandyNotesPin",
	[26] = "TimeManagerClockButton",
	[27] = "GameTimeFrame",
	[28] = "DA_Minimap",
	[29] = "ElvConfigToggle",
	[30] = "MiniMapInstanceDifficulty",
	[31] = "MinimapZoneTextButton",
	[32] = "GuildInstanceDifficulty",
	[33] = "MiniMapVoiceChatFrame",
	[34] = "MiniMapRecordingButton",
	[35] = "QueueStatusMinimapButton",
	[36] = "GatherArchNote",
	[37] = "ZGVMarker",
	[38] = "QuestPointerPOI",	-- QuestPointer
	[39] = "poiMinimap",	-- QuestPointer
	[40] = "MiniMapLFGFrame",    -- LFG
	[41] = "PremadeFilter_MinimapButton",    -- PreMadeFilter
	[42] = "QuestieFrame", -- Questie Fix
	[43] = "NauticusClassicMiniIcon", -- NauticusClassic Fix
	[44] = "Spy_", --Spy Addon
	[45] = "TomTomMapOverlay"
};

BBB_IgnoreSize = {
	[1] = "AM_MinimapButton",
	[2] = "STC_HealthstoneButton",
	[3] = "STC_ShardButton",
	[4] = "STC_SoulstoneButton",
	[5] = "STC_SpellstoneButton",
	[6] = "STC_FirestoneButton"
};

BBB_ExtraSize = {
	["GathererMinimapButton"] = function()
		GathererMinimapButton.mask:SetHeight(31);
		GathererMinimapButton.mask:SetWidth(31);
	end
};

function BBB_OnLoad()
--	hooksecurefunc("SecureHandlerClickTemplate_onclick", BBB_SecureOnClick);
--	hooksecurefunc("SecureHandlerClickTemplate_OnEnter", BBB_SecureOnEnter);
--	hooksecurefunc("SecureHandlerClickTemplate_OnLeave", BBB_SecureOnLeave);
	
	if( AceLibrary ) then
		if( AceLibrary:HasInstance(BBB_FuBar_MinimapContainer) ) then
			AceLibrary(BBB_FuBar_MinimapContainer).oldAddPlugin = AceLibrary(BBB_FuBar_MinimapContainer).AddPlugin;
			AceLibrary(BBB_FuBar_MinimapContainer).AddPlugin = function(...)
				local plugin = select(2, ...);
				local self = select(1, ...);
				local value = AceLibrary(BBB_FuBar_MinimapContainer):oldAddPlugin(plugin);
				local button = plugin.minimapFrame:GetName();
				local frame = _G[button]
				
				if( not frame.oshow ) then
					BBB_PrepareButton(button);
					--if( not BBB_IsExcluded(button) ) then
					if( not BBB_IsInArray(BBB_Exclude, button) ) then
						BBB_AddButton(button);
						BBB_SetPositions();
					end
				end
				
				return value;
			end
			
			AceLibrary(BBB_FuBar_MinimapContainer).oldRemovePlugin = AceLibrary(BBB_FuBar_MinimapContainer).RemovePlugin;
			AceLibrary(BBB_FuBar_MinimapContainer).RemovePlugin = function(...)
				local self = select(1, ...);
				local plugin = select(2, ...);
				local button = plugin.minimapFrame:GetName();
				local frame = _G[button]
				
				if( not frame.oshow ) then
					BBB_PrepareButton(button);
				end
				
				local value = AceLibrary(BBB_FuBar_MinimapContainer):oldRemovePlugin(plugin);
				return value;
			end
		end
	end
	
	BBBFrame:RegisterEvent("ADDON_LOADED");
	SLASH_BBB1 = "/BBB";
	SLASH_BBB2 = "/brattybuttonbag";
	SLASH_BBB3 = "/bbb";
	SlashCmdList["BBB"] = BBB_SlashHandler;
end

function BBB_SlashHandler(cmd)
	if( cmd == "buttons" ) then
		BBB_Print("BBB Buttons:");
		
		if( #BBB_Buttons > 0 ) then
			for i,name in ipairs(BBB_Buttons) do
				BBB_Print("  " .. name);
			end
		else
			BBB_Print("No Minimap buttons are currently stored.");
		end
	elseif( string.sub(cmd, 1, 6) == "debug " ) then
		local iStart, iEnd, sFrame = string.find(cmd, "debug (.+)");
		
		local hasClick, hasMouseUp, hasMouseDown, hasEnter, hasLeave = BBB_TestFrame(sFrame);
		
		BBB_Debug("Frame: " .. sFrame);
		if( hasClick ) then
			BBB_Debug("  has OnClick script");
		else
			BBB_Debug("  has no OnClick script");
		end
		if( hasMouseUp ) then
			BBB_Debug("  has OnMouseUp script");
		else
			BBB_Debug("  has no OnMouseUp script");
		end
		if( hasMouseDown ) then
			BBB_Debug("  has OnMouseDown script");
		else
			BBB_Debug("  has no OnMouseDown script");
		end
		if( hasEnter ) then
			BBB_Debug("  has OnEnter script");
		else
			BBB_Debug("  has no OnEnter script");
		end
		if( hasLeave ) then
			BBB_Debug("  has OnLeave script");
		else
			BBB_Debug("  has no OnLeave script");
		end
	elseif( cmd == "reset position" ) then
		-- Reset the main button position.
		BBB_ResetButtonPosition()
	elseif( cmd == "reset all" ) then
		BBB_Options = BBB_DefaultOptions;
		
		-- Reset the main button position.
		BBB_ResetButtonPosition()
		
		for i=1,table.maxn(BBB_Exclude) do
			BBB_AddButton(BBB_Exclude[i]);
		end
		
		BBB_SetPositions();
	elseif( cmd == "errors" ) then
		if( table.maxn(BBB_DebugInfo) > 0 ) then
			for name, arr in pairs(BBB_DebugInfo) do
				BBB_Print(name);
				for _, error in pairs(arr) do
					BBB_Print("  " .. error);
				end
			end
		else
			BBB_Print(BBB_NOERRORS);
		end
	else
		BBB_Print("BBB v" .. BBB_Version .. ":");
		BBB_Print(BBB_HELP1);
		BBB_Print(BBB_HELP2);
		BBB_Print(BBB_HELP3);
		BBB_Print(BBB_HELP4);
	end
end

function BBB_TestFrame(name)
	local hasClick = false;
	local hasMouseUp = false;
	local hasMouseDown = false;
	local hasEnter = false;
	local hasLeave = false;
	local testframe = _G[name]
	
	if( testframe ) then
		if( not testframe.HasScript ) then
			if( testframe:GetName() ) then
				if( not BBB_DebugInfo[testframe:GetName()] ) then
					BBB_DebugInfo[testframe:GetName()] = {};
				end
				if( not BBB_IsInArray(BBB_DebugInfo[testframe:GetName()], "No HasScript") ) then
					table.insert(BBB_DebugInfo[testframe:GetName()], "No HasScript");
				end
			end
		else
			if( testframe:HasScript("OnClick") ) then
				local test = testframe:GetScript("OnClick");
				if( test ) then
					hasClick = true;
				end
			end
			if( testframe:HasScript("OnMouseUp") ) then
				local test = testframe:GetScript("OnMouseUp");
				if( test ) then
					hasMouseUp = true;
				end
			end
			if( testframe:HasScript("OnMouseDown") ) then
				local test = testframe:GetScript("OnMouseDown");
				if( test ) then
					hasMouseDown = true;
				end
			end
			if( testframe:HasScript("OnEnter") ) then
				local test = testframe:GetScript("OnEnter");
				if( test ) then
					hasEnter = true;
				end
			end
			if( testframe:HasScript("OnLeave") ) then
				local test = testframe:GetScript("OnLeave");
				if( test ) then
					hasLeave = true;
				end
			end
		end
	end
	
	return hasClick, hasMouseUp, hasMouseDown, hasEnter, hasLeave;
end

function BBB_OnEvent(self, event, ...)
	if( BBB_Options ) then
		for opt,val in pairs(BBB_DefaultOptions) do
			if( not BBB_Options[opt] ) then
				BBB_Debug(opt .. " option set to default: " .. tostring(val));
				BBB_Options[opt] = val;
			else
				BBB_Debug(opt .. " option exists: " .. tostring(BBB_Options[opt]));
			end
		end
	else
		BBB_Options = BBB_DefaultOptions;
	end
	BBB_SetButtonPosition();
end

function BBB_PrepareButton(name)
	local buttonframe = _G[name]
	local hasHeader;
	if( buttonframe.GetAttribute ) then
		hasHeader = buttonframe:GetAttribute("anchorchild");
		if( hasHeader and hasHeader == "$parent" and not buttonframe.hasParentFrame ) then
			BBB_Debug("buttonframe has header parent");
			buttonframe.hasParentFrame = true;
		end
	else
		if( buttonframe:GetName() ) then
			if( not BBB_DebugInfo[buttonframe:GetName()] ) then
				BBB_DebugInfo[buttonframe:GetName()] = {};
			end
			if( not BBB_IsInArray(BBB_DebugInfo[buttonframe:GetName()], "No GetAttribute") ) then
				table.insert(BBB_DebugInfo[buttonframe:GetName()], "No GetAttribute");
			end
		end
	end
	
	if( buttonframe ) then
		if( buttonframe.RegisterForClicks ) then
			buttonframe:RegisterForClicks("LeftButtonDown","RightButtonDown");
		end
		
		buttonframe.isvisible = buttonframe:IsVisible();
		
		if( buttonframe.hasParentFrame ) then
			local parent = buttonframe:GetParent();
			parent.BBBChild = buttonframe:GetName();
			buttonframe.parentisvisible = parent:IsVisible();
			parent.oshow = parent.Show;
			parent.Show = function(...)
				local self = select(1, ...);
				local parent = select(1, ...);
				BBB_Debug("Parent Frame: " .. parent:GetName());
				local child = _G[parent.BBBChild]
				BBB_Debug("Child Frame: " .. child:GetName());
				child.parentisvisible = true;
				BBB_Debug("Showing frame: " .. parent:GetName());
				if( not BBB_IsInArray(BBB_Exclude, child:GetName()) ) then
					BBB_SetPositions();
				end
				if( BBB_IsInArray(BBB_Exclude, child:GetName()) or BBB_IsShown == 1 ) then
					parent.oshow(select(1, ...));
					--child.oshow(child);
				end
			end
			parent.ohide = parent.Hide;
			parent.Hide = function(...)
				local parent = select(1, ...);
				BBB_Debug("Parent Frame: " .. parent:GetName());
				local child = _G[parent.BBBChild]
				BBB_Debug("Child Frame: " .. child:GetName());
				child.parentisvisible = false;
				BBB_Debug("Hiding frame: " .. parent:GetName());
				parent.ohide(select(1, ...));
				if( not BBB_IsInArray(BBB_Exclude, child:GetName()) ) then
					BBB_SetPositions();
				end
			end
		end
		
		buttonframe.oshow = buttonframe.Show;
		buttonframe.Show = function(...)
			local innerframe = select(1, ...);
			innerframe.isvisible = true;
			BBB_Debug("Showing innerframe: " .. innerframe:GetName());
			if( not BBB_IsInArray(BBB_Exclude, innerframe:GetName()) ) then
				BBB_SetPositions();
			end
			if( BBB_IsInArray(BBB_Exclude, innerframe:GetName()) or BBB_IsShown == 1 ) then
				--[[if( innerframe.hasParentFrame ) then
					local parent = innerframe:GetParent();
					parent.oshow(parent);
				else]]
					innerframe.oshow(select(1, ...));
				--end
			end
		end
		buttonframe.ohide = buttonframe.Hide;
		buttonframe.Hide = function(...)
			local innerframe = select(1, ...);
			BBB_Debug("Hiding innerframe: " .. innerframe:GetName());
			if( innerframe ~= buttonframe ) then
				innerframe.isvisible = false;
				innerframe.ohide(innerframe);
			end
			if( not BBB_IsInArray(BBB_Exclude, innerframe:GetName()) ) then
				BBB_SetPositions();
			end
		end
		
		if( buttonframe:HasScript("OnClick") and not hasHeader ) then
			buttonframe.oclick = buttonframe:GetScript("OnClick");
			buttonframe:SetScript("OnClick", function(...)
				local self = select(1, ...);
				local arg1 = select(2, ...);
				if( arg1 and arg1 == "RightButton" and IsControlKeyDown() ) then
					local name = self:GetName();
					if( BBB_IsInArray(BBB_Exclude, name) ) then
						BBB_AddButton(name);
					else
						BBB_RestoreButton(name);
					end
					BBB_SetPositions();
				elseif( self.oclick ) then
					self.oclick(select(1, ...));
				end
			end);
		elseif( buttonframe:HasScript("OnMouseUp") and not hasHeader ) then
			buttonframe.omouseup = buttonframe:GetScript("OnMouseUp");
			buttonframe:SetScript("OnMouseUp", function(...)
				local self = select(1, ...);
				local arg1 = select(2, ...);
				if( arg1 and arg1 == "RightButton" and IsControlKeyDown() ) then
					local name = self:GetName();
					if( BBB_IsInArray(BBB_Exclude, name) ) then
						BBB_AddButton(name);
					else
						BBB_RestoreButton(name);
					end
					BBB_SetPositions();
				elseif( self.omouseup ) then
					self.omouseup(select(1, ...));
				end
			end);
		elseif( buttonframe:HasScript("OnMouseDown") and not hasHeader ) then
			buttonframe.omousedown = buttonframe:GetScript("OnMouseDown");
			buttonframe:SetScript("OnMouseDown", function(...)
				local self = select(1, ...);
				local arg1 = select(2, ...);
				if( arg1 and arg1 == "RightButton" and IsControlKeyDown() ) then
					local name = self:GetName();
					if( BBB_IsInArray(BBB_Exclude, name) ) then
						BBB_AddButton(name);
					else
						BBB_RestoreButton(name);
					end
					BBB_SetPositions();
				elseif( self.omousedown ) then
					self.omousedown(select(1, ...));
				end
			end);
		end
		if( buttonframe:HasScript("OnEnter") and not hasHeader ) then
			buttonframe.oenter = buttonframe:GetScript("OnEnter");
			buttonframe:SetScript("OnEnter", function(...)
				local self = select(1, ...);
				if( IsControlKeyDown() ) then
					local button;
					if( BBB_IsInArray(BBB_Exclude, self:GetName()) ) then
						button = _G["BBB_ButtonAdd"]
					else
						button = _G["BBB_ButtonRemove"]
					end
					button.BBBButtonName = self:GetName();
					button:ClearAllPoints();
					button:SetPoint("BOTTOM", self, "TOP", 0, 0);
					button:Show();
				end
				if( not BBB_IsInArray(BBB_Exclude, self:GetName()) ) then
					BBB_ShowTimeout = -1;
				end
				if( self.oenter ) then
					self.oenter(select(1, ...));
				end
			end);
		end
		if( buttonframe:HasScript("OnLeave") and not hasHeader ) then
			buttonframe.oleave = buttonframe:GetScript("OnLeave");
			buttonframe:SetScript("OnLeave", function(...)
				local self = select(1, ...);
				if( not BBB_IsInArray(BBB_Exclude, self:GetName()) ) then
					BBB_ShowTimeout = 0;
				end
				if( self.oleave ) then
					self.oleave(select(1, ...));
				end
			end);
		end
	end
end

function BBB_AddButton(name)
	local child = _G[name]
	
	child.opoint = {child:GetPoint()};
	if( not child.opoint[1] ) then
		child.opoint = {"TOP", Minimap, "BOTTOM", 0, 0};
	end
	child.osize = {child:GetHeight(),child:GetWidth()};
	child.oclearallpoints = child.ClearAllPoints;
	child.ClearAllPoints = function() end;
	child.osetpoint = child.SetPoint;
	child.SetPoint = function() end;
	if( BBB_IsShown == 0 ) then
		if( child.hasParentFrame ) then
			local parent = child:GetParent();
			child.oshow(child);
			parent.ohide(parent);
		else
			-- TODO: Not sure why ohide would be nil but it is.  We'll fix this later.
			if(child.ohide) then
				child.ohide(child);
			end
		end
	end
	table.insert(BBB_Buttons, name);
	local i = BBB_IsInArray(BBB_Exclude, name);
	if( i ) then
		table.remove(BBB_Exclude, i);
	end
end

function BBB_RestoreButton(name)
	local button = _G[name]
	
	button.oclearallpoints(button);
	button.osetpoint(button, button.opoint[1], button.opoint[2], button.opoint[3], button.opoint[4], button.opoint[5]);
	button:SetHeight(button.osize[1]);
	button:SetWidth(button.osize[1]);
	button.ClearAllPoints = button.oclearallpoints;
	button.SetPoint = button.osetpoint;
	BBB_Debug("EVENT Restoring Button");
	if( button.hasParentFrame ) then
		local parent = button:GetParent();
		parent.oshow(parent);
	else
		button.oshow(button);
	end
	
	table.insert(BBB_Exclude, name);
	local i = BBB_IsInArray(BBB_Buttons, button:GetName());
	if( i ) then
		table.remove(BBB_Buttons, i);
	end
end

function BBB_SetPositions()
	local directions = {
		[1] = {"RIGHT", "LEFT"},
		[2] = {"BOTTOM", "TOP"},
		[3] = {"LEFT", "RIGHT"},
		[4] = {"TOP", "BOTTOM"}
	};
	local offsets = {
		[1] = {-5, 0},
		[2] = {0, 5},
		[3] = {5, 0},
		[4] = {0, -5}
	};
	
	local pos = {0, 0};
	local parentid = 0;
	local firstid = 1;
	local count = 1;
	for i,name in ipairs(BBB_Buttons) do
		local positionframe = _G[name]
		if( not positionframe.hasParentFrame ) then
			positionframe.parentisvisible = true;
		end
		if( positionframe.isvisible and positionframe.parentisvisible ) then
			local parent;
			if( parentid==0 ) then
				parent = BBB_MinimapButtonFrame;
			else
				parent = _G[BBB_Buttons[parentid]]
			end
			
			if( not BBB_IsInArray(BBB_IgnoreSize, name) ) then
				if( BBB_ExtraSize[name] ) then
					local func = BBB_ExtraSize[name];
					func();
				else
					positionframe:SetHeight(31); -- 33
					positionframe:SetWidth(31);
				end
			end
			
			local direction;
			
			if( BBB_Options.MaxButtonsPerLine > 0 and count > BBB_Options.MaxButtonsPerLine ) then
				parent = _G[BBB_Buttons[firstid]]
				direction = {directions[BBB_Options.AltExpandDirection][1], directions[BBB_Options.AltExpandDirection][2]};
				if( BBB_ExtraSize[name] or BBB_IsInArray(BBB_IgnoreSize, name) or BBB_ExtraSize[parent:GetName()] or BBB_IsInArray(BBB_IgnoreSize, parent:GetName()) ) then
					pos = offsets[BBB_Options.AltExpandDirection];
				else
					pos = {0, 0};
				end
				count = 2;
				firstid = i;
			else
				direction = {directions[BBB_Options.ExpandDirection][1], directions[BBB_Options.ExpandDirection][2]};
				if( BBB_ExtraSize[name] or BBB_IsInArray(BBB_IgnoreSize, name) or BBB_ExtraSize[parent:GetName()] or BBB_IsInArray(BBB_IgnoreSize, parent:GetName()) ) then
					pos = offsets[BBB_Options.ExpandDirection];
				else
					pos = {0, 0};
				end
				count = count + 1;
			end
			
			positionframe.oclearallpoints(positionframe);
			positionframe.osetpoint(positionframe, direction[1], parent, direction[2], pos[1], pos[2]);
			
			parentid = i;
		end
	end
end

function BBB_OnClick(arg1)
	if( arg1 and arg1 == "RightButton" and IsControlKeyDown() ) then
		if( BBB_Options.AttachToMinimap == 1 ) then
			--[[local xpos,ypos = GetCursorPosition();
			local scale = GetCVar("uiScale");]]
			BBB_Options.AttachToMinimap = 0;
			BBB_Options.ButtonPos = {0, 0};	--{(xpos/scale)-10, (ypos/scale)-10};
			BBB_Options.DetachedButtonPos = BBB_DefaultOptions.DetachedButtonPos;
		else
			BBB_Options.AttachToMinimap = 1;
			BBB_Options.ButtonPos = BBB_DefaultOptions.ButtonPos;
		end
		BBB_SetButtonPosition();
	elseif( arg1 and arg1 == "RightButton" ) then
		BBB_OptionsFrame:Show();
	else
		if( BBB_IsShown == 1 ) then
			BBB_HideButtons();
		else
			BBB_Debug("EVENT OnClick");
			for i,name in ipairs(BBB_Buttons) do
				local clickframe = _G[name]
				if( not clickframe.hasParentFrame ) then
					clickframe.parentisvisible = true;
				end
				if( clickframe.isvisible and clickframe.parentisvisible ) then
					if( clickframe.hasParentFrame and clickframe.hasParentFrame ) then
						local parent = clickframe:GetParent();
						if( parent.oshow ) then
							parent.oshow(parent);
						else
							if( parent:GetName() ) then
								if( not BBB_DebugInfo[parent:GetName()] ) then
									BBB_DebugInfo[parent:GetName()] = {};
								end
								if( not BBB_IsInArray(BBB_DebugInfo[parent:GetName()], "No oshow") ) then
									table.insert(BBB_DebugInfo[parent:GetName()], "No oshow");
								end
							end
						end
					else
						clickframe.oshow(clickframe);
					end
				end
			end
			BBB_IsShown = 1;
			--BBB_ShowTimeout = 0;
		end
	end
end

function BBB_HideButtons()
	BBB_ShowTimeout = -1;
	for i,name in ipairs(BBB_Buttons) do
		local buttonhideframe = _G[name]
		if( buttonhideframe.hasParentFrame ) then
			local parent = buttonhideframe:GetParent();
			if( parent.ohide ) then
				parent.ohide(parent);
			else
				if( parent:GetName() ) then
					if( not BBB_DebugInfo[parent:GetName()] ) then
						BBB_DebugInfo[parent:GetName()] = {};
					end
					if( not BBB_IsInArray(BBB_DebugInfo[parent:GetName()], "No ohide") ) then
						table.insert(BBB_DebugInfo[parent:GetName()], "No ohide");
					end
				end
				buttonhideframe.ohide(buttonhideframe);
			end
		else
			buttonhideframe.ohide(buttonhideframe);
		end
	end
	BBB_IsShown = 0;
end

function BBB_IsKnownButton(name, opt)
	if( not opt ) then
		opt = 1;
	end
	
	if( opt <= 1 ) then
		for _, button in ipairs(BBB_Buttons) do
			if( button == name ) then
				return true;
			end
		end
	end
	if( opt <= 2 ) then
		for _, button in ipairs(BBB_Exclude) do
			if( button == name ) then
				return true;
			end
		end
	end
	if( opt <= 3 ) then
		for _, button in ipairs(BBB_Ignore) do
			if( string.find(name, button) ) then
				return true;
			end
		end
	end
	
	return false;
end

local MinimapChildrenChecked = false
function BBB_OnUpdate(elapsed)
	-- let's do it only once for performance reason, there could be a thousand children that would cause some frame lag.
	--if( BBB_CheckTime >= 3 ) then
	if( not MinimapChildrenChecked ) then
		--BBB_CheckTime = 0;
		MinimapChildrenChecked = true
		local children = {Minimap:GetChildren()};
		for _, child in ipairs(children) do
			if( child:HasScript("OnClick") and not child.oshow and child:GetName() and not BBB_IsKnownButton(child:GetName(), 3) ) then
				BBB_PrepareButton(child:GetName());
				if( not BBB_IsInArray(BBB_Exclude, child:GetName()) ) then
					BBB_AddButton(child:GetName());
					BBB_SetPositions();
				end
			end
		end
	--else
		--BBB_CheckTime = BBB_CheckTime + elapsed;
	end
	
	if( BBB_DragFlag == 1 and BBB_Options.AttachToMinimap == 1 ) then
		local xpos,ypos = GetCursorPosition();
		local xmin,ymin = Minimap:GetLeft(), Minimap:GetBottom();

		xpos = xmin-xpos/Minimap:GetEffectiveScale()+70;
		ypos = ypos/Minimap:GetEffectiveScale()-ymin-70;

		local angle = math.deg(math.atan2(ypos,xpos));
		
		BBB_MinimapButtonFrame:SetPoint("TOPLEFT", Minimap, "TOPLEFT", 53-(cos(angle)*81), -55+(sin(angle)*81));
	end
	
	if( BBB_Options.CollapseTimeout and BBB_Options.CollapseTimeout ~= 0 ) then
		if( BBB_ShowTimeout >= BBB_Options.CollapseTimeout and BBB_IsShown == 1 ) then
			BBB_HideButtons();
		end
		if( BBB_ShowTimeout ~= -1 ) then
			BBB_ShowTimeout = BBB_ShowTimeout + elapsed;
		end
	end
end

function BBB_ResetButtonPosition()
	BBB_Options.AttachToMinimap = BBB_DefaultOptions.AttachToMinimap;
	BBB_Options.ButtonPos = BBB_DefaultOptions.ButtonPos;
	BBB_Options.DetachedButtonPos = BBB_DefaultOptions.DetachedButtonPos;
	
	BBB_SetButtonPosition();
end

function BBB_SetButtonPosition()
	if( BBB_Options.AttachToMinimap == 1 ) then
		BBB_MinimapButtonFrame:ClearAllPoints();
		BBB_MinimapButtonFrame:SetPoint("TOPLEFT", Minimap, "TOPLEFT", BBB_Options.ButtonPos[1], BBB_Options.ButtonPos[2]);
	else
		BBB_MinimapButtonFrame:ClearAllPoints();
		BBB_MinimapButtonFrame:SetPoint(BBB_Options.DetachedButtonPos, UIParent, BBB_Options.DetachedButtonPos, BBB_Options.ButtonPos[1], BBB_Options.ButtonPos[2]);
	end
end

function BBB_RadioButton_OnClick(id, alt)
	local substring;
	if( alt ) then
		substring = "Alt";
	else
		substring = "";
	end
	local buttons = {
		[1] = "Left",
		[2] = "Top",
		[3] = "Right",
		[4] = "Bottom"
	};
	
	for i,name in ipairs(buttons) do
		if( i == id ) then
			_G["BBB_OptionsFrame_" .. name .. substring .. "Radio"]:SetChecked(true)
		else
			_G["BBB_OptionsFrame_" .. name .. substring .. "Radio"]:SetChecked(nil);
		end
	end
end

function BBB_UpdateAltRadioButtons()
	local buttons = {
		[1] = "Left",
		[2] = "Top",
		[3] = "Right",
		[4] = "Bottom"
	};
	
	local exchecked = 1;
	
	for i,name in pairs(buttons) do
		if( _G["BBB_OptionsFrame_" .. name .. "Radio"]:GetChecked() ) then
			exchecked = i;
			break;
		end
	end
	
	local checked = false;
	local textbox = _G["BBB_OptionsFrame_MaxButtonsTextBox"]
	
	for i,name in pairs(buttons) do
		local radio = _G["BBB_OptionsFrame_" .. name .. "AltRadio"]
		local label = _G["BBB_OptionsFrame_" .. name .. "AltRadioLabel"]
		if( textbox:GetText() == "" or tonumber(textbox:GetText()) == 0 ) then
			radio:Disable();
			radio:SetChecked(nil);
			label:SetTextColor(0.5, 0.5, 0.5);
		else
			if( exchecked % 2 == i % 2 ) then
				if( radio:GetChecked() ) then
					checked = true;
					if( i == 4 ) then
						_G["BBB_OptionsFrame_LeftAltRadio"]:SetChecked(true);
					else
						_G["BBB_OptionsFrame_" .. buttons[i+1] .. "AltRadio"]:SetChecked(true);
					end
				end
				radio:Disable();
				radio:SetChecked(nil);
				label:SetTextColor(0.5, 0.5, 0.5);
			else
				if( radio:GetChecked() ) then
					checked = true;
				end
				radio:Enable();
				label:SetTextColor(1, 1, 1);
			end
		end
	end
	
	if( not checked and tonumber(textbox:GetText()) ~= 0 and textbox:GetText() ~= "" ) then
		if( exchecked % 2 == 1 ) then
			_G["BBB_OptionsFrame_TopAltRadio"]:SetChecked(true);
		else
			_G["BBB_OptionsFrame_LeftAltRadio"]:SetChecked(true);
		end
	end
end

function BBB_Debug(msg)
	if (BBB_DebugFlag == 1) then
		BBB_Print("BBB Debug : " .. tostring(msg));
	end
end

function BBB_Test()
	local children = {Minimap:GetChildren()};
	for _, child in ipairs(children) do
		if( child:GetName() and not BBB_IsKnownButton(child:GetName()) ) then
			ChatFrame1:AddMessage(child:GetName());
		end
	end
end

function BBB_IsInArray(array, needle)
	if(type(array) == "table") then
		--BBB_Debug("Looking for " .. tostring(needle) .. " in " .. tostring(array));
		for i, element in pairs(array) do
			if(type(element) ==  type(needle) and element == needle) then
				return i;
			end
		end
	end
	return nil;
end

function BBB_SecureOnClick(self, button, down)
	local name = self:GetName();
	if(name) then -- trap to check for nils
		BBB_Debug("Name: " .. name);
		BBB_Debug("Button: " .. button);
		if( BBB_IsInArray(BBB_Buttons, name) ) then
			if( button == "RightButton" and IsControlKeyDown() ) then
				BBB_Debug("Restoring button: " .. name);
				BBB_RestoreButton(name);
				BBB_SetPositions();
			end
		elseif( BBB_IsInArray(BBB_Exclude, name) ) then
			if( button == "RightButton" and IsControlKeyDown() ) then
				BBB_Debug("Adding button: " .. name);
				BBB_AddButton(name);
				BBB_SetPositions();
			end
		end
	end
end

function BBB_SecureOnEnter(self)
	local name = self:GetName();
	if(name) then -- trap to check for nils
		BBB_Debug("Name: " .. name);
		if( BBB_IsInArray(BBB_Buttons, name) ) then
			if( IsControlKeyDown() ) then
				local button = _G["BBB_ButtonRemove"]
				button.BBBButtonName = name;
				button:ClearAllPoints();
				button:SetPoint("BOTTOM", self, "TOP", 0, 0);
				button:Show();
			end
			BBB_ShowTimeout = -1;
		elseif( BBB_IsInArray(BBB_Exclude, name) ) then
			if( IsControlKeyDown() ) then
				local button = _G["BBB_ButtonAdd"]
				button.BBBButtonName = name;
				button:ClearAllPoints();
				button:SetPoint("BOTTOM", self, "TOP", 0, 0);
				button:Show();
			end
		end
	end
end

function BBB_SecureOnLeave(self)
	local name = self:GetName();
	if(name) then -- trap to check for nils
		BBB_Debug("Name: " .. name);
		if( BBB_IsInArray(BBB_Buttons, name) ) then
			BBB_ShowTimeout = 0;
		elseif( BBB_IsInArray(BBB_Exclude, name) ) then
		
		end
	end
end

function BBB_Print(msg)
	DEFAULT_CHAT_FRAME:AddMessage(msg, 0.2, 0.8, 0.8);
end

-- This looks to be used for testing only.
function BBB_NotSureIfThisIsNeeded()
	local children = {Minimap:GetChildren()};
	local additional = {MinimapBackdrop:GetChildren()};
	for _,child in ipairs(additional) do
		table.insert(children, child);
	end
	for _,child in ipairs(BBB_Include) do
		local childframe = _G[child]
		if( childframe ) then
			table.insert(children, childframe);
		end
	end
	
	for _,child in ipairs(children) do
		if( child:GetName() ) then
			local ignore = false;
			local exclude = false;
			for i,needle in ipairs(BBB_Ignore) do
				if( string.find(child:GetName(), needle) ) then
					ignore = true;
				end
			end
			if( not ignore ) then
				if( not child:HasScript("OnClick") ) then
					for _,subchild in ipairs({child:GetChildren()}) do
						if( subchild:HasScript("OnClick") ) then
							child = subchild;
							child.hasParentFrame = true;
							break;
						end
					end
				end
				
				local hasClick, hasMouseUp, hasMouseDown, hasEnter, hasLeave = BBB_TestFrame(child:GetName());
				
				if( hasClick or hasMouseUp or hasMouseDown ) then
					local name = child:GetName();
					
					BBB_PrepareButton(name);
					if( not BBB_IsInArray(BBB_Exclude, name) ) then
						if( child:IsVisible() ) then
							BBB_Debug("Button is visible: " .. name);
						else
							BBB_Debug("Button is not visible: " .. name);
						end
						BBB_Debug("Button added: " .. name);
						BBB_AddButton(name);
					else
						BBB_Debug("Button excluded: " .. name);
					end
				else
					BBB_Debug("Frame is no button: " .. child:GetName());
				end
			else
				BBB_Debug("Frame ignored: " .. child:GetName());
			end
		end
	end
	
	BBB_SetPositions()
end
