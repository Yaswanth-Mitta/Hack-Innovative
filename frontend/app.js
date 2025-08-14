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
