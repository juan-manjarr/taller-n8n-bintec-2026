// Gemini devuelve { candidates: [ { content: { parts: [ { text: '...' } ] } } ], ... }
// El texto es el JSON que le pedimos al agente en el prompt.
let raw = $json.candidates[0].content.parts[0].text.trim();

// Por si el modelo lo envuelve en un bloque de código markdown
if (raw.startsWith('```')) {
  raw = raw.replace(/^```(json)?/, '').replace(/```$/, '').trim();
}

const parsed = JSON.parse(raw);
return [{ json: parsed }];