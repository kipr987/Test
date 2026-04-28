local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Camera = workspace.CurrentCamera

local LocalPlayer = Players.LocalPlayer
local Holding = false
local MaxDistance = 300

local function IsVisible(targetPart, targetModel)
	local character = LocalPlayer.Character
	if not character then return false end

	local myHead = character:FindFirstChild("Head")
	if not myHead then return false end

	local origin = myHead.Position
	local direction = (targetPart.Position - origin)

	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Blacklist
	params.FilterDescendantsInstances = {
		character, -- себя игнорим
		Camera
	}
	params.IgnoreWater = true

	local result = workspace:Raycast(origin, direction, params)

	-- если луч попал прямо в цель (или в её часть)
	if result and result.Instance then
		if result.Instance:IsDescendantOf(targetModel) then
			return true
		end
		return false
	end

	return false
end

local function GetClosestTarget()
	local character = LocalPlayer.Character
	if not character then return nil end

	local myRoot = character:FindFirstChild("HumanoidRootPart")
	if not myRoot then return nil end

	local myTeam = LocalPlayer:GetAttribute("Team")

	local closest = nil
	local shortest = MaxDistance

	local function Check(model, targetTeam)
		if not model then return end

		local hrp = model:FindFirstChild("HumanoidRootPart")
		local head = model:FindFirstChild("Head")
		local humanoid = model:FindFirstChildOfClass("Humanoid")

		if not hrp or not head or not humanoid then
			return
		end

		if humanoid.Health <= 0 then
			return
		end

		if model == character then
			return
		end

		-- не своя команда
		if myTeam and targetTeam and myTeam == targetTeam then
			return
		end

		local dist = (hrp.Position - myRoot.Position).Magnitude
		if dist > MaxDistance then
			return
		end

		-- проверка видимости через raycast (должна быть видна голова)
		if not IsVisible(head, model) then
			return
		end

		if dist < shortest then
			shortest = dist
			closest = model
		end
	end

	-- Мобы
	local mobsFolder = workspace:FindFirstChild("Mobs")
	if mobsFolder then
		for _, mob in pairs(mobsFolder:GetChildren()) do
			Check(mob, mob:GetAttribute("Team"))
		end
	end

	-- Игроки
	for _, player in pairs(Players:GetPlayers()) do
		if player ~= LocalPlayer and player.Character then
			Check(player.Character, player:GetAttribute("Team"))
		end
	end

	return closest
end

-- ПКМ
UserInputService.InputBegan:Connect(function(input, gp)
	if gp then return end

	if input.UserInputType == Enum.UserInputType.MouseButton2 then
		Holding = true
	end
end)

UserInputService.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton2 then
		Holding = false
	end
end)

RunService.RenderStepped:Connect(function()
	if not Holding then return end

	local target = GetClosestTarget()
	if not target then return end

	local head = target:FindFirstChild("Head")
	if not head then return end

	Camera.CFrame = CFrame.new(
		Camera.CFrame.Position,
		head.Position
	)
end)
while task.wait() do
	pcall(function()
		local myTeam = game:GetService("Players").LocalPlayer:GetAttribute("Team")

		-- Мобы
		for _, v in pairs(workspace.Mobs:GetChildren()) do
			if v:GetAttribute("Team") ~= myTeam then
			for i, f in v:GetChildren() do
				if f:IsA("Highlight") and f.Name ~= "L" then
					f:Destroy()
				end
			end
				if not v:FindFirstChild("L") then
					local l = Instance.new("Highlight")
					l.Name = "L"
					l.Parent = v
				end
			end
		end

		-- Игроки
		for _, v in pairs(game:GetService("Players"):GetPlayers()) do
			if v ~= game:GetService("Players").LocalPlayer then
				local char = v.Character
				for i, f in char:GetChildren() do
					if f:IsA("Highlight") and f.Name ~= "L" then
						f:Destroy()
					end
				end
				if char and v:GetAttribute("Team") ~= myTeam then
					if not char:FindFirstChild("L") then
						local l = Instance.new("Highlight")
						l.Name = "L"
						l.Parent = char
					end
				end
			end
		end
	end)
end
