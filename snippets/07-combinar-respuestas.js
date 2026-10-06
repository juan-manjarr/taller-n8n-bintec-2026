// El Merge de arriba junta Risk + Fraud + CRM en un solo objeto plano.
// Aqui lo reordenamos en la misma forma anidada que usa el resto del flujo.
const flat = $json;

return [
  {
    json: {
      cliente: {
        customer_id: flat.customer_id,
        customer_name: flat.customer_name,
        segment: flat.segment,
        monthly_income: flat.monthly_income,
        employment: flat.employment,
        tenure_months: flat.tenure_months,
        product_history: flat.product_history,
      },
      riesgo: {
        customer_id: flat.customer_id,
        credit_score: flat.credit_score,
        risk_level: flat.risk_level,
        approved_limit: flat.approved_limit,
        recommended_term_months: flat.recommended_term_months,
      },
      fraude: {
        customer_id: flat.customer_id,
        fraud_risk_score: flat.fraud_risk_score,
        is_high_risk: flat.is_high_risk,
        alerts: flat.alerts,
      },
    },
  },
];