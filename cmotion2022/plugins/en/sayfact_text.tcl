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
	set intro "%VAR{get_fact_intros}"
	global cMotionFacts
	set items [array names cMotionFacts]
	#this gets a random item to give a fact about
	set i [lindex $items [rand [llength $items]]]
	if {[regexp "what,(.+)" $i matches item]} {
		#set item 
	}
	#set property $cMotionFacts(what,$item)
	set property [lindex $cMotionFacts(what,$item) [rand [llength $cMotionFacts(what,$item)]]]
	#give the people what they want!
	cMotionDoAction $channel $nick "$intro $item was $property"
	return 1
}

cMotion_abstract_register "get_fact_intros"
cMotion_abstract_batchadd "get_fact_intros" {
  "I think I heard that"
  "last I knew, "
  "it could be that"
  "ok, I'll tell you that"
  "well, don't tell anyone, but%REPEAT{3:7:.}"
}
