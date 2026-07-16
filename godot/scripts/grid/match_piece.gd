class_name MatchPiece
extends RefCounted

## Piece / cell metadata for ScrapSwap match-3 (Candy Crush–style).

enum Special {
	NONE = 0,
	STRIPE_H = 1,
	STRIPE_V = 2,
	WRAPPED = 3,
	BOMB = 4,
	FISH = 5,
}

enum Blocker {
	NONE = 0,
	TAPE = 1, ## frosting / masking tape layers
	GLUE = 2, ## chocolate-like spreading
	SCRAP = 3, ## liquorice swirl-like
	WRAP = 4, ## marmalade
	HONEY = 5,
	CAKE = 6,
	CHEST = 7,
	FOUNTAIN = 8,
}

static func empty() -> Dictionary:
	return {
		"color": -1,
		"special": Special.NONE,
		"blocker": Blocker.NONE,
		"blocker_layers": 0,
		"sticker": 0,
		"playable": true,
	}


static func plain(color: int) -> Dictionary:
	var p := empty()
	p.color = color
	return p


static func color_of(cell) -> int:
	if typeof(cell) == TYPE_DICTIONARY:
		return int(cell.get("color", -1))
	return int(cell)


static func is_empty_cell(cell) -> bool:
	return color_of(cell) < 0
