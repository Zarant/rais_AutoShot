
local _,class = UnitClass("player");
if not(class == "HUNTER") then return end


local AddOn = "rais_AutoShot-Kronos"
local _G = getfenv(0)


	local Textures = {
		Bar = "Interface\\AddOns\\"..AddOn.."\\Textures\\Bar.tga",
	}
	
	local Table = {
		["posX"] = 0;
		["posY"] = -180;
		["Width"] = 100;
		["Height"] = 15;
	}
	
	local AimedCastBar = false; -- true / false  (WIP)
	

	autoshot_latency = 0

	


	local castdelay = 0
	local _,PlayerRace = UnitRace("player")
	local castStart = false;
	local swingStart = false;
	local aimedStart = false;
	local shooting = false; -- player adott pillantban lő-e
	local posX, posY -- player position when starts Casting
	--local interruptTime -- Concussive shot miatt
	local castTime = 0.65
	local swingTime
	local berserkValue = 0
	local ammoCount = 0
	local prevswing = 0
	local relative
	local mainhandslot = GetInventoryItemLink("player",16)
	local offhandslot = GetInventoryItemLink("player",17)
	local rangedslot = GetInventoryItemLink("player",18)
	local InterruptTimer = 0
	
	
	local multiStart = 0
	--local Background
	local Lat

	
	local function AutoShotBar_Create()
		Table["posX"] = Table["posX"] *GetScreenWidth() /1000;
		Table["posY"] = Table["posY"] *GetScreenHeight() /1000;
		Table["Width"] = Table["Width"] *GetScreenWidth() /1000;
		Table["Height"] = Table["Height"] *GetScreenHeight() /1000;

		_G[AddOn.."_Frame_Timer"] = CreateFrame("Frame",nil,UIParent);
		local Frame = _G[AddOn.."_Frame_Timer"];
		Frame:SetFrameLevel(1)
		Frame:SetFrameStrata("HIGH");
		Frame:SetWidth(Table["Width"]);
		Frame:SetHeight(Table["Height"]);
		Frame:SetPoint("CENTER",UIParent,"CENTER",Table["posX"],Table["posY"]);
		Frame:SetAlpha(0);
		
		_G[AddOn.."_Frame_Timer2"] = CreateFrame("Frame",nil,UIParent);
		local Frame2 = _G[AddOn.."_Frame_Timer2"];
		Frame2:SetFrameLevel(2)
		Frame2:SetFrameStrata("HIGH");
		Frame2:SetWidth(Table["Width"]);
		Frame2:SetHeight(Table["Height"]);
		Frame2:SetPoint("CENTER",UIParent,"CENTER",Table["posX"],Table["posY"]);
		Frame2:SetAlpha(0);
		
		

		_G[AddOn.."_Texture_Timer"] = Frame2:CreateTexture(nil,"OVERLAY"); --overlay
		local Bar = _G[AddOn.."_Texture_Timer"];
		Bar:SetHeight(Table["Height"]);
		Bar:SetTexture(Textures.Bar);
		Bar:SetPoint("CENTER",Frame2,"CENTER");

		

		_G[AddOn.."_Texture_LAT"] = Frame:CreateTexture(nil,"OVERLAY");
		Lat = _G[AddOn.."_Texture_LAT"];
		Lat:SetHeight(Table["Height"]);
		Lat:SetTexture(Textures.Bar);
		Lat:SetPoint("CENTER",Frame,"CENTER");
		Lat:SetVertexColor(0.15,0.15,0.15)
		Lat:SetWidth(Table["Width"] * (castTime - castdelay)/castTime);
		
		
		_G[AddOn.."_Texture_BG"] = Frame:CreateTexture(nil,"ARTWORK");
		Background = _G[AddOn.."_Texture_BG"];
		Background:SetHeight(Table["Height"]);
		Background:SetTexture(Textures.Bar);
		Background:SetPoint("CENTER",Frame,"CENTER");
		Background:SetVertexColor(0.5,0.5,0.5)
		Background:SetWidth(Table["Width"]);
		

		Border = Frame:CreateTexture(nil,"BORDER"); 
		Border:SetPoint("CENTER",Frame,"CENTER");
		Border:SetWidth(Table["Width"] +3);
		Border:SetHeight(Table["Height"] +3);
		Border:SetTexture(0,0,0);
		
	
		local Border = Frame:CreateTexture(nil,"BACKGROUND");
		Border:SetPoint("CENTER",Frame,"CENTER");
		Border:SetWidth(Table["Width"] +6);
		Border:SetHeight(Table["Height"] +6);
		Border:SetTexture(1,1,1);
	end

	local function autoshot_latency_update()
		
		Lat:SetWidth(Table["Width"] * (castTime - castdelay)/castTime);
		Background:SetDrawLayer("ARTWORK")
		
	end




	local function Cast_Start()
		
		--------print('Cast_start '..castdelay)
		autoshot_latency_update()
		_G[AddOn.."_Texture_Timer"]:SetVertexColor(1,0,0);
		posX, posY = GetPlayerMapPosition("player");
		castStart = GetTime();
		
	end
	
	local function Cast_Interrupted()
		----castdelay = 10
		_G[AddOn.."_Frame_Timer"]:SetAlpha(0);
		_G[AddOn.."_Frame_Timer2"]:SetAlpha(0);
		
		swingStart = false;
		
		Cast_Start()
	end
	
	local function Cast_Update()
		_G[AddOn.."_Frame_Timer"]:SetAlpha(1);
		_G[AddOn.."_Frame_Timer2"]:SetAlpha(1);
		relative = GetTime() - castStart;
		
		if ( relative > castTime ) then
			castStart = false;
			_G[AddOn.."_Frame_Timer"]:SetAlpha(0);
			_G[AddOn.."_Frame_Timer2"]:SetAlpha(0);
		elseif ( swingStart == false ) then
			_G[AddOn.."_Texture_Timer"]:SetWidth(Table["Width"] * relative/castTime);
		end
		multis = nil;
		if ((relative > (castTime - castdelay)) and (castStart ~= false)) then
			_G[AddOn.."_Texture_Timer"]:SetVertexColor(0,0,0.5);		

		
		
			shotrotation_update(1)
		

			
		end
		
	end


	local function Shot_Start()
		Cast_Start();
		shooting = true;
	end
	local function Shot_End()
		if ( swingStart == false ) then
			_G[AddOn.."_Frame_Timer"]:SetAlpha(0);
			_G[AddOn.."_Frame_Timer2"]:SetAlpha(0);
		end
		castStart = false
		shooting = false
	end

	local prevswingspeed = false
	local function Swing_Start()
		
		
		swingTime = UnitRangedDamage("player") - castTime;
		
		if not prevswingspeed then
			prevswingspeed = swingTime
		end
		
		if (GetTime() - prevswing) > (prevswingspeed+0.3) then
			_G[AddOn.."_Frame_Timer"]:SetAlpha(1);
			_G[AddOn.."_Frame_Timer2"]:SetAlpha(1);
			_G[AddOn.."_Texture_Timer"]:SetVertexColor(1,1,1);
			castStart = false
			swingStart = GetTime();
			prevswing = swingStart;
			prevswingspeed = swingTime
		end
		
	end



	local AimedTooltip = CreateFrame("GameTooltip","AimedTooltip",UIParent,"GameTooltipTemplate");
	AimedTooltip:SetOwner(UIParent,"ANCHOR_NONE");

	AimedID = 0
	local AimedSlot = 1
	function AimedID_Get()
		local _,_,offset,numSpells = GetSpellTabInfo(GetNumSpellTabs())
		local numAllSpell = offset + numSpells;
		for spellID=1,numAllSpell do
			local name = GetSpellName(spellID,"BOOKTYPE_SPELL");
			if ( name == "Aimed Shot" ) then
				AimedID = spellID
				break
			end
		end
		if AimedID > 0 then
			local AimedT = GetSpellTexture(AimedID,"BOOKTYPE_SPELL")
		end
		for i = 1, 120 do
			if GetActionTexture(i) == AimedT then
				AimedSlot = i
				break
			end
		end
		
	end

	MultiID = 0
	function MultiID_Get()
		local _,_,offset,numSpells = GetSpellTabInfo(GetNumSpellTabs())
		local numAllSpell = offset + numSpells;
		for spellID=1,numAllSpell do
			local name = GetSpellName(spellID,"BOOKTYPE_SPELL");
			if ( name == "Multi-Shot" ) then
				MultiID = spellID
				break
			end
		end
	end


	

	
	local function Aimed_Start()
		aimedStart = GetTime()
	
	
		
		
		if ( swingStart == false ) then
			_G[AddOn.."_Frame_Timer"]:SetAlpha(0);
			_G[AddOn.."_Frame_Timer2"]:SetAlpha(0);
		end
		castStart = false

		--[[
		AimedTooltip:ClearLines();
		AimedTooltip:SetInventoryItem("player", 18)
		local speed_base = string.gsub(AimedTooltipTextRight3:GetText(),"Speed ","")
		local speed_haste = UnitRangedDamage("player");
		local castTime_Aimed = 3 * speed_haste / speed_base -- rapid 1.4 / quick 1.3 / berserking / spider 1.2
		]]

		-- azt kéne, hogy alapból megnézi mennyi az auto-shot casttime (speed_haste) belogoláskor pl. (a lényeg, hogy modosító buff ne legyen), majd utána ahhoz viszonítja az épp jelenlévőt. De lehet ez se jó, mert hátha van olyan amit auto-shotét csökkenti, aimedét nem (mint pl. quiver)

		local castTime_Aimed = 3
		for i=1,32 do
			if UnitBuff("player",i) == "Interface\\Icons\\Ability_Warrior_InnerRage" then
				castTime_Aimed = castTime_Aimed/1.3
			end
			if UnitBuff("player",i) == "Interface\\Icons\\Ability_Hunter_RunningShot" then
				castTime_Aimed = castTime_Aimed/1.4
			end
			if (UnitBuff("player",i) == "Interface\\Icons\\Racial_Troll_Berserk") and  (PlayerRace == "Troll") then
				castTime_Aimed = castTime_Aimed/ (1 + berserkValue)
			end
			if UnitBuff("player",i) == "Interface\\Icons\\Inv_Trinket_Naxxramas04" then
				castTime_Aimed = castTime_Aimed/1.2
			end
		end
		
		--[[local _,_,castdelay = GetNetStats();
		castdelay = castdelay/1000;
		castTime_Aimed = castTime_Aimed - castdelay;]]
		--castdelay = autoshot_latency/1e3
		
		if ( AimedCastBar == true ) then
			CastingBarFrameStatusBar:SetStatusBarColor(1.0, 0.7, 0.0);
			CastingBarSpark:Show();
			CastingBarFrame.startTime = GetTime();
			CastingBarFrame.maxValue = CastingBarFrame.startTime + castTime_Aimed;
			CastingBarFrameStatusBar:SetMinMaxValues(CastingBarFrame.startTime, CastingBarFrame.maxValue);
			CastingBarFrameStatusBar:SetValue(CastingBarFrame.startTime);
			
		
			CastingBarText:SetText("Aimed Shot   "..string.format("%.2f",castTime_Aimed));
			
			-- CastingBarText:SetText(castTime_Aimed);
			CastingBarFrame:SetAlpha(1.0);
			CastingBarFrame.holdTime = 0;
			CastingBarFrame.casting = 1;
			CastingBarFrame.fadeOut = nil;
			CastingBarFrame:Show();
			CastingBarFrame.mode = "casting";
		end
	end
	
	function multi_start()
			multiStart = GetTime()
			
			local castTime_Multi = 0.5
			if ( AimedCastBar == true ) then
				CastingBarFrameStatusBar:SetStatusBarColor(1.0, 0.7, 0.0);
				CastingBarSpark:Show();
				CastingBarFrame.startTime = GetTime();
				CastingBarFrame.maxValue = CastingBarFrame.startTime + castTime_Multi;
				CastingBarFrameStatusBar:SetMinMaxValues(CastingBarFrame.startTime, CastingBarFrame.maxValue);
				CastingBarFrameStatusBar:SetValue(CastingBarFrame.startTime);
				
			
				CastingBarText:SetText("Multi-Shot   "..string.format("%.2f",castTime_Multi));
				
				-- CastingBarText:SetText(castTime_Aimed);
				CastingBarFrame:SetAlpha(1.0);
				CastingBarFrame.holdTime = 0;
				CastingBarFrame.casting = 1;
				CastingBarFrame.fadeOut = nil;
				CastingBarFrame:Show();
				CastingBarFrame.mode = "casting";
			end
	end
	
	
	local eventCount = 0
	local spellcast = 0
	local spelltimer = 0
	--
	
	UseAction_Real = UseAction;
	function UseAction( slot, checkFlags, checkSelf )
		--------print(slot)
		AimedTooltip:ClearLines();
		AimedTooltip:SetAction(slot);
		
		spelltimer = GetTime()
		
		local spellName = AimedTooltipTextLeft1:GetText();
		
		
			if ( spellName == "Aimed Shot" ) then
				spellcast = 1
			elseif ( spellName == "Multi-Shot" ) then
				spellcast = 2
			else
			spellcast = 0
			
			end
	
		------print(spellName..':'..slot)
			----print('s'..spellcast..' '..spellName)
		UseAction_Real( slot, checkFlags, checkSelf );
	end

	CastSpell_Real = CastSpell;
	function CastSpell(spellID, spellTab)
			------print("1-"..spellID)
			spelltimer = GetTime()
			if not(AimedID) then
				AimedID_Get()
			end
		
		
			if ( spellID == AimedID and spellTab == "BOOKTYPE_SPELL" ) then
				spellcast = 1
			elseif ( spellID == MultiID and spellTab == "BOOKTYPE_SPELL" ) then
				spellcast = 2
			else
			spellcast = 0
			
			end
		
			----print('s'..spellcast)
		CastSpell_Real(spellID,spellTab);
	end

	CastSpellByName_Real = CastSpellByName;
	function CastSpellByName(spellName)
		
			if ( spellName == "Aimed Shot" ) then
				spellcast = 1
			elseif ( spellName == "Multi-Shot" ) then
				spellcast = 2
			else
				spellcast = 0
			end
		
		
		------print("2-"..spellName)
		----print('s'..spellcast)
		spelltimer = GetTime()
		CastSpellByName_Real(spellName)
		
	end



	local Frame = CreateFrame("Frame"); --Frame:RegisterAllEvents() Frame:SetScript("OnEvent",function() ----print(event) end)
	Frame:RegisterEvent("SKILL_LINES_CHANGED")
	Frame:RegisterEvent("PLAYER_LOGIN")
	Frame:RegisterEvent("SPELLCAST_STOP")
	Frame:RegisterEvent("CURRENT_SPELL_CAST_CHANGED")
	Frame:RegisterEvent("START_AUTOREPEAT_SPELL")
	Frame:RegisterEvent("STOP_AUTOREPEAT_SPELL")
	Frame:RegisterEvent("ITEM_LOCK_CHANGED")
	Frame:RegisterEvent("CHAT_MSG_SPELL_FAILED_LOCALPLAYER")
	Frame:RegisterEvent("SPELLCAST_FAILED")
	Frame:RegisterEvent("SPELL_UPDATE_COOLDOWN")
	
	if (PlayerRace == "Troll") then
		Frame:RegisterEvent("UNIT_AURA")
	end	
	
	local ammoCheck = false
	local previousEvent
	local lockTimer = 0
	local csccTimer = 0
	
	Frame:SetScript("OnEvent",function()

		
		
		--print((GetTime() - spelltimer)..' '..event..'-'..eventCount..':'..spellcast)
		if ( event == "PLAYER_LOGIN" ) then
			AutoShotBar_Create();
			DEFAULT_CHAT_FRAME:AddMessage("|cff00ccff"..AddOn.."|cffffffff Loaded");
		end
		if ( event == "START_AUTOREPEAT_SPELL" ) then

			
			if castdelay > 0 then
				castdelay = 0
				--------print(event..' '..castdelay)
				autoshot_latency_update();
			end
			
			Shot_Start();
			
			
		end
		if ( event == "STOP_AUTOREPEAT_SPELL" ) then
			prevswingspeed = false
			Shot_End();
		end

		if ( event == "SKILL_LINES_CHANGED" ) then
			AimedID_Get()
			MultiID_Get()
		end
		
		if ( event == "SPELLCAST_STOP" ) then
			
			
			--local framerate = GetFramerate()
			--if (previousEvent == "CURRENT_SPELL_CAST_CHANGED") or ((GetTime() - csccTimer) <= 1/framerate)  then
				
				
				
				if ( aimedStart ~= false ) then
					aimedStart = false
				end
				
				
				multiStart = 0
				
				
				
				
				spellcast = 0
				eventCount = 0
				
			--end
		
			if ammoCheck then 
			
				local framerate = GetFramerate()
				if (previousEvent == "ITEM_LOCK_CHANGED") or ((GetTime() - lockTimer) <= 1.1/framerate)  then

					--print('boom')
					if (autoshot_latency/1e3 < castTime) then
						castdelay = autoshot_latency/1e3
					else 
						castdelay = castTime*0.99
					end
					------print('Swing_start '..castdelay)
					autoshot_latency_update();
					Swing_Start();

					
				end
				ammoCheck = false
			end
		
			
		end
		if ( event == "CURRENT_SPELL_CAST_CHANGED" ) then
			--------print((GetTime() - spelltimer)..' cast changed')
			--[[
			if (previousEvent == "ITEM_LOCK_CHANGED") or ((GetTime() - lockTimer) <= 1.1/framerate)  then
				ammoCheck = false
			end]]
			
			ammoCheck = false
			
			if (spellcast > 0) and (eventCount < 1) then
				eventCount = 1
				
			elseif (spellcast < 0) then
				spellcast = 0
			end
			
			if (eventCount > 0) then
				local framerate = GetFramerate()
				if ((GetTime() - spelltimer) <= 1/framerate) then
					eventCount = eventCount + 1
					if eventCount > 32 then
						if spellcast == 1 then
							eventCount = 0
							spellcast = 0
							Aimed_Start()
							----print('aimedstart')
						elseif spellcast == 2 then
							----print(eventCount)
							eventCount = 0
							spellcast = 0
							----print(eventCount)
							multi_start()
						else
							spellcast = 0
						end
					end
					
					
					----print(eventCount)
				else
					eventCount = 0
					spellcast = 0
					
					----print('fail')
				end
			end
		
		csccTimer = GetTime()
			
		end
		
		
		if  (event == "SPELLCAST_FAILED") or (event == "CHAT_MSG_SPELL_FAILED_LOCALPLAYER") then
			
			eventCount = 0
			spellcast = 0
		end
		

		
		if ( event == "SPELL_UPDATE_COOLDOWN" ) then

			----print((GetTime() - spelltimer)..' update cd')
			
			
			
			if eventCount > 4 then
				local framerate = GetFramerate()
				if ((GetTime() - spelltimer) <= 1/framerate) then
					eventCount = eventCount*32
					----print('uc '..eventCount)
				else
					eventCount = 0
					spellcast = 0

				end
			end
			
			
			if ammoCheck then 
			
				local framerate = GetFramerate()
				if ((previousEvent == "ITEM_LOCK_CHANGED") or ((GetTime() - lockTimer) <= 1.1/framerate)) and (previousEvent ~= "SPELLCAST_STOP")  then

					--print('boom')
					if (autoshot_latency/1e3 < castTime) then
						castdelay = autoshot_latency/1e3
					else 
						castdelay = castTime*0.99
					end
					----print('Swing_start '..castdelay)
					autoshot_latency_update();
					Swing_Start();

					
				end
				ammoCheck = false
			end

			
		end
						
				
		if ( event == "ITEM_LOCK_CHANGED" ) then
			
			
			if UnitAffectingCombat("player") and ((mainhandslot ~= GetInventoryItemLink("player",16)) or (offhandslot ~= GetInventoryItemLink("player",17)) or (rangedslot ~= GetInventoryItemLink("player",18))) then
				InterruptTimer = GetTime() + 1.5
				----print('beep beep')
			end
			
			mainhandslot = GetInventoryItemLink("player",16)
			offhandslot = GetInventoryItemLink("player",17)
			rangedslot = GetInventoryItemLink("player",18)
			
			if ( shooting == true ) then 
				
				--[[local _,_,offset,numSpells = GetSpellTabInfo(GetNumSpellTabs())
				local numAllSpell = offset + numSpells;
				for i=1,numAllSpell do
					local name = GetSpellName(i,"BOOKTYPE_SPELL");
					if ( name == "Aimed Shot" ) then
						aST,aSCD = GetSpellCooldown(i,"BOOKTYPE_SPELL")
					end
				end]]
				

				if ( aimedStart ~= false ) then
					
					if (autoshot_latency/1e3 < castTime) then
						castdelay = autoshot_latency/1e3
					else 
						castdelay = castTime*0.99
					end
					autoshot_latency_update();
					_G[AddOn.."_Frame_Timer"]:SetAlpha(1);
					_G[AddOn.."_Frame_Timer2"]:SetAlpha(1);
					Cast_Start();
				
				end
				
				
				
				if (ammoCount ~= GetInventoryItemCount("player", 0)) then
					
					ammoCheck = true
				end

	--			if ( GetTime()-interruptTime > 0.3 ) then -- ha Concussive Shot castolás megy Auto-Shot castolás közben, ne induljon el a swingtimer
	--			end
			end
			
			ammoCount = GetInventoryItemCount("player", 0)
			lockTimer = GetTime();
			
		end
		--[[if ( UnitName("target") ) then
			if ( event ~= "CHAT_MSG_CHANNEL" and event ~= "TABARD_CANSAVE_CHANGED" and event ~= "SPELL_UPDATE_COOLDOWN" and event ~= "CHAT_MSG_SPELL_FAILED_LOCALPLAYER"  and event ~= "CURSOR_UPDATE" and event ~= "CHAT_MSG_COMBAT_SELF_HITS" and event ~= "SPELL_UPDATE_USABLE" and event ~= "UPDATE_MOUSEOVER_UNIT" and event ~= "UNIT_HAPPINESS" and event ~= "PLAYER_TARGET_CHANGED" and event ~= "UNIT_MANA" and event ~= "UNIT_HEALTH" ) then
				if ( event ~= "ACTIONBAR_UPDATE_STATE" and event ~= "CURRENT_SPELL_CAST_CHANGED" ) then
					if ( event ~= "UNIT_COMBAT" and event ~= "UI_ERROR_MESSAGE"and event ~= "SPELLCAST_INTERRUPTED" ) then
						DEFAULT_CHAT_FRAME:AddMessage(event);
					end
				end
			end
		end]]
		if ( event == "UNIT_AURA" ) then
			for i=1,16 do
				if ( UnitBuff("player",i) == "Interface\\Icons\\Racial_Troll_Berserk" ) then
					if ( berserkValue == 0 ) then
						if((UnitHealth("player")/UnitHealthMax("player")) >= 0.40) then
							berserkValue = (1.30 - (UnitHealth("player")/UnitHealthMax("player")))/3
						else
							berserkValue = 0.30
						end
					end
				else
					berserkValue = 0
				end
			end
		end

		previousEvent = event;
	end)

	Frame:SetScript("OnUpdate",function()
		
		if ( shooting == true ) then
			autoshot_latency_update()
			if ( castStart ~= false ) then
			
				local cposX, cposY = GetPlayerMapPosition("player") -- player position atm
				
				if (multiStart > 0) or (InterruptTimer > GetTime()) then
					
					Cast_Interrupted();
					
				elseif ( posX == cposX and posY == cposY ) then
					
					Cast_Update();
				else
					if castdelay > 0 then
						
						castdelay = 0
						autoshot_latency_update();
						--------print('Cast update '..castdelay)
					end
					Cast_Interrupted();
					
				end
			end
					

			
		end

		
		if ( swingStart ~= false ) then
			relative = GetTime() - swingStart
			
			_G[AddOn.."_Texture_Timer"]:SetWidth(Table["Width"] - (Table["Width"]*relative/swingTime));
			_G[AddOn.."_Texture_Timer"]:SetVertexColor(1,1,1);
			
			
		
				shotrotation_update(0)
			
	
			
			if ( relative > swingTime ) then
				if ( shooting == true and aimedStart == false ) then
					Cast_Start()
				else
					_G[AddOn.."_Texture_Timer"]:SetWidth(0);
					_G[AddOn.."_Frame_Timer"]:SetAlpha(0);
					_G[AddOn.."_Frame_Timer2"]:SetAlpha(0);
				end
				swingStart = false;
			end
		end
	end)

	
	
	
