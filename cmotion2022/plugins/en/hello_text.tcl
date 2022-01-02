## cMotion text plugin: hello "^${botnicks}(!\+!@#\$%^&*{3,})"

cMotion_plugin_add_text "hello" "^(hey|hi|hello|r|greetings|hullo|bonjour|morning|afternoon|evening|yo|y0) %botnicks$" 100 cMotion_plugin_text_hello "en"
cMotion_plugin_add_text "hello2" "^%botnicks(!+|\[!\$%^&*()#\]{3,})" 100 cMotion_plugin_text_hello "en"

proc cMotion_plugin_text_hello { nick host handle channel text } {
  global botnicks
  set exclaim ""
  regexp -nocase "^%botnicks(!+|\[!\$%^&*()#\]{3,})" $text bling pop exclaim
  global cMotionInfo 
  set lastGreeted [cMotion_plugins_settings_get "text:hello" "lastGreeted" $channel ""]
  if {$cMotionInfo(away) == 1} {
    putserv "AWAY"
    set cMotionInfo(away) 0
    set cMotionInfo(silence) 0
    cMotionDoAction $channel $nick "/returns"
  }
  driftFriendship $handle 3
  #check if this nick has already been greeted
  if {$lastGreeted == $handle} {
    cMotionDoAction $channel $nick "%VAR{smiles}"
    return 1
  }
  cMotion_plugins_settings_set "text:hello" "lastGreeted" $channel "" $handle
  if {[string length $exclaim] >= 3} {
    set greeting "%%%colen"
  } else {
    if {[getFriendship $nick] > 60} {
      set greeting "%VAR{hello_familiars}"
    } else {
      set greeting "%VAR{greetings}"
    }
  }
  cMotionDoAction $channel $nick $greeting
  return 1
}

cMotion_abstract_register "hello_familiars"
cMotion_abstract_batchadd "hello_familiars" {
  "%%%colen"
  "%%!"
  "%% :D"
  "%% :)"
  "/hugs %%"
  "%VAR{smiles}"
}
