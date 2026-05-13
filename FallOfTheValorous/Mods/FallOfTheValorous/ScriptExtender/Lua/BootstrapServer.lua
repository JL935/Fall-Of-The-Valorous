--- @alias FunctionRef function

Ext.Require("Shared.lua")

Ext.Vars.RegisterModVariable(ModuleUUID, "SoulWard", {Server = true, Client = true})
Ext.Vars.RegisterModVariable(ModuleUUID, "Xulvorith", {Server = true, Client = true})

--Lonely global variables at the top of the world
Spellcastability = nil

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

--Define statuses granted when you complete a feat of renown and their corresponding inspiration
local featsofrenown = {
    JL_FOTV_FOR_DTD_TECHNICAL = "0a30d65a-c707-4844-a468-0409fb9338ae",
    JL_FOTV_FOR_SOS_TECHNICAL = "245d0964-87c2-4725-be7c-cdc0752fb111",
    JL_FOTV_FOR_HYH_TECHNICAL = "1febdc4d-65d1-4546-9327-526bacf8ccd1"
}

--ty LaughingLeader for all of this DealDamage stuff
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

--the function that deals the delayed damage
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
local function DealDelayedDamage(target, amount, damageType, source, opts)
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
--ty Focus
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
                                --_D(status)
                                ---@cast status EsvStatusHeal
                                local targetuuid = Ext.Entity.HandleToUuid(target)
                                local targetentity = Ext.Entity.Get(target)
                                if Osi.HasActiveStatus(targetuuid, "JL_FOTV_SUPERNAL_MALEDICTION") == 1 or Osi.HasActiveStatus(targetuuid, "JL_FOTV_PERIAPT_HEALRANDOMIZER_DAMAGE") == 1 then
                                    DealDelayedDamage(targetentity,((status.HealAmount)),"Force",targetentity,{
                                        IgnoreDamageBonus = true,
                                        IgnoreImmune = true,
                                    })
                                    status.HealAmount = 0
                                    Osi.RemoveStatus(targetuuid, "JL_FOTV_PERIAPT_HEALRANDOMIZER_DAMAGE")
                                end
                                if Osi.HasActiveStatus(targetuuid, "JL_FOTV_PERIAPT_HEALRANDOMIZER_NEGATE") == 1 then
                                    status.HealAmount = 0
                                    Osi.RemoveStatus(targetuuid, "JL_FOTV_PERIAPT_HEALRANDOMIZER_NEGATE")
                                end
                                if Osi.HasActiveStatus(targetuuid, "JL_FOTV_PERIAPT_CURSE") == 1 then
                                    status.HealAmount = math.floor((status.HealAmount)/2)
                                end
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

--hiding feats of renown from the inspiration menu
--ty Focus
---@param goal Guid
---@return Guid|nil
function BackgroundManager:GetGoalBackground(goal)
    local data = Ext.StaticData.Get(goal, "BackgroundGoal")
    if data ~= nil then
        return data.BackgroundUuid
    end
end

-- Server only
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

-- Server only
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

-- Server only
---@param character EntityHandle
---@param goal Guid
function BackgroundManager:ToggleGoal(character, goal)
    self:ForceCompleteBackgroundGoal(character, goal)
    Ext.Timer.WaitFor(200, function()
        self:UnsetBackgroundGoalCompleted(character, goal)
        self:CleanBackgroundFromUI(character, self:GetGoalBackground(goal))
    end)
end

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
    _P("initialized table")

    --Calculate the total damage tracked on the entity
    for _,i in pairs(XulvorithTracker[source]) do
        totalxulvorith = totalxulvorith + i.Amount
    end
    _P("total damage tracked before this function = " ..totalxulvorith)

    --Add the new damage amount to the table of tracked values
    if sourceentity.BoostsContainer ~= nil then
        table.insert(XulvorithTracker[source], {
            Amount = amount,
        })
        totalxulvorith = totalxulvorith + amount
    end
    _D(XulvorithTracker)
    _P("new total after tracking is " ..totalxulvorith)

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
    _P("total damage to be dealt = " ..totalxulvorith)

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

