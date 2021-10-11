
local _,class = UnitClass("player");
if not(class == "HUNTER") then return end

local AddOn = "rais_AutoShot"


local Table = {
	["posX"] = 0;
	["posY"] = -180;
	["Width"] = 100;
	["Height"] = 15;
}
--[[	
local function print(a)
DEFAULT_CHAT_FRAME:AddMessage(a)
end]]

local Debug = false

local baseCastTime = 0.50;
local castTime = baseCastTime
--local AimedDelay = 0;
local AutoRepeat = false

local AutoID = 75;
local AutoName = GetSpellInfo(AutoID)
local pGUID = UnitGUID("player")
local raptorStrike = GetSpellInfo(2973)
local meleeReset = false
local FDstate = false
local FD = GetSpellInfo(5384)
local steadyID = 34120
local steadyShot = GetSpellInfo(steadyID)

--local ASfailed = 0;
local castdelay = 0;
local castStart = false;
local swingStart = false;

local r
local moving = false 
local swingTime
local relative
local InterruptTimer = 0
local baseSpeed = 0
rais_AutoShot = {}

Table["posX"] = Table["posX"] *GetScreenWidth() /1000;
Table["posY"] = Table["posY"] *GetScreenHeight() /1000;
Table["Width"] = Table["Width"] *GetScreenWidth() /1000;
Table["Height"] = Table["Height"] *GetScreenHeight() /1000;

local Lat,Background
local autoshot_latency_update

local function UpdateFrame(self,w,h,x,y)

	w = w or self:GetWidth()
	h = h or self:GetHeight()
	if w < 33 then
		w = 33
	end
	if h < 5 then
		h = 5
	end
	self:SetWidth(w)
	self:SetHeight(h)
	local wdiff = w - r.w
	local hdiff = h - r.h
	r.w = w
	r.h = h

	for _,t in pairs({self:GetRegions()}) do
		t:SetAlpha(1)
		t:SetWidth(t:GetWidth()+wdiff)
		t:SetHeight(t:GetHeight()+hdiff)
	end

	for _,f in pairs({self:GetChildren()}) do
		f:SetAlpha(1)
		f:SetWidth(r.w)
		f:SetHeight(r.h)
		for _,t in pairs({f:GetRegions()}) do
			t:SetAlpha(1)
			t:SetWidth(t:GetWidth()+wdiff)
			t:SetHeight(t:GetHeight()+hdiff)
		end
	end
	autoshot_latency_update()
	if x and y then
		self:ClearAllPoints()
		self:SetPoint("CENTER",UIParent,"CENTER",x,y)
		r.point = "CENTER"
		r.relativePoint = "CENTER"
		r.x = x
		r.y = y
	end
end

function r_Reset()
	local f = rais_AutoShot.Frame_Timer
	local x = Table["posX"]
	local y = Table["posY"]
	local w = Table["Width"]
	local h = Table["Height"]
	UpdateFrame(f,w,h,x,y)
	print(AddOn..': Bar position is now Reset')
end

function r_Latency(arg)
	r.autoshot_latency = tonumber(arg)
	if r.autoshot_latency then
		print(AddOn..': Auto Shot latency set to '..tostring(r.autoshot_latency)..'ms')
	else
		r.autoshot_latency = 0
		print(AddOn..': Error, couldn\'t set Auto shot latency to '..arg)
	end
		
	if r.autoshot_latency < 0 then
		r.autoshot_latency = 0
	elseif r.autoshot_latency > 350 then
		r.autoshot_latency = 350
	end
	r.autoshot_latency = r.autoshot_latency/1e3
end







