## cMotion plugin: away handler
# checks for away messages/actions
cMotion_plugin_add_action "away" "^(is )?away" 40 cMotion_plugin_action_away "en"
cMotion_plugin_add_action "back" "^((is )?back)|has returned|returns" 40 cMotion_plugin_action_back "en"

proc cMotion_plugin_action_away { nick host handle channel text } {
  #check we haven't already done something for this nick
  if {$nick == [cMotion_plugins_settings_get "action:away" "lastnick" $channel ""]} {
    return 2
  }
  #save as newnick because if they do a /me next it'll be their new nick
  cMotion_plugins_settings_set "action:away" "lastnick" $channel "" $nick
  #autoaway
  if [regexp -nocase "(auto( |-)?away|idle)" $text] {
    cMotionDoAction $channel $nick "%VAR{autoAways}"
    return 1
  }
  #work
  if [regexp -nocase "w(o|0|e|3)rk" $text] {
    cMotionDoAction $channel $nick "%VAR{awayWorks}"
    return 1
  }
  #sleep
  if [regexp -nocase "(sleep|sleeping|bed|zzz+)" $text] {
    cMotionDoAction $channel $nick "%VAR{goodnights}"
    if {[getFriendshipHandle $user] > 50} {
      if {[rand 2] == 0} {return 1}
      cMotionDoAction $channel $nick "*hugs*"
    }
    return 1
  }
  #shower
  if [regexp -nocase "(shower|nekkid)" $text] {
    if {[getFriendshipHandle $user] > 50} {
      cMotionDoAction $channel $nick "%VAR{joinins}"
      return 1
    }
  }
  #exam
  if [regexp -nocase "(exam|test)" $text] {
    cMotionDoAction $channel $nick "%VAR{goodlucks}"
    return 1
  }    
  cMotionDoAction $channel $nick "%VAR{cyas}"
  return 1
}

proc cMotion_plugin_action_back { nick host handle channel text } {
  #check we haven't already done something for this nick
  if {$nick == [cMotion_plugins_settings_get "action:returned" "lastnick" $channel ""]} {
    return 2
  }
  #save as newnick because if they do a /me next it'll be their new nick
  cMotion_plugins_settings_set "action:returned" "lastnick" $channel "" $nick
  #let's do some cool stuff
  #if they came back from sleep, it's morning
  if [regexp -nocase "(sleep|regenerating|bed|zzz)" $text] {
    cMotionDoAction $channel $nick "%VAR{goodMornings}"
    return 1
  }
  cMotionDoAction $channel $nick "%VAR{welcomeBacks}"
	cMotion_plugins_settings_set "system:join" "lastgreeted" $channel "" $nick
  return 1
}
# extra abstracts
cMotion_abstract_register "joinins"
cMotion_abstract_batchadd "joinins" { "bathtime!" "/gets %% a towel" "about time!" "/joins %%" ":)" "have fun ;)" }

cMotion_abstract_register "autoAways"
cMotion_abstract_batchadd "autoAways" { "oh, bye then" "okay, we'll have fun without you ;)" "fine, just wander away then" "damnit! I WAS TALKING TO YOU!" "yeah, \"auto away\"" }

