## cMotion plugin: manners

cMotion_plugin_add_text "sorry1" "(i'm)?( )?(very)?( )?sorry(,)? %botnicks" 100 cMotion_plugin_text_sorry "en"
cMotion_plugin_add_text "sorry2" "%botnicks:? sorry" 100 cMotion_plugin_text_sorry "en"

proc cMotion_plugin_text_sorry { nick host handle channel text } {
  cMotionDoAction $channel $nick "%VAR{sorryoks} %%"
  cMotionGetHappy
  cMotionGetUnLonely
  driftFriendship $nick 3
  return 1
}
cMotion_abstract_register "sorryoks"
cMotion_abstract_batchadd "sorryoks" { 
  "ok" 
  "that's ok" 
  "alright then" 
  "i forgive you" 
  "That's ok then. I suppose." 
  "humph"
  "apology accepted."
}
#
cMotion_plugin_add_text "thanks" "^(thank(s|z|x)|thankyou|thank you|thx|thanx|ta|cheers|merki|merci)" 100 cMotion_plugin_text_thanks "en"
proc cMotion_plugin_text_thanks { nick host handle channel text } {
	if [cMotionTalkingToMe $text] {
	  cMotionDoAction $channel $nick "%VAR{welcomes}"
	  cMotionGetHappy
	  driftFriendship $nick 3
	  return 1
  }
}
cMotion_abstract_register "welcomes"
cMotion_abstract_batchadd "welcomes" {
  "you're welcome" 
  "no problem" 
  "np" "no prob" 
  "ok" 
  "my pleasure" 
  "any time" 
  "only for you" 
  "no biggie" 
  "no worries"
}
