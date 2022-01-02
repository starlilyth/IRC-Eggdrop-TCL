# cMotion: mgmt plugin file for abstracts
proc cMotion_plugin_mgmt_abstract { handle { arg "" }} {
  #abstract show <name>
  if [regexp -nocase {show ([^ ]+)} $arg matches name] {
    set result [cMotion_abstract_all $name]
    cMotion_putadmin "Abstract $name has [llength $result] items."
    set i 0
    foreach a $result {
      cMotion_putadmin "$i: $a"
      incr i
    }
    return 0
  }
  #abstract gc
  if [regexp -nocase {gc} $arg matches] {
    cMotion_putadmin "Garbage collecting..."
    cMotion_abstract_gc
    return 0
  }
  #status
  if [regexp -nocase {status} $arg] {
    global cMotion_abstract_contents cMotion_abstract_timestamps cMotion_abstract_max_age
    global cMotion_abstract_ondisk
    set mem 0
    set disk 0
    set handles [array names cMotion_abstract_contents]
    cMotion_putadmin "cMotion abstract info info:\r"
    foreach handle $handles {      
      set diff [expr [clock seconds]- $cMotion_abstract_timestamps($handle)]
      cMotion_putadmin "$handle: [llength [cMotion_abstract_all $handle]] items, $diff seconds since used"
      incr mem
    }
    foreach handle $cMotion_abstract_ondisk {
      cMotion_putadmin "$handle: on disk"
      incr disk
    }
    cMotion_putadmin "[expr $mem + $disk] total abstracts, $mem loaded, $disk on disk"
    return 0
  }
  if [regexp -nocase {info (.+)} $arg matches name] {
    set result [cMotion_abstract_all $name]
    cMotion_putadmin "Abstract $name has [llength $result] items.\r"
    return 0
  }
  if [regexp -nocase {delete (.+) (.+)} $arg matches name index] {
    cMotion_putadmin "Deleting element $index from abstract $name...\r"
    cMotion_abstract_delete $name $index
    return 0
  }
	if [regexp -nocase {purge ([^ ]+) (.+)} $arg matches name re] {
		cMotion_putadmin "Purging abstract $name for elements matching /$re/"
		cMotion_abstract_filter $name $re
		return 0
	}
	if [regexp -nocase "flush" $arg] {
		cMotion_abstract_flush
		cMotion_putadmin "Flushing all abstracts to disk..."
		return 0
	}
	if [regexp -nocase "filter (\[a-z\]+)( (\[^ \]+)( .+)?)?" $arg matches cmd parms abstract filter] {
		switch $cmd {
			"list" {
				global cMotion_abstract_filters
				set filternames [array names cMotion_abstract_filters]
				foreach f $filternames {
					if {$f == "dummy"} {
						continue
					}
					cMotion_putadmin "$f: $cMotion_abstract_filters($f)"
				}
				return
			}

			"purge" {
				cMotion_abstract_flush_filters
				cMotion_putadmin "Flushed all filters."
				return
			}

			"add" {
				if {$abstract == ""} {
					cMotion_putadmin "Missing abstract"
					return
				}

				if {$filter == ""} {
					cMotion_putadmin "Missing filter"
					return
				}

				set filter [string trim $filter]

				cMotion_abstract_add_filter $abstract $filter
				cMotion_putadmin "Added filter /$filter/ for abstract $abstract"
				return
			}

			"apply" {
				if {$abstract == ""} {
					cMotion_putadmin "Missing abstract name"
					return
				}
				cMotion_putadmin "Applying filter for $abstract (if one exists)"
				cMotion_abstract_apply_filter $abstract
				return
			}
		}
	}
  #all else fails, list help
	cMotion_putadmin "Try .cmotion help abstract"
  return 0
}

proc cMotion_plugin_mgmt_abstract_help { } {
	cMotion_putadmin "Manage abstracts in cMotion."
	cMotion_putadmin "  .cMotion abstract info <abstract>"
	cMotion_putadmin "    Find out info about an abstract"
	cMotion_putadmin "  .cMotion abstract show <abstract>"
	cMotion_putadmin "    List the contents of an abstract (Potentially much output!)"
	cMotion_putadmin "  .cMotion abstract gc"
	cMotion_putadmin "    Force a garbage collection of abstracts (pages out unused ones)"
	cMotion_putadmin "  .cMotion abstract status"
	cMotion_putadmin "    List all abstracts and their status (Much ouput!)"
	cMotion_putadmin "  .cMotion abstract delete <abstract> <index>"
	cMotion_putadmin "    Delete an element from an abstract"
	cMotion_putadmin "    Index is 0-based; use the show command to find entries"
	cMotion_putadmin "  .cMotion abstract purge <abstract> <regexp>"
	cMotion_putadmin "    Remove all matching elements from an abstract (dangerous)"
	cMotion_putadmin "  .cMotion abstract flush"
	cMotion_putadmin "    Force all abstracts to be flushed to disk"
	cMotion_putadmin "  .cMotion abstract filter add <abstract> <regexp>"
	cMotion_putadmin "    Add a filter to an abstract"
	cMotion_putadmin "  .cMotion abstract filter list"
	cMotion_putadmin "    List all abstract filters"
	cMotion_putadmin "  .cMotion abstract filter purge"
	cMotion_putadmin "    Purge all filters"
	cMotion_putadmin "  .cMotion abstract filter apply <abstract>"
	cMotion_putadmin "    For an abstract to be filtered now"
	return 0
}
# register the plugin
cMotion_plugin_add_mgmt "abstract" "^abstract" n "cMotion_plugin_mgmt_abstract" "any" "cMotion_plugin_mgmt_abstract_help"