function rais_AutoShot.AutoShotBar_Create()
	r.x = r.x or Table["posX"]
	r.y = r.y or Table["posY"]
	r.w = r.w or Table["Width"]
	r.h = r.h or Table["Height"]
	r.point = r.point or "CENTER"
	r.relativePoint = r.relativePoint or "CENTER"
	
	local backdrop = {
		bgFile = "Interface/BUTTONS/WHITE8X8",
		tile = true,
		tileSize = 8,
	}
	--local version = select(4, GetBuildInfo())

    local BackdropTemplate = BackdropTemplateMixin and "BackdropTemplate" or nil

    rais_AutoShot.Frame_Timer = CreateFrame("Frame",nil,UIParent, BackdropTemplate);

	local Frame = rais_AutoShot.Frame_Timer;
	Frame:SetFrameLevel(1)
	Frame:SetFrameStrata("HIGH");
	Frame:SetWidth(r.w);
	Frame:SetHeight(r.h);
	Frame:SetPoint(r.point,UIParent,r.relativePoint,r.x,r.y);
	Frame:SetAlpha(1);
	Frame:SetBackdrop(backdrop)
	Frame:SetBackdropColor(0.15,0.15,0.15)
	RF = rais_AutoShot.Frame_Timer
	Frame:SetClampedToScreen(true)
	Frame:SetScript("OnMouseDown", function(self, button)
		if IsAltKeyDown() then
			self:StartSizing("BOTTOMRIGHT")

			for _,t in pairs({Frame:GetRegions()}) do
				t:SetAlpha(0)
			end

			for _,f in pairs({self:GetChildren()}) do
				f:SetAlpha(0)
			end

		else
			self:StartMoving()
		end
	end)
	Frame:SetScript("OnMouseUp", function(self,button)
		local point, relativeTo, relativePoint, x, y = self:GetPoint()
		r.point = point
		r.relativePoint = relativePoint
		r.x = x
		r.y = y
		self:StopMovingOrSizing()
		UpdateFrame(self)

	end)



	rais_AutoShot.Frame_Timer2 = CreateFrame("Frame",nil,Frame);
	local Frame2 = rais_AutoShot.Frame_Timer2;
	Frame2:SetFrameLevel(2)
	Frame2:SetFrameStrata("HIGH");
	Frame2:SetWidth(r.w);
	Frame2:SetHeight(r.h);
	Frame2:SetPoint("CENTER",Frame,"CENTER");
	Frame2:SetAlpha(1);



	rais_AutoShot.Texture_Timer = Frame2:CreateTexture(nil,"OVERLAY"); --overlay
	local Bar = rais_AutoShot.Texture_Timer;
	Bar:SetHeight(r.h);
	Bar:SetTexture([[Interface\AddOns\rais_AutoShot\Textures\Bar.tga]]);
	Bar:SetPoint("CENTER",Frame2,"CENTER");



	rais_AutoShot.Texture_LATENCY = Frame:CreateTexture(nil,"OVERLAY");
	Lat = rais_AutoShot.Texture_LATENCY;
	Lat:SetHeight(r.h);
	Lat:SetTexture([[Interface\AddOns\rais_AutoShot\Textures\Bar.tga]]);
	Lat:SetPoint("CENTER",Frame,"CENTER");
	Lat:SetVertexColor(0.15,0.15,0.15)
	Lat:SetWidth(r.w * (castTime - castdelay)/castTime);


	rais_AutoShot.Texture_BG = Frame:CreateTexture(nil,"ARTWORK");
	Background = rais_AutoShot.Texture_BG;
	Background:SetHeight(r.h);
	Background:SetTexture([[Interface\AddOns\rais_AutoShot\Textures\Bar.tga]]);
	Background:SetPoint("CENTER",Frame,"CENTER");
	Background:SetVertexColor(0.5,0.5,0.5)
	Background:SetWidth(r.w);


	Border = Frame:CreateTexture(nil,"BORDER"); 
	Border:SetPoint("CENTER",Frame,"CENTER");
	Border:SetWidth(r.w +2);
	Border:SetHeight(r.h +2);
	Border:SetColorTexture(0,0,0);


	local Border = Frame:CreateTexture(nil,"BACKGROUND");
	Border:SetPoint("CENTER",Frame,"CENTER");
	Border:SetWidth(r.w +4);
	Border:SetHeight(r.h +4);
	Border:SetColorTexture(1,1,1);
end

local isLocked = true
local function r_Lock()
	local f = rais_AutoShot.Frame_Timer
	if isLocked then
		print(AddOn..': Auto Shot bar is now unlocked')
		f:Show()
		--f:SetAlpha(1);
		f:SetResizable(true)
		f:SetMovable(true)
		f:EnableMouse(true)
	else
		print(AddOn..': Auto Shot bar is now locked')
		f:Hide()
		f:SetResizable(false)
		f:SetMovable(false)
		f:EnableMouse(false)
	end
	isLocked = not(isLocked)
