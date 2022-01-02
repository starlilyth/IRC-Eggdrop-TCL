## cMotion plugin: activate

cMotion_plugin_add_action "z-activate" "%botnicks:?,? (enable|activate|increase power to)" 100 cMotion_plugin_action_activate "en"

proc cMotion_plugin_action_activate { nick host handle channel text } {
  global botnicks
  if [regexp -nocase "(enable|activate|increase power to) (.+)$" $text matches verb item] {
      set item [string trim $item]
      cMotionDoAction $channel $item "%VAR{activateses}"
  }
}

cMotion_abstract_register "activateses"
cMotion_abstract_batchadd "activateses" {
  "/increases power to %%"
  "/brings %% online"
  "%% engaged%colen"
  "/activates %%"
  "%% to maximum%colen"
}
