from flask import Flask, jsonify
from flask_cors import CORS
from pymongo import MongoClient
from dotenv import load_dotenv
import os

# Load MongoDB URI from .env
load_dotenv()
mongo_uri = os.getenv("MONGO_URI")

# Connect to MongoDB
client = MongoClient(mongo_uri)
db = client["legal_library"]

# Create Flask app
app = Flask(__name__)
CORS(app)

# Get all Acts
@app.route('/acts', methods=['GET'])
def get_acts():
    acts = list(db.acts.find({}, {'_id': 0}))
    return jsonify(acts)

# Get Sections of a Specific Act
@app.route('/acts/<act_id>', methods=['GET'])
def get_act_sections(act_id):
    sections = list(db.acts.find({'act_id': act_id}, {'_id': 0}))
    if sections:
        return jsonify({
            "act_id": act_id,
            "act_name": sections[0]['act_name'],
            "description": sections[0]['description'],
            "sections": [
                {
                    "section_number": sec["section_number"],
                    "title": sec["section_title"],
                    "content": sec["section_content"]
                } for sec in sections
            ]
        })
    else:
        return jsonify({"error": "Act not found"}), 404

# Get all Articles
@app.route('/articles', methods=['GET'])
def get_articles():
    articles = list(db.articles.find({}, {'_id': 0}))
    return jsonify(articles)

# Get all Cases
@app.route('/cases', methods=['GET'])
def get_cases():
    cases = list(db.cases.find({}, {'_id': 0}))
    return jsonify(cases)
@app.route('/')
def index():
    return '✅ Legal Library Backend is Running!'


# Run the app
if __name__ == "__main__":
    port = int(os.environ.get("PORT", 5000))  # Render provides PORT
    app.run(host="0.0.0.0", port=port, debug=True)
