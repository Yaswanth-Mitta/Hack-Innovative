#!/bin/bash

# Create the main project directory
mkdir secret-chat-app
cd secret-chat-app

# Create backend files
mkdir backend
cat << 'EOF' > backend/app.py
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
EOF

cat << 'EOF' > backend/Dockerfile
# Use official Python base image
FROM python:3.10-slim
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt
COPY . .
EXPOSE 5000
CMD ["python", "app.py"]
EOF

cat << 'EOF' > backend/requirements.txt
flask
flask-pymongo
flask-cors
EOF

# Create frontend files
mkdir frontend
cat << 'EOF' > frontend/index.html
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Simple Secret Chat</title>
    <link rel="stylesheet" href="style.css">
</head>
<body>
    <div class="container" id="login-container">
        <h1>Welcome! 🤫</h1>
        <input type="text" id="username-input" placeholder="Enter your name..." />
        <div class="button-group">
            <button id="create-room-btn">Create Room</button>
            <button id="join-room-btn">Join Room</button>
        </div>
        <div id="join-room-section" class="hidden">
            <input type="text" id="room-key-input" placeholder="Enter room key..." />
            <button id="submit-join-btn">Join Chat</button>
        </div>
    </div>

    <div class="container hidden" id="chat-container">
        <h1 id="room-title"></h1>
        <div id="messages"></div>
        <div class="input-group">
            <input type="text" id="message-input" placeholder="Type a message..." />
            <button id="send-btn">Send</button>
        </div>
        <button id="leave-btn" class="leave-btn">Leave Room</button>
    </div>
    <script src="app.js"></script>
</body>
</html>
EOF

cat << 'EOF' > frontend/style.css
body {
    font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
    background: linear-gradient(135deg, #74ABE2, #5563DE);
    margin: 0;
    padding: 20px;
    color: #333;
    display: flex;
    justify-content: center;
    align-items: center;
    min-height: 100vh;
}

.container {
    max-width: 500px;
    width: 100%;
    margin: auto;
    background: #fff;
    padding: 30px;
    border-radius: 10px;
    box-shadow: 0px 4px 15px rgba(0, 0, 0, 0.15);
    text-align: center;
}

.container.hidden {
    display: none;
}

h1 {
    color: #5563DE;
    margin-bottom: 25px;
}

input[type="text"] {
    width: calc(100% - 22px);
    padding: 10px;
    font-size: 16px;
    border-radius: 6px;
    border: 1px solid #ccc;
    outline: none;
    margin-bottom: 15px;
    transition: border-color 0.2s;
}

input[type="text"]:focus {
    border-color: #5563DE;
}

.button-group, .input-group {
    display: flex;
    gap: 10px;
    justify-content: center;
}

button {
    background-color: #5563DE;
    color: white;
    border: none;
    padding: 10px 20px;
    font-size: 16px;
    border-radius: 6px;
    cursor: pointer;
    transition: background-color 0.2s;
}

button:hover {
    background-color: #4052b5;
}

#messages {
    height: 300px;
    border: 1px solid #ddd;
    border-radius: 6px;
    padding: 10px;
    margin-top: 20px;
    text-align: left;
    overflow-y: auto;
    background: #f9f9f9;
}

#messages p {
    margin: 5px 0;
    padding: 8px;
    border-radius: 6px;
}

#messages .user-message {
    background-color: #e6f7ff;
    border-left: 3px solid #5563DE;
}

.status-message {
    font-style: italic;
    color: #666;
    text-align: center;
}

.leave-btn {
    background-color: #ff4d4d;
    margin-top: 20px;
}

.leave-btn:hover {
    background-color: #d93636;
}
EOF

cat << 'EOF' > frontend/app.js
const loginContainer = document.getElementById('login-container');
const chatContainer = document.getElementById('chat-container');
const usernameInput = document.getElementById('username-input');
const createRoomBtn = document.getElementById('create-room-btn');
const joinRoomBtn = document.getElementById('join-room-btn');
const joinRoomSection = document.getElementById('join-room-section');
const roomKeyInput = document.getElementById('room-key-input');
const submitJoinBtn = document.getElementById('submit-join-btn');
const roomTitle = document.getElementById('room-title');
const messagesDiv = document.getElementById('messages');
const messageInput = document.getElementById('message-input');
const sendBtn = document.getElementById('send-btn');
const leaveBtn = document.getElementById('leave-btn');

let currentUsername = '';
let currentRoom = '';
let refreshInterval;

function showMessage(msg, username) {
    const p = document.createElement('p');
    p.textContent = `${username}: ${msg}`;
    p.className = 'user-message';
    messagesDiv.appendChild(p);
    messagesDiv.scrollTop = messagesDiv.scrollHeight;
}

