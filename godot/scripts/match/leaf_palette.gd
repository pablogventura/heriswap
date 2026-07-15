class_name LeafPalette
extends RefCounted

## Accent colors for the 8 craft piece types (star, heart, coin, flower, fish, pennant, sun, cloud).

static func color_for(leaf_type: int) -> Color:
	match clampi(leaf_type, 0, 7):
		0:
			return Color(0.92, 0.74, 0.22)  # yellow star / foil
		1:
			return Color(0.86, 0.28, 0.28)  # red heart
		2:
			return Color(0.55, 0.58, 0.62)  # newsprint / grid coin
		3:
			return Color(0.78, 0.42, 0.68)  # flower magazine
		4:
			return Color(0.28, 0.58, 0.78)  # fish / bird blues
		5:
			return Color(0.35, 0.72, 0.48)  # shiny pennant greens
		6:
			return Color(0.92, 0.55, 0.18)  # kraft / sun orange
		_:
			return Color(0.45, 0.72, 0.88)  # cloud / rainbow sky
