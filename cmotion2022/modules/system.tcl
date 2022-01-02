# System functions

### init our counters 
cMotion_counter_init "system" "randomstuff"

### Set up the binds 
bind join - *!*@* cMotion_event_onjoin
bind mode - * cMotion_event_mode
bind pubm - * cMotion_event_main
bind sign - * cMotion_event_onquit
bind nick - * cMotion_event_nick
bind part - * cMotion_event_onpart
bind ctcp - ACTION cMotion_event_action

bind dcc m cMotion* cMotion_dcc_command

#bedtime
bind time - "* * * * *" cMotion_check_tired

### cMotion_update_chanlist 
# rebuilds our channel list based on which channels are +cMotion
proc cMotion_update_chanlist { } {
	global cMotionChannels
	set cMotionChannels [list]
	foreach chan [channels] {
		if {[channel get $chan cMotion]} {
			lappend cMotionChannels $chan
		}
	}
}

### Initalise some variables per channel 
cMotion_update_chanlist
foreach chan $cMotionChannels {
  set cMotionLastEvent($chan) [clock seconds]
  set cMotionInfo(adminSilence,$chan) 0
  #set to 1 when the bot says something, and 0 when someone else says something
  #used to make the bot a bit more intelligent (perhaps) at conversations
  set cMotionCache($chan,last) 0
  #channel mood tracker
  set cMotionCache($chan,mood) 0
}

### cMotion_dcc_command 
proc cMotion_dcc_command { handle idx arg } {
  global cMotionSettings
  set cmd $arg
  cMotion_plugins_settings_set "mgmt" "type" "" "" "dcc"
  cMotion_plugins_settings_set "mgmt" "idx" "" "" $idx
  set nfo [cMotion_plugin_find_mgmt $cmd]
  if {$nfo == ""} {
    cMotion_putadmin "what"
    return 1
  }
  set blah [split $nfo "¦"]
  set flags [lindex $blah 0]
  set callback [lindex $blah 1]
  if {![matchattr $handle $flags]} {
    cMotion_putadmin "What? You need more flags :)"
    return 1
  }
  cMotion_putloglev d * "cMotion: mgmt callback matched, calling $callback"
  #strip the first command
  regexp {[^ ]+( .+)?} $cmd {\1} arg
  #run the callback :)
  set arg [join $arg]
  set arg [string trim $arg]
  catch {
    if {$arg == ""} {
      $callback $handle
    } else {
      $callback $handle $arg
    }
  } err
  if {($err != "") && ($err != 0)} {
    putlog "cMotion: ALERT! Callback failed for !cMotion: $callback: $err"
  } else {
    return 0
  }
  cMotion_putloglev 2 * "cMotion: mgmt command $arg from $handle"
  set info [cMotion_plugin_find_mgmt $arg $cMotionSettings(deflang)]
  if {$info == ""} {
    putidx $idx "Unknown command (or error). Try .cMotion help"
    return 1
  }
  set blah [split $info "¦"]
  set flags [lindex $blah 0]
  set callback [lindex $blah 1]
  if {![matchattr $handle $flags]} {
    putidx $idx "What? You need more flags :)"
    return 1
  }
  cMotion_putloglev d * "cMotion: mgmt callback matched, calling $callback"
  #strip the first command
  regexp {[^ ]+( .+)?} $arg {\1} arg
  #run the callback :)
  set arg [join $arg]
  set arg [string trim $arg]
  catch {
    if {$arg == ""} {
      $callback $handle $idx
    } else {
      $callback $handle $idx $arg
    }
  } err
  if {($err != "") && ($err != 0)} {
    putlog "cMotion: ALERT! Callback failed for .bmadmin: $callback ($handle $idx $arg)"
    putidx $idx "Sorry :( Running your callback failed ($err)\r"
  }
}
### cMotion_putadmin 
proc cMotion_putadmin { text } {
  set output [cMotion_plugins_settings_get "mgmt" "type" "" ""]
  if {$output == "dcc"} {
    set idx [cMotion_plugins_settings_get "mgmt" "idx" "" ""]
    putidx $idx $text
    return 0
  }
  return 0}

