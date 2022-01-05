# cMotion - Abstract Handling
# NOTE: This module should be loaded before plugins as they will need it to register abstracts
#
# The idea is that abstracts are stored in a db, and loaded into memory when needed.
# At some point they're unloaded (i.e. deallocated) out of memory to free up space.
# This is done by deallocating them 5 mins after their last use.
#
# Variables:
#   cMotion_abstract_contents: a name-indexed array containing the lists of abstracts
#   cMotion_abstract_timestamps: a name-indexed array containing the last access time of an abstract
#                                0 means not cached
#
# Functions:
#   cMotion_abstract_register(abstract): register an abstract list (add table to DB).
#
#   cMotion_abstract_add(abstract, contents): add an abstract to a list (add to DB and load into memory).
#
#   cMotion_abstract_get(abstract): return a random element from the list.
#
#   cMotion_abstract_gc(): the "garbage collector": unloads from memory not recently used abstract lists
#
#   cMotion_abstract_all(abstract): return the list of all elements from an abstract
#
#   cMotion_abstract_delete(abstract, index): delete from an abstract list (DB and memory).
#
#   cMotion_abstract_load(abstract): load the abstract list into memory from DB
#
# Admin plugin to be loaded (but not from this module):
#   !cmadmin abstract (add|list|view|delete|gc) ...

if { [cMotion_setting_get "abstractMaxAge"] != "" } {
  set cMotion_abstract_max_age [cMotion_setting_get "abstractMaxAge"]
} else {
  set cMotion_abstract_max_age 300
}

if { [cMotion_setting_get "abstractMaxNumber"] != "" } {
  set cMotion_abstract_max_number [cMotion_setting_get "abstractMaxNumber"]
} else {
  set cMotion_abstract_max_number 600
}

# initialise the arrays
if {![info exists cMotion_abstract_contents]} {
  set cMotion_abstract_contents(dummy) ""
  set cMotion_abstract_languages(dummy) "en"
  set cMotion_abstract_timestamps(dummy) 1
	set cMotion_abstract_last_get(dummy) ""
}

#init our counters
cMotion_counter_init "abstracts" "faults"
cMotion_counter_init "abstracts" "pageouts"
cMotion_counter_init "abstracts" "gc"
cMotion_counter_init "abstracts" "gets"

proc cMotion_abstract_register { abstract { stuff "" } } {
	cMotion_putloglev 5 * "cMotion_abstract_register ($abstract)"
  global cMotionSettings absdb cMotion_abstract_contents cMotion_abstract_timestamps cMotion_abstract_last_get cMotion_abstract_languages
  set lang $cMotionSettings(deflang)
  #set timestamp to now
  set cMotion_abstract_timestamps($abstract) [clock seconds]
	set cMotion_abstract_last_get($abstract) ""

  set tableName "abs_$lang\_$abstract"
  sqlite3 adb $absdb
  # check if abstract table exists
  set abExists [adb eval "SELECT count() FROM sqlite_master WHERE type='table' AND name=:tableName"]
  if { $abExists == 1 } {
    cMotion_abstract_load $abstract
  } else {
    #create blank array for it
    set cMotion_abstract_contents($abstract) [list]
    set cMotion_abstract_languages($abstract) "$lang"
    # DB table creation. Uses UNIQUE constraint to prevent duplicate entries
    adb eval "CREATE TABLE IF NOT EXISTS $tableName (entry TEXT NOT NULL COLLATE NOCASE UNIQUE)"
    # Add data
  	if {$stuff != ""} {
  		# batch-add at the same time
  		cMotion_putloglev d * "Batchadding during registration for $abstract"
  		cMotion_abstract_batchadd $abstract $stuff
  	}
  }
}

proc cMotion_abstract_batchadd { abstract stuff } {
  cMotion_putloglev 1 * "batch-adding to $abstract"
  foreach i $stuff {
    cMotion_abstract_add $abstract $i
  }
}

proc cMotion_abstract_add { abstract text } {
	cMotion_putloglev 5 * "cMotion_abstract_add ($abstract, $text)"
  global cMotion_abstract_contents cMotion_abstract_timestamps cMotion_abstract_max_age absdb cMotionSettings
  set lang $cMotionSettings(deflang)
  cMotion_putloglev 2 * "updating abstract '$abstract' with $text"
  # load abstract into memory if it isnt already
  if {$cMotion_abstract_timestamps($abstract) < [expr [clock seconds] - $cMotion_abstract_max_age]} {
    cMotion_abstract_load $abstract
  }
  # add entry to array in memory
  if {[lsearch -exact $cMotion_abstract_contents($abstract) $text] == -1} {
    lappend cMotion_abstract_contents($abstract) $text
  }
  # update the DB table
  set tableName "abs_$lang\_$abstract"
  sqlite3 adb $absdb
  catch {
    adb eval "INSERT INTO $tableName VALUES (:text)"
  } err
  # dont return error on unique constraint violation, we are using this to filter duplicates
  if {[string match "UNIQUE *" $err]} {return 0}
}

