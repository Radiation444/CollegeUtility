import firebase_admin
from firebase_admin import credentials, messaging

# 1. Initialize the Firebase Admin SDK
cred = credentials.Certificate("firebase-key.json")
firebase_admin.initialize_app(cred)

def send_test_notification():
    # 2. Paste the exact token from your terminal logs!
    user_fcm_token = "eqNbytJqTtWnT7ZfJoWVOZ:APA91bGwf-cgB0Bk2I6J1U--9Fpl74EgCly4PqGJ25bQq9yuZ3Z13_xDY30fIwJdDbkazYvapR9VVc3JWcphLjevtB3fJL6MzoL2sykCOYf5duCkaLD3F0U"

    # 3. Create the payload
    message = messaging.Message(
        notification=messaging.Notification(
            title="Match Found! 🎯",
            body="Someone just posted an item similar to your Lost post.",
        ),
        data={
            "postId": "12345ABC",
            "type": "lost_found_match"
        },
        token=user_fcm_token,
    )

    # 4. Send the message!
    try:
        response = messaging.send(message)
        print(f"Successfully sent message! Firebase response ID: {response}")
    except Exception as e:
        print(f"Error sending message: {e}")

if __name__ == "__main__":
    send_test_notification()