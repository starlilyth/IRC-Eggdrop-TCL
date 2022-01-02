## cMotion plugin: xmas

cMotion_plugin_add_text "xmas" "(merry|happy|have a good) (xmas|christmas|chrismas|newyear|new year) %botnicks" 100 cMotion_plugin_text_xmas "en"

proc cMotion_plugin_text_xmas { nick host handle channel text } {
  cMotionGetHappy
  cMotionGetUnLonely
  cMotionDoAction $channel $nick "merry christmas and happy new year %% %VAR{smiles}"
  driftFriendship $nick 3
  return 1
}
