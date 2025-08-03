--============================================================--
-- ⚡ Δ LAG CRUSHER 160Hz Ultra™ v4.3 HyperStable ⚡
-- Ultimate FPS Booster + Smooth 140Hz Motion Blur + Ultra Stable
-- No Shake + Mobile Optimized + Memory-Safe
-- Made by Merebennie
--============================================================--

-- Services
local Players      = game:GetService("Players")
local Workspace    = game:GetService("Workspace")
local Lighting     = game:GetService("Lighting")
local Content      = game:GetService("ContentProvider")
local SoundService = game:GetService("SoundService")
local RunService   = game:GetService("RunService")
local UIS          = game:GetService("UserInputService")
local LocalPlayer  = Players.LocalPlayer
local playerGui    = LocalPlayer:WaitForChild("PlayerGui")

-- ━━ UI SETUP ━━
local gui = Instance.new("ScreenGui")
gui.Name = "LagCrusherGUI"
gui.Parent = playerGui
gui.ResetOnSpawn = false
gui.DisplayOrder = 999

-- Watermark
local watermark = Instance.new("TextLabel", gui)
watermark.AnchorPoint = Vector2.new(0.5,0)
watermark.Position = UDim2.new(0.5,0,0,8)
watermark.Size = UDim2.new(0,180,0,20)
watermark.BackgroundTransparency = 1
watermark.Text = "Made by Merebennie"
watermark.Font = Enum.Font.Arcade
watermark.TextScaled = true
watermark.TextColor3 = Color3.new(1,1,1)
watermark.TextStrokeColor3 = Color3.new(0,0,0)
watermark.TextStrokeTransparency = 0

-- Status Label
local lbl = Instance.new("TextLabel", gui)
lbl.Position = UDim2.new(0,8,0,8)
lbl.Size = UDim2.new(0,180,0,20)
lbl.BackgroundColor3 = Color3.new(0,0,0)
lbl.BackgroundTransparency = 0.4
lbl.Font = Enum.Font.Arcade
lbl.TextSize = 14
lbl.Text = "Δ LagCrusher: OFF"
lbl.TextColor3 = Color3.new(1,1,1)
lbl.TextStrokeColor3 = Color3.new(0,0,0)
lbl.TextStrokeTransparency = 0

-- Toggle Button
local button = Instance.new("TextButton", gui)
button.AnchorPoint = Vector2.new(1,1)
button.Position = UDim2.new(1,-16,1,-16)
button.Size = UDim2.new(0,50,0,50)
button.BackgroundColor3 = Color3.fromRGB(120,120,120)
button.Font = Enum.Font.Arcade
button.Text = "Q"
button.TextScaled = true
button.TextColor3 = Color3.new(1,1,1)
button.TextStrokeColor3 = Color3.new(0,0,0)
button.TextStrokeTransparency = 0
local corner = Instance.new("UICorner", button)
corner.CornerRadius = UDim.new(0,8)

-- Dragging Logic
local dragging, startPos, startInput
button.InputBegan:Connect(function(input)
 if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
  dragging = true
  startPos = button.Position
  startInput = input.Position
  local conn; conn = input.Changed:Connect(function()
   if input.UserInputState == Enum.UserInputState.End then
    dragging = false
    conn:Disconnect()
   end
  end)
 end
end)
UIS.InputChanged:Connect(function(input)
 if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
  local delta = input.Position - startInput
  button.Position = UDim2.new(
   startPos.X.Scale, startPos.X.Offset + delta.X,
   startPos.Y.Scale, startPos.Y.Offset + delta.Y
  )
 end
end)

-- ━━ ULTRA OPTIMIZER ━━
local effectClasses = {
 "ParticleEmitter","Trail","Smoke","Fire","Beam","Sparkles","Explosion",
 "DepthOfFieldEffect","BlurEffect","SunRaysEffect","ColorCorrectionEffect",
 "BloomEffect","Atmosphere","Attachment","PostEffect","ViewportFrame"
}

local function ultraOptimize()
 pcall(function()
  local phys = settings().Physics
  phys.AllowSleep = true
  phys.ThrottleAdjustTime = 1/160
  phys.PhysicsEnvironmentalThrottle = Enum.EnviromentalPhysicsThrottle.Disabled
 end)
 pcall(function()
  UserSettings().GameSettings.SavedQualityLevel = 1
 end)

 -- Destroy heavy assets
 coroutine.wrap(function()
  for i,obj in ipairs(Workspace:GetDescendants()) do
   pcall(function()
    if obj:IsA("BasePart") then
     obj.Material = Enum.Material.Plastic
     obj.Reflectance = 0
     obj.CastShadow = false
     for _,d in ipairs(obj:GetDescendants()) do
      if d:IsA("Texture") or d:IsA("Decal") or d:IsA("MeshPart") or d:IsA("SpecialMesh") then
       d:Destroy()
      end
     end
    elseif obj:IsA("Sound") then
     obj.Playing = false
     obj.Looped = false
    else
     for _,cls in ipairs(effectClasses) do
      if obj:IsA(cls) then obj:Destroy(); break end
     end
    end
   end)
   if i % 150 == 0 then RunService.Heartbeat:Wait() end
  end
 end)()

 -- Lighting Optimization
 pcall(function()
  Lighting.GlobalShadows = false
  Lighting.Brightness = 0.05
  Lighting.OutdoorAmbient = Color3.new(0.01,0.01,0.01)
  Lighting.FogStart, Lighting.FogEnd = 0,5
  Lighting.EnvironmentDiffuseScale = 0
  Lighting.EnvironmentSpecularScale = 0
  Lighting.ClockTime = 12
 end)
 pcall(function()
  Workspace.StreamingEnabled = false
  Content:ClearRequests()
 end)
 pcall(function()
  SoundService.RespectFilteringEnabled = false
  SoundService.AmbientReverb = Enum.ReverbType.NoReverb
 end)
end

-- ━━ HyperStable 140Hz Blur ━━
local blur = Instance.new("BlurEffect", Lighting)
blur.Size = 0
local smoothFactor = 0.06
local maxBlur = 2.0
local lastRot = Workspace.CurrentCamera.CFrame.Rotation

local function onRender()
 local cam = Workspace.CurrentCamera
 local cf = cam.CFrame
 local rot = cf.Rotation
 local sm = lastRot:Lerp(rot, 1 - smoothFactor)
 cam.CFrame = CFrame.new(cf.Position) * sm -- No shake, only smooth
 local angle = math.acos(math.clamp(lastRot.LookVector:Dot(rot.LookVector),-1,1))
 blur.Size = (angle > 0.005) and math.min(angle*350,maxBlur) or 0
 lastRot = sm
end

-- ━━ TOGGLE ━━
local activated, conn = false, nil
button.MouseButton1Click:Connect(function()
 activated = not activated
 if activated then
  lbl.Text = "Δ LagCrusher: ON"
  button.BackgroundColor3 = Color3.fromRGB(200,50,50)
  ultraOptimize()
  conn = RunService.RenderStepped:Connect(onRender)
 else
  lbl.Text = "Δ LagCrusher: OFF"
  button.BackgroundColor3 = Color3.fromRGB(120,120,120)
  if con
n then conn:Disconnect(); conn = nil end
  blur.Size = 0
 end
end)

print("[Δ LagCrusher v4.3 HyperStable™] ✅ Loaded Ultra Stable & Smooth FPS Booster!")

Give me downloable version of this 