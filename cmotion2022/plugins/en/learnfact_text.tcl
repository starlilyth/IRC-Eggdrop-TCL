# cMotion learn facts TEXT plugin
# This learns facts from text on channel. See also: learnfact_action.tcl
#
# regexp to stop learning of facts
set cMotionSettings(ignorefacts) "is online"

cMotion_plugin_add_text "fact" "(is|was|==?|am|are|were)" 100 cMotion_plugin_text_fact "en"

proc cMotion_plugin_text_fact { nick host handle channel text } {
  global cMotionFacts cMotionFactTimestamps
  cMotion_putloglev d * "Text fact learning triggered.."

  # ignore set ignorewords
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
  #don't let synchro trigger us
  if [string match "(ready to burn|ready for another)" $text] {
    return 0
  }
  # skip questions
  if {[string range $text end end] == "?"} { return 0 }

  # get a string
  if [regexp -nocase {(\w+)\s+(is|was|==?|am|are|were)\s+(.*)} $text matches item blah fact] {
    cMotion_putloglev d * "Text fact learning matched!"
    set item [string tolower $item]
    # skip facts that are too short or long
    if {([string length $fact] < 3) || ([string length $fact] > 30)} { return 0 }
    # skip nonspecific and personal subjects
    if [regexp "(who|why|what|which|when|where|there|then|this|that|you|yours|he|she|we|it|to|have|and|am)" $item] {
      return 0
    }
    set type "what"
    # set first person subjects to speakers nick
    if {$item eq "i"} {
      set item [string tolower $nick]
      set type "who"
    }
    # set first person objects to speakers nick
    if {$item eq "me"} {
      regsub {\mme\M} $fact $nick fact
      set fact [string tolower [string trim $fact]]
      set type "who"
    }
    if {$item eq "my"} {
      regsub {\mmy\M} $fact "%OWNER{$nick}" fact
      set type "who"
    }

    cMotion_putloglev d * "fact: $item ($type) == $fact"
    lappend cMotionFacts($type,$item) $fact
    set cMotionFactTimestamps($type,$item) [clock seconds]
  }
	#return 0 because we don't put anything to irc, so we shouldn't get in the way
  return 0
}
