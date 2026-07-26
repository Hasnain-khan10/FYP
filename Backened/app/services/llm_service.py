import os
import json
import re
import httpx
from typing import List, Optional

# ======================================================================
# 🏆 HYBRID ENGINE: GROQ (TEXT) & OPENROUTER MULTI-MODEL CHAIN (SCANNING)
# ======================================================================
async def call_ai(prompt: str, images: Optional[List[str]] = None, temperature: float = 0.3):
    if images is None:
        images = []
        
    # 🔥 CONDITION 1: VISION (SCANNING) -> AUTOMATIC MULTI-MODEL FALLBACK LOOP
    if len(images) > 0:
        openrouter_key = os.getenv("OPENROUTER_API_KEY")
        if not openrouter_key:
            raise ValueError("OPENROUTER_API_KEY is missing in your .env file!")
            
        print("🚀 Routing to OpenRouter Multi-Model Fallback Engine for Paper Scan...")
        url = "https://openrouter.ai/api/v1/chat/completions"
        
        message_content = [{"type": "text", "text": prompt}]
        for img in images:
            clean_base64 = img if img.startswith("data:image") else f"data:image/jpeg;base64,{img}"
            message_content.append({
                "type": "image_url",
                "image_url": {"url": clean_base64}
            })
            
        free_vision_models = [
            "google/gemini-2.5-flash",
            "meta-llama/llama-3.2-11b-vision-instruct",
            "qwen/qwen-2-vl-7b-instruct",
            "microsoft/phi-3-medium-128k-instruct"
        ]
        
        content = None
        last_error = None
        
        # Using httpx.AsyncClient for fast, non-blocking requests like axios
        async with httpx.AsyncClient(timeout=15.0) as client:
            for model_id in free_vision_models:
                try:
                    print(f"⏳ Trying Vision Model: {model_id}...")
                    payload = {
                        "model": model_id,
                        "messages": [{"role": "user", "content": message_content}],
                        "temperature": temperature
                    }
                    headers = {
                        "Authorization": f"Bearer {openrouter_key}",
                        "Content-Type": "application/json",
                        "HTTP-Referer": "https://smart-assistant.com",
                        "X-Title": "Smart Teacher Assistant"
                    }
                    
                    response = await client.post(url, json=payload, headers=headers)
                    response.raise_for_status()
                    
                    resp_data = response.json()
                    if resp_data.get("choices") and resp_data["choices"][0].get("message", {}).get("content"):
                        content = resp_data["choices"][0]["message"]["content"]
                        print(f"🎯 SCAN SUCCESSFUL! Handled by Model: {model_id}")
                        break
                        
                except Exception as err:
                    print(f"⚠️ Model [{model_id}] bypassed/failed. Reason: {str(err)}")
                    last_error = err
                    
        if not content:
            raise Exception(f"All free vision endpoints failed or are down. Last error: {str(last_error)}")
            
        # ✅ 100% UNBREAKABLE JSON EXTRACTOR & FAILSAFE
        try:
            first_curly = content.find("{")
            last_curly = content.rfind("}")
            
            if first_curly != -1 and last_curly != -1:
                extracted = content[first_curly:last_curly + 1]
                return json.loads(extracted.strip())
            else:
                raise ValueError("No JSON brackets found in AI response")
        except Exception:
            print("⚠️ Standard JSON Parse failed, trying aggressive regex clean...")
            try:
                cleaned = re.sub(r'```json', '', content, flags=re.IGNORECASE)
                cleaned = cleaned.replace('```', '').strip()
                return json.loads(cleaned)
            except Exception:
                print("🛑 AI IGNORED JSON RULES. RETURNING RAW TEXT AS FEEDBACK (CRASH PREVENTED).")
                return {
                    "obtained_marks": 0,
                    "feedback": content.strip()
                }
                
    # 🔥 CONDITION 2: PURE TEXT (WEEKLY PLAN / QUIZ GENERATION) -> RUNS ON GROQ UNTOUCHED
    else:
        groq_key = os.getenv("GROQ_API_KEY")
        if not groq_key:
            raise ValueError("GROQ_API_KEY is missing in your .env file!")
            
        active_model = "llama-3.3-70b-versatile"
        max_tokens = 7500 if "18-Week" in prompt or "weeks" in prompt else 3500
        
        url = "https://api.groq.com/openai/v1/chat/completions"
        payload = {
            "model": active_model,
            "messages": [{"role": "user", "content": str(prompt)}],
            "temperature": temperature,
            "max_tokens": max_tokens,
            "response_format": {"type": "json_object"}
        }
        headers = {
            "Authorization": f"Bearer {groq_key}",
            "Content-Type": "application/json"
        }
        
        print(f"🚀 Routing to Groq using Model: {active_model}...")
        
        async with httpx.AsyncClient(timeout=30.0) as client:
            try:
                response = await client.post(url, json=payload, headers=headers)
                response.raise_for_status()
                
                resp_data = response.json()
                content = resp_data["choices"][0]["message"]["content"]
                
                print("🤖 GROQ RAW RESPONSE RECEIVED SUCCESSFULLY")
                return json.loads(content)
            except Exception as error:
                print(f"❌ AI HYBRID SERVICE CRITICAL ERROR => {str(error)}")
                raise Exception(f"AI request failed. Please try again. {str(error)}")