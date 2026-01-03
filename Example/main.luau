---@import "Utils/ScriptLoader/init.luau"
------------- ScriptLoader Setup -------------
-- Fallback pattern: HTTP first (standard executors) -> local file (MaouHub)
local function loadScriptLoader()
    -- Method 1: Local file (for MaouHub)
    local success, result = pcall(function()
        return loadstring(readfile("Utils/ScriptLoader/init.luau"))()
    end)

    if success and result then
        warn("[MemSea] Loaded ScriptLoader via HTTP")
        return result
    end

    -- Method 2: HTTP (for standard executors)
    success, result = pcall(function()
        return loadstring(game:HttpGet(
                              "https://raw.githubusercontent.com/MaouStan/Roblox/refs/heads/master/Utils/ScriptLoader/init.luau?token=GHSAT0AAAAAADSBLWC3QUSGJFBQIHXQ45QQ2KXQ3OQ"))()
    end)

    if success and result then
        warn("[MemSea] Loaded ScriptLoader via local file (MaouHub)")
        return result
    end

    return nil
end

local GG = loadScriptLoader()

if not GG then
    GG.selff:Kick("Failed to load ScriptLoader");
    return
end

------------- State Management -------------
if not GG.State then GG.State = {} end
if not GG.State.MemSea then
    GG.State.MemSea = {
        List = {
            Tools = {},
            Quests = {
                Enemies = {},
                Bosses = {},
                Raids = {},
                Special = {},
                QuestData = {}
            },
            TpMethods = {"Above", "Below", "Behind", "Bring"}
        },
        Functions = {
            Combat = {},
            Quest = {},
            Boss = {},
            Raid = {},
            Teleport = {},
            Enemies = {},
            Tools = {},
            Farming = {},
            Misc = {}
        },
        Toggles = {
            AutoSkills = false,
            AutoQuest = false,
            AutoLevel = false,
            AutoFarm = false,
            AutoBring = false,
            AutoSpecialQuest = false,
            AutoRaid = false,
        },
        Slides = {Distance = 8},
        CurrentTargetSelected = nil,  -- Selected target name (from dropdown)
        CurrentTargetInstance = nil,  -- Actual enemy Instance (from W)
        CurrentSpecialQuest = nil,
        CurrentRaid = nil,
        CurrentMob = nil,  -- Current mob Instance (for stabilization)
        CurrentTool = nil,
        CurrentTpMethod = nil,
        BroughtMobs = {}  -- Track brought mobs with their BodyGyro/BodyVelocity
    }
end
local State = GG.State.MemSea or {}

------------- On Game Load - Team Selection -------------

-- Configuration: Select team (Floppa or Cheems)
local AUTO_SELECT_TEAM = "Floppa"

-- Services needed for team selection (from decompiled LoadingGui.lua)
local StarterGui = game:GetService("StarterGui")
local UserInputService = game:GetService("UserInputService")
local GuiService = game:GetService("GuiService")

-- If player is Neutral, execute team selection logic
repeat
    task.wait(1)
    if GG.selff.Neutral then
        -- Get remotes (exact logic from decompiled game script)
        local OtherEvent = GG.R:WaitForChild("OtherEvent", 10)
        local GuiEvent = OtherEvent:WaitForChild("GuiEvents", 5):WaitForChild("GuiEvent", 5)
        local TeamChoose = OtherEvent:WaitForChild("MainEvents", 5):WaitForChild("TeamChoose", 5)

        -- Step 1: Close menu via GuiEvent
        pcall(function()
            GuiEvent:Fire({
                ["MenuName"] = "Menu",
                ["Action"] = "Close"
            })
        end)

        -- Step 2: Fire TeamChoose remote
        pcall(function()
            TeamChoose:FireServer(AUTO_SELECT_TEAM)
        end)

        -- Step 3: Enable CoreGui (Health, Backpack)
        StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Health, true)
        StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, true)

        -- Step 4: Wait 1 second (exact timing from decompiled)
        local waitStart = tick()
        repeat
            task.wait(0.1)
        until tick() - waitStart >= 1

        -- Step 5: Clear gamepad selection
        if UserInputService.GamepadEnabled then
            GuiService.SelectedObject = nil
        end

        -- Step 6: Disable LoadingGui
        local loadingGui = GG.selff.PlayerGui:FindFirstChild("LoadingGui")
        if loadingGui then
            loadingGui.Enabled = false
        end

        -- Step 7: Reset camera
        GG.W.CurrentCamera.CameraType = Enum.CameraType.Custom
        if GG.selff.Character and GG.selff.Character:FindFirstChild("Humanoid") then
            GG.W.CurrentCamera.CameraSubject = GG.selff.Character:FindFirstChild("Humanoid")
        end
    end
until not GG.selff.Neutral

------------------------------------
------------- Remotes -------------
local OtherEvent = GG.R:WaitForChild("OtherEvent", 30);
local QuestEvents = OtherEvent:WaitForChild("QuestEvents", 10);
local SkillEvents = OtherEvent:WaitForChild("SkillEvents", 10);

-- Get Server_Skills remote for proper skill firing
local Server_Skills = SkillEvents:WaitForChild("Server_Skills", 10);

-- Get Server_Hitbox remote for direct skill damage (bypasses tool activation)
local Server_Hitbox = SkillEvents:FindFirstChild("Server_Hitbox")

-- Get Quest remote for abandoning quests
local QuestRemote = QuestEvents:WaitForChild("Quest", 10);

------------- Tools -------------
-- initialize tool table
State.List.Tools = {}

for _, tool in pairs(GG.selff.Backpack:GetChildren()) do
    if tool:IsA("Tool") then State.List.Tools[tool.Name] = tool end
end

for _, tool in pairs(GG.selc:GetChildren()) do
    if tool:IsA("Tool") then State.List.Tools[tool.Name] = tool end
end

State.Functions.Tools.getTools = function()
    return GG.tableToList(State.List.Tools, function(k, v) return k; end)
end

-- Get current tool instance - refreshes from Backpack/Character to handle character death
-- This function ensures we always have a valid tool instance reference
State.Functions.Tools.getCurrentToolInstance = function()
    if not State.CurrentTool or not State.CurrentTool.Name then
        return nil
    end

    -- Try to find tool in Backpack first, then Character
    local toolInstance = GG.selff.Backpack:FindFirstChild(State.CurrentTool.Name) or
                         GG.selc:FindFirstChild(State.CurrentTool.Name)

    -- Update the stored instance reference (lazy-load pattern)
    if toolInstance then
        State.CurrentTool.Instance = toolInstance
    end

    return toolInstance
end

-- Refresh tool list (rescan Backpack and Character)
State.Functions.Tools.refreshToolList = function()
    State.List.Tools = {}

    for _, tool in pairs(GG.selff.Backpack:GetChildren()) do
        if tool:IsA("Tool") then State.List.Tools[tool.Name] = tool end
    end

    for _, tool in pairs(GG.selc:GetChildren()) do
        if tool:IsA("Tool") then State.List.Tools[tool.Name] = tool end
    end

    -- Also refresh CurrentTool.Instance if we have a tool selected
    if State.CurrentTool and State.CurrentTool.Name then
        State.Functions.Tools.getCurrentToolInstance()
    end
end

-- connection to update tools when added/removed
GG.selff.Backpack.ChildAdded:Connect(function(child)
    if child:IsA("Tool") then State.List.Tools[child.Name] = child end
end)

