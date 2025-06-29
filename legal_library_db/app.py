from flask import Flask, request, jsonify
from flask_cors import CORS
from pymongo import MongoClient
from dotenv import load_dotenv
import os
import requests
import json  # ADD THIS IMPORT

# Load environment variables from .env
load_dotenv()

# Initialize Flask app
app = Flask(__name__)
CORS(app)

# Connect to MongoDB
mongo_uri = os.getenv("MONGO_URI")
client = MongoClient(mongo_uri)
db = client["legal_library"]

# ======================= ROUTES =======================

# Home Route
@app.route('/')
def index():
    return '✅ Legal Library Backend is Running!'

# Get All Acts
@app.route('/acts', methods=['GET'])
def get_acts():
    acts = list(db.acts.find({}, {'_id': 0}))
    return jsonify(acts)

# Get Specific Act's Sections
@app.route('/acts/<act_id>', methods=['GET'])
def get_act_sections(act_id):
    sections = list(db.acts.find({'act_id': act_id}, {'_id': 0}))
    if not sections:
        return jsonify({"error": "Act not found"}), 404

    return jsonify({
        "act_id": act_id,
        "act_name": sections[0].get('act_name', ''),
        "description": sections[0].get('description', ''),
        "sections": [
            {
                "section_number": s.get("section_number", ""),
                "title": s.get("section_title", ""),
                "content": s.get("section_content", "")
            } for s in sections
        ]
    })

# Get Articles
@app.route('/articles', methods=['GET'])
def get_articles():
    articles = list(db.articles.find({}, {'_id': 0}))
    return jsonify(articles)

# Get Cases
@app.route('/cases', methods=['GET'])
def get_cases():
    cases = list(db.cases.find({}, {'_id': 0}))
    return jsonify(cases)

# AI Chatbot using OpenRouter - DEBUG VERSION
@app.route('/chat', methods=['POST'])
def chat():
    try:
        data = request.get_json()
        user_message = data.get("message", "").strip()

        if not user_message:
            return jsonify({"reply": "❌ No message provided"}), 400

        # Check if API key exists and log it (first few characters only for security)
        api_key = os.getenv('OPENROUTER_API_KEY')
        if not api_key:
            print("ERROR: OPENROUTER_API_KEY not found in environment variables")
            return jsonify({"reply": "❌ API key not configured on server"}), 500
        
        print(f"API Key found: {api_key[:10]}...")  # Log first 10 chars for debugging
        
        # OpenRouter API Request
        headers = {
            "Authorization": f"Bearer {api_key}",
            "Content-Type": "application/json",
            "HTTP-Referer": os.getenv("SITE_URL", "https://law-and-order-app.onrender.com"),
            "X-Title": os.getenv("SITE_TITLE", "Nyaya Sahayak"),
        }
        
        payload = {
            "model": "deepseek/deepseek-chat",
            "messages": [
                {"role": "system", "content": "You are a helpful legal assistant for Indian law. Provide accurate information while noting that you cannot provide legal advice and users should consult qualified lawyers."},
                {"role": "user", "content": user_message}
            ]
        }
        
        print(f"Sending request to OpenRouter...")  # Debug log
        
        response = requests.post(
            url="https://openrouter.ai/api/v1/chat/completions",
            headers=headers,
            data=json.dumps(payload),
            timeout=30  # Add timeout
        )

        print(f"OpenRouter response status: {response.status_code}")  # Debug log
        
        if response.status_code == 200:
            reply_data = response.json()
            reply = reply_data["choices"][0]["message"]["content"]
            return jsonify({"reply": reply})
        elif response.status_code == 401:
            print(f"401 Unauthorized - API key might be invalid")
            print(f"Response: {response.text}")
            return jsonify({
                "reply": "❌ Authentication failed. API key might be invalid or expired.",
                "detail": "Please check OpenRouter API key configuration"
            }), 500
        else:
            print(f"OpenRouter API Error: {response.status_code} - {response.text}")
            return jsonify({
                "reply": f"❌ AI service error (Status: {response.status_code})",
                "detail": response.text[:200]  # Limit error message length
            }), 500

    except requests.exceptions.Timeout:
        return jsonify({"reply": "❌ Request timeout. Please try again."}), 500
    except requests.exceptions.RequestException as e:
        print(f"Request error: {str(e)}")
        return jsonify({"reply": "❌ Network error connecting to AI service"}), 500
    except Exception as e:
        print(f"Chat endpoint error: {str(e)}")
        return jsonify({"reply": "❌ Server error", "error": str(e)}), 500

# ======================= RUN =======================

if __name__ == "__main__":
    port = int(os.environ.get("PORT", 5000))
    app.run(host="0.0.0.0", port=port, debug=True)


