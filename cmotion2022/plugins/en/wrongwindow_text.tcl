# cMotion: wrong_console.tcl
# "specific" typos
cMotion_plugin_add_text "wrong console(tm)" "^rm|^cp|^su( -)?$|^make$|^ls" 80 "cMotion_plugin_text_wrong_console" "en"

proc cMotion_plugin_text_wrong_console { nick host handle channel text } {
	cMotionDoAction $channel "" "%VAR{randomWrongConsoleReply}"
	return 1
}

# random wrong console responses
cMotion_abstract_register "randomWrongConsoleReply"
cMotion_abstract_batchadd "randomWrongConsoleReply" {
	"try the other window"
	"Would you like a hand?"
	"%% is t3h l337 h4x0R!"
	"wrong window!"
	"almost..."
}
