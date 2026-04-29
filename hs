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
	local direction = targetPart.Position - origin

	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Blacklist
	params.FilterDescendantsInstances = {
		character,
		Camera
	}
	params.IgnoreWater = true

	local result = workspace:Raycast(origin, direction, params)

	if result and result.Instance then
		if result.Instance:IsDescendantOf(targetModel) then
			return true
		end
		return false
	end

	return true
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

		if myTeam and targetTeam and myTeam == targetTeam then
			return
		end

		local dist = (hrp.Position - myRoot.Position).Magnitude
		if dist > MaxDistance then
			return
		end

		if not IsVisible(head, model) then
			return
		end

		if dist < shortest then
			shortest = dist
			closest = model
		end
	end

	local mobsFolder = workspace:FindFirstChild("Mobs")
	if mobsFolder then
		for _, mob in pairs(mobsFolder:GetChildren()) do
			Check(mob, mob:GetAttribute("Team"))
		end
	end

	for _, player in pairs(Players:GetPlayers()) do
		if player ~= LocalPlayer and player.Character then
			Check(player.Character, player:GetAttribute("Team"))
		end
	end

	return closest
end

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

task.spawn(function()
	while task.wait(1) do
		pcall(function()
			local myTeam = LocalPlayer:GetAttribute("Team")

			local mobsFolder = workspace:FindFirstChild("Mobs")
			if mobsFolder then
				for _, v in pairs(mobsFolder:GetChildren()) do
					if v:GetAttribute("Team") ~= myTeam then
						for _, f in pairs(v:GetChildren()) do
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
			end

			for _, v in pairs(Players:GetPlayers()) do
				if v ~= LocalPlayer and v.Character then
					local char = v.Character

					if v:GetAttribute("Team") ~= myTeam then
						for _, f in pairs(char:GetChildren()) do
							if f:IsA("Highlight") and f.Name ~= "L" then
								f:Destroy()
							end
						end

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
end)
