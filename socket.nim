import std/[asyncdispatch, json, strutils]
import ws

type
  LuxSocketClient* = ref object
    ws*: WebSocket
    isConnected*: bool
    url*: string

proc newLuxSocketClient*(url: string): LuxSocketClient =
  new(result)
  result.url = url
  result.isConnected = false

proc connect*(self: LuxSocketClient): Future[bool] {.async.} =
  try:
    echo "[Lux Idle WS] Conectando a ", self.url
    self.ws = await newWebSocket(self.url)
    self.isConnected = true
    result = true
  except CatchableError as e:
    echo "[Lux Idle WS] Erro de conexão WebSocket: ", e.msg
    self.isConnected = false
    result = false

proc sendJson*(self: LuxSocketClient, val: JsonNode): Future[bool] {.async.} =
  if self == nil or not self.isConnected:
    return false
  try:
    await self.ws.send($val)
    result = true
  except CatchableError as e:
    echo "[Lux Idle WS] Erro ao enviar pacote: ", e.msg
    self.isConnected = false
    result = false

proc readMessage*(self: LuxSocketClient): Future[string] {.async.} =
  if self == nil or not self.isConnected:
    return ""
  try:
    result = await self.ws.receiveStrPacket()
  except CatchableError as e:
    self.isConnected = false
    result = ""
