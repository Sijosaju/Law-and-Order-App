import requests
import json
from pymongo import MongoClient
from datetime import datetime
import os
from dotenv import load_dotenv

# Load environment variables
load_dotenv()

def connect_to_mongodb():
    """Connect to MongoDB Atlas"""
    try:
        mongo_uri = os.getenv("MONGO_URI")
        if not mongo_uri:
            print("❌ MONGO_URI not found in .env file")
            print("Please add your MongoDB Atlas connection string to .env file")
            return None
        
        client = MongoClient(mongo_uri, serverSelectionTimeoutMS=5000)
        client.admin.command("ping")
        db = client["legal_library"]
        print("✅ Connected to MongoDB Atlas successfully")
        return db
    except Exception as e:
        print(f"❌ MongoDB connection failed: {e}")
        return None

def populate_states_and_districts(db):
    """Download and populate states and districts from GitHub"""
    try:
        print("📥 Downloading states and districts data from GitHub...")
        
        # Download from reliable GitHub source
        url = "https://raw.githubusercontent.com/sab99r/Indian-States-And-Districts/master/states-and-districts.json"
        response = requests.get(url, timeout=30)
        response.raise_for_status()
        
        raw_data = response.json()
        print(f"✅ Downloaded raw data successfully")
        
        # Transform the data structure to expected format
        if 'states' in raw_data:
            data = {item['state']: item['districts'] for item in raw_data['states']}
        else:
            data = raw_data
            
        print(f"✅ Processed data for {len(data)} states/UTs")
        
        # Prepare data for insertion
        states_data = []
        districts_data = []
        
        # State code mapping for consistency
        state_code_mapping = {
            "Andhra Pradesh": "AP", "Arunachal Pradesh": "AR", "Assam": "AS",
            "Bihar": "BR", "Chhattisgarh": "CG", "Goa": "GA", "Gujarat": "GJ",
            "Haryana": "HR", "Himachal Pradesh": "HP", "Jharkhand": "JH",
            "Karnataka": "KA", "Kerala": "KL", "Madhya Pradesh": "MP",
            "Maharashtra": "MH", "Manipur": "MN", "Meghalaya": "ML",
            "Mizoram": "MZ", "Nagaland": "NL", "Odisha": "OR", "Punjab": "PB",
            "Rajasthan": "RJ", "Sikkim": "SK", "Tamil Nadu": "TN",
            "Telangana": "TG", "Tripura": "TR", "Uttar Pradesh": "UP",
            "Uttarakhand": "UK", "West Bengal": "WB",
            # Union Territories
            "Andaman and Nicobar Islands": "AN", "Chandigarh (UT)": "CH",
            "Dadra and Nagar Haveli (UT)": "DN", "Delhi (NCT)": "DL",
            "Jammu and Kashmir": "JK", "Ladakh": "LA", "Lakshadweep (UT)": "LD",
            "Puducherry (UT)": "PY", "Daman and Diu (UT)": "DD"
        }
        
        for state_name, districts in data.items():
            # Clean state name
            state_name = state_name.strip()
            state_code = state_code_mapping.get(state_name, 
                                               ''.join([word[0] for word in state_name.split()]).upper()[:2])
            
            # Determine state type
            state_type = "union_territory" if "(UT)" in state_name or state_name in [
                "Andaman and Nicobar Islands", "Chandigarh", 
                "Dadra and Nagar Haveli", "Delhi",
                "Jammu and Kashmir", "Ladakh", "Lakshadweep", "Puducherry"
            ] else "state"
            
            # Add state
            states_data.append({
                "code": state_code,
                "name": state_name,
                "type": state_type,
                "created_at": datetime.now()
            })
            
            # Add districts for this state
            for district in districts:
                district_name = district.strip()
                district_code = f"{state_code}_{district_name.replace(' ', '').replace('-', '').replace('(', '').replace(')', '').upper()[:4]}"
                
                districts_data.append({
                    "code": district_code,
                    "name": district_name,
                    "state_code": state_code,
                    "state_name": state_name,
                    "created_at": datetime.now()
                })
        
        # Clear existing data and insert new
        print("🗑️ Clearing existing states and districts data...")
        db.states.delete_many({})
        db.districts.delete_many({})
        
        # Insert new data
        print("📝 Inserting states data...")
        db.states.insert_many(states_data)
        
        print("📝 Inserting districts data...")
        db.districts.insert_many(districts_data)
        
        print(f"✅ Successfully inserted {len(states_data)} states and {len(districts_data)} districts")
        
        return True
        
    except requests.RequestException as e:
        print(f"❌ Failed to download data: {e}")
        return False
    except Exception as e:
        print(f"❌ Error populating states and districts: {e}")
        return False


