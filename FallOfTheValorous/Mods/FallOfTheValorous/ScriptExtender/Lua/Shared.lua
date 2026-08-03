--ty Bengt
JLFOTV = JLFOTV or {}

JLFOTV.SubclassFlagSet = Ext.Net.CreateChannel(ModuleUUID, "JLFOTV_SubclassFlagSet")
----------------------------------------------------------------------------------------------------
------------------------------------------FEATS OF RENOWN-------------------------------------------
----------------------------------------------------------------------------------------------------
----------------------------credits: Focus for the BackgroundManager <3 ----------------------------
----------------------------------------------------------------------------------------------------
BackgroundManager = {
    Net = Ext.Net.CreateChannel(ModuleUUID, "UpdateBG"),
}

-- Will only totally remove character from background UI if they are not currently of that background.
-- Will scrub character from completed background goals regardless.
---@param character EntityHandle
---@param background Guid
function BackgroundManager:CleanBackgroundFromUI(character, background)
    if Ext.IsServer() then
        self.Net:Broadcast({Character = Ext.Entity.HandleToUuid(character), Background = background})
        return
    end

    local ui = Ext.UI:GetRoot():Find('ContentRoot').Children[1]
    local data = ui ~= nil and ui.DataContext.Data
    if data ~= nil then
        for i = #data.BackgroundGoals, 1, -1 do
            local bgData = data.BackgroundGoals[i]
            if bgData.Guid == background then
                local charIcon = self:GetPlayerCharacterIcon(character)
                if charIcon ~= nil then
                    -- Clean from owners
                    for i2, owner in ipairs(bgData.BackgroundOwners) do
                        if owner.Icon.ImageSource.UriSource == charIcon and character.Background.Background ~= bgData.Guid then
                            bgData.BackgroundOwners[i2] = nil
                            break
                        end
                    end

                    -- Clean completed goals
                    for i3 = #bgData.GoalCategories, 1, -1 do
                        local goalCategory = bgData.GoalCategories[i3]
                        for i4 = #goalCategory.ContainerChildren, 1, -1 do
                            local goal = goalCategory.ContainerChildren[i4]
                            for i5 = #goal.GoalOwners, 1, -1 do
                                local owner = goal.GoalOwners[i5]
                                if owner.Icon.ImageSource.UriSource == charIcon then
                                    goal.GoalOwners[i5] = nil
                                    if #goal.GoalOwners == 0 then
                                        goalCategory.ContainerChildren[i4] = nil
                                    end
                                    break
                                end
                            end
                        end

                        if #goalCategory.ContainerChildren == 0 then
                            bgData.GoalCategories[i3] = nil
                        end
                    end

                    if #bgData.BackgroundOwners == 0 then
                        data.BackgroundGoals[i] = nil
                    end
                end
                break
            end
        end
    end
end
----------------------------------------------------------------------------------------------------
-----------------------------------------DIVINE DEFIANCE--------------------------------------------
----------------------------------------------------------------------------------------------------
-------------------------credits: Sinbad and nzx for the spell list compiler------------------------
----------------------------------------------------------------------------------------------------
--Compile a list of all divine spells
function StringSplit(s, sep, plain)
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

function ExtractSpellsFromPassive(passive_data)
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

