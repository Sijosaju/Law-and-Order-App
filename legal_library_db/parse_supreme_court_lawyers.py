import pymongo
import re
import random
from datetime import datetime
import json
import os
from dotenv import load_dotenv

# Load environment variables from .env file
load_dotenv()

# MongoDB connection from .env file
MONGO_URI = os.getenv("MONGO_URI")
DATABASE_NAME = "legal_library"
COLLECTION_NAME = "lawyers"

def connect_to_mongodb():
    """Connect to MongoDB"""
    try:
        if not MONGO_URI:
            print("❌ MONGO_URI not found in .env file")
            return None
            
        client = pymongo.MongoClient(MONGO_URI)
        # Test connection
        client.admin.command('ping')
        db = client[DATABASE_NAME]
        collection = db[COLLECTION_NAME]
        print("✅ Connected to MongoDB successfully")
        return collection
    except Exception as e:
        print(f"❌ Error connecting to MongoDB: {e}")
        return None

def extract_city_from_address(address):
    """Extract city from address"""
    cities = ['New Delhi', 'Delhi', 'Mumbai', 'Bangalore', 'Chennai', 'Kolkata', 'Hyderabad', 'Pune', 'Noida', 'Gurgaon', 'Ghaziabad']
    for city in cities:
        if city in address:
            return city
    return "New Delhi"

def get_coordinates_for_city(city):
    """Get latitude and longitude for city"""
    coordinates = {
        "New Delhi": (28.6139, 77.2090),
        "Delhi": (28.6139, 77.2090),
        "Mumbai": (19.0760, 72.8777),
        "Bangalore": (12.9716, 77.5946),
        "Chennai": (13.0827, 80.2707),
        "Kolkata": (22.5726, 88.3639),
        "Hyderabad": (17.3850, 78.4867),
        "Pune": (18.5204, 73.8567),
        "Noida": (28.5355, 77.3910),
        "Gurgaon": (28.4595, 77.0266),
        "Ghaziabad": (28.6692, 77.4538)
    }
    return coordinates.get(city, (28.6139, 77.2090))

def parse_lawyer_text(text_content):
    """Parse the Supreme Court lawyer text and extract structured data"""
    lawyers = []
    
    # Split by entries (each lawyer entry starts with a serial number)
    entries = re.split(r'\n(?=\d+\s+)', text_content)
    
    for entry in entries:
        if not entry.strip():
            continue
            
        try:
            # Extract serial number
            serial_match = re.match(r'^(\d+)\s+', entry)
            if not serial_match:
                continue
                
            serial_no = serial_match.group(1)
            
            # Extract name (after serial number, before address)
            name_pattern = r'^\d+\s+(Sh|Ms\.|Miss|Smt\.|Dr\.)\s+([^(]+?)(?:\(|Address:|Office:|Chamber:|Residence:)'
            name_match = re.search(name_pattern, entry, re.MULTILINE | re.DOTALL)
            
            if name_match:
                prefix = name_match.group(1)
                name = name_match.group(2).strip()
                full_name = f"{prefix} {name}" if prefix else name
                
                # Clean up name
                full_name = re.sub(r'\s+', ' ', full_name)
                full_name = full_name.replace('\n', ' ').strip()
                
                # Extract registration date
                date_pattern = r'(\d{1,2}/\d{1,2}/\d{4})'
                date_match = re.search(date_pattern, entry)
                registration_date = date_match.group(1) if date_match else None
                
                # Extract file/registration number
                file_no_pattern = r'(\d{3,4})'
                file_no_match = re.search(file_no_pattern, entry)
                file_no = file_no_match.group(1) if file_no_match else None
                
                # Extract contact info
                phone_pattern = r'(\+?91[-\s]?\d{10}|\d{10})'
                phone_match = re.search(phone_pattern, entry)
                phone = phone_match.group(1) if phone_match else None
                
                email_pattern = r'([a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,})'
                email_match = re.search(email_pattern, entry)
                email = email_match.group(1) if email_match else None
                
                # Extract address (simplified)
                address_pattern = r'(?:Address:|Office:|Chamber:|Residence:)\s*([^\n]+(?:\n[^\n]+)*?)(?=\n\d|$)'
                address_match = re.search(address_pattern, entry, re.MULTILINE)
                address = address_match.group(1).strip() if address_match else "New Delhi"
                
                # Determine if Senior Advocate
                is_senior = bool(re.search(r'Senior Advocate|Sr\. Advocate', entry, re.IGNORECASE))
                
                # Determine verification status
                verified = not bool(re.search(r'Expired|Removed|Suspended', entry, re.IGNORECASE))
                
                # Generate synthetic data for missing fields
                expertise_areas = [
                    'Constitutional Law', 'Criminal Law', 'Civil Law', 'Corporate Law',
                    'Family Law', 'Property Law', 'Tax Law', 'Labor Law', 'Environmental Law',
                    'Intellectual Property', 'Banking Law', 'Insurance Law', 'Consumer Law'
                ]
                
                cities = ['New Delhi', 'Mumbai', 'Bangalore', 'Chennai', 'Kolkata', 'Hyderabad', 'Pune']
                
                # Calculate experience based on registration date
                experience = 10
                if registration_date:
                    try:
                        reg_year = int(registration_date.split('/')[-1])
                        current_year = datetime.now().year
                        experience = max(1, current_year - reg_year)
                    except:
                        experience = random.randint(5, 25)
                
                # Create lawyer document
                lawyer_doc = {
                    "id": serial_no,
                    "name": full_name,
                    "expertise": random.choice(expertise_areas),
                    "city": extract_city_from_address(address) or random.choice(cities),
                    "state": "Delhi" if "Delhi" in address else "Maharashtra",
                    "rating": round(random.uniform(3.5, 5.0), 1),
                    "reviews": random.randint(5, 200),
                    "verified": verified,
                    "senior_advocate": is_senior,
                    "experience": experience,
                    "photoUrl": "https://via.placeholder.com/150",
                    "latitude": get_coordinates_for_city(extract_city_from_address(address) or "New Delhi")[0],
                    "longitude": get_coordinates_for_city(extract_city_from_address(address) or "New Delhi")[1],
                    "fee": f"₹{random.randint(1000, 5000)}/hr",
                    "description": f"Experienced advocate practicing {random.choice(expertise_areas).lower()} with {experience}+ years of experience",
                    "phone": phone or f"+91-{random.randint(7000000000, 9999999999)}",
                    "email": email or f"{name.lower().replace(' ', '.')}@example.com",
                    "address": address,
                    "enrollment_number": f"D/{file_no}/{registration_date.split('/')[-1] if registration_date else '2020'}",
                    "registration_date": registration_date,
                    "court": "Supreme Court of India",
                    "specializations": [random.choice(expertise_areas) for _ in range(random.randint(1, 3))],
                    "languages": ["English", "Hindi"],
                    "created_at": datetime.now().isoformat(),
                    "updated_at": datetime.now().isoformat()
                }
                
                lawyers.append(lawyer_doc)
                
        except Exception as e:
            print(f"Error parsing entry {serial_no if 'serial_no' in locals() else 'unknown'}: {e}")
            continue
    
    return lawyers