GG.selff.Backpack.ChildRemoved:Connect(function(child)
    if child:IsA("Tool") then State.List.Tools[child.Name] = nil end
end)

-- unequips all tools
if GG.selc and GG.selc:FindFirstChild("Humanoid") then
    GG.selc.Humanoid:UnequipTools()
end

------------- ENEMIES PHASE -------------
State.Functions.Enemies = {}

-- Health validation helper - normalizes negative health to 0 for consistent dead/alive handling
-- Returns true if humanoid exists and has health > 0 (negative health is treated as 0/dead)
function State.Functions.Enemies.isAlive(humanoid)
    if not humanoid then return false end
    local health = math.max(0, humanoid.Health) -- Normalize negative health to 0
    return health > 0
end

-- Validate enemy target - checks instance exists, has HRP, has Humanoid, and is alive
-- Returns (part, hum, isAlive) tuple for comprehensive validation
function State.Functions.Enemies.isValidTarget(enemy)
    if not enemy or not enemy.Parent then return nil, nil, false end

    local part, hum = GG.rootHum(enemy)
    if not part or not hum then return nil, nil, false end

    local alive = State.Functions.Enemies.isAlive(hum)
    return part, hum, alive
end

-- Load enemy data from game
-- Only returns enemies that are alive (Health > 0, negative health treated as dead)
function State.Functions.Enemies.findEnemy(name)
    local enemyInstance = nil
    -- Collection
    local collectedEnemies = GG.CollectionService:GetTagged("Enemy")
    for _, enemy in pairs(collectedEnemies) do
        if enemy.Name == name then
            local part, hum = GG.rootHum(enemy)
            -- Validate both part exists AND enemy is alive
            if part and hum and hum.Health > 0 then return enemy end
        end
    end

    -- Folder
    local monsterFolder = {
        GG.W:FindFirstChild("Monsters"),
        GG.R:FindFirstChild("MonsterSpawn")
    }
    for _, folder in pairs(monsterFolder) do
        if folder then
            for _, enemy in pairs(folder:GetChildren()) do
                if enemy.Name == name then
                    local part, hum = GG.rootHum(enemy)
                    -- Validate both part exists AND enemy is alive
                    if part and hum and hum.Health > 0 then return enemy end
                end
            end
        end
    end

    return enemyInstance
end

-- bring mobs to target (magnet effect)
-- Protects the main target instance - only brings OTHER mobs to it
-- Uses BodyGyro/BodyVelocity to freeze brought mobs at target position
function State.Functions.Enemies.bringEnemyToTarget()
    local mainTarget = State.CurrentTargetInstance
    if not mainTarget then return false end

    local destPart = GG.rootHum(mainTarget)
    if not destPart then return false end
    local destPos = destPart.CFrame
    local targetName = mainTarget.Name
    destPart.CanCollide = false

    -- Constants
    local HIGH_TORQUE = Vector3.new(9e9, 9e9, 9e9)
    local HIGH_FORCE = Vector3.new(9e9, 9e9, 9e9)
    local GYRO_P = 100000
    local VELOCITY_P = 100000
    local ZERO_VELOCITY = Vector3.new(0, 0, 0)

    -- Cleanup dead mobs
    for enemy, constraints in pairs(State.BroughtMobs) do
        local hum = enemy:FindFirstChild("Humanoid")
        if not enemy.Parent or not State.Functions.Enemies.isAlive(hum) then
            if constraints.BodyGyro then
                pcall(function() constraints.BodyGyro:Destroy() end)
            end
            if constraints.BodyVelocity then
                pcall(function() constraints.BodyVelocity:Destroy() end)
            end
            State.BroughtMobs[enemy] = nil
        end
    end

    local collectedEnemies = GG.CollectionService:GetTagged("Enemy")
    for _, enemy in pairs(collectedEnemies) do
        local part, hum = GG.rootHum(enemy)

        if enemy.Name ~= targetName then continue end
        if not GG.CommonF:isnetworkowner(part) then continue end
        if not part or not hum then continue end
        if not State.Functions.Enemies.isAlive(hum) then continue end
        if enemy == mainTarget or part == destPart then continue end

        -- Check if already brought
        local constraints = State.BroughtMobs[enemy]
        if constraints then
            local bg = constraints.BodyGyro
            local bv = constraints.BodyVelocity
            if bg and bg.Parent then
                bg.CFrame = destPos
            end
            if bv and bv.Parent then
                bv.Velocity = ZERO_VELOCITY
            end
            part.CFrame = destPos
            continue
        end

        -- Create BodyGyro to freeze position
        local bg = Instance.new("BodyGyro")
        bg.P = GYRO_P
        bg.MaxTorque = HIGH_TORQUE
        bg.CFrame = destPos
        bg.Parent = part

        -- Create BodyVelocity to freeze movement
        local bv = Instance.new("BodyVelocity")
        bv.Velocity = ZERO_VELOCITY
        bv.MaxForce = HIGH_FORCE
        bv.P = VELOCITY_P
        bv.Parent = part

        -- Track
        State.BroughtMobs[enemy] = {
            BodyGyro = bg,
            BodyVelocity = bv,
            Timestamp = tick()
        }

        -- Teleport to target
        part.CFrame = destPos

        -- Freeze
        -- hum.PlatformStand = true
        -- hum.Sit = true
        -- hum:ChangeState(11)
        hum.JumpPower = 0
        hum.WalkSpeed = 0
        part.CanCollide = false

        -- Remove animator
        local animator = enemy:FindFirstChild("Animator")
        if animator then
            animator:Destroy()
        end

        sethiddenproperty(GG.selff, "SimulationRadius", math.huge)
    end

    return true
end

-- Cleanup function for brought mobs (call when toggling off or changing target)
function State.Functions.Enemies.cleanupBroughtMobs()
    for enemy, constraints in pairs(State.BroughtMobs) do
        if constraints.BodyGyro then
            pcall(function() constraints.BodyGyro:Destroy() end)
        end
        if constraints.BodyVelocity then
            pcall(function() constraints.BodyVelocity:Destroy() end)
        end
    end
    State.BroughtMobs = {}
end

------------- COMBAT PHASE -------------
State.Functions.Combat = {}
-- Basic attack function - uses getCurrentToolInstance for safe instance access
function State.Functions.Combat.Attack()
    if State.CurrentTargetInstance and State.CurrentTool and State.CurrentTool.Name then
        -- Get fresh tool instance (handles character death)
        local tool = State.Functions.Tools.getCurrentToolInstance()
        if not tool then return end

        if tool.Parent ~= GG.selc then
            GG.CommonF:EquipTool(tool)
        end
        tool:Activate()
        tool.Enabled = true
    end
end

-- Cast Skills - validates tool instance exists before firing skill remotes
function State.Functions.Combat.CastSkill(key, targetHRP)
    if not State.CurrentTool or not State.CurrentTool.Name then return end

    -- Verify tool instance is valid (handles character death)
    local tool = State.Functions.Tools.getCurrentToolInstance()
    if not tool then return end

    local mousePos = nil
    if targetHRP then
        mousePos = targetHRP.Position
    else
        mousePos = GG.cmdm.Hit.Position
    end

    local holdArgs = {GG.selc, tool.Name, key, "Hold"}
    pcall(function() Server_Skills:FireServer(unpack(holdArgs)) end)

    task.wait(0.05)

    local releaseArgs = {
        GG.selc, tool.Name, key, "Release",
        {Mouse_Position = mousePos, Hit_Position = mousePos}
    }
    pcall(function() Server_Skills:FireServer(unpack(releaseArgs)) end)