end
	
function autoshot_latency_update()
	
	Lat:SetWidth(r.w * (castTime - castdelay)/castTime);
	Background:SetDrawLayer("ARTWORK")
	
end


local function ShowFrame()
	rais_AutoShot.Frame_Timer:Show();
end

local function HideFrame()
	if isLocked then
		rais_AutoShot.Frame_Timer:Hide();
	end
end

local function Cast_Start()
	
	local haste
	if baseSpeed == 0 then
		haste = 1
	else
		haste = baseSpeed/UnitRangedDamage("player")
	end
	castTime = baseCastTime/haste
	--print(castTime)
	
	HideFrame()
	if moving or IsSpellInRange(AutoName,"target") ~= 1 or not(AutoRepeat)then
		swingStart = false;
		
	else
		ShowFrame()
		--print(GetTime())
		autoshot_latency_update()
		rais_AutoShot.Texture_Timer:SetVertexColor(1,0,0);
		castStart = GetTime();
		if larg2 == nil then
			larg2 = "nil"
		end
		if larg1 == nil then
			larg1 = "nil"
		end
		--if Debug then
			--print(lastevent..'-'..larg1..'-'..larg2)
			--print(IsCurrentSpell("Steady Shot")) -- steadyshot
		--end
	end
	
	
end



local function Cast_Interrupted()
	
	if swingStart == false then
		HideFrame()
	end
	castStart = false
	
end

local function Cast_Update()
	ShowFrame()
	relative = GetTime() - castStart;
	
	if ( relative > castTime ) then
		castStart = false;
		HideFrame()
	elseif ( swingStart == false ) then
		--if  (UnitCastingInfo("player") ~= nil or IsCurrentSpell("Steady Shot") or IsCurrentSpell("Multi-Shot")) then --or InterruptTimer > GetTime()
		--	Cast_Interrupted()
	--	else
			rais_AutoShot.Texture_Timer:SetWidth(r.w * relative/castTime);
	--	end
	end
	if ((relative > (castTime - castdelay)) and (castStart ~= false)) then
		rais_AutoShot.Texture_Timer:SetVertexColor(0,0,0.5);		

	end
	
end




local function Swing_Start(delay)
	if not delay then
		delay = 0
	end
	
	swingTime = UnitRangedDamage("player") - castTime + delay;
	
	ShowFrame()
	rais_AutoShot.Texture_Timer:SetVertexColor(1,1,1);
	castStart = false
	swingStart = GetTime();

	
end






local Frame = CreateFrame("Frame");
Frame:RegisterEvent("PLAYER_ENTERING_WORLD")
Frame:RegisterEvent("UNIT_INVENTORY_CHANGED")
Frame:RegisterEvent("UNIT_SPELLCAST_SENT")
Frame:RegisterEvent("PLAYER_LEVEL_UP")
Frame:RegisterEvent("PLAYER_LOGIN")
Frame:RegisterUnitEvent("UNIT_SPELLCAST_STOP","player")
Frame:RegisterUnitEvent("UNIT_SPELLCAST_INTERRUPTED","player")
Frame:RegisterUnitEvent("UNIT_SPELLCAST_FAILED","player")
--Frame:RegisterUnitEvent("UNIT_SPELLCAST_FAILED_QUIET","player")
Frame:RegisterUnitEvent("UNIT_SPELLCAST_START","player")
Frame:RegisterUnitEvent("UNIT_SPELLCAST_SUCCEEDED","player")
Frame:RegisterEvent("PLAYER_STARTED_MOVING")
Frame:RegisterEvent("PLAYER_STOPPED_MOVING")
Frame:RegisterEvent("START_AUTOREPEAT_SPELL")
Frame:RegisterEvent("STOP_AUTOREPEAT_SPELL")
Frame:RegisterUnitEvent("UNIT_AURA","player")
Frame:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")

--Debug = true

