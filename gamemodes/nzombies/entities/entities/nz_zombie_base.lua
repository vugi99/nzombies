AddCSLuaFile()

ENT.Base = "base_nextbot"
ENT.PrintName = "Zombie"
ENT.Category = "Brainz"
ENT.Author = "Zet0r"

ENT.bIsZombie = true
nzConfig.ValidEnemies["nz_zombie_base"] = {
	-- Set to false to disable the spawning of this zombie
	Valid = true,
	-- Allow you to scale damage on a per-hitgroup basis
	ScaleDMG = function(zombie, hitgroup, dmginfo)
		-- Headshots for double damage
		if hitgroup == HITGROUP_HEAD then dmginfo:ScaleDamage(2) end
	end,
	-- Function runs whenever the zombie is damaged (NOT when killed)
	OnHit = function(zombie, dmginfo, hitgroup)
		local attacker = dmginfo:GetAttacker()
		-- If player is playing and is not downed, give points
		if attacker:IsPlayer() and attacker:GetNotDowned() then
			attacker:GivePoints(10)
		end
	end,
	-- Function is run whenever the zombie is killed
	OnKilled = function(zombie, dmginfo, hitgroup)
		local attacker = dmginfo:GetAttacker()
		if attacker:IsPlayer() and attacker:GetNotDowned() then
			if dmginfo:GetDamageType() == DMG_CLUB then
				attacker:GivePoints(130)
			elseif hitgroup == HITGROUP_HEAD then
				attacker:GivePoints(100)
			else
				attacker:GivePoints(50)
			end
		end
	end
}

-- Data to be set by extensions
ENT.Model = "models/nzombies/zombie_rigs/nzombie_honorguard.mdl"
ENT.Speed = 100
ENT.AttackRange = 50
ENT.PathTolerance = 10

-- Only in the base
AccessorFunc( ENT, "fRunSpeed", "RunSpeed", FORCE_NUMBER)
AccessorFunc( ENT, "bTimedOut", "TimedOut", FORCE_BOOL)


function ENT:Initialize()

	self:SetModel(self.Model)
	self.ZombieAlive = true

end

function ENT:TimeOut(time)
	self:SetTimedOut(true)
	if coroutine.running() then
		coroutine.wait(time)
	end
end

---------------------------------------------------
---			Pathing related functions			---
---------------------------------------------------
function ENT:GetTargetPosition()
	return self.TargetPosition
end
function ENT:SetTargetPosition(pos)
	self.TargetPosition = pos
end
function ENT:HasTarget()
	return self:IsValidTarget(self:GetTarget())
end
function ENT:IsValidTarget(ent)
	return IsValid(ent) and ent:GetTargetPriority() > TARGET_PRIORITY_NONE
end
function ENT:GetTarget()
	return self.Target
end
function ENT:SetTarget(ent)
	self.Target = ent
end
function ENT:GetTargetNavArea()
	return self:HasTarget() and navmesh.GetNearestNavArea( self:GetTarget():GetPos(), false, 100)
end

function ENT:GetTargetPosition()
	return self.TargetPosition
end
function ENT:SetTargetPosition(pos)
	self.TargetPosition = pos
end


function ENT:OnPathingOK()
	--if self:TargetInAttackRange() then
		--self:OnTargetInAttackRange()
		self:TimeOut(1)
	--else
		self:TimeOut(0.5)
	--end
end
function ENT:OnPathingFailed() self:TimeOut(2) end
function ENT:OnPathingTimeout() end
function ENT:OnPathingBarricade(barricade, normal)
	self:OnBarricadeBlocking(barricade, normal)
end
function ENT:OnPathingRetarget() self:TimeOut(1) end
function ENT:OnPathingStuck() self:TimeOut(3) end

function ENT:RunBehaviour()
	self:SetTarget(Entity(1))
	while (true) do
		local targetpos = self:GetTargetPosition()
		local tolerance = 0
		if not targetpos then
			local target = self:GetTarget()
			if self:IsValidTarget(target) then
				targetpos = target:GetPos()
				tolerance = self.PathTolerance
			end
		end
		if targetpos then
			local result, arg1, arg2 = self:ChaseTarget({
				maxage = 1,
				draw = true,
				tolerance = tolerance,
				target = targetpos
			})
			self[result](self, arg1, arg2) -- Call self:Result() depending on the result of pathfinding
		else
			self:TimeOut(1)
		end
	end
