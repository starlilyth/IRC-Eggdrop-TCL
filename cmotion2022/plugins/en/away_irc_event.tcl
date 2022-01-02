#  cMotion plugin irc_nick_away.tcl 
#  checks if someone has set their nick with an 'away' tag
cMotion_plugin_add_irc_event "returned" "nick" ".*" 10 "cMotion_plugins_nick_returned" "en"
cMotion_plugin_add_irc_event "away" "nick" "(away|sleep|gone|afk|zzz+|bed|w(o|e|3|0)rk)" 10 "cMotion_plugins_nick_away" "en"

#someone's away (fires on every nick change and checks for away)
proc cMotion_plugins_nick_away { nick host handle channel newnick } {
  #check we haven't already done something for this nick
  if {$nick == [cMotion_plugins_settings_get "action:away" "lastnick" $channel ""]} {
    return 0
  }
  #save as newnick because if they do a /me next it'll be their new nick
  cMotion_plugins_settings_set "action:away" "lastnick" $channel "" $newnick
  #work
  if [regexp -nocase "w(o|e|3|0)rk" $newnick] {
    cMotionDoAction $channel $nick "%VAR{awayWorks}"
    return 1
  }
  #sleep
  if [regexp -nocase "(sleep|bed|zzz+)" $newnick] {
    cMotionDoAction $channel $nick "%VAR{goodnights}"
    if {[getFriendshipHandle $user] > 50} {
      if {[rand 2] == 0} {return 0}
      cMotionDoAction $channel $nick "*hugs*"
    }
    return 1
  }
  cMotionDoAction $channel $nick "%VAR{cyas}"
  return 1
}

#someone's returned
proc cMotion_plugins_nick_returned { nick host handle channel newnick } {
  #check we haven't already done something for this nick
  if {$nick == [cMotion_plugins_settings_get "action:returned" "lastnick" $channel ""]} {
    return 0
  }
  #save as newnick because if they do a /me next it'll be their new nick
  cMotion_plugins_settings_set "action:returned" "lastnick" $channel "" $newnick
  if {[regexp -nocase "(away|sleep|gone|afk|zzz+|bed|w(0|e|3|o)rk|school)" $nick] && 
       ![regexp -nocase "(away|sleep|gone|afk|w(0|e|3|o)rk|school)" $newnick]} {   
    cMotion_plugins_settings_set "system" "lastdonefor" $channel "" $nick
    cMotion_plugins_settings_set "system:join" "lastgreeted" $channel "" $newnick
    #if they came back from sleep, it's morning
    if [regexp -nocase "(sleep|bed|zzz+)" $nick] {
      cMotionDoAction $channel $newnick "%VAR{goodMornings}"
      return 1
    }
    cMotionDoAction $channel $newnick "%VAR{welcomeBacks}"
    return 1
  }
  #we didn't match an away nick for their old nick, so let other nick plugins fire
  return 0
}
