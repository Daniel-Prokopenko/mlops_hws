import os
import time
import json
from pathlib import Path

OUT_DIR = Path(os.getenv("OUT_DIR", "artifacts"))
OUT_DIR.mkdir(parents=True, exist_ok=True)

def main():
    time.sleep(1)
    model_artifact = {
        "type": "mock-model",
        "trained_at": time.time(),
        "version": os.getenv("MODEL_VERSION", "0.0.1"),
    }
    (OUT_DIR / "model.pkl").write_text(json.dumps(model_artifact), encoding="utf-8")
    print(f"Saved mock model to {OUT_DIR / 'model.pkl'}")

if __name__ == "__main__":
    main()
