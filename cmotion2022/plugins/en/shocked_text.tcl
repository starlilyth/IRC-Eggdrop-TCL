# cMotion shocked.tcl 
cMotion_abstract_register "shocked"
cMotion_abstract_batchadd "shocked" { "!" "!!!" "dewd" "woah" "jeez" "yikes" "wow" "boom" ":O" ":o" "%colen" "O_O" "look out" }

cMotion_plugin_add_text "shocked" "^((((=|:|;)-?(o|0))|(!+))|yikes|what the(.*)?|shit|fuck( it)?|damn( it)?)$" 40 cMotion_plugin_text_shock "en"

proc cMotion_plugin_text_shock { nick host handle channel text } {
  global cMotionCache
  #if we spoke last, it's probable this is a reaction to us
  #being surprised at yourself is lame
  if {$cMotionCache($channel,last)} {
    return 0
  }
  cMotionDoAction $channel $nick "%VAR{shocked}"
  return 1
}

