# Dog Trainer — Setup

## 1. Start the relay server
```
cd dog-trainer
npm install
node server.js
```
Open http://localhost:3000 in your browser — you'll see the webcam console.

## 2. Expose it to Roblox via ngrok
```
ngrok http 3000
```
Copy the `https://xxxx.ngrok-free.app` URL it gives you.

## 3. Seed the model (webcam page)
Hold each gesture in front of the camera and click the matching button ~5 times each:
- ☝️ Finger → SIT
- ✋ Open palm → SHAKE
- ✊ Fist → JUMP

## 4. Set up Roblox
1. File → Experience Settings → Security → **Allow HTTP requests**
2. Create a `RemoteEvent` named **DogTrainer** in `ReplicatedStorage`
3. Paste **roblox_server.lua** into a `Script` in `ServerScriptService`
4. Paste **roblox_client.lua** into a `LocalScript` in `StarterPlayerScripts`
5. In `roblox_server.lua` line 9 — replace `YOUR-NGROK-URL` with the one from step 2
6. In `roblox_server.lua`, find the `playTrick(trick)` function and plug in your dog's animations

## How the live-learning loop works
- Webcam page classifies the gesture every 500ms → pushes result to relay
- Roblox polls relay, dog performs the trick, judgment buttons appear
- Kid taps the correct trick → relay notified → webcam page grabs the buffered
  embedding for that frame and adds it to the classifier under the correct label
- The dog gets smarter as the session goes on; every treat = a confirmed training example
