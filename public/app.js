const MODEL_URL = "https://teachablemachine.withgoogle.com/models/hcP3FBOLH/";
let model, webcam, frameId = 0;

async function init() {
  setStatus("loading model…");
  model = await tmImage.load(MODEL_URL + "model.json", MODEL_URL + "metadata.json");

  webcam = new tmImage.Webcam(300, 300, true);
  await webcam.setup();
  await webcam.play();
  document.getElementById("webcam-container").appendChild(webcam.canvas);

  setStatus("running ✅");
  loop();
}

async function loop() {
  webcam.update();
  const predictions = await model.predict(webcam.canvas);
  const best = predictions.reduce((a, b) => a.probability > b.probability ? a : b);

  document.getElementById("guess").textContent = best.className;

  // update label display
  const container = document.getElementById("label-container");
  container.innerHTML = predictions.map(p =>
    `<div>${p.className}: ${(p.probability * 100).toFixed(0)}%</div>`
  ).join("");

  // send to relay server
  await fetch("/classify", {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({ id: ++frameId, label: best.className, confidence: best.probability }),
  }).catch(() => {});

  window.requestAnimationFrame(loop);
}

function setStatus(msg) { document.getElementById("status").textContent = msg; }

init();