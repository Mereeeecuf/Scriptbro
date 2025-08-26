--// Merebennie Custom Stick Dash (Delta Mobile Compatible)
-- UI overhaul: cleaner, modern, draggable UI + info panel and reopen button
-- DO NOT CHANGE GAME LOGIC: only UI improvements. All timings and logic preserved.
-- Modified: TRIGGER_COOLDOWN = 0.35 (kept from your last request)

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer

-- runtime vars that will be updated on respawn
local Character, Humanoid, HumanoidRootPart

-- original quick debounce kept (adjusted)
local lastTrigger = 0
local TRIGGER_COOLDOWN = 0.35 -- changed to 0.35

-- UI / feature controls
local enabled = true -- UI On/Off (default ON)
local uiOnCooldown = false
local COOLDOWN_DURATION = 7.2 -- unchanged visual/functional cooldown

-- immobilization extension after script completes (in seconds)
local IMMOB_EXTRA_AFTER = 0.3

-- === Utility: find nearest player or npc (unchanged) ===
local function getNearestTarget()
    local nearest, dist = nil, math.huge
    for _, v in pairs(workspace:GetDescendants()) do
        if v:IsA("Model") and v:FindFirstChild("HumanoidRootPart") and v ~= Character then
            local ok, mag = pcall(function()
                return (HumanoidRootPart.Position - v.HumanoidRootPart.Position).Magnitude
            end)
            if ok and mag and mag < dist then
                dist = mag
                nearest = v
            end
        end
    end
    return nearest
end

-- === FireServer Q logic (kept; just adds +0.1s before Q) ===
local function fireQ()
    -- Added per request: extra 0.1s before activating Q
    task.delay(0.1, function()
        pcall(function()
            local args = {
                [1] = {
                    ["Dash"] = Enum.KeyCode.W,
                    ["Key"] = Enum.KeyCode.Q,
                    ["Goal"] = "KeyPress"
                }
            }
            if Character and Character:FindFirstChild("Communicate") then
                Character.Communicate:FireServer(unpack(args))
            end
        end)
    end)

    -- your getNil logic (executor-specific)
    local function getNil(name, class)
        for _, v in pairs(getnilinstances()) do
            if v.ClassName == class and v.Name == name then
                return v
            end
        end
    end

    pcall(function()
        local args2 = {
            [1] = {
                ["Goal"] = "delete bv",
                ["BV"] = getNil("moveme", "BodyVelocity")
            }
        }
        if Character and Character:FindFirstChild("Communicate") then
            Character.Communicate:FireServer(unpack(args2))
        end
    end)
end

