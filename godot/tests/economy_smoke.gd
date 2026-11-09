extends SceneTree
## Fails CI if the in-game wallet, purchase UI or ammunition accounting regresses.
const ECONOMY = preload("res://scripts/arsenal.gd")
const BUY = preload("res://scripts/buy_menu.gd")
var failures: Array[String] = []

func _check(result: bool, label: String) -> void:
    if not result:
        failures.append(label)
        push_error("TEAMCS_ECONOMY_FAILURE: "+label)

func _initialize() -> void:
    var wallet = ECONOMY.new()
    wallet.begin_match()
    _check(wallet.credits == 2400,"initial match credits")
    _check(wallet.primary == "","default sidearm")
    _check(wallet.buy("carbine") == "ZAKUPIONO: K-18","primary purchase")
    _check(wallet.credits == 200,"deduct exactly 2200")
    _check(wallet.primary == "carbine" and wallet.active_slot == 1,"active primary")
    _check(not wallet.can_buy("armor"),"wallet rejects unaffordable armor")
    _check(wallet.ammo() == 30 and wallet.reserve() == 90,"new weapon ammunition")
    wallet.fire()
    wallet.fire()
    _check(wallet.ammo() == 28,"firing reduces real magazine")
    wallet.complete_reload()
    _check(wallet.ammo() == 30 and wallet.reserve() == 88,"reload transfers reserve")
    _check(wallet.select_slot(2),"switch to sidearm")
    _check(wallet.active_id() == "p1" and wallet.ammo() == 12,"slot does not share ammo")
    wallet.reward_round(true)
    _check(wallet.credits == 3300,"reward for winning round")
    wallet.begin_round()
    _check(wallet.credits == 3300 and wallet.primary == "","wallet persists, loadout resets each round")
    var menu = BUY.new()
    get_root().add_child(menu)
    menu.purchase_requested.connect(func(id: String):
        wallet.buy(id)
        menu.refresh()
    )
    menu.open(wallet,2)
    _check(menu.visible and menu.items.size() == ECONOMY.CATALOG.size(),"all catalog buttons visible")
    _check(menu.wallet.text == "3300 $","actual wallet displayed")
    var armor_button: Button = menu.items["armor"]
    _check(not armor_button.disabled,"affordable armor selectable")
    armor_button.pressed.emit()
    _check(wallet.has_armor and wallet.credits == 2650,"purchase button pays for armor")
    _check(armor_button.disabled,"owned armor cannot be repurchased")
    var sidearm_button: Button = menu.items["p2"]
    sidearm_button.pressed.emit()
    _check(wallet.credits == 2150 and wallet.sidearm == "p2","sidearm purchase through menu")
    _check(menu.wallet.text == "2150 $","buy UI refreshes exact credits")
    menu.close()
    _check(not menu.visible,"buy phase closes")
    if failures.is_empty():
        print("TEAMCS_ECONOMY_PASS: 20 state and UI assertions")
        quit(0)
    else:
        print("TEAMCS_ECONOMY_FAIL: ",failures)
        quit(1)