--dont judge me pls
Ext.Osiris.RegisterListener("StatusApplied", 4, "after", function(object, status, causee, _)
    local objecthandle = Ext.Entity.Get(object) --[[@as EntityHandle]]
    local causeehandle = Ext.Entity.Get(causee) --[[@as EntityHandle]]
    if Osi.HasActiveStatus(object, "JL_FOTV_RAVENER_SOULWARD_BLOCK") == 0 then
        if soulpointstatuses[status] or status == "JL_FOTV_RAVENER_SOULCONSUMED" then
            SoulWardCalculation(object, status)
        end
    end
    if status == "RESURRECTING" and (Osi.GetStatusTurns(object, "JL_FOTV_NEGATIVELEVEL") >= Osi.GetLevel(object)) then
        local nlta = Osi.GetLevel(object) - 1
        Osi.RemoveStatus(object, "JL_FOTV_NEGATIVELEVEL")
        Osi.ApplyStatus(object, "JL_FOTV_NEGATIVELEVEL", nlta*6, 0)
    end
    if status == "JL_FOTV_XULVORITH_SUCCESS" or status == "JL_FOTV_XULVORITH_FAIL" then
        XulvorithDamage(object, status, causee)
    end
    if soulwardreducers[status] and Osi.HasActiveStatus(object, "JL_FOTV_RAVENER_SOULWARD_BLOCK") == 1 then
        Osi.RemoveStatus(object, "JL_FOTV_RAVENER_SOULWARD_BLOCK")
    end
    if status == "JL_FOTV_DIVINEDEFIANCE_LOCATED" then
        --Osi.RequestPassiveRoll(causee, object, "SavingThrow", Spellcastability, "c44bfd7d-84de-4568-9c57-a059b8df5435", 0, "DivineDefianceRoll")
        if Spellcastability == "Intelligence" then
            FunctorManager:ExecuteFunctorString("ApplyStatus(JL_FOTV_DIVINEDEFIANCE_CASTERSAVE_INT,100,1)", objecthandle, causeehandle)
        elseif Spellcastability == "Wisdom" then
            FunctorManager:ExecuteFunctorString("ApplyStatus(JL_FOTV_DIVINEDEFIANCE_CASTERSAVE_WIS,100,1)", objecthandle, causeehandle)
        elseif Spellcastability == "Charisma" then
            FunctorManager:ExecuteFunctorString("ApplyStatus(JL_FOTV_DIVINEDEFIANCE_CASTERSAVE_CHA,100,1)", objecthandle, causeehandle)
        end
    end
    if status == "JL_FOTV_DIVINEDEFIANCE_IMMUNE" or status == "JL_FOTV_DIVINEDEFIANCE_IMMUNE_SMALLER" then
        Osi.RealtimeObjectTimerLaunch(object, "DivineDefianceTimerRemove", 1000)
    end
    if featsofrenown[status] then
        BackgroundManager:ToggleGoal(objecthandle, featsofrenown[status])
    end
    if status == "JL_FOTV_LITANY_DUSKDAWN_ENEMY_SUPERHEALTECH" then
        FunctorManager:ExecuteFunctorString("RegainHitPoints(SELF,foreach(WisdomModifier,1d8))", objecthandle, objecthandle)
    end
    if status == "JL_FOTV_TAAROGUS_HEALTHTHRESHOLD_STATUS" and Osi.HasActiveStatus(object, "JL_FOTV_TAAROGUS_MINDCONTROL_1") == 1 and Osi.HasActiveStatus(object, "JL_FOTV_ARZIMYR_RESOLVE") == 0 and Osi.GetFlag("846e807c-134c-4700-8f99-02712bf1be5b", "NULL_00000000-0000-0000-0000-000000000000") == 1 then
        Mods.Mazzle_Lib.BB_Print("Use Word of Resolve on Taarogus to attempt to free him from mind control.", 10)
    end
end)

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

---@param e EsvLuaBeforeDealDamageEvent
Ext.Events.BeforeDealDamage:Subscribe(function (e)
    local hit = e.Hit
    --_D(e)
    if GetTotalDamage(hit) > 0 then
        local sourceGuid = hit.Inflicter ~= nil and hit.Inflicter.Uuid.EntityUuid or "NULL_00000000-0000-0000-0000-000000000000"
        if Osi.HasActiveStatus(sourceGuid, "JL_FOTV_XULVORITH") == 1 then
            for _,dlist in pairs(hit.DamageList) do
                --_P("hewwo")
                TrackXulvorith(sourceGuid, dlist.Amount)
            end
        end
    end
end)

--When in the level up screen, this sends the answer to the Client of "is the global flag set?" for hiding/unhiding Valor Inquisition
--ty Bengt
JLFOTV.SubclassFlagSet:SetRequestHandler(function(data, user)
    local isSet = Osi.GetFlag("30d714d5-35e8-458c-9a74-31dc9ccc512e", "NULL_00000000-0000-0000-0000-000000000000") == 0
    return { Result = isSet }
end)

