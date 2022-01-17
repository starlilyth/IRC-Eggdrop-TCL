# cMotion facts module
# facts are learned via the learnfact_action plugin, and output from the sayfact_text plugin
#
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
# initialise
if {![info exists cMotionFacts]} {
	set cMotionFacts(what,cMotion) [list "is,a very nice script"]
  sqlite3 adb $absdb
  # fact column is unique to prevent duplicate entries
  adb eval "CREATE TABLE IF NOT EXISTS facts (type TEXT NOT NULL COLLATE NOCASE, item TEXT NOT NULL COLLATE NOCASE, verb TEXT NOT NULL COLLATE NOCASE, fact TEXT NOT NULL COLLATE NOCASE UNIQUE)"
}
proc cMotion_facts_load { } {
  global cMotionFacts
  cMotion_putloglev 1 * "Attempting to load facts from DB"
  # get the list of items and facts
  set abList [adb eval {SELECT type,item,verb,fact FROM facts}]
  # loop through the list
  while {[llength $abList] > 0 } {
    # assign first two elements to our vars
    lassign $abList type item verb fact
    # create item list if it doesnt exist
    if {![info exists cMotionFacts($type,$item)]} {
      set cMotionFacts($type,$item) [list]
    }
    # add the entry to memory if it isnt present already
    set vfact "$verb,$fact"
    if {[lsearch -exact $cMotionFacts($type,$item) $vfact] == -1} {
      lappend cMotionFacts($type,$item) $vfact
    }
    # remove the first two elements and loop again
    set abList [lreplace $abList 0 3]
  }
}

proc cMotion_facts_save { } {
  global cMotionFacts cMotion_facts_max_facts cMotion_facts_max_items absdb
  cMotion_putloglev 1 * "Saving facts to DB"
  set tidy 0
  set count 0
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
    foreach fact $cMotionFacts($item) {
      if {[llength $cMotionFacts($item)] > $cMotion_facts_max_facts} {
        if {[rand 100] < 10} {
          #less critical so we won't waste time trying to delete from memory too :)
          continue
        }
      }
      set ti [split $item ","]
      lassign $ti t i
      set vf [split $fact ","]
      lassign $vf v f
      sqlite3 adb $absdb
      catch {
        adb eval "INSERT INTO facts VALUES (:t, :i, :v, :f)"
      } err
      if {$err ne ""} {
        cMotion_putloglev d * "DB insert error: $err"
      }
    }
  }
  if {$tidy} {
    cMotion_putloglev d * "$count facts have been forgo.. los... delet... thingy *dribbles*"
  }
}

proc cMotion_facts_auto_save { min hr a b c } {
  putlog "cMotion: autosaving facts..."
  cMotion_facts_save
}
# save facts every hour
bind time - "01 * * * *" cMotion_facts_auto_save

proc cMotion_fact_forget_fact { type item fact } {
  global cMotionFacts absdb
  set item_list $cMotionFacts($type,$item)
  set vfact [lindex $item_list $fact]
  # delete from memory
  set item_list [lreplace $item_list $fact $fact]
  set cMotionFacts($type,$item) $item_list
  # delete from DB
  set vf [split $vfact ","]
  lassign $vf v f
  sqlite3 adb $absdb
  catch {
    adb eval "DELETE FROM facts WHERE type = :type AND item = :item AND verb = :v AND fact = :f"
  } err
  if {$err ne ""} {
    cMotion_putloglev d * "DB delete error: $err"
  }
}

proc cMotion_facts_delete_all { type item } {
  global cMotionFacts absdb
  # drop the array element
  unset cMotionFacts($type,$item)
  # delete DB entry
  sqlite3 adb $absdb
  catch {
    adb eval "DELETE FROM facts WHERE type = :type AND item = :item"
  } err
  if {$err ne ""} {
    cMotion_putloglev d * "DB delete error: $err"
  }
}

# load facts at startup
catch {
  if {$cMotion_loading == 1} {
    cMotion_putloglev d * "autoloading facts..."
    cMotion_facts_load
  }
}
