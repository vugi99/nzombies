local mapscript = {}

local tokens = nzItemCarry:CreateCategory("token")
tokens:SetIcon("icon16/coins.png")
tokens:SetDropOnDowned(false)
tokens:SetNotificationSound("ambient/levels/labs/coinslot1.wav")

tokens:SetResetFunction( function(self)
	-- Nothing
end)
tokens:Update()

-- Lets you use PaP (on top of 5000 points)
local paptoken = nzItemCarry:CreateCategory("paptoken")
paptoken:SetIcon("icon16/color_wheel.png")
paptoken:SetDropOnDowned(false)
paptoken:SetResetFunction( function(self)
	-- Nothing
end)
paptoken:SetNotificationSound("ambient/levels/labs/coinslot1.wav")
paptoken:Update()

local maxsouls = 20 -- Per player
local soulspertoken = 5
local maxtokens = 10

local papgame = {
	["models/props_junk/watermelon01.mdl"]={pos=Vector(1172,-163,-351),ang=Angle(-41,-177,-38)},
	["models/props_c17/doll01.mdl"]={pos=Vector(-97,-649,-393),ang=Angle(-24,-99,90)},
	["models/props_junk/gascan001a.mdl"]={pos=Vector(-248,27,-382),ang=Angle(0,-180,0)},
	["models/props_c17/streetsign004e.mdl"]={pos=Vector(611,1235,-386),ang=Angle(27,145,20)},
	["models/props_c17/trappropeller_engine.mdl"]={pos=Vector(-267,1854,-228),ang=Angle(0,180,0)},
	["models/props_junk/garbage_milkcarton001a.mdl"]={pos=Vector(864,1312,-261),ang=Angle(0,-99,0)},
	["models/props_junk/trafficcone001a.mdl"]={pos=Vector(1675,1485,-254),ang=Angle(0,168,0)},
	["models/gibs/hgibs.mdl"]={pos=Vector(1896,614,-226),ang=Angle(-6,47,7)},
	["models/props_junk/plasticbucket001a.mdl"]={pos=Vector(2213,1165,-471),ang=Angle(1,-178,-1)},
	["models/props_c17/clock01.mdl"]={pos=Vector(896,1115,-413),ang=Angle(90,90,180)},
}

local spingamerewards = {
	{model = "models/nzpowerups/x2.mdl", func = function(ply, ent) nzPowerUps:Activate("dp", ply, ent) end},
	{model = "models/nzpowerups/insta.mdl", func = function(ply, ent) nzPowerUps:Activate("insta", ply, ent) end},
	{model = "models/nzpowerups/nuke.mdl", func = function(ply, ent) nzPowerUps:Activate("nuke", ply, ent) end},
	{model = "models/nzpowerups/firesale.mdl", func = function(ply, ent) nzPowerUps:Activate("firesale", ply, ent) end},
	{model = "models/nzpowerups/carpenter.mdl", func = function(ply, ent) nzPowerUps:Activate("carpenter", ply, ent) end},
	{model = "models/nzpowerups/zombieblood.mdl", func = function(ply, ent) nzPowerUps:Activate("zombieblood", ply, ent) end},
	{model = "models/nzpowerups/deathmachine.mdl", func = function(ply, ent) nzPowerUps:Activate("deathmachine", ply, ent) end},
}
local spinshield = {model = "models/props_c17/furnitureradiator001a.mdl", func = function(ply, ent, index)
	ply:GiveCarryItem("shield2")
	table.remove(spingamerewards, index)
end}

local crashgamerewards = {
	{time = 1, pos = Vector(106, 964, -355), reward = 10},
	{time = 1, pos = Vector(100, 958, -355), reward = 20},
	{time = 1, pos = Vector(96, 950, -355), reward = 30},
	{time = 1, pos = Vector(94, 940, -355), reward = 40},
	{time = 1, pos = Vector(96, 930, -355), reward = 50},
	{time = 1, pos = Vector(100, 923, -355), reward = 75},
	{time = 1, pos = Vector(106, 917, -355), reward = 100},
}

local shield1 = nzItemCarry:CreateCategory("shield1")
shield1:SetIcon("spawnicons/models/props_c17/fence01b.png")
shield1:SetText("Press E to pick up part.")
shield1:SetDropOnDowned(false)
shield1:SetShared(false)

