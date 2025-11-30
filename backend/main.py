from fastapi import FastAPI, WebSocket, WebSocketDisconnect
import uuid
import random
import json

from websocket import handle_websocket

app = FastAPI()

rooms = {}
connections = {}

### WEBSOCKET ENDPOINT ###
@app.websocket("/ws")
async def websocket_endpoint(ws: WebSocket):
    await handle_websocket(ws=ws, rooms=rooms, connections=connections)