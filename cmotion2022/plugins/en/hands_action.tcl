## cMotion action plugin: hands
# TODO: Mood stuff
cMotion_plugin_add_action "hands" "(hands|gives) %botnicks " 100 cMotion_plugin_action_hands "en"
proc cMotion_plugin_action_hands { nick host handle channel text } {
  global botnicks
	if {[regexp -nocase "(hands|gives) $botnicks ((a|an|the|some) )?(.+)" $text bling act bot moo preposition item]} {
	  cMotion_putloglev d * "cMotion: Got handed !$item! by $nick in $channel"
    #Coffee
		if [regexp -nocase "(cup of )?coffee" $item] {
      cMotion_plugin_action_hands_coffee $channel $nick
      return 1
		}
    #hug
    if [regexp -nocase "^hug" $item] {
      if [cMotion_plugin_check_depend "action:hugs"] {
        cMotion_plugin_action_hugs $nick $host $handle $channel ""
        return 1
      }
    }
    # pie
    if [regexp -nocase {\mpie\M} $item] {
      cMotion_plugin_action_hands_pie $channel $nick
      return 1
    }
    #spliff
    if [regexp -nocase "(spliff|joint|bong|pipe|dope|gear|pot)" $item] {
      cMotion_plugin_action_hands_spliff $channel $nick $handle
      return 1
    }
    #catch everything else
    cMotionDoAction $channel $item "%VAR{hand_generic}"    
    #we'll add it to our random things list for this session too
    cMotion_abstract_add "sillyThings" $item
    return 1
  } 
  #end of "hands" handler
}

# supporting functions
if {![info exists got]} {
  set got(coffee,nick) ""
  set got(coffee,channel) ""
}
##### COFFEE
proc cMotion_plugin_action_hands_coffee { channel nick } {
  global got
  set coffeeNick [cMotion_plugins_settings_get "action:hands" "coffee_nick"  "" ""]
  cMotion_putloglev 1 * "cMotion: ...and it's a cup of coffee... mmmmmmm"
  if {$coffeeNick != ""} {
    cMotion_putloglev 1 * "cMotion: But I already have one :/"
    cMotionDoAction $channel $nick "%%: thanks anyway, but I'm already drinking the one $coffeeNick gave me :)"
    return 1
  }
  driftFriendship $nick 2
  cMotionDoAction $channel $nick "%VAR{thanks}"
  cMotionDoAction $channel $nick "mmmmm..."
  cMotionDoAction $channel $nick "/drinks the coffee %VAR{smiles}"
  cMotion_plugins_settings_set "action:hands" "coffee_nick" "" "" $nick
  cMotion_plugins_settings_set "action:hands" "coffee_channel" "" "" $channel
  utimer 45 { cMotion_plugin_action_hands_finishcoffee }
  return 1
}
proc cMotion_plugin_action_hands_finishcoffee { } {
  global mood
  set coffeeChannel [cMotion_plugins_settings_get "action:hands" "coffee_channel" "" ""]
	cMotionDoAction $coffeeChannel "" "/finishes the coffee"
	cMotionDoAction $coffeeChannel "" "mmmm... thanks :)"

  incr mood(happy) 1

	cMotion_plugins_settings_set "action:hands" "coffee_nick" "" "" ""
}
proc cMotion_plugin_action_hands_pie { channel nick } {
  driftFriendship $nick 1
  cMotion_putloglev 1 * "cMotion: ah ha, pie :D"
  cMotionGetHappy
  cMotionGetUnLonely
  cMotionDoAction $channel $nick ":D%|thanks %%%|/eats pie"
  return 0
}
##### SPLIFF
proc cMotion_plugin_action_hands_spliff { channel nick handle } {
  global mood
  driftFriendship $nick 1
  cMotion_putloglev 1 * "cMotion: ... and it's mind-altering drugs! WOOHOO!"
  cMotion_putloglev 1 * "cMotion: ...... wheeeeeeeeeeeeeeeeeeeeeeeeeeeeeee...."
  incr mood(stoned) 2
  checkmood $nick $channel
  cMotionDoAction $channel $nick "%VAR{smokes}"
  return 0
}
cMotion_abstract_register "smokes"
cMotion_abstract_batchadd "smokes" { "/takes a hit" "/burns" "/has a puff" "/smokes with %%" "/partakes of herbal refreshment" }
# abstracts
cMotion_abstract_register "hand_generic"
cMotion_abstract_batchadd "hand_generic" {
  "%VAR{thanks}"
  "%REPEAT{3:6:m} %%"
  "Do I want this?"
  "Just what I've always wanted %VAR{smiles}"
}