shield1:SetResetFunction( function(self)
	-- Resupply to game
	local poss = shieldparts[1]
	local ran = poss[math.random(table.Count(poss))]
	if ran and ran.pos and ran.ang then
		local part = ents.Create("nz_script_prop")
		part:SetModel("models/props_c17/fence01b.mdl")
		part:SetPos(ran.pos)
		part:SetAngles(ran.ang)
		part:Spawn()
		self:RegisterEntity( part )
	end
end)
shield1:Update()

local shield2 = nzItemCarry:CreateCategory("shield2")
shield2:SetIcon("spawnicons/models/props_c17/furnitureradiator001a.png")
shield2:SetText("Press E to pick up part.")
shield2:SetDropOnDowned(false)
shield2:SetShared(false)

shield2:SetResetFunction( function(self)
	-- Resupply to game
	table.insert(spingamerewards, spinshield)
end)
shield2:Update()

local shield3 = nzItemCarry:CreateCategory("shield3")
shield3:SetIcon("spawnicons/models/props_c17/playgroundtick-tack-toe_post01.png")
shield3:SetText("Press E to pick up part.")
shield3:SetDropOnDowned(false)
shield3:SetShared(false)

shield3:SetResetFunction( function(self)
	-- Resupply to game
	local poss = shieldparts[3]
	local ran = poss[math.random(table.Count(poss))]
	if ran and ran.pos and ran.ang then
		local part = ents.Create("nz_script_prop")
		part:SetModel("models/props_c17/playgroundtick-tack-toe_post01.mdl")
		part:SetPos(ran.pos)
		part:SetAngles(ran.ang)
		part:Spawn()
		self:RegisterEntity( part )
	end
end)
shield3:Update()

