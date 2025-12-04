# **Who Texted? (WIP)**

**Who Texted?** is a multiplayer social-imitation party game where players impersonate each other inside a fake iMessage-style chat experience.  
Each round, one player is secretly assigned as the **real impersonator** while everyone else submits misleading responses. The group must vote on which reply is authentic.

This repository contains an **in-progress** implementation of the game using a **SwiftUI iOS client** and a **Python WebSocket backend**.

---

## 🚀 **Overview**

Players join a room, start a game, and participate in multiple rounds of text-based impersonation. Each round:

- A **target player** is chosen (the person being impersonated)  
- A **prompt sender** is selected (the message appears to come from them)  
- One user becomes the **real impersonator** (secret role)  
- All players submit a response imitating the target player  
- Everyone **votes** on which reply is real  
- The game **reveals** authors and computes scores  

---

## 🧰 **Technologies Used**

### **iOS Client (Swift)**
- Swift 5  
- **SwiftUI**  
- Combine or async/await for WebSocket communication  
- Codable models mirroring backend  
- **iMessage-inspired UI** for prompts and responses  

### **Backend Server (Python)**
- **FastAPI** or Starlette (ASGI WebSockets)  
- **Pydantic** (Room, Round, Player, Response, Vote)  
- UUID-based room/round management  
- In-memory game state tracking  

### **Communication**
- **Bidirectional WebSocket protocol** using a single envelope (`SocketEnvelope`)  
- JSON-encoded events  
- Server-driven state synchronization  

---

## 🏗 **Architecture**

### **Shared Models**
Client and server both use analogous models:

- `Player`  
- `Room`  
- `Round`  
- `Response`  
- `Vote`  

The backend is the **source of truth**, while the client renders UI based on `Room.state` and `Round.state`.

### **Event System**
All WebSocket events are wrapped in a unified `SocketEnvelope`, containing:

- `type` — string identifying the event  
- `room` — synchronized state snapshot  
- Additional optional fields depending on the phase  
  (e.g., `promptText`, `responses`, `votes`, `scores`, etc.)

This makes the protocol **simple, flexible, and extensible**.

### **Game State Machine**

**Room states:**
- `lobby`  
- `playing`  
- `finished`

**Round states:**
- `prompt`  
- `responding`  
- `voting`  
- `reveal`  
- `scoring`  

SwiftUI screens update based on these values.

---

## 📌 **Project Status**

This project is actively under development.

### **Currently implemented / in progress**
- WebSocket event handling for all game phases  
- Full round lifecycle (prompt → response → vote → reveal → scoring)  
- Role assignment and scoring logic  
- SwiftUI screens for each phase  
- **iMessage-style UI** for prompts and anonymous responses  

### **Upcoming work**
- UI polish + animations  
- More robust prompt generation  
- Better real-time state syncing  
- Error handling + reconnection logic  
- Multi-device testing and latency improvements  

---

## 🎯 **Goals**

- Build a **fast, fun, and chaotic** social party game  
- Keep architecture simple, modular, and maintainable  
- Deliver smooth real-time multiplayer over WebSockets  
- Create a polished UI that feels intuitive and playful  
- Support future expansions (new modes, themes, prompts)