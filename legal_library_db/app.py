from flask import Flask, request, jsonify
from flask_cors import CORS
from pymongo import MongoClient
from dotenv import load_dotenv
import os
import requests
import json

# Load environment variables from .env
load_dotenv()

# Initialize Flask app
app = Flask(__name__)
CORS(app)  # Enable CORS for all routes

# Connect to MongoDB
mongo_uri = os.getenv("MONGO_URI")
if mongo_uri:
    client = MongoClient(mongo_uri)
    db = client["legal_library"]
else:
    print("WARNING: MONGO_URI not found in environment variables")
    db = None

# ======================= ROUTES =======================

# Home Route
@app.route('/')
def index():
    return '✅ Legal Library Backend is Running!'

# Test route to verify POST works
@app.route('/test', methods=['GET', 'POST'])
def test():
    if request.method == 'GET':
        return jsonify({"message": "GET request works"})
    elif request.method == 'POST':
        return jsonify({"message": "POST request works", "data": request.get_json()})

# Get All Acts
@app.route('/acts', methods=['GET'])
def get_acts():
    if not db:
        return jsonify({"error": "Database not connected"}), 500
    acts = list(db.acts.find({}, {'_id': 0}))
    return jsonify(acts)

# Get Specific Act's Sections
@app.route('/acts/<act_id>', methods=['GET'])
def get_act_sections(act_id):
    if not db:
        return jsonify({"error": "Database not connected"}), 500
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
    if not db:
        return jsonify({"error": "Database not connected"}), 500
    articles = list(db.articles.find({}, {'_id': 0}))
    return jsonify(articles)

# Get Cases
@app.route('/cases', methods=['GET'])
def get_cases():
    if not db:
        return jsonify({"error": "Database not connected"}), 500
    cases = list(db.cases.find({}, {'_id': 0}))
    return jsonify(cases)

# AI Chatbot using OpenRouter
@app.route('/chat', methods=['POST', 'OPTIONS'])  # Added OPTIONS for CORS
def chat():
    # Handle CORS preflight request
    if request.method == 'OPTIONS':
        return jsonify({"message": "CORS preflight successful"}), 200
    
    try:
        print("Chat endpoint called")  # Debug log
        
        # Get JSON data from request
        data = request.get_json()
        if not data:
            return jsonify({"reply": "❌ No JSON data received"}), 400
            
        user_message = data.get("message", "").strip()
        print(f"User message: {user_message}")  # Debug log

        if not user_message:
            return jsonify({"reply": "❌ No message provided"}), 400

        # Check if API key exists
        api_key = os.getenv('OPENROUTER_API_KEY')
        if not api_key:
            print("ERROR: OPENROUTER_API_KEY not found")
            return jsonify({"reply": "❌ API key not configured on server"}), 500
        
        print(f"API Key found: {api_key[:15]}...")  # Debug log (first 15 chars)
        
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
        
        print("Sending request to OpenRouter...")  # Debug log
        
        response = requests.post(
            url="https://openrouter.ai/api/v1/chat/completions",
            headers=headers,
            data=json.dumps(payload),
            timeout=30
        )

        print(f"OpenRouter response status: {response.status_code}")  # Debug log
        
        if response.status_code == 200:
            reply_data = response.json()
            reply = reply_data["choices"][0]["message"]["content"]
            print(f"Reply received: {reply[:50]}...")  # Debug log (first 50 chars)
            return jsonify({"reply": reply})
        else:
            error_msg = f"OpenRouter API Error: {response.status_code}"
            print(f"{error_msg} - {response.text}")
            return jsonify({
                "reply": f"❌ AI service error (Status: {response.status_code})",
                "detail": response.text[:200]
            }), 500

    except requests.exceptions.Timeout:
        return jsonify({"reply": "❌ Request timeout. Please try again."}), 500
    except requests.exceptions.RequestException as e:
        print(f"Request error: {str(e)}")
        return jsonify({"reply": "❌ Network error connecting to AI service"}), 500
    except Exception as e:
        print(f"Chat endpoint error: {str(e)}")
        return jsonify({"reply": "❌ Server error", "error": str(e)}), 500

# ======================= ERROR HANDLERS =======================

@app.errorhandler(404)
def not_found(error):
    return jsonify({"error": "Endpoint not found"}), 404

@app.errorhandler(405)
def method_not_allowed(error):
    return jsonify({"error": "Method not allowed for this endpoint"}), 405

# ======================= RUN =======================

if __name__ == "__main__":
    port = int(os.environ.get("PORT", 5000))
    print(f"Starting Flask app on port {port}")
    app.run(host="0.0.0.0", port=port, debug=True)