-- === Main stick dash (modified: immobilize while active + extra 0.3s) ===
local function stickDash()
    if not (Character and Humanoid and HumanoidRootPart) then return end

    local target = getNearestTarget()
    if not target then return end

    local targetHRP = target:FindFirstChild("HumanoidRootPart")
    if not targetHRP then return end

    -- save movement state so we can restore later
    local saved = {}
    pcall(function()
        saved.WalkSpeed = Humanoid.WalkSpeed
        saved.JumpPower = Humanoid.JumpPower
        saved.PlatformStand = Humanoid.PlatformStand
        -- some games use AutoRotate; save/restore if present
        if Humanoid:GetAttribute("AutoRotate") == nil then
            -- Humanoid.AutoRotate may not be available in all contexts; wrap safely
            pcall(function() saved.AutoRotate = Humanoid.AutoRotate end)
        else
            saved.AutoRotate = Humanoid.AutoRotate
        end
    end)

    -- remove common body movers to reduce being pushed by skills, then zero velocity each frame
    local antiConn
    local function startImmobilize()
        if not Humanoid or not HumanoidRootPart or not Character then return end
        pcall(function()
            Humanoid.WalkSpeed = 0
            Humanoid.JumpPower = 0
            Humanoid.PlatformStand = true
            pcall(function() Humanoid.AutoRotate = false end)
            if HumanoidRootPart then
                HumanoidRootPart.Velocity = Vector3.new(0,0,0)
                HumanoidRootPart.RotVelocity = Vector3.new(0,0,0)
            end
        end)

        -- destroy common mover objects that may be applied by scripts/skills
        for _, v in pairs(Character:GetDescendants()) do
            local class = v.ClassName
            if class == "BodyVelocity" or class == "BodyPosition" or class == "BodyGyro" or class == "VectorForce" or class == "AlignPosition" or class == "AlignOrientation" or class == "LinearVelocity" or class == "AngularVelocity" then
                pcall(function() v:Destroy() end)
            end
        end

        -- heartbeat zeroing to resist forces applied while immobilized
        antiConn = RunService.Heartbeat:Connect(function()
            if HumanoidRootPart then
                pcall(function()
                    HumanoidRootPart.Velocity = Vector3.new(0,0,0)
                    HumanoidRootPart.RotVelocity = Vector3.new(0,0,0)
                end)
            end
            -- ensure WalkSpeed stays zero in case something resets it
            if Humanoid and Humanoid.WalkSpeed then
                pcall(function() Humanoid.WalkSpeed = 0 end)
            end
        end)
    end

    local function stopImmobilize()
        if antiConn and antiConn.Disconnect then
            pcall(function() antiConn:Disconnect() end)
        end
        pcall(function()
            if Humanoid then
                Humanoid.WalkSpeed = saved.WalkSpeed or 16
                Humanoid.JumpPower = saved.JumpPower or 50
                Humanoid.PlatformStand = saved.PlatformStand or false
                if saved.AutoRotate ~= nil then pcall(function() Humanoid.AutoRotate = saved.AutoRotate end) end
            end
            if HumanoidRootPart then
                pcall(function()
                    HumanoidRootPart.Velocity = Vector3.new(0,0,0)
                    HumanoidRootPart.RotVelocity = Vector3.new(0,0,0)
                end)
            end
        end)
    end

    -- start immobilize right away (only while this stickDash is active)
    startImmobilize()

    -- put humanoid into physics state so animation/tweening behaves as before
    pcall(function()
        Humanoid:ChangeState(Enum.HumanoidStateType.Physics)
    end)
    HumanoidRootPart.CFrame = HumanoidRootPart.CFrame * CFrame.Angles(math.rad(85), 0, 0)

    local startTime = tick()
    local connection
    connection = RunService.Heartbeat:Connect(function()
        local elapsed = tick() - startTime
        if elapsed >= 0.7 then
            connection:Disconnect()
            return
        end
        local success, newCFrame = pcall(function()
            return CFrame.new(targetHRP.Position - targetHRP.CFrame.LookVector * 0.3) * CFrame.Angles(math.rad(85), 0, 0)
        end)
        if success and newCFrame then
            HumanoidRootPart.CFrame = newCFrame
        end
    end)

    -- original 0.18 laydown delay (unchanged) -> fireQ after laydown window
    task.delay(0.18, function()
        pcall(fireQ)
    end)

    -- original 0.3 stand-up timing (unchanged)
    task.delay(0.3, function()
        pcall(function()
            Humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
        end)
    end)

    -- stop immobilizing after the movement window (0.7s) + extra requested 0.3s
    local totalImmobilize = 0.7 + IMMOB_EXTRA_AFTER
    task.delay(totalImmobilize, function()
        pcall(stopImmobilize)
    end)
end

-- === Polished GUI creation (CoreGui so it persists) ===
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "Merebennie_StickDashGui"
ScreenGui.Parent = game:GetService("CoreGui")
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.Enabled = true

-- container
local UIContainer = Instance.new("Frame")
UIContainer.Name = "MerebennieContainer"
UIContainer.Size = UDim2.new(0, 340, 0, 150)
UIContainer.Position = UDim2.new(0.03, 0, 0.78, 0)
UIContainer.AnchorPoint = Vector2.new(0, 0)
UIContainer.BackgroundTransparency = 0
UIContainer.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
UIContainer.Parent = ScreenGui
UIContainer.ZIndex = 9999