### cMotionStats 
proc cMotionStats {nick host handle channel text} {
  global botnick 
  if {(![regexp -nocase $botnick $text])} { return 0 }
  global cMotion_abstract_contents cMotion_abstract_timestamps cMotion_abstract_max_age
  global cMotion_abstract_ondisk
  set mem [llength [array names cMotion_abstract_contents]]
  set disk [llength $cMotion_abstract_ondisk]
  set faults [cMotion_counter_get "abstracts" "faults"]
  set pageouts [cMotion_counter_get "abstracts" "pageouts"]
  global cMotionFacts
  set items [lsort [array names cMotionFacts]]
  set itemcount 0
  set factcount 0
  foreach item $items {
    incr itemcount
    incr factcount [llength $cMotionFacts($item)]
  }
  putchan $channel "abstracts: [expr $mem + $disk] total, $mem loaded, $disk on disk, $faults faults, $pageouts pageouts. [cMotion_counter_get abstracts gc] garbage collections, [cMotion_counter_get abstracts gets] fetches"
  putchan $channel "facts: $factcount facts about $itemcount items"
  putchan $channel "plugins fired: text [cMotion_counter_get events textplugins], action [cMotion_counter_get events actionplugins]"
  putchan $channel "output: lines sent to output: [cMotion_counter_get output lines], lines sent to irc: [cMotion_counter_get output irclines]"
  putchan $channel "system: randomness: [cMotion_counter_get system randomstuff]"
  putchan $channel "flood: checks: [cMotion_counter_get flood checks]"
}

# check if a channel is active enough for randomy things
proc cMotion_is_active_enough { channel } {
  global cMotionSettings cMotionLastEvent 
	cMotion_putloglev 4 * "cMotion_is_active_enough $channel"
	set last_event 0
	catch {
		set last_event $cMotionLastEvent($channel)
	}
	if {$last_event == 0} {
		cMotion_putloglev d * "last event info for $channel not available"
		# assume we're ok
		return 1
	}
	cMotion_putloglev 3 * "last event for $channel was $last_event"
  if {([clock seconds] - $last_event) < ([expr $cMotionSettings(maxIdleGap) * 60])} {
		cMotion_putloglev 3 * "it fits!"
    return 1
  }
	return 0
}

### doRandomStuff 
proc doRandomStuff {} {
  global cMotionInfo cMotionSettings cMotion_SLEEP cMotionLastEvent cMotionChannels
  set timeNow [clock seconds]
  set saidChannels [list]
  set silentChannels [list]
  set cMotionOriginalNick ""
  cMotion_update_chanlist
  #do this first now
  set upperLimit [expr $cMotionSettings(maxRandomDelay) - $cMotionSettings(minRandomDelay)]
  if {$upperLimit < 1} {
  	set upperLimit 1
  }
  set temp [expr [rand $upperLimit] + $cMotionSettings(minRandomDelay)]
  timer $temp doRandomStuff
  cMotion_putloglev d * "cMotion: randomStuff next ($temp minutes)"
	# don't bother if we're asleep
	if {$cMotionSettings(asleep) != $cMotion_SLEEP(AWAKE)} {
		cMotion_putloglev d * "not doing randomstuff now, i'm asleep"
		# kill any away status as we don't want to come back from the shops after we've been to bed :P
		set cMotionInfo(away) 0
		return
	}
  #not away
  #find the most recent event
  set mostRecent 0
  set line "comparing idle times: "
  foreach channel $cMotionChannels {
    append line "$channel=$cMotionLastEvent($channel) "
    if {$cMotionLastEvent($channel) > $mostRecent} {
      set mostRecent $cMotionLastEvent($channel)
    }
  }
  cMotion_putloglev 1 * "cMotion: most recent: $mostRecent .. timenow $timeNow .. gap [expr $cMotionSettings(maxIdleGap) * 10]"
  set idleEnough 0
  if {($timeNow - $mostRecent) > ([expr $cMotionSettings(maxIdleGap) * 10])} {
    set idleEnough 1
  }
  #override if we should never go away
  if {$cMotionSettings(useAway) == 0} {
    set idleEnough 0
  }
  if {$idleEnough} {
    if {$cMotionInfo(away) == 1} {
      #away, don't do anything
      return 0
    }
    #channel is quite idle
    if {[rand 4] == 0} {
      putlog "cMotion: All channels are idle, going away"
      cMotionSetRandomAway
      return 0
    }
  }
  #not idle
  #set back if away
  if {$cMotionInfo(away) == 1} {
    cMotionSetRandomBack
  }
  #we didn't set ourselves away, let's do something random
  cMotion_counter_incr "system" "randomstuff"
  foreach channel $cMotionChannels {
    if {(($timeNow - $cMotionLastEvent($channel)) < ($cMotionSettings(maxIdleGap) * 60))} {
      lappend saidChannels $channel
      cMotionSaySomethingRandom $channel
    } else {
      lappend silentChannels $channel
    }
  }
  cMotion_putloglev d * "cMotion: randomStuff said ($saidChannels) silent ($silentChannels)"
}

