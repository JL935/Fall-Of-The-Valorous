--- @alias FunctionRef function

Ext.Require("Shared.lua")

Ext.Vars.RegisterModVariable(ModuleUUID, "SoulWard", {Server = true, Client = true})
Ext.Vars.RegisterModVariable(ModuleUUID, "Xulvorith", {Server = true, Client = true})
----------------------------------------------------------------------------------------------------
---------------------------------------------SOUL WARD----------------------------------------------
----------------------------------------------------------------------------------------------------
---------------credits: idk tbh i think i frankensteined this shit by myself for once---------------
----------------------------------------------------------------------------------------------------
--[[
--Define statuses that change the value of the Soul Ward and by how much
local soulpointstatuses = {
    JL_FOTV_DS_SOULPOINTS = 5,
    JL_FOTV_BOM_F_SOULPOINTS = 2,
    JL_FOTV_BOM_S_SOULPOINTS = 1,
    JL_FOTV_RAVENER_YOUNGSTARTINGWARD = 5,
    JL_FOTV_RAVENER_ADULTSTARTINGWARD = 10,
    JL_FOTV_RAVENER_ANCIENTSTARTINGWARD = 15,
    JL_FOTV_ARZIMYR_REDUCEWARD = -1,
    JL_FOTV_XULVORITH_REDUCEWARD = -5
}

--Define statuses that are used specifically to reduce the value of the Soul Ward
local soulwardreducers = {
    JL_FOTV_ARZIMYR_REDUCEWARD = true,
    JL_FOTV_XULVORITH_REDUCEWARD = true
}

--Function that tracks the points in the Soul Ward
function SoulWardCalculation(object, status)
	local vars = Ext.Vars.GetModVariables(ModuleUUID)
	local soulward = vars.SoulWard or {}
    local soulwardpool = 0
    local objectentity = Ext.Entity.Get(object)
    local soulpointvalue = soulpointstatuses[status] or Osi.GetStatusTurns(object, "JL_FOTV_RAVENER_SOULCONSUMED")
    local soulwardmax = 0

    _P("point value of status is " ..soulpointvalue)

    --Set the maximum capacity of the Soul Ward based on the age category of the ravener
    if Osi.IsTagged(object, "e5c0f3ba-c42f-44e8-aa0a-704d1ddc1537") == 1 then
        soulwardmax = 40
    elseif Osi.IsTagged(object, "45f0b59c-d732-410e-a4e9-8a3912adcc24") == 1 then
        soulwardmax = 30
    elseif Osi.IsTagged(object, "bec81b6c-02f0-44df-ab09-48121ad7e572") == 1 then
        soulwardmax = 20
    elseif Osi.IsTagged(object, "b169a4a0-4867-4e90-a0f8-5e2b8bade0b8") == 1 then
        soulwardmax = 10
    end

    --Initialize the Soul Ward on the ravener
	if soulward[object] == nil then
		soulward[object] = {}
	end

    --Calculate the points in the Soul Ward prior to adding the value of the incoming status
    for _,i in pairs(soulward[object]) do
        soulwardpool = soulwardpool + i.Amount
    end
    _P("pool amount before function runs is " ..soulwardpool)

    --Logic for what should happen based on the new total of the Soul Ward vs the maximum capacity
    if objectentity.BoostsContainer ~= nil then
        if soulwardpool + soulpointvalue < 0 then
            soulwardpool = 0
        elseif soulwardpool + soulpointvalue < soulwardmax then
            table.insert(soulward[object], {
		        Amount = soulpointvalue,
            })
            soulwardpool = soulwardpool + soulpointvalue
        elseif soulwardpool + soulpointvalue >= soulwardmax then
            Osi.ApplyStatus(object, "JL_FOTV_RAVENER_SOULWARD_BLOCK", -1, 0, object)
            table.insert(soulward[object], {
		        Amount = soulwardmax-soulwardpool,
            })
            soulwardpool = soulwardmax
        end
    end

    local soulstatuslevel = math.floor(soulwardpool/5)
    _P("pool amount after function is " ..soulwardpool)
    _P("soul status level is " ..soulstatuslevel)

    --Apply stacks of the Soul Ward status based on how many points are in the Soul Ward
    if soulstatuslevel ~= 0 then
        Osi.RemoveStatus(object, "JL_FOTV_RAVENER_SOULWARD_DR", object)
        Osi.ApplyStatus(object, "JL_FOTV_RAVENER_SOULWARD_DR", soulstatuslevel*6, 0, object)
    elseif soulwardpool < 5 then
        Osi.RemoveStatus(object, "JL_FOTV_RAVENER_SOULWARD_DR", object)
    end

    Osi.RemoveStatus(object, "JL_FOTV_RAVENER_SOULCONSUMED", object)

	vars.SoulWard = soulward
end

--soul ward listeners
Ext.Osiris.RegisterListener("StatusApplied", 4, "after", function(object, status, _, _)
    if Osi.HasActiveStatus(object, "JL_FOTV_RAVENER_SOULWARD_BLOCK") == 0 then
        if soulpointstatuses[status] or status == "JL_FOTV_RAVENER_SOULCONSUMED" then
            SoulWardCalculation(object, status)
        end
    end
    if soulwardreducers[status] and Osi.HasActiveStatus(object, "JL_FOTV_RAVENER_SOULWARD_BLOCK") == 1 then
        Osi.RemoveStatus(object, "JL_FOTV_RAVENER_SOULWARD_BLOCK")
    end
end)
]]
--apply a status at the beginning of combat to any applicable character who can bypass the soul ward (ClassIds table from Shared)
Ext.Osiris.RegisterListener("CombatStarted", 1, "after", function(_)
    local incombat = Osi.DB_Is_InCombat:Get(nil,nil)
    for i = #incombat, 1, -1 do
        local isholy = incombat[i][1]
        local holyentity = Ext.Entity.Get(isholy)
        local classes = holyentity.Classes.Classes
        for _, classEntry in pairs(classes) do
            if ClassIds[classEntry.ClassUUID] then
                Osi.ApplyStatus(holyentity.Uuid.EntityUuid, "JL_FOTV_SOULWARD_CANBYPASS", -1)
            elseif ClassIds[classEntry.SubClassUUID] then
                Osi.ApplyStatus(holyentity.Uuid.EntityUuid, "JL_FOTV_SOULWARD_CANBYPASS", -1)
            end
        end
    end
end)

