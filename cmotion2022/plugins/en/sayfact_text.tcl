# facts
# Makes the bot return a random fact
#
# Usage:
#	botname tell me   
#	botname what do you know 
#	botname tell me something new

cMotion_plugin_add_text "getfact1" "^%botnicks,?:? tell me" 100 cMotion_plugin_text_get_fact "en"
cMotion_plugin_add_text "getfact2" "^%botnicks,?:? what do you know" 100 cMotion_plugin_text_get_fact "en" 
cMotion_plugin_add_text "getfact3" "^%botnicks,?:? tell me something new" 100 cMotion_plugin_text_get_fact "en"

proc cMotion_plugin_text_get_fact { nick host handle channel text } {
	global cMotionFacts
	set intro "%VAR{get_fact_intros}"
	set items [array names cMotionFacts]
	# this gets a random item to give a fact about
	set i [lindex $items [rand [llength $items]]]
	if {[regexp "(what|who),(.+)" $i matches type item]} {
		set property [lindex $cMotionFacts($type,$item) [rand [llength $cMotionFacts($type,$item)]]]

		cMotionDoAction $channel $nick "$intro $item was $property"

	}
	return 1
}

cMotion_abstract_register "get_fact_intros" {
  "I think I heard that"
  "last I knew, "
  "it could be that"
  "ok, I'll tell you that"
  "well, don't tell anyone else, but%REPEAT{3:7:.}"
}