end

-- Cast Skill Direct - uses Server_Hitbox for instant damage without tool activation
-- Faster and more reliable than CastSkill, bypasses Hold/Release delays
function State.Functions.Combat.CastSkillDirect(target, key)
    if not target or not State.CurrentTool or not State.CurrentTool.Name then return end

    local targetHRP = target:FindFirstChild("HumanoidRootPart")
    local playerHRP = GG.HumRSelf
    if not targetHRP or not playerHRP then return end

    local args = {
        target,
        State.CurrentTool.Name,
        key,
        {
            Skill_Type = "Enemy_Effect",
            Mouse_Position = targetHRP.Position,
            Moving_Speed = 275,
            Weapon_Effect = true,
            RootPart_Position = playerHRP.Position
        }
    }

    if Server_Hitbox then
        pcall(function() Server_Hitbox:FireServer(unpack(args)) end)
        State.Functions.Combat.CastSkill(key, targetHRP)
    end
end

-- Cast Skill on Multiple Targets - applies skill damage to all nearby enemies
-- Useful for AOE farming when using bringEnemyToTarget
function State.Functions.Combat.CastSkillAOE(key, maxTargets)
    maxTargets = maxTargets or 5
    local targets = {}
    local targetName = State.CurrentTargetSelected

    -- Extract plain name from "Name [Level]" format
    local plainTargetName = targetName and targetName:match("^(.+)%s+%[%d+%]$") or targetName

    -- Collect all enemies with same name
    local collectedEnemies = GG.CollectionService:GetTagged("Enemy")
    for _, enemy in pairs(collectedEnemies) do
        if #targets >= maxTargets then break end

        -- Only include same-name mobs (for bring targeting)
        if plainTargetName and enemy.Name ~= plainTargetName then
            continue
        end

        local part = enemy:FindFirstChild("HumanoidRootPart")
        local hum = enemy:FindFirstChild("Humanoid")
        -- Use isAlive helper for consistent health validation (handles negative health)
        if part and hum and State.Functions.Enemies.isAlive(hum) then
            table.insert(targets, enemy)
        end
    end

    -- Cast skill on each target
    for _, target in pairs(targets) do
        State.Functions.Combat.CastSkillDirect(target, key)
    end
end

-- Cast All Skills - shared function to eliminate duplicate logic
-- Casts traditional, direct, and AOE skills with xpcall protection
function State.Functions.Combat.castAllSkills(enemy, enemyPart, aoeCount)
    aoeCount = aoeCount or 5

    local skills = {"X", "Z", "C"}
    for _, skill in ipairs(skills) do
        -- Traditional skill (Hold/Release pattern)
        xpcall(function()
            State.Functions.Combat.CastSkill(skill, enemyPart)
        end, function(err)
            warn("[MemSea] CastSkill " .. skill .. " error:", err)
        end)

        -- Direct skill damage (instant)
        xpcall(function()
            -- State.Functions.Combat.CastSkillDirect(enemy, skill)
        end, function(err)
            warn("[MemSea] CastSkillDirect " .. skill .. " error:", err)
        end)

        -- AOE skills
        xpcall(function()
            -- State.Functions.Combat.CastSkillAOE(skill, aoeCount)
        end, function(err)
            warn("[MemSea] CastSkillAOE " .. skill .. " error:", err)
        end)
    end
end

-- Auto Skills
function State.Functions.Combat.autoSkills(value)
    State.Toggles.AutoSkills = value
    GG.CommonF:Threads("AutoSkillsThread", value, function()
        while State.Toggles.AutoSkills do
            task.wait(0.05)
            if State.CurrentTool and State.CurrentTargetInstance and
                State.Toggles.AutoFarm then

                local enemy = State.CurrentTargetInstance
                local enemyPart = enemy:FindFirstChild("HumanoidRootPart")

                GG.CommonF:spawnThread(function()
                    State.Functions.Combat.castAllSkills(enemy, enemyPart, 5)
                end)
            end
        end
    end)
end

-- AutoFarm

------------- QUEST PHASE -------------
-- Load quest data from game
State.Functions.Quest = {}

-- Load MonsterSettings for enemy data
pcall(function()
    local ModuleScript = GG.R:FindFirstChild("ModuleScript")
    if ModuleScript then
        local MonsterSettings = ModuleScript:FindFirstChild("MonsterSettings")
        if MonsterSettings then
            local loadedEnemies = require(MonsterSettings)
            if type(loadedEnemies) == "table" then
                State.List.AllEnemies = loadedEnemies
                -- Categorize enemies into Bosses and Raids
                for enemyName, data in pairs(loadedEnemies) do
                    -- EnemyName with Level
                    enemyName = enemyName .. " [" .. (data.Level or "0") .. "]"
                    if type(data) == "table" and not (data.Raid_Boss or data.Raid_Enemy or data.TrueRaid_Boss or data.Special_Quest) then
                        State.List.Quest.Enemies[enemyName] = data
                    -- if type(data) == "table" and (data.Need == 1 and not (data.Raid_Boss or data.Raid_Enemy or data.TrueRaid_Boss)) then
                    --     State.List.Quest.Bosses[enemyName] = data
                    -- end
                    elseif type(data) == "table" and (data.Raid_Boss or data.Raid_Enemy or data.TrueRaid_Boss) then
                        State.List.Quest.Raids[enemyName] = data
                    elseif type(data) == "table" and data.Special_Quest then
                        State.List.Quest.Special[enemyName] = data
                    end
                end
            end
        else
            warn("[MemSea] MonsterSettings not found in ModuleScript")
        end

        -- Also load Quest_Settings for quest data
        local QuestSettings = ModuleScript:FindFirstChild("Quest_Settings")
        if QuestSettings then
            local loadedQuests = require(QuestSettings)
            if type(loadedQuests) == "table" then
                State.List.Quest.QuestData = loadedQuests
            end
        else
            warn("[MemSea] Quest_Settings not found in ModuleScript")
        end
    else
        warn("[MemSea] ModuleScript not found in R")
    end
end)

-- get List of Enemies then sort by level
--- Normal Enemies List
function State.Functions.Quest.getNormalEnemiesList()
    local enemyList = {}
    for name, data in pairs(State.List.Quest.Enemies) do
        table.insert(enemyList, {Name = name, Level = data.Level or 0})
    end

    table.sort(enemyList, function(a, b) return a.Level < b.Level end)

    local sortedNames = {}
    for _, entry in pairs(enemyList) do
        table.insert(sortedNames, entry.Name)
    end

    return sortedNames
end

--- Special Quests
function State.Functions.Quest.getSpecialList()
    local specialList = {}
    for name, _ in pairs(State.List.Quest.Special) do
        table.insert(specialList, name)
    end

    table.sort(specialList)

    return specialList
end

--- Raids
function State.Functions.Quest.getRaidsList()
    local raidList = {}
    for name, _ in pairs(State.List.Quest.Raids) do
        table.insert(raidList, name)
    end

    table.sort(raidList)

    return raidList
end

