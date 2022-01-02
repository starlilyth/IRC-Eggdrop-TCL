## cMotion plugin: waves

cMotion_plugin_add_action "waves" "waves (at|to) %botnicks" 100 cMotion_plugin_action_waves "en"

proc cMotion_plugin_action_waves { nick host handle channel text } {
  set lastGreeted [cMotion_plugins_settings_get "action:wave" "lastGreeted" $channel ""]

  if {$lastGreeted != $handle} {
    cMotionDoAction $channel $nick "/waves back"
    cMotion_plugins_settings_set "action:wave" "lastGreeted" $channel "" $handle
    cMotionGetUnLonely
    driftFriendship $nick 1
  } else {
    if {[rand 2] == 0} {
      cMotionDoAction $channel $nick "%VAR{waveTooMuch}"
    }
  }
  return 1
}

cMotion_abstract_register "waveTooMuch"
cMotion_abstract_batchadd "waveTooMuch" {
  "ookay buhbyenaow"
  "What." 
  "Are you practicing to be the Queen or something?" 
  "..."
}
