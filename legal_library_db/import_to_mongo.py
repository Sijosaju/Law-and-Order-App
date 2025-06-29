from pymongo import MongoClient
import json
import os
from dotenv import load_dotenv

# Load .env file to get MONGO_URI
load_dotenv()
client = MongoClient(os.getenv("MONGO_URI"))
db = client["legal_library"]
acts_collection = db["acts"]

# Clear old data
print("🧹 Deleting existing documents in 'acts' collection...")
acts_collection.delete_many({})
print("✅ Cleared.\n")

def flatten_paragraphs(paragraphs):
    content = []
    if isinstance(paragraphs, dict):
        for para in paragraphs.values():
            if isinstance(para, dict):
                text = para.get("text", "")
                content.append(text.strip())

                subpoints = para.get("contains")
                if isinstance(subpoints, dict):
                    content.extend([str(p).strip() for p in subpoints.values()])
            elif isinstance(para, str):
                content.append(para.strip())
    elif isinstance(paragraphs, list):
        content.extend([str(p).strip() for p in paragraphs])
    elif isinstance(paragraphs, str):
        content.append(paragraphs.strip())
    return "\n".join(content)

def extract_sections(parts):
    all_sections = []
    if isinstance(parts, dict):
        for part in parts.values():
            sections = part.get("Sections", {})
            if isinstance(sections, dict):
                for sec_key, sec_val in sections.items():
                    section_number = sec_key.replace("Section ", "").strip()
                    section_title = sec_val.get("heading", "Untitled")
                    paragraphs = sec_val.get("paragraphs", {})
                    section_content = flatten_paragraphs(paragraphs)

                    all_sections.append({
                        "section_number": section_number,
                        "title": section_title,
                        "content": section_content
                    })
    return all_sections

def normalize_act_data(raw, act_id):
    return {
        "act_id": str(act_id),
        "act_name": raw.get("Act Title", "Untitled"),
        "description": " ".join(raw.get("Act Definition", {}).values()) if isinstance(raw.get("Act Definition"), dict) else raw.get("Act Definition", "No description"),
        "sections": extract_sections(raw.get("Parts", {}))
    }

def import_acts(folder_path):
    act_id = 1
    files = [f for f in os.listdir(folder_path) if f.endswith(".json")]

    if not files:
        print("⚠️ No JSON files found in folder.")
        return

    for filename in files:
        filepath = os.path.join(folder_path, filename)
        try:
            with open(filepath, "r", encoding="utf-8") as f:
                raw_data = json.load(f)
                act = normalize_act_data(raw_data, act_id)
                acts_collection.insert_one(act)
                print(f"✅ Imported: {filename} as '{act['act_name']}'")
                act_id += 1
        except Exception as e:
            print(f"❌ Failed to import {filename}: {e}")

    print(f"\n🎉 Import completed. {act_id - 1} files imported.")

# Entry point
if __name__ == "__main__":
    import_acts("central_acts")