if Debug == true then
	local lastevent
	local larg1,larg2

	local AutoShotDebugFrame = CreateFrame("Frame");
	AutoShotDebugFrame:RegisterAllEvents()

	AutoShotDebugFrame:SetScript("OnEvent",function(self,event,arg1,arg2,arg3)
		--if arg1 == 75 or arg2 == 75 or arg3 == 75 or arg1 == "Auto Shot" or arg2 == "Auto Shot" or arg3 == "Auto Shot" or string.match(event, "QUEST") then
			if not string.match(event,"ITEM") and not string.match(event,"ADDON")  then print(event) end
		--end
		if event == "COMBAT_LOG_EVENT_UNFILTERED" then
			timeStamp, event, _, sourceGUID, sourceName, sourceFlags, sourceRaidFlags, destGUID, destName, destFlags, destRaidFlags, spellID, spellName = CombatLogGetCurrentEventInfo()
			if sourceGUID == UnitGUID("player") and (spellName == "Auto Shot" or spellID == 75) then
				print(event)
			end
		end
	end)	
	--Frame:RegisterAllEvents()
end



Frame:SetScript("OnEvent",function(self,event,arg1,arg2,arg3,arg4)
	if Debug == true and event ~= nil then
		lastevent = event
		larg1 = arg1
		larg2 = arg2
		if not ((event == "WORLD_MAP_UPDATE") or (event == "UPDATE_SHAPESHIFT_FORM") or string.find(event,"LIST_UPDATE") or string.find(event,"COMBAT_LOG") or string.find(event,"CHAT") or string.find(event,"CHANNEL")) then
			local a = GetTime()..' '..event..':'
			if arg1 ~= nil then
				a = a.."/"..tostring(arg1)
			end
			if arg2 ~= nil then
				a = a.."/"..tostring(arg2)
			end
			if arg3 ~= nil then
				a = a.."/"..tostring(arg3)
			end
			if arg4 ~= nil then
				a = a.."/"..tostring(arg4)
			end
			DEFAULT_CHAT_FRAME:AddMessage(a)
		end
	end
	
	if event == "COMBAT_LOG_EVENT_UNFILTERED" then
		timeStamp, event, _, sourceGUID, sourceName, sourceFlags, sourceRaidFlags, destGUID, destName, destFlags, destRaidFlags, spellID, spellName, x3, x4, x5 = CombatLogGetCurrentEventInfo()
			
			--[[
			if sourceGUID == pGUID then dd = "true" else dd = "false" end
			print(event..'-'..spellName..':'..dd)
			if spellID == 75 then
				print(event)
				print(sourceGUID)
				print(pGUID)
			end]]
		if sourceGUID == pGUID then

			
				
			if (spellName == AutoName) then -- and castStart == false then --autoshot
				if (event == "SPELL_CAST_START") then
					Cast_Interrupted();	
					swingStart = false
					Cast_Start()
				end
				
			end
			if meleeReset == true then
				if (event == "SWING_DAMAGE") or (event == "SWING_MISSED") then
					Swing_Start()
				elseif ((event == "SPELL_DAMAGE") or (event == "SPELL_MISSED")) and string.find(spellName,raptorStrike) then
					Swing_Start()
				end
			end
		end
		return
	elseif event == "PLAYER_LEVEL_UP" then
		castdelay = r.autoshot_latency
		autoshot_latency_update();
		Swing_Start();
	elseif (event == "UNIT_INVENTORY_CHANGED" and arg1 == "player") or event == "PLAYER_ENTERING_WORLD" then
		
		GameTooltip:SetOwner(rais_AutoShot.Frame_Timer, "ANCHOR_RIGHT")
		GameTooltip:SetInventoryItem("player",18)
		
		
		for n = 2,GameTooltip:NumLines() do
			local text = getglobal("GameTooltipTextRight"..n):GetText()
			if text then
				baseSpeed = tonumber(string.match(text,"%a+ (%d%p%d%d?)")) or 0
				if baseSpeed > 0 then
					break
				end
			end
		end
		
		GameTooltip:Hide();
		--print(baseSpeed)
		
	elseif ( event == "PLAYER_LOGIN" ) then
		raisAutoShotOptions = raisAutoShotOptions or {}
		r = raisAutoShotOptions
		r.autoshot_latency = r.autoshot_latency or 0
		rais_AutoShot.AutoShotBar_Create();
		DEFAULT_CHAT_FRAME:AddMessage("|cff00ccff"..AddOn.."|cffffffff Loaded");
	elseif event == "PLAYER_STARTED_MOVING" and not IsCurrentSpell(steadyID) then
		moving = true
		if swingStart == false then
			Cast_Interrupted();	
		end 
	elseif event == "PLAYER_STOPPED_MOVING" then
		moving = false
		--[[
		if rais_AutoShot.Frame_Timer:GetAlpha() == 0 then
			Cast_Interrupted();	
			Cast_Start()
		end]]
	elseif event == "START_AUTOREPEAT_SPELL" then
		AutoRepeat = true
		--[[if rais_AutoShot.Frame_Timer:GetAlpha() == 0 then
			Cast_Interrupted()
		end]]
	elseif event == "STOP_AUTOREPEAT_SPELL" then
		AutoRepeat = false
	end
	
	if arg1 ~= "player" then 
		return
	end
	if arg3 == AutoID and (event == "UNIT_SPELLCAST_SUCCEEDED") then
		castdelay = r.autoshot_latency
		autoshot_latency_update();
		Swing_Start();
	elseif (event == "UNIT_AURA") then
		--Resets auto shot timer after feign death 
		local buffed = false
		for i=1,32 do 
			local name=UnitBuff("player",i); 
			if name == FD then
				buffed = true 
			end
		end
		if buffed then
			FDstate = true
		elseif FDstate == true then
			castdelay = r.autoshot_latency
			autoshot_latency_update();
			Swing_Start(0.5);
			FDstate = false
		else
			FDstate = false
		end
	end

	--[[ 
	if rais_AutoShot.Frame_Timer:GetAlpha() == 0 and (arg3 == "Steady Shot" or arg3 == "Multi-Shot" or arg3 == "Aimed Shot") and (event == "UNIT_SPELLCAST_STOP") then
		Cast_Interrupted();	
	end
	]]
	--
	if (event == "UNIT_SPELLCAST_FAILED" or event == "UNIT_SPELLCAST_INTERRUPTED") and (arg3 == AutoID ) then
		Cast_Interrupted();
	end


end)

