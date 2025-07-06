"""
Flask-based Legal-Library API
────────────────────────────
• MongoDB for data (acts, articles, cases, lawyers)
• Firebase Admin for authentication (signup, login, token verification)
• .env for ALL secrets (Mongo URI, Firebase creds, OpenRouter key, etc.)
"""

from flask import Flask, request, jsonify
from flask_cors import CORS
from pymongo import MongoClient
from dotenv import load_dotenv
import firebase_admin
from firebase_admin import credentials, auth, firestore
import requests
import logging
import os
import json
from math import radians, cos, sin, asin, sqrt

# ────────────────────────────────────────────────────────────────────────────────
#  ENV / LOGGING
# ────────────────────────────────────────────────────────────────────────────────
load_dotenv()                                              # Load .env variables

logging.basicConfig(level=logging.INFO,
                    format="%(asctime)s %(levelname)s %(message)s")
logger = logging.getLogger(__name__)

# ────────────────────────────────────────────────────────────────────────────────
#  FLASK APP INIT + CORS
# ────────────────────────────────────────────────────────────────────────────────
app = Flask(__name__)
CORS(app)                                                  # Allow all origins

# ────────────────────────────────────────────────────────────────────────────────
#  MONGODB CONNECTION
# ────────────────────────────────────────────────────────────────────────────────
mongo_uri = os.getenv("MONGO_URI")
client, db = None, None
if mongo_uri:
    try:
        client = MongoClient(mongo_uri, serverSelectionTimeoutMS=5_000)
        client.admin.command("ping")
        db = client["legal_library"]
        logger.info("✅ MongoDB connected")
    except Exception as e:
        logger.error(f"❌ MongoDB connection failed: {e}")
else:
    logger.warning("⚠️  MONGO_URI missing in .env")

# ────────────────────────────────────────────────────────────────────────────────
#  FIREBASE ADMIN INITIALISATION
# ────────────────────────────────────────────────────────────────────────────────
def init_firebase_admin() -> firestore.Client | None:
    """
    Build a service-account credentials dict from .env and
    initialise Firebase Admin. Returns Firestore client or None.
    """
    try:
        cred_dict = {
            "type": "service_account",
            "project_id": os.getenv("FIREBASE_PROJECT_ID"),
            "private_key_id": os.getenv("FIREBASE_PRIVATE_KEY_ID"),
            "private_key": os.getenv("FIREBASE_PRIVATE_KEY").replace("\\n", "\n"),
            "client_email": os.getenv("FIREBASE_CLIENT_EMAIL"),
            "client_id": os.getenv("FIREBASE_CLIENT_ID"),
            "auth_uri": os.getenv("FIREBASE_AUTH_URI"),
            "token_uri": os.getenv("FIREBASE_TOKEN_URI"),
        }
        cred = credentials.Certificate(cred_dict)
        firebase_admin.initialize_app(cred)
        logger.info("✅ Firebase Admin initialised")
        return firestore.client()
    except Exception as e:
        logger.error(f"❌ Firebase Admin init failed: {e}")
        return None

fs = init_firebase_admin()   # Firestore client (optional use)

# ────────────────────────────────────────────────────────────────────────────────
#  UTILITY HELPERS
# ────────────────────────────────────────────────────────────────────────────────
def validate_db_connection():
    if db is None:
        return False, "Database not connected"
    try:
        db.admin.command("ping")
        return True, "Connected"
    except Exception as e:
        return False, str(e)


def calculate_distance(lat1, lon1, lat2, lon2):
    """Haversine distance in KM."""
    lat1, lon1, lat2, lon2 = map(radians, [lat1, lon1, lat2, lon2])
    dlat, dlon = lat2 - lat1, lon2 - lon1
    a = sin(dlat / 2) ** 2 + cos(lat1) * cos(lat2) * sin(dlon / 2) ** 2
    return 2 * asin(sqrt(a)) * 6371  # Earth radius


# ────────────────────────────────────────────────────────────────────────────────
#  ROOT + HEALTH
# ────────────────────────────────────────────────────────────────────────────────
@app.route("/")
def index():
    return jsonify(
        message="✅ Legal Library Backend Running!",
        endpoints={
            "acts": "/acts",
            "articles": "/articles",
            "cases": "/cases",
            "lawyers": "/lawyers",
            "chat": "/chat",
            "auth": {
                "signup": "/auth/signup",
                "login": "/auth/login",
                "verify": "/auth/verify-token",
            },
        },
    )