--Compile a list of all divine spells
--ty Nzx and Sinbad
local function StringSplit(s, sep, plain)
   local start = 1
   local done = false
   local function pass(i, j, ...)
      if i then
         local seg = s:sub(start, i - 1)
         start = j + 1
         return seg, ...
      else
         done = true
         return s:sub(start)
      end
   end
   return function()
      if done then
         return
      end
      if sep == '' then
         done = true
         return s
      end
      return pass(s:find(sep, start, plain))
   end
end

local function ExtractSpellsFromPassive(passive_data)
   local co = coroutine.create(
   function()
      for str in StringSplit(passive_data.Boosts, ";", true) do
         local unlocks_spell = str:match("UnlockSpell%(([^,%)]+)")
         if unlocks_spell then
            coroutine.yield(unlocks_spell)
         end
      end
   end
   )
   return function()
      local ok, spell = coroutine.resume(co)
      return spell
   end
end

local classIds = {
   "114e7aee-d1d4-4371-8d90-8a2080592faf", -- Cleric
   "b927a22a-d64b-48d6-bc7c-38c5f7f6a061", --- Death Domain
   "ebe18794-b5e1-41c4-befa-4b9d6922b0ec", --- Knowledge Domain
   "4b5da2f5-b999-4623-8bff-a63df5560fb3", --- Life Domain
   "c54d7591-b305-4f22-b2a7-1bf5c4a3470a", --- Light Domain
   "6dec76d0-df22-411c-8a78-3d6fb843ae50", --- Nature Domain
   "89bacf1b-8f15-4972-ada7-bf59c7c78441", --- Tempest Domain
   "f013d01b-3310-43f7-81bf-a51130442b5e", --- Trickery Domain
   "b9ccf90e-b35b-4b73-b896-8ed2d32ae8c6", --- War Domain
   "ff4d9497-023c-434a-bd14-82fc367e991c", -- Paladin
   "1c761ad0-6f5f-409e-ac1d-ddf6f85c1fc4", --- Oath of Devotion
   "b36d247e-d39f-4ae9-9476-3ec315c55789", --- Oath of the Ancients
   "eaad98ec-026b-429e-aa24-8274dfd1ecb7", --- Oath of the Crown
   "3cc3d397-c47d-4966-87ae-88827f73f645", --- Oath of Vengeance
   "6fb3831e-45d8-4b30-9714-6fe73988921b", --- Oathbreaker
   "96cff02d-92a3-4083-9fc4-16703ca5dc8d", -- Inquisitor
   "4dc44aca-29ec-4fe5-8d34-bc58c8d7c269", --- Tactics Inquisition
   "040e41b0-e197-4856-a7c3-f7093ae85f0b", --- Valor Inquisition
   "81e4c08b-ce20-4c3f-bad4-959966432f1c", --- Vengeance Inquisition
   "e115216d-f6f8-4034-bca5-e06cd1e95dfe", --- Zeal Inquisition
}

local validSpells = {}