local AutoShotRange = 0

Frame:SetScript("OnUpdate",function()
	
	
	
	if ( swingStart == false ) then
		

		if ( moving == false ) and AutoRepeat and IsSpellInRange(AutoName,"target") then
			if  castStart ~= false then
				Cast_Update();
			end
		else
			if castdelay < 0 then
				
				castdelay = 0
				
			end
			Cast_Interrupted();

		end
	else

		relative = GetTime() - swingStart
		
		rais_AutoShot.Texture_Timer:SetWidth(r.w*(1 - (relative/swingTime)));
		rais_AutoShot.Texture_Timer:SetVertexColor(1,1,1);
		
		if ( relative >= swingTime ) then
			swingStart = false;
            Cast_Interrupted()
            if IsCurrentSpell(steadyID) then
                Cast_Start();
            end
		end
	end
	autoshot_latency_update()
	AutoShotRange = IsSpellInRange(AutoName,"target")


end)


SLASH_RAISAUTOSHOT1 = "/raisautoshot"

local 	commandList = {
		["lock"] = {r_Lock,SLASH_RAISAUTOSHOT1.." lock | Lock/Unlock the bar, use alt+click to resize"};
		["reset"] = {r_Reset,SLASH_RAISAUTOSHOT1.." reset | reset to the default positions"};
		["latency"] = {r_Latency,SLASH_RAISAUTOSHOT1.." latency <number> | Sets the latency threshold indicator (in milliseconds)"};
	}


SlashCmdList["RAISAUTOSHOT"] = function(msg)
	_,_,cmd,arg = strfind(msg,"%s?(%w+)%s?(.*)")


	if cmd then
		cmd = strlower(cmd)
	end
	if arg == "" then
		arg = nil
	end

	if cmd == "help" or not cmd or cmd == "" then
		local list = {"Command List:"}
		for command,entry in pairs(commandList) do
			if arg == command then
				print(entry[2])
				return
			else
				--table.insert(list,SLASH_RAISAUTOSHOT1.." "..command)
				table.insert(list,entry[2])
			end
		end
		for i,v in pairs(list) do
			print(v)
		end
		--print("For more info type "..SLASH_RAISAUTOSHOT1.." help <command>")
	else
		for command,entry in pairs(commandList) do
			if cmd == command then
				entry[1](arg)
				return 
			end
		end
		print("Error: command \'"..cmd.."\' not recognized")
	end
end 
