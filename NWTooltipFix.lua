	--[[

		NWTooltipFix
			by null
			https://github.com/nullfoxh/NWTooltipFix
		
			For use on Atlantiss, Netherwing.
			Shows pre-2.3 Spell and item values on tooltips.
			Remove this addon on patch 2.3!

	]]--
	
	local _G, pairs, tonumber, GetSpellLink, GetTradeSkillInfo, IsControlKeyDown
		= _G, pairs, tonumber, GetSpellLink, GetTradeSkillInfo, IsControlKeyDown

	local find = string.find
	local gsub = string.gsub
	local match = string.match
	local format = string.format

	local itemtips = {
		GameTooltip,
		ShoppingTooltip1,
		ShoppingTooltip2,
		ItemRefTooltip,
	}

	local ItemSubData = {
		[29713] = { { " Drums can be used while shapeshifted.", "\n|cffffffff1 sec cast|r" }, }, -- Pattern: Drums of Panic (Keepers of Time)
		[29714] = { { " Drums can be used while shapeshifted.", "\n|cffffffff1 sec cast|r" }, }, -- Pattern: Drums of Restoration

		[29717] = { { " Drums can be used while shapeshifted.", "\n|cffffffff1 sec cast|r" }, }, -- Pattern: Drums of Battle (Sha'tar)
		[29718] = { { " Drums can be used while shapeshifted.", "\n|cffffffff1 sec cast|r" }, }, -- Pattern: Drums of Speed

		[34172] = { { " Drums can be used while shapeshifted.", "\n|cffffffff1 sec cast|r" }, }, -- Pattern: Drums of Speed (Mag'har)
		[34173] = { { " Drums can be used while shapeshifted.", "\n|cffffffff1 sec cast|r" }, }, -- Pattern: Drums of Speed (Kurenai)
		[34174] = { { " Drums can be used while shapeshifted.", "\n|cffffffff1 sec cast|r" }, }, -- Pattern: Drums of Restoration (Mag'har)
		[34175] = { { " Drums can be used while shapeshifted.", "\n|cffffffff1 sec cast|r" }, }, -- Pattern: Drums of Restoration (Kurenai)

		[29528] = { { " Drums can be used while shapeshifted.", "\n|cffffffff1 sec cast|r" }, }, -- Drums of War
		[29529] = { { " Drums can be used while shapeshifted.", "\n|cffffffff1 sec cast|r" }, }, -- Drums of Battle
		[29530] = { { " Drums can be used while shapeshifted.", "\n|cffffffff1 sec cast|r" }, }, -- Drums of Speed
		[29531] = { { " Drums can be used while shapeshifted.", "\n|cffffffff1 sec cast|r" }, }, -- Drums of Restoration
		[29532] = { { " Drums can be used while shapeshifted.", "\n|cffffffff1 sec cast|r" }, }, -- Drums of Panic
	}

	-- not yet needed, commented out for now
	local SpellSubData = { 
		-- For instance: Persuasion by Lady Vashj
		-- [38511] = { { "$s1.", "200" },  { "$s2.", "1000" }, }, 
	}

	-- We can't get ID's for auras, so we need to use aura name
	local AuraSubData = {
		-- Persuasion by Lady Vashj
		["Persuasion"] = { { "$s1.", "200" },  { "$s2.", "1000" }, }, 
	}


	local function ReplaceHealing(obj)
		local healing = match(obj:GetText(), "Increases healing done by up to (%d+) and damage done")
		if healing then
			obj:SetText(format("Equip: Increases healing done by spells and effects by up to %s.", healing))
		end
	end

	local function ReplaceOther(obj, subdata)
		for k, v in pairs(subdata) do
			local str, count = gsub(obj:GetText(), v[1], v[2])
			if count > 0 then
				obj:SetText(str)
			end
		end
	end

	local function OnTipSetSpell(tip, tipname)
		if IsControlKeyDown() then return end

		local subdata
		local name, rank = tip:GetSpell()
		local id = GetSpellLink(name, rank)
		id = id and tonumber(id:match("spell:(%d+)"))

		if id then
			subdata = SpellSubData[id]
		end

		if subdata then
			for i = 1, tip:NumLines() do
				local obj = _G[format("%sTextLeft%s", tipname, i)]
				if subdata then
					ReplaceOther(obj, subdata)
				end
			end
		end
	end

	local function OnTipSetAura(self, ...)
		if IsControlKeyDown() then return end

		local title = GameTooltipTextLeft1:GetText()
		local subdata = AuraSubData[title]
		if subdata then
			for i = 1, GameTooltip:NumLines() do
				local obj = _G[format("GameTooltipTextLeft%s", i)]
				ReplaceOther(obj, subdata)
			end
		end
	end

	local function OnTipSetItem(tip, name)
		if IsControlKeyDown() then return end

		local subdata
		local _, link = tip:GetItem()

		if link then
			local id = tonumber(match(link, ":(%w+)"))
			subdata = ItemSubData[id]
		end
		
		for i = 1, tip:NumLines() do
			local obj = _G[format("%sTextLeft%s", name, i)]
			ReplaceHealing(obj)
			if subdata then
				ReplaceOther(obj, subdata)
			end
		end
	end

	local function OnSetItemRefTip(link)
		if find(link, "^spell:")then
			--OnTipSetSpell(ItemRefTooltip, "ItemRefTooltip")
		else
			OnTipSetItem(ItemRefTooltip, "ItemRefTooltip")
		end
	end

	for i = 1, #itemtips do
		local t = itemtips[i]
		t:HookScript("OnTooltipSetItem", function(self) OnTipSetItem(self, self:GetName()) end)
	end

	--GameTooltip:SetScript("OnTooltipSetSpell", function(self) OnTipSetSpell(GameTooltip, "GameTooltip") end)

	hooksecurefunc("SetItemRef", OnSetItemRefTip)

	hooksecurefunc(GameTooltip, "SetUnitBuff", OnTipSetAura)
	hooksecurefunc(GameTooltip, "SetUnitDebuff", OnTipSetAura)
	hooksecurefunc(GameTooltip, "SetPlayerBuff", OnTipSetAura)

	if AtlasLootTooltip then
		if AtlasLootTooltip.HookScript2 then
			AtlasLootTooltip:HookScript2("OnShow", function(self) OnTipSetItem(self, self:GetName()) end)
		end
	end


	-- Fix for cooking recipe 'Fisherman's Feast' (spellid 42302)
	-- We hook GetTradeSkillNumMade to return correct yield for the recipe
	-- this should ensure crafting addons work correctly as well.
	local function HookTradeSkillFrame()
		local GetTradeSkillNumMade_orig = GetTradeSkillNumMade
		GetTradeSkillNumMade = function(...)
			local skillName, skillType, numAvailable, isExpanded = GetTradeSkillInfo(...)
			if skillName == "Fisherman's Feast" then
				return 1, 1
			else
				return GetTradeSkillNumMade_orig(...)
			end
		end
	end

	local f = CreateFrame("Frame")
	f:SetScript("OnEvent", function(self, event, addon, ...)
		if addon == "Blizzard_TradeSkillUI" then
			HookTradeSkillFrame()
			self:UnregisterEvent("ADDON_LOADED")
		end
	end)

	if TradeSkillFrame then
		HookTradeSkillFrame()
	else
		f:RegisterEvent("ADDON_LOADED")
	end