-------
function State.Functions.Quest.isSpecialQuest(questData)
    if not questData then return false end

    -- Method 1: Check if quest target is in Bosses list
    local targetName = questData.Target
    -- if State.List.Bosses[targetName] then return true end

    -- Method 2: Check if quest target is in Raids list
    if State.List.Raids[targetName] then return true end

    -- Method 3: Check enemy data for Boss flag
    local enemyData = State.List.Enemies[targetName]
    if enemyData and type(enemyData) == "table" then
        if enemyData.TrueRaid_Boss or enemyData.Raid_Boss or enemyData.Raid_Enemy then
            return true
        end
    end

    return false
end

function State.Functions.Quest.getCurrentLevel()
    local playerData = GG.selff:FindFirstChild("PlayerData")
    if playerData then
        local level = playerData:FindFirstChild("Level")
        if level then return level.Value end
    end
    return -1
end

function State.Functions.Quest.findQuest(targetName)
    if not State.List.Quest.QuestData then
        warn("[MemSea] Quest list not loaded!")
        return nil, nil
    end

    -- Extract name from "Name [Level]" format if present
    local plainName = targetName:match("^(.+)%s+%[%d+%]$") or targetName

    local questList = {}
    for name, _ in pairs(State.List.Quest.QuestData) do table.insert(questList, name) end
    local total = #questList

    for i, questName in pairs(questList) do
        local data = State.List.Quest.QuestData[questName]
        -- Match both plain name and "Name [Level]" format
        local formattedTarget = data.Target .. " [" .. data.LevelNeed .. "]"
        print(string.format("Looking for quest: %s == %s or %s",
            plainName, data.Target, formattedTarget))
        if data.Target == plainName or formattedTarget == targetName then
            return data, questName
        end
    end
    return nil, nil
end
function State.Functions.Quest.getBestQuestForLevel(level)
    if not State.List.Quest.QuestData then
        warn("[MemSea] Quest list not loaded!")
        return nil, nil
    end

    local bestQuest = nil
    local bestQuestName = nil
    local maxExpRatio = -1

    for questName, data in pairs(State.List.Quest.QuestData) do
        if data.LevelNeed <= level then
            -- Skip special quests (boss/raid) for AutoLevel
            if State.Functions.Quest.isSpecialQuest(data) then
                continue
            end

            if data.Exp and data.Need and data.Need > 0 and data.Exp > 0 then
                local expRatio = data.Exp / data.Need
                if expRatio > maxExpRatio then
                    maxExpRatio = expRatio
                    bestQuest = data
                    bestQuestName = questName
                end
            end
        end
    end

    return bestQuest, bestQuestName
end

function State.Functions.Quest.getActiveQuest()
    local playerData = GG.selff:FindFirstChild("PlayerData")
    if not playerData then return 0 end

    return playerData.CurrentQuest.Value
end

function State.Functions.Quest.getCurrentQuestsTarget(target)
    local questsFolder = GG.selff:FindFirstChild("QuestFolder")
    if not questsFolder then return nil end

    local activeTargets = {}

    for index, questSlot in pairs(questsFolder:GetChildren()) do
        if questSlot:FindFirstChild("Target") then
            local questTarget = questSlot.Target.Value
            if questTarget == target then
                table.insert(activeTargets, questSlot)
            end
        end
    end

    return activeTargets
end

function State.Functions.Quest.abandonAllQuests()
    local playerData = GG.selff:FindFirstChild("PlayerData")
    if not playerData then return end

    local questsFolder = playerData:FindFirstChild("Quests")
    if not questsFolder then return end

    for index, quest in pairs(questsFolder:GetChildren()) do
        local args = {"Abandon_Quest", {QuestSlot = quest.Name}}
        QuestRemote:FireServer(unpack(args))
    end
end

function State.Functions.Quest.findQuestNPC(questName)
    local npcsFolder = GG.W:FindFirstChild("NPCs")
    local questNpcFolder = npcsFolder and
                               npcsFolder:FindFirstChild("Quests_Npc")
    local npcStorage = GG.R:FindFirstChild("NPC_Storage")

    local npcFolders = {questNpcFolder, npcStorage}

    for _, folder in pairs(npcFolders) do
        if folder then
            for _, npc in pairs(folder:GetChildren()) do
                if npc.Name == questName then
                    local part, hum = GG.rootHum(npc)
                    if part then return npc end
                end
            end
        end
    end

    return nil
end

function State.Functions.Quest.acceptQuestFromNPC(questName)
    local npc = State.Functions.Quest.findQuestNPC(questName)
    if not npc then return false end

    -- Teleport to NPC
    print("Teleporting to NPC: " .. questName)
    GG.CommonF:TpAL(npc, 0.05)
    task.wait(0.5)

    -- Find and fire proximity prompt on NPC
    local prox = GG.CommonF:findPrompt(npc:GetDescendants())
    if not prox then
        -- Try searching in NPCs folder structure
        local npcsFolder = GG.W:FindFirstChild("NPCs")
        if npcsFolder then
            local questNpc = npcsFolder:FindFirstChild("Quests_Npc")
            if questNpc then
                local targetNpc = questNpc:FindFirstChild(questName)
                if targetNpc then
                    prox = GG.CommonF:findPrompt(targetNpc:GetDescendants())
                end
            end
        end
    end

    if not prox then return false end

    -- Fire the proximity prompt to accept quest
    if fireproximityprompt then
        fireproximityprompt(prox)
    else
        -- Fallback: Teleport to prompt and activate
        local hrp = GG.HumRSelf
        if hrp and prox.Parent then
            local promptPart = prox.Parent:IsA("BasePart") and prox.Parent or
                                   prox.Parent:FindFirstChildWhichIsA("BasePart")
            if promptPart then
                hrp.CFrame = promptPart.CFrame
                task.wait(0.2)
                -- Simulate proximity
                prox.MaxActivationDistance = 999
                prox.HoldDuration = 0
            end
        end
    end

    task.wait(0.5)
    return true
end

function State.Functions.Quest.autoQuest(value)
    State.Toggles.AutoQuest = value
    GG.CommonF:Threads("AutoQuestThread", value, function()
        print("Auto Quest thread started")
        while State.Toggles.AutoQuest do
            task.wait(1)

            local currentLevel = State.Functions.Quest.getCurrentLevel()
            local activeQuests = State.Functions.Quest.getActiveQuest()

            if activeQuests == 0 then
                local bestQuest, bestQuestName
                if State.Toggles.AutoLevel then
                    bestQuest, bestQuestName =
                        State.Functions.Quest.getBestQuestForLevel(currentLevel)
                    print("Looking for best quest for level: " ..
                              tostring(currentLevel))
                else
                    bestQuest, bestQuestName =
                        State.Functions.Quest.findQuest(State.CurrentTargetSelected)
                    print("Looking for quest for target: " ..
                              tostring(State.CurrentTargetSelected))
                end

                if bestQuest and bestQuestName then
                    -- Set target to best quest target (with level format)
                    local targetFormatted = bestQuest.Target .. " [" .. bestQuest.LevelNeed .. "]"
                    print("[MemSea] AutoLevel: Target = " .. targetFormatted)
                    
                    -- Update dropdown
                    pcall(function() Options['EnemyTargetDropdown']:SetValue(targetFormatted) end)
                    State.CurrentTargetSelected = targetFormatted
                    local accepted = State.Functions.Quest.acceptQuestFromNPC(
                                         bestQuestName)
                    if not accepted then
                        GG.CommonF:Notify("MemSea Hub",
                                          "Failed to accept quest: " ..
                                              bestQuestName, 5)
                    end
                else
                    GG.CommonF:Notify("MemSea Hub",
                                      "No suitable quest found for level " ..
                                          tostring(currentLevel), 5)
                end
            elseif State.Toggles.AutoLevel then
                -- Always abandon and accept best quest (no need to check current quests)
                local bestQuest, bestQuestName =
                    State.Functions.Quest.getBestQuestForLevel(currentLevel)

                State.Functions.Quest.abandonAllQuests()
                local accepted = State.Functions.Quest.acceptQuestFromNPC(bestQuestName)

                if accepted then
                    local targetFormatted = bestQuest.Target .. " [" .. bestQuest.LevelNeed .. "]"
                    print("[MemSea] AutoLevel: Accepted quest - Target = " .. targetFormatted)

                    -- Update dropdown
                    pcall(function() Options['EnemyTargetDropdown']:SetValue(targetFormatted) end)
                    State.CurrentTargetSelected = targetFormatted
                end
            end
        end
    end)
