# Flood checking

# init our counters
cMotion_counter_init "flood" "checks"

# We're going to track flooding PER NICK globally, not per channel
# If someone's flooding us in one place, we'll handle it for all channels
# to stop them being annoying

# HOW IT WORKS
#
# Track a score for each nick
# Reduce the scores by 1 every 30 seconds
# Matching a plugin is one point
# Matching the SAME plugin as before is 3
# Going over 7 will make the bot ignore 50% of what you would trigger
# Going over 15 cuts you out completely
# Message levels: 
#   log: Flood checks
#     d: flood ticks
#     2: flood additions/subtractions

if {![info exists cMotion_flood_info]} {
  set cMotion_flood_info(_) 0
  set cMotion_flood_last(_) ""
  set cMotion_flood_lasttext(_) ""
  set cMotion_flood_note ""
  set cMotion_flood_undo 0
}

proc cMotion_flood_tick { } { 
  cMotion_putloglev 4 * "cMotion: flood tick"
	utimer 30 cMotion_flood_tick
  #tick all values down one, to zero
  global cMotion_flood_info cMotion_flood_last cMotion_flood_lasttext
  set stats ""
  foreach element [array names cMotion_flood_info] {
    set val $cMotion_flood_info($element)
    incr val -2
    if {$val < 0} {
      catch {
        unset cMotion_flood_info($element)
      }
      catch {
        unset cMotion_flood_last($element)
      }
      catch {
        unset cMotion_flood_lasttext($element)
      }
      cMotion_putloglev 2 * "cMotion: flood tick: $element removed"
    } else {
      append stats "$element:\002$val\002 "
      set cMotion_flood_info($element) $val
    }
  }
  if {$stats != ""} {
    cMotion_putloglev d * "cMotion: flood tick: $stats"
  }
}

proc cMotion_flood_add { nick { callback "" } { text "" } } {
  global cMotion_flood_info cMotion_flood_last cMotion_flood_lasttext cMotion_flood_last cMotion_flood_undo
  set val 1
  if [validuser $nick] {
    set handle $nick
  } else {
    set handle [nick2hand $nick]
    if {$handle == "*"} {
      set handle $nick
    }
  }
  set lastCallback ""
  catch {
    set lastCallback $cMotion_flood_last($handle)
  }
  if {$callback != ""} {
    set cMotion_flood_last($handle) $callback
    if {$lastCallback == $callback} {
      #naughty
      set val 3
    }
  }
  set lastText ""
  catch {
    set lastText $cMotion_flood_lasttext($handle)
  }
  if {$text != ""} {
    set cMotion_flood_lasttext($handle) $text
    #putlog "now: $text, last: $lastText"
    if {$lastText == $text} {
      #naughty
      incr val 2
    }
  }
  set flood 0
  catch {
    set flood $cMotion_flood_info($handle)
  }
	set oldflood $flood
  incr flood $val
  if {$flood > 40} {set flood 40}
  cMotion_putloglev 2 * "cMotion: flood $oldflood -- $val --> $flood for $nick"
	cMotion_putloglev 3 * "flood was added by plugin $callback"
  set cMotion_flood_info($handle) $flood
  set cMotion_flood_undo $val
}

proc cMotion_flood_clear { nick } {
  global cMotion_flood_info cMotion_flood_last
	cMotion_putloglev d * "Cleared flood for $nick"
  set cMotion_flood_info($nick) 0
  set cMotion_flood_last($nick) ""
}

proc cMotion_flood_remove { nick } {
  global cMotion_flood_info 
  set val 1
  if [validuser $nick] {
    set handle $nick
  } else {
    set handle [nick2hand $nick]
    if {$handle == "*"} {
      set handle $nick
    }
  }
  set flood 0
  catch {
    set flood $cMotion_flood_info($handle)
  }
  incr flood -1
  if {$flood < 0} {return 0}
  cMotion_putloglev 2 * "cMotion: flood removed 1 from $nick, now $flood"
  set cMotion_flood_info($handle) $flood
}

proc cMotion_flood_undo { nick } {
  global cMotion_flood_undo cMotion_flood_info cMotion_flood_lasttext
  set val $cMotion_flood_undo
  if {$val <= 1} {return 0}
  if [validuser $nick] {
    set handle $nick
  } else {
    set handle [nick2hand $nick]
    if {$handle == "*"} {
      set handle $nick
    }
  }
  set flood 0
  catch {
    set flood $cMotion_flood_info($handle)
  }
	set oldflood $flood
  incr flood [expr 0 - $val]
  if {$flood < 0} {set flood 0}
  set cMotion_flood_info($handle) $flood
  set cMotion_flood_lasttext($handle) ""
  set cMotion_flood_undo 1
  cMotion_putloglev 2 * "cMotion: undid flood $oldflood -- $val --> $flood from $nick"
  return 0
}

proc cMotion_flood_get { nick } {
  global cMotion_flood_info
  if [validuser $nick] {
    set handle $nick
  } else {
    set handle [nick2hand $nick]
    if {$handle == "*"} {set handle $nick}
  }
  set flood 0
  catch {
    set flood $cMotion_flood_info($handle)
  }
  return $flood
}

proc cMotion_flood_check { nick } {
  if { [cMotion_setting_get "disableFloodChecks"] != "" } {
    if { [cMotion_setting_get "disableFloodChecks"] == 1 } {return 0}  
  }  
  cMotion_putloglev 3 * "checking flood for $nick"
  set flood [cMotion_flood_get $nick]
  set chance 2
  if {$flood > 35} {set chance -1}
  if {$flood > 25} {set chance -1}
  if {$flood > 15} {set chance 1}
  set r [rand 2]
  if {!($r < $chance)} {
    putlog "cMotion: FLOOD check on $nick"
    cMotion_counter_incr "flood" "checks"
    return 1
  }
  return 0
}

utimer 30 cMotion_flood_tick
