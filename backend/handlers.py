import json
from models import (
    BaseWSMessage, CreateRoomRequest, JoinRoomRequest,
    SendMessageRequest, LeaveRoomRequest, StartGameRequest,
    SubmitResponseRequest, SubmitVoteRequest, NextRoundRequest
)

def parse_message(raw: str) -> BaseWSMessage:
    data = json.loads(raw)
    msg_type = data.get("type")

    match msg_type:
        case "create_room":
            return CreateRoomRequest(**data)
        case "join_room":
            return JoinRoomRequest(**data)
        case "start_game":
            return StartGameRequest(**data)
        case "send_message":
            return SendMessageRequest(**data)
        case "leave_room":
            return LeaveRoomRequest(**data)
        case "submit_response":
            return SubmitResponseRequest(**data)
        case "submit_vote":
            return SubmitVoteRequest(**data)
        case "next_round":
            return NextRoundRequest(**data)
        case _:
            raise ValueError(f"Unknown WebSocket event type: {msg_type}")
