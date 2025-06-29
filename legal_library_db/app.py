from flask import Flask, request, jsonify
from flask_cors import CORS
from pymongo import MongoClient
from dotenv import load_dotenv
import os
import requests
import json
import logging

# Load environment variables from .env
load_dotenv()

# Initialize Flask app
app = Flask(__name__)
CORS(app)  # Enable CORS for all routes

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Connect to MongoDB
mongo_uri = os.getenv("MONGO_URI")
client = None
db = None

if mongo_uri:
    try:
        client = MongoClient(mongo_uri, serverSelectionTimeoutMS=5000)
        client.admin.command('ping')
        db = client["legal_library"]
        logger.info("✅ MongoDB connected successfully")
    except Exception as e:
        logger.error(f"❌ MongoDB connection failed: {str(e)}")
        db = None
else:
    logger.warning("⚠️ MONGO_URI not found in environment variables")
    db = None

# ======================= UTILITY FUNCTIONS =======================

def validate_db_connection():
    if db is None:
        return False, "Database not connected"
    try:
        db.admin.command('ping')
        return True, "Connected"
    except Exception as e:
        return False, str(e)

# ======================= ROUTES =======================

@app.route('/')
def index():
    return jsonify({
        "message": "✅ Legal Library Backend is Running!",
        "endpoints": {
            "acts": "/acts",
            "articles": "/articles", 
            "cases": "/cases",
            "chat": "/chat",
            "debug": "/debug/db-status"
        }
    })

@app.route('/health')
def health_check():
    db_connected, db_message = validate_db_connection()
    return jsonify({
        "status": "healthy" if db_connected else "unhealthy",
        "database": db_message,
        "server_time": str(os.times()),
        "message": "Server is running properly"
    })

@app.route('/ping')
def ping():
    return jsonify({
        "message": "pong",
        "timestamp": str(os.times()),
        "server": "Flask Legal Library API"
    })

@app.route('/debug/db-status')
def debug_db_status():
    try:
        if db is None:
            return jsonify({
                "status": "error", 
                "message": "Database not connected", 
                "mongo_uri_exists": bool(mongo_uri)
            }), 500

        db.admin.command('ping')
        collections = db.list_collection_names()
        acts_count = db.acts.count_documents({})
        articles_count = db.articles.count_documents({})
        cases_count = db.cases.count_documents({})

        sample_act = db.acts.find_one({}, {'_id': 0}) if acts_count > 0 else None
        sample_article = db.articles.find_one({}, {'_id': 0}) if articles_count > 0 else None
        sample_case = db.cases.find_one({}, {'_id': 0}) if cases_count > 0 else None

        return jsonify({
            "status": "connected",
            "database_name": db.name,
            "collections": collections,
            "document_counts": {
                "acts": acts_count,
                "articles": articles_count,
                "cases": cases_count
            },
            "sample_data": {
                "act": sample_act,
                "article": sample_article,
                "case": sample_case
            }
        })
    except Exception as e:
        logger.error(f"Database debug error: {str(e)}")
        return jsonify({"status": "error", "message": str(e)}), 500

@app.route('/test', methods=['GET', 'POST'])
def test():
    if request.method == 'GET':
        return jsonify({"message": "GET request works", "timestamp": str(os.times())})
    elif request.method == 'POST':
        data = request.get_json() or {}
        return jsonify({"message": "POST request works", "data": data})

@app.route('/acts', methods=['GET'])
def get_acts():
    try:
        logger.info("📚 Fetching acts from database...")
        if db is None:  # ✅ FIXED: Compare with None instead of using 'not db'
            logger.error("Database not connected")
            return jsonify({"error": "Database not connected"}), 500
        acts_cursor = db.acts.find({}, {'_id': 0})
        acts = list(acts_cursor)
        logger.info(f"Found {len(acts)} acts")
        if not acts:
            logger.warning("No acts found in database")
            return jsonify([])
        logger.info(f"First act structure: {list(acts[0].keys())}")
        return jsonify(acts)
    except Exception as e:
        logger.error(f"Error in get_acts: {str(e)}")
        return jsonify({"error": f"Failed to fetch acts: {str(e)}"}), 500

@app.route('/acts/<act_id>', methods=['GET'])
def get_act_sections(act_id):
    try:
        logger.info(f"📖 Fetching sections for act ID: {act_id}")
        if db is None:  # ✅ FIXED: Compare with None
            return jsonify({"error": "Database not connected"}), 500
        act = db.acts.find_one({
            "$or": [
                {"act_id": act_id},
                {"act_name": {"$regex": act_id, "$options": "i"}}
            ]
        }, {'_id': 0})
        if not act:
            logger.warning(f"Act not found: {act_id}")
            return jsonify({"error": "Act not found"}), 404
        return jsonify(act)
    except Exception as e:
        logger.error(f"Error in get_act_sections: {str(e)}")
        return jsonify({"error": f"Failed to fetch act sections: {str(e)}"}), 500

@app.route('/articles', methods=['GET'])
def get_articles():
    try:
        logger.info("📰 Fetching articles from database...")
        if db is None:  # ✅ FIXED: Compare with None
            logger.error("Database not connected")
            return jsonify({"error": "Database not connected"}), 500
        articles_cursor = db.articles.find({}, {'_id': 0})
        articles = list(articles_cursor)
        logger.info(f"Found {len(articles)} articles")
        if not articles:
            logger.warning("No articles found in database")
            return jsonify([])
        logger.info(f"First article structure: {list(articles[0].keys())}")
        return jsonify(articles)
    except Exception as e:
        logger.error(f"Error in get_articles: {str(e)}")
        return jsonify({"error": f"Failed to fetch articles: {str(e)}"}), 500

