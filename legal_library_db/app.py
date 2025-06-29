from flask import Flask, request, jsonify
from flask_cors import CORS
from pymongo import MongoClient
from dotenv import load_dotenv
import os
import requests

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

# AI Chatbot using OpenRouter
@app.route('/chat', methods=['POST'])
def chat():
    try:
        data = request.get_json()
        user_message = data.get("message", "").strip()

        if not user_message:
            return jsonify({"reply": "❌ No message provided"}), 400

        # OpenRouter API Request
        response = requests.post(
            url="https://openrouter.ai/api/v1/chat/completions",
            headers={
                "Authorization": f"Bearer {os.getenv('OPENROUTER_API_KEY')}",
                "Content-Type": "application/json",
                "HTTP-Referer": os.getenv("SITE_URL", "https://yourapp.com"),
                "X-Title": os.getenv("SITE_TITLE", "Nyaya Sahayak"),
            },
            json={
                "model": "deepseek/deepseek-chat",
                "messages": [
                    {"role": "system", "content": "You are a helpful legal assistant for Indian law."},
                    {"role": "user", "content": user_message}
                ]
            }
        )

        if response.status_code == 200:
            reply = response.json()["choices"][0]["message"]["content"]
            return jsonify({"reply": reply})
        else:
            return jsonify({"reply": "❌ Failed to fetch reply", "detail": response.text}), response.status_code

    except Exception as e:
        return jsonify({"reply": "❌ Server error", "error": str(e)}), 500

# ======================= RUN =======================

if __name__ == "__main__":
    port = int(os.environ.get("PORT", 5000))
    app.run(host="0.0.0.0", port=port, debug=True)


