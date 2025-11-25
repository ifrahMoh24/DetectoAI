from googleapiclient.discovery import build
import requests, os, time
from PIL import Image
from io import BytesIO

# ✏️ Replace with your actual credentials
API_KEY = "AIzaSyAJ5S6KRTvKZ8RUF9cBdW9DcU-C48FwZNs"
CSE_ID = "e5531561e73064db7"

# Define your search queries and folder names
queries = {
    "cracked phone screen": "crack",
    "broken smartphone display": "crack",
    "phone body scratches": "scratch",
    "dented phone": "dent",
    "bent phone frame": "dent",
    "damaged phone corner": "dent",
    "phone with edge dent": "dent",
    "clean smartphone front": "pristine",
    "brand new smartphone": "pristine"
}


# Initialize Google Search API
service = build("customsearch", "v1", developerKey=API_KEY)

def fetch_images(query, folder, num=50):
    """Fetch images from Google Custom Search"""
    os.makedirs(folder, exist_ok=True)
    print(f"\n🔍 Searching for: {query}")

    for start in range(1, num, 10):
        try:
            response = service.cse().list(
                q=query,
                cx=CSE_ID,
                searchType='image',
                num=10,
                start=start,
                imgSize='LARGE',
                safe='off'
            ).execute()

            for i, item in enumerate(response.get('items', []), start=start):
                img_url = item['link']
                try:
                    img_data = requests.get(img_url, timeout=5).content
                    img = Image.open(BytesIO(img_data))
                    img = img.convert("RGB")
                    img.save(os.path.join(folder, f"{folder}_{i:03d}.jpg"))
                    print(f"✅ Saved: {folder}_{i:03d}.jpg")
                except Exception as e:
                    print(f"⚠️ Skipped one image: {e}")
                    continue

            time.sleep(2)
        except Exception as e:
            print(f"⚠️ Error for query '{query}': {e}")
            break

    print(f"✅ Finished collecting {folder}")

# Run collection for all queries
for q, folder in queries.items():
    fetch_images(q, folder, num=60)

print("\n🎯 All images collected successfully into SmartCheck_Dataset/")
