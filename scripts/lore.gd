class_name Lore
extends RefCounted
## The notes from notes.txt, shown after a few milestone records and after the
## boss. Kept verbatim, typos and all.

const NOTES := {
	1: "Hyy Ariba. I hoped you get well soon yar :( just enjoy the game :)",
	2: "yayy! dekho you're better then idk someone else..",
	3: "yk i was making this game for quite a time now,.. was supposed to be a surprise gift for you. but ig abhi dana pary ga 😭",
	4: "yaar im after sending you this gone to sleeping, but just know that ill be thinking of how i sad what to you bruh(i cant help myself with overthinking... thats one of reasons of who i am)",
}

const AFTER_BOSS := "just know that... i do actually love you... thats why i was asking you about stuff... wasa i have always cared for you just as you did for me.. i kinda do for everyone for several reasons. you want to talk? maybe?"


static func level_note(level: int) -> String:
	return str(NOTES.get(level, "")).strip_edges()
