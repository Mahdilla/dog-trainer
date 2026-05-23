-- SERVER SCRIPT (place in ServerScriptService)
local HttpService = game:GetService("HttpService")

local BASE_URL = "https://dolphin-epiphany-worst.ngrok-free.dev"
local CONFIDENCE_THRESHOLD = 0.7

local dogModel = workspace:WaitForChild("Dog")
local animator = dogModel:WaitForChild("Humanoid"):WaitForChild("Animator")

local animationIds = {
	sit   = "rbxassetid://106724539355978",
	shake = "rbxassetid://118084110439183",
	jump  = "rbxassetid://114339697984143",
}

local currentTrack = nil
local function playTrick(trick)
	local id = animationIds[trick]
	if not id then return end
	if currentTrack then currentTrack:Stop() end
	local anim = Instance.new("Animation")
	anim.AnimationId = id
	currentTrack = animator:LoadAnimation(anim)
	currentTrack:Play()
	print("[DOG] performing:", trick)
end

local function getState()
	local ok, res = pcall(function()
		return HttpService:RequestAsync({
			Url = BASE_URL .. "/state",
			Method = "GET",
			Headers = { ["ngrok-skip-browser-warning"] = "true" },
		})
	end)
	if ok and res.Success then
		return HttpService:JSONDecode(res.Body)
	end
	return nil
end

local lastId = 0
local lastLabel = ""

while true do
	local state = getState()
	if state and state.id ~= lastId and state.confidence >= CONFIDENCE_THRESHOLD then
		lastId = state.id
		local label = string.lower(state.label) -- fix capitalisation from TM
		if label ~= lastLabel then
			lastLabel = label
			playTrick(label)
		end
	end
	task.wait(0.5)
end