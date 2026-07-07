Ext.Require("Shared.lua")

---@class SubclassManager
SubclassManager = {}

---@class InspirationManager
InspirationManager = {}
----------------------------------------------------------------------------------------------------
------------------------------------------HIDING SUBCLASS-------------------------------------------
----------------------------------------------------------------------------------------------------
-----------------------------credits: Focus and Mazzle for Noesis help -----------------------------
----------------------------------------------------------------------------------------------------
--Finding the noesis object for the Valor Inquisition icon
---@return UiUIWidget|nil
function SubclassManager:GetLevelUpUI()
    for _, lvlui in ipairs(Ext.UI:GetRoot():Find('ContentRoot').Children) do
        if lvlui.Name == "CharacterLevelUp" then
--_P("CharacterLevelUp")
            return lvlui
        end
    end
end

function SubclassManager:GetLevelUpControlKB()
    local ui = self:GetLevelUpUI()
    for i = 1, ui.VisualChildrenCount do
        local vis = ui:VisualChild(i)
        for j = 1, vis.ChildrenCount do
            local visChild = vis:Child(j)
            if visChild.Type == "ContentPresenter" then
--_P("Border:ContentPresenter")
                for k = 1, visChild.VisualChildrenCount do
                    local visChildChild = visChild:VisualChild(k)
                    if visChildChild.Name == "levelUpControl" then
--_P("levelUpControl")
                        return visChildChild
                    end
                end
            end
        end
    end
end

function SubclassManager:GetLevelUpGridKB()
    local ui = self:GetLevelUpControlKB()
    if ui ~= nil then
        for i = 1, ui.VisualChildrenCount do
            local child = ui:VisualChild(i)
            if child.Name == "levelUp" then
--_P("levelUp")
                return child
            end
        end
    end
end

function SubclassManager:GetLevelUpLeftPanelsKB()
    local ui = self:GetLevelUpGridKB()
    if ui ~= nil then
        local nilgrid = ui:Child(3)
        for i = 1, nilgrid.ChildrenCount do
            local child = nilgrid:Child(i)
            if child.Name == "LeftPanels" then
--_P("Grid:LeftPanels")
                return child
            end
        end
    end
end

function SubclassManager:GetLevelUpGameplayPanelsKB()
    local ui = self:GetLevelUpLeftPanelsKB()
    if ui ~= nil then
        for i = 1, ui.ChildrenCount do
            local child = ui:Child(i)
            if child.Type == "Grid" then
                for j = 1, child.ChildrenCount do
                    local child2 = child:Child(j)
                    if child2.Name == "gameplayPanel" then
--_P("Grid:gameplayPanel")
                        return child2
                    end
                end
            end
        end
    end
end

function SubclassManager:GetLevelUpSelectableSubclassesKB()
    local ui = self:GetLevelUpGameplayPanelsKB()
    if ui ~= nil then
        for i = 1, ui.VisualChildrenCount do
            local child = ui:VisualChild(i)
            if child.Type == "Grid" then
--_P("Subclass Grid")
                for j = 1, child.ChildrenCount do
                    local child2 = child:Child(j)
                    if child2.Type == "StackPanel" then
--_P("Subclass StackPanel 1")
                        for k = 1, child2.ChildrenCount do
                            local child3 = child2:Child(k)
                            if child3.Type == "ls.LSScrollViewer" then
--_P("ls.LSScrollViewer")
                                for l = 1, child3.ChildrenCount do
                                    local child4 = child3:Child(l)
                                    if child4.Type == "StackPanel" then
--_P("Subclass StackPanel 2")
                                        for m = 1, child4.ChildrenCount do
                                            local child5 = child4:Child(m)
                                            if child5.Name == "SelectableSubClassesListBox" then
--_P("SelectableSubClassesListBox")
                                                return child5
                                            end
                                        end
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end
    end
end

function SubclassManager:GetLevelUpSubclassesListKB()
    local list = self:GetLevelUpSelectableSubclassesKB()
    if list ~= nil then
        for i = 1, list.VisualChildrenCount do
            local child = list:VisualChild(i)
            if child.Type == "ItemsPresenter" then
--_P("ItemsPresenter")
                for j = 1, child.VisualChildrenCount do
                    local child2 = child:VisualChild(j)
                    if child2.Type == "WrapPanel" then
--_P("WrapPanel")
                        return child2
                    end
                end
            end
        end
    end
end

function SubclassManager:GetLevelUpSubClassIconKB(subclass)
    local list = self:GetLevelUpSubclassesListKB()
    if list ~= nil then
        for i = 1, list.VisualChildrenCount do
            local child = list:VisualChild(i)
            if child.DataContext.SubclassIDString == subclass then
--_P("found subclass")
                return child
            end
        end
    end
end

-------------------------------functions for hiding

function SubclassManager:LevelUpHideSubclass(subclass)
    for _, lvlui in ipairs(Ext.UI:GetRoot():Find('ContentRoot').Children) do
        if lvlui.Name == "CharacterLevelUp" then
            local item = self:GetLevelUpSubClassIconKB(subclass)
            if item ~= nil then
--_P("keyboard icon hidden")
                item.Visibility = "Collapsed"
            end
        end
    end
end

function SubclassManager:LevelUpShowSubclass(subclass)
    local item = self:GetLevelUpSubClassIconKB(subclass)
    if item ~= nil then
        item.Visibility = "Visible"
    end
end

--Console commands for testing the above functions
Ext.RegisterConsoleCommand("HideSubclass", function(_, subclass)
    SubclassManager:LevelUpHideSubclass(subclass)
end)

Ext.RegisterConsoleCommand("ShowSubclass", function(_, subclass)
    SubclassManager:LevelUpShowSubclass(subclass)
end)

local ticksub

--Run the function to hide the Valor Inquisition icon when you enter level up, if the global flag isn't set
---@diagnostic disable: param-type-mismatch
Ext.Entity.OnCreate("ClientCCLevelUpDefinition", function()
    --local LastCheck = 0
    ticksub = Ext.Events.Tick:Subscribe(function()
        JLFOTV.SubclassFlagSet:RequestToServer({}, function(response)
            if response.Result then
                SubclassManager:LevelUpHideSubclass("ValorInquisitor")
            end
        end)
    end)
end)

Ext.Entity.OnDestroy("ClientCCLevelUpDefinition", function()
    Ext.Events.Tick:Unsubscribe(ticksub)
end)
----------------------------------------------------------------------------------------------------
------------------------------------------FEATS OF RENOWN-------------------------------------------
----------------------------------------------------------------------------------------------------
----------------------------credits: Focus for the BackgroundManager <3 ----------------------------
----------------------------------------------------------------------------------------------------
--hiding feats of renown from the inspiration menu
--ty Focus
-- Client only
---@param character EntityHandle
---@return string|nil
function BackgroundManager:GetPlayerCharacterIcon(character)
    local ui = Ext.UI:GetRoot():Find('ContentRoot').Children[1]
    local data = ui ~= nil and ui.DataContext.Data
    if data ~= nil then
        local charGuid = Ext.Entity.HandleToUuid(character)
        for _, char in ipairs(data.PartyCharacters) do
            if char.EntityUUID == charGuid then
                return char.Icon.ImageSource.UriSource
            end
        end
    end
end

if Ext.IsClient() then
    BackgroundManager.Net:SetHandler(function(data)
        local charEntity = Ext.Entity.Get(data.Character)
        if charEntity ~= nil then
            BackgroundManager:CleanBackgroundFromUI(charEntity, data.Background)
        end
    end)
end