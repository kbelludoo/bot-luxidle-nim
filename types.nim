import std/[json, options]

type
  GameCredentials* = object
    email*: string
    password*: string
    characterName*: string
    vocation*: string
    token*: string
    origin*: string

  GameSettings* = object
    huntTarget*: string
    autoHunt*: bool
    autoSell*: bool
    autoBless*: bool
    autoDaily*: bool
    autoTasks*: bool
    autoQuiver*: bool
    autoCoinMarket*: bool

  AccountConfig* = object
    id*: string
    name*: string
    enabled*: bool
    bindIP*: string
    credentials*: GameCredentials
    settings*: GameSettings

  CharacterInfo* = object
    name*: string
    level*: int
    vocation*: string

  CharacterState* = object
    name*: string
    level*: int
    vocation*: string
    hp*: int
    mana*: int
    gold*: int64
    coins*: int64

proc parseCredentials(node: JsonNode): GameCredentials =
  if node != nil:
    result.email = node{"email"}.getStr("")
    result.password = node{"password"}.getStr("")
    result.characterName = node{"characterName"}.getStr("")
    result.vocation = node{"vocation"}.getStr("")
    result.token = node{"token"}.getStr("")
    result.origin = node{"origin"}.getStr("")

proc parseSettings(node: JsonNode): GameSettings =
  result.huntTarget = "auto"
  result.autoHunt = true
  result.autoSell = true
  result.autoBless = true
  result.autoDaily = true
  result.autoTasks = true
  result.autoQuiver = true
  result.autoCoinMarket = true
  if node != nil:
    if node.hasKey("huntTarget"): result.huntTarget = node["huntTarget"].getStr("auto")
    elif node.hasKey("hunt_target"): result.huntTarget = node["hunt_target"].getStr("auto")

    if node.hasKey("autoHunt"): result.autoHunt = node["autoHunt"].getBool(true)
    elif node.hasKey("auto_hunt"): result.autoHunt = node["auto_hunt"].getBool(true)

    if node.hasKey("autoSell"): result.autoSell = node["autoSell"].getBool(true)
    elif node.hasKey("auto_sell"): result.autoSell = node["auto_sell"].getBool(true)

    if node.hasKey("autoBless"): result.autoBless = node["autoBless"].getBool(true)
    elif node.hasKey("auto_bless"): result.autoBless = node["auto_bless"].getBool(true)

    if node.hasKey("autoDaily"): result.autoDaily = node["autoDaily"].getBool(true)
    elif node.hasKey("auto_daily"): result.autoDaily = node["auto_daily"].getBool(true)

    if node.hasKey("autoTasks"): result.autoTasks = node["autoTasks"].getBool(true)
    elif node.hasKey("auto_tasks"): result.autoTasks = node["auto_tasks"].getBool(true)

    if node.hasKey("autoQuiver"): result.autoQuiver = node["autoQuiver"].getBool(true)
    elif node.hasKey("auto_quiver"): result.autoQuiver = node["auto_quiver"].getBool(true)

    if node.hasKey("autoCoinMarket"): result.autoCoinMarket = node["autoCoinMarket"].getBool(true)
    elif node.hasKey("auto_coin_market"): result.autoCoinMarket = node["auto_coin_market"].getBool(true)

proc parseAccountConfig*(node: JsonNode): AccountConfig =
  result.id = node{"id"}.getStr("")
  result.name = node{"name"}.getStr(result.id)
  result.enabled = node{"enabled"}.getBool(true)
  result.bindIP = node{"bindIP"}.getStr("")
  result.credentials = parseCredentials(node{"credentials"})
  result.settings = parseSettings(node{"settings"})