@app.route("/health")
def health():
    ok, msg = validate_db_connection()
    return jsonify(status="healthy" if ok else "unhealthy",
                   database=msg,
                   server_time=str(os.times()))


@app.route("/ping")
def ping():
    return jsonify(message="pong", timestamp=str(os.times()))

# ────────────────────────────────────────────────────────────────────────────────
#  AUTHENTICATION ROUTES (Firebase Admin)
# ────────────────────────────────────────────────────────────────────────────────
@app.route("/auth/signup", methods=["POST"])
def signup():
    """
    Expects JSON: {name, email, password}
    Creates user in Firebase Auth & Firestore (optional) and returns UID.
    """
    try:
        data = request.get_json(force=True)
        user = auth.create_user(
            email=data["email"],
            password=data["password"],
            display_name=data.get("name", ""),
        )
        # Optional: store profile in Firestore
        if fs:
            fs.collection("users").document(user.uid).set({
                "uid": user.uid,
                "email": user.email,
                "name": user.display_name,
            })
        return jsonify(success=True, uid=user.uid, email=user.email)
    except Exception as e:
        logger.error(f"Signup error: {e}")
        return jsonify(success=False, message=str(e)), 400


@app.route("/auth/login", methods=["POST"])
def login():
    """
    Email/password verification MUST be done client-side with Firebase SDK.
    Our server will instead receive an ID token and exchange it for session info
    OR create a custom token that the client can use.
    For a simple backend-only demo, we accept {uid} and return a custom token.
    """
    try:
        uid = request.json.get("uid")  # Provided by your client
        if not uid:
            return jsonify(success=False, message="uid required"), 400

        custom_token = auth.create_custom_token(uid).decode("utf-8")
        return jsonify(success=True, customToken=custom_token)
    except Exception as e:
        logger.error(f"Login error: {e}")
        return jsonify(success=False, message=str(e)), 400


@app.route("/auth/verify-token", methods=["POST"])
def verify_token():
    """Client sends ID token; we verify and return uid & claims."""
    try:
        id_token = request.json.get("idToken")
        decoded = auth.verify_id_token(id_token)
        return jsonify(success=True, uid=decoded["uid"], claims=decoded)
    except Exception as e:
        logger.error(f"Token verify error: {e}")
        return jsonify(success=False, message="Invalid token"), 401


# ────────────────────────────────────────────────────────────────────────────────
#  DATA ROUTES  (Acts, Articles, Cases, Lawyers)
# ────────────────────────────────────────────────────────────────────────────────
@app.route("/acts")
def get_acts():
    try:
        if db is None:
            return jsonify(error="DB not connected"), 500
        acts = list(db.acts.find({}, {"_id": 0}))
        return jsonify(acts)
    except Exception as e:
        logger.error(e)
        return jsonify(error=str(e)), 500


@app.route("/acts/<act_id>")
def get_act_sections(act_id):
    try:
        if db is None:
            return jsonify(error="DB not connected"), 500
        act = db.acts.find_one(
            {"$or": [{"act_id": act_id}, {"act_name": {"$regex": act_id, "$options": "i"}}]},
            {"_id": 0},
        )
        if not act:
            return jsonify(error="Act not found"), 404
        return jsonify(act)
    except Exception as e:
        logger.error(e)
        return jsonify(error=str(e)), 500


@app.route("/articles")
def get_articles():
    try:
        if db is None:
            return jsonify(error="DB not connected"), 500
        return jsonify(list(db.articles.find({}, {"_id": 0})))
    except Exception as e:
        logger.error(e)
        return jsonify(error=str(e)), 500


@app.route("/cases")
def get_cases():
    try:
        if db is None:
            return jsonify(error="DB not connected"), 500
        return jsonify(list(db.cases.find({}, {"_id": 0})))
    except Exception as e:
        logger.error(e)
        return jsonify(error=str(e)), 500


