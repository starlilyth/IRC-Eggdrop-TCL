# cMotion ASL plugin

cMotion_plugin_add_text "asl" {\ma/?s/?l\??\M} 100 cMotion_plugin_text_asl "en"
  
proc cMotion_plugin_text_asl { nick host handle channel text } {
  if {[cMotionTalkingToMe $text] || [rand 2]} {
    set age [expr [rand 20] + 13]
    global cMotionSettings
    cMotionDoAction $channel $nick "%%: $age/$cMotionSettings(gender)/%VAR{locations}"
    return 1
  }
  return 0
}
cMotion_abstract_register "locations"
cMotion_abstract_batchadd "locations" { 
  "england" 
  "US" 
  "california" 
  "indiana" 
  "the moon" 
  "australia" 
  "holland" 
  "norway" 
  "boston" 
  "russia" 
  "canada" 
  "toronto" 
  "amsterdam" 
  "mars" 
  "los angeles" 
  "london" 
  "new york" 
  "chicago" 
  "mordor" 
  "middle earth" 
}