--this is for if u join combat later
--why did i use the CombatStarted listener when this seems like it would work better
Ext.Osiris.RegisterListener("EnteredCombat", 2, "after", function(object, _)
    local holyentity = Ext.Entity.Get(object)
    local classes = holyentity.Classes.Classes
    for _, classEntry in pairs(classes) do
        if ClassIds[classEntry.ClassUUID] then
            Osi.ApplyStatus(holyentity.Uuid.EntityUuid, "JL_FOTV_SOULWARD_CANBYPASS", -1)
        elseif ClassIds[classEntry.SubClassUUID] then
            Osi.ApplyStatus(holyentity.Uuid.EntityUuid, "JL_FOTV_SOULWARD_CANBYPASS", -1)
        end
    end
end)
----------------------------------------------------------------------------------------------------
---------------------------------------------XULVORITH----------------------------------------------
----------------------------------------------------------------------------------------------------
-----------------------credits: LaughingLeader for the BeforeDealDamage stuff-----------------------
----------------------------------------------------------------------------------------------------
--Track the damage dealt by an entity who is affected by Xulvorith
function TrackXulvorith(source, amount)
    local vars = Ext.Vars.GetModVariables(ModuleUUID)
    local XulvorithTracker = vars.Xulvorith or {}
    local totalxulvorith = 0
    local sourceentity = Ext.Entity.Get(source)

    --Initialize damage tracker for the entity
    if XulvorithTracker[source] == nil then
		XulvorithTracker[source] = {}
	end
    --_P("initialized table")

    --Calculate the total damage tracked on the entity
    for _,i in pairs(XulvorithTracker[source]) do
        totalxulvorith = totalxulvorith + i.Amount
    end
    --_P("total damage tracked before this function = " ..totalxulvorith)

    --Add the new damage amount to the table of tracked values
    if sourceentity.BoostsContainer ~= nil then
        table.insert(XulvorithTracker[source], {
            Amount = amount,
        })
        totalxulvorith = totalxulvorith + amount
    end
    --_D(XulvorithTracker)
    --_P("new total after tracking is " ..totalxulvorith)

    vars.Xulvorith = XulvorithTracker
end

--Function to deal Xulvorith damage
function XulvorithDamage(object, status, causee)
    local vars = Ext.Vars.GetModVariables(ModuleUUID)
    local XulvorithTracker = vars.Xulvorith or {}
    local totalxulvorith = 0
    local guid = Osi.GetUUID(object)

    --Calculate total amount of damage tracked
    for _,i in pairs(XulvorithTracker[guid]) do
        totalxulvorith = totalxulvorith + i.Amount
    end
    --_P("total damage to be dealt = " ..totalxulvorith)

    --Deal full damage or halved damage based on the outcome of the entity's saving throw
    if status == "JL_FOTV_XULVORITH_FAIL" then
        Osi.ApplyDamage(object, totalxulvorith, "Force", causee)
    elseif status == "JL_FOTV_XULVORITH_SUCCESS" then
        Osi.ApplyDamage(object, (totalxulvorith)/2, "Force", causee)
    end

    --Clear the damage tracker
    if XulvorithTracker[guid] ~= nil then
		XulvorithTracker[guid] = nil
	end

    vars.Xulvorith = XulvorithTracker
end

--xulvorith listener
Ext.Osiris.RegisterListener("StatusApplied", 4, "after", function(object, status, causee, _)
    if status == "JL_FOTV_XULVORITH_SUCCESS" or status == "JL_FOTV_XULVORITH_FAIL" then
        XulvorithDamage(object, status, causee)
    end
end)

--makes sure the damage of an incoming attack is >0
---@param hit HitDesc
local function GetTotalDamage(hit)
	if hit.TotalDamageDone > 0 then
		return hit.TotalDamageDone
	end
	if hit.Results.FinalDamage > 0 then
		return hit.Results.FinalDamage
	end
	if hit.Damage.FinalDamage > 0 then
		return hit.Damage.FinalDamage
	end
	return 0
end

--tracks when someone dealing damage is affected by Xulvorith
---@param e EsvLuaBeforeDealDamageEvent
Ext.Events.BeforeDealDamage:Subscribe(function (e)
    local hit = e.Hit
    if GetTotalDamage(hit) > 0 then
        local sourceGuid = hit.Inflicter ~= nil and hit.Inflicter.Uuid.EntityUuid or "NULL_00000000-0000-0000-0000-000000000000"
        if Osi.HasActiveStatus(sourceGuid, "JL_FOTV_XULVORITH") == 1 then
            for _,dlist in pairs(hit.DamageList) do
                TrackXulvorith(sourceGuid, dlist.Amount)
            end
        end
    end
end)
----------------------------------------------------------------------------------------------------
------------------------------------------FEATS OF RENOWN-------------------------------------------
----------------------------------------------------------------------------------------------------
----------------------------credits: Focus for the BackgroundManager <3 ----------------------------
----------------------------------------------------------------------------------------------------
--Define statuses granted when you complete a feat of renown and their corresponding inspiration
local featsofrenown = {
    JL_FOTV_FOR_DTD_TECHNICAL = "0a30d65a-c707-4844-a468-0409fb9338ae",
    JL_FOTV_FOR_SOS_TECHNICAL = "245d0964-87c2-4725-be7c-cdc0752fb111",
    JL_FOTV_FOR_HYH_TECHNICAL = "1febdc4d-65d1-4546-9327-526bacf8ccd1",
    JL_FOTV_FOR_ACT1_ANY_TECHNICAL = "f836e307-7732-4abe-a2b5-f7fe0e940bcb"
}