@app.route("/lawyers")
def get_lawyers():
    try:
        if db is None:
            return jsonify(error="DB not connected"), 500

        # Filtering params
        q, city, exp, min_rating = (request.args.get("search", "").strip(),
                                    request.args.get("city"),
                                    request.args.get("expertise"),
                                    request.args.get("min_rating", type=float))
        lat, lng = request.args.get("lat", type=float), request.args.get("lng", type=float)
        radius = request.args.get("radius", type=float, default=50)

        query = {}
        if exp and exp != "All":
            query["expertise"] = exp
        if city and city != "All":
            query["city"] = city
        if min_rating:
            query["rating"] = {"$gte": min_rating}
        if q:
            query["$or"] = [
                {"name": {"$regex": q, "$options": "i"}},
                {"expertise": {"$regex": q, "$options": "i"}},
                {"city": {"$regex": q, "$options": "i"}},
                {"description": {"$regex": q, "$options": "i"}},
            ]

        lawyers = list(db.lawyers.find(query, {"_id": 0}))
        # Filter by distance
        if lat and lng:
            lawyers = [
                {**lw, "distance": calculate_distance(lat, lng, lw["latitude"], lw["longitude"])}
                for lw in lawyers
                if "latitude" in lw and "longitude" in lw
                and calculate_distance(lat, lng, lw["latitude"], lw["longitude"]) <= radius
            ]
            lawyers.sort(key=lambda x: x["distance"])
        return jsonify(lawyers)
    except Exception as e:
        logger.error(e)
        return jsonify(error=str(e)), 500

# ────────────────────────────────────────────────────────────────────────────────
#  AI CHAT ENDPOINT
# ────────────────────────────────────────────────────────────────────────────────
@app.route("/chat", methods=["POST", "OPTIONS"])
def chat():
    if request.method == "OPTIONS":
        return jsonify(message="CORS preflight OK"), 200

    try:
        user_msg = (request.get_json() or {}).get("message", "").strip()
        if not user_msg:
            return jsonify(reply="❌ No message provided"), 400

        api_key = os.getenv("OPENROUTER_API_KEY")
        if not api_key:
            return jsonify(reply="❌ AI service not configured"), 500

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
                    "content": (
                        "You are a helpful legal assistant for Indian law. "
                        "Provide accurate information while noting that you cannot provide legal advice "
                        "and users should consult qualified lawyers for specific matters."
                    ),
                },
                {"role": "user", "content": user_msg},
            ],
            "max_tokens": 1000,
            "temperature": 0.7,
        }
        resp = requests.post("https://openrouter.ai/api/v1/chat/completions",
                             headers=headers, data=json.dumps(payload), timeout=30)
        if resp.status_code == 200:
            reply = resp.json()["choices"][0]["message"]["content"]
            return jsonify(reply=reply)
        return jsonify(reply="❌ AI error", detail=resp.text[:200]), 500
    except requests.exceptions.Timeout:
        return jsonify(reply="❌ Request timeout"), 500
    except Exception as e:
        logger.error(e)
        return jsonify(reply="❌ Server error"), 500

# ────────────────────────────────────────────────────────────────────────────────
#  DEBUG ROUTES
# ────────────────────────────────────────────────────────────────────────────────
@app.route("/debug/db-status")
def debug_db_status():
    ok, msg = validate_db_connection()
    if not ok:
        return jsonify(status="error", message=msg), 500
    collections = db.list_collection_names()
    return jsonify(status="connected", collections=collections)


# ────────────────────────────────────────────────────────────────────────────────
#  ERROR HANDLERS
# ────────────────────────────────────────────────────────────────────────────────
@app.errorhandler(404)
def not_found(e):
    return jsonify(error="Endpoint not found"), 404


@app.errorhandler(500)
def server_error(e):
    logger.error(e)
    return jsonify(error="Internal server error"), 500


# ────────────────────────────────────────────────────────────────────────────────
#  ENTRY-POINT
# ────────────────────────────────────────────────────────────────────────────────
if __name__ == "__main__":
    port = int(os.getenv("PORT", 5000))
    debug_mode = os.getenv("FLASK_DEBUG", "false").lower() == "true"
    logger.info(f"🚀 Flask API running on 0.0.0.0:{port}  |  Debug={debug_mode}")
    logger.info(f"Mongo connected: {db is not None}")
    logger.info(f"Firebase Admin  : {fs is not None}")
    app.run(host="0.0.0.0", port=port, debug=debug_mode)



