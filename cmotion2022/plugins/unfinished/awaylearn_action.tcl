## cMotion plugin: away reason learning
#
# $Id: action_complex_away_learn.tcl 662 2006-01-07 23:27:52Z james $
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

cMotion_plugin_add_action_complex "away-learn" "^(is )?(away|gone)" 50 cMotion_plugin_complex_action_away_learn "en"

#make sure this abstract is registered
cMotion_abstract_register "randomAways"

proc cMotion_plugin_complex_action_away_learn { nick host handle channel text } {
  #autoaway
  if [regexp -nocase {(auto[ -]?away)|idle} $text] {
    #don't want to learn this
    return 0
  }

  if [regexp -nocase {^(is )?(away|gone)[^a-z0-9]*([a-z0-9 ]+)} $text matches skip1 skip2 reason] {
    cMotion_putloglev d * "learning away reason: $reason"
    cMotion_abstract_add "randomAways" [string tolower $reason]
  }

  return 0
}
