## cMotion: correct common english errors by other people

cMotion_plugin_add_text "correct-of" "(must|should) of" 60 cMotion_plugin_text_correct-of "en"
cMotion_plugin_add_text "correct-your" "^your (a |the )?\[a-z\]+$" 60 cMotion_plugin_text_correct-your "en"
cMotion_plugin_add_text "correct-regexp" "^s/\[^/\]+/\[^/\]+$" 60 cMotion_plugin_text_correct-regexp "en"

proc cMotion_plugin_text_correct-of { nick host handle channel text } {
    cMotionDoAction $channel $nnk "%VAR{shouldhaves}"
    return 1
}
cMotion_abstract_register "shouldhaves"
cMotion_abstract_batchadd "shouldhaves" {
  "\"%% have\" %VAR{smiles}"
  "%% what?"
  "%% HAVE, %% HAVE"
  "s/of/have/"
}

proc cMotion_plugin_text_correct-your {nick host handle channel text} {
	cMotionDoAction $channel $nick "%VAR{correctyour}"
  return 1
}
cMotion_abstract_register "correctyour"
cMotion_abstract_batchadd "correctyour" {
  "%%: \"you're\"" 
  "their what?" 
  "s/your/you're/"
}

proc cMotion_plugin_text_correct-regexp {nick host handle channel text} {
	if [string match "\\" $text] {
		return 0
	}
	cMotionDoAction $channel $nick "%VAR{correctregexp}"
	return 1
}
cMotion_abstract_register "correctregexp"
cMotion_abstract_batchadd "correctregexp" {
 "Invalid regular expression." 
 "That wont work." 
 "/detects invalid regexp use" 
 "%%: +/" 
}