### cMotionSaySomethingRandom 
proc cMotionSaySomethingRandom {channel} {
  if {[rand 3] == 0} {
    # specific day (holiday)
	set today [clock format [clock seconds] -format "randomStuff_%m_%d"]
	if [cMotion_abstract_exists $today] {
	  cMotion_putloglev d * "using abstract $today for randomstuff in $channel"
	  cMotionDoAction $channel "" "%VAR{$today}"
	  return 0
	} 

    if {[rand 2]} {
		# Day of week
		set today [clock format [clock seconds] -format "randomStuff_%A"]
		if [cMotion_abstract_exists $today] {
			cMotion_putloglev d * "using abstract $today for randomstuff in $channel"
			cMotionDoAction $channel "" "%VAR{$today}"
			return 0
		}	
	} else {
        # Month
		set today [clock format [clock seconds] -format "randomStuff_%B"]
		if [cMotion_abstract_exists $today] {
			cMotion_putloglev d * "using abstract $today for randomstuff in $channel"
			cMotionDoAction $channel "" "%VAR{$today}"
			return 0
		}
	}

  }	else {
		cMotion_putloglev d * "using abstract randomStuff in $channel"
        cMotionDoAction $channel "" "%VAR{randomStuff}"
  }
  return 0
}

### cMotionSetRandomAway 
proc cMotionSetRandomAway {} {
  #set myself away with a random message
  global cMotionInfo cMotionSettings cMotionChannels
  set awayReason [cMotion_abstract_get "randomAways"]
  foreach channel $cMotionChannels {
    if {[lsearch $cMotionSettings(noAwayFor) $channel] == -1} {
      cMotionDoAction $channel $awayReason "/is away: %%"
    }
  }
  putserv "AWAY :$awayReason"
  set cMotionInfo(away) 1
  set cMotionInfo(silence) 1
  cMotion_putloglev d * "cMotion: Set myself away: $awayReason"
  cMotion_putloglev d * "cMotion: Going silent"
}

### cMotionSetRandomBack 
proc cMotionSetRandomBack {} {
  #set myself back
  global cMotionInfo cMotionSettings cMotionChannels
	cMotion_update_chanlist
  set cMotionInfo(away) 0
  set cMotionInfo(silence) 0
  foreach channel $cMotionChannels {
    if {[lsearch $cMotionSettings(noAwayFor) $channel] == -1} {
      cMotionDoAction $channel "" "/is back"
    }
  }
  putserv "AWAY"
  return 0
}

### cMotionTalkingToMe 
proc cMotionTalkingToMe { text } {
  global botnicks
  cMotion_putloglev 2 * "checking $text to see if they're talking to me"
	if [regexp -nocase "^$botnicks\[ :,\]" $text] {
		cMotion_putloglev 2 * "`- yes"	
		return 1
	}
	if [regexp -nocase "$botnicks\[!?~\]*$" $text] {
		cMotion_putloglev 2 * "`- yes"	
		return 1
	}
  cMotion_putloglev 2 * "`- no"
  return 0
}

### cMotionSilence 
# Makes the bot shut up
proc cMotionSilence {nick host channel} {
  global cMotionInfo silenceAways cMotionSettings
  if {$cMotionInfo(silence) == 1} {
    #I already am :P
    putserv "NOTICE $nick :I already am silent :P"
    return 0
  }
  timer $cMotionSettings(silenceTime) cMotionUnSilence
  putlog "cMotion: Was told to be silent for $cMotionSettings(silenceTime) minutes by $nick in $channel"
  cMotionDoAction $channel $nick "%VAR{silenceAways}"
  putserv "AWAY :afk ($nick $channel)"
  set cMotionInfo(silence) 1
  set cMotionInfo(away) 1
}

