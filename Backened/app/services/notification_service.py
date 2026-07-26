import firebase_admin
from firebase_admin import credentials, messaging
import os

# Initialize Firebase Admin SDK
cred_path = os.path.join(os.getcwd(), "firebase_credentials.json")

if os.path.exists(cred_path):
    cred = credentials.Certificate(cred_path)
    firebase_admin.initialize_app(cred)
    print("🔥 Firebase Admin SDK Initialized Successfully!")
else:
    print("⚠️ firebase_credentials.json not found! Push notifications will run in mock mode.")

class NotificationService:
    @staticmethod
    async def send_push_notification(fcm_token: str, title: str, body: str, data_payload: dict = None):
        """
        Sends a background/foreground push notification to a specific mobile device.
        """
        if not fcm_token or fcm_token.strip() == "":
            return False

        try:
            message = messaging.Message(
                notification=messaging.Notification(
                    title=title,
                    body=body,
                ),
                data={k: str(v) for k, v in (data_payload or {}).items()},
                token=fcm_token.strip(),
            )
            
            response = messaging.send(message)
            print(f"✅ FCM Notification Sent Successfully: {response}")
            return True

        except Exception as e:
            print(f"❌ FCM Notification Engine Error: {str(e)}")
            return False