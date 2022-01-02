# cMotion - Abstract Handling
# NOTE: This module should be loaded before plugins as they will need it to register abstracts
# Summary of new abstract system design:
#
# Abstracts are getting out of control... the amount of information cMotion tracks can get silly
# with the whole learning arrangement. The idea behind the new system is that abstracts are stored
# on disk, and loaded into memory when needed, at which point they're loaded into memory.
#
# At some point they're unloaded (i.e. deallocated) out of memory to free up space. This will
# probably be done by deallocating them 5 mins after their last use.
#
# This has important implications for cMotion. No longer will abstracts be stored as global-scope
# lists, but in some name-indexed array. Code that directly fetches abstracts (rather than using
# %VAR{}) will fail.
#
# Due to the way the caching will work, abstracts should be fetched through an interface rather than
# directly indexing the array. This interface also means the way abstracts are stored internally can
# be changed later on without affecting the operation of the rest of cMotion.
#
# Variables:
#   cMotion_abstract_contents: a name-indexed array containing the lists of abstracts
#   cMotion_abstract_timestamps: a name-indexed array containing the last access time of an abstract
#                                0 means not cached
#
# Functions:
#   cMotion_abstract_register(abstract): register that an abstract should be tracked. A file for it
#                                        if created on disk if needed; if the file exists then the
#                                        contents are loaded
#   cMotion_abstract_add(abstract, contents): add an abstract to a list. The change is immediately
#                                             written to disk
#   cMotion_abstract_get(abstract): return a random element from the list. The list is transparnetly
#                                   loaded from disk if needed
#   cMotion_abstract_gc(): the "garbage collector": unsets any abstracts not used recently
#   cMotion_abstract_all(abstract): return the list of all elements from an abstract
#   cMotion_abstract_delete(abstract, index): delete from an abstract. The change is immediately
#                                             written to disk
#   cMotion_abstract_load(abstract): cache the abstract list in memory from disk
#   cMotion_abstract_save(abstract): saves the cached version to disk
#
# Admin plugin to be loaded (but not from this module):
#   !bmadmin abstract (add|list|view|del(ete)?|cache|gc) ...
#
#
# The abstracts will be stored in ./abstracts/<language>/<abstract name>.txt in the cMotion directory. The
# fileformat is simply one per line.
## Wha? Oh hi, SQLite data storage, yes thats the plan. Then we can ditch all this caching biz. 

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
  set cMotion_abstract_ondisk [list]
	set cMotion_abstract_last_get(dummy) ""
	set cMotion_abstract_filters(dummy) ""
}

#init our counters
cMotion_counter_init "abstracts" "faults"
cMotion_counter_init "abstracts" "pageouts"
cMotion_counter_init "abstracts" "gc"
cMotion_counter_init "abstracts" "gets"

# if dir doesnt exist, create it!
set cMotion_abstract_dir "$cMotionLocal/abstracts/$cMotionSettings(deflang)"

# garbage collect the abstracts arrays
proc cMotion_abstract_gc { } {
	cMotion_putloglev 5 * "cMotion_abstract_gc"
  global cMotion_abstract_contents cMotion_abstract_timestamps
  global cMotion_abstract_max_age cMotion_abstract_ondisk
  global cMotionSettings cMotion_abstract_languages
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
      lappend cMotion_abstract_ondisk $abstract
      cMotion_counter_incr "abstracts" "pageouts"
    }
  }

  if {$expiredList != ""} {
    cMotion_putloglev d * "expired $expiredCount abstracts: $expiredList"
  }
}

proc cMotion_abstract_register { abstract { stuff "" } } {
	cMotion_putloglev 5 * "cMotion_abstract_register ($abstract)"
  global cMotion_abstract_contents cMotion_abstract_timestamps
  global cMotionData cMotion_testing 
  global cMotionSettings cMotion_abstract_languages cMotion_abstract_dir
	global cMotion_abstract_last_get

  #set timestamp to now
  set cMotion_abstract_timestamps($abstract) [clock seconds]
  set lang $cMotionSettings(deflang)
	set cMotion_abstract_last_get($abstract) ""

  #load any existing abstracts
  if [file exists "$cMotion_abstract_dir/${abstract}.txt"] {
    cMotion_abstract_load $abstract
  } else {
    # check that the language directory exists while we're at it
    if { ![file exists $cMotion_abstract_dir] } {
      [file mkdir $cMotion_abstract_dir]
    }
    #file doesn't exist - create an empty one
    #create blank array for it
    set cMotion_abstract_contents($abstract) [list]
    set cMotion_abstract_languages($abstract) "$lang"
    cMotion_putloglev 1 * "Creating new abstract file for $abstract"
    set fileHandle [open "$cMotion_abstract_dir/${abstract}.txt" "w"]
    puts $fileHandle " "
  }

  if {[info exists fileHandle]} {
    close $fileHandle
  }

	if {$stuff != ""} {
		# batch-add at the same time
		cMotion_putloglev d * "Batchadding during registration for $abstract"
		cMotion_abstract_batchadd $abstract $stuff
	}
}

