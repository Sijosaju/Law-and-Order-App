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
# ENV / LOGGING
# ──────────────────────────────────────────────────────────────────────────────── 

load_dotenv()

logging.basicConfig(level=logging.INFO, format="%(asctime)s %(levelname)s %(message)s")
logger = logging.getLogger(__name__)

# ──────────────────────────────────────────────────────────────────────────────── 
# FLASK APP INIT + CORS
# ──────────────────────────────────────────────────────────────────────────────── 

app = Flask(__name__)
CORS(app)

# ──────────────────────────────────────────────────────────────────────────────── 
# MONGODB CONNECTION
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
# FIREBASE ADMIN INITIALISATION
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
# UTILITY HELPERS
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
    <h2>Welcome to LexAid!</h2>
    <p>Hi {name},</p>
    <p>Thank you for creating an account with LexAid.</p>
    <p>Click the link below to verify your email:</p>
    <a href="{verification_link}">Verify Email</a>
    <p>If you did not create this account, you can ignore this email.</p>
    """
    return send_email_smtp(email, "Verify Your LexAid Account", html_content)

def send_password_reset_email(email, name, reset_link):
    html_content = f"""
    <h2>Password Reset Request</h2>
    <p>Hi {name},</p>
    <p>Click the link below to reset your password:</p>
    <a href="{reset_link}">Reset Password</a>
    <p>If you did not request this, you can ignore this email.</p>
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
# ROOT + HEALTH
# ──────────────────────────────────────────────────────────────────────────────── 

@app.route("/")
def index():
    return jsonify(
        message="✅ Legal Library Backend Running!",
        version="2.0.0",
        features=["Email Validation", "Password Recovery", "Email Verification", "FIR Management", "Location Services"],
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
            "locations": {
                "states": "/api/locations/states",
                "districts": "/api/locations/districts/<state_code>",
                "police_stations": "/api/locations/police-stations/<district_code>"
            },
            "fir": {
                "create": "/api/fir",
                "track": "/api/fir/<fir_id>"
            }
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
# AUTHENTICATION ROUTES
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
# LOCATION ROUTES
# ──────────────────────────────────────────────────────────────────────────────── 

@app.route("/api/locations/states", methods=["GET"])
def get_states():
    try:
        if db is None:
            return jsonify(error="Database not connected"), 500
        
        states = list(db.states.find({}, {"_id": 0}).sort("name", 1))
        return jsonify(states)
    except Exception as e:
        logger.error(f"States fetch error: {e}")
        return jsonify(error=str(e)), 500

@app.route("/api/locations/districts/<state_code>", methods=["GET"])
def get_districts(state_code):
    try:
        if db is None:
            return jsonify(error="Database not connected"), 500
        
        districts = list(db.districts.find(
            {"state_code": state_code}, 
            {"_id": 0}
        ).sort("name", 1))
        return jsonify(districts)
    except Exception as e:
        logger.error(f"Districts fetch error: {e}")
        return jsonify(error=str(e)), 500

@app.route("/api/locations/police-stations/<district_code>", methods=["GET"])
def get_police_stations(district_code):
    try:
        if db is None:
            return jsonify(error="Database not connected"), 500
        
        stations = list(db.police_stations.find(
            {"district_code": district_code}, 
            {"_id": 0}
        ).sort("name", 1))
        return jsonify(stations)
    except Exception as e:
        logger.error(f"Police stations fetch error: {e}")
        return jsonify(error=str(e)), 500

# ──────────────────────────────────────────────────────────────────────────────── 
# FIR ROUTES
# ──────────────────────────────────────────────────────────────────────────────── 

@app.route("/api/fir", methods=["POST"])
def create_fir():
    try:
        fir_data = request.get_json()
        
        if not fir_data:
            return jsonify(success=False, error="No data provided"), 400
        
        # Validate required fields
        required_fields = ['fir_id', 'complainant_name', 'category', 'description']
        for field in required_fields:
            if not fir_data.get(field):
                return jsonify(success=False, error=f"Missing required field: {field}"), 400
        
        # Store in database
        if db is not None:
            db.fir_records.insert_one(fir_data)
            logger.info(f"FIR created successfully: {fir_data.get('fir_id')}")
        
        return jsonify({
            "success": True,
            "fir_id": fir_data.get("fir_id"),
            "message": "FIR created successfully"
        })
    except Exception as e:
        logger.error(f"FIR creation error: {e}")
        return jsonify(success=False, error=str(e)), 500

@app.route("/api/fir/<fir_id>", methods=["GET"])
def get_fir(fir_id):
    try:
        if db is not None:
            fir = db.fir_records.find_one({"fir_id": fir_id}, {"_id": 0})
            if fir:
                return jsonify(fir)
        
        return jsonify(error="FIR not found"), 404
    except Exception as e:
        logger.error(f"FIR retrieval error: {e}")
        return jsonify(error=str(e)), 500

# ──────────────────────────────────────────────────────────────────────────────── 
# LEGAL CONTENT ROUTES (Your existing routes)
# ──────────────────────────────────────────────────────────────────────────────── 

@app.route("/acts")
def get_acts():
    try:
        if db is None:
            return jsonify(error="Database not connected"), 500
        
        acts = list(db.acts.find({}, {"_id": 0}).limit(50))
        return jsonify(acts)
    except Exception as e:
        logger.error(f"Acts fetch error: {e}")
        return jsonify(error=str(e)), 500

@app.route("/articles")
def get_articles():
    try:
        if db is None:
            return jsonify(error="Database not connected"), 500
        
        articles = list(db.articles.find({}, {"_id": 0}).limit(50))
        return jsonify(articles)
    except Exception as e:
        logger.error(f"Articles fetch error: {e}")
        return jsonify(error=str(e)), 500

@app.route("/cases")
def get_cases():
    try:
        if db is None:
            return jsonify(error="Database not connected"), 500
        
        cases = list(db.cases.find({}, {"_id": 0}).limit(50))
        return jsonify(cases)
    except Exception as e:
        logger.error(f"Cases fetch error: {e}")
        return jsonify(error=str(e)), 500

@app.route("/lawyers")
def get_lawyers():
    try:
        if db is None:
            return jsonify(error="Database not connected"), 500
        
        lawyers = list(db.lawyers.find({}, {"_id": 0}).limit(50))
        return jsonify(lawyers)
    except Exception as e:
        logger.error(f"Lawyers fetch error: {e}")
        return jsonify(error=str(e)), 500

@app.route("/chat", methods=["POST"])
def chat():
    try:
        data = request.get_json()
        message = data.get("message", "")
        
        if not message:
            return jsonify(error="Message is required"), 400
        
        # Simple echo response for now
        response = f"You asked: {message}. This is a placeholder response."
        
        return jsonify({
            "response": response,
            "timestamp": "2025-07-08T17:07:00Z"
        })
    except Exception as e:
        logger.error(f"Chat error: {e}")
        return jsonify(error=str(e)), 500

# ──────────────────────────────────────────────────────────────────────────────── 
# ERROR HANDLERS
# ──────────────────────────────────────────────────────────────────────────────── 

@app.errorhandler(404)
def not_found(error):
    return jsonify(error="Endpoint not found"), 404

@app.errorhandler(500)
def internal_error(error):
    return jsonify(error="Internal server error"), 500

@app.errorhandler(400)
def bad_request(error):
    return jsonify(error="Bad request"), 400

# ──────────────────────────────────────────────────────────────────────────────── 
# APP RUNNER
# ──────────────────────────────────────────────────────────────────────────────── 

if __name__ == "__main__":
    app.run(debug=True, host="0.0.0.0", port=5000)







