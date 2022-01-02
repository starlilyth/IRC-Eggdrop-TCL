## cMotion output plugin: colloquial
#  Attempt to make contractions etc similar to real people

cMotion_plugin_add_output "colloq" cMotion_plugin_output_colloq 1 "en"
proc cMotion_plugin_output_colloq { channel line } {
  global cMotionSettings
  set colloq_rate $cMotionSettings(colloq)
  set oldLine $line
  if [cMotion_plugin_output_colloq_chance $colloq_rate] {
    regsub -all -nocase "\mshould( have|\'ve| of)\M" $line "%VAR{colloq_shouldhave}" line
  }
  if [cMotion_plugin_output_colloq_chance $colloq_rate] {
    regsub -all -nocase "\mshouldn't( have|\'ve| of)\M" $line "%VAR{colloq_shouldhavenot}" line
  }
  if [cMotion_plugin_output_colloq_chance $colloq_rate] {
    regsub -all -nocase "sort of" $line "sorta" line
    regsub -all -nocase "something" $line "smthn" line
  }
  if [cMotion_plugin_output_colloq_chance $colloq_rate] {
    regsub -all -nocase "cheap" $line "cheep" line
    regsub -all -nocase "seam" $line "seem" line
    regsub -all -nocase "mean" $line "meen" line
  }
  if [cMotion_plugin_output_colloq_chance $colloq_rate] {
    regsub -all -nocase "exactly" $line "zactly" line
    regsub -all -nocase "separate" $line "seperate" line
    regsub -all -nocase "definitely" $line "definetely" line
  }
  if [cMotion_plugin_output_colloq_chance $colloq_rate] {
    regsub -all -nocase {\myou\M} $line "%VAR{colloq_you}" line
    regsub -all -nocase {\myour\M} $line "%VAR{colloq_your}" line
  }
  if [cMotion_plugin_output_colloq_chance $colloq_rate] {
    regsub -all -nocase "n't" $line "nt" line
  }
  if [cMotion_plugin_output_colloq_chance $colloq_rate] {
    if {![regexp "\.$" $line]} {
      append line "."
    }
  }
  #let's break some words
  global colloq_negative
  set newLine ""
  set words [split $line { }]
  foreach word $words {
    if {[cMotion_plugin_output_colloq_chance $colloq_rate]} {
      regsub -nocase {\m(dis|anti|un|im)} $word [pickRandom $colloq_negative] word
    }
    append newLine "$word "
  }
  set line $newLine
  #don't waste time updating if the line didn't change
  if {$line == $oldLine} {
    return $oldLine
  }
  return [string trim [cMotionDoInterpolation $line "" ""]]
}
#random chance test
proc cMotion_plugin_output_colloq_chance { freq } {
  if {[rand 1000] <= $freq} {
    return 1
  }
  return 0
}
set colloq_shouldhave {
  "should've"
  "should of"
}
set colloq_shouldhavenot {
  "shouldnt've"
  "shouldn't of"
  "shouldnt of"
  "shouldnt have"
}
set colloq_you {
  "u"
  "ya"
}
set colloq_your {
  "ur"
}
set colloq_negative {
  "dis"
  "un"
  "anti"
  "im"
}