proc cMotion_abstract_load { abstract } {
  cMotion_putloglev 5 * "cMotion_abstract_load ($abstract)"
  global cMotion_abstract_contents cMotion_abstract_timestamps cMotion_abstract_languages cMotion_testing cMotionSettings absdb
  set lang $cMotionSettings(deflang)
  cMotion_putloglev 1 * "Attempting to load abstract '$abstract'"
  if {$cMotion_testing} {
    return 0
  }
  #create blank array for it
  set cMotion_abstract_contents($abstract) [list]
  set cMotion_abstract_languages($abstract) "$lang"
  #set timestamp to now
  set cMotion_abstract_timestamps($abstract) [clock seconds]

  set tableName "abs_$lang\_$abstract"
  sqlite3 adb $absdb
  set sqlList [adb eval "SELECT * FROM $tableName"]
  foreach item $sqlList {
    lappend cMotion_abstract_contents($abstract) $item
  }
}

proc cMotion_abstract_all { abstract } {
	cMotion_putloglev 5 * "cMotion_abstract_all ($abstract)"
  global cMotion_abstract_contents cMotion_abstract_timestamps cMotion_abstract_max_age
	if [info exists cMotion_abstract_timestamps($abstract)] {
    # load abstract into memory if it isnt already
		if {$cMotion_abstract_timestamps($abstract) < [expr [clock seconds] - $cMotion_abstract_max_age]} {
			cMotion_abstract_load $abstract
		}
		return $cMotion_abstract_contents($abstract)
	} else {
	  #abstract doesn't exist
		cMotion_putloglev d * "cMotion_abstract_all: couldn't find abstract '$abstract'"
	}
}

proc cMotion_abstract_exists { abstract } {
	cMotion_putloglev 5 * "cMotion_abstract_exists ($abstract)"
  global cMotion_abstract_timestamps
  cMotion_putloglev 2 * "checking for existence of abstract $abstract"
  if {![info exists cMotion_abstract_timestamps($abstract)]} {
    return 0
  }
	return 1
}

proc cMotion_abstract_get { abstract } {
	cMotion_putloglev 5 * "cMotion_abstract_get ($abstract)"
  global cMotion_abstract_timestamps cMotion_abstract_max_age cMotion_abstract_last_get cMotionSettings
  cMotion_putloglev 2 * "getting abstract $abstract"

  if {![info exists cMotion_abstract_timestamps($abstract)]} {
    return ""
  }
  cMotion_counter_incr "abstracts" "gets"

  if {$cMotion_abstract_timestamps($abstract) < [expr [clock seconds] - $cMotion_abstract_max_age]} {
    cMotion_putloglev d * "abstract $abstract has been unloaded, reloading..."
    cMotion_counter_incr "abstracts" "faults"
    cMotion_abstract_load $abstract
  }

  set cMotion_abstract_timestamps($abstract) [clock seconds]

	if {![info exists cMotion_abstract_last_get($abstract)]} {
		set cMotion_abstract_last_get($abstract) ""
	}

	# look for male and female versions, and merge in if needed
	if [cMotion_abstract_exists "${abstract}_$cMotionSettings(gender)"] {
		# mix-in the gender one with the vanilla one
		cMotion_putloglev 1 * "mixing in $cMotionSettings(gender) version of $abstract"
		set final_version [concat [cMotion_abstract_all $abstract] [cMotion_abstract_all "${abstract}_$cMotionSettings(gender)"]]
	} else {
		set final_version [cMotion_abstract_all $abstract]
	}

	if {[llength $final_version] == 0} {
		cMotion_putloglev d * "abstract '$abstract' is empty!"
		return ""
	} else {
		set retval [lindex $final_version [rand [llength $final_version]]]
		if {[llength $final_version] > 1} {
			set count 0
			while {$retval == $cMotion_abstract_last_get($abstract)} {
				cMotion_putloglev d * "fetched repeat value for abstract $abstract, trying again"
				cMotion_putloglev 1 * "this: $retval ... last: $cMotion_abstract_last_get($abstract)"
				set retval [lindex $final_version [rand [llength $final_version]]]
				incr count
				if {$count > 5} {
					cMotion_putloglev d * "trying too hard to find non-dupe for abstract $abstract, giving up and using $retval"
					break
				}
			}
		}
	}

	set cMotion_abstract_last_get($abstract) $retval
	cMotion_putloglev 5 * "successfully got '$retval' from '$abstract'"
	return $retval
}