-- Handles the shot rotation 1 button macro (WIP)

multis = nil
aimed = nil
function shotrotation_update(arg1)

	if arg1 == 0 then
		if not(AimedID and MultiID)  then
			AimedID_Get()
			MultiID_Get()
		end
		local Astart, Aduration = GetSpellCooldown(AimedID, "BOOKTYPE_SPELL")
		local Mstart, Mduration = GetSpellCooldown(MultiID, "BOOKTYPE_SPELL")

		if (relative < (swingTime - 0.55)) then
			multis = 1
		else
			multis = nil;
		end
		if (relative > (swingTime - 0.7)) and ((math.abs(Mstart - Astart - (Mduration - Aduration)) < 0.7)) then
		 
			multis = nil;
			
		end
		local d = GetTime() - Astart
		if (relative < 0.6) then
			aimed = 1;
			if d > (6 - 0.6) then
				multis = nil
				
			end
		else
			aimed = nil;
		end
		return true
	elseif arg1 == 1 then
	
		aimed = 1;
		multis = 1;
		
		if not(AimedID and MultiID)  then
			AimedID_Get()
			MultiID_Get()
		end
		local Astart, Aduration = GetSpellCooldown(AimedID, "BOOKTYPE_SPELL")
		local Mstart, Mduration = GetSpellCooldown(MultiID, "BOOKTYPE_SPELL")
		if (math.abs(Mstart - Astart - (Mduration - Aduration)) < (0.6+castdelay)) then
			multis = nil;
		end
		
		if (GetTime() - Astart) > (6 - 0.6 - castdelay) then
			multis = nil
		end
		return true
	end
	
	
end


function ShotRotation(ping)
	
	autoshot_latency = ping
	if not(AimedID and MultiID) or not(GetActionTexture(AimedSlot) == AimedT)  then
		AimedID_Get()
		MultiID_Get()
	end
	
	local Astart, Aduration = GetSpellCooldown(AimedID, "BOOKTYPE_SPELL")
	local Mstart, Mduration = GetSpellCooldown(MultiID, "BOOKTYPE_SPELL")	

	
	if not shooting then
		CastSpellByName("Auto Shot")
	end


	if aimed and (Aduration ~= 6) and UnitCanAttack("target","player") and not(IsCurrentAction(AimedSlot)) then
		CastSpellByName("Aimed Shot")
	end

	
	local name, subtext, texture, isToken, isActive = GetPetActionInfo(4)
	if isActive then
		CastSpellByName("Lightning Breath")
		
	end
	
	if multis then
		CastSpellByName("Multi-Shot")
	end


end

	
	
