import logging

import requests

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s | %(levelname)s | %(name)s | %(message)s"
)
logger = logging.getLogger(__name__)

API_URL_LOCAL = "http://localhost:5000/api"
API_URL_LOCAL_K8S = "http://localhost:30080/api"
API_URL_CLOUD_K8S = "http://<EC2_PUBLIC_IP>:5000/api"

API_URL = API_URL_LOCAL_K8S    # Change this to the appropriate URL based on your deployment

QUESTION_URL = f"{API_URL}/question"
FEEDBACK_URL = f"{API_URL}/feedback"

def chat():
    conversation = []

    try:
        while True:
            user_input = input("\nUser: ").strip()

            if not user_input:
                print("Please enter a message.")
                continue

            if user_input.lower() in ["exit", "quit"]:
                print("\nGoodbye! Thanks for using HealthSecure AI Assistant.")
                break

            try:
                response = requests.post(
                    QUESTION_URL,
                    json={
                        "message": user_input,
                        "history": conversation
                    },
                    timeout=30
                )
            except requests.exceptions.ConnectionError:
                print(
                    "\nSorry, I am unable to connect to the server right now. "
                    "Please try again later."
                )
                continue
            except requests.exceptions.Timeout:
                print(
                    "\nThe request is taking longer than expected. "
                    "Please try again."
                )
                continue
            except requests.exceptions.RequestException:
                print(
                    "\nSomething went wrong while contacting the assistant."
                )
                continue

            if response.status_code != 200:
                print(
                    "\nSorry, I couldn't process your request right now."
                )
                continue

            result = response.json()

            assistant_message = result["response"]
            conversation_id = result.get("conversation_id")

            conversation.append(
                {
                    "role": "user",
                    "content": user_input
                }
            )

            conversation.append(
                {
                    "role": "assistant",
                    "content": assistant_message
                }
            )

            print("\nAssistant:", assistant_message)
            print("Cost:", result.get("cost", 0))
            logger.info("Conversation ID: %s", conversation_id)

            rating = input(
                "\nWas this response helpful? (yes/no): "
            ).strip().lower()

            if rating in ["yes", "y"]:
                rating = "positive"

            elif rating in ["no", "n"]:
                rating = "negative"

            else:
                print("Invalid feedback. Skipping.")
                continue

            try:
                feedback_response = requests.post(
                    FEEDBACK_URL,
                    json={
                        "question": user_input,
                        "response": assistant_message,
                        "rating": rating,
                        "conversation_id": conversation_id,
                        "source": "test_agent",
                        "relevance": "medium",
                        "explanation": "Feedback submitted from test_agent",
                        "score": 5 if rating == "positive" else 1
                    },
                    timeout=10
                )

                if feedback_response.status_code == 200:
                    print("Thank you for your feedback.")

                else:
                    print("Unable to save feedback right now.")

            except requests.exceptions.RequestException:
                print("Unable to submit feedback right now.")

    except KeyboardInterrupt:
        print("\n\nChat ended. Goodbye.")

if __name__ == "__main__":
    chat()