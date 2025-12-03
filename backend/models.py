from pydantic import BaseModel
from typing import List, Optional

# --- Core Models ---

class Player(BaseModel):
    id: str
    username: str
    displayName: Optional[str]
    isHost: bool

class Room(BaseModel):
    id: str
    hostId: str
    players: List[Player]
    state: str = "lobby"
    currentRound: int = 0
    currentPrompt: Optional[str] = None


# --- Incoming WebSocket messages (client → server) ---

class BaseWSMessage(BaseModel):
    type: str

class CreateRoomRequest(BaseWSMessage):
    username: str

class JoinRoomRequest(BaseWSMessage):
    roomId: str
    username: str

class SendMessageRequest(BaseWSMessage):
    roomId: str
    text: str

class LeaveRoomRequest(BaseWSMessage):
    roomId: str

class StartGameRequest(BaseWSMessage):
    roomId: str


# --- Outgoing WebSocket messages (server → client) ---

class RoomJoinedResponse(BaseModel):
    type: str = "room_joined"
    playerId: str
    roomId: str
    displayName: str
    isHost: bool
    room: Room

class RoomUpdateResponse(BaseModel):
    type: str = "room_update"
    room: Room

class ChatMessageResponse(BaseModel):
    type: str = "chat_message"
    senderId: str
    senderDisplayName: str
    text: str

class GameStartedResponse(BaseModel):
    type: str = "game_started"
    room: Room