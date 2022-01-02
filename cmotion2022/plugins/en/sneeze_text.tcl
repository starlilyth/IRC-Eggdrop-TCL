## cMotion simple plugin: sneeze
cMotion_plugin_add_text "sneeze" "^(sneeze(s)?|(w)?atcho{2,6})" 80 cMotion_plugin_text_sneeze "en"

proc cMotion_plugin_text_sneeze { nick host handle channel text } {
  cMotionDoAction $channel $nick "%VAR{blessyous}"
  return 1
}

cMotion_abstract_register "blessyous" {
  "gesuntheit"
  "bless you"
  "Bless you"
  "/hands %% a tissue"
  "e%REPEAT{2:5:w}%|*wipe*"
  "hehe, someone must be talking about you %VAR{smiles}"
  "good thing I bought this haz-mat suit"
  "Rogue bogey!"
  "/ducks"
  "/hides behind %ruser"   
  "Great. Now I'm gonna get a cold %VAR{unsmiles}"
  "Eek. Don't give it to me"
  "%% - I recommend %VAR{sillyThings}"
}

