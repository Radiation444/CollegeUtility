from fastapi import FastAPI, UploadFile, Form, BackgroundTasks
import uvicorn
from pydantic import BaseModel
import torch
import clip
from PIL import Image
import io
import json
import os
from dotenv import load_dotenv

load_dotenv()

# Pinecone & Firebase
from pinecone import Pinecone
import firebase_admin
from firebase_admin import credentials, messaging, firestore

# ==========================================
# 1. INITIALIZE EXTERNAL SERVICES
# ==========================================

# Initialize Firebase (Make sure firebase-key.json is in the same folder!)
cred = credentials.Certificate("firebase-key.json")
if not firebase_admin._apps:
    firebase_admin.initialize_app(cred)
db = firestore.client()

# Initialize Pinecone
pc = Pinecone(api_key=os.getenv("PINECONE_API_KEY"))
index = pc.Index("campus-index")

# Initialize OpenAI CLIP
device = "cuda" if torch.cuda.is_available() else "cpu"
print(f"Loading CLIP model on {device}...")
model, preprocess = clip.load("ViT-B/32", device=device)
print("CLIP model loaded successfully!")

# Initialize FastAPI App
app = FastAPI(title="Campus Hub Matching Engine")

# ==========================================
# 2. HELPER FUNCTIONS
# ==========================================

def send_match_notification(matched_user_id: str, new_post_id: str, status: str):
    """Fetches the user's FCM token from Firestore and sends the push notification."""
    try:
        # 1. Look up the user in Firestore
        user_doc = db.collection("users").document(matched_user_id).get()
        
        if user_doc.exists:
            user_data = user_doc.to_dict()
            fcm_token = user_data.get("fcmToken")
            
            if fcm_token:
                # 2. Construct the message
                title = "Match Found! 🎯"
                body = f"Someone just posted a {status} item that looks very similar to yours."
                
                message = messaging.Message(
                    notification=messaging.Notification(title=title, body=body),
                    data={"postId": new_post_id, "type": "match"},
                    token=fcm_token,
                )
                # 3. Send it!
                messaging.send(message)
                print(f"Notification sent successfully to {matched_user_id}!")
            else:
                print(f"User {matched_user_id} has no FCM token.")
    except Exception as e:
        print(f"Error sending notification: {e}")

# ==========================================
# 3. MAIN API ENDPOINT
# ==========================================

@app.post("/upload_item/")
async def upload_item(
    background_tasks: BackgroundTasks,
    file: UploadFile,
    post_id: str = Form(...),
    user_id: str = Form(...),
    status: str = Form(...), # "lost" or "found"
    category: str = Form(...), # e.g., "bottle", "phone", "keys"
):
    """
    This endpoint is called whenever a user uploads a new item.
    """
    # 1. Read and Preprocess the Image
    image_bytes = await file.read()
    img = Image.open(io.BytesIO(image_bytes)).convert("RGB")
    image_tensor = preprocess(img).unsqueeze(0).to(device)

    # 2. Generate the CLIP Vector
    with torch.no_grad():
        # Encode image and convert to a flat python list for Pinecone
        vector = model.encode_image(image_tensor).cpu().numpy().flatten().tolist()

    # 3. THE MATCHING LOGIC (Text First, Image Second)
    # If the user lost an item, we only search "found" items.
    target_status = "found" if status.lower() == "lost" else "lost"
    
    # We use Pinecone's Metadata Filtering to enforce the text/category match!
    # This saves huge amounts of computation.
    query_response = index.query(
        vector=vector,
        top_k=1, # Only get the absolute best match
        include_metadata=True,
        filter={
            "status": target_status,
            "category": category.lower() # Enforce text matching!
        }
    )

    match_found = False
    
    # 4. Check the similarity threshold (e.g., 0.82 based on your Colab tests)
    if query_response['matches']:
        best_match = query_response['matches'][0]
        score = best_match['score']
        
        if score > 0.82:
            match_found = True
            matched_user_id = best_match['metadata']['user_id']
            
            print(f"MATCH FOUND! Score: {score:.4f} between {post_id} and {best_match['id']}")
            
            # Fire the notification in the background so the API doesn't slow down
            background_tasks.add_task(
                send_match_notification, 
                matched_user_id, 
                post_id, 
                status
            )

    # 5. Save the NEW item to the Vector Database
    # We include the metadata so it can be filtered in future searches
    index.upsert(
        vectors=[{
            "id": post_id,
            "values": vector,
            "metadata": {
                "status": status.lower(),
                "category": category.lower(),
                "user_id": user_id
            }
        }]
    )

    return {
        "status": "success",
        "message": "Item processed and saved.",
        "match_found": match_found
    }

if __name__ == "__main__":
    uvicorn.run("main:app", host="0.0.0.0", port=8000, reload=True) 