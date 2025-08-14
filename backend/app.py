from flask import Flask, request, jsonify
from flask_pymongo import PyMongo
from flask_cors import CORS
import os
import secrets

app = Flask(__name__)
CORS(app)

# MongoDB configuration
app.config["MONGO_URI"] = os.environ.get("MONGO_URI", "mongodb://mongo:27017/chat_db")
mongo = PyMongo(app)
chat_rooms_collection = mongo.db.rooms

@app.route("/room/create", methods=["GET"])
def create_room():
    room_key = secrets.token_urlsafe(8)
    chat_rooms_collection.insert_one({'room_key': room_key, 'messages': []})
    return jsonify({"room_key": room_key}), 201

@app.route("/room/join", methods=["POST"])
def join_room():
    data = request.get_json()
    room_key = data.get('room_key')
    if not room_key:
        return jsonify({"error": "Room key is required"}), 400
    room = chat_rooms_collection.find_one({'room_key': room_key})
    if not room:
        return jsonify({"error": "Room not found"}), 404
    return jsonify({"room_key": room_key}), 200

@app.route("/room/<room_key>/messages", methods=["GET"])
def get_messages(room_key):
    room = chat_rooms_collection.find_one({'room_key': room_key}, {'_id': 0, 'messages': 1})
    if not room:
        return jsonify({"error": "Room not found"}), 404
    return jsonify(room.get('messages', [])), 200

@app.route("/room/<room_key>/messages", methods=["POST"])
def post_message(room_key):
    data = request.get_json()
    username = data.get('username')
    message_content = data.get('msg')
    if not username or not message_content:
        return jsonify({"error": "Username and message are required"}), 400

    message = {'username': username, 'msg': message_content}
    result = chat_rooms_collection.update_one(
        {'room_key': room_key},
        {'$push': {'messages': message}}
    )
    if result.matched_count == 0:
        return jsonify({"error": "Room not found"}), 404
    return jsonify({"message": "Message sent"}), 201

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000, debug=True)
