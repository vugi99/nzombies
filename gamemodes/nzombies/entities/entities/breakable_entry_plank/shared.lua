AddCSLuaFile( )

ENT.Type = "anim"
 
ENT.PrintName		= "breakable_entry_plank"
ENT.Author			= "Zet0r"
ENT.Contact			= ""
ENT.Purpose			= ""
ENT.Instructions	= ""

function ENT:Initialize()

	self:SetModel("models/props_debris/wood_board02a.mdl")
	self:SetMoveType( MOVETYPE_VPHYSICS )
	self:SetSolid( SOLID_VPHYSICS )
	self:SetModelScale(1.25)
	
	if CLIENT then
		local mat = Matrix()
		mat:Scale(Vector(1, 1.5, 1))
		self:EnableMatrix( "RenderMultiply", mat )
	end
	
end

if SERVER then
	-- Perhaps make the animation client-sided using SetRenderOrigin?
	
	local stages = {
		function(self, barricade)
			self.BeginPos = self:GetPos()
			self.BeginAng = self:GetAngles()
			self.TargetPos = self:GetPos()
			self.TargetAng = self:GetAngles()
			self.TargetTime = CurTime()
			self.TargetDuration = 0.3
		end,
		function(self, barricade)
			self.BeginPos = self:GetPos()
			self.BeginAng = self:GetAngles()
			self.TargetPos = self.FinalPos
			self.TargetAng = self.FinalAng
			self.TargetTime = CurTime()
			self.TargetDuration = 0.1
		end,
	}
	
	function ENT:Repair(barricade, pos, ang)
		self.Barricade = barricade
		local bpos = barricade:GetPos()
		local bang = barricade:GetAngles()
		local tang = bang + Angle(0,0,ang)
		local tpos = bpos + barricade:GetAngles():Forward()*50
		self:SetPos(tpos + Vector(0,0,-40))
		self:SetAngles(Angle(90,math.random(-180,180),math.random(-180,180)))
		self:Spawn()
		
		local pos = bang:Forward()*pos.x + bang:Right()*pos.y + bang:Up()*pos.z
		
		self.BeginPos = self:GetPos()
		self.BeginAng = self:GetAngles()
		self.TargetPos = pos + tpos
		self.TargetAng = tang
		self.TargetTime = CurTime()
		self.TargetDuration = 0.3
		
		self.FinalPos = bpos + pos
		self.FinalAng = tang
		
		self.RepairStage = 0
		self.Repairing = true
	end
	
	function ENT:Think()
		if self.Repairing then
			local phys = self
			if IsValid(phys) then
				local diff = (CurTime() - self.TargetTime)/self.TargetDuration
				if diff >= 1 then
					self.RepairStage = self.RepairStage + 1
					if self.RepairStage > 2 then self.Repairing = false self.Repaired = true return end
					stages[self.RepairStage](self, self.Barricade)
				end
				
				local tpos = LerpVector(diff, self.BeginPos, self.TargetPos)
				local tang = LerpAngle(diff, self.BeginAng, self.TargetAng)
		
				phys:SetPos(tpos)
				phys:SetAngles(tang)
				
				self:NextThink(CurTime()+0.01)
				return true
			end
		end
	end
end

if CLIENT then
	function ENT:Draw()
		self:DrawModel()
	end
end