
local _,class = UnitClass("player");
if not(class == "HUNTER") then return end

local AddOn = "rais_AutoShot"
--local _G = getfenv(0)

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
autoshot_latency = 0;
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

--local ASfailed = 0;
local castdelay = 0;
local castStart = false;
local swingStart = false;

local moving = false 
local swingTime
local prevswing = 0
local relative
local InterruptTimer = 0
local baseSpeed = 0


local Lat

rais_AutoShot = {}




Table["posX"] = Table["posX"] *GetScreenWidth() /1000;
Table["posY"] = Table["posY"] *GetScreenHeight() /1000;
Table["Width"] = Table["Width"] *GetScreenWidth() /1000;
Table["Height"] = Table["Height"] *GetScreenHeight() /1000;


function rais_AutoShot.AutoShotBar_Create()
	rais_AutoShot.Frame_Timer = CreateFrame("Frame",nil,UIParent);
	local Frame = rais_AutoShot.Frame_Timer;
	Frame:SetFrameLevel(1)
	Frame:SetFrameStrata("HIGH");
	Frame:SetWidth(Table["Width"]);
	Frame:SetHeight(Table["Height"]);
	Frame:SetPoint("CENTER",UIParent,"CENTER",Table["posX"],Table["posY"]);
	Frame:SetAlpha(1);

	rais_AutoShot.Frame_Timer2 = CreateFrame("Frame",nil,UIParent);
	local Frame2 = rais_AutoShot.Frame_Timer2;
	Frame2:SetFrameLevel(2)
	Frame2:SetFrameStrata("HIGH");
	Frame2:SetWidth(Table["Width"]);
	Frame2:SetHeight(Table["Height"]);
	Frame2:SetPoint("CENTER",Frame,"CENTER");
	Frame2:SetAlpha(1);



	rais_AutoShot.Texture_Timer = Frame2:CreateTexture(nil,"OVERLAY"); --overlay
	local Bar = rais_AutoShot.Texture_Timer;
	Bar:SetHeight(Table["Height"]);
	Bar:SetTexture([[Interface\AddOns\rais_AutoShot\Textures\Bar.tga]]);
	Bar:SetPoint("CENTER",Frame2,"CENTER");



	rais_AutoShot.Texture_LATENCY = Frame:CreateTexture(nil,"OVERLAY");
	Lat = rais_AutoShot.Texture_LATENCY;
	Lat:SetHeight(Table["Height"]);
	Lat:SetTexture([[Interface\AddOns\rais_AutoShot\Textures\Bar.tga]]);
	Lat:SetPoint("CENTER",Frame,"CENTER");
	Lat:SetVertexColor(0.15,0.15,0.15)
	Lat:SetWidth(Table["Width"] * (castTime - castdelay)/castTime);


	rais_AutoShot.Texture_BG = Frame:CreateTexture(nil,"ARTWORK");
	Background = rais_AutoShot.Texture_BG;
	Background:SetHeight(Table["Height"]);
	Background:SetTexture([[Interface\AddOns\rais_AutoShot\Textures\Bar.tga]]);
	Background:SetPoint("CENTER",Frame,"CENTER");
	Background:SetVertexColor(0.5,0.5,0.5)
	Background:SetWidth(Table["Width"]);


	Border = Frame:CreateTexture(nil,"BORDER"); 
	Border:SetPoint("CENTER",Frame,"CENTER");
	Border:SetWidth(Table["Width"] +2);
	Border:SetHeight(Table["Height"] +2);
	Border:SetColorTexture(0,0,0);


	local Border = Frame:CreateTexture(nil,"BACKGROUND");
	Border:SetPoint("CENTER",Frame,"CENTER");
	Border:SetWidth(Table["Width"] +4);
	Border:SetHeight(Table["Height"] +4);
	Border:SetColorTexture(1,1,1);
end

	
local function autoshot_latency_update()
	
	Lat:SetWidth(Table["Width"] * (castTime - castdelay)/castTime);
	Background:SetDrawLayer("ARTWORK")
	
end

local function SetBarAlpha(n)
	rais_AutoShot.Frame_Timer:SetAlpha(n);
	rais_AutoShot.Frame_Timer2:SetAlpha(n);
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
	
	SetBarAlpha(0)
	if moving or IsSpellInRange(AutoName,"target") ~= 1 or not(AutoRepeat)then
		swingStart = false;
		
	else
		SetBarAlpha(1)
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
		if Debug then
			--print(lastevent..'-'..larg1..'-'..larg2)
			--print(IsCurrentSpell("Steady Shot")) -- steadyshot
		end
	end
	
	
end



local function Cast_Interrupted()
	
	if swingStart == false then
		SetBarAlpha(0)
	end
	castStart = false
	
end

local function Cast_Update()
	SetBarAlpha(1)
	relative = GetTime() - castStart;
	
	if ( relative > castTime ) then
		castStart = false;
		SetBarAlpha(0)
	elseif ( swingStart == false ) then
		--if  (UnitCastingInfo("player") ~= nil or IsCurrentSpell("Steady Shot") or IsCurrentSpell("Multi-Shot")) then --or InterruptTimer > GetTime()
		--	Cast_Interrupted()
	--	else
			rais_AutoShot.Texture_Timer:SetWidth(Table["Width"] * relative/castTime);
	--	end
	end
	if ((relative > (castTime - castdelay)) and (castStart ~= false)) then
		rais_AutoShot.Texture_Timer:SetVertexColor(0,0,0.5);		

	end
	
end




local prevswingspeed = false
local function Swing_Start(delay)
	if not delay then
		delay = 0
	end
	
	swingTime = UnitRangedDamage("player") - castTime + delay;
	
	if not prevswingspeed then
		prevswingspeed = swingTime
	end
	
	--if (GetTime() - prevswing) > (prevswingspeed+0.3) then
		SetBarAlpha(1)
		rais_AutoShot.Texture_Timer:SetVertexColor(1,1,1);
		castStart = false
		swingStart = GetTime();
		prevswing = swingStart;
		prevswingspeed = swingTime
	--end
	
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
		castdelay = autoshot_latency/1e3
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
		rais_AutoShot.AutoShotBar_Create();
		DEFAULT_CHAT_FRAME:AddMessage("|cff00ccff"..AddOn.."|cffffffff Loaded");
	elseif event == "PLAYER_STARTED_MOVING" then
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
		castdelay = autoshot_latency/1e3
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
			castdelay = autoshot_latency/1e3
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
			if castdelay > 0 then
				
				castdelay = 0
				
			end
			Cast_Interrupted();
			--Cast_Start();
		end
	end
	

	if ( swingStart ~= false ) then

		relative = GetTime() - swingStart
		
		rais_AutoShot.Texture_Timer:SetWidth(Table["Width"]*(1 - (relative/swingTime)));
		rais_AutoShot.Texture_Timer:SetVertexColor(1,1,1);
		
		if ( relative >= swingTime ) then
			swingStart = false;
				Cast_Interrupted()
		end
	end
	autoshot_latency_update()
	AutoShotRange = IsSpellInRange(AutoName,"target")


end)
