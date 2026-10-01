from fastapi import FastAPI
from pydantic import BaseModel

app = FastAPI(title="Risk API")

class RiskRequest(BaseModel):
    customer_id: str
    requested_amount: float
    term_months: int

@app.get("/health")
def health():
    return {"status": "ok", "service": "risk-api"}

@app.post("/score")
def score(request: RiskRequest):
    base = 750
    amount_factor = 100 - (request.requested_amount / 150000)
    term_factor = (30 - request.term_months) / 2
    score = int(min(850, max(400, base + amount_factor + term_factor)))

    if score >= 700:
        level = "BAJO"
        approved_limit = 25000000
    elif score >= 550:
        level = "MEDIO"
        approved_limit = 12000000
    else:
        level = "ALTO"
        approved_limit = 4000000

    return {
        "customer_id": request.customer_id,
        "credit_score": score,
        "risk_level": level,
        "approved_limit": approved_limit,
        "recommended_term_months": min(request.term_months, 36),
    }

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)