ClassIds = {
   ["114e7aee-d1d4-4371-8d90-8a2080592faf"] = true, -- Cleric
   ["b927a22a-d64b-48d6-bc7c-38c5f7f6a061"] = true, --- Death Domain
   ["ebe18794-b5e1-41c4-befa-4b9d6922b0ec"] = true, --- Knowledge Domain
   ["4b5da2f5-b999-4623-8bff-a63df5560fb3"] = true, --- Life Domain
   ["c54d7591-b305-4f22-b2a7-1bf5c4a3470a"] = true, --- Light Domain
   ["6dec76d0-df22-411c-8a78-3d6fb843ae50"] = true, --- Nature Domain
   ["89bacf1b-8f15-4972-ada7-bf59c7c78441"] = true, --- Tempest Domain
   ["f013d01b-3310-43f7-81bf-a51130442b5e"] = true, --- Trickery Domain
   ["b9ccf90e-b35b-4b73-b896-8ed2d32ae8c6"] = true, --- War Domain
   ["ff4d9497-023c-434a-bd14-82fc367e991c"] = true, -- Paladin
   ["1c761ad0-6f5f-409e-ac1d-ddf6f85c1fc4"] = true, --- Oath of Devotion
   ["b36d247e-d39f-4ae9-9476-3ec315c55789"] = true, --- Oath of the Ancients
   ["eaad98ec-026b-429e-aa24-8274dfd1ecb7"] = true, --- Oath of the Crown
   ["3cc3d397-c47d-4966-87ae-88827f73f645"] = true, --- Oath of Vengeance
   ["6fb3831e-45d8-4b30-9714-6fe73988921b"] = true, --- Oathbreaker
   ["96cff02d-92a3-4083-9fc4-16703ca5dc8d"] = true, -- Inquisitor
   ["4dc44aca-29ec-4fe5-8d34-bc58c8d7c269"] = true, --- Tactics Inquisition
   ["040e41b0-e197-4856-a7c3-f7093ae85f0b"] = true, --- Valor Inquisition
   ["81e4c08b-ce20-4c3f-bad4-959966432f1c"] = true, --- Vengeance Inquisition
   ["e115216d-f6f8-4034-bca5-e06cd1e95dfe"] = true, --- Zeal Inquisition
   ["7b9992cd-1fca-471d-bb34-a55a707acee5"] = true, -- Blackguard (xarara)
   ["06b7f7cd-8888-424d-a81d-b82fd7a9b13d"] = true, --- Shadoweaver Blackguard (xarara)
   ["9efc2aa6-8e79-43f1-a02f-b03f6bd20913"] = true, --- Blood Knight Blackguard (xarara)
   ["d98a466a-e801-42cd-b7bc-5f09895dc100"] = true, -- Sword Dancer of Eilistraee (zx10rx)
   ["f38bab5c-927c-4800-ad0e-a12794372858"] = true, --- Sword Dancer (zx10rx)
   ["228bfc22-789a-453e-86ea-62e7af5baf91"] = true, --- Darksong Knight (zx10rx)
   ["3d8f37da-6612-4078-b9e6-5bea5821a9b8"] = true, --- Silver Bladedancer (zx10rx)
   ["1acb74df-8c0e-4e0d-9af8-90f3456cff85"] = true, ---- Divine Soul Sorcerer (IncogneatoBurrito)
   ["9224b4be-5bad-4e99-83c1-0b87f5ee26c5"] = true, ---- Divine Soul Sorcerer (xarara)
   ["faa44aaa-d250-4efe-b270-fa6f24e3cccb"] = true, ---- College of Cantors Bard (Lumaterian)
   ["cfa23c67-2bf3-49ff-a72c-6345843483d1"] = true, ---- Favored Soul Sorcerer (Lumaterian)
   ["0452af7e-7faf-46d5-a60c-46e4b37cc604"] = true, ---- Hierophant Wizard (Lumaterian)
   ["b9cee698-cc8c-400f-b6b5-e8da339816b2"] = true, ---- Justicar Rogue (Lumaterian)
   ["bdeff5b4-a2fd-4c44-b6e4-f75801a066a3"] = true, ---- The Celestial Warlock (Lumaterian)
   ["29823366-652f-485d-8dfd-b24bf1ad571d"] = true, ---- The Undying Light Warlock (Lumaterian)
   ["35b6fd53-6d7a-4226-a518-f409501aafb9"] = true, ---- Crusader Fighter (TheWailingBard)
   ["34cdb230-ced4-470d-a257-34964b8dbe0d"] = true, ---- Divine Hand Rogue (TheWailingBard)
   ["a96273c5-7c78-41c5-b8ac-8a431ff34ae2"] = true, ---- Way of Transcendence Monk (TheWailingBard)
   ["da6716ef-9962-421e-a562-6437275813a4"] = true, ---- Celestial Warlock (chizfreak)
   ["ce3323fd-ddf6-4f73-8367-ff0704f72e30"] = true, ---- Virtuous Paragon (CatDude55)
}

ValidSpells = {}

function GetSpellsByHolyClasses()
   for uuid in pairs(ClassIds) do
      local spell_lists = {}
      local passives = {}

      local desc = Ext.StaticData.Get(uuid, "ClassDescription")
      if desc then
         -- Direct SpellList
         if desc.SpellList then
            local listData = Ext.StaticData.Get(desc.SpellList, "SpellList")
            if listData and listData.Spells then
               for _, spell in pairs(listData.Spells) do
                  ValidSpells[spell] = ValidSpells[spell] or {}
                  ValidSpells[spell][#ValidSpells[spell] + 1] = uuid
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
                  ValidSpells[spell] = ValidSpells[spell] or {}
                  ValidSpells[spell][#ValidSpells[spell] + 1] = uuid
               end
            end
         end

         for passive in pairs(passives) do
            local passive_data = Ext.Stats.Get(passive)
            if passive_data then
               for spell in ExtractSpellsFromPassive(passive_data) do
                  ValidSpells[spell] = ValidSpells[spell] or {}
                  ValidSpells[spell][#ValidSpells[spell] + 1] = uuid
               end
            end
         end
      end
   end

   local count = 0
   for _ in pairs(ValidSpells) do
      count = count + 1
   end

   --_D(ValidSpells)
   _P("Holy spells loaded: " .. count .. " spells")
end

--check if the caster of a spell on the divine list is a divine caster themself
function IsDivineCaster(spell, caster)
    local classes = Ext.Entity.Get(caster).Classes.Classes
    for _, id in ipairs(ValidSpells[spell]) do
        for _, classEntry in pairs(classes) do
            if classEntry.ClassUUID == id or classEntry.SubClassUUID == id then
                return true
            end
        end
    end
end

Ext.Events.SessionLoaded:Subscribe(GetSpellsByHolyClasses)
Ext.Events.ResetCompleted:Subscribe(GetSpellsByHolyClasses)