end

------------- FARMING PHASE (Shared Loop) -------------
State.Functions.Farming = {}

-- Check if current quest matches target (for AutoQuest mode)
-- If quest is wrong and AutoFarm is on, will TP to accept correct quest
local function isQuestCorrect()
    if not State.Toggles.AutoQuest and not State.Toggles.AutoFarm then
        return true -- No quest check needed if not in AutoQuest/AutoFarm mode
    end

    local targetName = State.CurrentTargetSelected
    if not targetName or targetName == "" then
        return true
    end

    local plainName = targetName:match("^(.+)%s+%[%d+%]$") or targetName

    local questsFolder = GG.selff:FindFirstChild("QuestFolder")
    if not questsFolder then
        -- TP to accept quest if AutoFarm is on
        if State.Toggles.AutoFarm then
            State.Functions.Quest.abandonAllQuests()
            State.Functions.Quest.acceptQuestFromNPC(plainName)
        end
        return true
    end

    for _, questSlot in pairs(questsFolder:GetChildren()) do
        if questSlot:FindFirstChild("Target") then
            local questTarget = questSlot.Target.Value
            if questTarget == plainName then
                return true -- Quest matches target
            end
        end
    end

    -- Quest doesn't match - TP to accept correct quest if AutoFarm is on
    if State.Toggles.AutoFarm then
        State.Functions.Quest.abandonAllQuests()
        State.Functions.Quest.acceptQuestFromNPC(plainName)
    end

    return true -- Allow farming to continue
end

-- Shared farming loop - split threads for teleport, bring, attack, skills
function State.Functions.Farming.runFarmLoop()
    -- Track current enemy for all threads
    local currentEnemy = nil

    -- 1. Teleport Thread - continuous teleport to target (no delay)
    GG.CommonF:Threads("TeleportThread", true, function()
        State.Functions.Teleport.startStabilize()
        while State.Toggles.AutoFarm or State.Toggles.AutoQuest or State.Toggles.AutoLevel or State.Toggles.AutoSpecialQuest do
            task.wait()

            local targetName = State.CurrentTargetSelected
            if (not targetName or targetName == "") and not State.Toggles.AutoLevel then
                continue
            end

            -- Only teleport if quest is correct (when AutoQuest is on)
            if not isQuestCorrect() then
                continue
            end

            local plainName = targetName and targetName:match("^(.+)%s+%[%d+%]$") or targetName
            local enemy = State.Functions.Enemies.findEnemy(plainName)
            if enemy then
                -- Double-validate enemy is still alive before setting as target
                local part, hum, alive = State.Functions.Enemies.isValidTarget(enemy)
                if alive then
                    currentEnemy = enemy
                    State.CurrentTargetInstance = enemy
                    State.Functions.Teleport.toTarget(enemy)
                else
                    -- Target invalid/dead, clear it
                    State.CurrentTargetInstance = nil
                end
            end
        end
    end)

    -- 2. Bring Thread - continuous bring mobs to target (no delay)
    GG.CommonF:Threads("BringThread", true, function()
        while State.Toggles.AutoFarm or State.Toggles.AutoQuest or State.Toggles.AutoLevel or State.Toggles.AutoSpecialQuest do
            task.wait()

            -- Only run if AutoBring is enabled
            if not State.Toggles.AutoBring then
                continue
            end

            local targetName = State.CurrentTargetSelected
            if not targetName or targetName == "" then
                continue
            end

            -- Only bring if quest is correct (when AutoQuest is on)
            if not isQuestCorrect() then
                continue
            end

            -- Bring mobs to main target (uses State.CurrentTargetInstance)
            State.Functions.Enemies.bringEnemyToTarget()
        end
    end)

    -- 3. Attack Thread - attack when mob is in distance
    GG.CommonF:Threads("AttackThread", true, function()
        while State.Toggles.AutoFarm or State.Toggles.AutoLevel or State.Toggles.AutoSpecialQuest do
            task.wait()

            local targetName = State.CurrentTargetSelected
            if not targetName or targetName == "" or not State.CurrentTargetInstance then
                continue
            end

            -- Only attack if quest is correct (when AutoQuest is on)
            if not isQuestCorrect() then
                continue
            end

            -- Check if mob is in distance
            local enemyPart = GG.rootHum(State.CurrentTargetInstance)
            local playerPart = GG.HumRSelf
            if not enemyPart or not playerPart then
                continue
            end

            local distance = (enemyPart.Position - playerPart.Position).Magnitude
            local maxDistance = State.Slides.Distance + 20 -- Allow some tolerance

            if distance <= maxDistance and State.CurrentTool then
                State.Functions.Combat.Attack()
            end
        end
    end)

    -- -- 4. Skills Thread - cast skills when mob is in distance
    GG.CommonF:Threads("SkillsThread", true, function()
        while State.Toggles.AutoFarm or State.Toggles.AutoLevel or State.Toggles.AutoSpecialQuest do
            task.wait() -- Skills need more cooldown time

            local targetName = State.CurrentTargetSelected
            if not targetName or targetName == "" then
                continue
            end

            -- Only cast skills if quest is correct (when AutoQuest is on)
            if not isQuestCorrect() then
                continue
            end

            if not State.Toggles.AutoSkills or not State.CurrentTool or not State.CurrentTool.Name then
                continue
            end

            -- Verify tool instance is valid (handles character death)
            local toolInstance = State.Functions.Tools.getCurrentToolInstance()
            if not toolInstance then
                continue
            end

            local plainName = targetName:match("^(.+)%s+%[%d+%]$") or targetName
            local enemy = State.Functions.Enemies.findEnemy(plainName)
            if not enemy then
                continue
            end

            -- Check if mob is in distance
            local enemyPart = GG.rootHum(enemy)
            local playerPart = GG.HumRSelf
            if not enemyPart or not playerPart then
                continue
            end

            local distance = (enemyPart.Position - playerPart.Position).Magnitude
            local maxDistance = State.Slides.Distance + 20

            if distance <= maxDistance then
                State.Functions.Combat.castAllSkills(enemy, enemyPart, 5)
            end
        end
    end)

    print("[MemSea] Farm threads started")
end

-- AutoFarm toggle wrapper
function State.Functions.Farming.autoFarm(value)
    State.Toggles.AutoFarm = value

    if value then
        -- Disable conflicting toggles
        if State.Toggles.AutoLevel then
            State.Toggles.AutoLevel = false
            pcall(function() Options['AutoLevel']:SetValue(false) end)
        end
        State.Functions.Farming.runFarmLoop()
        print("[MemSea] Auto Farm: ON")
    else
        -- Stop all farm threads
        GG.CommonF:Threads("TeleportThread", false, nil)
        State.Functions.Teleport.stopStabilize()
        print("[MemSea] Auto Farm: OFF")
    end
