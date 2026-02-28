import os
import time
import json
import logging
from typing import Any, Dict, Optional

from fastapi import FastAPI, Request
from pydantic import BaseModel
from prometheus_client import Counter, Histogram, generate_latest, CONTENT_TYPE_LATEST

APP_NAME = os.getenv("APP_NAME", "aiops-quality-api")
DRIFT_THRESHOLD = float(os.getenv("DRIFT_THRESHOLD", "0.9"))
MODEL_PATH = os.getenv("MODEL_PATH", "/models/model.pkl")

logging.basicConfig(level=logging.INFO, format="%(asctime)s %(levelname)s %(message)s")
log = logging.getLogger(APP_NAME)

REQ_COUNT = Counter("http_requests_total", "Total HTTP requests", ["method", "path", "status"])
REQ_LAT = Histogram("http_request_latency_seconds", "Request latency", ["path"])

app = FastAPI(title=APP_NAME)

MODEL: Dict[str, Any] = {"loaded": False, "path": MODEL_PATH}

def load_model() -> None:
    MODEL["loaded"] = True
    MODEL["loaded_at"] = time.time()
    log.info(f"Model loaded (mock). path={MODEL_PATH}")

def predict(data: Dict[str, Any]) -> Dict[str, Any]:
    x = data.get("x", 0)
    y = 2 * x if isinstance(x, (int, float)) else 0
    return {"y": y}

def drift_detect(data: Dict[str, Any], pred: Dict[str, Any]) -> bool:
    if data.get("drift") is True:
        return True
    key = json.dumps(data, sort_keys=True) + json.dumps(pred, sort_keys=True)
    score = (abs(hash(key)) % 1000) / 1000.0
    return score > DRIFT_THRESHOLD

class PredictIn(BaseModel):
    x: Optional[float] = None
    drift: Optional[bool] = None
    meta: Optional[Dict[str, Any]] = None

@app.on_event("startup")
def _startup():
    load_model()

@app.middleware("http")
async def metrics_mw(request: Request, call_next):
    path = request.url.path
    start = time.time()
    status = "500"
    try:
        resp = await call_next(request)
        status = str(resp.status_code)
        return resp
    finally:
        dur = time.time() - start
        REQ_LAT.labels(path=path).observe(dur)
        REQ_COUNT.labels(method=request.method, path=path, status=status).inc()

@app.get("/health")
def health():
    return {"status": "ok", "model_loaded": MODEL["loaded"], "model_path": MODEL["path"]}

@app.get("/metrics")
def metrics():
    return generate_latest(), 200, {"Content-Type": CONTENT_TYPE_LATEST}

@app.post("/predict")
def predict_endpoint(payload: PredictIn):
    data = payload.model_dump()
    pred = predict(data)

    log.info(json.dumps({"event": "inference", "input": data, "pred": pred}, ensure_ascii=False))

    is_drift = drift_detect(data, pred)
    if is_drift:
        log.warning("Drift detected")

    return {"prediction": pred, "drift": is_drift}
