class_name LeafPalette
extends RefCounted

## Accent colors matching the 8 feuille types (approximate).

static func color_for(leaf_type: int) -> Color:
	match clampi(leaf_type, 0, 7):
		0:
			return Color(0.95, 0.35, 0.28)
		1:
			return Color(0.35, 0.75, 0.32)
		2:
			return Color(0.95, 0.78, 0.22)
		3:
			return Color(0.35, 0.55, 0.95)
		4:
			return Color(0.85, 0.45, 0.85)
		5:
			return Color(0.95, 0.55, 0.18)
		6:
			return Color(0.45, 0.9, 0.85)
		_:
			return Color(0.7, 0.55, 0.35)
