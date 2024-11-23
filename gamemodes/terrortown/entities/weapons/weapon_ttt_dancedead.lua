if SERVER then
    AddCSLuaFile()
end

if CLIENT then
    SWEP.PrintName = "Dance Gun"
    SWEP.Slot = 6

    SWEP.EquipMenuData = {
        type = "item_weapon",
        desc = "Shoot someone to make them dance to a random song, then die."
    }

    SWEP.Icon = "vgui/ttt/icon_dancetilyoudead.png"
end

SWEP.Base = "weapon_tttbase"
SWEP.Kind = WEAPON_EQUIP1
SWEP.InLoadoutFor = nil
SWEP.LimitedStock = true
SWEP.AllowDrop = true
SWEP.IsSilent = false
SWEP.NoSights = false
SWEP.AutoSpawnable = false
SWEP.HoldType = "pistol"
SWEP.Primary.Recoil = 3
SWEP.Primary.Damage = 1
SWEP.Primary.Delay = 1
SWEP.Primary.Cone = 0.01
SWEP.Primary.ClipSize = 1
SWEP.Primary.Automatic = false
SWEP.Primary.DefaultClip = 1
SWEP.Primary.ClipMax = 1
SWEP.Primary.Ammo = "none"
SWEP.AmmoEnt = "none"
SWEP.ViewModel = "models/weapons/v_pist_deagle.mdl"
SWEP.WorldModel = "models/weapons/w_pist_deagle.mdl"

SWEP.CanBuy = {ROLE_TRAITOR}

-- [Sound Name, Shoot Sound Length, Dance Sound Length]
local shootSounds = {
    {"bad", 0.975, 16.731},
    {"doomfart", 0.79, 13.172},
    {"fire", 1.486, 16.015},
    {"fortnitevictoryroyale", 1.939, 6.694},
    {"grandma", 0.803, 11.467},
    {"guardian", 1.102, 10.511},
    {"plant", 2.681, 25.222},
    {"spongebob", 1.401, 12.386}
}

function SWEP:Initialize()
    self:SetHoldType(self.HoldType)
end

function SWEP:PrimaryAttack()
    if CLIENT or not self:CanPrimaryAttack() then return end
    local chosenSounds = shootSounds[math.random(#shootSounds)]
    self:GetOwner():EmitSound("dancedead/shoot/" .. chosenSounds[1] .. ".mp3")
    local cone = self.Primary.Cone
    local num = 1
    local bullet = {}
    bullet.Num = num
    bullet.Src = self:GetOwner():GetShootPos()
    bullet.Dir = self:GetOwner():GetAimVector()
    bullet.Spread = Vector(cone, cone, 0)
    bullet.Tracer = 1
    bullet.Force = 10
    bullet.Damage = 1
    bullet.TracerName = "PhyscannonImpact"

    bullet.Callback = function(att, tr)
        if SERVER or (CLIENT and IsFirstTimePredicted()) then
            local ent = tr.Entity

            if SERVER and ent:IsPlayer() then
                timer.Simple(chosenSounds[2] - 0.1, function()
                    ent:EmitSound("dancedead/dance/" .. chosenSounds[1] .. ".mp3")
                end)

                ent:GodEnable()
                ent:ConCommand("thirdperson_etp 1")

                timer.Create("DanceDeadGunTimer" .. ent:EntIndex(), 1, chosenSounds[3], function()
                    local danceChange = math.random(2)

                    if danceChange == 1 then
                        ent:DoAnimationEvent(ACT_GMOD_GESTURE_TAUNT_ZOMBIE, 1641)
                    else
                        ent:DoAnimationEvent(ACT_GMOD_TAUNT_DANCE, 1642)
                    end

                    if not ent:IsFrozen() then
                        ent:Freeze(true)
                    end
                end)

                ent:Freeze(true)

                timer.Simple(chosenSounds[2] + chosenSounds[3], function()
                    if ent:Alive() then
                        ent:StopSound("dancedead/dance/" .. chosenSounds[1] .. ".mp3")
                        ent:GodDisable()
                        ent:ConCommand("thirdperson_etp 0")
                        ent:Freeze(false)
                        local totalHealth = ent:Health()
                        local inflictWep = ents.Create("weapon_ttt_dancedead")
                        local dmg = DamageInfo()
                        dmg:SetInflictor(inflictWep)
                        dmg:SetAttacker(att)
                        dmg:SetDamageType(DMG_BULLET)
                        dmg:SetDamage(totalHealth * 100)
                        ent:TakeDamageInfo(dmg)

                        timer.Simple(1, function()
                            if ent:IsFrozen() then
                                ent:Freeze(false)
                            end
                        end)
                    end
                end)
            end
        end
    end

    self:GetOwner():FireBullets(bullet)

    if SERVER then
        self:TakePrimaryAmmo(1)

        if self:Clip1() <= 0 then
            self:Remove()
        end
    end
end