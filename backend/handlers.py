import json
from models import (
    BaseWSMessage, CreateRoomRequest, JoinRoomRequest,
    SendMessageRequest, LeaveRoomRequest,
)

def parse_message(raw: str) -> BaseWSMessage:
    data = json.loads(raw)
    msg_type = data.get("type")

    match msg_type:
        case "create_room":
            return CreateRoomRequest(**data)
        case "join_room":
            return JoinRoomRequest(**data)
        case "send_message":
            return SendMessageRequest(**data)
        case "leave_room":
            return LeaveRoomRequest(**data)
        case _:
            raise ValueError(f"Unknown WebSocket event type: {msg_type}")
