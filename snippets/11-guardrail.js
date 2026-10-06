// Guardrail combinado: un monto alto por si solo no basta para forzar
// revision humana si el riesgo es bajo; solo cuenta cuando coincide con
// riesgo ALTO. Un fraude alto siempre fuerza revision, sin importar el monto.
const decision = $json;
const fraude = $('Combinar respuestas').item.json.fraude;

const montoAltoYRiesgoAlto = decision.approved_amount > 10000000 && decision.risk_level === 'ALTO';
const fraudeAlto = fraude.fraud_risk_score >= 45;

const needs_human_review = montoAltoYRiesgoAlto || fraudeAlto;

return [{ json: { ...decision, needs_human_review } }];