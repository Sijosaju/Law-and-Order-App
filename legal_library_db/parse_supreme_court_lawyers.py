import pymongo
import re
import random
from datetime import datetime
import json
import os
from dotenv import load_dotenv
import pdfplumber

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
    cities = [
        'New Delhi', 'Delhi', 'Mumbai', 'Bangalore', 'Chennai', 'Kolkata', 
        'Hyderabad', 'Pune', 'Noida', 'Gurgaon', 'Ghaziabad', 'Faridabad',
        'Jaipur', 'Lucknow', 'Bhopal', 'Chandigarh', 'Ahmedabad', 'Surat',
        'Kochi', 'Thiruvananthapuram', 'Bhubaneswar', 'Patna', 'Ranchi',
        'Dehradun', 'Indore', 'Nagpur', 'Nashik', 'Coimbatore', 'Madurai',
        'Visakhapatnam', 'Vijayawada', 'Ghaziabad', 'Kanpur', 'Agra'
    ]
    
    # Convert address to uppercase for better matching
    address_upper = address.upper()
    
    for city in cities:
        if city.upper() in address_upper:
            return city
    
    # If no specific city found, check for "Delhi" patterns
    if any(pattern in address_upper for pattern in ['DELHI', 'NEW DELHI', 'ND']):
        return "New Delhi"
    
    return "New Delhi"  # Default fallback

def determine_state_from_city(city):
    """Determine state from city name"""
    city_state_map = {
        "New Delhi": "Delhi",
        "Delhi": "Delhi",
        "Mumbai": "Maharashtra",
        "Bangalore": "Karnataka",
        "Chennai": "Tamil Nadu",
        "Kolkata": "West Bengal",
        "Hyderabad": "Telangana",
        "Pune": "Maharashtra",
        "Noida": "Uttar Pradesh",
        "Gurgaon": "Haryana",
        "Ghaziabad": "Uttar Pradesh",
        "Jaipur": "Rajasthan",
        "Lucknow": "Uttar Pradesh",
        "Bhopal": "Madhya Pradesh",
        "Chandigarh": "Chandigarh",
        "Ahmedabad": "Gujarat",
        "Kanpur": "Uttar Pradesh",
        "Agra": "Uttar Pradesh"
    }
    return city_state_map.get(city, "Delhi")

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
        "Ghaziabad": (28.6692, 77.4538),
        "Kanpur": (26.4499, 80.3319),
        "Agra": (27.1767, 78.0081)
    }
    return coordinates.get(city, (28.6139, 77.2090))

def calculate_distance(lat1, lon1, lat2, lon2):
    """Calculate distance between two points in kilometers"""
    from math import radians, cos, sin, asin, sqrt
    
    # Convert decimal degrees to radians
    lat1, lon1, lat2, lon2 = map(radians, [lat1, lon1, lat2, lon2])
    
    # Haversine formula
    dlat = lat2 - lat1
    dlon = lon2 - lon1
    a = sin(dlat/2)**2 + cos(lat1) * cos(lat2) * sin(dlon/2)**2
    c = 2 * asin(sqrt(a))
    r = 6371  # Radius of earth in kilometers
    return c * r