def upload_to_mongodb(lawyers, collection):
    """Upload lawyers data to MongoDB"""
    try:
        # Fix: Use "is not None" instead of just "collection"
        if collection is not None:
            # Clear existing data (optional)
            # collection.delete_many({})
            
            # Insert new data
            if lawyers:
                result = collection.insert_many(lawyers)
                print(f"✅ Successfully uploaded {len(result.inserted_ids)} lawyers to MongoDB")
                return True
            else:
                print("❌ No lawyer data to upload")
                return False
        else:
            print("❌ Collection is None")
            return False
            
    except Exception as e:
        print(f"❌ Error uploading to MongoDB: {e}")
        return False

def main():
    """Main function"""
    print("🚀 Starting Supreme Court Lawyers Data Processing...")
    
    try:
        import pdfplumber
        
        # Extract text from PDF
        pdf_path = "2025050163.pdf"  # Your PDF file path
        text_content = ""
        
        with pdfplumber.open(pdf_path) as pdf:
            for page in pdf.pages:
                text_content += page.extract_text() + "\n"
        
        print(f"📄 Extracted text from PDF ({len(text_content)} characters)")
        
        # Parse lawyer data
        print("🔍 Parsing lawyer data...")
        lawyers = parse_lawyer_text(text_content)
        print(f"📊 Parsed {len(lawyers)} lawyers")
        
        # Connect to MongoDB
        collection = connect_to_mongodb()
        if collection is None:  # Fix: Use "is None" instead of "not collection"
            print("❌ Failed to connect to MongoDB")
            return
        
        # Upload to MongoDB
        success = upload_to_mongodb(lawyers, collection)
        
        if success:
            print("🎉 Data processing completed successfully!")
            
            # Print sample data
            if lawyers:
                print("\n📋 Sample lawyer data:")
                sample = lawyers[0]
                print(json.dumps(sample, indent=2, default=str))
        
    except ImportError:
        print("❌ Please install pdfplumber: pip install pdfplumber")
    except Exception as e:
        print(f"❌ Error in main process: {e}")

if __name__ == "__main__":
    main()