local containerCorner = Instance.new("UICorner", UIContainer)
containerCorner.CornerRadius = UDim.new(0, 12)

local containerStroke = Instance.new("UIStroke", UIContainer)
containerStroke.Thickness = 1
containerStroke.Transparency = 0.6

local containerGradient = Instance.new("UIGradient", UIContainer)
containerGradient.Color = ColorSequence.new{
    ColorSequenceKeypoint.new(0, Color3.fromRGB(34,34,34)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(26,26,26))
}
containerGradient.Rotation = 90

-- header (draggable)
local Header = Instance.new("Frame")
Header.Name = "Header"
Header.Size = UDim2.new(1, 0, 0, 34)
Header.Position = UDim2.new(0, 0, 0, 0)
Header.BackgroundTransparency = 1
Header.Parent = UIContainer
Header.ZIndex = 10000

local Title = Instance.new("TextLabel")
Title.Name = "Title"
Title.Size = UDim2.new(0.8, -8, 1, 0)
Title.Position = UDim2.new(0, 12, 0, 0)
Title.BackgroundTransparency = 1
Title.Font = Enum.Font.GothamBold
Title.TextSize = 16
Title.Text = "Merebennie — Stick Dash"
Title.TextColor3 = Color3.fromRGB(235,235,235)
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.Parent = Header
Title.ZIndex = 10001

-- small subtitle
local Sub = Instance.new("TextLabel")
Sub.Name = "Sub"
Sub.Size = UDim2.new(0.7, -8, 0, 18)
Sub.Position = UDim2.new(0, 12, 0, 18)
Sub.BackgroundTransparency = 1
Sub.Font = Enum.Font.Gotham
Sub.TextSize = 11
Sub.Text = "Blue toggle: ON / OFF · Cooldown shows below"
Sub.TextColor3 = Color3.fromRGB(170,170,170)
Sub.TextXAlignment = Enum.TextXAlignment.Left
Sub.Parent = Header
Sub.ZIndex = 10001

-- close button (hides UI) and reopen small button
local CloseBtn = Instance.new("TextButton")
CloseBtn.Name = "CloseBtn"
CloseBtn.Size = UDim2.new(0, 28, 0, 24)
CloseBtn.Position = UDim2.new(1, -36, 0, 6)
CloseBtn.BackgroundColor3 = Color3.fromRGB(200, 60, 60)
CloseBtn.Text = "x"
CloseBtn.Font = Enum.Font.GothamBold
CloseBtn.TextSize = 16
CloseBtn.TextColor3 = Color3.new(1,1,1)
CloseBtn.Parent = Header
CloseBtn.ZIndex = 10002
local closeCorner = Instance.new("UICorner", CloseBtn)
closeCorner.CornerRadius = UDim.new(0, 6)

-- Reopen small floating button (hidden by default)
local ReopenBtn = Instance.new("TextButton")
ReopenBtn.Name = "ReopenBtn"
ReopenBtn.Size = UDim2.new(0, 36, 0, 36)
ReopenBtn.Position = UDim2.new(0.01, 0, 0.8, 0)
ReopenBtn.BackgroundColor3 = Color3.fromRGB(30,136,229)
ReopenBtn.Text = "M"
ReopenBtn.Font = Enum.Font.GothamBold
ReopenBtn.TextSize = 16
ReopenBtn.TextColor3 = Color3.new(1,1,1)
ReopenBtn.Parent = ScreenGui
ReopenBtn.ZIndex = 9998
ReopenBtn.Visible = false
local reopenCorner = Instance.new("UICorner", ReopenBtn)
reopenCorner.CornerRadius = UDim.new(0, 12)

