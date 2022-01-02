# cMotion facts module
# maximum number of things about which facts can be known
	if { [cMotion_setting_get "factsMaxItems"] != "" } {
		set cMotion_facts_max_items [cMotion_setting_get "factsMaxItems"]
	} else {
		set cMotion_facts_max_items 500
	}
# maximum number of facts to know about an item
	if { [cMotion_setting_get "factsMaxFacts"] != "" } {
		set cMotion_facts_max_facts [cMotion_setting_get "factsMaxFacts"]
	} else {
		set cMotion_facts_max_facts 20
	}
#work out where we're storing facts
	if {[cMotion_setting_get "factsFile"] == ""} {
		set cMotion_facts_file "$cMotionLocal/facts/facts.txt"
	} else {
		set cMotion_facts_file [cMotion_setting_get "factsFile"]
	}
# initialise
	if {![info exists cMotionFacts]} {
		set cMotionFacts(what,cMotion) [list "a very nice script"]
	}
proc cMotion_facts_load { } {
  global cMotionFacts cMotion_facts_file
	global cMotion_testing
	if {$cMotion_testing == 1} {
		return 0
	}
  cMotion_putloglev 1 * "Attempting to load $cMotion_facts_file"
  if {![file exists "$cMotion_facts_file"]} {
		cMotion_putloglev d * "facts file $cMotion_facts_file doesn't exist"
    return
  }
  set fileHandle [open "$cMotion_facts_file" "r"]
  set line [gets $fileHandle]
  set needResave 0
  set count 0
  while {![eof $fileHandle]} {
    if {$line != ""} {
      regexp {([^ ]+) (.+)} $line matches item fact
      if {![info exists cMotionFacts($item)]} {
        set cMotionFacts($item) [list]
      }
		 lappend cMotionFacts($item) $fact

      incr count


      if {[expr $count % 1000] == 0} {

      cMotion_putloglev d * "  still loading facts: $count ..."

      }
    }
    set line [gets $fileHandle]
  }

	#now de-dupe the lists
	set factnodes [array names cMotionFacts]
	foreach node $factnodes {
		set count [llength $cMotionFacts($node)]
		set cMotionFacts($node) [lsort -unique $cMotionFacts($node)]
		set newcount [llength $cMotionFacts($node)]
		if {$newcount < $count} {
			cMotion_putloglev 3 * "saved [expr $count - $newcount] items from $node"
		}
	}

  if {[info exists fileHandle]} {
    close $fileHandle
  }

  if {$needReSave} {
    cMotion_facts_save
  }
}

proc cMotion_facts_save { } {
  global cMotionFacts cMotion_facts_file
  global cMotion_facts_max_facts
  global cMotion_facts_max_items

  set tidy 0
  set tidyfact 0
  set count 0

  cMotion_putloglev 1 * "Saving facts to $cMotion_facts_file"

  set fileHandle [open "$cMotion_facts_file" "w"]

  set items [array names cMotionFacts]
  if {[llength $items] > $cMotion_facts_max_items} {
    cMotion_putloglev d * "Too many items are known ([llength $items] > $cMotion_facts_max_items), tidying up"
    set tidy 1
  }
  foreach item $items {
    if {$tidy} {
      if {[rand 100]< 10} {
        #clear array entry
        unset cMotionFacts($item)
        incr count
        continue
      }
    }
    if {[llength $cMotionFacts($item)] > $cMotion_facts_max_facts} {
      set tidyfact 1
    } else {
      set tidyfact 0
    }
    foreach fact $cMotionFacts($item) {
      if {$tidyfact} {
        if {[rand 100] < 10} {
          #less critical so we won't waste time trying to delete from memory too :)
          continue
        }
        puts $fileHandle "$item $fact"
      } else {
        # don't tidy, just dump it straight to the file
        puts $fileHandle "$item $fact"
      }  
    }
  }
  if {$tidy} {
    cMotion_putloglev d * "$count facts have been forgo.. los... delet... thingy *dribbles*"
  }
  close $fileHandle
}

proc cMotion_facts_auto_save { min hr a b c } {
  putlog "cMotion: autosaving facts..."
  cMotion_facts_save
}

proc cMotion_facts_forget_all { fact } {
  global cMotionFacts cMotionLocal

  #drop the array element
  unset cMotionFacts($fact)

  #resave to delete
  cMotion_facts_save
}

# save facts every hour
bind time - "01 * * * *" cMotion_facts_auto_save

# load facts at startup
catch {
  if {$cMotion_loading == 1} {
    cMotion_putloglev d * "autoloading facts..."
    cMotion_facts_load
  }
}

putlog "loaded fact module"
