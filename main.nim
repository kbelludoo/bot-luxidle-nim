import std/[asyncdispatch, json, os, strutils, strformat, random]
import types, supervisor, dashboard, bot

const DefaultAccountsExample = staticRead("accounts.example.json")

proc formatNumber(n: int64): string =
  if n < 1000:
    $n
  elif n < 1_000_000:
    fmt"{(n.float / 1000.0):.1f}k"
  else:
    fmt"{(n.float / 1_000_000.0):.2f}kk"

proc runTicker(sup: Supervisor) {.async.} =
  var tick: int64 = 0
  while true:
    let jitter = 0.8 + rand(0.4)
    await sleepAsync((4000.0 * jitter).int)
    inc tick

    var totalKills: int64 = 0
    var totalGold: int64 = 0
    var totalExp: int64 = 0
    let bots = sup.getBots()

    for b in bots:
      totalKills += b.kills
      totalGold += b.gold
      totalExp += b.exp

    echo fmt"[Console Ticker #{tick}] Contas: {bots.len} | Kills: {totalKills} | Lux Coins: {formatNumber(totalGold)} | Exp: {formatNumber(totalExp)}"

proc main() =
  echo "================================================================================"
  echo "       ⚡ LUX IDLE ONLINE NATIVE NIM BOT (ZERO-GC & ALTA PERFORMANCE) ⚡"
  echo "================================================================================"

  let configPath = "accounts.json"
  var content = ""
  if fileExists(configPath):
    content = readFile(configPath)
  else:
    echo "⚠️ Arquivo accounts.json não encontrado. Criando template padrão..."
    writeFile(configPath, DefaultAccountsExample)
    content = DefaultAccountsExample

  let rootJson = parseJson(content)
  var allConfigs: seq[AccountConfig] = @[]
  if rootJson.kind == JArray:
    for item in rootJson:
      allConfigs.add(parseAccountConfig(item))

  let targetAcc = getEnv("ACCOUNT", "")
  var activeConfigs: seq[AccountConfig] = @[]
  for cfg in allConfigs:
    if not cfg.enabled and cfg.id != targetAcc:
      continue
    if targetAcc.len > 0 and cfg.id != targetAcc:
      continue
    activeConfigs.add(cfg)

  if activeConfigs.len == 0:
    echo "⚠️ Nenhuma conta com 'enabled: true' encontrada em accounts.json."

  let sup = newSupervisor(activeConfigs)
  sup.startAll()

  var port = 3012
  let portEnv = getEnv("PORT", "3012")
  try:
    port = parseInt(portEnv)
  except ValueError:
    port = 3012

  let webServer = newWebServer(sup, port)
  asyncCheck webServer.start()
  asyncCheck runTicker(sup)

  echo fmt"Bot operacional na porta {port}. Pressione Ctrl+C para encerrar."
  runForever()

when isMainModule:
  main()
