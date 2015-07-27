local playerMeta = FindMetaTable("Player")
if SERVER then

	function playerMeta:DownPlayer()
		self:AnimRestartGesture(GESTURE_SLOT_GRENADE, ACT_HL2MP_SIT_PISTOL)
		self:SetMoveType(MOVETYPE_NONE)
		self:RemovePerks()
		
		nz.Revive.Data.Players[self] = {}
		nz.Revive.Data.Players[self].DownTime = CurTime()
		nz.Revive.Functions.SendSync()
		
		// Equip the first pistol found in inventory - unless a pistol is already equipped
		local wep = self:GetActiveWeapon()
		if IsValid(wep) and wep:GetHoldType() == "pistol" or wep:GetHoldType() == "duel" or wep.HoldType == "pistol" or wep.HoldType == "duel" then
			print("Already has a pistol equipped!")
			return
		end
		for k,v in pairs(self:GetWeapons()) do
			if v:GetHoldType() == "pistol" or v:GetHoldType() == "duel" or v.HoldType == "pistol" or v.HoldType == "duel" then
				self:SelectWeapon(v:GetClass())
				print("Equipped "..v.ClassName.."!")
				return
			end
		end
	end
	
	function playerMeta:RevivePlayer(nosync)	 //Also used to clear that someone is downed - like when they die
		if !nz.Revive.Data.Players[self] then return end
		self:AnimResetGestureSlot(GESTURE_SLOT_GRENADE)
		self:SetMoveType(MOVETYPE_WALK)
		nz.Revive.Data.Players[self] = nil
		if !nosync then nz.Revive.Functions.SendSync() end
	end
	
	function playerMeta:StartRevive(nosync)
		if !nz.Revive.Data.Players[self] then return end
		if !nosync then nz.Revive.Functions.SendSync() end
	end
	
	function playerMeta:KillDownedPlayer(silent, nosync)
		nz.Revive.Data.Players[self] = nil
		if silent then
			self:KillSilent()
		else
			self:Kill()
		end
		if !nosync then nz.Revive.Functions.SendSync() end
	end
	
end

function playerMeta:GetNotDowned()
	if nz.Revive.Data.Players[self] then
		return false
	else
		return true
	end
end