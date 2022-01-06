# cMotion learn facts plugin
#
# regexp to stop learning of facts
set cMotionSettings(ignorefacts) "is online"

cMotion_plugin_add_action "fact" {\m(is|was|=|am|are|were)\M} 100 cMotion_plugin_action_fact "en"

proc cMotion_plugin_action_fact { nick host handle channel text } {
  global cMotionFacts cMotionFactTimestamps
  set ignoretext [cMotion_setting_get "ignorefacts"]
  if {$ignoretext != ""} {
    if [regexp -nocase $ignoretext $text] {
      return 0
    }
  }
  #don't let trivia trigger us
	if [string match "*answer was*" $text] {
		return 0
	}  
  # skip questions
  if {[string range $text end end] == "?"} { return 0 }
  # get a string
  if [regexp -nocase {\m([^ !"]+)[!" ]+(is|was|==?|am) ?([a-z0-9 '_/-]+)} $text matches item blah fact] {
    set item [string tolower $item]
    # skip facts that are too short or long
    if {([string length $fact] < 3) || ([string length $fact] > 30)} { return 0 }
    # skip nonspecific and personal subjects
    if [regexp "(what|which|have|it|that|when|where|there|then|this|who|you|you|yours|why|he|she)" $item] {
      return 0
    }
    # set first person subjects to speakers nick
    if {$item == "i"} {set item [string tolower $nick]}
    # set first person objects to speakers nick
    regsub {\mme\M} $fact $nick fact

    set fact [string tolower [string trim $fact]]
    regsub {\mmy\M} $fact "%OWNER{$nick}" fact
    cMotion_putloglev d * "fact: $item == $fact"
    lappend cMotionFacts(what,$item) $fact
    set cMotionFactTimestamps(what,$item) [clock seconds]
  }
	#return 0 because we don't put anything to irc, so we shouldn't get in the way
  return 0
}
