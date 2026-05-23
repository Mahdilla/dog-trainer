-- LOCAL SCRIPT (place in StarterPlayerScripts)
-- Shows the "What should the dog have done?" buttons and the treat jar counter.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local dogTrainerEvent = ReplicatedStorage:WaitForChild("DogTrainer")

-- ── Build the GUI ──────────────────────────────────────────────
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "DogTrainerGui"
screenGui.ResetOnSpawn = false
screenGui.Parent = player.PlayerGui

-- Treat jar (always visible)
local treatLabel = Instance.new("TextLabel")
treatLabel.Size = UDim2.new(0, 200, 0, 40)
treatLabel.Position = UDim2.new(0, 16, 0, 16)
treatLabel.BackgroundColor3 = Color3.fromRGB(30, 25, 15)
treatLabel.TextColor3 = Color3.fromRGB(255, 210, 80)
treatLabel.Font = Enum.Font.GothamBold
treatLabel.TextSize = 18
treatLabel.Text = "🦴 Treats: 0"
treatLabel.BackgroundTransparency = 0.3
treatLabel.Parent = screenGui
Instance.new("UICorner", treatLabel).CornerRadius = UDim.new(0, 8)

-- Guess display
local guessLabel = Instance.new("TextLabel")
guessLabel.Size = UDim2.new(0, 260, 0, 50)
guessLabel.Position = UDim2.new(0.5, -130, 0.15, 0)
guessLabel.BackgroundTransparency = 1
guessLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
guessLabel.Font = Enum.Font.GothamBold
guessLabel.TextSize = 22
guessLabel.Text = ""
guessLabel.Parent = screenGui

-- Judgment panel (hidden until dog guesses)
local panel = Instance.new("Frame")
panel.Size = UDim2.new(0, 340, 0, 130)
panel.Position = UDim2.new(0.5, -170, 0.75, 0)
panel.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
panel.BackgroundTransparency = 0.2
panel.Visible = false
panel.Parent = screenGui
Instance.new("UICorner", panel).CornerRadius = UDim.new(0, 10)

local promptLabel = Instance.new("TextLabel")
promptLabel.Size = UDim2.new(1, 0, 0, 30)
promptLabel.BackgroundTransparency = 1
promptLabel.TextColor3 = Color3.fromRGB(200, 200, 220)
promptLabel.Font = Enum.Font.Gotham
promptLabel.TextSize = 14
promptLabel.Text = "What should it have been?"
promptLabel.Parent = panel

local btnData = {
	{ label = "sit",   text = "☝️ SIT",   pos = UDim2.new(0.04, 0, 0.35, 0) },
	{ label = "shake", text = "✋ SHAKE", pos = UDim2.new(0.37, 0, 0.35, 0) },
	{ label = "jump",  text = "✊ JUMP",  pos = UDim2.new(0.70, 0, 0.35, 0) },
}

local currentId, currentDogGuess = nil, nil
local buttons = {}

for _, d in ipairs(btnData) do
	local btn = Instance.new("TextButton")
	btn.Size = UDim2.new(0.28, 0, 0.48, 0)
	btn.Position = d.pos
	btn.BackgroundColor3 = Color3.fromRGB(50, 60, 90)
	btn.TextColor3 = Color3.fromRGB(255, 255, 255)
	btn.Font = Enum.Font.GothamBold
	btn.TextSize = 15
	btn.Text = d.text
	btn.Parent = panel
	Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)

	btn.MouseButton1Click:Connect(function()
		if currentId then
			dogTrainerEvent:FireServer(d.label, currentId, currentDogGuess)
			panel.Visible = false
			guessLabel.Text = ""
			currentId = nil
		end
	end)
	buttons[d.label] = btn
end

-- ── Listen for events from the server script ───────────────────
dogTrainerEvent.OnClientEvent:Connect(function(a, b, c)
	if a == "treats" then
		-- b = treat count, c = whether it was correct
		treatLabel.Text = "🦴 Treats: " .. tostring(b)
		if c then
			guessLabel.Text = "✅ Good dog!"
		else
			guessLabel.Text = "❌ Wrong — but learning!"
		end
		task.delay(2, function() guessLabel.Text = "" end)
	else
		-- a = dogGuess, b = id → show the judgment panel
		currentDogGuess = a
		currentId = b
		guessLabel.Text = 'The dog thinks: "' .. a:upper() .. '"'
		panel.Visible = true
	end
end)
