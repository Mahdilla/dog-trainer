// Paste your Teachable Machine shareable URL here:
const MODEL_URL = "https://teachablemachine.withgoogle.com/models/hcP3FBOLH/";

let model, video;
let frameId = 0;

async function init() {
  setStatus("loading model…");
  model = await tmImage.load(MODEL_URL + "model.json", MODEL_URL + "metadata.json");

  video = document.getElementById("cam");
  const stream = await navigator.mediaDevices.getUserMedia({ video: true });
  video.srcObject = stream;
  await new Promise((r) => (video.onloadedmetadata = r));

  setStatus("running ✅");
  loop();
}

async function loop() {
  const predictions = await model.predict(video);
  // pick the class with highest confidence
  const best = predictions.reduce((a, b) => (a.probability > b.probability ? a : b));

  document.getElementById("guess").textContent = best.className;
  document.getElementById("conf").textContent = `confidence: ${(best.probability * 100).toFixed(0)}%`;

  await fetch("/classify", {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({ id: ++frameId, label: best.className, confidence: best.probability }),
  }).catch(() => {});

  setTimeout(loop, 500);
}

function setStatus(msg) { document.getElementById("status").textContent = msg; }

init();