@app.route('/cases', methods=['GET'])
def get_cases():
    try:
        logger.info("⚖️ Fetching cases from database...")
        if db is None:  # ✅ FIXED: Compare with None
            logger.error("Database not connected")
            return jsonify({"error": "Database not connected"}), 500
        cases_cursor = db.cases.find({}, {'_id': 0})
        cases = list(cases_cursor)
        logger.info(f"Found {len(cases)} cases")
        if not cases:
            logger.warning("No cases found in database")
            return jsonify([])
        logger.info(f"First case structure: {list(cases[0].keys())}")
        return jsonify(cases)
    except Exception as e:
        logger.error(f"Error in get_cases: {str(e)}")
        return jsonify({"error": f"Failed to fetch cases: {str(e)}"}), 500

@app.route('/chat', methods=['POST', 'OPTIONS'])
def chat():
    if request.method == 'OPTIONS':
        return jsonify({"message": "CORS preflight successful"}), 200

    try:
        logger.info("🤖 Chat endpoint called")
        data = request.get_json()
        if not data:
            return jsonify({"reply": "❌ No JSON data received"}), 400

        user_message = data.get("message", "").strip()
        logger.info(f"User message received: {user_message[:50]}...")

        if not user_message:
            return jsonify({"reply": "❌ No message provided"}), 400

        api_key = os.getenv('OPENROUTER_API_KEY')
        if not api_key:
            logger.error("OPENROUTER_API_KEY not found")
            return jsonify({"reply": "❌ AI service not configured"}), 500

        logger.info("Making request to OpenRouter...")
        headers = {
            "Authorization": f"Bearer {api_key}",
            "Content-Type": "application/json",
            "HTTP-Referer": os.getenv("SITE_URL", "https://law-and-order-app.onrender.com"),
            "X-Title": os.getenv("SITE_TITLE", "Nyaya Sahayak"),
        }
        payload = {
            "model": "deepseek/deepseek-chat",
            "messages": [
                {
                    "role": "system", 
                    "content": "You are a helpful legal assistant for Indian law. Provide accurate information while noting that you cannot provide legal advice and users should consult qualified lawyers for specific legal matters."
                },
                {"role": "user", "content": user_message}
            ],
            "max_tokens": 1000,
            "temperature": 0.7
        }

        response = requests.post(
            url="https://openrouter.ai/api/v1/chat/completions",
            headers=headers,
            data=json.dumps(payload),
            timeout=30
        )

        logger.info(f"OpenRouter response status: {response.status_code}")

        if response.status_code == 200:
            reply_data = response.json()
            reply = reply_data["choices"][0]["message"]["content"]
            logger.info(f"Reply generated successfully: {len(reply)} characters")
            return jsonify({"reply": reply})
        else:
            error_msg = f"OpenRouter API Error: {response.status_code}"
            logger.error(f"{error_msg} - {response.text}")
            return jsonify({
                "reply": f"❌ AI service error (Status: {response.status_code})",
                "detail": response.text[:200]
            }), 500

    except requests.exceptions.Timeout:
        logger.error("Request timeout to OpenRouter")
        return jsonify({"reply": "❌ Request timeout. Please try again."}), 500
    except requests.exceptions.RequestException as e:
        logger.error(f"Request error: {str(e)}")
        return jsonify({"reply": "❌ Network error connecting to AI service"}), 500
    except Exception as e:
        logger.error(f"Chat endpoint error: {str(e)}")
        return jsonify({"reply": "❌ Server error occurred"}), 500

@app.route('/debug/collections', methods=['GET'])
def debug_collections():
    try:
        if db is None:  # ✅ FIXED: Compare with None
            return jsonify({"error": "Database not connected"}), 500
        result = {}
        collections = ['acts', 'articles', 'cases']
        for collection_name in collections:
            collection = db[collection_name]
            count = collection.count_documents({})
            sample = collection.find_one({}, {'_id': 0})
            field_names = set()
            for doc in collection.find({}).limit(5):
                field_names.update(doc.keys())
            field_names.discard('_id')
            result[collection_name] = {
                "count": count,
                "sample_document": sample,
                "all_fields": list(field_names)
            }
        return jsonify(result)
    except Exception as e:
        logger.error(f"Error inspecting collections: {str(e)}")
        return jsonify({"error": str(e)}), 500

@app.errorhandler(404)
def not_found(error):
    return jsonify({"error": "Endpoint not found"}), 404

@app.errorhandler(405)
def method_not_allowed(error):
    return jsonify({"error": "Method not allowed for this endpoint"}), 405

@app.errorhandler(500)
def internal_error(error):
    logger.error(f"Internal server error: {str(error)}")
    return jsonify({"error": "Internal server error"}), 500

if __name__ == "__main__":
    port = int(os.environ.get("PORT", 5000))
    debug_mode = os.environ.get("FLASK_DEBUG", "False").lower() == "true"

    logger.info(f"🚀 Starting Flask app on port {port}")
    logger.info(f"Debug mode: {debug_mode}")
    logger.info(f"Database connected: {db is not None}")  # ✅ FIXED: Compare with None

    app.run(host="0.0.0.0", port=port, debug=debug_mode)

