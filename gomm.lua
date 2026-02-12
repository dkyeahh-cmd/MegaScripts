local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer

local Net = ReplicatedStorage.Modules.Net
local RegisterAttack = Net:WaitForChild("RE/RegisterAttack")
local RegisterHit = Net:WaitForChild("RE/RegisterHit")

--================ GUI =================--

local gui = Instance.new("ScreenGui", LocalPlayer.PlayerGui)

local frame = Instance.new("Frame", gui)
frame.Size = UDim2.new(0,260,0,320)
frame.Position = UDim2.new(0.3,0,0.3,0)
frame.BackgroundColor3 = Color3.fromRGB(30,30,30)
frame.Active = true
frame.Draggable = true

local title = Instance.new("TextLabel", frame)
title.Size = UDim2.new(1,0,0,25)
title.Text = "MEGA COMBAT PANEL 😈"
title.BackgroundColor3 = Color3.fromRGB(20,20,20)
title.TextColor3 = Color3.new(1,1,1)

-- قائمة اللاعبين
local listFrame = Instance.new("ScrollingFrame", frame)
listFrame.Size = UDim2.new(1,-10,0,100)
listFrame.Position = UDim2.new(0,5,0,30)
listFrame.CanvasSize = UDim2.new(0,0,5,0)
listFrame.BackgroundColor3 = Color3.fromRGB(40,40,40)

-- teleport distance
local distBox = Instance.new("TextBox", frame)
distBox.Size = UDim2.new(1,-10,0,30)
distBox.Position = UDim2.new(0,5,0,135)
distBox.PlaceholderText = "Teleport Distance (0.1 - 7000)"

-- attack range
local rangeBox = Instance.new("TextBox", frame)
rangeBox.Size = UDim2.new(1,-10,0,30)
rangeBox.Position = UDim2.new(0,5,0,170)
rangeBox.PlaceholderText = "Attack Range (Max 5000)"

-- teleport toggle
local tpToggle = Instance.new("TextButton", frame)
tpToggle.Size = UDim2.new(1,-10,0,30)
tpToggle.Position = UDim2.new(0,5,0,210)
tpToggle.Text = "Teleport OFF"

-- attack toggle
local atkToggle = Instance.new("TextButton", frame)
atkToggle.Size = UDim2.new(1,-10,0,30)
atkToggle.Position = UDim2.new(0,5,0,250)
atkToggle.Text = "Fast Attack OFF"

--================ CONFIG =================--

local selectedPlayer = nil
local teleportEnabled = false
local attackEnabled = false

local COMBAT_CONFIG = {
    attacksPerTarget = 3,
    maxTargets = 5,
    baseRange = 1700
}

tpToggle.MouseButton1Click:Connect(function()
    teleportEnabled = not teleportEnabled
    tpToggle.Text = teleportEnabled and "Teleport ON" or "Teleport OFF"
end)

atkToggle.MouseButton1Click:Connect(function()
    attackEnabled = not attackEnabled
    atkToggle.Text = attackEnabled and "Fast Attack ON" or "Fast Attack OFF"
end)

-- تحديث قائمة اللاعبين
local function refreshList()

    listFrame:ClearAllChildren()

    local y = 0

    for _,plr in pairs(Players:GetPlayers()) do

        if plr ~= LocalPlayer then

            local btn = Instance.new("TextButton", listFrame)
            btn.Size = UDim2.new(1,0,0,20)
            btn.Position = UDim2.new(0,0,0,y)
            btn.Text = plr.Name

            btn.MouseButton1Click:Connect(function()
                selectedPlayer = plr
                print("Selected:",plr.Name)
            end)

            y += 20
        end
    end
end

Players.PlayerAdded:Connect(refreshList)
Players.PlayerRemoving:Connect(refreshList)

refreshList()

--================ TELEPORT =================--

RunService.RenderStepped:Connect(function()

    if not teleportEnabled then return end
    if not selectedPlayer then return end

    local targetHRP = selectedPlayer.Character and selectedPlayer.Character:FindFirstChild("HumanoidRootPart")
    local myHRP = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")

    if not targetHRP or not myHRP then return end

    local dist = tonumber(distBox.Text)
    if not dist then return end

    dist = math.clamp(dist,0.1,7000)

    local offset = targetHRP.CFrame.LookVector * -dist
    myHRP.CFrame = targetHRP.CFrame + offset

end)

--================ FAST ATTACK =================--

local function GetPrimaryPart(model)
    return model:FindFirstChild("HumanoidRootPart") or model.PrimaryPart
end

local lastAttackTime = 0

RunService.Heartbeat:Connect(function()

    if not attackEnabled then return end
    if not selectedPlayer then return end

    local character = LocalPlayer.Character
    if not character or not character.PrimaryPart then return end

    local charPos = character.PrimaryPart.Position

    local customRange = tonumber(rangeBox.Text)
    if customRange then
        COMBAT_CONFIG.baseRange = math.clamp(customRange,0,5000)
    end

    local targetChar = selectedPlayer.Character
    if not targetChar then return end

    local part = GetPrimaryPart(targetChar)
    if not part then return end

    local dist = (part.Position - charPos).Magnitude

    if dist <= COMBAT_CONFIG.baseRange then

        local now = tick()

        if now - lastAttackTime >= 0.05 then

            RegisterAttack:FireServer()

            for i=1,COMBAT_CONFIG.attacksPerTarget do
                RegisterHit:FireServer(part)
            end

            lastAttackTime = now
        end
    end
end)
