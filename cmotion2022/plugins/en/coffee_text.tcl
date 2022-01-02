# the bot loves coffee

cMotion_plugin_add_text "mmmcoffee" "coffee" 40 cMotion_plugin_text_mmmcoffee "en"
proc cMotion_plugin_text_mmmcoffee { nick host handle channel text } {
  cMotionDoAction $channel $nick "%VAR{mmmcoffees}"
  return 1
}
cMotion_abstract_register "mmmcoffees" {
  "I love coffee"
  "/gets a fresh cup"
  "/makes a fresh pot"
  "%VAR{smiles}"
  "mmmcoffee"
  "mmmcoffee %VAR{smiles}"
  "%REPEAT{3:8:m}c%REPEAT{1:4:o}%REPEAT{3:5:f}%REPEAT{3:8:e}"
  "!coffee++"
  "I <3 coffee"
  "coffee is the best thing ever I could drink it all day and I feel great no worries here hehehehehe *snort*"
}

cMotion_plugin_add_text "zzz" "^zzz+" 50 cMotion_plugin_text_zzz "en"
proc cMotion_plugin_text_zzz { nick host handle channel text } {
  cMotionDoAction $channel $nick "%VAR{handcoffees}"
  return 1
}
cMotion_abstract_register "handcoffees" {
  "/hands %% coffee"
  "wake up%colen"
  "go to bed already"
  "sorry, are we keeping you up?"
  "you need coffee"
  "/throws water over %% to wake them up"
  "/gets %% a pillow"
  "/gets %% a blanket"
}
