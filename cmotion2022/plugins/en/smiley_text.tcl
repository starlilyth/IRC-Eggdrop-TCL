# cMotion text plugin: smiley

cMotion_plugin_add_text "smiley1"  {^[;:=]-?[)D>]$} 40 cMotion_plugin_text_smiley "all"
cMotion_plugin_add_text "smiley2" {^([\-^])_*[\-^];*$} 40 cMotion_plugin_text_smiley "all"
cMotion_plugin_add_text "hehsmiley" {^heh(ehe?)*$} 30 cMotion_plugin_text_smiley "all"
cMotion_plugin_add_text "lolsmiley" {^lol(olo?)*$} 30 cMotion_plugin_text_smiley "all"
cMotion_plugin_add_text "smileyAtbot1" {^%botnicks,? [;:=]-?[)D>]$} 80 cMotion_plugin_text_smiley "all"
cMotion_plugin_add_text "smileyAtbot2" {^%botnicks,? ([\-^])_*[\-^];*$} 80 cMotion_plugin_text_smiley "all"

proc cMotion_plugin_text_smiley { nick host handle channel text } {
  global cMotionCache mood
  if {$cMotionCache(lastPlugin) == "cMotion_plugin_text_smiley"} {
    return 0
  }
  if {$mood(happy) < 0} {
    return 0
  }
  cMotionDoAction $channel $nick "%VAR{smiles}"
  cMotionGetHappy
  cMotionGetUnLonely
  return 1
}