function fetchMessages() {
    fetch(`/room/${currentRoom}/messages`)
        .then(res => res.json())
        .then(messages => {
            messagesDiv.innerHTML = ''; // Clear existing messages
            messages.forEach(message => {
                showMessage(message.msg, message.username);
            });
        })
        .catch(err => console.error("Error fetching messages:", err));
}

function startChat() {
    loginContainer.classList.add('hidden');
    chatContainer.classList.remove('hidden');
    roomTitle.textContent = `Room: ${currentRoom}`;
    fetchMessages();
    refreshInterval = setInterval(fetchMessages, 5000); // Refresh every 5 seconds
}

// Event Listeners
createRoomBtn.addEventListener('click', () => {
    currentUsername = usernameInput.value.trim();
    if (currentUsername) {
        fetch('/room/create')
            .then(res => res.json())
            .then(data => {
                currentRoom = data.room_key;
                alert(`Room created! Share this key: ${currentRoom}`);
                startChat();
            })
            .catch(err => console.error("Error creating room:", err));
    } else {
        alert('Please enter a name!');
    }
});

joinRoomBtn.addEventListener('click', () => {
    currentUsername = usernameInput.value.trim();
    if (currentUsername) {
        joinRoomSection.classList.remove('hidden');
    } else {
        alert('Please enter a name!');
    }
});

submitJoinBtn.addEventListener('click', () => {
    const roomKey = roomKeyInput.value.trim();
    if (roomKey) {
        fetch('/room/join', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ room_key: roomKey })
        })
        .then(res => {
            if (res.ok) {
                currentRoom = roomKey;
                startChat();
            } else {
                alert('Invalid room key!');
            }
        })
        .catch(err => console.error("Error joining room:", err));
    } else {
        alert('Please enter a room key!');
    }
});

sendBtn.addEventListener('click', () => {
    const msg = messageInput.value.trim();
    if (msg) {
        fetch(`/room/${currentRoom}/messages`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ username: currentUsername, msg: msg })
        })
        .then(res => {
            if (res.ok) {
                messageInput.value = '';
                fetchMessages(); // Refresh messages immediately after sending
            }
        })
        .catch(err => console.error("Error sending message:", err));
    }
});

leaveBtn.addEventListener('click', () => {
    clearInterval(refreshInterval);
    loginContainer.classList.remove('hidden');
    chatContainer.classList.add('hidden');
    messagesDiv.innerHTML = '';
    currentUsername = '';
    currentRoom = '';
});
EOF

cat << 'EOF' > frontend/nginx.conf
worker_processes 1;

events { worker_connections 1024; }

http {
    include mime.types;
    default_type application/octet-stream;

    server {
        listen 80;

        location / {
            root /usr/share/nginx/html;
            index index.html;
            try_files $uri $uri/ /index.html;
        }

        location /room {
            proxy_pass http://backend:5000;
            proxy_http_version 1.1;
            proxy_set_header Host $host;
        }
    }
}
EOF

# Create Kubernetes files
mkdir k8s
cat << 'EOF' > k8s/backend-deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: backend
spec:
  replicas: 1
  selector:
    matchLabels:
      app: backend
  template:
    metadata:
      labels:
        app: backend
    spec:
      containers:
        - name: backend
          image: yaswanthmitta/backend:latest # Replace with your Docker Hub image
          ports:
            - containerPort: 5000
          env:
            - name: MONGO_URI
              value: mongodb://mongo:27017/chat_db
---
apiVersion: v1
kind: Service
metadata:
  name: backend
spec:
  selector:
    app: backend
  ports:
    - port: 5000
      targetPort: 5000
EOF

cat << 'EOF' > k8s/frontend-deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: frontend
spec:
  replicas: 1
  selector:
    matchLabels:
      app: frontend
  template:
    metadata:
      labels:
        app: frontend
    spec:
      containers:
        - name: frontend
          image: yaswanthmitta/frontend:latest # Replace with your Docker Hub image
          ports:
            - containerPort: 80
---
apiVersion: v1
kind: Service
metadata:
  name: frontend
spec:
  type: NodePort
  selector:
    app: frontend
  ports:
    - port: 80
      targetPort: 80
      nodePort: 30080
EOF

cat << 'EOF' > k8s/mongo-deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: mongo
spec:
  replicas: 1
  selector:
    matchLabels:
      app: mongo
  template:
    metadata:
      labels:
        app: mongo
    spec:
      containers:
        - name: mongo
          image: mongo:6.0
          ports:
            - containerPort: 27017
          volumeMounts:
            - name: mongo-data
              mountPath: /data/db
      volumes:
        - name: mongo-data
          emptyDir: {}
---
apiVersion: v1
kind: Service
metadata:
  name: mongo
spec:
  selector:
    app: mongo
  ports:
    - port: 27017
      targetPort: 27017
EOF

echo "All files for the simple chat app have been generated in the 'secret-chat-app' directory. ✅"
