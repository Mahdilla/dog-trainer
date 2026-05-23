# Dog Trainer — Setup

## What it does
Hold a hand gesture in front of the webcam and the Roblox dog performs a trick:
- ☝️ Finger → Sit
- ✋ Open palm → Shake
- ✊ Fist → Jump

## Files
- `server.js` — relay server between the webcam page and Roblox
- `public/index.html` + `public/app.js` — webcam classifier (Teachable Machine model)
- `roblox_server.lua` — paste into a Script in ServerScriptService

## Setup

### 1. Start the relay server (in Codespaces)
```
npm install
node server.js
```

### 2. Start ngrok (in a second Codespaces terminal)
```
ngrok http 3000
```
Copy the `https://xxxx.ngrok-free.app` URL.

### 3. Paste the ngrok URL into roblox_server.lua
```lua
local BASE_URL = "https://xxxx.ngrok-free.app"
```

### 4. Open the webcam page
Open the ngrok URL in your browser — the classifier starts automatically.

### 5. Set up Roblox Studio
1. File → Game Settings → Security → **Allow HTTP Requests** on
2. Paste `roblox_server.lua` into a **Script** in `ServerScriptService`
3. Make sure your dog model in Workspace is named **Dog**
4. Hit **Play**

## Notes
- The webcam page must be open and running for the dog to react
- Confidence threshold is 0.7 — gestures need to be clear and held steady
- ngrok URL changes every time you restart it — update `roblox_server.lua` each session