--hiding feats of renown from the inspiration menu
---@param goal Guid
---@return Guid|nil
function BackgroundManager:GetGoalBackground(goal)
    local data = Ext.StaticData.Get(goal, "BackgroundGoal")
    if data ~= nil then
        return data.BackgroundUuid
    end
end

---@param character EntityHandle
---@param goal Guid
function BackgroundManager:ForceCompleteBackgroundGoal(character, goal)
    local backgroundGuid = self:GetGoalBackground(goal)
    if backgroundGuid ~= nil then
        local charBackground = character.Background
        if charBackground ~= nil then
            if charBackground.Background ~= backgroundGuid then -- swap backgrounds for a few ticks
                local oldBg = charBackground.Background
                charBackground.Background = backgroundGuid
                character:Replicate("Background")
                Ext.Timer.WaitFor(125, function()
                    character.Background.Background = oldBg
                    character:Replicate("Background")
                end)
            end

            Osi.PROC_GLO_Backgrounds_GivePoint(character.Uuid.EntityUuid, goal)
            --Ext.Log.Print(string.format("Completing %s: %s for %s", Ext.StaticData.Get(backgroundGuid, "Background").DisplayName:Get(), Ext.StaticData.Get(goal, "BackgroundGoal").Title:Get(), character.DisplayName.Name:Get()))
        end
    end
end

---@param character EntityHandle
---@param goal Guid
function BackgroundManager:UnsetBackgroundGoalCompleted(character, goal)
    local backgroundGuid = self:GetGoalBackground(goal)
    if backgroundGuid ~= nil then
        local goalsEntity = Ext.Entity.GetAllEntitiesWithComponent("BackgroundGoals")[1]
        local bgGoals = goalsEntity.BackgroundGoals.Goals[backgroundGuid]
        if bgGoals ~= nil then
            local charGuid = Ext.Entity.HandleToUuid(character)
            for i, bgGoal in ipairs(bgGoals) do
                if bgGoal.Goal == goal and bgGoal.Entity == charGuid then
                    if #bgGoals == 1 then
                        goalsEntity.BackgroundGoals.Goals[backgroundGuid] = nil
                    else
                        bgGoals[i] = nil
                    end
                    goalsEntity:Replicate("BackgroundGoals")
                end
            end
        end
    end
end

---@param character EntityHandle
---@param goal Guid
function BackgroundManager:ToggleGoal(character, goal)
    self:ForceCompleteBackgroundGoal(character, goal)
    Ext.Timer.WaitFor(200, function()
        self:UnsetBackgroundGoalCompleted(character, goal)
        self:CleanBackgroundFromUI(character, self:GetGoalBackground(goal))
    end)
end

--listener for feats of renown
Ext.Osiris.RegisterListener("StatusApplied", 4, "after", function(object, status, causee, _)
    local objecthandle = Ext.Entity.Get(object) --[[@as EntityHandle]]
    if featsofrenown[status] then
        BackgroundManager:ToggleGoal(objecthandle, featsofrenown[status])
    end
end)
----------------------------------------------------------------------------------------------------
---------------------------------------FUCKING WITH HEALING-----------------------------------------
----------------------------------------------------------------------------------------------------
----credits: LaughingLeader for the DealDamage function, Focus for the ServerStatusRequest stuff----
----------------------------------------------------------------------------------------------------
--all of this is for a function that replicates the DealDamage functor from stats
---@class DealDamageOptionsParams
---@field Magical boolean?
---@field Nonlethal boolean?
---@field CoinMultiplier integer?
---@field Tooltip Guid?
---@field IgnoreDamageBonus boolean?
---@field IgnoreOnDamage boolean?
---@field ConsumeCoin boolean?
---@field IgnoreImmune boolean?
---@field StoryActionId integer?

---@class DealDamageOptions:DealDamageOptionsParams
local DefaultDealDamageOpts = {
    Magical = false,
    Nonlethal = false,
    CoinMultiplier = 0,
    Tooltip = "",
    IgnoreDamageBonus = false,
    IgnoreOnDamage = false,
    ConsumeCoin = false,
    IgnoreImmune = false,
}

function DefaultDealDamageOpts:ToString(amount, damageType)
    return string.format("DealDamage(%i,%s,%s,%s,%i,%s,%s,%s,%s,%s)", math.floor(amount), damageType,
    self.Magical and "Magical" or "Nonmagical",
    self.Nonlethal and "Nonlethal" or "Lethal",
    math.floor(self.CoinMultiplier),
    self.Tooltip,
    self.IgnoreDamageBonus,
    self.IgnoreOnDamage,
    self.ConsumeCoin,
    self.IgnoreImmune)
end

local _FuncSpellId = "Target_UnyieldingResolve_ScriptedDamage"