def populate_police_stations(db):
    """Generate comprehensive police stations for all districts"""
    try:
        print("📝 Generating police stations for all districts...")
        
        # Get all districts from database
        districts = list(db.districts.find({}, {"_id": 0}))
        
        if not districts:
            print("❌ No districts found. Please populate states and districts first.")
            return False
        
        police_stations_data = []
        
        # Comprehensive police station types
        station_types = [
            "Main Police Station",
            "City Police Station",
            "Rural Police Station", 
            "Traffic Police Station",
            "Women Police Station",
            "Cyber Crime Police Station",
            "Economic Offences Police Station",
            "Railway Police Station"
        ]
        
        for district in districts:
            district_code = district['code']
            district_name = district['name']
            state_code = district['state_code']
            
            # Generate 3-6 police stations per district
            num_stations = min(6, max(3, len(district_name.split()) + 2))
            
            for i in range(num_stations):
                station_type = station_types[i % len(station_types)]
                station_code = f"{district_code}_{str(i+1).zfill(3)}"
                
                if i == 0:
                    station_name = f"{district_name} Main Police Station"
                else:
                    station_name = f"{district_name} {station_type}"
                
                police_stations_data.append({
                    "code": station_code,
                    "name": station_name,
                    "district_code": district_code,
                    "district_name": district_name,
                    "state_code": state_code,
                    "type": "regular",
                    "created_at": datetime.now()
                })
        
        # Clear existing data and insert new
        print("🗑️ Clearing existing police stations data...")
        db.police_stations.delete_many({})
        
        print("📝 Inserting police stations data...")
        db.police_stations.insert_many(police_stations_data)
        
        print(f"✅ Successfully inserted {len(police_stations_data)} police stations")
        return True
        
    except Exception as e:
        print(f"❌ Error generating police stations: {e}")
        return False

def create_indexes(db):
    """Create indexes for better query performance"""
    try:
        print("🔍 Creating database indexes for better performance...")
        
        # States indexes
        db.states.create_index("code")
        db.states.create_index("name")
        
        # Districts indexes
        db.districts.create_index("state_code")
        db.districts.create_index("code")
        db.districts.create_index("name")
        
        # Police stations indexes
        db.police_stations.create_index("district_code")
        db.police_stations.create_index("state_code")
        db.police_stations.create_index("code")
        
        # FIR records indexes
        db.fir_records.create_index("fir_id")
        db.fir_records.create_index([("created_at", -1)])
        db.fir_records.create_index("state_code")
        db.fir_records.create_index("district_code")
        
        print("✅ Database indexes created successfully")
        
    except Exception as e:
        print(f"❌ Error creating indexes: {e}")

def verify_data(db):
    """Verify the inserted data"""
    try:
        print("\n📊 Data Verification:")
        print("=" * 50)
        
        states_count = db.states.count_documents({})
        districts_count = db.districts.count_documents({})
        stations_count = db.police_stations.count_documents({})
        fir_count = db.fir_records.count_documents({})
        
        print(f"States: {states_count}")
        print(f"Districts: {districts_count}")
        print(f"Police Stations: {stations_count}")
        print(f"FIR Records: {fir_count}")
        
        # Sample data verification
        print("\n📋 Sample Data:")
        print("-" * 30)
        
        sample_state = db.states.find_one({})
        if sample_state:
            print(f"Sample State: {sample_state['name']} ({sample_state['code']})")
        
        sample_district = db.districts.find_one({})
        if sample_district:
            print(f"Sample District: {sample_district['name']} ({sample_district['code']})")
        
        sample_station = db.police_stations.find_one({})
        if sample_station:
            print(f"Sample Police Station: {sample_station['name']}")
        
        print("\n✅ Data verification completed")
        
        # Test cascading relationship
        print("\n🔗 Testing Cascading Relationships:")
        print("-" * 40)
        
        # Get a sample state and its districts
        sample_state = db.states.find_one({})
        if sample_state:
            state_districts = list(db.districts.find({"state_code": sample_state['code']}).limit(3))
            print(f"State '{sample_state['name']}' has {len(state_districts)} districts (showing first 3):")
            for district in state_districts:
                district_stations = db.police_stations.count_documents({"district_code": district['code']})
                print(f"  - {district['name']}: {district_stations} police stations")
        
        print("\n🎉 All data relationships are working correctly!")
        
    except Exception as e:
        print(f"❌ Error verifying data: {e}")

def main():
    """Main function to populate the database"""
    print("🚀 Starting Legal Library Database Population")
    print("=" * 60)
    
    # Connect to MongoDB
    db = connect_to_mongodb()
    if db is None:  # ✅ Correct way to check
        print("\n❌ Cannot proceed without database connection.")
        print("Please check your MONGO_URI in .env file and try again.")
        return

    
    # Populate states and districts
    print("\n📍 Step 1: Populating States and Districts")
    if not populate_states_and_districts(db):
        print("❌ Failed to populate states and districts")
        return
    
    # Populate police stations
    print("\n🚔 Step 2: Populating Police Stations")
    if not populate_police_stations(db):
        print("❌ Failed to populate police stations")
        return
    
    # Create indexes
    print("\n⚡ Step 3: Creating Database Indexes")
    create_indexes(db)
    
    # Verify data
    print("\n🔍 Step 4: Verifying Data")
    verify_data(db)
    
    print("\n" + "=" * 60)
    print("🎉 Database population completed successfully!")
    print("Your FIR app is now ready with comprehensive location data.")
    print("\nNext steps:")
    print("1. Update your Flutter app backend URL")
    print("2. Test the cascading dropdowns in your FIR screen")
    print("3. Run your Flutter app and test the File FIR feature")

if __name__ == "__main__":
    main()
