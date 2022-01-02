## cMotion Mood and Friendship module
# Mood handling
set mood(happy) 0
set mood(lonely) 0
set mood(stoned) 0
set moodtarget(happy) 0
set moodtarget(lonely) 5
set moodtarget(stoned) 0
## MOOD ROUTINES 
proc cMotionGetHappy {} {
  global mood
  incr mood(happy) 1
  checkmood "" ""
}
proc cMotionGetSad {} {
  global mood
  incr mood(happy) -1
  checkmood "" ""
}
proc cMotionGetLonely {} {
  global mood
  incr mood(lonely) 1
  checkmood "" ""
}
proc cMotionGetUnLonely {} {
  global mood
  incr mood(lonely) -1
  checkmood "" ""
}

#MOVED FROM EVENTS_SUPPORT
proc frightened {nick channel} {
	global mood
	cMotionDoAction $channel $nick "%VAR{frightens} %VAR{unsmiles}"
	incr mood(lonely) -1
	incr mood(happy) -1
}
#---

## Checkmood: checks the moods are within limits
proc checkmood {nick channel} {
  global mood
  foreach r {happy lonely stoned} {
    if {$r < -30} {
      set mood($r) -30
      cMotion_putloglev d * "cMotion: Mood($r) went OOB, resetting to -30"
    }
    if {$mood($r) > 30} {
      cMotion_putloglev d * "cMotion: Mood($r) went OOB, resetting to 30"
      set mood($r) 30
    }
  }
}

## Driftmood: Drifts all moods towards 0
proc driftmood {} {
  set driftSummary ""
  global mood moodtarget
  foreach r {happy lonely stoned} {
    set drift 0
    set driftString ""
    if {$mood($r) > $moodtarget($r)} {
      set drift -1
      set driftString "$moodtarget($r)<$mood($r)"
    }
    if {$mood($r) < $moodtarget($r)} {
      set drift 2
      set driftString "$mood($r)>$moodtarget($r)"
    }
    if {$drift != 0} {
      set mood($r) [expr $mood($r) + $drift]
      set driftSummary "$driftSummary $r ($driftString) "
    }
  }
  if {$driftSummary != ""} {
    cMotion_putloglev d * "cMotion: driftMood $driftSummary"
  }
  checkmood "" ""
  set mooddrifttimer 1
  timer 10 driftmood
  return 0
}

## moodTimerStart: Used to start the mood drift timer when the script initialises
## and other timers now, too
proc moodTimerStart {} {
  global mooddrifttimer
	if  {![info exists mooddrifttimer]} {
		timer 10 driftmood
		timer [expr [rand 30] + 3] doRandomStuff
		set mooddrifttimer 1
	}
}

# friendship handler
proc getFriendship { nick } {
  if {![validuser $nick]} {
    set handle [nick2hand $nick]
    if {($handle == "*") || ($handle == "")} {
      cMotion_putloglev 1 * "cMotion: couldn't find a handle for $nick to get friendship."
      return 50
    }
  } else {set handle $nick}
  set friendship 50
  if {$handle != "*"} {
    set friendship [getuser $handle XTRA friend]
    if {$friendship == ""} {
      setFriendship $nick 50  
      set friendship 50
    }
  }
  return $friendship
}

proc getFriendshipHandle { handle } {
  set friendship 50
  set friendship [getuser $handle XTRA friend]
  if {$friendship == ""} {
    setFriendship $handle 50  
    set friendship 50
  }
  return $friendship
}

proc setFriendshipHandle { handle friendship } {
  if {$friendship > 100} {
    cMotion_putloglev 2 * "cMotion: friendship for $nick went over 100, capping back to 90"
    set friendship 90
  }
  if {$friendship < 1} {
    cMotion_putloglev 2 * "cMotion: friendship for $nick went under 1, capping back to 10"
    set friendship 10
  }
  setuser $handle XTRA friend $friendship
}

proc setFriendship { nick friendship } {
  cMotion_putloglev 4 * "setFriendship: nick = $nick, friendship = $friendship"
  set handle [nick2hand $nick]
  if {($handle == "*") || ($handle == "")} {
    #perhaps it was already a handle
    if {![validuser $nick]} {
      cMotion_putloglev 1 * "cMotion: couldn't find a handle for $nick to set friendship."
      return 50
    }
    set handle $nick
  }
  if {$friendship > 100} {
    cMotion_putloglev 2 * "cMotion: friendship for $nick went over 100, capping back to 9"
    set friendship 99
  }
  if {$friendship < 0} {
    cMotion_putloglev 2 * "cMotion: friendship for $nick went under 0, capping back to 1"
    set friendship 1
  }
 catch {
    setuser $handle XTRA friend $friendship
  }
}

proc driftFriendship { nick drift } {
  cMotion_putloglev 4 * "driftFriendship: nick = $nick, drift = $drift"
  set handle [nick2hand $nick]
  if {($handle == "*") || ($handle == "")} {
    cMotion_putloglev 1 * "cMotion: couldn't find a handle for $nick to drift friendship."
    return 50
  }
  set friendship [getFriendship $handle]
  incr friendship $drift
  setFriendship $nick $friendship
  cMotion_putloglev 2 * "cMotion: drifting friendship for $nick by $drift, now $friendship"
  return $friendship
}

proc getFriendsList { } {
  set users [userlist]
  set r ""
  set best(name) ""
  set best(val) 0
  set worst(name) ""
  set worst(val) 100
  foreach user $users {
    set f [getuser $user XTRA friend]
    if {$f != ""} {
      append r "$user:$f "
    }
    if {$f > $best(val)} {
      set best(val) $f
      set best(name) $user
    }
    if {($f < $worst(val)) && ($f > 0)} {
      set worst(val) $f
      set worst(name) $user
    }
  }
  set r "Best friend: $best(name), worst friend: $worst(name). $r"
  return $r
}

proc cMotionIsFriend { nick } {
  set friendship [getFriendship $nick]
  cMotion_putloglev 2 * "cMotion: friendship for $nick is $friendship"
  if {$friendship < 35} {
    return 0
  }
  return 1
}    

proc cMotion_friendship_tick { min hr a b c } {
  cMotion_putloglev 3 * "cMotion_friendship_tick"
  cMotion_putloglev d * "friendship tick"
  set users [userlist]
  foreach user $users {
    set f [getuser $user XTRA friend]
    if {$f != ""} {
      cMotion_putloglev 4 * "$user is $f"
      if {$f > 60} {
        setuser $user XTRA friend [expr $f - 1]
      }
      if {$f < 40} {
        setuser $user XTRA friend [expr $f + 1]
      }
    }
  }
}

bind time - "00 * * * *" cMotion_friendship_tick


cMotion_putloglev d * "cMotion: emotions module loaded"
