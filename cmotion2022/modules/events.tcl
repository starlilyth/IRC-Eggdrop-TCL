# Event handling
# Event main and event action, and IRC event handlers

### Register our counters 
cMotion_counter_init "events" "textplugins"
cMotion_counter_init "events" "actionplugins"
cMotion_counter_init "events" "lines"

### cMotion_event_main 
proc cMotion_event_main {nick host handle channel text} {
  global cMotionGlobal botnick botnicks cMotionSettings cMotionCache cMotionLastEvent
  if {$cMotionGlobal == 0} {return 0}
  if {![channel get $channel cMotion]} {return 0}
  if {[matchattr $handle b]} {
    set cMotionCache($channel,last) 0
    return 0
  }
  if [regexp -nocase "^!seen" $text] {return 0}	
  set channel [string tolower $channel]
  cMotion_putloglev 4 * "cMotion: entering cMotion_event_main with nick: $nick host: $host handle: $handle chan: $channel text: $text"
  set cMotionOriginalNick $nick
  set cMotionOriginalInput $text
  #filter bold, etc codes out
  catch {
  	set text [stripcodes bcruag $text]
  }
  cMotion_check_botnicks
  #does this look like a paste?
  if [regexp -nocase {^[([]?[0-9]{2}[-:.][0-9]{2}. ?[[<(]?[%@+]?[a-z0-9` ]+[@+%]?. \w+} $text] {return 0}
  ## Update the channel idle tracker 
  set cMotionLastEvent($channel) [clock seconds]
  cMotion_counter_incr "events" "lines"
  #don't let people break us 
  if {![matchattr $handle n]} {
    if [regexp -nocase "%(pronoun|me|noun|colen|percent|VAR|\\|)" $text] {
      regsub -all "%" $text "%percent" text
    }
  }
  regsub -all "\</" $text "%slash" text	
  #If this isn't just a smiley of some kind, trim smilies 
  if {[string length $text] >= ([string length $botnick] + 4)} {
    regsub -all -nocase {[;:=]-?[)D>/]} $text "" text
    regsub -all {([\-^])_*[\-^];*} $text "" text
	regsub -all {\\o/} $text "" text
  }
  set text [string trim $text]
  ## Dump double+ spaces #
  regsub -all "  +" $text " " text
  ## Update the last-talked flag for the join system
  cMotion_plugins_settings_set "system:join" "lasttalk" $channel "" 0
  set cMotionThisText $text
  #if we spoke last, add "$botnick: " if it's not in the line 
  if {![regexp -nocase $botnicks $text] && [cMotion_did_i_speak_last $channel]} {
  	if [regexp {^[^:]+:.+} $text] {
	  #since our nick isn't in the line and they're addressing someone, drop this line
	  return 0
	}
    set text "${botnick}: $text"
  }
  #check for someone breaking the loop of lastSpoke 
  if {[regexp -nocase "(i'm not talking to|not) you" $text] && $cMotionCache($channel,last)} {
    cMotionDoAction $channel $nick "oh"
    set cMotionCache($channel,last) 0
    return 0
  }
  set cMotionCache($channel,last) 0
  #Run the text plugins 
  set response [cMotion_plugin_find_text $text $cMotionSettings(deflang)]
  if {[llength $response] > 0} {
    cMotion_putloglev 1 * "going to run plugins: $response for $nick"
    foreach callback $response {
	  cMotion_putloglev 1 * "cMotion: flood checking $nick for $callback..."
      if [cMotion_flood_check $nick] { return 0 }
      cMotion_putloglev 1 * "cMotion: `- running callback $callback"
	  set result 0
	  cMotion_counter_incr "events" "textplugins"
	  set result [$callback $nick $host $handle $channel $text]
	  set cMotionCache(lastPlugin) $callback
	  cMotion_plugin_history_add $channel "text" $callback
	  #plugins return 1 if triggered, 2 if without output, 0 otherwise
      if {$result > 0} {
		if {$result == 1} {cMotion_flood_add $nick $callback $text}
        cMotion_putloglev 2 * "cMotion:    `-$callback returned $result, breaking out..."
        break
      }
    }
  }
  #Check for all caps 
  regsub -all {[^A-Za-z]} $text "" textChars
  regsub -all {[a-z]} $textChars "" textLowerChars
  if {(([string length $textChars] > 4) && ([expr [string length $textLowerChars] / [string length $textChars]] > 0.9)) || [regexp ".+!{4,}" $text]} {
    if {[rand 60] >= 55} {
      cMotionDoAction $channel $nick "%VAR{blownAways}"
      return 0
    }
  }
  #shut up 
  if [regexp -nocase "^${botnicks}:?,? (silence|shut up|be quiet|go away)" $text] {
    driftFriendship $nick -10
    cMotionSilence $nick $host $channel
    return 0
  }
  if [regexp -nocase "(silence|shut up|be quiet|go away),?;? ${botnicks}" $text] {
    driftFriendship $nick -10
    cMotionSilence $nick $host $channel
    return 0
  }
  #If the text is "*blah*" reinject it into cMotion as an action ##
  if [regexp {^\*(.+)\*$} $text blah action] {
    cMotion_putloglev 1 * "Unhandled *$action* by $nick in $channel... redirecting to action handler"
    cMotion_event_action $nick $host $handle $channel "" $action
    return 0
  }
}
### cMotion_event_action 
proc cMotion_event_action {nick host handle dest keyword text} {
  global cMotionGlobal cMotionSettings
  if {$cMotionGlobal == 0} {return 0}
  if {[matchattr $handle b]} {return 0}
  set dest [channame2dname $dest]
  set channel $dest
  if {![channel get $channel cMotion]} {return 0}
  cMotion_putloglev 4 * "cMotion: entering cMotion_event_action with $nick $host $handle $dest $keyword $text"
  set nick [cMotion_cleanNick $nick $handle]
  set text [string trim $text]
  ## Dump double+ spaces ##
  regsub -all "  +" $text " " text
  cMotion_check_botnicks
  #Run the action plugins 
  set response [cMotion_plugin_find_action $text $cMotionSettings(deflang)]
  if {[llength $response] > 0} {
    cMotion_putloglev 1 * "going to run action plugins: $response"
    foreach callback $response {
	  cMotion_putloglev 1 * "cMotion: doing flood for $callback..."
      if [cMotion_flood_check $nick] { return 0 }
      cMotion_putloglev 1 * "cMotion: matched action plugin, running callback $callback"
	  set result 0
	  cMotion_counter_incr "events" "actionplugins"
      set result [$callback $nick $host $handle $channel $text]
	  cMotion_plugin_history_add $channel "action" $callback
      if {$result > 0} {
		if {$result == 1} {cMotion_flood_add $nick $callback $text}
        cMotion_putloglev 2 * "cMotion:    `-$callback returned $result, breaking out..."
        break
      }
    }
    return 0
  }
}

# IRC Event handlers
### cMotionDoEventResponse 
proc cMotionDoEventResponse { type nick host handle channel text } {
  global cMotionGlobal cMotionSettings cMotionCache
  if {$cMotionGlobal == 0} {return 0}
  set channel [string tolower $channel]
  if [matchattr $handle b] {
    set cMotionCache($channel,last) 0
    return 0
  }
  cMotion_putloglev 4 * "entering cMotionDoEventResponse: $type $nick $host $handle $channel $text"
  if { ![regexp -nocase "nick|join|quit|part|split" $type] } {return 0}
  set response [cMotion_plugin_find_irc_event $text $type $cMotionSettings(deflang)]
  if {[llength $response] > 0} {
    foreach callback $response {
	  cMotion_putloglev 2 * "adding flood for callback $callback"
	  cMotion_flood_add $nick $callback $text
      if [cMotion_flood_check $nick] { return 0 }
      cMotion_putloglev 1 * "cMotion: matched irc event plugin, running callback $callback"
      set result [$callback $nick $host $handle $channel $text ]
	  cMotion_putloglev 2 * "returned from callback $callback"
      if {$result == 1} {
        cMotion_putloglev 2 * "cMotion: $callback returned 1, breaking out..."
        break
      }
      return 1
    }
    return 0
  }
  return 0
}

### cMotion_event_onjoin 
proc cMotion_event_onjoin {nick host handle channel} {
  if {![channel get $channel cMotion]} {return 0}
  if [isbotnick $nick] {return 0}
  if [matchattr $handle b] {return 0}
  set result [cMotionDoEventResponse "join" $nick $host $handle $channel ""]
}

### cMotion_event_onpart 
proc cMotion_event_onpart {nick host handle channel {msg ""}} {
  global cMotionGlobal
  if {$cMotionGlobal == 0} {return 0}
  if {![channel get $channel cMotion]} {return 0}
  cMotion_putloglev 3 * "entering cMotion_event_onpart: $nick $host $handle $channel $msg"
  cMotion_plugins_settings_set "system" "lastleft" $channel "" $nick
  #TODO: Fix this? Passing a cleaned nick around can break things
  set nick [cMotion_cleanNick $nick $handle]
  set result [cMotionDoEventResponse "part" $nick $host $handle $channel $msg]
}

### cMotion_event_onquit 
proc cMotion_event_onquit {nick host handle channel reason} {
  global cMotionGlobal
  if {$cMotionGlobal == 0} {return 0}
  if {![channel get $channel cMotion]} {return 0}
  set nick [cMotion_cleanNick $nick $handle]
  cMotion_plugins_settings_set "system" "lastleft" $channel "" $nick
  set result [cMotionDoEventResponse "quit" $nick $host $handle $channel $reason ]
}

### cMotion_event_mode 
proc cMotion_event_mode {nick host handle channel mode victim} {
  global cMotionGlobal botnick
  if {$cMotionGlobal == 0} {return 0}
  if {![channel get $channel cMotion]} {return 0}
  if {$victim != $botnick} {return 0}
  cMotion_putloglev 4 * "cMotion: entering cMotion_event_mode with $nick $host $handle $channel $mode $victim"
  if {$mode == "+o"} {
	if {$nick == ""} {return 0}
    #check to see if i was opped before
    if [wasop $botnick $channel] {return 0}
	cMotionDoAction $channel $nick "%VAR{opped}"
	return 0
  }
  if {$mode == "-o"} {
	if {![wasop $botnick $channel]} {return 0}
	cMotionDoAction $channel $nick "%VAR{deopped}"
	return 0
  }
}

### cMotion_event_nick 
proc cMotion_event_nick { nick host handle channel newnick } {
  global cMotionGlobal
  if {$cMotionGlobal == 0} {return 0}
  if {![channel get $channel cMotion]} {return 0}
  set nick [cMotion_cleanNick $nick $handle]
  set newnick [cMotion_cleanNick $newnick $handle]
  set result [cMotionDoEventResponse "nick" $nick $host $handle $channel $newnick ]
}

cMotion_putloglev d * "cMotion: events module loaded"
