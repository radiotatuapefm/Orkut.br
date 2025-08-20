// Script para testar a API do Gemini
const API_URL = "https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash-latest:generateContent";
const API_KEY = "AIzaSyB8QXNgbYg6xZWVyYdI8bw64Kr8BmRlWGk";

async function testGeminiAPI() {
  console.log("🧪 Testando API do Gemini...");
  
  try {
    const response = await fetch(`${API_URL}?key=${API_KEY}`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        contents: [{
          parts: [{ text: "Olá! Você é o Orky, assistente do Orkut. Responda apenas: 'Olá! Sou o Orky e estou funcionando perfeitamente!'" }]
        }],
        generationConfig: {
          temperature: 0.7,
          maxOutputTokens: 100,
        }
      })
    });

    console.log("📡 Status da resposta:", response.status);
    
    if (!response.ok) {
      const errorText = await response.text();
      console.error("❌ Erro na API:", response.statusText);
      console.error("❌ Detalhes:", errorText);
      return;
    }

    const data = await response.json();
    const result = data.candidates?.[0]?.content?.parts?.[0]?.text;
    
    if (result) {
      console.log("✅ API do Gemini funcionando!");
      console.log("🤖 Resposta do Orky:", result);
    } else {
      console.error("❌ Resposta vazia da API");
      console.error("📝 Dados completos:", JSON.stringify(data, null, 2));
    }
    
  } catch (error) {
    console.error("❌ Erro ao testar API:", error.message);
  }
}

// Executar o teste
testGeminiAPI();
