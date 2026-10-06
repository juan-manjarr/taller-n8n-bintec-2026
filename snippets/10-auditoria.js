// Paso 7 - Trazabilidad y auditoría.
// Arma el registro completo de la decisión. Reemplaza el console.log
// de abajo por un nodo real (Postgres, Elasticsearch, etc.) cuando
// tengas esa base de datos lista; mientras tanto, cada ejecución queda
// visible en n8n -> Executions con este objeto en el log.
const combinado = $('Combinar respuestas').item.json;
const decision = $json;

const audit = {
  request_id: `${$workflow.id}-${Date.now()}`,
  timestamp: new Date().toISOString(),
  customer_id: combinado.cliente.customer_id,
  risk_response: combinado.riesgo,
  fraud_response: combinado.fraude,
  crm_response: combinado.cliente,
  // modelo que realmente respondió (Gemini o el gateway del taller lo informan en modelVersion)
  llm_model: $('Gemini Agent').item.json.modelVersion ?? $env.LLM_MODEL,
  decision: decision.decision,
  human_review: decision.human_review,
};

// TODO: inserta 'audit' en tu tabla/índice de trazabilidad real.
console.log('AUDITORIA:', JSON.stringify(audit));

return [{ json: decision }];