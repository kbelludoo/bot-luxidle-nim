import std/[asyncdispatch, json, strformat, strutils, times]
import types, socket, stealth

type
  BotInstance* = ref object
    config*: AccountConfig
    socket*: LuxSocketClient
    character*: CharacterState
    running*: bool
    isHunting*: bool
    kills*: int64
    gold*: int64
    exp*: int64
    currentLevel*: int
    cbState*: string
    fatigue*: float

proc newBotInstance*(config: AccountConfig): BotInstance =
  new(result)
  result.config = config
  let wsUrl = if config.credentials.origin.len == 0:
                "wss://luxidle.com.br/ws?livro=1&cacadas=1"
              else:
                var orig = config.credentials.origin
                let scheme = if orig.startsWith("https"): "wss" else: "ws"
                var host = orig.replace("https://", "").replace("http://", "").strip(chars = {'/'})
                scheme & "://" & host & "/ws?livro=1&cacadas=1"
  result.socket = newLuxSocketClient(wsUrl)
  result.running = false
  result.isHunting = false
  result.kills = 0
  result.gold = 0
  result.exp = 0
  result.currentLevel = 1
  result.cbState = "Closed"
  result.fatigue = 0.0

proc handleMessage*(self: BotInstance, raw: string) {.async.} =
  try:
    let node = parseJson(raw)
    let t = node{"t"}.getStr("")
    case t
    of "account":
      echo fmt"👤 [{self.config.name}] Conta carregada no Lux Idle."
      if node.hasKey("characters") and node["characters"].kind == JArray:
        var selectedName = ""
        for c in node["characters"]:
          let cName = c{"name"}.getStr("")
          let cLvl = c{"level"}.getInt(1)
          if self.config.credentials.characterName.len > 0:
            if cName == self.config.credentials.characterName:
              selectedName = cName
              break
          else:
            selectedName = cName
            break
        if selectedName.len > 0:
          echo fmt"🎮 [{self.config.name}] Selecionando personagem: {selectedName}"
          discard await self.socket.sendJson(%*{"t": "selectChar", "name": selectedName})
    of "welcome", "state":
      if node.hasKey("character") and node["character"].kind == JObject:
        let c = node["character"]
        let lvl = c{"level"}.getInt(1)
        let goldVal = c{"gold"}.getBiggestInt(0)
        if lvl > 0: self.currentLevel = lvl
        if goldVal > 0: self.gold = goldVal
        self.character.name = c{"name"}.getStr("")
        self.character.level = lvl
        self.character.gold = goldVal
    of "grupoConvite":
      let fromUser = node{"from"}.getStr("")
      echo fmt"👥 [{self.config.name}] Convite de party recebido de '{fromUser}'. Aceitando..."
      discard await self.socket.sendJson(%*{"t": "grupo", "action": "aceitar"})
    of "pong", "coinMarket":
      discard
    else:
      discard
  except CatchableError:
    discard

proc performAutomationTick*(self: BotInstance) {.async.} =
  if not self.socket.isConnected: return

  # 1. Auto-Hunt
  if self.config.settings.autoHunt and not self.isHunting:
    var target = self.config.settings.huntTarget
    if target.len == 0 or target == "auto":
      if self.currentLevel < 20: target = "hunt-rotworms"
      elif self.currentLevel < 50: target = "hunt-dragons"
      else: target = "hunt-demons"
    echo fmt"⚔️ [{self.config.name}] Iniciando caçada em '{target}'..."
    discard await self.socket.sendJson(%*{
      "t": "startHunt",
      "hunt": target,
      "mode": "online",
      "distance": 0
    })
    self.isHunting = true
    await pacingDelay(300, 500)

  # 2. Blessings
  if self.config.settings.autoBless:
    for b in 1 .. 5:
      discard await self.socket.sendJson(%*{"t": "buyBless", "blessing": b})
      await pacingDelay(100, 250)

  # 3. Quiver Auto (Paladino)
  if self.config.settings.autoQuiver:
    discard await self.socket.sendJson(%*{"t": "quiverAuto"})
    await pacingDelay(150, 300)

  # 4. Venda de loot
  if self.config.settings.autoSell:
    discard await self.socket.sendJson(%*{"t": "sellTrash"})
    await pacingDelay(200, 400)

  # 5. Diárias
  if self.config.settings.autoDaily:
    discard await self.socket.sendJson(%*{"t": "claimDaily"})
    await pacingDelay(200, 400)

proc readerLoop*(self: BotInstance) {.async.} =
  while self.running and self.socket.isConnected:
    let msg = await self.socket.readMessage()
    if msg.len > 0:
      await self.handleMessage(msg)
    else:
      break

proc runLoop*(self: BotInstance) {.async.} =
  self.running = true
  echo fmt"🚀 Bot [{self.config.name}] (Lux Idle Online) conectado com protocolo nativo."

  while self.running:
    let connected = await self.socket.connect()
    if connected:
      # Handshake inicial
      discard await self.socket.sendJson(%*{"t": "delta", "on": true, "sessao": true, "fundo": true})
      discard await self.socket.sendJson(%*{"t": "oculta", "on": false})

      let token = self.config.credentials.token
      if token.len > 0 and token != "seu-token-de-sessao-ou-jwt":
        discard await self.socket.sendJson(%*{"t": "resume", "token": token})
      elif self.config.credentials.email.len > 0:
        discard await self.socket.sendJson(%*{
          "t": "login",
          "email": self.config.credentials.email,
          "password": self.config.credentials.password
        })

      asyncCheck self.readerLoop()

      var pingTimer = 0
      while self.running and self.socket.isConnected:
        await self.performAutomationTick()

        inc pingTimer
        if pingTimer >= 6: # a cada ~18s (6 x 3s)
          pingTimer = 0
          let nowMs = (epochTime() * 1000).int64
          discard await self.socket.sendJson(%*{"t": "ping", "at": nowMs})

        let delayMs = applyJitter(3000, 0.20)
        await sleepAsync(delayMs)
    else:
      echo fmt"⚠️ [{self.config.name}] Falha na conexão WS. Reconectando em breve..."

    if self.running:
      self.isHunting = false
      let reconnDelay = applyJitter(5000, 0.20)
      await sleepAsync(reconnDelay)

  echo fmt"🛑 Bot [{self.config.name}] finalizado."
