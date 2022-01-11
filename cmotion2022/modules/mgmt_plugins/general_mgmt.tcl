# cMotion admin plugins
#                        name   regexp               flags   callback					lang 	
cMotion_plugin_add_mgmt "status" "^(status|info)"     t       cMotion_plugin_mgmt_status "any"
cMotion_plugin_add_mgmt "queue" "^queue"            n       cMotion_plugin_mgmt_queue "any"
cMotion_plugin_add_mgmt "parse" "^parse"            n       cMotion_plugin_mgmt_parse "any"
cMotion_plugin_add_mgmt "rehash" "^rehash"          n       cMotion_plugin_mgmt_rehash "any"
cMotion_plugin_add_mgmt "reload" "^reload"          n       cMotion_plugin_mgmt_reload "any"
cMotion_plugin_add_mgmt "settings" "^settings" n cMotion_plugin_mgmt_settings "any"
cMotion_plugin_add_mgmt "global" "^global" n cMotion_plugin_mgmt_global "any"
cMotion_plugin_add_mgmt "help" "^help"     t       "cMotion_plugin_mgmt_help" "any"
cMotion_plugin_add_mgmt "version" "^version" n "cMotion_plugin_mgmt_version"

#################################################################################################################################
# Declare plugin functions
proc cMotion_plugin_mgmt_status { handle { args "" } } {
  global botnicks cMotionSettings cMotionVersion cMotionChannels botnick
	cMotion_update_chanlist 
	cMotion_check_botnicks
	cMotion_putadmin "I AM $botnick! I'm powered by cMotion $cMotionVersion and I'm $cMotionSettings(gender)."
    cMotion_putadmin "My botnicks are currently /$botnicks/. I'm active on: $cMotionChannels"
	if {[cMotion_setting_get "sleepy"]} {
		switch $cMotionSettings(asleep) {
			0 {
				cMotion_putadmin "I'm currently awake and my next bedtime is [clock format $cMotionSettings(sleepy_nextchange)]."
			}
			1 {
				cMotion_putadmin "I'm currently in my pajamas."
			}
			2 {
				cMotion_putadmin "I'm actually asleep right now. My alarm's set for [clock format $cMotionSettings(sleepy_nextchange)]."
			}
			default {
				cMotion_putadmin "I'm not really sure if I'm awake or what. My current sleep state is $cMotionSettings(asleep) and my next event is [clock format $cMotionSettings(sleepy_nextchange)], although who knows what'll happen then."
			}
		}
	} else {
		cMotion_putadmin "I am impervious to tiredness and never need to sleep."
	}

  cMotion_putadmin "Random stuff happens at least every [cMotion_setting_get minRandomDelay], at most every [cMotion_setting_get maxRandomDelay], and not if channel quiet for more than [cMotion_setting_get maxIdleGap] (mins)"
  if [cMotion_setting_get silence] {
  	cMotion_putadmin "Running silent"
  }
  return 0
}

