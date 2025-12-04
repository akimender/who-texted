from pydantic import BaseModel
from typing import List, Optional
import uuid

# --- Core Models ---

class Player(BaseModel):
    id: str
    username: str
    displayName: Optional[str]
    isHost: bool
    points: int

class Response(BaseModel):
    id: str
    playerId: Optional[str] = None  # Stored internally, hidden in VotingPhaseResponse, revealed in RevealPhaseResponse
    text: str
    isReal: bool  # True if from real impersonator
    voteCount: int = 0  # Votes received

class Vote(BaseModel):
    voterId: str
    responseId: str  # Which response they voted for

class Round(BaseModel):
    id: str
    roundNumber: int
    prompt: str
    targetPlayerId: str  # The player being impersonated
    promptSenderId: str  # The player who "sent" the prompt message
    realImpersonatorId: str  # Secretly assigned real impersonator
    responses: List[Response] = []
    votes: List[Vote] = []
    state: str = "prompt"  # prompt, responding, voting, reveal, scoring

class Room(BaseModel):
    id: str
    hostId: str
    players: List[Player]
    state: str = "lobby" # default to lobby
    currentRound: int = 0
    maxRounds: int = 5
    currentPrompt: Optional[str] = None
    currentRoundData: Optional[Round] = None
    rounds: List[Round] = []


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

class SubmitResponseRequest(BaseWSMessage):
    type: str = "submit_response"
    roomId: str
    text: str

class SubmitVoteRequest(BaseWSMessage):
    type: str = "submit_vote"
    roomId: str
    responseId: str

class NextRoundRequest(BaseWSMessage):
    type: str = "next_round"
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
    type: str = "game_start"
    room: Room

class RoundSetupResponse(BaseModel):
    type: str = "round_setup"
    room: Room
    targetPlayerName: str
    promptSenderName: str
    yourRole: str  # "real_impersonator" or "fake_responder"

class PromptDisplayResponse(BaseModel):
    type: str = "prompt_display"
    room: Room
    promptText: str
    targetPlayerName: str

class ResponseSubmittedResponse(BaseModel):
    type: str = "response_submitted"
    room: Room
    allSubmitted: bool  # True if all players have submitted

class VotingPhaseResponse(BaseModel):
    type: str = "voting_phase"
    room: Room
    responses: List[Response]  # Anonymous, no playerId shown

class VoteSubmittedResponse(BaseModel):
    type: str = "vote_submitted"
    room: Room
    allVoted: bool

class RevealPhaseResponse(BaseModel):
    type: str = "reveal_phase"
    room: Room
    responses: List[Response]  # With playerId revealed
    votes: List[Vote]

class ScoringPhaseResponse(BaseModel):
    type: str = "scoring_phase"
    room: Room
    scores: dict  # player_id -> points_earned
    roundSummary: dict

class RoundCompleteResponse(BaseModel):
    type: str = "round_complete"
    room: Room

class GameFinishedResponse(BaseModel):
    type: str = "game_finished"
    room: Room
    finalScores: dict  # player_id -> total_points
    winner: Player