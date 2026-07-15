class_name UiLayout
extends RefCounted

## Fixed 800x1280 Control placement helpers (Gimp canvas equivalent).

const CANVAS_W := 800.0
const CANVAS_H := 1280.0


static func place(ctrl: Control, x: float, y: float, w: float, h: float) -> void:
	ctrl.set_anchors_preset(Control.PRESET_TOP_LEFT)
	ctrl.anchor_right = 0.0
	ctrl.anchor_bottom = 0.0
	ctrl.offset_left = x
	ctrl.offset_top = y
	ctrl.offset_right = x + w
	ctrl.offset_bottom = y + h
	ctrl.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	ctrl.grow_vertical = Control.GROW_DIRECTION_BEGIN


static func place_centered(ctrl: Control, cx: float, cy: float, w: float, h: float) -> void:
	place(ctrl, cx - w * 0.5, cy - h * 0.5, w, h)
