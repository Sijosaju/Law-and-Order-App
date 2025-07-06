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
import re
import smtplib
from email.mime.text import MIMEText
from email.mime.multipart import MIMEMultipart
from math import radians, cos, sin, asin, sqrt

# ────────────────────────────────────────────────────────────────────────────────
#  ENV / LOGGING
# ────────────────────────────────────────────────────────────────────────────────
load_dotenv()
logging.basicConfig(level=logging.INFO, format="%(asctime)s %(levelname)s %(message)s")
logger = logging.getLogger(__name__)

# ────────────────────────────────────────────────────────────────────────────────
#  FLASK APP INIT + CORS
# ────────────────────────────────────────────────────────────────────────────────
app = Flask(__name__)
CORS(app)

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
    logger.warning("⚠️ MONGO_URI missing in .env")

# ────────────────────────────────────────────────────────────────────────────────
#  FIREBASE ADMIN INITIALISATION
# ────────────────────────────────────────────────────────────────────────────────
def init_firebase_admin():
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

fs = init_firebase_admin()

# ────────────────────────────────────────────────────────────────────────────────
#  UTILITY HELPERS
# ────────────────────────────────────────────────────────────────────────────────
def is_valid_email(email):
    pattern = r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$'
    return re.match(pattern, email) is not None

def is_strong_password(password):
    if len(password) < 6:
        return False, "Password must be at least 6 characters"
    if not re.search(r'[A-Za-z]', password):
        return False, "Password must contain at least one letter"
    if not re.search(r'\d', password):
        return False, "Password must contain at least one number"
    return True, "Password is strong"

def send_email_smtp(to_email, subject, html_content):
    """Send email using SMTP (Gmail) with proper UTF-8 encoding"""
    try:
        smtp_server = "smtp.gmail.com"
        smtp_port = 587
        sender_email = os.getenv('SMTP_EMAIL')
        sender_password = os.getenv('SMTP_PASSWORD')
        
        if not sender_email or not sender_password:
            logger.error("SMTP credentials not configured")
            return False
        
        message = MIMEMultipart("alternative")
        message["Subject"] = subject
        message["From"] = sender_email
        message["To"] = to_email

        # Use UTF-8 encoding for the HTML content
        html_part = MIMEText(html_content, "html", "utf-8")
        message.attach(html_part)
        
        server = smtplib.SMTP(smtp_server, smtp_port)
        server.starttls()
        server.login(sender_email, sender_password)
        server.sendmail(sender_email, to_email, message.as_string().encode('utf-8'))
        server.quit()
        
        logger.info(f"Email sent successfully to {to_email}")
        return True
        
    except Exception as e:
        logger.error(f"SMTP email failed: {e}")
        return False

def send_verification_email(email, name, verification_link):
    html_content = f"""
    <html>
      <body style="font-family: Arial, sans-serif;">
        <h2>Welcome to LexAid, {name}!</h2>
        <p>Thank you for creating an account with LexAid.</p>
        <p>Click the link below to verify your email:</p>
        <a href="{verification_link}">{verification_link}</a>
        <p>If you did not create this account, you can ignore this email.</p>
      </body>
    </html>
    """
    return send_email_smtp(email, "Verify Your LexAid Account", html_content)

def send_password_reset_email(email, name, reset_link):
    html_content = f"""
    <html>
      <body style="font-family: Arial, sans-serif;">
        <h2>Password Reset Request</h2>
        <p>Hi {name},</p>
        <p>Click the link below to reset your password:</p>
        <a href="{reset_link}">{reset_link}</a>
        <p>If you did not request this, you can ignore this email.</p>
      </body>
    </html>
    """
    return send_email_smtp(email, "Reset Your LexAid Password", html_content)

def validate_db_connection():
    if db is None:
        return False, "Database not connected"
    try:
        db.admin.command("ping")
        return True, "Connected"
    except Exception as e:
        return False, str(e)

def calculate_distance(lat1, lon1, lat2, lon2):
    lat1, lon1, lat2, lon2 = map(radians, [lat1, lon1, lat2, lon2])
    dlat, dlon = lat2 - lat1, lon2 - lon1
    a = sin(dlat / 2) ** 2 + cos(lat1) * cos(lat2) * sin(dlon / 2) ** 2
    return 2 * asin(sqrt(a)) * 6371

