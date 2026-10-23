class_name Lang
extends RefCounted
## Translation for static code, which has no Object.tr(). Texts are written in English and
## used as message ids; the translations live in localization/*.po.


## `msgid` in the current language (unchanged if there is no translation).
static func text(msgid: String) -> String:
	return String(TranslationServer.translate(msgid))


## True if the current language writes decimals with a comma (1,5K instead of 1.5K).
static func uses_decimal_comma() -> bool:
	return TranslationServer.get_locale().get_slice("_", 0) == "de"
