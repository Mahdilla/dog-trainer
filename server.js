// Relay server. Sits between the webcam page (browser) and Roblox.
// Browser PUSHES its latest guess here; Roblox PULLS it.
// Roblox PUSHES the kid's judgment here; browser PULLS it to retrain.

const express = require("express");
const cors = require("cors");
const path = require("path");

const app = express();
app.use(cors());
app.use(express.json());
app.use(express.static(path.join(__dirname, "public")));

// latest classification from the webcam page
let state = { id: 0, label: "none", confidence: 0, treats: 0 };

// judgments from Roblox waiting to be folded back into the model
let pendingCorrections = [];

// --- browser -> server: push the current guess ---
app.post("/classify", (req, res) => {
  const { id, label, confidence } = req.body;
  state.id = id;
  state.label = label;
  state.confidence = confidence;
  res.json({ ok: true });
});

// --- Roblox -> server: poll the current guess ---
app.get("/state", (req, res) => {
  res.json(state);
});

// --- Roblox -> server: the kid's verdict ("it should have been X") ---
app.post("/correct", (req, res) => {
  const { id, dogGuess, actualLabel } = req.body;
  pendingCorrections.push({ id, actualLabel }); // always a new training example
  if (dogGuess === actualLabel) state.treats += 1; // treat only if the dog was right
  console.log(
    `judged: dog said "${dogGuess}", kid said "${actualLabel}" -> treats: ${state.treats}`
  );
  res.json({ ok: true, treats: state.treats, correct: dogGuess === actualLabel });
});

// --- browser -> server: poll for corrections to retrain on ---
app.get("/corrections", (req, res) => {
  const out = pendingCorrections;
  pendingCorrections = [];
  res.json(out);
});

app.listen(3000, () => {
  console.log("Dog-trainer relay running:  http://localhost:3000");
  console.log("Open that URL in your browser, then run:  ngrok http 3000");
});
