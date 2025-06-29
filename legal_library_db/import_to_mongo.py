import json
from pymongo import MongoClient

# Replace this with your actual MongoDB Atlas URL
client = MongoClient("MONGO_URI=mongodb+srv://law_app:")
db = client["legal_library"]

# Import acts
with open("acts.json", "r", encoding="utf-8") as f:
    db.acts.insert_many(json.load(f))

# Import articles
with open("articles.json", "r", encoding="utf-8") as f:
    db.articles.insert_many(json.load(f))

# Import cases
with open("cases.json", "r", encoding="utf-8") as f:
    db.cases.insert_many(json.load(f))

print("✅ All data imported successfully into MongoDB Atlas.")