proc cMotion_plugin_mgmt_queue { handle { args "" }} {
  global cMotion_queue
  if {$args == ""} {
    #display queue
    cMotion_putadmin "Queue size: [cMotion_queue_size] lines"
	  foreach item $cMotion_queue {
	    set sec [lindex $item 0]
	    set target [lindex $item 1]
	    set content [lindex $item 2]
	    cMotion_putadmin "Delay $sec sec, target $target: $content"
    }
    return 0
  }
  if [regexp -nocase "clear|flush|delete|reset" $args] {
    cMotion_putadmin "Flushing queue..."
    cMotion_queue_flush
    return 0
  }
	if {$args == "freeze"} {
		cMotion_putadmin "Freezing queue..."
		cMotion_queue_freeze
		return 0
	}
	if {$args == "thaw"} {
		cMotion_putadmin "Thawing queue..."
		cMotion_queue_thaw
		return 0
	}
	if {$args == "run"} {
		cMotion_putadmin "Running queue..."
		cMotion_queue_run 1
		return 0
	}
}
proc cMotion_plugin_mgmt_parse { handle { arg "" } } {
	if {$arg == ""} {
		cMotion_putadmin "You must supply something to parse"
		return 0
	}
	set output [cMotion_plugins_settings_get "admin" "type" "" ""]
	set target [cMotion_plugins_settings_get "admin" "target" "" ""]
	if {$output == ""} {
		return 0
	}
	if {($output == "dcc") || (![string match "#*" $target])} {
		#command syntax should be:
		# .cMotion parse #channel output
		if [regexp -nocase {(#[^ ]+) (.+)} $arg matches chan parse] {
			cMotionDoAction $chan "somenick" "\[parse\] $parse"
			cMotion_putadmin "Sent '$parse' to $chan"
			return 0
		}
	}
	putlog "Parsing '$arg', requested in $target"
	#we've been requested from a channel
	puthelp $target
	cMotionDoAction $target "somenick" $arg
	return 0
}
proc cMotion_plugin_mgmt_rehash { handle } {
  global cMotion_testing cMotionRoot
  #check we're not going to die
  catch {
    putlog "cMotion: testing new code.."
    cMotion_putloglev d * "cMotion: Testing new code..."
    set cMotion_testing 1
    source "$cMotionRoot/cMotion.tcl"
  } msg
  if {$msg != 0} {
    putlog "cMotion: FATAL: Cannot rehash due to error: $msg"
    cMotion_putadmin "Cannot rehash due to error: $msg"
    return 0
  } else {
    putlog "cMotion: code test passed!"
    cMotion_putloglev d * "cMotion: New code ok, rehashing..."
    cMotion_putadmin "Rehashing..."
    set cMotion_testing 0
    rehash
  }
}

proc cMotion_plugin_mgmt_reload { handle } {
  global cMotion_testing cMotionRoot
  #check we're not going to die
  catch {
    putlog "cMotion: Testing new code.."
    cMotion_putloglev d * "cMotion: testing new code..."
    set cMotion_testing 1
    source "$cMotionRoot/cMotion.tcl"
  } msg
  if {$msg != 0} {
    putlog "cMotion: FATAL: Cannot reload due to error: $msg"
    cMotion_putadmin "Cannot reload due to error: $msg"
    return 0
  } else {
    putlog "cMotion: code test passed!"
    cMotion_putloglev d * "cMotion: New code ok, reloading..."
    cMotion_putadmin "Reloading cMotion..."
    set cMotion_testing 0
    source "$cMotionRoot/cMotion.tcl"
  }
}

proc cMotion_plugin_mgmt_settings { handle { arg "" } } {
  global cMotion_plugins_settings
  if {$arg == "clear"} {
  	if {![info exists cMotion_plugins_settings]} {
    	unset cMotion_plugins_settings
    	set cMotion_plugins_settings(dummy,setting,channel,nick) "dummy"
  	}
  	cMotion_putadmin "Cleared plugins settings array"
  	return 0
  } 
  if {$arg == "list"} {
	set s [array startsearch cMotion_plugins_settings]
  	while {[set key [array nextelement cMotion_plugins_settings $s]] != ""} {
  		cMotion_putadmin "$key = $cMotion_plugins_settings($key)"
    }
  	array donesearch cMotion_plugins_settings $s
  } 
  cMotion_putadmin "usage: settings (list|clear)"
  return 0
}

proc cMotion_plugin_mgmt_global { handle { text "" } } {
  global cMotionGlobal
  if [string match -nocase "off" $text] {
    cMotion_putadmin "globally disabling cMotion"
    set cMotionGlobal 0
    return 0
  }
  if [string match -nocase "on" $text] {
    cMotion_putadmin "globally enabling cMotion"
    set cMotionGlobal 1
    return 0
  }
  if {$cMotionGlobal == 0} {
    cMotion_putadmin "cMotion is currently disabled"
  } else {
    cMotion_putadmin "cMotion is currently enabled"
  }
  cMotion_putadmin "use: global off|on"
  return 0
}

proc cMotion_plugin_mgmt_help { handle { args "" } } {
  global cMotion_plugins_mgmt
  if {$args == ""} {
	  cMotion_putadmin "You can run cMotion commands from DCC with .cmotion COMMAND"
	  cMotion_putadmin "Loaded cMotion mgmt Commands:"
	  set line ""
	  set s [array startsearch cMotion_plugins_mgmt]
# wont sort?
      set s [lsort $s]
	  while {[set key [array nextelement cMotion_plugins_mgmt $s]] != ""} {
	  	if {$key == "dummy"} {
	  		continue
	  	}
	  	append line "$key "
	  	if {[string length $line] > 50} {
	  		cMotion_putadmin "  $line"
	  		set line ""
	  	}
	  }
	  if {$line != ""} {
	  	cMotion_putadmin "  $line"
	  }
	  array donesearch cMotion_plugins_mgmt $s
	  cMotion_putadmin "Help is available for mgmt plugins; run .cmotion help COMMAND"
	  cMotion_putadmin "  for more information."
	  return 0
  } else {
  	switch $args {
  		"status" {
  			cMotion_putadmin "Show a summary of cMotion's status."
  		}
  		"global" {
  			cMotion_putadmin "Switch cMotion on and off everywhere:"
  			cMotion_putadmin "  .cMotion global off"
  			cMotion_putadmin "    disable cMotion"
  			cMotion_putadmin "  .cMotion global on"
  			cMotion_putadmin "    enable cMotion"
  		}
  		"reload" {
  			cMotion_putadmin "Reload cMotion without rehashing bot. Will be quicker than rehashing"
  			cMotion_putadmin "but will generate ALERTs which you should ignore."
  		}
  		"rehash" {
  			cMotion_putadmin "Safely rehash the bot. cMotion will check to make sure there are no"
  			cMotion_putadmin "problems with loading the script and then rehash."
  		}
  		"settings" {
  			cMotion_putadmin "Handles internal cMotion settings (not configuration)"
  			cMotion_putadmin "  .cMotion settings list"
  			cMotion_putadmin "    List all settings stored by cMotion. This can be a lot of output."
  			cMotion_putadmin "  .cMotion settings clear"
  			cMotion_putadmin "    Clears the settings array."
  		}
  		"queue" {
  			cMotion_putadmin "Interact with the cMotion queue"
  			cMotion_putadmin "  .cMotion queue"
  			cMotion_putadmin "    List the contents of cMotion's output queue"
  			cMotion_putadmin "  .cMotion queue flush"
  			cMotion_putadmin "    Clear the cMotion output queue"
  		}
  		"parse" {
  			cMotion_putadmin "Make cMotion parse some text as a test"
  			cMotion_putadmin "  .cMotion parse \[<channel>\] <text>"
  			cMotion_putadmin "    If this command is issued from a query or the partyline,"
  			cMotion_putadmin "    you must give the channel to send output to. Requests from"
  			cMotion_putadmin "    a query or the partyline have '\[parse\]' prefixed."
  		}
   		default {
   			#no pre-defined help, see if there's a callback for it
   			set callback [cMotion_plugin_find_mgmt_help $args]
   			if {$callback != ""} {
   				set result [$callback]
   			} else {
  				cMotion_putadmin "I seem to have misplaced my help for that command."
  			}
  		}
  	}
  	return 0
  }
}
proc cMotion_plugin_mgmt_version { handle { arg "" } } {
  global cMotionVersion
	cMotion_putadmin "cMotion $cMotionVersion"
  return 0
}
