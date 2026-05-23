let net, classifier, video;
let frameId = 0;
const embeddingBuffer = new Map(); // id -> tensor
const counts = { sit: 0, shake: 0, jump: 0 };
const MAX_BUFFER = 40;

async function init() {
  video = document.getElementById("cam");
  const stream = await navigator.mediaDevices.getUserMedia({ video: true });
  video.srcObject = stream;
  await new Promise((r) => (video.onloadedmetadata = r));

  setStatus("loading MobileNet…");
  net = await mobilenet.load();
  classifier = knnClassifier.create();
  setStatus("ready — seed the puppy then it will start guessing");

  document.querySelectorAll("button[data-label]").forEach((btn) => {
    btn.addEventListener("click", () => addExample(btn.dataset.label));
  });

  classifyLoop();
  correctionsLoop();
}

function addExample(label) {
  const act = net.infer(video, true);
  classifier.addExample(act, label); // knn owns this tensor
  counts[label]++;
  document.getElementById("c-" + label).textContent = counts[label];
  log(`taught: ${label} (${counts[label]} examples)`);
}

async function classifyLoop() {
  if (classifier.getNumClasses() > 0) {
    const act = net.infer(video, true);
    const result = await classifier.predictClass(act);
    const confidence = result.confidences[result.label] || 0;
    const id = ++frameId;

    // buffer for later correction; evict oldest if full
    embeddingBuffer.set(id, act);
    if (embeddingBuffer.size > MAX_BUFFER) {
      const oldest = embeddingBuffer.keys().next().value;
      embeddingBuffer.get(oldest).dispose();
      embeddingBuffer.delete(oldest);
    }

    document.getElementById("guess").textContent = result.label;
    document.getElementById("conf").textContent =
      `confidence: ${(confidence * 100).toFixed(0)}%`;

    await postClassify(id, result.label, confidence);
  }
  setTimeout(classifyLoop, 500);
}

async function correctionsLoop() {
  try {
    const res = await fetch("/corrections");
    const corrections = await res.json();
    for (const c of corrections) {
      const emb = embeddingBuffer.get(c.id);
      if (emb) {
        classifier.addExample(emb.clone(), c.actualLabel); // knn owns the clone
        counts[c.actualLabel]++;
        document.getElementById("c-" + c.actualLabel).textContent =
          counts[c.actualLabel];
        log(`🔁 retrained: added example for "${c.actualLabel}"`);
      } else {
        log(`⚠️ correction for expired frame ${c.id} — ignored`);
      }
    }
  } catch (e) {
    log("server unreachable — retrying…");
  }
  setTimeout(correctionsLoop, 1000);
}

async function postClassify(id, label, confidence) {
  try {
    await fetch("/classify", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ id, label, confidence }),
    });
  } catch (_) {}
}

function setStatus(msg) {
  document.getElementById("status").textContent = msg;
}

function log(msg) {
  const el = document.getElementById("log");
  el.innerHTML += `<div>${new Date().toLocaleTimeString()} — ${msg}</div>`;
  el.scrollTop = el.scrollHeight;
}

init();