end

------------- TELEPORT PHASE -------------
State.Functions.Teleport = {}
function State.Functions.Teleport.toTarget(target)
    if not target then return end

    local targetPart, _ = GG.rootHum(target)
    if not targetPart then return end

    local tpMethod = State.CurrentTpMethod or "Above"
    local distance = State.Slides.Distance

    -- Calculate teleport CFrame based on method
    local teleportCFrame
    if tpMethod == "Above" then
        teleportCFrame = targetPart.CFrame * GG.CF(0, distance, 0) * GG.CFAg(math.rad(-90), 0, 0)
    elseif tpMethod == "Below" then
        teleportCFrame = targetPart.CFrame * GG.CF(0, -distance, 0) * GG.CFAg(math.rad(90), 0, 0)
    elseif tpMethod == "Behind" then
        teleportCFrame = targetPart.CFrame * GG.CF(0, 0, distance)
    elseif tpMethod == "Bring" then
        targetPart.CFrame = GG.HumRSelf.CFrame * GG.CF(0, 0, -distance)
    end

    if teleportCFrame then
        GG.CommonF:Tp(teleportCFrame)
        GG.HumRSelf.Velocity = Vector3.new(0, 0, 0)
        GG.HumRSelf.RotVelocity = Vector3.new(0, 0, 0)
        if State.StabilizeBG ~= nil then
            State.StabilizeBG.CFrame = GG.CFLook(
                GG.HumRSelf.Position,
                targetPart.Position
            )
        end
    end
    -- Store current mob Instance for stabilization
    State.CurrentMob = target
end

-- Stabilize using Heartbeat (runs every frame)
function State.Functions.Teleport.startStabilize()
    local character = GG.selc
    local hrp = character and character:FindFirstChild("HumanoidRootPart")

    if hrp and not State.StabilizeBG and not State.StabilizeBV then
        -- Create BodyGyro and BodyVelocity for stabilization
        local BG = Instance.new("BodyGyro")
        local BV = Instance.new("BodyVelocity")
        BG.P = 9e4
        BG.Parent = hrp
        BV.Parent = hrp
        BG.MaxTorque = Vector3.new(9e9, 9e9, 9e9)
        BG.CFrame = hrp.CFrame
        BV.Velocity = Vector3.new(0, 0, 0)
        BV.MaxForce = Vector3.new(9e9, 9e9, 9e9)

        State.StabilizeBG = BG
        State.StabilizeBV = BV
    end
end

function State.Functions.Teleport.stopStabilize()
    if State.StabilizeBG then
        State.StabilizeBG:Destroy()
        State.StabilizeBG = nil
    end
    if State.StabilizeBV then
        State.StabilizeBV:Destroy()
        State.StabilizeBV = nil
    end
    State.CurrentMob = nil
end

------------- FLUENT UI SETUP -------------
-- Local UI Library: D:\Code\Roblox\03-UI-Library\Libraries\Fluent\main.lua
-- GitHub: https://github.com/dawid-scripts/Fluent
--
-- For local development, replace loadstring with:
--   local Fluent = loadfile("03-UI-Library/Libraries/Fluent/main.lua")()
--
local Fluent = loadstring(game:HttpGet(
                              "https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"))()
local SaveManager = loadstring(game:HttpGet(
                                   "https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/SaveManager.lua"))()
local InterfaceManager = loadstring(game:HttpGet(
                                        "https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/InterfaceManager.lua"))()


local Options = Fluent.Options
                                        
local Window = Fluent:CreateWindow({
    Title = "MemSea Hub v2.6.0",
    SubTitle = "OOP Refactoring + Code Cleanup",
    TabWidth = 160,
    Size = UDim2.fromOffset(580, 480),
    Acrylic = true,
    Theme = "Dark",
    MinimizeKey = Enum.KeyCode.F6
})

------------- Override ScriptLoader Notifications with Fluent UI -------------
if GG.CommonF and GG.CommonF.SetNotify then
    GG.CommonF:SetNotify(function(title, message, duration)
        Fluent:Notify({
            Title = title,
            Content = message,
            Duration = duration or 3
        })
    end)
end

------------- UI DEFAULT VALUES HELPER -------------
-- Helper function to get default value from State or fallback
-- This enables state persistence across sessions
local function getDefault(key, fallback)
    local value = State[key]
    if value ~= nil then
        return value
    end
    -- Check Toggles for boolean values
    if State.Toggles and State.Toggles[key] ~= nil then
        return State.Toggles[key]
    end
    -- Check Slides for numeric values
    if State.Slides and State.Slides[key] ~= nil then
        return State.Slides[key]
    end
    return fallback
end

local Tabs = {
    Main = Window:AddTab({Title = "Auto Farm", Icon = "sword"}),
    Misc = Window:AddTab({Title = "Misc", Icon = "more-horizontal"}),
    Settings = Window:AddTab({Title = "Settings", Icon = "settings"})
}

------------- MAIN TAB CONTROLS -------------

-- Section Auto Farm Settings (Shared)
local AutoFarmSettingsSection = Tabs.Main:AddSection("Farm Settings")

-- dropdown Tools
AutoFarmSettingsSection:AddDropdown("ToolDropdown", {
    Title = "Select Tool",
    Default = "",
    Description = "Choose the tool/weapon to use for farming.",
    Values = State.Functions.Tools.getTools(),
    Callback = function(selected)
        State.CurrentTool = {
            Name = selected,
            Instance = (function()
                return GG.selff.Backpack:FindFirstChild(selected) or
                           GG.selc:FindFirstChild(selected)
            end)()
        }
    end
})
AutoFarmSettingsSection:AddButton({
    Title = "Refresh Tools",
    Description = "Refresh the list of available tools.",
    Callback = function()
        -- Use the new refreshToolList function which also refreshes CurrentTool.Instance
        State.Functions.Tools.refreshToolList()
        GG.CommonF:Notify("MemSea Hub", "Tool list refreshed.", 3)
        -- SetValues
        Options['ToolDropdown']:SetValues(State.Functions.Tools.getTools())
    end
})

-- teleport method
AutoFarmSettingsSection:AddDropdown("TpMethodDropdown", {
    Title = "Select Teleport Method",
    Default = getDefault("CurrentTpMethod", "Above"),
    Description = "Choose the teleportation method to reach the target.",
    Values = State.List.TpMethods,
    Callback = function(selected) State.CurrentTpMethod = selected end
})

-- distance slider
AutoFarmSettingsSection:AddSlider("DistanceSlider", {
    Title = "Teleport Distance",
    Default = getDefault("Distance", 8),
    Min = 1,
    Max = 20,
    Rounding = 0,
    Description = "Set the distance for teleportation methods.",
    Callback = function(value) State.Slides.Distance = value end
})

-- Auto Skills
AutoFarmSettingsSection:AddToggle("AutoSkills", {
    Title = "Enable Auto Skills",
    Default = getDefault("AutoSkills", false),
    Description = "Automatically uses skills during combat.",
    Callback = function(value) State.Functions.Combat.autoSkills(value) end
})

