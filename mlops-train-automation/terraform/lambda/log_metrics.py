import json
import time

def lambda_handler(event, context):
    print("Logging metrics...")
    print("Input:", json.dumps(event))
    metrics = {"accuracy": 0.91, "loss": 0.23, "ts": int(time.time())}
    return {"ok": True, "stage": "log_metrics", "metrics": metrics, "received": event}
