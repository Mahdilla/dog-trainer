-- SERVER SCRIPT (place in ServerScriptService)
-- Polls the relay server, drives dog tricks, handles treat logic.
-- Create a RemoteEvent named "DogTrainer" in ReplicatedStorage first.

local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local BASE_URL = "https://YOUR-NGROK-URL.ngrok-free.app" -- ← paste your ngrok URL
local CONFIDENCE_THRESHOLD = 0.6

local dogTrainerEvent = ReplicatedStorage:WaitForChild("DogTrainer")

-- ───────────────────────────────────────────
-- TODO: replace with your actual dog model / animations
local function playTrick(trick)
	print("[DOG] performing:", trick)
	-- e.g.
	-- local anim = dogModel.Humanoid.Animator:LoadAnimation(animations[trick])
	-- anim:Play()
end
-- ───────────────────────────────────────────

local function request(method, path, body)
	local ok, res = pcall(function()
		return HttpService:RequestAsync({
			Url = BASE_URL .. path,
			Method = method,
			Headers = {
				["Content-Type"] = "application/json",
				["ngrok-skip-browser-warning"] = "true",
			},
			Body = body and HttpService:JSONEncode(body) or nil,
		})
	end)
	if ok and res.Success then
		return HttpService:JSONDecode(res.Body)
	end
	return nil
end

-- listen for judgment from the client LocalScript
local pendingJudgment = nil
dogTrainerEvent.OnServerEvent:Connect(function(player, actualLabel, id, dogGuess)
	pendingJudgment = { id = id, dogGuess = dogGuess, actualLabel = actualLabel }
end)

local lastId = 0

while true do
	local state = request("GET", "/state")

	if state and state.id ~= lastId
		and state.label ~= "none"
		and state.confidence >= CONFIDENCE_THRESHOLD then

		lastId = state.id
		local dogGuess = state.label
		local currentId = state.id

		playTrick(dogGuess)

		-- tell the client to show the judgment buttons
		for _, player in pairs(game.Players:GetPlayers()) do
			dogTrainerEvent:FireClient(player, dogGuess, currentId)
		end

		-- wait up to 8 seconds for the kid's verdict
		pendingJudgment = nil
		local elapsed = 0
		while pendingJudgment == nil and elapsed < 8 do
			task.wait(0.2)
			elapsed += 0.2
		end

		if pendingJudgment then
			local result = request("POST", "/correct", {
				id = pendingJudgment.id,
				dogGuess = pendingJudgment.dogGuess,
				actualLabel = pendingJudgment.actualLabel,
			})
			if result then
				-- broadcast updated treat count to all clients
				for _, player in pairs(game.Players:GetPlayers()) do
					dogTrainerEvent:FireClient(player, "treats", result.treats, result.correct)
				end
			end
		end
	end

	task.wait(0.5)
end
