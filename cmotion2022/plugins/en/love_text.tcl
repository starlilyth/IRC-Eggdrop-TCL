## cMotion Module: love
cMotion_abstract_register "loveresponses"
cMotion_abstract_batchadd "loveresponses" { "awh thanks" "i love you too" "i wuv you too" "i love you, %%" "wuv you %%" "love you, %%" "awh :)" "/blushes" "hehe thanks" ":*" }

cMotion_plugin_add_text "love" "(i )?(think )?(you are|you're )?(love|luv|wov|wuv|luvly|lovely)( you)? %botnicks" 100 cMotion_plugin_text_love "en"

proc cMotion_plugin_text_love { nick host handle channel text } {
  global mood
  if {[getFriendshipHandle $user] < 50} {
    frightened $nick $channel
    return 1
  }
  driftFriendship $nick 4
  if {$mood(happy) < 15 && $mood(lonely) < 5} {
    cMotionDoAction $channel $nick "%VAR{loveresponses}"
    cMotionGetHappy
    cMotionGetUnLonely
		cMotion_plugins_settings_set "system" "lastdonefor" $channel "" $nick
    return 1
  } else {
    cMotionDoAction $channel $nick "aww thanks :)"
    set mood(happy) [expr $mood(happy) - 10]
		cMotion_plugins_settings_set "system" "lastdonefor" $channel "" $nick
    return 1
  }
}