### cMotionUnSilence 
# Undoes the shut up command
proc cMotionUnSilence {} {
  # Timer for silence expires
  putserv "AWAY"
  putlog "cMotion: No longer silent."
  global cMotionInfo
  set cMotionInfo(silence) 0
  set cMotionInfo(away) 0
}

### getHour 
proc getHour {} {
  return [clock format [clock seconds] -format "%H"]
}

### cMotion_get_number 
proc cMotion_get_number { num } {
	if {$num <= 0} {
		cMotion_putloglev d * "Warning: cMotion_get_number called with invalid parameter: $num"
		return 0
	}
  return [expr [rand $num] + 1]
}

### cMotion_rand_nonzero 
proc cMotion_rand_nonzero { limit } {
	if {$limit <= 0} {return 0}
	incr limit 1
	set result [rand $limit]
	incr limit
	return $limit
}

### cMotion_startTimers 
proc cMotion_startTimers { } {
  global mooddrifttimer
	if  {![info exists mooddrifttimer]} {
	  timer 10 driftmood
      timer [expr [rand 30] + 3] doRandomStuff
	  set mooddrifttimer 1
      set delay [expr [rand 200] + 1700]
	}
}

### cMotion_cleanNick 
proc cMotion_cleanNick { nick { handle "" } } {
  #attempt to clean []s etc out of nicks
  if {![regexp {[\\\[\]\{\}]} $nick]} {return $nick}
  if {($handle == "") || ($handle == "*")} {
    set handle [nick2hand $nick]
  }
  if {($handle != "") && ($handle != "*")} {
    set nick $handle
  }
  #have we STILL got illegal chars?
  if {[regexp {[\\\[\]\{\}]} $nick]} {
    return [string map { \[ "_" \] "_" \{ "_" \} "_" } $nick]
  }
  return $nick
}

