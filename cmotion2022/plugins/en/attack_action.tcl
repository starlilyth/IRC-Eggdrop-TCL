## cMotion plugin: attack

cMotion_plugin_add_action "attacks" "^attacks (.+) with " 100 cMotion_plugin_action_attack "en"

proc cMotion_plugin_action_attack { nick host handle channel text } {  
  set damage [rand 1500]
  regexp -nocase "^attacks (.+) with (.+)" $text matches who item
  regexp -nocase "(an?|the|some|his|her) (.+)" $item matches blah item
  cMotion_plugins_settings_set "action:attacks" "who" "" "" $who
  cMotion_plugins_settings_set "action:attacks" "item" "" "" $item
  cMotion_plugins_settings_set "action:attacks" "score" "" "" $damage
  cMotionDoAction $channel $nick "%VAR{attack_responses}"
  return 1
}

cMotion_abstract_register "attack_responses"
cMotion_abstract_batchadd "attack_responses" {
  "%% attacks %SETTING{action:attacks:who:_:_} with '%SETTING{action:attacks:item:_:_}' for %SETTING{action:attacks:score:_:_} damage."
  "%SETTING{action:attacks:who:_:_} takes %SETTING{action:attacks:score:_:_} damage from %OWNER{%%} '%SETTING{action:attacks:item:_:_}'"
  "%SETTING{action:attacks:who:_:_} is seriously damaged by the %SETTING{action:attacks:item:_:_} and takes %SETTING{action:attacks:score:_:_} damage!"
  "MISS!"
  "%SETTING{action:attacks:who:_:_} is immune to '%SETTING{action:attacks:item:_:_}'"
  "%SETTING{action:attacks:who:_:_} absorbs the damage and gains %SETTING{action:attacks:score:_:_} HP!"
}
