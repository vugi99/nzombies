local playerMeta = FindMetaTable("Player")
if SERVER then

	function playerMeta:GiveCarryItem(id, modstr)
		if !nzItemCarry.Players[self] then nzItemCarry.Players[self] = {} end
		if nzItemCarry.Items[id].shared then -- If shared, give to all players
			for k,v in pairs(player.GetAllPlaying()) do
				nzItemCarry.Players[v][id] = modstr or nzItemCarry.Players[v][id] or ""
			end
			nzItemCarry:SendPlayerItem()
			if nzItemCarry.Items[id].notif then
				nzItemCarry:SendPlayerItemNotification(nil, id)
			end
		else
			nzItemCarry.Players[self][id] = modstr or nzItemCarry.Players[self][id] or ""
			nzItemCarry:SendPlayerItem(self)
			if nzItemCarry.Items[id].notif then
				nzItemCarry:SendPlayerItemNotification(self, id)
			end
		end
	end
	
	function playerMeta:RemoveCarryItem(id)
		if !nzItemCarry.Players[self] then nzItemCarry.Players[self] = {} end
		if nzItemCarry.Items[id].shared then -- If shared, remove from all players
			for k,v in pairs(player.GetAllPlaying()) do
				nzItemCarry.Players[v][id] = nil
			end
			nzItemCarry:SendPlayerItem()
		else
			if nzItemCarry.Players[self][id] then
				nzItemCarry.Players[self][id] = nil
				nzItemCarry:SendPlayerItem(self)
			end
		end
	end
	
end

function playerMeta:HasCarryItem(id)
	if !nzItemCarry.Players[self] then nzItemCarry.Players[self] = {} end
	return nzItemCarry.Players[self][id]
end

function playerMeta:GetCarryItems()
	if !nzItemCarry.Players[self] then nzItemCarry.Players[self] = {} end
	return table.GetKeys(nzItemCarry.Players[self])
end

function playerMeta:GetCarryItemModifiers()
	if !nzItemCarry.Players[self] then nzItemCarry.Players[self] = {} end
	return nzItemCarry.Players[self]
end

-- On player downed
hook.Add("PlayerDowned", "nzDropCarryItems", function(ply)
	if ply.GetCarryItems then
		for k,v in pairs(ply:GetCarryItems()) do
			local item = nzItemCarry.Items[v]
			if item.dropondowned and item.dropfunction then
				item:dropfunction(ply)
				ply:RemoveCarryItem(v)
			end
		end
	end
end)

-- Players disconnecting/dropping out need to reset the item so it isn't lost forever
hook.Add("OnPlayerDropOut", "nzResetCarryItems", function(ply)
	for k,v in pairs(ply:GetCarryItems()) do
		local item = nzItemCarry.Items[v]
		if item.dropondowned and item.dropfunction then
			item:dropfunction(ply)
		else
			item:resetfunction()
		end
	end
	nzItemCarry.Players[ply] = nil
	nzItemCarry:SendPlayerItem() -- No arguments for full sync, cleans the table of this disconnected player
end)