end

function ENT:ChaseTarget( options )

	if not options.target then
		return "OnPathingRetarget"
	end
	
	local path = self:ChaseTargetPath(options)
	if not IsValid(path) then return "OnPathingFailed" end
	while (IsValid(path)) do
		if not self:HasTarget() then
			return "OnPathingRetarget"
		end
		
		path:Update(self)
		
		if ( path:GetAge() > options.maxage ) then
			local segment = path:FirstSegment()
			if segment then
				local barricade, normal = self:CheckForBarricade(segment.forward)
				if barricade then return "OnPathingBarricade", barricade, normal end
			end
			return "OnPathingTimeout"
		end
		
		coroutine.yield()
	end
	
	return "OnPathingOK"

end

function ENT:ChaseTargetPath( options )
	options = options or {}

	local path = Path( "Follow" )
	path:SetMinLookAheadDistance( options.lookahead or 300 )
	path:SetGoalTolerance( options.tolerance or 30 )

	-- Custom path computer, the same as default but not pathing through locked nav areas.
	path:Compute( self, options.target,  function( area, fromArea, ladder, elevator, length )
		if ( !IsValid( fromArea ) ) then
			-- First area in path, no cost
			return 0
		else
			if ( !self.loco:IsAreaTraversable( area ) ) then
				-- Our locomotor says we can't move here
				return -1
			end
			-- Prevent movement through either locked navareas or areas with closed doors
			if (nzNav.Locks[area:GetID()]) then
				if nzNav.Locks[area:GetID()].link then
					if !nzDoors:IsLinkOpened( nzNav.Locks[area:GetID()].link ) then
						return -1
					end
				elseif nzNav.Locks[area:GetID()].locked then
				return -1 end
			end
			-- Compute distance traveled along path so far
			local dist = 0
			--[[if ( IsValid( ladder ) ) then
				dist = ladder:GetLength()
			elseif ( length > 0 ) then
				--optimization to avoid recomputing length
				dist = length
			else
				dist = ( area:GetCenter() - fromArea:GetCenter() ):GetLength()
			end]]--
			local cost = dist + fromArea:GetCostSoFar()
			--check height change
			local deltaZ = fromArea:ComputeAdjacentConnectionHeightChange( area )
			if ( deltaZ >= self.loco:GetStepHeight() ) then
				-- use player default max jump height even thouh teh zombie will jump a bit higher
				if ( deltaZ >= 64 ) then
					--Include ladders in pathing:
					--currently disableddue to the lack of a loco:Climb function
					--[[if IsValid( ladder ) then
						if ladder:GetTopForwardArea():GetID() == area:GetID() then
							return cost
						end
					end --]]
					--too high to reach
					return -1
				end
				--jumping is slower than flat ground
				local jumpPenalty = 1.1
				cost = cost + jumpPenalty * dist
			elseif ( deltaZ < -self.loco:GetDeathDropHeight() ) then
				--too far to drop
				return -1
			end
			return cost
		end
	end)

	return path
end

function ENT:CheckForBarricade(dir)
	-- First off, try a trace line since it's better
	local dataL = {}
	dataL.start = self:GetPos() + Vector(0, 0, self:OBBCenter().z)
	dataL.endpos = self:GetPos() + Vector(0, 0, self:OBBCenter().z) + dir * 48
	dataL.filter = function(ent) return ent:GetClass() == "breakable_entry" end
	dataL.ignoreworld = true
	local trL = util.TraceLine(dataL)

	--debugoverlay.Line(self:GetPos() + Vector( 0, 0, self:OBBCenter().z ), self:GetPos() + Vector( 0, 0, self:OBBCenter().z ) + self.BarricadeCheckDir * 32)
	--debugoverlay.Cross(self:GetPos() + Vector( 0, 0, self:OBBCenter().z ), 1)
	
	if IsValid(trL.Entity) then
		return trL.Entity, trL.HitNormal
	end

	-- Perform a hull trace if line didn't hit just to make sure
	local dataH = {}
	dataH.start = self:GetPos()
	dataH.endpos = self:GetPos() + dir * 48
	dataH.filter = function(ent) return ent:GetClass() == "breakable_entry" end
	dataH.mins = self:OBBMins() * 0.65
	dataH.maxs = self:OBBMaxs() * 0.65
	local trH = util.TraceHull(dataH)

	if IsValid(trH.Entity) then
		return trH.Entity, trH.HitNormal
	end

	return nil

