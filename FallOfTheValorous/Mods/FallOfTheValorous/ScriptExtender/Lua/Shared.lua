--ty Bengt
JLFOTV = JLFOTV or {}

JLFOTV.SubclassFlagSet = Ext.Net.CreateChannel(ModuleUUID, "JLFOTV_SubclassFlagSet")

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