function mapscript.OnGameBegin()
	local cashreg = ents.Create("nz_script_soulcatcher")
	cashreg:SetModel("models/props_c17/cashregister01a.mdl")
	cashreg:SetPos(Vector(1233, 1390, -430))
	cashreg:SetAngles(Angle(0,-180,0))
	cashreg:Spawn()
	cashreg.PlayerSouls = {}
	
	cashreg:SetReleaseOverride(function(self, z, dmg, dist)
		local ply = dmg:GetAttacker()
		if !IsValid(ply) then return end
		if !self.PlayerSouls[ply] then self.PlayerSouls[ply] = 0 end
		if self.PlayerSouls[ply] >= maxsouls then return end
		
		local e = EffectData()
		e:SetOrigin(z:GetPos() + Vector(0,0,50))
		e:SetEntity(self)
		util.Effect("zombie_soul", e)
		self.PlayerSouls[ply] = self.PlayerSouls[ply] + 1
		self:CollectSoul()
	end)
	cashreg.CollectSoul = function(self) -- Overwrite to not collect souls (handled above)
		self:EmitSound("ambient/levels/labs/coinslot1.wav")
	end
	
	cashreg.OnUsed = function(self, ply)
		if self.PlayerSouls[ply] then
			local amount = tonumber(ply:HasCarryItem("token")) or 0
			local cangive = math.floor(self.PlayerSouls[ply]/soulspertoken)
			
			local togive = math.Clamp(maxtokens - amount, 0, cangive)
			if togive > 0 then
				ply:GiveCarryItem("token", amount + togive)
				self.PlayerSouls[ply] = self.PlayerSouls[ply] - soulspertoken*togive
			else
				ply:ChatPrint("You cannot get any tokens from this.")
			end
		end
	end
	
	local papconsole = ents.Create("nz_script_prop")
	papconsole:SetModel("models/props_c17/consolebox05a.mdl")
	papconsole:SetPos(Vector(1225,877,-419))
	papconsole:SetAngles(Angle(0,0,0))
	papconsole:Spawn()
	
	local topress,papply,order
	local papents = {}
	for k,v in pairs(papgame) do
		local e = ents.Create("nz_script_prop")
		e:SetModel(k)
		e:SetPos(v.pos)
		e:SetAngles(v.ang)
		e:Spawn()
		e.OnUsed = function(self, ply)
			if ply == papply then
				if order[topress] == self then
					topress = topress + 1
				else
					topress = 0
				end
				-- Noise/effect
			end
		end
		table.insert(papents, e)
	end

	papconsole.OnUsed = function(self, ply)
		if IsValid(papply) then
			if papply == ply then
				if order[topress] == self then
					ply:GiveCarryItem("paptoken")
					ply:ChatPrint("You earned a Pack-a-Punch Token!")
				else
					ply:ChatPrint("You failed!")
				end
				papply = nil
				self:SetNWString("NZText", "Press E to start game [5 Tokens]")
			else
				ply:ChatPrint("Another player is currently playing this game.")
			end
		else
			if ply:HasCarryItem("paptoken") then
				ply:ChatPrint("You already have a Pack-a-Punch Token.")
				return
			end
			
			local amount = ply:HasCarryItem("token") or 0
			if amount >= 10 then
				ply:RemoveCarryItem("token") -- Set to 0
				
				-- Start game
				order = {}
				local props = table.Copy(papents)
				for i = 1,3 do
					local index = math.random(#props)
					local e = props[index]
					table.insert(order,e)
					table.remove(props, index)
				end
				
				table.insert(order, self) -- Last is itself
				papply = ply
				ply:GivePowerUp("zombieblood", 60)
				
				topress = 1
				
				local show = ents.Create("nz_script_prop")
				show:SetPos(self:GetPos() + Vector(0,0,20))
				show:SetModel(order[1]:GetModel())
				timer.Simple(1, function() if IsValid(show) then show:SetModel(order[2]:GetModel()) end end)
				timer.Simple(2, function() if IsValid(show) then show:SetModel(order[3]:GetModel()) end end)
				timer.Simple(3, function() if IsValid(show) then show:Remove() end end)
				
				timer.Simple(60, function() if IsValid(self) and papply then
					papply:ChatPrint("Time's up")
					papply = nil
					self:SetNWString("NZText", "Press E to start game [5 Tokens]")
				end end)
				
				self:SetNWString("NZText", "Game in progress. Press E to end.")
			else
				ply:ChatPrint("You need 10 tokens to play this game.")
			end
		end
	end
	papconsole:SetNWString("NZText", "Press E to start game [5 Tokens]")
	
	local pap
	local perks = ents.FindByClass("perk_machine")
	for k,v in pairs(perks) do
		if v:GetPerkID() == "pap" then
			pap = v
			break
		end
	end
	
	if IsValid(pap) then
		pap:SetNWString("NZText", "Press E to buy Pack-a-Punch for [1 PaP-Token] + 5000 points.")
		pap.OnUsed = function(self, ply)
			if !nzElec.Active then return end
			
			if !ply:CanAfford(5000) or !ply:HasCarryItem("paptoken") then
				ply:ChatPrint("You can't afford this.")
				return true
			end
			ply:RemoveCarryItem("paptoken")
		end
	end
	
	local spingame = ents.Create("nz_script_prop")
	spingame:SetPos(Vector(1606, 606, -218))
	spingame:SetAngles(Angle(0,0,0))
	spingame:SetModel("models/props_c17/consolebox05a.mdl")
	spingame.OnUsed = function(self, ply)
		if IsValid(self.PlayingPlayer) then
			if ply == self.PlayingPlayer then
				if !self.gamegoing and ply == self.PlayingPlayer then
					spingamerewards[self.index].func(ply, self.spinner, self.index)
					self.PlayingPlayer = nil
					self:SetNWString("NZText", "Press E to start game [5 Tokens]")
					self.spinner:Remove()
				else
					self.gamegoing = false
					self:SetNWString("NZText", "Press E to take reward.")
					timer.Simple(5, function()
						if IsValid(self) and IsValid(self.spinner) then
							self:OnUsed(self.PlayingPlayer)
						end
					end)
				end
			else
				ply:ChatPrint("Another player is currently playing this game.")
			end
		else			
			local amount = tonumber(ply:HasCarryItem("token")) or 0
			if amount >= 5 then
				local newamount = amount - 5
				if newamount < 1 then
					ply:RemoveCarryItem("token")
				else
					ply:GiveCarryItem("token", newamount)
				end
				
				self.index = 1
				local endtime = CurTime() + 10
				local changedelay = 0.1
				local nextchange = CurTime() + changedelay
				self.gamegoing = true
				local e = ents.Create("nz_script_prop")
				e:SetPos(Vector(1606, 606, -198))
				e:SetMaterial("models/shiny.vtf")
				e:SetColor( Color(255,200,0) )
				e:SetNotSolid(true)
				e:SetModel("models/nzpowerups/x2.mdl")
				e.Think = function(self2)
					local ct = CurTime()
					if self.gamegoing and ct > nextchange then
						if ct > endtime then -- Force end after 10 seconds
							self.gamegoing = false
							self:SetNWString("NZText", "Press E to take reward.")
							timer.Simple(5, function()
								if IsValid(self) and IsValid(self.spinner) then
									self:OnUsed(self.PlayingPlayer)
								end
							end)
						else -- Spin to random reward
							self.index = (self.index + math.random(3))%#spingamerewards + 1
							self2:SetModel(spingamerewards[self.index].model)
							nextchange = ct + changedelay
						end
					end
				end
				e:Spawn()
				
				self.spinner = e
				self.PlayingPlayer = ply
				self:SetNWString("NZText", "Press E to stop the spin.")
			else
				ply:ChatPrint("You need 5 tokens to play this game.")
			end
		end
	end
	spingame:Spawn()
	spingame:SetCollisionGroup(COLLISION_GROUP_DEBRIS_TRIGGER)
	spingame:SetNWString("NZText", "Press E to start game [5 Tokens]")
	
	local crashgame = ents.Create("nz_script_prop")
	crashgame:SetModel("models/nzombies_plates/plate1x1.mdl")
	crashgame:SetPos(Vector(90,940,-355))
	crashgame:SetCollisionGroup(COLLISION_GROUP_DEBRIS_TRIGGER)
	crashgame:SetNoDraw(true)
	crashgame:Spawn()
	crashgame:SetNWString("NZText", "Press to to start game [5 Tokens]")
	crashgame.OnUsed = function(self, ply)
		if IsValid(self.PlayingPlayer) then
			if ply == self.PlayingPlayer then
				if !self.gamegoing and ply == self.PlayingPlayer then
					-- Give reward
					print("Done")
					
					self.PlayingPlayer = nil
					self:SetNWString("NZText", "Press E to start game [5 Tokens]")
					self.spinner:Remove()
				else
					print("Stopped")
					self.gamegoing = false
					self:SetNWString("NZText", "Press E to take reward.")
					timer.Simple(5, function()
						if IsValid(self) and IsValid(self.spinner) then
							self:OnUsed(self.PlayingPlayer)
						end
					end)
				end
			else
				ply:ChatPrint("Another player is currently playing this game.")
			end
		else			
			local amount = tonumber(ply:HasCarryItem("token")) or 0
			if amount >= 5 then
				local newamount = amount - 5
				if newamount < 1 then
					ply:RemoveCarryItem("token")
				else
					ply:GiveCarryItem("token", newamount)
				end
				
				local e = ents.Create("nz_script_prop")
				
				self.index = 0
				local physcontroller = {
					secondstoarrive = 1,
					pos = e:GetPos(),
					ang = Angle(0,0,0),
					maxangular = 0,
					maxangulardamp = 0,
					maxspeed = 1000,
					maxspeeddamp = 1000,
					dampfactor = 0.8,
					teleportdistance = 0,
					deltatime = 0.01
				}
				local self2 = self
				function e:PhysicsSimulate(phys, deltatime)
					print("here")
					local ct = CurTime()
					if ct > nexttarget then
						if self2.index >= #crashgamerewards then
							self2.PlayingPlayer = nil
							self:StopMotionController()
							--self2:Remove()
						else
							self2.index = self2.index + 1
							physcontroller.pos = crashgamerewards[self2.index].pos
							nexttarget = ct + crashgamerewards[self2.index].time
							physcontroller.timetoarrive = crashgamerewards[self2.index].time
						end
					else
						
					end
					physcontroller.deltatime = deltatime
					self2:ComputeShadowControl(physcontroller)
				end
				
				e:SetPos(Vector(112, 968, -355))
				e:SetMaterial("models/shiny.vtf")
				e:SetColor( Color(255,200,0) )
				e:SetNotSolid(true)
				e:SetModel("models/XQM/Rails/gumball_1.mdl")
				e:SetModelScale(0.1)
				
				e:Spawn()
				e:StartMotionController()
				
				self.spinner = e
				self.gamegoing = true
				self.PlayingPlayer = ply
				self:SetNWString("NZText", "Press E to stop the ball.")
			else
				ply:ChatPrint("You need 5 tokens to play this game.")
			end
		end
	end
	
	shield2:Reset()
end

return mapscript