import std/[asyncdispatch, asynchttpserver, json, times]
import supervisor, bot

type
  WebServer* = ref object
    supervisor*: Supervisor
    port*: int
    startTime*: float

proc newWebServer*(sup: Supervisor, port: int): WebServer =
  new(result)
  result.supervisor = sup
  result.port = port
  result.startTime = epochTime()

proc start*(self: WebServer) {.async.} =
  var server = newAsyncHttpServer()
  let port = self.port
  let sup = self.supervisor
  let startT = self.startTime

  proc cb(req: Request) {.async.} =
    if req.url.path == "/api/status":
      let uptime = (epochTime() - startT).int64
      var accArray = newJArray()

      for b in sup.getBots():
        accArray.add(%*{
          "id": b.config.id,
          "name": b.config.name,
          "running": b.running,
          "kills": b.kills,
          "gold": b.gold,
          "exp": b.exp,
          "cb_state": b.cbState,
          "fatigue": b.fatigue
        })

      let payload = %*{
        "game": "Lux Idle Online",
        "engine": "Native Nim Ultra-Light (Zero-GC-Overhead)",
        "uptime_sec": uptime,
        "total_accounts": accArray.len,
        "port": port,
        "accounts": accArray
      }

      let headers = newHttpHeaders([
        ("Content-Type", "application/json"),
        ("Access-Control-Allow-Origin", "*")
      ])
      await req.respond(Http200, $payload, headers)
    else:
      await req.respond(Http404, "{\"error\": \"not found\"}", newHttpHeaders([("Content-Type", "application/json")]))

  server.listen(Port(port))
  echo "[Dashboard] Servidor HTTP de telemetria ativo na porta ", port
  while true:
    if server.shouldAcceptRequest():
      await server.acceptRequest(cb)
    else:
      await sleepAsync(10)
