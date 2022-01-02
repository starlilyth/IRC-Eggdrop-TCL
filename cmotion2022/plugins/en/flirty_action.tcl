# cMotion flirty action responses

cMotion_plugin_add_action "hug" "^(hugs|snugs|snuggles|huggles|cuddles) %botnicks$" 100 cMotion_plugin_action_hug "en"

proc cMotion_plugin_action_hug { nick host handle channel text } {
  global botnicks
  if [cMotionIsFriend $nick] {
    set nick [cMotionTransformNick $nick $nick $host]
    cMotionGetUnLonely
    cMotionGetHappy
    driftFriendship $nick 1
    cMotionDoAction $channel $nick "%VAR{hugs}"
		return 1
  } else {
    cMotionDoAction $channel $nick "%VAR{thanks}"
		return 1
  }
}

cMotion_plugin_add_action "hops" "^hops (in|on)to %botnicks'?s lap" 100 cMotion_plugin_action_hops "en"

proc cMotion_plugin_action_hops { nick host handle channel text } {
  if {[getFriendshipHandle $user] > 50} {
    cMotionDoAction $channel $nick "%VAR{rarrs}"
    cMotionGetHappy
    cMotionGetUnLonely
    driftFriendship $nick 1
  } else {
    cMotionGetSad
    cMotionGetLonely
    driftFriendship $nick -1
  }
  return 1
}
cMotion_plugin_add_action "rarraction" "(licks|bites|touches|scratches|pets|strokes) %botnicks" 100 cMotion_plugin_action_rarraction "en"
proc cMotion_plugin_action_rarraction { nick host handle channel text } {
  if [cMotionIsFriend $nick] {
    set nick [cMotionTransformNick $nick $nick $host]
    cMotionGetUnLonely
    cMotionGetHappy
    driftFriendship $nick 1
    cMotionDoAction $channel $nick "%VAR{rarrs}"
    return 1
  } else {
    cMotionDoAction $channel $nick "%VAR{thanks}"
	return 1
  }
}

cMotion_plugin_add_action "sleeps" "^(falls asleep|dozes off|snoozes|sleeps) (on|with) %botnicks" 100 cMotion_plugin_action_sleeps "en"

proc cMotion_plugin_action_sleeps { nick host handle channel text } {
  if {[getFriendshipHandle $user] > 50} {
    cMotionDoAction $channel $nick "%VAR{rarrs}"
    cMotionGetHappy
    cMotionGetUnLonely
    driftFriendship $nick 1
  } else {
    frightened $nick $channel
    cMotionGetUnHappy
    driftFriendship $nick -1
  }
  return 1
}