### cMotion_uncolen 
# clean out $£(($ off the end
proc cMotion_uncolen { line } {
  regsub -all {([!\"\!\$\%\^\&\*\(\)\#\@]{3,})} $line "" line
  return $line
}

### cMotion_setting_get 
# get a setting out of the two variables that commonly hold them
proc cMotion_setting_get { setting } {
  global cMotionSettings cMotionInfo
  set val ""
  catch {set val $cMotionSettings($setting)}
  if {$val != ""} {return $val}
  cMotion_putloglev 3 * "setting '$setting' doesn't exist in cMotionSettings, trying cMotionInfo..."
  catch {set val $cMotionInfo($setting)}
  if {$val != ""} {return $val}
  cMotion_putloglev 3 * "nope, not there either, returning nothing"
  return ""
}

proc cMotion_check_botnicks { } {
	global botnicks cMotionSettings botnick
	if {$botnicks == ""} {
		set botnicks "($botnick|$cMotionSettings(botnicks)) ?"
	}
}

### Sleepy stuff
proc cMotion_check_tired { a b c d e } {
	global cMotion_SLEEP 
	# check if we're past the time we should be changing
	if {[cMotion_setting_get "sleepy"] != 1} {return 0}
	set limit [cMotion_setting_get "sleepy_nextchange"]
	cMotion_putloglev 4 * "current time = [clock seconds], checking if we're past $limit"
	if {[clock seconds] >= $limit} {
		cMotion_putloglev d * "need to do a sleepy state change"
		set state [cMotion_setting_get "asleep"]
		if {$state == $cMotion_SLEEP(AWAKE)} {
			cMotion_putloglev d * "maybe going to sleep"
			cMotion_go_to_sleep
			return
		}
		if {$state == $cMotion_SLEEP(BEDTIME)} {
			cMotion_putloglev d * "maybe going to sleep"
			cMotion_go_to_sleep
			return
		}
		if {$state == $cMotion_SLEEP(ASLEEP)} {
			cMotion_putloglev d * "maybe going to wake up"
			cMotion_wake_up
			return 
		}
		putlog "Whoops! Tried to do a sleepy state change but I'm not sure if I'm asleep or not :( ($state)"
		return
	}
}
# go to sleep
proc cMotion_go_to_sleep { } {
	global cMotionSettings cMotion_SLEEP cMotionChannels
	cMotion_update_chanlist
	if {$cMotionSettings(asleep) == $cMotion_SLEEP(AWAKE)} {
		cMotion_putloglev 3 * "considering awake -> bedtime"
		if {[rand 10] > 3} {
			# announce we're tired
			set cMotionSettings(asleep) $cMotion_SLEEP(BEDTIME)
			putlog "cMotion: preparing to go to bed"
			foreach chan $cMotionChannels {
				if [cMotion_is_active_enough $chan] {
					cMotion_putloglev 3 * "sending tired output to $chan"
					cMotionDoAction $chan "" "%VAR{tireds}"
				}
			}
			return
		} else {
			cMotion_putloglev d * "tired but not enough to tell anyone yet"
		}
		return
	}
	if {$cMotionSettings(asleep) == $cMotion_SLEEP(BEDTIME)} {
		cMotion_putloglev 3 * "considering bedtime -> sleep"
		if {[rand 10] > 3} {
			set cMotionSettings(asleep) $cMotion_SLEEP(ASLEEP)
			putserv "AWAY :ZzZz"
			# go to sleep
			foreach chan $cMotionChannels {
				if [cMotion_is_active_enough $chan] {
					cMotion_putloglev 3 * "sending sleeping output to $chan"
					cMotionDoAction $chan "" "%VAR{go_sleeps}"
				}
			}
			putlog "cMotion: gone to sleep"
			set hour [cMotion_setting_get "wakeytime_hour"]
			set minute [cMotion_setting_get "wakeytime_minute"]
			set cMotionSettings(sleepy_nextchange) [cMotion_sleep_next_event "$hour:$minute"]
			return
		} else {
			cMotion_putloglev 1 * "not quite tired enough to actually go to sleep yet"
		}
		return
	}
	cMotion_putloglev d * "What th... cMotion_go_to_sleep called but I'm already asleep!"
}
proc cMotion_wake_up { } {
	global cMotionSettings cMotion_SLEEP cMotionChannels
	cMotion_update_chanlist
	if {$cMotionSettings(asleep) == $cMotion_SLEEP(ASLEEP)} {
		cMotion_putloglev 3 * "considering asleep -> awake"
		if {[rand 10] > 7} {
			putlog "cMotion: woke up!"
			set cMotionSettings(asleep) $cMotion_SLEEP(AWAKE)
			putserv "AWAY"
			foreach chan $cMotionChannels {
				# don't check for active enough here, as we're waking everyone up
				# but do check we didn't speak last as that just looks dumb
				if {![cMotion_did_i_speak_last $chan]} {
					cMotion_putloglev 3 * "sending waking output to $chan"
					cMotionDoAction $chan "" "%VAR{wake_ups}"
				}
			}
			set hour [cMotion_setting_get "bedtime_hour"]
			set minute [cMotion_setting_get "bedtime_minute"]
			set cMotionSettings(sleepy_nextchange) [cMotion_sleep_next_event "$hour:$minute"]
			return
		} else {
			cMotion_putloglev d * "just a few more minutes in bed..."
		}
		return
	}
}
proc cMotion_sleep_next_event { when } {
	set now [clock seconds]
	set ts [clock scan $when]
	if {$ts < $now} {
		# oh, add 24h
		incr ts 86400
	}
	cMotion_putloglev d * "sleepy: next state change at $ts = [clock format $ts]"
	return $ts
}
proc cMotion_did_i_speak_last { channel } {
	global cMotionCache
	catch {
		return $cMotionCache($channel,last)
	}
	#assume no
	return 0
}
# on start up, we should be awake and the next transition will be to sleep
if {[cMotion_setting_get "sleepy"] == 1} {
	set cMotionSettings(sleepy_nextchange) [cMotion_sleep_next_event "$cMotionSettings(bedtime_hour):$cMotionSettings(bedtime_minute)"]
}

cMotion_putloglev d * "cMotion: system module loaded"

