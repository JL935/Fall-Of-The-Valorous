Ext.Require("Shared.lua")

---@class SubclassManager
SubclassManager = {}

---@class InspirationManager
InspirationManager = {}

--Finding the noesis object for the Valor Inquisition icon
--ty Focus and Mazzle <3
---------------------------------figure out if KB+M or Controller
---@return UiUIWidget|nil
function SubclassManager:GetLevelUpUI()
    for _, lvlui in ipairs(Ext.UI:GetRoot():Find('ContentRoot').Children) do
        if lvlui.Name == "CharacterLevelUp" then
_P("CharacterLevelUp")
            return lvlui
        end
    end
    for _, lvlui in ipairs(Ext.UI:GetRoot():Find('ContentRoot').Children) do
        if lvlui.Name == "CharacterLevelUp_c" then
_P("CharacterLevelUp_c")
            return lvlui
        end
    end
end

-----------------------------------hide subclass for KB+M

function SubclassManager:GetLevelUpControlKB()
    local ui = self:GetLevelUpUI()
    for i = 1, ui.VisualChildrenCount do
        local vis = ui:VisualChild(i)
        for j = 1, vis.ChildrenCount do
            local visChild = vis:Child(j)
            if visChild.Type == "ContentPresenter" then
_P("Border:ContentPresenter")
                for k = 1, visChild.VisualChildrenCount do
                    local visChildChild = visChild:VisualChild(k)
                    if visChildChild.Name == "levelUpControl" then
_P("levelUpControl")
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
_P("levelUp")
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
_P("Grid:LeftPanels")
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
_P("Grid:gameplayPanel")
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
_P("Subclass Grid")
                for j = 1, child.ChildrenCount do
                    local child2 = child:Child(j)
                    if child2.Type == "StackPanel" then
_P("Subclass StackPanel 1")
                        for k = 1, child2.ChildrenCount do
                            local child3 = child2:Child(k)
                            if child3.Type == "ls.LSScrollViewer" then
_P("ls.LSScrollViewer")
                                for l = 1, child3.ChildrenCount do
                                    local child4 = child3:Child(l)
                                    if child4.Type == "StackPanel" then
_P("Subclass StackPanel 2")
                                        for m = 1, child4.ChildrenCount do
                                            local child5 = child4:Child(m)
                                            if child5.Name == "SelectableSubClassesListBox" then
_P("SelectableSubClassesListBox")
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
_P("ItemsPresenter")
                for j = 1, child.VisualChildrenCount do
                    local child2 = child:VisualChild(j)
                    if child2.Type == "WrapPanel" then
_P("WrapPanel")
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
_P("found subclass")
                return child
            end
        end
    end
end