proc cMotion_abstract_delete { abstract index } {
	cMotion_putloglev 5 * "cMotion_abstract_delete ($abstract, $index)"
  global cMotion_abstract_contents cMotion_abstract_timestamps absdb cMotion_abstract_max_age cMotion_abstract_languages
  if [info exists cMotion_abstract_timestamps($abstract)] {
    # load abstract into memory if it isnt already
    if {$cMotion_abstract_timestamps($abstract) < [expr [clock seconds] - $cMotion_abstract_max_age]} {
      cMotion_abstract_load $abstract
    }
    set itemName [lindex $cMotion_abstract_contents($abstract) $index]
    # delete from memory
    set cMotion_abstract_contents($abstract) [lreplace $cMotion_abstract_contents($abstract) $index $index]
    # update the DB table
    set absLang $cMotion_abstract_languages($abstract)
    set tableName "abs_$absLang\_$abstract"
    sqlite3 adb $absdb
    catch {
      adb eval "DELETE FROM $tableName WHERE entry = :itemName"
    }
  } else {
    #abstract doesn't exist
    cMotion_putloglev d * "cMotion_abstract_all: couldn't find abstract '$abstract'"
  }
}

# garbage collect the abstracts arrays
proc cMotion_abstract_gc { } {
  cMotion_putloglev 5 * "cMotion_abstract_gc"
  global cMotion_abstract_contents cMotion_abstract_timestamps cMotion_abstract_max_age cMotionSettings cMotion_abstract_languages
  set lang $cMotionSettings(deflang)
  cMotion_putloglev 2 * "Garbage collecting abstracts..."
  cMotion_counter_incr "abstracts" "gc"
  set abstracts [array names cMotion_abstract_contents]
  set limit [expr [clock seconds] - $cMotion_abstract_max_age]
  set expiredList ""
  set expiredCount 0
  foreach abstract $abstracts {
    if {($cMotion_abstract_timestamps($abstract) < $limit) && ($cMotion_abstract_timestamps($abstract) > 0) || $cMotion_abstract_languages($abstract) != $lang } {
      append expiredList "$abstract "
      incr expiredCount
      unset cMotion_abstract_contents($abstract)
      unset cMotion_abstract_languages($abstract)
      set cMotion_abstract_timestamps($abstract) 0
      cMotion_counter_incr "abstracts" "pageouts"
    }
  }
  if {$expiredList != ""} {
    cMotion_putloglev d * "expired $expiredCount abstracts: $expiredList"
  }
}

proc cMotion_abstract_auto_gc { min hr a b c } {
  cMotion_abstract_gc
}
bind time - "* * * * *" cMotion_abstract_auto_gc

# flush all of the abstracts to disk
# this was created for changing languages on the fly. If you're using this
# for some other reason, then you might want to be sure.
proc cMotion_abstract_flush { } {
  global cMotionSettings cMotion_abstract_contents cMotion_abstract_languages
  set lang $cMotionSettings(deflang)
  set abstracts [array names cMotion_abstract_contents]
  foreach abstract $abstracts {
    set storedLang $cMotion_abstract_languages($abstract)
    if { $abstract != "dummy" && $storedLang == $lang } {
      unset cMotion_abstract_contents($abstract)
      unset cMotion_abstract_languages($abstract)
    }
  }
  set cMotion_abstract_contents(dummy) ""
  set cMotion_abstract_languages(dummy) ""
  set cMotion_abstract_timestamps(dummy) 1
}

# this loads language abstracts for the current language in cMotionSettings
proc cMotion_abstract_revive_language { } {
  global cMotionSettings cMotionData cMotion_abstract_contents
  set lang $cMotionSettings(deflang)
  cMotion_putloglev 2 * "cMotion: reviving language ($lang) abstracts"
  set languages [split $cMotionSettings(languages) ","]
  # just check if it's ok to use this language
  set ok 0
  foreach language $languages {
    if { $lang == $language } { set ok 1 }
  }
  if { $ok != 1 } {
    cMotion_putloglev 2 * "cMotion: language not found, cannot revive"
    return -1
  }
  # if the default abstract list exists, load it first
  if { [file exists "$cMotionData/abstracts/$lang/abstracts.tcl"] } {
		cMotion_putloglev d * "loading system abstracts for lang $lang"
    catch {
      source "$cMotionData/abstracts/$lang/abstracts.tcl"
    }
  } else {
    cMotion_putloglev 2 * "cMotion: language default abstracts not found"
  }
  # Other abstract lists
  set abfiles [glob -nocomplain "$cMotionData/abstracts/$lang/*-abstracts.tcl"]
  foreach ab $abfiles {
    source $ab
  }
  cMotion_putloglev d * "loaded abstracts data"
}

# we have to revive at least one language
cMotion_abstract_revive_language

cMotion_putloglev d * "abstract module loaded"