---@param target EntityHandle
---@param source EntityHandle
---@param amount integer
---@param damageType DamageType
---@param opts DealDamageOptionsParams?
local function LLDealDamageFunctor(target, amount, damageType, source, opts)
    ---@type DealDamageOptions
    local funcOpts = {}
    setmetatable(funcOpts, {__index = function (t, k)
        if opts ~= nil and opts[k] ~= nil then return opts[k] end
        return DefaultDealDamageOpts[k]
    end})
    local stat = Ext.Stats.Get(_FuncSpellId) --[[@as SpellData]]
    stat:SetRawAttribute("SpellProperties", funcOpts:ToString(amount, damageType))
    Ext.Stats.Sync(_FuncSpellId, false)
    local functor = stat.SpellProperties[1].Functors[1] --[[@as StatsFunctor]]
    local context = Ext.Stats.PrepareFunctorParams("AttackTarget") --[[@as StatsAttackTargetContextData]]
    context.Caster = source
    context.Target = target
    context.Position = target.Transform.Transform.Translate
    context.PropertyContext = functor.PropertyContext
    context.SpellId.OriginatorPrototype = _FuncSpellId
    context.SpellId.Prototype = _FuncSpellId
    context.StoryActionId = 194925220
    Ext.Stats.ExecuteFunctor(functor, context)
end

--checks when healing has been applied
local function ReallyHealy()
    local requests = Ext.System.ServerStatusRequest.AttemptedEvent
    for i=1,#requests do
        local request = requests[i] --[[@as AttemptedEventRequest]]
        if request.Type == "HEAL" then
            local statuses = nil
            local target = request.Owner --[[@as EntityHandle]]
            if target and target.Health then
                local health = target.Health --[[@as HealthComponent]]
                if target.ServerCharacter then
                    statuses = target.ServerCharacter.StatusManager.Statuses
                elseif target.ServerItem then
                    statuses = target.ServerItem.StatusManager.Statuses
                end
                if statuses then
                    for j=1,#statuses do
                        local status = statuses[j]
                        if status ~= nil then
                            if status.StatusHandle == request.Status then
                                ---@cast status EsvStatusHeal
                                ---i actually did most of this on my own are u proud
                                local targetuuid = Ext.Entity.HandleToUuid(target)
                                local targetentity = Ext.Entity.Get(target)
                                --turning incoming healing directly to damage
                                if Osi.HasActiveStatus(targetuuid, "JL_FOTV_SUPERNAL_MALEDICTION") == 1 or Osi.HasActiveStatus(targetuuid, "JL_FOTV_PERIAPT_HEALRANDOMIZER_DAMAGE") == 1 then
                                    LLDealDamageFunctor(targetentity,((status.HealAmount)),"Force",targetentity,{
                                        IgnoreDamageBonus = true,
                                        IgnoreImmune = true,
                                    })
                                    status.HealAmount = 0
                                    Osi.RemoveStatus(targetuuid, "JL_FOTV_PERIAPT_HEALRANDOMIZER_DAMAGE")
                                end
                                --negating incoming healing
                                if Osi.HasActiveStatus(targetuuid, "JL_FOTV_PERIAPT_HEALRANDOMIZER_NEGATE") == 1 then
                                    status.HealAmount = 0
                                    Osi.RemoveStatus(targetuuid, "JL_FOTV_PERIAPT_HEALRANDOMIZER_NEGATE")
                                end
                                --halving incoming healing
                                if Osi.HasActiveStatus(targetuuid, "JL_FOTV_PERIAPT_CURSE") == 1 then
                                    status.HealAmount = math.floor((status.HealAmount)/2)
                                end
                                --dividing incoming healing among all allies benefitting from Litany of Dawn
                                if Osi.HasActiveStatus(targetuuid, "JL_FOTV_LITANY_DUSKDAWN_INSPIRE") == 1 then
                                    local healamt = status.HealAmount
                                    local numallies = 0
                                    local incombat = Osi.DB_Is_InCombat:Get(nil, nil)
                                    local allyheal = {}
                                    for k = #incombat, 1, -1 do
                                        local validally = incombat[k][1]
                                        if Osi.HasActiveStatus(validally, "JL_FOTV_LITANY_DUSKDAWN_ALLY") == 1 or Osi.HasActiveStatus(validally, "JL_FOTV_LITANY_DUSKDAWN_INSPIRE") == 1 then
                                            numallies = numallies + 1
                                            allyheal[validally] = allyheal[validally] or {}
                                        end
                                    end
                                    local newheal = Osi.RealToInteger(healamt/numallies)
                                    for ally, _ in pairs(allyheal) do
                                        local allyentity = Ext.Entity.Get(ally)
                                        FunctorManager:ExecuteFunctorString("RegainHitPoints("..newheal..")", targetentity, allyentity)
                                    end
                                    status.HealAmount = 0
                                end
                            end
                        end
                    end
                end
            end
        end
    end
end

Ext.Events.SessionLoaded:Subscribe(function (e)
    Ext.Entity.OnSystemUpdate("ServerStatusRequest", ReallyHealy)
end)
----------------------------------------------------------------------------------------------------
---------------------------------------------LITANIES-----------------------------------------------
----------------------------------------------------------------------------------------------------
----------------------------credits: basically 100% Focus u are a godsend---------------------------
----------------------------------------------------------------------------------------------------
--i cant really even annotate this cuz idk whats going on
---@class LitanyCast
---@field Attacks {Target:EntityHandle, Damage:integer}[]
---@field Heals {Target:EntityHandle}[]