-- Auto Bring
AutoFarmSettingsSection:AddToggle("AutoBring", {
    Title = "Enable Auto Bring",
    Default = getDefault("AutoBring", false),
    Description = "Brings nearby enemies to your target (magnet farm).",
    Callback = function(value)
        State.Toggles.AutoBring = value
        -- Cleanup brought mobs when turning off
        if not value then
            State.Functions.Enemies.cleanupBroughtMobs()
        end
    end
})

------------- FARMING DETAILS SECTION -------------
local FarmingDetailsSection = Tabs.Main:AddSection("Farming Details")

-- Paragraph references for updating
local TargetParagraph = FarmingDetailsSection:AddParagraph({
    Title = "Target: None",
    Content = ""
})
local QuestParagraph = FarmingDetailsSection:AddParagraph({
    Title = "Quest: No active quest",
    Content = ""
})
local MobParagraph = FarmingDetailsSection:AddParagraph({
    Title = "Current Mob: None",
    Content = ""
})

-- Update function to refresh the details display
local function updateFarmingDetails()
    local targetText = State.CurrentTargetSelected or "None"
    local questText = "No active quest"
    local mobText = "None"

    -- Update target paragraph
    TargetParagraph:SetTitle("Target: " .. targetText)

    -- Get active quest info
    local activeQuests = State.Functions.Quest.getActiveQuest()
    if activeQuests > 0 then
        questText = tostring(activeQuests) .. " active"
    end
    QuestParagraph:SetTitle("Quest: " .. questText)

    -- Show current mob being farmed (from State.CurrentMob)
    if State.CurrentMob and State.CurrentMob.Parent then
        local part = GG.rootHum(State.CurrentMob)
        if part then
            local dist = (part.Position - (GG.HumRSelf and GG.HumRSelf.Position or Vector3.new())).Magnitude
            mobText = State.CurrentMob.Name .. " [" .. math.floor(dist) .. " studs]"
        else
            mobText = State.CurrentMob.Name .. " [no HRP]"
        end
    end
    MobParagraph:SetTitle("Current Mob: " .. mobText)
end

-- Initial display
updateFarmingDetails()

-- Auto-refresh farming details every 1 second
GG.CommonF:Threads("FarmingDetailsThread", true, function()
    while true do
        task.wait(1)
        -- Only update when farming is active
        if State.Toggles.AutoFarm or State.Toggles.AutoQuest or State.Toggles.AutoLevel then
            updateFarmingDetails()
        end
    end
end)


------------- AUTO LEVEL SECTION -------------
local AutoLevelSection = Tabs.Main:AddSection("Auto Level")

AutoLevelSection:AddToggle("AutoLevel", {
    Title = "Enable Auto Level",
    Default = getDefault("AutoLevel", false),
    Description = "Auto-leveling: Quests ON, Boss/Raid OFF, AutoFarm ON with best quest target.",
    Callback = function(value)
        State.Toggles.AutoLevel = value

        -- Force toggles (State only, no UI updates)
        State.Toggles.AutoQuest = value
        State.Toggles.SpecialQuest = false
        State.Toggles.AutoRaid = false
        State.Toggles.AutoFarm = value

        if value then
            -- AutoLevel ON: Configure settings
            local currentLevel = State.Functions.Quest.getCurrentLevel()
            local bestQuest, bestQuestName = State.Functions.Quest.getBestQuestForLevel(currentLevel)

            if bestQuest then
                -- Set target directly (no dropdown update)
                local targetFormatted = bestQuest.Target .. " [" .. bestQuest.LevelNeed .. "]"
                print("[MemSea] AutoLevel: Target = " .. targetFormatted)
                State.CurrentTargetSelected = targetFormatted

                -- Start quest management + shared farming loop
                State.Functions.Quest.autoQuest(true)
                State.Functions.Farming.runFarmLoop()

                GG.CommonF:Notify("Auto Level", "Farming: " .. bestQuest.Target .. " [Lvl " .. bestQuest.LevelNeed .. "]", 5)
            else
                GG.CommonF:Notify("Auto Level", "No suitable quest found for level " .. currentLevel, 5)
                State.Toggles.AutoLevel = false
            end
        else
            -- Stop all farm threads
            GG.CommonF:Threads("TeleportThread", false, nil)
            State.Functions.Teleport.stopStabilize()
            print("[MemSea] AutoLevel: Disabled")
        end
    end
})

-- Show current level info
AutoLevelSection:AddParagraph({
    Title = "Current Level: " .. State.Functions.Quest.getCurrentLevel(),
    Content = ""
})

-- Auto Farm Selection
local AutoFarmSection = Tabs.Main:AddSection("Auto Farm")
-- dropdown enemies targets from quest data
AutoFarmSection:AddDropdown("EnemyTargetDropdown", {
    Title = "Select Target Enemy",
    Default = "",
    Description = "Choose the enemy you want to farm.",
    Values = State.Functions.Quest.getNormalEnemiesList(),
    Callback = function(selected)
        State.CurrentTargetSelected = selected
        -- Cleanup previously brought mobs when changing target
        if State.Toggles.AutoBring then
            State.Functions.Enemies.cleanupBroughtMobs()
        end
    end
})

-- Auto Farm
AutoFarmSection:AddToggle("AutoFarm", {
    Title = "Enable Auto Farm",
    Default = getDefault("AutoFarm", false),
    Description = "Automatically farms the selected target using the chosen tool.",
    Callback = function(value)
        if value and State.Toggles.AutoLevel then
            GG.CommonF:Notify("Auto Farm", "Disabled - AutoLevel is running", 3)
            return
        end
        State.Functions.Farming.autoFarm(value)
    end
})

-- Auto Quest
AutoFarmSection:AddToggle("AutoQuest", {
    Title = "Enable Auto Quest",
    Default = getDefault("AutoQuest", false),
    Description = "Automatically accepts and completes quests for the selected target.",
    Callback = function(value)
        if value and State.Toggles.AutoLevel then
            GG.CommonF:Notify("Auto Quest", "Disabled - AutoLevel is running", 3)
            return
        end
        State.Functions.Quest.autoQuest(value)
    end
})

------------- SPECIAL QUEST SECTION -------------
local SpecialQuestSection = Tabs.Main:AddSection("Special Quest")

SpecialQuestSection:AddDropdown("SpecialQuestTargetDropdown", {
    Title = "Select Special Quest Target",
    Default = "",
    Description = "Choose the boss, raid, or special quest you want to fight.",
    Values = State.Functions.Quest.getSpecialList(),
    Callback = function(selected)
        State.CurrentSpecialQuest = selected
        print("[MemSea] Selected special quest: " .. selected)
    end
})

SpecialQuestSection:AddToggle("AutoSpecialQuest", {
    Title = "Enable Auto Special Quest",
    Default = getDefault("AutoSpecialQuest", false),
    Description = "Auto-farm selected Boss/Raid/SpecialQuest with auto quest.",
    Callback = function(value)
        State.Toggles.AutoSpecialQuest = value

        if value then
            -- Check if target is selected
            if not State.CurrentSpecialQuest or State.CurrentSpecialQuest == "" then
                GG.CommonF:Notify("Auto Special Quest", "Please select a target first!", 3)
                State.Toggles.AutoSpecialQuest = false
                return
            end

            -- Set target to special quest selection
            State.CurrentTargetSelected = State.CurrentSpecialQuest

            -- Enable AutoQuest + AutoFarm
            State.Toggles.AutoQuest = true
            State.Toggles.AutoFarm = true

            -- Disable conflicting toggles
            State.Toggles.AutoLevel = false

            print("[MemSea] AutoSpecialQuest: Target = " .. State.CurrentSpecialQuest)

            -- Start quest management + farming loop
            State.Functions.Quest.autoQuest(true)
            -- State.Functions.Farming.runFarmLoop()

            GG.CommonF:Notify("Auto Special Quest", "Farming: " .. State.CurrentSpecialQuest, 5)
        else
            -- Stop farm threads
            GG.CommonF:Threads("TeleportThread", false, nil)
            State.Functions.Teleport.stopStabilize()
            print("[MemSea] AutoSpecialQuest: Disabled")
        end
    end
})

