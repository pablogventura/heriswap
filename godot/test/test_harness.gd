class_name TestHarness
extends RefCounted

static func expect(label: String, cond: bool) -> int:
	if cond:
		print("OK ", label)
		return 0
	print("FAIL ", label)
	return 1


static func approx(label: String, a: float, b: float, eps: float = 0.001) -> int:
	return expect(label, absf(a - b) <= eps)
