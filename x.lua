--[[
    Residence Massacre Spirit Helper (Delta Full)
    - draggable UI + toggles + status bar
    - auto alarm/radio off | auto bear | auto lamp | nightvision
    - monster alert (notify+text) | ESP (monster+player) | noclip | simple fly
    - no audio errors / syntax checked
]]

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local Lighting = game:GetService("Lighting")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local StarterGui = game:GetService("StarterGui")

local LP = Players.LocalPlayer
local PG = LP:WaitForChild("PlayerGui")

-- anti double-load
if PG:FindFirstChild("SpiritHelper") then
    PG.SpiritHelper:Destroy()
end

local CFG = {
    Alarm = true,
    Bear = true,
    Lamp = true,
    NightVision = true,
    MonsterAlert = true,
    MonsterAlertESP = true,
    PlayerESP = false,
    Noclip = false,
    Fly = false,
}

local SG = Instance.new("ScreenGui")
SG.Name = "SpiritHelper"
SG.Parent = PG
SG.ResetOnSpawn = false

-- main panel
local F = Instance.new("Frame")
F.Size = UDim2.new(0, 200, 0, 340)
F.Position = UDim2.new(0, 10, 0, 10)
F.BackgroundColor3 = Color3.fromRGB(20, 20, 28)
F.BorderSizePixel = 0
F.Active = true
F.Draggable = true
F.Parent = SG
local UC = Instance.new("UICorner")
UC.CornerRadius = UDim.new(0, 8)
UC.Parent = F

-- title
local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, 0, 0, 26)
Title.Text = "Spirit Helper [drag]"
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.BackgroundColor3 = Color3.fromRGB(45, 45, 60)
Title.Font = Enum.Font.SourceSansBold
Title.TextSize = 15
Title.Parent = F
local TC = Instance.new("UICorner")
TC.CornerRadius = UDim.new(0, 8)
TC.Parent = Title

-- status bar
local ST = Instance.new("TextLabel")
ST.Position = UDim2.new(0, 6, 0, 300)
ST.Size = UDim2.new(1, -12, 0, 36)
ST.Text = "Loading..."
ST.TextColor3 = Color3.fromRGB(120, 255, 120)
ST.BackgroundTransparency = 1
ST.Font = Enum.Font.SourceSans
ST.TextSize = 12
ST.TextWrapped = true
ST.TextXAlignment = Enum.TextXAlignment.Left
ST.Parent = F

-- button factory
local Y = 30
local function AddButton(text, key)
    local btn = Instance.new("TextButton")
    btn.Position = UDim2.new(0, 8, 0, Y)
    btn.Size = UDim2.new(1, -16, 0, 26)
    btn.Text = text .. ": ON"
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.BackgroundColor3 = Color3.fromRGB(55, 55, 70)
    btn.Font = Enum.Font.SourceSans
    btn.TextSize = 13
    btn.Parent = F
    local BC = Instance.new("UICorner")
    BC.CornerRadius = UDim.new(0, 6)
    BC.Parent = btn

    local function Refresh()
        btn.Text = text .. ": " .. (CFG[key] and "ON" or "OFF")
        btn.BackgroundColor3 = CFG[key] and Color3.fromRGB(60, 120, 60) or Color3.fromRGB(55, 55, 70)
    end
    Refresh()

    btn.MouseButton1Click:Connect(function()
        CFG[key] = not CFG[key]
        Refresh()
    end)
    return Refresh
end

local RefreshAlarm = AddButton("Auto Alarm Off", "Alarm")
local RefreshBear = AddButton("Auto Pet Bear", "Bear")
local RefreshLamp = AddButton("Auto Lamp On", "Lamp")
local RefreshNightVision = AddButton("NightVision", "NightVision")
local RefreshMonsterAlert = AddButton("Monster Alert", "MonsterAlert")
local RefreshMonsterAlertESP = AddButton("Monster ESP", "MonsterAlertESP")
local RefreshPlayerESP = AddButton("Player ESP", "PlayerESP")
local RefreshNoclip = AddButton("Noclip", "Noclip")
local RefreshFly = AddButton("Fly", "Fly")

local function SetStatus(msg)
    pcall(function()
        ST.Text = msg
    end)
end

-- util: safely trigger interactions
local function TryInteract(root)
    local prompt = root:FindFirstChildOfClass("ProximityPrompt")
    if prompt then
        pcall(function() fireproximityprompt(prompt) end)
    end
    local click = root:FindFirstChildOfClass("ClickDetector")
    if click then
        pcall(function() fireclickdetector(click) end)
    end
end

