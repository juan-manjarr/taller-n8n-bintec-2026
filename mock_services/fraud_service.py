from fastapi import FastAPI
from pydantic import BaseModel

app = FastAPI(title="Fraud API")

class FraudRequest(BaseModel):
    customer_id: str
    ip: str
    channel: str
    amount: float
    device_id: str

@app.get("/health")
def health():
    return {"status": "ok", "service": "fraud-api"}

@app.post("/check")
def check(request: FraudRequest):
    suspicious_ip = request.ip.startswith("185.") or request.ip.startswith("10.")
    high_amount = request.amount > 8000000
    risky_channel = request.channel.lower() in ["sms", "email"]
    risk_score = 0

    if suspicious_ip:
        risk_score += 30
    if high_amount:
        risk_score += 25
    if risky_channel:
        risk_score += 20

    return {
        "customer_id": request.customer_id,
        "fraud_risk_score": risk_score,
        "is_high_risk": risk_score >= 45,
        "alerts": {
            "suspicious_ip": suspicious_ip,
            "high_amount": high_amount,
            "risky_channel": risky_channel,
        },
    }

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)