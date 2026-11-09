extends RefCounted
## Fully offline match economy, per-weapon ammunition and round purchases.
const CATALOG := [
    {"id":"p1","name":"P-9","category":"PISTOLETY","cost":0,"slot":2,"mag":12,"reserve":48,"interval":.24,"impact":40,"reload":1.1},
    {"id":"p2","name":"P-12","category":"PISTOLETY","cost":500,"slot":2,"mag":15,"reserve":60,"interval":.20,"impact":32,"reload":1.15},
    {"id":"smg","name":"PM-7","category":"PM","cost":1250,"slot":1,"mag":28,"reserve":112,"interval":.11,"impact":27,"reload":1.55},
    {"id":"carbine","name":"K-18","category":"KARABINY","cost":2200,"slot":1,"mag":30,"reserve":90,"interval":.15,"impact":44,"reload":1.8},
    {"id":"rifle","name":"K-24","category":"KARABINY","cost":2900,"slot":1,"mag":24,"reserve":72,"interval":.19,"impact":60,"reload":2.0},
    {"id":"precision","name":"P-40","category":"PRECYZYJNE","cost":3600,"slot":1,"mag":8,"reserve":32,"interval":.8,"impact":100,"reload":2.4},
    {"id":"armor","name":"KAMIZELKA","category":"WYPOSAŻENIE","cost":650,"slot":0}
]
const INITIAL_CREDITS := 2400
const WIN_REWARD := 3100
const LOSS_REWARD := 1800
const MAX_CREDITS := 12000
var credits := INITIAL_CREDITS
var primary := ""
var sidearm := "p1"
var active_slot := 2
var has_armor := false
var magazines: Dictionary = {}
var reserves: Dictionary = {}

func begin_match() -> void:
    credits = INITIAL_CREDITS
    begin_round()

func begin_round() -> void:
    primary = ""
    sidearm = "p1"
    active_slot = 2
    has_armor = false
    magazines.clear()
    reserves.clear()
    for entry in CATALOG:
        var item: Dictionary = entry
        var id: String = str(item["id"])
        if int(item["slot"]) > 0:
            magazines[id] = int(item["mag"])
            reserves[id] = int(item["reserve"])

func reward_round(won: bool) -> void:
    credits = mini(MAX_CREDITS, credits + (WIN_REWARD if won else LOSS_REWARD))

func item_by_id(item_id: String) -> Dictionary:
    for entry in CATALOG:
        var item: Dictionary = entry
        if str(item["id"]) == item_id:
            return item
    return {}

func can_buy(item_id: String) -> bool:
    var item := item_by_id(item_id)
    if item.is_empty() or credits < int(item["cost"]):
        return false
    if item_id == "armor":
        return not has_armor
    return item_id != primary and item_id != sidearm

func buy(item_id: String) -> String:
    var item := item_by_id(item_id)
    if item.is_empty():
        return "NIEZNANY PRZEDMIOT"
    if not can_buy(item_id):
        return "ZA MAŁO ŚRODKÓW LUB JUŻ POSIADASZ"
    credits -= int(item["cost"])
    if item_id == "armor":
        has_armor = true
    else:
        var slot := int(item["slot"])
        if slot == 1:
            primary = item_id
        else:
            sidearm = item_id
        active_slot = slot
        magazines[item_id] = int(item["mag"])
        reserves[item_id] = int(item["reserve"])
    return "ZAKUPIONO: " + str(item["name"])

func select_slot(slot: int) -> bool:
    if slot == 1 and primary != "":
        active_slot = 1
        return true
    if slot == 2 and sidearm != "":
        active_slot = 2
        return true
    return false

func active_id() -> String:
    return primary if active_slot == 1 and primary != "" else sidearm

func active_weapon() -> Dictionary:
    return item_by_id(active_id())

func ammo() -> int:
    return int(magazines.get(active_id(),0))

func reserve() -> int:
    return int(reserves.get(active_id(),0))

func capacity() -> int:
    return int(active_weapon().get("mag",12))

func cooldown() -> float:
    return float(active_weapon().get("interval",.2))

func impact() -> int:
    return int(active_weapon().get("impact",40))

func reload_seconds() -> float:
    return float(active_weapon().get("reload",1.2))

func fire() -> bool:
    var id := active_id()
    if ammo() <= 0:
        return false
    magazines[id] = ammo()-1
    return true

func can_reload() -> bool:
    return ammo() < capacity() and reserve() > 0

func complete_reload() -> void:
    var id := active_id()
    var amount := mini(capacity()-ammo(),reserve())
    if amount <= 0:
        return
    magazines[id] = ammo()+amount
    reserves[id] = reserve()-amount