proc cMotion_abstract_batchadd { abstract stuff } {
  cMotion_putloglev 1 * "batch-adding to $abstract"
  foreach i $stuff {
    cMotion_abstract_add $abstract $i 0
  }
  cMotion_abstract_save $abstract
}

proc cMotion_abstract_load { abstract } {
	cMotion_putloglev 5 * "cMotion_abstract_load ($abstract)"
  global cMotion_abstract_contents cMotion_abstract_timestamps
  global cMotionData cMotion_abstract_ondisk
  global cMotion_testing cMotionSettings
  global cMotion_abstract_languages cMotion_abstract_dir
  set lang $cMotionSettings(deflang)

  cMotion_putloglev 1 * "Attempting to load $cMotion_abstract_dir/${abstract}.txt"

  if {![file exists "$cMotion_abstract_dir/${abstract}.txt"]} {
    return
  }

  #create blank array for it
  set cMotion_abstract_contents($abstract) [list]
  set cMotion_abstract_languages($abstract) "$lang"

  #set timestamp to now
  set cMotion_abstract_timestamps($abstract) [clock seconds]

  if {$cMotion_testing} {
    return 0
  }

  #remove from ondisk list
  set index [lsearch -exact $cMotion_abstract_ondisk $abstract]
  set cMotion_abstract_ondisk [lreplace $cMotion_abstract_ondisk $index $index]

  set fileHandle [open "$cMotion_abstract_dir/${abstract}.txt" "r"]
  set line [gets $fileHandle]
  set needReSave 0
  set count 0

  while {![eof $fileHandle]} {
    set line [string trim $line]
    if {$line != ""} {
			lappend cMotion_abstract_contents($abstract) $line
      incr count
    }
    set line [gets $fileHandle]
  }

	#optimise
	set cMotion_abstract_contents($abstract) [lsort -unique $cMotion_abstract_contents($abstract)]
	set newcount [llength $cMotion_abstract_contents($abstract)]
	if {$newcount < $count} {
		cMotion_putloglev d * "Shrunk abstract $abstract by [expr $count - $newcount] items by de-duping"
		set needReSave 1
	}

  if {[info exists fileHandle]} {
    close $fileHandle
  }

  if {$needReSave} {
    cMotion_abstract_save $abstract
  }

	cMotion_putloglev 1 * "Abstract $abstract loaded, checking for filter"
	cMotion_abstract_apply_filter $abstract
}

proc cMotion_abstract_add { abstract text {save 1} } {
	cMotion_putloglev 5 * "cMotion_abstract_add ($abstract, $text, $save)"
  global cMotion_abstract_contents cMotion_abstract_timestamps cMotion_abstract_max_age
  global cMotionData cMotionSettings
	global cMotion_abstract_dir
  set lang $cMotionSettings(deflang)

  cMotion_putloglev 2 * "Adding '$text' to abstract '$abstract'"

  if {$cMotion_abstract_timestamps($abstract) < [expr [clock seconds] - $cMotion_abstract_max_age]} {
    #cMotion_abstract_load $abstract
    #new more efficient way
    # - append it to the file regardless
    # - it can be filtered on load

    cMotion_putloglev 2 * "updating abstracts '$abstract' on disk"
    if {$save} {
      set fileHandle [open "$cMotion_abstract_dir/${abstract}.txt" "a+"]
      puts $fileHandle $text
      close $fileHandle
    }
    return
  }

  if {[lsearch -exact $cMotion_abstract_contents($abstract) $text] == -1} {
    lappend cMotion_abstract_contents($abstract) $text
    if {$save} {
      cMotion_putloglev 2 * "updating abstracts '$abstract' on disk and in memory"
      set fileHandle [open "$cMotion_abstract_dir/${abstract}.txt" "a+"]
      puts $fileHandle $text
      close $fileHandle
    }
  }
}

