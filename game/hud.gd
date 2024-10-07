extends Control

var player1_position := Vector3()
var player2_position := Vector3()
var coin_count := 0
var coin_total := 0
func _ready():
	coin_total = get_tree().get_nodes_in_group("collectible").size()

func _on_collected_coin():
	coin_total = maxi(get_tree().get_nodes_in_group("collectible").size(), coin_total)
	coin_count = mini(coin_total, coin_count + 1)
	Console.print_line("coin get (%d/%d)" % [coin_count, coin_total], true)
	if coin_count >= coin_total:
		Console.print_line("all coins collected!", true)