# ────────────────────────────────────────────────────────────────────────────────
#  ROOT + HEALTH
# ────────────────────────────────────────────────────────────────────────────────
@app.route("/")
def index():
    return jsonify(
        message="✅ Legal Library Backend Running!",
        version="2.0.0",
        features=["Email Validation", "Password Recovery", "Email Verification"],
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
                "forgot_password": "/auth/forgot-password",
                "resend_verification": "/auth/resend-verification"
            },
        },
    )

@app.route("/health")
def health():
    ok, msg = validate_db_connection()
    return jsonify(
        status="healthy" if ok else "unhealthy",
        database=msg,
        firebase_admin=fs is not None,
        email_service=bool(os.getenv('SMTP_EMAIL')),
        environment_vars={
            'mongo_uri': bool(os.getenv('MONGO_URI')),
            'firebase_project_id': bool(os.getenv('FIREBASE_PROJECT_ID')),
            'openrouter_key': bool(os.getenv('OPENROUTER_API_KEY')),
            'smtp_configured': bool(os.getenv('SMTP_EMAIL') and os.getenv('SMTP_PASSWORD'))
        }
    )

@app.route("/ping")
def ping():
    return jsonify(message="pong")

# ────────────────────────────────────────────────────────────────────────────────
#  AUTHENTICATION ROUTES
# ────────────────────────────────────────────────────────────────────────────────
@app.route("/auth/signup", methods=["POST"])
def signup():
    try:
        data = request.get_json(force=True)
        email = data.get("email", "").strip().lower()
        password = data.get("password", "")
        name = data.get("name", "").strip()
        if not email or not password or not name:
            return jsonify(success=False, message="All fields are required"), 400
        if not is_valid_email(email):
            return jsonify(success=False, message="Invalid email format"), 400
        is_strong, password_msg = is_strong_password(password)
        if not is_strong:
            return jsonify(success=False, message=password_msg), 400
        user = auth.create_user(
            email=email,
            password=password,
            display_name=name,
            email_verified=False
        )
        try:
            verification_link = auth.generate_email_verification_link(email)
            email_sent = send_verification_email(email, name, verification_link)
            if not email_sent:
                logger.warning(f"Failed to send verification email to {email}")
        except Exception as e:
            logger.error(f"Email verification link generation failed: {e}")
        try:
            if fs:
                fs.collection("users").document(user.uid).set({
                    "uid": user.uid,
                    "email": user.email,
                    "name": user.display_name,
                    "email_verified": False,
                    "created_at": firestore.SERVER_TIMESTAMP
                })
        except Exception as e:
            logger.warning(f"Firestore write failed: {e}")
        return jsonify(
            success=True, 
            uid=user.uid, 
            email=user.email, 
            name=user.display_name,
            message="Account created successfully! Please check your email for verification link."
        )
    except auth.EmailAlreadyExistsError:
        return jsonify(success=False, message="An account with this email already exists"), 400
    except Exception as e:
        logger.error(f"Signup error: {e}")
        return jsonify(success=False, message="Account creation failed. Please try again."), 400

@app.route("/auth/login", methods=["POST"])
def login():
    try:
        data = request.get_json(force=True)
        email = data.get("email", "").strip().lower()
        password = data.get("password", "")
        if not email or not password:
            return jsonify(success=False, message="Email and password are required"), 400
        if not is_valid_email(email):
            return jsonify(success=False, message="Invalid email format"), 400
        try:
            user = auth.get_user_by_email(email)
        except auth.UserNotFoundError:
            return jsonify(success=False, message="Invalid email or password"), 401
        if not user.email_verified:
            return jsonify(
                success=False, 
                message="Please verify your email before logging in. Check your inbox for verification link.",
                email_not_verified=True
            ), 401
        custom_token = auth.create_custom_token(user.uid).decode("utf-8")
        return jsonify(
            success=True, 
            customToken=custom_token,
            uid=user.uid,
            email=user.email,
            name=user.display_name,
            email_verified=user.email_verified
        )
    except Exception as e:
        logger.error(f"Login error: {e}")
        return jsonify(success=False, message="Login failed. Please try again."), 401

