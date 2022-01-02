## cMotion plugin: youreword

cMotion_plugin_add_text "youreword" "^i'?m .+$" 20 cMotion_plugin_text_youreword "en"

proc cMotion_plugin_text_youreword { nick host handle channel text } {
  if [regexp -nocase {^i'?m ([a-z]+)$} $text matches word] {
	    cMotionDoAction $channel $nick "You're $word? I thought you were $nick!"
		return 1
    return 0
  }
}
