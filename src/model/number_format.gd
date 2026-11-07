class_name NumberFormat
extends RefCounted
## Compact number formatting for the UI: 999, 1.23K, 12.3K, 456M, ... (1,23K in German)

const SUFFIXES: Array[String] = ["", "K", "M", "B", "T", "Qa", "Qi"]


## Always rounds down, so the UI never shows more money than the player has.
static func compact(value: float) -> String:
	var prefix := "-" if value < 0.0 else ""
	var v := absf(value)
	if v < 1000.0:
		return prefix + str(int(v))
	var tier := 0
	while v >= 1000.0 and tier < SUFFIXES.size() - 1:
		v /= 1000.0
		tier += 1
	# The epsilon guards against float error, e.g. 1.15 * 100 = 114.999...
	var text: String
	if v >= 100.0:
		text = str(int(v + 1e-9))
	elif v >= 10.0:
		text = "%.1f" % (floorf(v * 10.0 + 1e-6) / 10.0)
	else:
		text = "%.2f" % (floorf(v * 100.0 + 1e-6) / 100.0)
	if Lang.uses_decimal_comma():
		text = text.replace(".", ",")
	return prefix + text + SUFFIXES[tier]


## Friendly number for a headline: 345,678 below a million, then 1.3 million, 25.7 billion, 120
## trillion, ...
## (345.678 and 1,3 Mio. in German). Rounds down like compact().
static func words(value: float) -> String:
	var prefix := "-" if value < 0.0 else ""
	var v := absf(value)
	if v < 1_000_000.0:
		return prefix + _grouped(int(v + 1e-9))
	var tier := 0
	while v >= 1000.0 and tier < SUFFIXES.size() - 1:
		v /= 1000.0
		tier += 1
	var text: String
	if v >= 100.0 or floorf(v * 10.0 + 1e-6) == floorf(v) * 10.0:
		text = str(int(v + 1e-9))
	else:
		text = "%.1f" % (floorf(v * 10.0 + 1e-6) / 10.0)
	if Lang.uses_decimal_comma():
		text = text.replace(".", ",")
	return prefix + text + " " + _tier_word(tier)


## 1234567 as 1,234,567 (1.234.567 in German).
static func _grouped(n: int) -> String:
	var digits := str(n)
	var separator := "." if Lang.uses_decimal_comma() else ","
	var text := ""
	while digits.length() > 3:
		text = separator + digits.right(3) + text
		digits = digits.left(digits.length() - 3)
	return digits + text


static func _tier_word(tier: int) -> String:
	match tier:
		2: return Lang.text("million")
		3: return Lang.text("billion")
		4: return Lang.text("trillion")
		5: return Lang.text("quadrillion")
		_: return Lang.text("quintillion")
