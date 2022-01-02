cMotion_plugin_add_text "pirate" "(arrr|arrgh|avast|ahoy|matey)" 80 cMotion_plugin_text_pirate "en"

proc cMotion_plugin_text_pirate { nick host handle channel text } {
  cMotionDoAction $channel $nick "%VAR{pirates}"
  return 1
}
cMotion_abstract_register "pirates"
cMotion_abstract_batchadd "pirates" {
  "ARRR"
  "arrr %%"
  "ahoy matey!"
  "ahoy %%!"
  "rrrrr"
  "arrrgh"
  "ahoy me hearties!"
  "aye, we be searchin' for treasure!"
  "oh ho, bucko"
  "/rattles a cutlass at %%"
  "/flies the jolly roger"
  "shiver me timbers!"
  "/stands on the poop deck with a spyglass"
  "Man-o-war on the horizon! Batten the hatches and drop the mizzen, you scallywags!"
}