---@class LitanyManager
---@field Casts table<EntityHandle, LitanyCast>
LitanyManager = {
    LitanySpells = {
        JL_FOTV_Teleportation_LitanyOfBalance = "3d10",
        JL_FOTV_Teleportation_LitanyOfBalance_5 = "4d10",
        JL_FOTV_Teleportation_LitanyOfBalance_6 = "5d10",
        JL_FOTV_Teleportation_LitanyOfBalance_7 = "6d10",
        JL_FOTV_Teleportation_LitanyOfBalance_8 = "7d10",
        JL_FOTV_Teleportation_LitanyOfBalance_9 = "8d10"
    },
    Casts = {},
    HealingTechnical = "JL_FOTV_LITANYOFBALANCE_ALREADYHEALED",
    HealingVFX = "JL_FOTV_LITANYOFBALANCE_HEALVFX",
    HealStat = "JL_FOTV_Projectile_Litany_DuskDawn_Healing"
}

---@param spellId string
---@return boolean
function LitanyManager:IsLitanySpell(spellId)
    return self.LitanySpells[spellId] ~= nil
end

---@param caster EntityHandle
function LitanyManager:CreateLitanyCast(caster)
    self.Casts[caster] = {Attacks = {}, Heals = {}}

    Ext.Timer.WaitFor(2000, function()
        self:CleanupLitanyCast(caster)
    end)

    return self.Casts[caster]
end

function LitanyManager:CleanupLitanyCast(caster)
    self.Casts[caster] = nil
end

---@param caster EntityHandle
---@param target EntityHandle
---@param damage integer
function LitanyManager:RecordDamage(caster, target, damage)
    local group = self.Casts[caster] or self:CreateLitanyCast(caster)
    table.insert(group.Attacks, {Target = target, Damage = damage})
    self:DoHealWithNewAttack(caster, group)
end

---@param caster EntityHandle
---@param target EntityHandle
function LitanyManager:RecordHeal(caster, target)
    local group = self.Casts[caster] or self:CreateLitanyCast(caster)
    table.insert(group.Heals, {Target = target})
    self:DoHealWithNewHeal(caster, group)
end

