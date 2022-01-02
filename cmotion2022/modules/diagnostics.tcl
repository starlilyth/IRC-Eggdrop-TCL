# cMotion - Diagnostics
# cMotion_diagnostic_timers 
# make sure we only have one instance of each timer
proc cMotion_diagnostic_timers { } {
	cMotion_putloglev d * "running level 4 diagnostic on timers"
	set alltimers [timers]
	set seentimers [list]
	foreach t $alltimers {
		cMotion_putloglev 1 * "checking timer $t"
		set t_function [lindex $t 1]
		set t_name [lindex $t 2]
		set t_function [string tolower $t_function]
		if {[lsearch $seentimers $t_function] >= 0} {
			cMotion_putloglev d * "cMotion: A level 4 diagnostic has found a duplicate timer $t_name for $t_function ... removing (this is not an error)"
			#remove timer
			killtimer $t_name
		} else {
			#add to seen list
			lappend seentimers $t_function
		}
	}
}

# cMotion_diagnostic_utimers 
# make sure we have only one instance of each utimer
proc cMotion_diagnostic_utimers { } {
	cMotion_putloglev d * "running level 4 diagnostic on utimers"
	set alltimers [utimers]
	set seentimers [list]
	foreach t $alltimers {
		cMotion_putloglev 1 * "checking timer $t"
		set t_function [lindex $t 1]
		set t_name [lindex $t 2]
		set t_function [string tolower $t_function]
		if {[lsearch $seentimers $t_function] >= 0} {
			cMotion_putloglev d * "cMotion: A level 4 diagnostic has found a duplicate utimer $t_name for $t_function ... removing (this is not an error)"
			#remove timer
			killutimer $t_name
		} else {
			#add to seen list
			lappend seentimers $t_function
		}
	}
}

### cMotion_diagnostic_plugins 
# check some plugins loaded
proc cMotion_diagnostic_plugins { } {
	cMotion_putloglev 5 * "cMotion_diagnostic_plugins"
	foreach t {text action mgmt output irc_event} {
		set arrayName "cMotion_plugins_$t"
		upvar #0 $arrayName cheese
		if {[llength [array names cheese]] == 0} {
			putlog "cMotion: diagnostics: No $t plugins loaded, something is wrong!"
		}
	}
}

### cMotion_diagnostic_settings 
# check needed settings are defined
proc cMotion_diagnostic_settings { } {
	global cMotionSettings
	set errors 0
        set slist { "botnicks" "friendly" "gender" "useAway" "noAwayFor"
"typos" "colloq" "noPlugin" "minRandomDelay" "maxRandomDelay" "maxIdleGap" "silenceTime"
"languages" "deflang" "typingSpeed" "disableFloodChecks" "abstractMaxAge"
"abstractMaxNumber" "factsMaxItems" "factsMaxFacts" "sleepy" "bedtime_hour"
"bedtime_minute" "wakeytime_hour" "wakeytime_minute" }
	foreach val $slist {
		if {![info exists cMotionSettings($val)]} {
		  putlog "cMotion: diagnostics: $val not defined, check settings file!"
		  set errors 1
		}
	}
	if {$errors == 1} {
		putlog "cMotion: ### MISSING ONE OR MORE CONFIG SETTINGS ###"
		putlog "cMotion: ### It's likely that your bot will be broken!"
	}
}

### cMotion_diagnostic_auto 
proc cMotion_diagnostic_auto { min hr a b c } {
	cMotion_putloglev 5 * "cMotion_diagnostic_auto"
	putlog "cMotion: running level 4 self-diagnostic"
	cMotion_diagnostic_timers
	cMotion_diagnostic_utimers
}
if {$cMotion_testing == 0} {
	cMotion_putloglev d * "Running a level 5 self-diagnostic..."
	cMotion_diagnostic_plugins
	cMotion_diagnostic_settings
	cMotion_diagnostic_userinfo
	cMotion_putloglev d * "Diagnostics complete."
}

bind time - "30 * * * *" cMotion_diagnostic_auto
