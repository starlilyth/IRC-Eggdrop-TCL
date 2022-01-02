# cMotion init module - variables, counters, queue modules moved here 
#  Set global variables
if {![info exists cMotionInfo]} {
  set cMotionInfo(silence) 0
  set cMotionInfo(away) 0
}
set cMotionCache(lastPlugin) ""
set botnicks ""
set cMotionAdminFlag "n"
set cMotionThisText ""
set cMotionGlobal 1
set cMotionPluginHistory [list]
set cMotionChannels [list]

# 0 -> 1 -> 2 -> 0
set cMotion_SLEEP(AWAKE) 0
set cMotion_SLEEP(BEDTIME) 1
set cMotion_SLEEP(ASLEEP) 2
# start off awake
set cMotionSettings(asleep) $cMotion_SLEEP(AWAKE)

### Counters
if {![info exists cMotion_counters]} {
  set cMotion_counters(dummy,dummy) 0
}
proc cMotion_counter_init { section name } {
  global cMotion_counters
  if {($section=="")|($name=="")} {return 0}
  if [info exists cMotion_counters($section,$name)] {
    cMotion_putloglev d * "not reiniting counter for $section $name"
    return 0
  }
  cMotion_putloglev d * "initing counter for $section $name"
  set cMotion_counters($section,$name) 0
}
proc cMotion_counter_incr { section name { amount 1 } } {
  global cMotion_counters
  cMotion_putloglev 1 * "incring counter $section $name by $amount"
  if {($section=="")|($name=="")} {return 0}
  incr cMotion_counters($section,$name) $amount
}
proc cMotion_counter_get { section name } {
  global cMotion_counters
  if {($section=="")|($name=="")} {return 0}
  return $cMotion_counters($section,$name)
}
proc cMotion_counter_set { section name amount } {
  global cMotion_counters
  if {($section=="")|($name=="")} {return 0}
  set cMotion_counters($section,$name) $amount
}

## Queue
# A rehash should kill the queue
set cMotion_queue [list]
set cMotion_queue_runny 1
# queue format is:
#  list of:
#    int: number of seconds until line should be output
#    str: target
#    str: content
# cMotion_queue_run
#
# Processes the queue, reducing all the times by 1. If anything hits or goes below
# 0 then it is sent to output
proc cMotion_queue_run { {force 0} } {
  global cMotion_queue cMotion_queue_runny
	if {$cMotion_queue_runny == 0} {
		if {$force == 0} {
			#queue is frozen
			return 0
		} else {
			cMotion_putloglev d * "Running queue once while frozen"
		}
	}
  set tempqueue [list]
  cMotion_putloglev 3 * "Running output queue..."
  foreach item $cMotion_queue {
    set sec [lindex $item 0]
    incr sec -1
    set target [lindex $item 1]
    set content [lindex $item 2]
    if {$sec < 1} {
      #time to output this
      cMotion_putloglev 4 * "queue: NOW $target :$content"
        if {$content != ""} {
          puthelp "PRIVMSG $target :$content"
        }
    } else {
      #put it back into queue
      cMotion_putloglev 4 * "queue: ${sec}s: $target :$content"
      lappend tempqueue [list $sec $target $content]
    }
  }
  set cMotion_queue $tempqueue
}
# Returns the number of seconds something to wait to be last in the queue
proc cMotion_queue_get_delay { } {
  global cMotion_queue
  return [expr 2 + [llength $cMotion_queue]]
}
# Adds some output to the queue
proc cMotion_queue_add { target content {delay 0} } {
  global cMotion_queue
  #calculate line delay
  set delay [expr $delay == 0 ? [cMotion_queue_get_delay] : $delay]
  cMotion_putloglev 1 * "queuing output '$content' for '$target' with ${delay}s delay"
  lappend cMotion_queue [list $delay $target $content]
}
# Adds some output to the head of the queue
proc cMotion_queue_add_now { target content } {
  global cMotion_queue
  #no delay
  set delay 0
  cMotion_putloglev 1 * "queuing output '$content' for '$target' with 0s delay"
  lappend cMotion_queue [list $delay $target $content]
}
# This is the timer function
proc cMotion_queue_callback { } {
  global cMotion_queue
  utimer 2 cMotion_queue_callback
  if {[llength $cMotion_queue] > 0} {
    cMotion_queue_run
  }
}
# Get the size of the queue in an implementation-independent fashion
proc cMotion_queue_size { } {
	global cMotion_queue
	return [llength cMotion_queue]
}
# Clears the queue
proc cMotion_queue_flush { } {
	global cMotion_queue
	set cMotion_queue [list]
}
# Stops queue output
proc cMotion_queue_freeze { } {
	global cMotion_queue_runny
	set cMotion_queue_runny 0
	cMotion_putloglev d * "Freezing output queue"
}
proc cMotion_queue_thaw { } {
	global cMotion_queue_runny
	set cMotion_queue_runny 1
	cMotion_putloglev d * "Thawing output queue"
}
# init timer
utimer 1 cMotion_queue_callback