---@param caster EntityHandle
---@param group LitanyCast
function LitanyManager:DoHealWithNewAttack(caster, group)
    local heal = group.Heals[#group.Attacks]
    if heal ~= nil then
        local attack = group.Attacks[#group.Attacks]
        self:DoHeal(caster, heal.Target, attack.Damage)
    end
end

---@param caster EntityHandle
---@param group LitanyCast
function LitanyManager:DoHealWithNewHeal(caster, group)
    local attack = group.Attacks[#group.Heals]
    if attack ~= nil then
        local heal = group.Heals[#group.Heals]
        self:DoHeal(caster, heal.Target, attack.Damage)
    end
end

---@param source EntityHandle
---@param target EntityHandle
---@param amount integer
function LitanyManager:DoHeal(source, target, amount)
    local statName = self.HealStat
    local stat = Ext.Stats.Get(statName) or Ext.Stats.Create(statName, "SpellData", "Target_Bless")
    local healFunctorString = string.format("RegainHitPoints(%s)", amount)
    stat:SetRawAttribute("SpellProperties", healFunctorString)
    Ext.Stats.Sync(self.HealStat, false)
    for _, spellProperty in ipairs(stat.SpellProperties) do
        for _, functor in ipairs(spellProperty.Functors) do
            local context = Ext.Stats.PrepareFunctorParams("AttackTarget")
            context.Caster = source
            context.Target = target
            context.Position = target.Transform.Transform.Translate
            context.PropertyContext = functor.PropertyContext
            context.SpellId.OriginatorPrototype = statName
            context.SpellId.Prototype = statName
            Ext.Stats.ExecuteFunctor(functor, context)
        end
    end

    Osi.ApplyStatus(target.Uuid.EntityUuid, "JL_FOTV_LITANYOFBALANCE_HEALVFX", 0)
end

---@param e EsvLuaDealtDamageEvent
Ext.Events.DealtDamage:Subscribe(function(e)
    local spell = e.Hit.SpellId -- This is the originator spell even for chains
    local trueSpell = e.SpellId.Prototype -- Has chain ids
    if LitanyManager:IsLitanySpell(spell) then
        if LitanyManager:IsLitanySpell(spell) then
            LitanyManager:RecordDamage(e.Caster, e.Target, e.Result.Attack.TotalDamageDone)
        end
    end
end)

Ext.Osiris.RegisterListener("StatusApplied", 4, "after", function(target, status, caster)
    if status == LitanyManager.HealingTechnical then
        local casterEntity = Ext.Entity.Get(caster) --[[@as EntityHandle]]
        local targetEntity = Ext.Entity.Get(target) --[[@as EntityHandle]]
        if casterEntity ~= nil and targetEntity ~= nil then
            LitanyManager:RecordHeal(casterEntity, targetEntity)
        end
    end
end)

--litany listener
--litaner, perhaps
Ext.Osiris.RegisterListener("StatusApplied", 4, "after", function(object, status, causee, _)
    local objecthandle = Ext.Entity.Get(object) --[[@as EntityHandle]]
    if status == "JL_FOTV_LITANY_DUSKDAWN_ENEMY_SUPERHEALTECH" then
        FunctorManager:ExecuteFunctorString("RegainHitPoints(SELF,foreach(WisdomModifier,1d8))", objecthandle, objecthandle)
    end
end)
----------------------------------------------------------------------------------------------------
-------------------------------------------QUEST STUFF----------------------------------------------
----------------------------------------------------------------------------------------------------
----------------------credits: Bengt for the server/client communication stuff ---------------------
----------------------------------------------------------------------------------------------------
--When in the level up screen, this sends the answer to the Client of "is the global flag set?" for hiding/unhiding Valor Inquisition
JLFOTV.SubclassFlagSet:SetRequestHandler(function(data, user)
    local isSet = Osi.GetFlag("30d714d5-35e8-458c-9a74-31dc9ccc512e", "NULL_00000000-0000-0000-0000-000000000000") == 0
    return { Result = isSet }
end)

--questy listener
Ext.Osiris.RegisterListener("StatusApplied", 4, "after", function(object, status, causee, _)
    if status == "JL_FOTV_TAAROGUS_HEALTHTHRESHOLD_STATUS" and Osi.HasActiveStatus(object, "JL_FOTV_TAAROGUS_MINDCONTROL_1") == 1 and Osi.HasActiveStatus(object, "JL_FOTV_ARZIMYR_RESOLVE") == 0 and Osi.GetFlag("846e807c-134c-4700-8f99-02712bf1be5b", "NULL_00000000-0000-0000-0000-000000000000") == 1 then
        Mods.Mazzle_Lib.BB_Print("Use Word of Resolve on Taarogus to attempt to free him from mind control.", 10)
    end
end)
----------------------------------------------------------------------------------------------------
-----------------------------------------DIVINE DEFIANCE--------------------------------------------
----------------------------------------------------------------------------------------------------
-------credits: Sinbad and nzx for the spell list compiler, nzx for basically everything else ------
----------------------------------------------------------------------------------------------------
local SR_PASSIVE   = "JL_FOTV_Ravener_DivineDefiance_Hidden"
local SRActive = {}
local SRPending = nil

local ABILITY_INDEX = {
    Strength = 2, Dexterity = 3, Constitution = 4, Intelligence = 5, Wisdom = 6, Charisma = 7
}

local DifficultyClasses = {}

local function CacheDifficulties()
    for _, uuid in ipairs(Ext.StaticData.GetAll("DifficultyClass")) do
        local dc = Ext.StaticData.Get(uuid, "DifficultyClass")
        if dc.Name:find("^DC_Legacy_Unsaved") then
            DifficultyClasses[dc.Difficulties[1]] = uuid
        end
    end
end

local function SaveMod(entity, spellcastability)
    local stats = entity.Stats
    if not stats then return 0 end
    return (stats.AbilityModifiers[ABILITY_INDEX[spellcastability] or 5] or 0) + stats.ProficiencyBonus
end

local function SpellDC(entity)
    local stats = entity.Stats
    if not stats then return 10 end
    return 8 + stats.ProficiencyBonus + (stats.AbilityModifiers[ABILITY_INDEX[tostring(stats.SpellCastingAbility)] or 5])
end

--divine defiance listeners
Ext.Osiris.RegisterListener("UsingSpellOnTarget", 6, "after", function(caster, target, spell, _, _, _)
    local spelldata = Ext.Stats.Get(spell)
    --_D(spelldata)

    for property, basespell in pairs(spelldata) do
        if property == "SpellContainerID" and basespell ~= nil and basespell ~= "" then
            spell = basespell
        elseif property == "RootSpellID" and basespell ~= nil and basespell ~= "" then
            spell = basespell
        end
    end

    if not (ValidSpells[spell] and IsDivineCaster(spell, caster)) then return end

    local bossUUID   = target:sub(-36)
    local casterUUID = caster:sub(-36)
    local casterEntity = Ext.Entity.Get(casterUUID)

    local spellcastability = nil

    for _, i in pairs(casterEntity.SpellBook.Spells) do
        if i.Id.OriginatorPrototype == spell then
            spellcastability = tostring(i.SpellCastingAbility)
        end
    end

    local dc = SpellDC(Ext.Entity.Get(bossUUID))
        _P(dc)
    local natural = math.random(1, 20)
        _P(natural)
    local total = natural + SaveMod(casterEntity, spellcastability)
        _P(total)

    if Osi.HasPassive(bossUUID, SR_PASSIVE) ~= 1 then return end

    SRPending = { natural = natural, total = total }
    if total < dc then
        SRActive[bossUUID] = true
    end

    Osi.RequestPassiveRoll(casterUUID, bossUUID, "SavingThrow", spellcastability, DifficultyClasses[dc], 0, "JL_SR")
end)

Ext.Osiris.RegisterListener("UsingSpellAtPosition", 8, "after", function(caster, x, y, z, spell, _, _, _)
    local spelldata = Ext.Stats.Get(spell)
    --_D(spelldata)

    for property, basespell in pairs(spelldata) do
        if property == "SpellContainerID" and basespell ~= nil and basespell ~= "" then
            spell = basespell
        elseif property == "RootSpellID" and basespell ~= nil and basespell ~= "" then
            spell = basespell
        end
    end

    if not (ValidSpells[spell] and IsDivineCaster(spell, caster)) then return end

    local bossUUID = caster:sub(-36)
    local casterUUID = caster:sub(-36)
    local casterEntity = Ext.Entity.Get(casterUUID)

    for _, entity in pairs(Ext.Entity.GetAllEntitiesWithComponent("ServerCharacter")) do
        local char = entity.Uuid.EntityUuid
        local dist = Osi.GetDistanceToPosition(char, x, y, z)
        if dist <= 30 and Osi.HasPassive(char, SR_PASSIVE) == 1 then
            bossUUID = char:sub(-36)
        end
    end

    local spellcastability = nil

    for _, i in pairs(casterEntity.SpellBook.Spells) do
        if i.Id.OriginatorPrototype == spell then
            spellcastability = tostring(i.SpellCastingAbility)
        end
    end

    local dc = SpellDC(Ext.Entity.Get(bossUUID))
        _P(dc)
    local natural = math.random(1, 20)
        _P(natural)
    local total = natural + SaveMod(casterEntity, spellcastability)
        _P(total)

    SRPending = { natural = natural, total = total }

    if total < dc then
        SRActive[bossUUID] = true
    end

    Osi.RequestPassiveRoll(casterUUID, bossUUID, "SavingThrow", spellcastability, DifficultyClasses[dc], 0, "JL_SR")
end)

--to emulate rolling the divine defiance save in the combat log
Ext.Entity.OnChange("RequestedRoll", function(e)
    local rr = e.RequestedRoll
    if not rr or rr.field_1B0 ~= "JL_SR" or not SRPending then return end
    rr.NaturalRoll = SRPending.natural
    rr.Result.NaturalRoll = SRPending.natural
    rr.Result.Total = SRPending.total
    rr.Result.Critical = SRPending.natural == 20 and "CriticalSuccess" or SRPending.natural == 1 and "CriticalFail" or "None"
end)

Ext.Entity.OnDestroy("RequestedRoll", function(e, _, rr)
    if rr and rr.field_1B0 == "JL_SR" then SRPending = nil end
end)

--the part that actually does the thing
Ext.Events.ExecuteFunctor:Subscribe(function(e)
    if e.Params.Type ~= "AttackTarget" then return end
    if not e.Params.Target then return end
    if SRActive[e.Params.Target.Uuid.EntityUuid] then
        Osi.ApplyStatus(e.Params.Target.Uuid.EntityUuid, "JL_FOTV_DIVINEDEFIANCE_DISTRIBUTOR", 6)
        e.Params.Target = nil
    end
end)

Ext.Osiris.RegisterListener("CastedSpell", 5, "after", function(_, _, _, _, _)
    SRActive = {}
end)

Ext.Events.SessionLoaded:Subscribe(CacheDifficulties)

--start the timer to remove divine defiance once applied
Ext.Osiris.RegisterListener("StatusApplied", 4, "after", function(object, status, causee, _)
    if status == "JL_FOTV_DIVINEDEFIANCE_IMMUNE" or status == "JL_FOTV_DIVINEDEFIANCE_IMMUNE_SMALLER" then
        Osi.RealtimeObjectTimerLaunch(object, "DivineDefianceTimerRemove", 1000)
    end
end)

--remove the divine defiance status 1 realtime second after application
Ext.Osiris.RegisterListener("ObjectTimerFinished", 2, "after", function(object, timer)
    if timer == "DivineDefianceTimerRemove" then
        Osi.RemoveStatus(object, "JL_FOTV_DIVINEDEFIANCE_IMMUNE")
        Osi.RemoveStatus(object, "JL_FOTV_DIVINEDEFIANCE_IMMUNE_SMALLER")
    end
end)
----------------------------------------------------------------------------------------------------
------------------------------------------FOCUS MANAGERS--------------------------------------------
----------------------------------------------------------------------------------------------------
-------------------------------------------credits: Focus-------------------------------------------
----------------------------------------------------------------------------------------------------
---@class FunctorManager
FunctorManager = {
    Stat = "JL_FOTV_Projectile_Litany_DuskDawn_Healing",
    ActionId = 194925221
}

---@param functorString string
---@param source EntityHandle
---@param target EntityHandle
---@param context? StatsContextData
function FunctorManager:ExecuteFunctorString(functorString, source, target, context)
    local statName = self.Stat
    local stat = Ext.Stats.Get(statName) or Ext.Stats.Create(statName, "SpellData", "Target_Bless")
    stat:SetRawAttribute("SpellProperties", functorString)
    Ext.Stats.Sync(self.Stat, false)
    for _, spellProperty in ipairs(stat.SpellProperties) do
        for _, functor in ipairs(spellProperty.Functors) do
            if context == nil then
                context = Ext.Stats.PrepareFunctorParams("AttackTarget")
                context.Caster = source
                context.Target = target
                context.Position = target.Transform.Transform.Translate
                context.PropertyContext = functor.PropertyContext
                context.SpellId.OriginatorPrototype = statName
                context.SpellId.Prototype = statName
                context.StoryActionId = self.ActionId
            end
            Ext.Stats.ExecuteFunctor(functor, context)
        end
    end
end
----------------------------------------------------------------------------------------------------
-----------------------------------------ELYSIAN DEFENSE--------------------------------------------
----------------------------------------------------------------------------------------------------
-------credits: actually just me this time woah but also built off what LaughingLeader gave me------
----------------------------------------------------------------------------------------------------
---@type EntityHandle?
local lastHitTarget = nil

---@param e EsvLuaDealDamageEvent
Ext.Events.DealDamage:Subscribe(function (e)
	lastHitTarget = e.Target
end)

---@param e EsvLuaBeforeDealDamageEvent
Ext.Events.BeforeDealDamage:Subscribe(function (e)
    local hit = e.Hit
    if lastHitTarget ~= nil then
        if GetTotalDamage(hit) > 0 then
            local targetGuid = lastHitTarget.Uuid.EntityUuid
            local conditionrollExpression = hit.Damage.ConditionRoll.Expression
            local nullify = 0
            if conditionrollExpression ~= nil then
                for conditionroll,expression in pairs(conditionrollExpression) do
                    if conditionroll == "Params" then
                        for _,params in pairs(expression) do
                            if params == "Divide" then
                            nullify = 1
                            end
                        end
                    end
                end
            end
            if hit.SaveAbility == "Constitution" and Osi.HasPassive(targetGuid, "JL_FOTV_EmpyrealMantle_ElysianDefense") == 1 then
                if nullify == 0 then
                    hit.TotalDamageDone = math.floor((hit.TotalDamageDone)/2)
                    hit.Damage.TotalDamage = math.floor((hit.Damage.TotalDamage)/2)
                    hit.Damage.AdditionalDamage = math.floor((hit.Damage.AdditionalDamage)/2)
                    hit.Damage.FinalDamage = math.floor((hit.Damage.FinalDamage)/2)
                    hit.Damage.SecondaryValue = math.floor((hit.Damage.SecondaryValue)/2)
                    hit.Damage.BaseValue = math.floor((hit.Damage.BaseValue)/2)
                    for _,rolls in pairs(hit.Damage.DamageRolls) do
                        for _,roll in pairs(rolls) do
                            roll.Result.Total = math.floor((roll.Result.Total)/2)
                        end
                    end
                    for _,dlist in pairs(hit.DamageList) do
                        dlist.Amount = math.floor((dlist.Amount)/2)
                    end
                    for _,tdpt in pairs(hit.Damage.TotalDamagePerType) do
                        tdpt = math.floor((tdpt)/2)
                    end
                    for _,fdpt in pairs(hit.Damage.FinalDamagePerType) do
                        fdpt = math.floor((fdpt)/2)
                    end
                elseif nullify == 1 then
                    hit.TotalDamageDone = 0
                    hit.DamageList = {}
                    hit.Damage.TotalDamage = 0
                    hit.Damage.TotalDamagePerType = {}
                    hit.Damage.AdditionalDamage = 0
                    hit.Damage.FinalDamage = 0
                    hit.Damage.FinalDamagePerType = {}
                    hit.Damage.SecondaryValue = 0
                    hit.Damage.BaseValue = 0
                    for _,rolls in pairs(hit.Damage.DamageRolls) do
                        for _,roll in pairs(rolls) do
                            roll.Result.Total = 0
                        end
                    end
                    e.Attack.DamageList = {}
                    e.Attack.TotalDamageDone = 0
                end
            end
        end
    end
end)
----------------------------------------------------------------------------------------------------
----------------------------------------CONSOLE COMMANDS--------------------------------------------
----------------------------------------------------------------------------------------------------
--------------------------------------------credits: me---------------------------------------------
----------------------------------------------------------------------------------------------------
Ext.RegisterConsoleCommand("JLFOTV_LearnAllHolyWords", function(_) --learn all holy words (also summons inquisiboss)
    Osi.SetFlag("a80348bb-7402-4460-a725-1d0bf923c153") --Lulix
    Osi.SetFlag("414c42de-2602-4703-b89d-fa32c1aa0fbd") --Arzimyr
    Osi.SetFlag("5b18c4c1-8839-4593-8457-f5ddf38544bb") --Xulvorith
    Osi.PROC_FOTV_UpdateHolyWords() --Vaelythra + Container + Toggle Passive
end)

Ext.RegisterConsoleCommand("JLFOTV_AllRavenerLore", function(_) --set flags for all ravener lore
    Osi.SetFlag("e6594196-80b1-427f-9bbe-9738530c1d7a") --soul ward
    Osi.SetFlag("1c1928f0-b078-48ae-8562-d305d7573c66") --frightful presence
    Osi.SetFlag("c58bd837-af7b-42e0-8f45-ac3826a4afe1") --malevolence
    Osi.SetFlag("97109720-da6a-4d93-9148-a00e2b44d4ba") --undeath
    Osi.SetFlag("6f5b0194-55b7-4d53-bdba-485b9067ab8b") --forebear
    Osi.SetFlag("10a4efdc-5863-44f0-93a9-3d11fa1d84d3") --qynoth
    Osi.SetFlag("db155e2f-ce1f-4d6c-a100-244bd5367959") --knows all A1 lore
end)

Ext.RegisterConsoleCommand("JLFOTV_UnlockValor", function(_) --unlock valor subclass
    Osi.SetFlag("30d714d5-35e8-458c-9a74-31dc9ccc512e")
end)

Ext.RegisterConsoleCommand("JLFOTV_AllGear", function(_) --add all gear
    Osi.TemplateAddTo("e530a44a-67c8-4906-bfbb-2809103082f5", Osi.GetHostCharacter(), 1, 1) --Oathkeeper's Periapt
    Osi.TemplateAddTo("f2dbca2a-d55f-4a53-a604-c57e3b07bb5a", Osi.GetHostCharacter(), 1, 1) --Empyreal Scion's Mantle
    Osi.TemplateAddTo("adc31816-0459-4809-847d-3574dd80b437", Osi.GetHostCharacter(), 1, 1) --Vindicator's Resplendence (Longsword)
end)

Ext.RegisterConsoleCommand("JLFOTV_TPCrypt", function(_) --teleport to crypt
    Osi.TeleportToPosition(Osi.GetHostCharacter(), -309, 17.5, -263)
end)

Ext.RegisterConsoleCommand("JLFOTV_SpawnVeiz", function(_) --summon veizoadeoth and teleport nearby
    Osi.SetFlag("4d6a8c37-4851-4e6a-b84b-e0f1211c5105")
    Osi.TeleportToPosition(Osi.GetHostCharacter(), 95, 35, 575)
end)

Ext.RegisterConsoleCommand("JLFOTV_TPPeriapt", function(_) --set periapt on stage and teleport close
    Osi.SetFlag("0f5c11bc-ea59-43ba-b343-0ed21dd7ae64")
    Osi.TeleportToPosition(Osi.GetHostCharacter(), -405, 0, 247)
end)

Ext.RegisterConsoleCommand("JLFOTV_TPMantle", function(_) -- teleport close to chestpiece
    Osi.TeleportToPosition(Osi.GetHostCharacter(), 307, 4, -174)
end)