-- toggle button (primary control)
local ToggleBtn = Instance.new("TextButton")
ToggleBtn.Name = "ToggleBtn"
ToggleBtn.Size = UDim2.new(0, 92, 0, 36)
ToggleBtn.Position = UDim2.new(0.6, 0, 0.12, 0)
ToggleBtn.BackgroundColor3 = Color3.fromRGB(30, 136, 229)
ToggleBtn.Font = Enum.Font.GothamBold
ToggleBtn.TextSize = 14
ToggleBtn.Text = "On"
ToggleBtn.TextColor3 = Color3.new(1,1,1)
ToggleBtn.Parent = UIContainer
ToggleBtn.ZIndex = 10001
local toggleCorner = Instance.new("UICorner", ToggleBtn)
toggleCorner.CornerRadius = UDim.new(0, 10)
local toggleStroke = Instance.new("UIStroke", ToggleBtn)
toggleStroke.Thickness = 1
toggleStroke.Transparency = 0.35

-- cooldown progress bar + label
local CooldownBarBg = Instance.new("Frame")
CooldownBarBg.Name = "CooldownBarBg"
CooldownBarBg.Size = UDim2.new(0.92, 0, 0, 12)
CooldownBarBg.Position = UDim2.new(0.04, 0, 0.6, 0)
CooldownBarBg.BackgroundColor3 = Color3.fromRGB(50,50,50)
CooldownBarBg.BackgroundTransparency = 0
CooldownBarBg.Parent = UIContainer
CooldownBarBg.ZIndex = 10000
local cdBgCorner = Instance.new("UICorner", CooldownBarBg)
cdBgCorner.CornerRadius = UDim.new(0, 6)

local CooldownFill = Instance.new("Frame")
CooldownFill.Name = "CooldownFill"
CooldownFill.Size = UDim2.new(0, 0, 1, 0)
CooldownFill.Position = UDim2.new(0, 0, 0, 0)
CooldownFill.BackgroundColor3 = Color3.fromRGB(30,136,229)
CooldownFill.Parent = CooldownBarBg
CooldownFill.ZIndex = 10001
local cdFillCorner = Instance.new("UICorner", CooldownFill)
cdFillCorner.CornerRadius = UDim.new(0, 6)

local CooldownLabel = Instance.new("TextLabel")
CooldownLabel.Name = "CooldownLabel"
CooldownLabel.Size = UDim2.new(1, 0, 0, 18)
CooldownLabel.Position = UDim2.new(0, 0, 0.72, 0)
CooldownLabel.BackgroundTransparency = 1
CooldownLabel.Font = Enum.Font.GothamBold
CooldownLabel.TextSize = 12
CooldownLabel.Text = "Ready"
CooldownLabel.TextColor3 = Color3.fromRGB(200,200,200)
CooldownLabel.Parent = UIContainer
CooldownLabel.ZIndex = 10001

-- info panel (smaller, sleek)
local InfoPanel = Instance.new("Frame")
InfoPanel.Name = "InfoPanel"
InfoPanel.Size = UDim2.new(0, 320, 0, 68)
InfoPanel.Position = UDim2.new(0.02, 0, 0.28, 0)
InfoPanel.BackgroundTransparency = 0
InfoPanel.BackgroundColor3 = Color3.fromRGB(245,245,245)
InfoPanel.Parent = UIContainer
InfoPanel.ZIndex = 10000
local infoCorner = Instance.new("UICorner", InfoPanel)
infoCorner.CornerRadius = UDim.new(0, 10)
local infoStroke = Instance.new("UIStroke", InfoPanel)
infoStroke.Thickness = 1
infoStroke.Transparency = 0.7

local InfoTitle = Instance.new("TextLabel")
InfoTitle.Name = "InfoTitle"
InfoTitle.Size = UDim2.new(1, -16, 0, 20)
InfoTitle.Position = UDim2.new(0, 8, 0, 6)
InfoTitle.BackgroundTransparency = 1
InfoTitle.Font = Enum.Font.GothamBold
InfoTitle.TextSize = 13
InfoTitle.Text = "Made by Merebennie"
InfoTitle.TextColor3 = Color3.fromRGB(20,20,20)
InfoTitle.TextXAlignment = Enum.TextXAlignment.Left
InfoTitle.Parent = InfoPanel