--[[----------------------------------------------hide subclass for Controllers
function SubclassManager:GetLevelUpControlC()
    local ui = self:GetLevelUpUI()
    for i = 1, ui.VisualChildrenCount do
        local vis = ui:VisualChild(i)
        for j = 1, vis.ChildrenCount do
            local visChild = vis:Child(j)
            if visChild.Type == "ContentPresenter" then
_P("Border:ContentPresenter")
                for k = 1, visChild.VisualChildrenCount do
                    local visChildChild = visChild:VisualChild(k)
                    if visChildChild.Name == "levelUpControl" then
_P("levelUpControl")
                        return visChildChild
                    end
                end
            end
        end
    end
end

function SubclassManager:GetLevelUpGridC()
    local ui = self:GetLevelUpControlC()
    if ui ~= nil then
        for i = 1, ui.VisualChildrenCount do
            local child = ui:VisualChild(i)
            if child.Name == "levelUp" then
_P("levelUp")
                return child
            end
        end
    end
end

function SubclassManager:GetLevelUpLeftPanelsC()
    local ui = self:GetLevelUpGridC()
    if ui ~= nil then
        local nilgrid = ui:Child(3)
        for i = 1, nilgrid.VisualChildrenCount do
            local child = nilgrid:VisualChild(i)
            if child.Name == "leftSidePanels" then
_P("Grid:leftSidePanels")
                return child
            end
        end
    end
end

function SubclassManager:GetLevelUpGameplayPanelsC()
    local ui = self:GetLevelUpLeftPanelsC()
    if ui ~= nil then
        for i = 1, ui.VisualChildrenCount do
            local child = ui:VisualChild(i)
            if child.Name == "gameplayPanel" then
_P("gameplayPanel")
                return child
            end
        end
    end
end

function SubclassManager:GetLevelUpSubclassCarousel()
    local ui = self:GetLevelUpGameplayPanelsC()
    if ui ~= nil then
        for i = 1, ui.VisualChildrenCount do
            local child = ui:VisualChild(i)
            if child.Type == "Control" then
_P("Carousel Control")
                for j = 1, child.VisualChildrenCount do
                    local child2 = child:VisualChild(j)
                    if child2.Type == "DockPanel" then
_P("Carousel DockPanel")
                        for k = 1, child2.VisualChildrenCount do
                            local child3 = child2:VisualChild(k)
                            if child3.Type == "StackPanel" then
_P("Carousel StackPanel")
                                for l = 1, child3.ChildrenCount do
                                    local child4 = child3:Child(l)
                                    if child4.Name == "subclassCarousel" then
_P("subclassCarousel")
                                        return child4
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

function SubclassManager:GetLevelUpDots()
    local ui = self:GetLevelUpSubclassCarousel()
    if ui ~= nil then
        for i = 1, ui.VisualChildrenCount do
            local child = ui:VisualChild(i)
            if child.Type == "StackPanel" then
_P("Dots StackPanel 1")
                for j = i, child.VisualChildrenCount do
                    local child2 = child:VisualChild(j)
                    if child2.Name == "dots" then
_P("dots")
                        return child2
                    end
                end
            end
        end
    end
end

function SubclassManager:GetToControllerSubclassesDots()
    local list = self:GetLevelUpDots()
    if list ~= nil then
        for i = 1, list.VisualChildrenCount do
            local child = list:VisualChild(i)
            if child.Type == "ScrollViewer" then
_P("Dots ScrollViewer")
                for j = 1, child.ChildrenCount do
                    local child2 = child:Child(j)
                    if child2.Type == "ItemsPresenter" then
_P("Dots ItemsPresenter")
                        for k = 1, child2.VisualChildrenCount do
                            local child3 = child2:VisualChild(k)
                            if child3.Type == "StackPanel" then
_P("Dots StackPanel 2")
                                return child3
                            end
                        end
                    end
                end
            end
        end
    end
end

function SubclassManager:GetLevelUpCarouselClipper()
    local ui = self:GetLevelUpSubclassCarousel()
    if ui ~= nil then
        for i = 1, ui.VisualChildrenCount do
            local child = ui:VisualChild(i)
            if child.Type == "StackPanel" then
_P("Carousel StackPanel 2")
                for j = 1, child.ChildrenCount do
                    local child2 = child:Child(j)
                    if child2.Type == "Grid" then
_P("Carousel Grid")
                        for k = 1, child2.VisualChildrenCount do
                            local child3 = child2:VisualChild(k)
                            if child3.Name == "carouselClipper" then
_P("carouselClipper")
                                return child3
                            end
                        end
                    end
                end
            end
        end
    end
end

function SubclassManager:GetLevelUpAnimatedCarousel()
    local ui = self:GetLevelUpCarouselClipper()
    if ui ~= nil then
        for i = 1, ui.VisualChildrenCount do
            local child = ui:VisualChild(i)
            if child.Name == "AnimatedCarousel" then
_P("AnimatedCarousel")
                return child
            end
        end
    end
end

function SubclassManager:GetToControllerSubclasses()
    local list = self:GetLevelUpAnimatedCarousel()
    if list ~= nil then
        for i = 1, list.VisualChildrenCount do
            local child = list:VisualChild(i)
            if child.Type == "ItemsPresenter" then
_P("ItemsPresenter")
                for j = 1, child.VisualChildrenCount do
                    local child2 = child:VisualChild(j)
                    if child2.Name == "itemsPanel" then
_P("itemsPanel")
                        return child2
                    end
                end
            end
        end
    end
end

function SubclassManager:GetLevelUpSubClassIconC(subclass)
    local list = self:GetToControllerSubclasses()
    if list ~= nil then
        for i = 1, list.VisualChildrenCount do
            local child = list:VisualChild(i)
            if child.DataContext.SubclassIDString == subclass then
_P("found subclass")
                return child
            end
        end
    end
end

function SubclassManager:GetLevelUpSubClassIconDot(subclass)
    local list = self:GetToControllerSubclassesDots()
    if list ~= nil then
        for i = 1, list.VisualChildrenCount do
            local child = list:VisualChild(i)
            if child.DataContext.SubclassIDString == subclass then
_P("found subclass dot")
                return child
            end
        end
    end
end


--[[
function SubclassManager:GetValorDockPanel()
    local ui = self:GetLevelUpGameplayPanelsC()
    if ui ~= nil then
        for i = 1, ui.VisualChildrenCount do
            local child = ui:VisualChild(i)
            if child.Type == "Control" then
_P("Carousel Control")
                for j = 1, child.VisualChildrenCount do
                    local child2 = child:VisualChild(j)
                    if child2.Type == "DockPanel" then
_P("Carousel DockPanel")
                        for k = 1, child2.VisualChildrenCount do
                            local child3 = child2:VisualChild(k)
                            if child3.Type == "StackPanel" then
_P("Carousel StackPanel")
                                for l = 1, child3.ChildrenCount do
                                    local child4 = child3:Child(l)
                                    if child4.Name == "subclassCarousel" then
_P("subclassCarousel")
                                        for m = 1, child4.VisualChildrenCount do
                                            local child5 = child4:VisualChild(m)
                                            if child5.Type == "StackPanel" then
_P("carousel stackpanel 2")
                                                for n = 1, child5.ChildrenCount do
                                                    local child6 = child5:Child(n)
                                                    if child6.Type == "Grid" then
_P("carousel grid")
                                                        for o = 1, child6.VisualChildrenCount do
                                                            local child7 = child6:VisualChild(o)
                                                            if child7.Name == "carouselClipper" then
_P("carouselClipper")
                                                                for p = 1, child7.VisualChildrenCount do
                                                                    local child8 = child7:VisualChild(p)
                                                                    if child8.Name == "AnimatedCarousel" then
_P("AnimatedCarousel")
                                                                        for q = 1, child8.VisualChildrenCount do
                                                                            local child9 = child8:VisualChild(q)
                                                                            if child9.Type == "ItemsPresenter" then
_P("ItemsPresenter")
                                                                                for r = 1, child9.VisualChildrenCount do
                                                                                    local child10 = child9:VisualChild(r)
                                                                                    if child10.Name == "itemsPanel" then
_P("itemsPanel")
                                                                                        for s = 1, child10.VisualChildrenCount do
                                                                                            local child11 = child10:VisualChild(s)
                                                                                            if child11.DataContext.SubclassIDString == "ValorInquisitor" then
_P("found subclass")
                                                                                                return child2
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

function SubclassManager:GetValorFlavorText()
    local ui = self:GetValorDockPanel()
    if ui ~= nil then
        for i = 1, ui.VisualChildrenCount do
            local child = ui:VisualChild(i)
            if child.Type == "StackPanel" then
                for j = 1, child.VisualChildrenCount do
                    local child2 = child:VisualChild(j)
                    if child2.Text ~= nil then
                        if child2.Text  == "It takes courage to confront the enemies of your faith. There is no monster too menacing nor mission too daunting for you, who stands tall in battle and commands the respect of the gods." then
_P("found subclass flavor")
                            return child2
                        end
                    end
                end
            end
        end
    end
end

function SubclassManager:GetValorFeaturesHeader()
    local ui = self:GetValorDockPanel()
    if ui ~= nil then
        for i = 1, ui.VisualChildrenCount do
            local child = ui:VisualChild(i)
            if child.Type == "StackPanel" then
                for j = 1, child.VisualChildrenCount do
                    local child2 = child:VisualChild(j)
                    if child2.Name  == "featuresHeader" then
_P("found featuresHeader")
                        return child2
                    end
                end
            end
        end
    end
end

function SubclassManager:GetValorScrollViewer()
    local ui = self:GetValorDockPanel()
    if ui ~= nil then
        for i = 1, ui.VisualChildrenCount do
            local child = ui:VisualChild(i)
            if child.Type == "ScrollViewer" then
                for j = 1, child.VisualChildrenCount do
                    local child2 = child:VisualChild(j)
                    if child2.Type  == "Grid" then
                        for k = 1, child2.VisualChildrenCount do
                            local child3 = child2:VisualChild(k)
                            if child3.Type == "ScrollContentPresenter" then
                                return child3
                            end
                        end
                    end
                end
            end
        end
    end
end

function SubclassManager:HideValorFlavor()
    local item = self:GetValorFlavorText()
    if item ~= nil then
        item.Visibility = "Collapsed"
    end
end

function SubclassManager:HideValorFeatureHeader()
    local item = self:GetValorFeaturesHeader()
    if item ~= nil then
        item.Visibility = "Collapsed"
    end
end

function SubclassManager:HideValorScrollViewer()
    local item = self:GetValorScrollViewer()
    if item ~= nil then
        item.Visibility = "Collapsed"
    end
end

Ext.RegisterConsoleCommand("HideFlavor", function(_)
    SubclassManager:HideValorFlavor()
end)

Ext.RegisterConsoleCommand("HideFH", function(_)
    SubclassManager:HideValorFeatureHeader()
end)

Ext.RegisterConsoleCommand("HideSV", function(_)
    SubclassManager:HideValorScrollViewer()
end)]]
-------------------------------functions for hiding

function SubclassManager:LevelUpHideSubclass(subclass)
    for _, lvlui in ipairs(Ext.UI:GetRoot():Find('ContentRoot').Children) do
        if lvlui.Name == "CharacterLevelUp" then
            local item = self:GetLevelUpSubClassIconKB(subclass)
            if item ~= nil then
_P("keyboard icon hidden")
                item.Visibility = "Collapsed"
            end
        end
    end
   --[[ for _, lvlui in ipairs(Ext.UI:GetRoot():Find('ContentRoot').Children) do
        if lvlui.Name == "CharacterLevelUp_c" then
            local item_c = self:GetLevelUpSubClassIconC(subclass)
            if item_c ~= nil then
_P("controller icon hidden")
                item_c.Visibility = "Collapsed"
            end
            local dot = self:GetLevelUpSubClassIconDot(subclass)
            if dot ~= nil then
_P("dot hidden")
                dot.Visibility = "Collapsed"
            end
        end
    end]]
end

function SubclassManager:LevelUpShowSubclass(subclass)
    local item = self:GetLevelUpSubClassIconKB(subclass)
    if item ~= nil then
        item.Visibility = "Visible"
    end
end

--[[function SubclassManager:LevelUpHideSubclass_C(subclass)
    local item = self:GetLevelUpSubClassIconC(subclass)
    if item ~= nil then
        item.Visibility = "Collapsed"
    end
    local dot = self:GetLevelUpSubClassIconDot(subclass)
    if dot ~= nil then
        dot.Visibility = "Collapsed"
    end
end

function SubclassManager:LevelUpShowSubclass_C(subclass)
    local item = self:GetLevelUpSubClassIconC(subclass)
    if item ~= nil then
        item.Visibility = "Visible"
    end
    local dot = self:GetLevelUpSubClassIconDot(subclass)
    if dot ~= nil then
        dot.Visibility = "Visible"
    end
end]]

--Console commands for testing the above functions
Ext.RegisterConsoleCommand("HideSubclass", function(_, subclass)
    SubclassManager:LevelUpHideSubclass(subclass)
end)

Ext.RegisterConsoleCommand("ShowSubclass", function(_, subclass)
    SubclassManager:LevelUpShowSubclass(subclass)
end)

--[[Ext.RegisterConsoleCommand("HideSubclassC", function(_, subclass)
    SubclassManager:LevelUpHideSubclass_C(subclass)
end)

Ext.RegisterConsoleCommand("ShowSubclassC", function(_, subclass)
    SubclassManager:LevelUpShowSubclass_C(subclass)
end)]]


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