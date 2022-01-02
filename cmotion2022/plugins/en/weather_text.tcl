## cMotion simple plugin: weather

cMotion_plugin_add_text "weather" "^!w " 10 cMotion_plugin_text_weather "en"

proc cMotion_plugin_text_weather { nick host handle channel text } {
  cMotionDoAction $channel $nick "%VAR{weathers}"
  return 1
}

cMotion_abstract_register "weathers"
cMotion_abstract_batchadd "weathers" {
  "that is some crazy weather!"
  "I love that weather"
  "I don't like that weather"
  "that weather is my favorite"
}