proc cMotion_abstract_save { abstract } {
	cMotion_putloglev 5 * "cMotion_abstract_save"
  global cMotion_abstract_contents
  global cMotionData cMotion_testing 
  global cMotion_abstract_max_number cMotionSettings cMotion_abstract_languages
	global cMotion_abstract_dir
  set lang $cMotionSettings(deflang)

  if {$lang != $cMotion_abstract_languages($abstract) } {
    cMotion_putloglev 1 * "Did not save '$abstract' to disk (wrong language)"
    return 0
  }

  set tidy 0
  set count 0
  set drop_count 0

  #don't save if we're starting up else we'll lose saved stuff
  if {$cMotion_testing} {
    return 0
  }

  cMotion_putloglev 1 * "Saving abstracts '$abstract' to disk"

  set fileHandle [open "$cMotion_abstract_dir/${abstract}.txt" "w"]
  set number [llength $cMotion_abstract_contents($abstract)]
  if {$number > $cMotion_abstract_max_number} {
    cMotion_putloglev d * "Abstract $abstract has too many elements ($number > $cMotion_abstract_max_number), tidying up"
    set tidy 1
  }
  foreach a $cMotion_abstract_contents($abstract) {
    if {$tidy} {
      if {[rand 100] < 10} {
        cMotion_putloglev 3 * "Dropped '$a' from abstract $abstract"
        incr drop_count
        continue
      }
    }
    puts $fileHandle $a
    incr count
  }
  if {$tidy} {
		cMotion_putloglev d * "Abstract $abstract now has $count elements ($drop_count fewer)"
  }
  close $fileHandle
	cMotion_putloglev 2 * "Saved abstract $abstract to disk"
}

proc cMotion_abstract_all { abstract } {
	cMotion_putloglev 5 * "cMotion_abstract_all ($abstract)"
  global cMotion_abstract_contents cMotion_abstract_timestamps cMotion_abstract_max_age

	if [info exists cMotion_abstract_timestamps($abstract)] {
		if {$cMotion_abstract_timestamps($abstract) < [expr [clock seconds] - $cMotion_abstract_max_age]} {
			cMotion_abstract_load $abstract
		}

		return $cMotion_abstract_contents($abstract)
	} else {
	#abstract doesn't exist
		cMotion_putloglev d * "cMotion_abstract_all: couldn't find abstract '$abstract' in new system"
		catch {
			global $abstract
			set var [subst $$abstract]

			return $var
		}
		cMotion_putloglev d * "cMotion_abstract_all: $abstract doesn't exist as a global variable either :("
		return ""
	}

}

proc cMotion_abstract_exists { abstract } {
	cMotion_putloglev 5 * "cMotion_abstract_exists ($abstract)"
  global cMotion_abstract_contents cMotion_abstract_timestamps cMotion_abstract_max_age cMotion_abstract_last_get

  cMotion_putloglev 2 * "checking for existence of abstract $abstract"

  if {![info exists cMotion_abstract_timestamps($abstract)]} {
    return 0
  }
	return 1
}

proc cMotion_abstract_get { abstract } {
	cMotion_putloglev 5 * "cMotion_abstract_get ($abstract)"
  global cMotion_abstract_contents cMotion_abstract_timestamps cMotion_abstract_max_age cMotion_abstract_last_get cMotionSettings

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
  global cMotion_abstract_contents

  set cMotion_abstract_contents($abstract) [lreplace $cMotion_abstract_contents($abstract) $index $index]
  cMotion_abstract_save $abstract
}

proc cMotion_abstract_auto_gc { min hr a b c } {
  cMotion_abstract_gc
}

# flush all of the abstracts to disk
# this was created for changing languages on the fly. If you're using this
# for some other reason, then you might want to be sure.
proc cMotion_abstract_flush { } {
  global cMotionSettings cMotion_abstract_contents
  global cMotion_abstract_languages
  set lang $cMotionSettings(deflang)
  set abstracts [array names cMotion_abstract_contents]
  foreach abstract $abstracts {
    set storedLang $cMotion_abstract_languages($abstract)
    if { $abstract != "dummy" && $storedLang == $lang } {
      cMotion_abstract_save $abstract
      unset cMotion_abstract_contents($abstract)
      unset cMotion_abstract_languages($abstract)
    }
  }
  set cMotion_abstract_contents(dummy) ""
  set cMotion_abstract_languages(dummy) ""
  set cMotion_abstract_timestamps(dummy) 1
  set cMotion_abstract_ondisk [list]
}

