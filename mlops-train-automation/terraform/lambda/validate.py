import json

def lambda_handler(event, context):
    print("Validating data...")
    print("Input:", json.dumps(event))
    return {"ok": True, "stage": "validate", "received": event}