def parse_lawyer_text(text_content):
    """Parse the Supreme Court lawyer text and extract structured data"""
    lawyers = []
    
    # Split by entries - each entry starts with serial number followed by title
    entries = re.split(r'\n(?=\d+\s+(?:Sh|Ms\.|Miss|Smt\.|Dr\.)\s)', text_content)
    
    for entry in entries:
        if not entry.strip():
            continue
            
        try:
            # Extract serial number
            serial_match = re.match(r'^(\d+)\s+', entry)
            if not serial_match:
                continue
                
            serial_no = serial_match.group(1)
            
            # Remove the serial number from the entry
            entry_without_serial = re.sub(r'^\d+\s+', '', entry)
            
            # Parse the structure: Title + Name + (Advocate/Attorney) + Address + Date + File No
            # Example: "Sh A D Sikri (Advocate)\nA-102 Sahadara Colony, Sarai Rohilla, New Delhi\n15/10/1981 690 34"
            
            lines = entry_without_serial.split('\n')
            if len(lines) < 2:
                continue
                
            # First line contains: Title + Name + (Advocate/Attorney)
            first_line = lines[0].strip()
            
            # Extract name before the bracket
            name_match = re.match(r'^((?:Sh|Ms\.|Miss|Smt\.|Dr\.)\s+[^(]+?)\s*\([^)]*\)', first_line)
            
            if not name_match:
                continue
                
            clean_name = name_match.group(1).strip()
            clean_name = re.sub(r'\s+', ' ', clean_name)  # Clean multiple spaces
            
            # Extract address from subsequent lines until we hit date pattern
            address_lines = []
            registration_date = None
            file_no = None
            
            for line in lines[1:]:
                line = line.strip()
                if not line:
                    continue
                    
                # Check if this line contains date pattern
                date_match = re.search(r'(\d{1,2}/\d{1,2}/\d{4})', line)
                if date_match:
                    registration_date = date_match.group(1)
                    
                    # Extract file number from the same line
                    # Usually appears after the date
                    remaining_text = line.replace(registration_date, '').strip()
                    file_no_match = re.search(r'(\d{3,4})', remaining_text)
                    if file_no_match:
                        file_no = file_no_match.group(1)
                    break
                else:
                    # This is part of the address
                    address_lines.append(line)
            
            # Join address lines
            address = ' '.join(address_lines).strip()
            
            # Clean address
            address = re.sub(r'\s+', ' ', address)
            address = re.sub(r'^[,\s]+|[,\s]+$', '', address)
            
            if not address or len(address) < 5:
                address = "New Delhi"
            
            # Extract contact info from address
            phone_pattern = r'(\+?91[-\s]?\d{10}|\d{10})'
            phone_match = re.search(phone_pattern, address)
            phone = phone_match.group(1) if phone_match else None
            
            email_pattern = r'([a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,})'
            email_match = re.search(email_pattern, address)
            email = email_match.group(1) if email_match else None
            
            # Clean address by removing phone and email
            clean_address = address
            if phone:
                clean_address = re.sub(re.escape(phone), '', clean_address)
            if email:
                clean_address = re.sub(re.escape(email), '', clean_address)
            
            # Final address cleanup
            clean_address = re.sub(r'\s+', ' ', clean_address).strip()
            clean_address = re.sub(r'^[,\s]+|[,\s]+$', '', clean_address)
            
            if not clean_address or len(clean_address) < 5:
                clean_address = "New Delhi"
            
            # Determine if Senior Advocate
            is_senior = bool(re.search(r'Senior Advocate|Sr\. Advocate|Designated as Sr\. Advocate', entry, re.IGNORECASE))
            
            # Determine verification status
            verified = not bool(re.search(r'Expired|Removed|Suspended', entry, re.IGNORECASE))
            
            # Generate synthetic data for missing fields
            expertise_areas = [
                'Constitutional Law', 'Criminal Law', 'Civil Law', 'Corporate Law',
                'Family Law', 'Property Law', 'Tax Law', 'Labor Law', 'Environmental Law',
                'Intellectual Property', 'Banking Law', 'Insurance Law', 'Consumer Law'
            ]
            
            # Calculate experience based on registration date
            experience = 10
            if registration_date:
                try:
                    reg_year = int(registration_date.split('/')[-1])
                    current_year = datetime.now().year
                    experience = max(1, current_year - reg_year)
                except:
                    experience = random.randint(5, 25)
            
            # Determine city from address
            city = extract_city_from_address(clean_address)
            
            # Create clean email from name
            name_for_email = clean_name.replace('Sh ', '').replace('Ms. ', '').replace('Dr. ', '').replace('Smt. ', '').replace('Miss ', '')
            clean_email = email or f"{name_for_email.lower().replace(' ', '.')}@example.com"
            
            # Create lawyer document
            lawyer_doc = {
                "id": serial_no,
                "name": clean_name,  # Clean name only (e.g., "Sh A D Sikri")
                "address": clean_address,  # Separate address field
                "expertise": random.choice(expertise_areas),
                "city": city,
                "state": determine_state_from_city(city),
                "rating": round(random.uniform(3.5, 5.0), 1),
                "reviews": random.randint(5, 200),
                "verified": verified,
                "senior_advocate": is_senior,
                "experience": experience,
                "photoUrl": "https://via.placeholder.com/150",
                "latitude": get_coordinates_for_city(city)[0],
                "longitude": get_coordinates_for_city(city)[1],
                "fee": f"₹{random.randint(1000, 5000)}/hr",
                "description": f"Experienced advocate practicing {random.choice(expertise_areas).lower()} with {experience}+ years of experience",
                "phone": phone or f"+91-{random.randint(7000000000, 9999999999)}",
                "email": clean_email,
                "enrollment_number": f"D/{file_no}/{registration_date.split('/')[-1] if registration_date else '2020'}",
                "registration_date": registration_date,
                "court": "Supreme Court of India",
                "specializations": [random.choice(expertise_areas) for _ in range(random.randint(1, 3))],
                "languages": ["English", "Hindi"],
                "created_at": datetime.now().isoformat(),
                "updated_at": datetime.now().isoformat()
            }
            
            lawyers.append(lawyer_doc)
            
            # Debug print for first few entries
            if len(lawyers) <= 5:
                print(f"✅ Parsed #{serial_no}: Name='{clean_name}', Address='{clean_address[:50]}...'")
                
        except Exception as e:
            print(f"❌ Error parsing entry {serial_no if 'serial_no' in locals() else 'unknown'}: {e}")
            continue
    
    return lawyers

def upload_to_mongodb(lawyers, collection):
    """Upload lawyers data to MongoDB"""
    try:
        if collection is not None:
            # Clear existing data
            print("🗑️ Deleting existing lawyers data...")
            result = collection.delete_many({})
            print(f"✅ Deleted {result.deleted_count} existing lawyer records")
            
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
        # Extract text from PDF
        pdf_path = "2025050163.pdf"  # Your PDF file path
        text_content = ""
        
        with pdfplumber.open(pdf_path) as pdf:
            for page in pdf.pages:
                page_text = page.extract_text()
                if page_text:
                    text_content += page_text + "\n"
        
        print(f"📄 Extracted text from PDF ({len(text_content)} characters)")
        
        # Parse lawyer data
        print("🔍 Parsing lawyer data...")
        lawyers = parse_lawyer_text(text_content)
        print(f"📊 Parsed {len(lawyers)} lawyers")
        
        # Connect to MongoDB
        collection = connect_to_mongodb()
        if collection is None:
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
                
            # Print statistics
            unique_cities = set(lawyer['city'] for lawyer in lawyers)
            print(f"\n🏙️ All cities found: {sorted(unique_cities)}")
            print(f"📊 Total unique cities: {len(unique_cities)}")
            
            verified_count = sum(1 for lawyer in lawyers if lawyer['verified'])
            senior_count = sum(1 for lawyer in lawyers if lawyer['senior_advocate'])
            print(f"✅ Verified lawyers: {verified_count}")
            print(f"👨‍⚖️ Senior advocates: {senior_count}")
        
    except ImportError:
        print("❌ Please install pdfplumber: pip install pdfplumber")
    except Exception as e:
        print(f"❌ Error in main process: {e}")

if __name__ == "__main__":
    main()