local InfoDesc = Instance.new("TextLabel")
InfoDesc.Name = "InfoDesc"
InfoDesc.Size = UDim2.new(1, -16, 0, 28)
InfoDesc.Position = UDim2.new(0, 8, 0, 26)
InfoDesc.BackgroundTransparency = 1
InfoDesc.Font = Enum.Font.Gotham
InfoDesc.TextSize = 12
InfoDesc.Text = "Join our Discord for more scripts. Copy invite or open it."
InfoDesc.TextColor3 = Color3.fromRGB(60,60,60)
InfoDesc.TextWrapped = true
InfoDesc.TextXAlignment = Enum.TextXAlignment.Left
InfoDesc.Parent = InfoPanel

local INVITE_URL = "https://discord.gg/5x4xbPvuSc"

local CopyBtn = Instance.new("TextButton")
CopyBtn.Name = "CopyBtn"
CopyBtn.Size = UDim2.new(0, 90, 0, 28)
CopyBtn.Position = UDim2.new(0.02, 0, 0.55, 0)
CopyBtn.BackgroundColor3 = Color3.fromRGB(30,136,229)
CopyBtn.Font = Enum.Font.GothamBold
CopyBtn.TextSize = 13
CopyBtn.Text = "Copy Invite"
CopyBtn.TextColor3 = Color3.new(1,1,1)
CopyBtn.Parent = InfoPanel
local copyCorner = Instance.new("UICorner", CopyBtn)
copyCorner.CornerRadius = UDim.new(0, 8)
local CopyFeedback = Instance.new("TextLabel")
CopyFeedback.Name = "CopyFeedback"
CopyFeedback.Size = UDim2.new(0, 200, 0, 18)
CopyFeedback.Position = UDim2.new(0.33, 0, 0.56, 0)
CopyFeedback.BackgroundTransparency = 1
CopyFeedback.Font = Enum.Font.Gotham
CopyFeedback.TextSize = 12
CopyFeedback.Text = ""
CopyFeedback.TextColor3 = Color3.fromRGB(20,150,20)
CopyFeedback.Visible = false
CopyFeedback.Parent = InfoPanel

-- drag behavior for UIContainer (drag header)
do
    local dragging, dragInput, dragStart, startPos
    Header.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = UIContainer.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)

    Header.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging and startPos then
            local delta = input.Position - dragStart
            UIContainer.Position = UDim2.new(
                startPos.X.Scale,
                startPos.X.Offset + delta.X,
                startPos.Y.Scale,
                startPos.Y.Offset + delta.Y
            )
        end
    end)
end

-- Close/hide and reopen behavior
CloseBtn.MouseButton1Click:Connect(function()
    pcall(function()
        UIContainer.Visible = false
        ReopenBtn.Visible = true
    end)
end)
ReopenBtn.MouseButton1Click:Connect(function()
    pcall(function()
        UIContainer.Visible = true
        ReopenBtn.Visible = false
    end)
end)

-- Toggle logic (no timing/behavior changed)
ToggleBtn.MouseButton1Click:Connect(function()
    enabled = not enabled
    if enabled then
        ToggleBtn.Text = "On"
        TweenService:Create(ToggleBtn, TweenInfo.new(0.18), {BackgroundColor3 = Color3.fromRGB(30,136,229)}):Play()
    else
        ToggleBtn.Text = "Off"
        TweenService:Create(ToggleBtn, TweenInfo.new(0.18), {BackgroundColor3 = Color3.fromRGB(90,90,90)}):Play()
    end
end)

