extends Label

var coin_count: int = 0
var coin_total: int = 0

func _process(_delta: float) -> void:
	text = "coins: %d/%d" % [ coin_count, coin_total ]
