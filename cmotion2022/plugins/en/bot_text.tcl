## cMotion plugin: bot related

cMotion_plugin_add_text "stupid" "(useless|stupid|idiot|imbecile|incompetent|loser|luser) bot" 100 cMotion_plugin_text_stupid "en"

proc cMotion_plugin_text_stupid { nick host handle channel text } {
  global botnicks
  if {[regexp -nocase "(stupid|idiot|imbecile|incompetent|loser|luser)( bot)?" $text] && [regexp -nocase $botnicks $text]} {
    cMotionDoAction $channel $nick "%VAR{stupidReplies}"
    cMotionGetSad
    driftFriendship $nick -5
    return 1
  }
}

cMotion_abstract_register "stupidReplies"
cMotion_abstract_batchadd "stupidReplies" {
  "You do better in 6911 lines of TCL :P" 
  "You know, I think you say that just to hide the fact that you're not the sharpest tool in the box either." 
  "lalalalala I can't hear you..." 
  "I'm only code, what's your excuse?" 
  "I only have 1s and 0s. You don't seem to be doing so hot with the rest of the numbers" 
  "You see how you do after 2 years on IRC with no sleep" 
  "You say that now. Wait till I'm in Mensa." 
  "You're so thick even Densa rejected you." 
  "%VAR{unmiles}"
}

cMotion_plugin_add_text "notbot" "%botnicks('s| is) a bot" 60 cMotion_plugin_text_notbot "en"
cMotion_plugin_add_text "arebot" "((is %botnicks a bot)|(are you a bot,? %botnicks)|(^%botnicks%:? are you a bot))" 60 cMotion_plugin_text_notbot "en"

proc cMotion_plugin_text_notbot { nick host handle channel text } {
  cMotionDoAction $channel $nick "%VAR{notbots}"
  return 1
}
cMotion_abstract_register "notbots"
cMotion_abstract_batchadd "notbots" {
  "no, I'm not"
  "am not :("
  "am not"
  "haha, no %VAR{smiles}"
  "%VAR{nos}"
  "so not a bot"
  "I thought you were a bot, %%!"
}
