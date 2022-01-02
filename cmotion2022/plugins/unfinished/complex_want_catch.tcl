## cMotion plugin: want catcher
#
# Jolly sneaky.. if someone wants something, we'll remember it for ourselves :)
#
# $Id: complex_want_catch.tcl 843 2007-08-28 15:06:29Z james $
#
# vim: fdm=indent fdn=1

###############################################################################
# This is a cMotion plugin
# Copyright (C) James Michael Seward 2000-2002
#
# This program is covered by the GPL, please refer the to LICENCE file in the
# distribution; further information can be found in the headers of the scripts
# in the modules directory.
###############################################################################

cMotion_plugin_add_complex "want-catch" "i (want|need) (.+)" 100 cMotion_plugin_complex_want_catcher "en"
cMotion_plugin_add_complex "mmm-catch" {^mm+[,. ]*(.+)} 100 cMotion_plugin_complex_mmm_catcher "en"
cMotion_plugin_add_complex "plusplus-catch" {^(.+)\+{2}$} 100 cMotion_plugin_complex_plusplus_catcher "en"
cMotion_plugin_add_complex "minmin-catch" {^(.+)-{2}$} 100 cMotion_plugin_complex_minmin_catcher "en"
cMotion_plugin_add_complex "zzz-noun-catch" {\m(?:a|an|the) ([[:alpha:]]+)} 100 cMotion_plugin_complex_noun_catcher "en"

proc cMotion_plugin_complex_want_catcher { nick host handle channel text } {
  if [regexp -nocase "i (want|need) (?!to)(.+? )" $text matches verb item] {
    #that's a negative lookahead ---^
    cMotion_abstract_add "sillyThings" $item
    if {[rand 100] > 95} {
    	cMotionDoAction $channel "" "%VAR{gotone}"
			return 1
    }
	}
}

proc cMotion_plugin_complex_mmm_catcher { nick host handle channel text } {
	global botnicks
  if [regexp -nocase {^mm+[,.]* (.+)} $text matches item] {
    
    if [regexp -nocase "\ycMotion|$botnicks\y" $item] {
    	cMotionDoAction $channel "" "%VAR{wins}"
    	return 1
    }
    
    cMotion_abstract_add "sillyThings" $item
	
		if {[rand 100] > 95} {
				cMotionDoAction $channel $item "%VAR{betters}"
				return 1
		}
	}
}


proc cMotion_plugin_complex_plusplus_catcher { nick host handle channel text } {
	global botnicks
  if [regexp -nocase {^(.+)\+{2}$} $text matches item] {
    
    if [regexp -nocase "\ycMotion|$botnicks\y" $item] {
    	cMotionDoAction $channel "" "%VAR{wins}"
    	return 1
    }
    
    cMotion_abstract_add "sillyThings" $item
	
		if {[rand 100] > 95} {
				cMotionDoAction $channel $item "%VAR{betters}"
				return 1
		}
	}
}

proc cMotion_plugin_complex_minmin_catcher { nick host handle channel text } {
  global botnicks
  if [regexp -nocase {^(.+)-{2}$} $text matches item] {

    if [regexp -nocase "\ycMotion|$botnicks\y" $item] {
      cMotionDoAction $channel "" "%VAR{unsmiles}"
      return 1
    }

    cMotion_abstract_add "sillyThings" $item

    if {[rand 100] > 95} {
        cMotionDoAction $channel $item "%% = %VAR{PROM}"
        return 1
    }
  }
}


proc cMotion_plugin_complex_noun_catcher { nick host handle channel text } {
  if [regexp -nocase {\m(a|an|the|some) ([[:alpha:]]+)( [[:alpha:]]+\M)?} $text matches prefix item second] {
    set item [string tolower $item]

    if [regexp "(ly)$" $item] {
      return 0
    }

    if [regexp "(ing|ed)$" $item] {
      if {$second == ""} {
        return 0
      }
      append item $second
    }

    set prefix [string tolower $prefix]
    if {$prefix == "the"} {
      if {[string range $item end end] == "s"} {
        set prefix "some"
      } else {
        set prefix "a"
      }
    }

    cMotion_abstract_add "sillyThings" "$prefix $item"
		return 0
  }
}

cMotion_abstract_register "gotone"
cMotion_abstract_batchadd "gotone" [list "I've already got one%|%BOT\[are you sure?\]%|yes yes, it's very nice" "I already have one of those." "I had one of them the other week. They're very nice, aren't they?"]

cMotion_abstract_register "betters"
cMotion_abstract_batchadd "betters" [list "mm%REPEAT{1:5:m}, %VAR{sillyThings}{strip}" "%VAR{sillyThings}{strip} > %%" "%% < %VAR{sillyThings}{strip}" "%%++"]