-- Cooldown UI updater (keeps original startUICooldown logic but with nicer visuals)
local cooldownTween
local function startUICooldown(duration)
    if uiOnCooldown then return end
    uiOnCooldown = true
    CooldownLabel.Text = string.format("%.1fs", duration)
    CooldownFill.Size = UDim2.new(1, 0, 1, 0) -- full, then we'll animate down
    local startTime = tick()
    while tick() - startTime < duration do
        local remaining = duration - (tick() - startTime)
        if remaining < 0 then remaining = 0 end
        CooldownLabel.Text = string.format("Cooldown: %.1fs", remaining)
        local frac = (duration - remaining) / duration
        CooldownFill.Size = UDim2.new(1 - frac, 0, 1, 0)
        task.wait(0.06)
    end
    CooldownFill.Size = UDim2.new(0, 0, 1, 0)
    uiOnCooldown = false
    CooldownLabel.Text = "Ready"
end

-- Copy button behavior (same approach as before)
CopyBtn.MouseButton1Click:Connect(function()
    local ok = false
    pcall(function()
        if setclipboard then
            setclipboard(INVITE_URL); ok = true
        elseif syn and syn.set_clipboard then
            syn.set_clipboard(INVITE_URL); ok = true
        elseif set_clipboard then
            set_clipboard(INVITE_URL); ok = true
        else
            pcall(function() _G.setclipboard and _G.setclipboard(INVITE_URL) end)
        end
    end)
    if ok then
        CopyFeedback.Text = "Copied to clipboard"
        CopyFeedback.TextColor3 = Color3.fromRGB(20,150,20)
        CopyFeedback.Visible = true
        task.delay(1.5, function() pcall(function() CopyFeedback.Visible = false end) end)
    else
        CopyFeedback.Text = "Copy not supported here. Invite: " .. INVITE_URL
        CopyFeedback.TextColor3 = Color3.fromRGB(160,60,60)
        CopyFeedback.Visible = true
        task.delay(3, function() pcall(function() CopyFeedback.Visible = false end) end)
    end
end)

-- === Character setup & animation detection (now blocks during cooldown) ===
local connections = {}

local function clearCharacterConnections()
    for _, conn in pairs(connections) do
        if conn and conn.Disconnect then
            pcall(function() conn:Disconnect() end)
        end
    end
    connections = {}
end

local function tryTrigger()
    -- Block if OFF or currently on the 7.2s cooldown
    if not enabled or uiOnCooldown then return end
    if tick() - lastTrigger >= TRIGGER_COOLDOWN then
        lastTrigger = tick()
        task.spawn(function() pcall(stickDash) end)
        task.spawn(function() startUICooldown(COOLDOWN_DURATION) end)
    end
end

local function onAnimationPlayed(track)
    if not track then return end
    local anim = track.Animation
    if not anim then return end
    local animId = tostring(anim.AnimationId or "")
    if string.find(animId, "10503381238", 1, true) then
        tryTrigger()
    end
end

local function setupCharacter(char)
    clearCharacterConnections()

    Character = char
    Humanoid = Character:FindFirstChildOfClass("Humanoid") or Character:WaitForChild("Humanoid", 5)
    HumanoidRootPart = Character:FindFirstChild("HumanoidRootPart") or Character:WaitForChild("HumanoidRootPart", 5)
    if not Humanoid or not HumanoidRootPart then return end

    local ok, conn = pcall(function()
        return Humanoid.AnimationPlayed:Connect(onAnimationPlayed)
    end)
    if ok and conn then table.insert(connections, conn) end

    local animator = Humanoid:FindFirstChildOfClass("Animator")
    if animator then
        local success, animConn = pcall(function()
            return animator.AnimationPlayed:Connect(onAnimationPlayed)
        end)
        if success and animConn then table.insert(connections, animConn) end
    end

    local descConn = Character.DescendantAdded:Connect(function(desc)
        if desc:IsA("Animation") then
            local aid = tostring(desc.AnimationId or "")
            if string.find(aid, "10503381238", 1, true) then
                tryTrigger()
            end
        end
    end)
    table.insert(connections, descConn)
end

LocalPlayer.CharacterAdded:Connect(function(char)
    task.wait(0.1)
    pcall(setupCharacter, char)
end)

if LocalPlayer.Character then
    pcall(setupCharacter, LocalPlayer.Character)
end

-- End of script
