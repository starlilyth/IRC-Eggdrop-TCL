## cMotion plugin: spoonerisms

cMotion_plugin_add_text "spoon" {^([^%/aeiou. ]+)([aeiuo][a-z]+) ([a-z]+ )?([^aeiou. ]*)([aeiuo][a-z]+)$} 1 cMotion_plugin_text_spoon "en"

proc cMotion_plugin_text_spoon { nick host handle channel text } {

  if {[regexp -nocase {^([^%/aeiou. ]+)([aeiuo][a-z]+) ([a-z]+ )?([^aeiou. ]*)([aeiuo][a-z]+)$} $text matches 1 2 3 4 5 6 7]} {
		if {![string equal -nocase "$4$2 $3$1$5" $text]} {
    	cMotionDoAction $channel $text "%VAR{spoonerisms}" "$4$2 $3$1$5"
    	return 1
		}
  }
}

cMotion_abstract_register "spoonerisms"
cMotion_abstract_batchadd "spoonerisms" { "I read that as %2" "%%? I thought you said %2" "/. o O (%2)" }
