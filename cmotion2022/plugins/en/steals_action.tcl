## cMotion plugin: steals
cMotion_plugin_add_action "steals" "^(steals|theives|removes|takes) %botnicks'?s .+" 100 cMotion_plugin_action_steals "en"

proc cMotion_plugin_action_steals { nick host handle channel text } {
  global botnicks
  if [regexp -nocase "(steals|theives|removes|takes) ${botnicks}'?s (.+)" $text matches action object] {
    cMotionDoAction $channel $nick "%VAR{stolens}"
    cMotionGetSad
    # TODO: switch to using plugin settings for this
    #set cMotionCache(lastEvil) $nick
		cMotion_plugins_settings_set "system" "lastevil" $channel "" $nick
    driftFriendship $nick -1
    return 1
  }
}
cMotion_abstract_register "stolens"
cMotion_abstract_batchadd "stolens" { "Hey NO :(%|That's mine%|/sulks at %%" "heeeeyyyy%|:(" "bah!%|/steals it back" "/smacks %%" "hey no, that's *MINE*" "what the?" "Stop! Thief!" }
