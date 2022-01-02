#cMotion core

setudef flag cMotion
set cMotionVersion "0.3"
set cMotionRoot "scripts/cmotion2022"
set cMotionModules "$cMotionRoot/modules"
set cMotionPlugins "$cMotionRoot/plugins"
set cMotionData "$cMotionRoot/data"
set cMotionLocal "$cMotionRoot/local"
putlog "cMotion $cMotionVersion starting up..."

# test mode or no? 
set cMotion_testing 0
if {$cMotion_testing == 0} {
  putloglev 1 * "cMotion: INFO: Code loading in running mode"
  set cMotion_loading 1
} else {
  putlog "cMotion: INFO: Code loading in testing mode"
  set cMotion_loading 0
}

# logging 
if {![info exists cMotion_log_regexp]} {
	set cMotion_log_regexp ""
}
proc cMotion_putloglev { level star text } {
  global cMotion_testing cMotion_log_regexp	
	if {$cMotion_log_regexp != ""} {
		if {![regexp -nocase $cMotion_log_regexp $text]} {
			return 0
		}
	}
  regsub "cMotion:" $text "" text
  set text2 ""
  if {$level != "d"} {
    set text2 [string repeat " " $level]
  }
  set text "cMotion:$text2 $text"
  if {$cMotion_testing == 0} {
    putloglev $level $star "($level)$text"
  }
}

# Modules
if {$cMotion_testing == 1} {putlog "... loading init"}
source "$cMotionModules/init.tcl"

if {$cMotion_testing == 1} {putlog "... loading settings"}
source "$cMotionRoot/settings.tcl"

if {$cMotion_testing == 1} {putlog "... loading system"}
source "$cMotionModules/system.tcl"

if {$cMotion_testing == 1} {putlog "... loading abstracts"}
source "$cMotionModules/abstracts.tcl"

if {$cMotion_testing == 1} {putlog "... loading output"}
source "$cMotionModules/output.tcl"

if {$cMotion_testing == 1} {putlog "... loading events"}
source "$cMotionModules/events.tcl"

if {$cMotion_testing == 1} {putlog "... loading flood"}
source "$cMotionModules/flood.tcl"

if {$cMotion_testing == 1} {putlog "... loading facts"}
source "$cMotionModules/fact.tcl"

if {$cMotion_testing == 1} {putlog "... loading emotions"}
source "$cMotionModules/emotions.tcl"

# Plugins (need to be last so they can load abstracts)
if {$cMotion_testing == 1} {putlog "... loading plugins"}
source "$cMotionModules/plugins.tcl"

# Abstracts data
set abfiles [glob -nocomplain "$cMotionData/*abstracts.tcl"]
foreach ab $abfiles {
  source $ab
}
cMotion_putloglev d * "loaded abstracts data"

# load diagnostics
catch {
  if {$cMotion_testing == 1} {putlog "... loading self-diagnostics"}
  source "$cMotionModules/diagnostics.tcl"
}

# Ignition!
cMotion_startTimers
if {$cMotion_testing == 0} {
	cMotion_diagnostic_utimers
	cMotion_diagnostic_timers

  putlog "\002cMotion $cMotionVersion AI online\002 :D"
}
set cMotion_loading 0
