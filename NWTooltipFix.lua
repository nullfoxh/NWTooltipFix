	--[[

		NWTooltipFix
			by null
			https://github.com/nullfoxh/NWTooltipFix
		
			For use on Atlantiss, Netherwing.
			Shows pre-2.3 Spell and item values on tooltips.
			Remove this addon on patch 2.3!

	]]--
	
	local _G, pairs, tonumber
		= _G, pairs, tonumber

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
		[29713] = { { " Drums can be used while shapeshifted.", "" }, }, -- Pattern: Drums of Panic (Keepers of Time)
		[29714] = { { " Drums can be used while shapeshifted.", "" }, }, -- Pattern: Drums of Restoration

		[29717] = { { " Drums can be used while shapeshifted.", "" }, }, -- Pattern: Drums of Battle (Sha'tar)
		[29718] = { { " Drums can be used while shapeshifted.", "" }, }, -- Pattern: Drums of Speed

		[34172] = { { " Drums can be used while shapeshifted.", "" }, }, -- Pattern: Drums of Speed (Mag'har)
		[34173] = { { " Drums can be used while shapeshifted.", "" }, }, -- Pattern: Drums of Speed (Kurenai)
		[34174] = { { " Drums can be used while shapeshifted.", "" }, }, -- Pattern: Drums of Restoration (Mag'har)
		[34175] = { { " Drums can be used while shapeshifted.", "" }, }, -- Pattern: Drums of Restoration (Kurenai)

		[29528] = { { " Drums can be used while shapeshifted.", "" }, }, -- Drums of War
		[29529] = { { " Drums can be used while shapeshifted.", "" }, }, -- Drums of Battle
		[29530] = { { " Drums can be used while shapeshifted.", "" }, }, -- Drums of Speed
		[29531] = { { " Drums can be used while shapeshifted.", "" }, }, -- Drums of Restoration
		[29532] = { { " Drums can be used while shapeshifted.", "" }, }, -- Drums of Panic
	}

	local function ReplaceHealing(obj, text)
		local healing = match(text, "Increases healing done by up to (%d+) and damage done")
		if healing then
			obj:SetText(format("Equip: Increases healing done by spells and effects by up to %s.", healing))
		end
	end

	local function ReplaceOther(obj, text, subdata)
		for k, v in pairs(subdata) do
			local str, count = gsub(text, v[1], v[2])
			if count > 0 then
				obj:SetText(str)
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
			local text = obj:GetText()
			ReplaceHealing(obj, text)
			if subdata then
				ReplaceOther(obj, text, subdata)
			end
		end
	end

	for i = 1, #itemtips do
		local t = itemtips[i]
		t:HookScript("OnTooltipSetItem", function(self) OnTipSetItem(self, self:GetName()) end)
	end

	hooksecurefunc("SetItemRef", function() OnTipSetItem(ItemRefTooltip, "ItemRefTooltip") end)

	if AtlasLootTooltip then
		AtlasLootTooltip:HookScript2("OnShow", function(self) OnTipSetItem(self, self:GetName()) end)
	end