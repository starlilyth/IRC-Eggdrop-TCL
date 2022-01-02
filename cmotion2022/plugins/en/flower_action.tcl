# for a bot named Flower :) 

cMotion_plugin_add_action "waters" "(waters|fertilizes|weeds|mulches|feeds) %botnicks" 100 cMotion_plugin_action_waters "en"
proc cMotion_plugin_action_waters { nick host handle channel text } {
    cMotionDoAction $channel $nick "%VAR{waters}"
    cMotionGetHappy
    cMotionGetUnLonely
    driftFriendship $nick 1
    return 1
}

cMotion_abstract_register "waters"
cMotion_abstract_batchadd "waters" {
  "/grows"
  "/thrives"
  "/blooms"
  "/pollinates"
}

cMotion_plugin_add_action "smells" "(smells|sniffs|admires) %botnicks" 100 cMotion_plugin_action_smells "en"
proc cMotion_plugin_action_smells { nick host handle channel text } {
    cMotionDoAction $channel $nick "%VAR{smiles}"
    cMotionGetHappy
    cMotionGetUnLonely
    driftFriendship $nick 1
    return 1
}

cMotion_plugin_add_action "picks" "(picks|cuts|prunes|digs up|stomps) %botnicks" 100 cMotion_plugin_action_picks "en"
proc cMotion_plugin_action_picks { nick host handle channel text } {
    cMotionDoAction $channel $nick "%VAR{frightens}"
    cMotionGetSad
    driftFriendship $nick -1
    return 1
}