-- main loop: auto interact
task.spawn(function()
    while true do
        task.wait(0.8)
        pcall(function()
            if CFG.Alarm then
                for _, V in ipairs(Workspace:GetDescendants()) do
                    local N = V.Name:lower()
                    if N:find("alarm") or N:find("clock") or N:find("radio") then
                        TryInteract(V)
                        if V:IsA("Sound") and V.Playing then
                            pcall(function() V:Stop() end)
                        end
                        local childSound = V:FindFirstChildOfClass("Sound")
                        if childSound and childSound.Playing then
                            pcall(function() childSound:Stop() end)
                        end
                    end
                end
            end

            if CFG.Bear then
                for _, V in ipairs(Workspace:GetDescendants()) do
                    local N = V.Name:lower()
                    if N:find("teddy") or N:find("bear") then
                        TryInteract(V)
                    end
                end
            end

            if CFG.Lamp then
                for _, V in ipairs(Workspace:GetDescendants()) do
                    local N = V.Name:lower()
                    if N:find("lamp") or N:find("lightswitch") or N:find("switch") then
                        TryInteract(V)
                    end
                end
            end

            if CFG.NightVision then
                Lighting.Brightness = 2.5
                Lighting.ClockTime = 12
                Lighting.FogEnd = 99999
                Lighting.GlobalShadows = false
            end

            if CFG.Noclip then
                for _, V in ipairs(Workspace:GetDescendants()) do
                    if V:IsA("BasePart") and V.CanCollide then
                        local parentModel = V.Parent
                        local hasHumanoid = parentModel and parentModel:FindFirstChildWhichIsA("Humanoid")
                        if not hasHumanoid then
                            V.CanCollide = false
                        end
                    end
                end
            end
        end)
    end
end)

-- monster detect + alert
task.spawn(function()
    local lastCount = 0
    while true do
        task.wait(1)
        if CFG.MonsterAlert then

        local monsterCount = 0
        local nearPlayer = false
        local char = LP.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")

        if hrp then
            for _, V in ipairs(Workspace:GetDescendants()) do
                local N = V.Name:lower()
                if N:find("pest") or N:find("anomaly") or N:find("monster") or N:find("barry") or N:find("entity") then
                    monsterCount = monsterCount + 1
                    local part = V
                    if V:IsA("Model") then
                        part = V.PrimaryPart or V:FindFirstChild("HumanoidRootPart") or V:FindFirstChild("Head") or V:FindFirstChildWhichIsA("BasePart")
                    end
                    if part and (hrp.Position - part.Position).Magnitude < 50 then
                        nearPlayer = true
                    end
                end
            end
        end

        if monsterCount > 0 and monsterCount ~= lastCount then
            local msg = nearPlayer and "Monster NEAR! Hide!" or ("Monsters: " .. monsterCount)
            pcall(function()
                StarterGui:SetCore("SendNotification", {
                    Title = "Spirit Helper",
                    Text = msg,
                    Duration = 3,
                })
            end)
            SetStatus(msg)
        end
        lastCount = monsterCount

        end -- if CFG.MonsterAlert
    end
end)

-- generic ESP
local function ApplyESP(target, color)
    if not target then return end
    if target:FindFirstChild("ESP") then return end

    local adornment = Instance.new("BoxHandleAdornment")
    adornment.Name = "ESP"
    adornment.Adornee = target
    adornment.Size = target.Size + Vector3.new(1, 1, 1)
    adornment.Color3 = color
    adornment.Transparency = 0.4
    adornment.AlwaysOnTop = true
    adornment.ZIndex = 10
    adornment.Parent = target
end

task.spawn(function()
    while true do
        task.wait(2)
        pcall(function()
            if CFG.MonsterAlertESP then
                for _, V in ipairs(Workspace:GetDescendants()) do
                    local N = V.Name:lower()
                    if N:find("pest") or N:find("anomaly") or N:find("monster") or N:find("barry") then
                        local part = V
                        if V:IsA("Model") then
                            part = V.PrimaryPart or V:FindFirstChild("HumanoidRootPart") or V:FindFirstChild("Head")
                        end
                        if part then
                            ApplyESP(part, Color3.fromRGB(255, 50, 50))
                        end
                    end
                end
            end

            if CFG.PlayerESP then
                for _, plr in ipairs(Players:GetPlayers()) do
                    if plr ~= LP and plr.Character then
                        local root = plr.Character:FindFirstChild("HumanoidRootPart") or plr.Character:FindFirstChild("Head")
                        if root then
                            ApplyESP(root, Color3.fromRGB(50, 150, 255))
                        end
                    end
                end
            end
        end)
    end
end)

-- fly control
local BV
local function EnsureBodyVelocity()
    local char = LP.Character
    if not char then return nil end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return nil end
    if not BV or not BV.Parent then
        BV = Instance.new("BodyVelocity")
        BV.MaxForce = Vector3.new(1e5, 1e5, 1e5)
        BV.Velocity = Vector3.new(0, 0, 0)
        BV.Parent = hrp
    end
    return BV
end

task.spawn(function()
    local speed = 60
    while true do
        task.wait()
  