local function GetSpellsByHolyClasses()
   for _, uuid in ipairs(classIds) do
      local spell_lists = {}
      local passives = {}
      
      local desc = Ext.StaticData.Get(uuid, "ClassDescription")
      if desc then
         -- Direct SpellList
         if desc.SpellList then
            local listData = Ext.StaticData.Get(desc.SpellList, "SpellList")
            if listData and listData.Spells then
               for _, spell in pairs(listData.Spells) do
                  validSpells[spell] = validSpells[spell] or {}
                  validSpells[spell][#validSpells[spell] + 1] = uuid
               end
            end
         end
         
         -- Progression spells
         local prog_table_uuid = desc.ProgressionTableUUID
         for _, prog_uuid in pairs(Ext.StaticData.GetAll("Progression")) do
            local pd = Ext.StaticData.Get(prog_uuid, "Progression")
            if pd.TableUUID == prog_table_uuid then
               for _, this_select in pairs(pd.AddSpells) do
                  spell_lists[this_select.SpellUUID] = true
               end
               for _, this_select in pairs(pd.SelectSpells) do
                  spell_lists[this_select.SpellUUID] = true
               end
               local passives_added = pd.PassivesAdded or ""
               for passive in StringSplit(passives_added, ";", true) do
                  passives[passive] = true
               end
               for _, this_select in pairs(pd.SelectPassives) do
                  local passive_list = Ext.StaticData.Get(this_select.UUID, "PassiveList")
                  if passive_list then
                     for _, passive in pairs(passive_list.Passives) do
                        passives[passive] = true
                     end
                  end
               end
            end
         end
         
         for spell_list_uuid in pairs(spell_lists) do
            local spell_list = Ext.StaticData.Get(spell_list_uuid, "SpellList")
            if spell_list then
               for _, spell in pairs(spell_list.Spells) do
                  validSpells[spell] = validSpells[spell] or {}
                  validSpells[spell][#validSpells[spell] + 1] = uuid
               end
            end
         end
         
         for passive in pairs(passives) do
            local passive_data = Ext.Stats.Get(passive)
            if passive_data then
               for spell in ExtractSpellsFromPassive(passive_data) do
                  validSpells[spell] = validSpells[spell] or {}
                  validSpells[spell][#validSpells[spell] + 1] = uuid
               end
            end
         end
      end
   end

   local count = 0
   for _ in pairs(validSpells) do
      count = count + 1
   end

   --_D(validSpells)
   _P("Holy spells loaded: " .. count .. " spells")
end

local function isDivineCaster(spell, caster)
    local classes = Ext.Entity.Get(caster).Classes.Classes
    for _, id in ipairs(validSpells[spell]) do
        for _, classEntry in pairs(classes) do
            if classEntry.ClassUUID == id then
                return true
            -- i actually wrote these next 2 lines myself are you proud of me
            elseif classEntry.SubClassUUID == id then
                return true
            end
        end
    end
end

Ext.Events.SessionLoaded:Subscribe(GetSpellsByHolyClasses)
Ext.Events.ResetCompleted:Subscribe(GetSpellsByHolyClasses)

Ext.Osiris.RegisterListener("UsingSpell", 5, "after", function(caster, spell, _, _, _)
    --i actually did these next few lines by myself too mostly
    --u can tell because the code is ass
    --ty Sinbad for pointing me in the right direction :gladge:
    local spelldata = Ext.Stats.Get(spell)

    for property, basespell in pairs(spelldata) do
        if property == "SpellContainerID" and basespell ~= nil and basespell ~= "" then
            spell = basespell
        elseif property == "RootSpellID" and basespell ~= nil and basespell ~= "" then
            spell = basespell
        end
    end

    --when casting a divine spell, apply a status to self that will mark applicable targets for the Divine Defiance saving throw
    if validSpells[spell] and isDivineCaster(spell, caster) then
        local casterhandle = Ext.Entity.UuidToHandle(caster)
        for _, i in pairs(casterhandle.SpellBook.Spells) do
                if i.Id.OriginatorPrototype == spell then
                    Spellcastability = tostring(i.SpellCastingAbility)
                end
            end
        Osi.ApplyStatus(caster, "JL_FOTV_DIVINEDEFIANCE_LOCATOR", 6)
    end

end)

--divine defiance roll fails = target is immune to the incoming spell
--[[Ext.Osiris.RegisterListener("RollResult", 6, "after", function(eventName, _, rollSubject, resultType, _, _)
    if eventName == "DivineDefianceRoll" and resultType == 0 then
        Osi.ApplyStatus(rollSubject, "JL_FOTV_DIVINEDEFIANCE_IMMUNE", 6)
        Osi.RealtimeObjectTimerLaunch(rollSubject, "DivineDefianceTimerRemove", 1000)
        Spellcastability = nil
    end
end)]]

--remove the divine defiance status 1 realtime second after application
Ext.Osiris.RegisterListener("ObjectTimerFinished", 2, "after", function(object, timer)
    if timer == "DivineDefianceTimerRemove" then
        Osi.RemoveStatus(object, "JL_FOTV_DIVINEDEFIANCE_IMMUNE")
        Osi.RemoveStatus(object, "JL_FOTV_DIVINEDEFIANCE_IMMUNE_SMALLER")
    end
end)






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

Ext.RegisterConsoleCommand("functor", function(_, functorString, source, target)
    source = Ext.Entity.Get(source or Osi.GetHostCharacter())
    target = Ext.Entity.Get(target or Osi.GetHostCharacter())
    FunctorManager:ExecuteFunctorString(functorString, source, target)
end)











--Focus you are a godsend

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

Ext.RegisterConsoleCommand("FCTEST_litany", function()
    local char = Osi.GetHostCharacter()
    Osi.AddBoosts(char, [[UnlockSpell(JL_FOTV_Teleportation_LitanyOfBalance, AddChildren,, Charisma)]], "", char)
end)