end


local barricaderips = {
	[1] = {
		{"nz_boardtear_m_1_grab", "nz_boardtear_m_1_hold", "nz_boardtear_m_1_pull"},
		{"nz_boardtear_m_2_grab", "nz_boardtear_m_2_hold", "nz_boardtear_m_2_pull"},
		{"nz_boardtear_m_3_grab", "nz_boardtear_m_3_hold", "nz_boardtear_m_3_pull"},
		{"nz_boardtear_m_4_grab", "nz_boardtear_m_4_hold", "nz_boardtear_m_4_pull"},
		{"nz_boardtear_m_5_grab", "nz_boardtear_m_5_hold", "nz_boardtear_m_5_pull"},
		{"nz_boardtear_m_6_grab", "nz_boardtear_m_6_hold", "nz_boardtear_m_6_pull"},
	},
	[2] = {
		{"nz_boardtear_l_1_grab", "nz_boardtear_l_1_hold", "nz_boardtear_l_1_pull"},
		{"nz_boardtear_l_2_grab", "nz_boardtear_l_2_hold", "nz_boardtear_l_2_pull"},
		{"nz_boardtear_l_3_grab", "nz_boardtear_l_3_hold", "nz_boardtear_l_3_pull"},
		{"nz_boardtear_l_4_grab", "nz_boardtear_l_4_hold", "nz_boardtear_l_4_pull"},
		{"nz_boardtear_l_5_grab", "nz_boardtear_l_5_hold", "nz_boardtear_l_5_pull"},
		{"nz_boardtear_l_6_grab", "nz_boardtear_l_6_hold", "nz_boardtear_l_6_pull"},
	},
	[3] = {
		{"nz_boardtear_r_1_grab", "nz_boardtear_r_1_hold", "nz_boardtear_r_1_pull"},
		{"nz_boardtear_r_2_grab", "nz_boardtear_r_2_hold", "nz_boardtear_r_2_pull"},
		{"nz_boardtear_r_3_grab", "nz_boardtear_r_3_hold", "nz_boardtear_r_3_pull"},
		{"nz_boardtear_r_4_grab", "nz_boardtear_r_4_hold", "nz_boardtear_r_4_pull"},
		{"nz_boardtear_r_5_grab", "nz_boardtear_r_5_hold", "nz_boardtear_r_5_pull"},
		{"nz_boardtear_r_6_grab", "nz_boardtear_r_6_hold", "nz_boardtear_r_6_pull"},
	},
}
function ENT:OnBarricadeBlocking(barricade, dir)
	if barricade:GetNumPlanks() > 0 then
		local barricadeattach = barricade:GetEmptyAttachSlot(self)
		if barricadeattach then
			local pos, ang = barricade:GetAttachPosition(barricadeattach)
			timer.Simple(0.2, function()
				if IsValid(self) then
					self:SetPos(pos)
					self:SetAngles(ang)
				end
			end)
			--barricade:AttachZombie(self, barricadeattach)
			
			while barricade:GetNumPlanks() > 0 do
				local plank, index = barricade:GetNextRepairedPlank()
				if plank then
					local grab = barricaderips[barricadeattach][index][1]
					local hold = barricaderips[barricadeattach][index][2]
					local pull = barricaderips[barricadeattach][index][3]
					
					local time = barricade:GrabPlank(zombie, plank)
					self:PlaySequenceAndWait(grab)
					while time > CurTime() do
						self:PlaySequenceAndWait(hold)
					end
					barricade:RemovePlank(plank, dir)
					self:PlaySequenceAndWait(pull)
				else
					self:TimeOut(1)
				end
			end
		end
		
		-- Attacking a new barricade resets the counter
		self.BarricadeJumpTries = 1	
	elseif barricade:GetTriggerJumps() and self.TriggerBarricadeJump then
		local dist = barricade:GetPos():DistToSqr(self:GetPos())
		if dist <= 3500 + (1000 * self.BarricadeJumpTries) then
			self:TriggerBarricadeJump(barricade, dir)
			self.BarricadeJumpTries = 0
		else
			-- If we continuously fail, we need to increase the check range (if it is a bigger prop)
			self.BarricadeJumpTries = self.BarricadeJumpTries + 1
			-- Otherwise they'd get continuously stuck on slightly bigger props :(
		end
	else
		self:SetAttacking(false)
	end
end