@app.route("/auth/forgot-password", methods=["POST"])
def forgot_password():
    try:
        data = request.get_json(force=True)
        email = data.get("email", "").strip().lower()
        if not email:
            return jsonify(success=False, message="Email is required"), 400
        if not is_valid_email(email):
            return jsonify(success=False, message="Invalid email format"), 400
        try:
            user = auth.get_user_by_email(email)
        except auth.UserNotFoundError:
            return jsonify(
                success=True, 
                message="If an account with this email exists, a password reset link has been sent."
            ), 200
        try:
            reset_link = auth.generate_password_reset_link(email)
            email_sent = send_password_reset_email(email, user.display_name or "User", reset_link)
            if email_sent:
                return jsonify(success=True, message="Password reset email sent successfully")
            else:
                return jsonify(success=False, message="Failed to send reset email. Please try again."), 500
        except Exception as e:
            logger.error(f"Password reset link generation failed: {e}")
            return jsonify(success=False, message="Failed to generate reset link"), 500
    except Exception as e:
        logger.error(f"Password reset error: {e}")
        return jsonify(success=False, message="Password reset failed. Please try again."), 500

@app.route("/auth/resend-verification", methods=["POST"])
def resend_verification():
    try:
        data = request.get_json(force=True)
        email = data.get("email", "").strip().lower()
        if not email:
            return jsonify(success=False, message="Email is required"), 400
        if not is_valid_email(email):
            return jsonify(success=False, message="Invalid email format"), 400
        try:
            user = auth.get_user_by_email(email)
        except auth.UserNotFoundError:
            return jsonify(success=False, message="No account found with this email"), 404
        if user.email_verified:
            return jsonify(success=False, message="Email is already verified"), 400
        verification_link = auth.generate_email_verification_link(email)
        email_sent = send_verification_email(email, user.display_name or "User", verification_link)
        if email_sent:
            return jsonify(success=True, message="Verification email sent successfully")
        else:
            return jsonify(success=False, message="Failed to send verification email"), 500
    except Exception as e:
        logger.error(f"Resend verification error: {e}")
        return jsonify(success=False, message="Failed to resend verification email"), 500

@app.route("/auth/verify-token", methods=["POST"])
def verify_token():
    try:
        id_token = request.json.get("idToken")
        if not id_token:
            return jsonify(success=False, message="ID token required"), 400
        decoded = auth.verify_id_token(id_token)
        return jsonify(success=True, uid=decoded["uid"], claims=decoded)
    except Exception as e:
        logger.error(f"Token verify error: {e}")
        return jsonify(success=False, message="Invalid token"), 401

# ────────────────────────────────────────────────────────────────────────────────
#  DATA ROUTES
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
        q, city, exp, min_rating = (
            request.args.get("search", "").strip(),
            request.args.get("city"),
            request.args.get("expertise"),
            request.args.get("min_rating", type=float)
        )
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
            "X-Title": os.getenv("SITE_TITLE", "LexAid"),
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

@app.route("/debug/db-status")
def debug_db_status():
    ok, msg = validate_db_connection()
    if not ok:
        return jsonify(status="error", message=msg), 500
    collections = db.list_collection_names()
    return jsonify(status="connected", collections=collections)

@app.errorhandler(404)
def not_found(e):
    return jsonify(error="Endpoint not found"), 404

@app.errorhandler(500)
def server_error(e):
    logger.error(e)
    return jsonify(error="Internal server error"), 500

if __name__ == "__main__":
    port = int(os.getenv("PORT", 5000))
    debug_mode = os.getenv("FLASK_DEBUG", "false").lower() == "true"
    logger.info(f"🚀 Flask API running on 0.0.0.0:{port} | Debug={debug_mode}")
    logger.info(f"Mongo connected: {db is not None}")
    logger.info(f"Firebase Admin: {fs is not None}")
    logger.info(f"Email service: {bool(os.getenv('SMTP_EMAIL'))}")
    app.run(host="0.0.0.0", port=port, debug=debug_mode)