# this loads language abstracts for the current language in cMotionSettings
proc cMotion_abstract_revive_language { } {
  global cMotionSettings cMotionData
  global cMotion_abstract_contents cMotionLocal

  set lang $cMotionSettings(deflang)

  cMotion_putloglev 2 * "cMotion: reviving language ($lang) abstracts"
  set languages [split $cMotionSettings(languages) ","]
  # just check if it's ok to use this language
  set ok 0
  foreach language $languages {
    if { $lang == $language } {
      set ok 1
    }
  }
  if { $ok != 1 } {
    cMotion_putloglev 2 * "cMotion: language not found, cannot revive"
    return -1
  }
  # if the default abstracts exists, use it first
  if { [file exists "$cMotionData/abstracts/$lang/abstracts.tcl"] } {
		cMotion_putloglev d * "loading system abstracts for lang $lang"
    catch {
      source "$cMotionData/abstracts/$lang/abstracts.tcl"
    }
  } else {
    cMotion_putloglev 2 * "cMotion: language default abstracts not found"
  }
	# then we need to load any others
	#TODO: should this be cMotionLocal not cMotionData?
	set files [glob -nocomplain "$cMotionData/abstracts/$lang/*.txt"]
	if { [llength $files] > 0} {
		foreach f $files {
			set pos [expr [string last "/" $f] + 1]
			set dot [expr [string last ".txt" $f] - 1]
			set abstract [string range $f $pos $dot]
			cMotion_putloglev 2 * "checking $abstract"
			set len 0
			catch { set len [llength $cMotion_abstract_contents($abstract)] } val
			if { $val != "$len" } {
				cMotion_abstract_load $abstract
			}
		}
	}

	# load the local abstracts
	cMotion_putloglev d * "looking for local abstracts..."
	if [file exists "$cMotionLocal/abstracts/$lang/abstracts.tcl"] {
		cMotion_putloglev d * "found local abstracts.tcl for $lang, loading"
		catch {
			source "$cMotionLocal/abstracts/$lang/abstracts.tcl"
		}
	}
}

## Filters
# filter out stuff from an abstract
proc cMotion_abstract_filter { abstract filter_text } {
	global cMotion_abstract_contents cMotion_abstract_ondisk

  set index [lsearch -exact $cMotion_abstract_ondisk $abstract]
	if {$index > -1} {
		cMotion_abstract_load $abstract
	}
	
	set contents [list]
	catch {
		set contents $cMotion_abstract_contents($abstract)
	}

	if {[llength $contents] == 0} {
		cMotion_putloglev d * "can't get contents for $abstract"
		return
	}

	set new_contents [list]
	set initial_size [llength $contents]

	foreach element $contents {
		cMotion_putloglev 2 * "considering $element for filtering"
		if [regexp -nocase $filter_text $element] {
			cMotion_putloglev 1 * "abstract $abstract element $element matches filter, dropping"
			continue
		}
		lappend new_contents $element
	}

	set new_size [llength $new_contents]
  set diff [expr $initial_size - $new_size]
	cMotion_putloglev d * "abstract $abstract reduced by $diff items with filter $filter_text"

	if {$diff > 0} {
		set cMotion_abstract_contents($abstract) $new_contents
		cMotion_abstract_save $abstract
	}
}

# apply a filter to an abstract, if it has one defined
proc cMotion_abstract_apply_filter { abstract } {
	global cMotion_abstract_filters

	set filter ""
	catch {
		set filter $cMotion_abstract_filters($abstract)
	}
	if {$filter == ""} {
		return
	}

	cMotion_abstract_filter $abstract $filter
}

# register a filter for an abstract
proc cMotion_abstract_add_filter { abstract filter_text } {
	global cMotion_abstract_filters

	set cMotion_abstract_filters($abstract) $filter_text
	cMotion_putloglev d * "registered filter /$filter_text/ for abstract $abstract"

	# apply it now
	cMotion_abstract_apply_filter $abstract
}

# nuke all filters
proc cMotion_abstract_flush_filters { } {
	global cMotion_abstract_filters

	unset cMotion_abstract_filters
	set cMotion_abstract_filters(dummy) ""
}

# implementation-independent way to get all filters
proc cMotion_abstract_list_filters { } {
	global cMotion_abstract_filters
	return $cMotion_abstract_filters
}


bind time - "* * * * *" cMotion_abstract_auto_gc

# we have to revive at least one language
cMotion_abstract_revive_language

cMotion_putloglev d * "abstract module loaded"
