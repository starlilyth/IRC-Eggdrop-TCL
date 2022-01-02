# cMotion general actions
#                         name  regexp            %   responses

cMotion_plugin_add_action "moos" "^(goes |does a )?moo+s?( at %botnicks)?" 50 cMotion_plugin_action_moo "en"
cMotion_plugin_add_text "moo" "^mooo*(!*)?$" 40 cMotion_plugin_action_moo "en"

cMotion_abstract_register "moos"
cMotion_abstract_batchadd "moos" { "moo" "MOO!" "/moos quietly" "/moos back to %%" "M%REPEAT{2:8:o}%REPEAT{2:8:O}%REPEAT{2:8:0}%REPEAT{2:8:o}%REPEAT{2:8:0}%REPEAT{2:8:o}!" "ahhh moo" "moo?" "/goes moo" "quack" "woof" "baa" "oink" "You mooing at me?" "MOo" "Moooooooweeeeeeeeeehahahahahahahahahaa" "MOO" "moo..." "mo...o" "moo%colen" }

proc cMotion_plugin_action_moo { nick host handle channel text } {
    cMotionDoAction $channel $nick "%VAR{moos}"
    return 1
}

cMotion_plugin_add_action "hides" "^hides behind %botnicks" 90 cMotion_plugin_action_hides "en"
proc cMotion_plugin_action_hides { nick host handle channel text } {
    cMotionDoAction $channel $nick "%VAR{hiddenBehinds}"
    cMotionGetUnLonely
    cMotionGetHappy
    return 1
}
cMotion_abstract_register "hiddenBehinds"
cMotion_abstract_batchadd "hiddenBehinds" {
  "heeeeyyyy"
  "hey, watch it"
  "watch where you are putting your hands"
  "/hides behind %%"
  "/runs for it"
  "/makes a break for it"
  "hey, look over there%|/runs away"
  "its too bad I am transparent today"
  "/points at %% behind them"
}

