from fastapi import FastAPI
from pydantic import BaseModel

app = FastAPI(title="CRM API")

class CRMRequest(BaseModel):
    customer_id: str

@app.get("/health")
def health():
    return {"status": "ok", "service": "crm-api"}

@app.post("/profile")
def profile(request: CRMRequest):
    customer_map = {
        "CLI-893201": {
            "customer_name": "Mariana Gómez",
            "segment": "PREFERENCIAL",
            "monthly_income": 6200000,
            "employment": "Empleado",
            "tenure_months": 42,
            "product_history": ["tarjeta", "cuenta de ahorros"],
        },
        "CLI-440102": {
            "customer_name": "Andrés Ramírez",
            "segment": "MEDIO",
            "monthly_income": 3200000,
            "employment": "Independiente",
            "tenure_months": 18,
            "product_history": ["cuenta corriente"],
        },
    }

    record = customer_map.get(request.customer_id, {
        "customer_name": "Cliente nuevo",
        "segment": "NUEVO",
        "monthly_income": 2500000,
        "employment": "No reportado",
        "tenure_months": 0,
        "product_history": [],
    })

    return {
        "customer_id": request.customer_id,
        **record,
    }

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)