------------- AUTO RAID SECTION -------------
local AutoRaidSection = Tabs.Main:AddSection("Auto Raid")

AutoRaidSection:AddDropdown("RaidTargetDropdown", {
    Title = "Select Raid Target",
    Default = "",
    Description = "Choose the raid you want to complete.",
    Values = State.Functions.Quest.getRaidsList(),
    Callback = function(selected)
        State.CurrentRaid = selected
        print("[MemSea] Selected raid: " .. selected)
    end
})

AutoRaidSection:AddToggle("AutoRaid", {
    Title = "Enable Auto Raid",
    Default = getDefault("AutoRaid", false),
    Description = "Automatically completes the selected raid.",
    Callback = function(value)
        if value and State.Toggles.AutoLevel then
            GG.CommonF:Notify("Auto Raid", "Disabled - AutoLevel is running", 3)
            Options['AutoRaid']:SetValue(false)
            return
        end
        State.Toggles.AutoRaid = value
        print("[MemSea] Auto Raid: " .. tostring(value))
    end
})

------------- NOCLIP FUNCTIONS -------------
State.NoclipConnection = nil

function State.Functions.Misc.setNoclip(enabled)
    -- Disconnect existing connection
    if State.NoclipConnection then
        State.NoclipConnection:Disconnect()
        State.NoclipConnection = nil
    end

    if enabled then
        -- Start noclip loop
        State.NoclipConnection = GG.H.Stepped:Connect(function()
            if GG.selc then
                for _, child in pairs(GG.selc:GetDescendants()) do
                    if child:IsA("BasePart") and child.CanCollide and child.Name ~= "FloatPart" then
                        child.CanCollide = false
                    end
                end
            end
        end)
        GG.CommonF:Notify("Noclip", "Noclip Enabled", 3)
    else
        -- Restore CanCollide
        if GG.selc then
            for _, child in pairs(GG.selc:GetDescendants()) do
                if child:IsA("BasePart") and child.Name ~= "FloatPart" then
                    child.CanCollide = true
                end
            end
        end
        GG.CommonF:Notify("Noclip", "Noclip Disabled", 3)
    end
end

------------- MISC TAB CONTROLS -------------

-- Noclip Section
local NoclipSection = Tabs.Misc:AddSection("Player")

NoclipSection:AddToggle("Noclip", {
    Title = "Enable Noclip",
    Default = getDefault("Noclip", false),
    Description = "Walk through walls and objects.",
    Callback = function(value)
        State.Functions.Misc.setNoclip(value)
    end
})

-- NPC Categories (from W.NPCs children)
local NPCCategories = {
    "AbilityTrainer_Npc",
    "BoatSpawner_Npc",
    "FightingStyle_Npc",
    "Misc_Npc",
    "Quests_Npc",
    "SetSpawn_Npc",
    "Shop_Npc"
}

-- NPC Storage reference
local NPC_Storage = GG.R:FindFirstChild("NPC_Storage")

-- Get NPCs by category (filter by Old_Parent attribute)
local function getNPCsByCategory(categoryName)
    local npcs = {}
    if not NPC_Storage then return npcs end

    for _, npc in pairs(NPC_Storage:GetChildren()) do
        if npc:IsA("Model") then
            local oldParent = npc:GetAttribute("Old_Parent")
            if oldParent == categoryName then
                table.insert(npcs, npc.Name)
            end
        end
    end

    return npcs
end

-- Store current selection
State.MiscNPC = {
    Category = nil,
    NPC = nil
}

-- NPC Teleport Section
local NPCTeleportSection = Tabs.Misc:AddSection("NPC Teleport")

-- Category Dropdown
NPCTeleportSection:AddDropdown("NPCCategoryDropdown", {
    Title = "Select NPC Category",
    Default = "",
    Description = "Choose the NPC category.",
    Values = NPCCategories,
    Callback = function(selected)
        State.MiscNPC.Category = selected
        State.MiscNPC.NPC = nil

        -- Update NPC dropdown with NPCs from this category
        local npcs = getNPCsByCategory(selected)
        Options['NPCDropdown']:SetValues(npcs)
        if #npcs > 0 then
            Options['NPCDropdown']:SetValue("")
        end
    end
})

-- NPC Dropdown (populated based on category)
NPCTeleportSection:AddDropdown("NPCDropdown", {
    Title = "Select NPC",
    Default = "",
    Description = "Choose the NPC to teleport to.",
    Values = {},
    Callback = function(selected)
        State.MiscNPC.NPC = selected
    end
})

-- Teleport Button
NPCTeleportSection:AddButton({
    Title = "Teleport to NPC",
    Description = "Teleport to the selected NPC.",
    Callback = function()
        local category = State.MiscNPC.Category
        local npcName = State.MiscNPC.NPC

        if not category or category == "" then
            GG.CommonF:Notify("Misc", "Please select a category first!", 3)
            return
        end

        if not npcName or npcName == "" then
            GG.CommonF:Notify("Misc", "Please select an NPC first!", 3)
            return
        end

        -- Try to find NPC in W first
        local npcsFolder = GG.W:FindFirstChild("NPCs")
        local targetNPC = nil

        if npcsFolder then
            local categoryFolder = npcsFolder:FindFirstChild(category)
            if categoryFolder then
                targetNPC = categoryFolder:FindFirstChild(npcName)
            end
        end

        -- If not in W, check NPC_Storage
        if not targetNPC and NPC_Storage then
            targetNPC = NPC_Storage:FindFirstChild(npcName)
        end

        if targetNPC then
            local targetPart, _ = GG.rootHum(targetNPC)
            if targetPart then
                GG.CommonF:TpAL(targetPart.CFrame, 0.05)
                GG.CommonF:Notify("Misc", "Teleported to " .. npcName, 3)
            else
                GG.CommonF:Notify("Misc", "NPC has no HumanoidRootPart!", 3)
            end
        else
            GG.CommonF:Notify("Misc", "NPC not found: " .. npcName, 3)
        end
    end
})

------------- SETTINGS TAB CONTROLS -------------
-- Addons:
-- SaveManager (Allows you to have a configuration system)
-- InterfaceManager (Allows you to have a interface managment system)
SaveManager:SetLibrary(Fluent)
InterfaceManager:SetLibrary(Fluent)

SaveManager:IgnoreThemeSettings()

SaveManager:SetIgnoreIndexes({})

InterfaceManager:SetFolder("MaouHub")
SaveManager:SetFolder("MaouHub/" .. (GG.GameId or GG.PlaceId))

InterfaceManager:BuildInterfaceSection(Tabs.Settings)
SaveManager:BuildConfigSection(Tabs.Settings)

Window:SelectTab(1)

Fluent:Notify({
    Title = "MemSea Hub",
    Content = "The script has been loaded.",
    Duration = 8
})

SaveManager:LoadAutoloadConfig()
