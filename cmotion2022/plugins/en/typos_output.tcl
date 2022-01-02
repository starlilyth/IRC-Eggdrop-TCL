## cMotion output plugin: typos (qwerty :)
proc cMotion_plugin_output_typos_do { line } {
	cMotion_putloglev 4 * "cMotion_plugin_output_typos_do $line"
	global cMotionSettings
  set typochance $cMotionSettings(typos)
  if {[rand 100] <= $typochance} {
    set line [string map -nocase { is si ome oem ame aem oe eo } $line ]
    set typochance [expr $typochance * 0.6]
  }
  if {[rand 100] <= $typochance} {
    set line [string map -nocase { aid iad ers ars ade aed ite eit } $line ]
    set typochance [expr $typochance * 0.6]
  }
  if {[rand 100] <= $typochance} {
    set line [string map -nocase { hi ih or ro ip pi ho oh } $line ]
    set typochance [expr $typochance * 0.6]
  }
  if {[rand 100] <= $typochance} {
    set line [string map -nocase { he eh re er in ni lv vl sec sex } $line ]
    set typochance [expr $typochance * 0.6]
  }
  if {[rand 100] <= $typochance} {
    set line [string map -nocase { ir ri ou uo ha ah ui iu ig gi nd dn} $line ]
    set typochance [expr $typochance * 0.6]
  }
  #go though the line one char at a time
  set chars [split $line {}]
  set newLine ""
  set typochance [expr $cMotionSettings(typos) / 2]
  foreach char $chars {
    if [string match -nocase "l" $char] {
      if {[rand 100] < $typochance} {
        append newLine ";l"
        cMotion_plugin_output_typos_adderror "" "-;"
				continue
      }
    }
    if [string match -nocase "a" $char] {
      if {[rand 100] < $typochance} {
        append newLine "sa"
        cMotion_plugin_output_typos_adderror "" "-s"
				continue
      }
    }
    if [string match -nocase "s" $char] {
      if {[rand 100] < $typochance} {
        append newLine "sd"
        cMotion_plugin_output_typos_adderror "" "-d"
				continue
      }
    }
    if [string match -nocase "e" $char] {
      if {[rand 100] < $typochance} {
        append newLine "re"
        cMotion_plugin_output_typos_adderror "" "-r"
				continue
      }
    }
    if [string match -nocase "d" $char] {
      if {[rand 100] < $typochance} {
        append newLine "df"
        cMotion_plugin_output_typos_adderror "" "-f"
				continue
      }
    }
    if [string match -nocase "z" $char] {
      if {[rand 100] < $typochance} {
        append newLine "zx"
        cMotion_plugin_output_typos_adderror "" "-x"
				continue
      }
    }
    if [string match -nocase "z" $char] {
      if {[rand 100] < $typochance} {
        append newLine "z\\"
        cMotion_plugin_output_typos_adderror "" "-\\"
				continue
      }
    }
    if [string match -nocase " " $char] {
      if {[rand 100] < $typochance} {
        cMotion_plugin_output_typos_adderror "" "+space"
				continue
      }
    }
    if [string match -nocase ")" $char] {
      if {[rand 100] < $typochance} {
        append newLine ")_"
        cMotion_plugin_output_typos_adderror "" "-_"
				continue
      }
    }
    #else...
    append newLine $char
  }
	cMotion_putloglev 4 * "returning $newLine"
  return $newLine
}

## Make Typos
#    Attempt to make typos similar to human typing errors
#
proc cMotion_plugin_output_typos { channel line } {
	cMotion_putloglev 4 * "cMotion_plugin_output_typos $channel $line"
  global cMotionSettings 
  set typochance $cMotionSettings(typos)
  set oldLine $line
	if {[rand 100] > $typochance} {
		#don't typo at all
		return $line
	}
  #reset typos
  cMotion_plugins_settings_set "output:typos" "typos" "" "" ""
  cMotion_plugins_settings_set "output:typos" "typosDone" "" "" ""
  set newLine ""	
  #split words
	set line [string trim $line]
  set words [split $line " "]
  #typo words
	cMotion_putloglev 4 * "words list is: $words"
  foreach word $words {
		cMotion_putloglev 4 * "typo_do'ing $word"
    append newLine [cMotion_plugin_output_typos_do $word]
		append newLine " "
  }
  set line [string trim $newLine]
  if {[rand 100] < $typochance} {
    set tmpchar [pickRandom {"#" "]"}]
    append line $tmpchar
    cMotion_plugin_output_typos_adderror "" "-$tmpchar"
		cMotion_putloglev 1 * "typoing a character onto the end of the line"
  }
  if {[rand 100] < $typochance} {
    set line [string toupper $line]
    cMotion_plugin_output_typos_adderror "" "-caps"
		cMotion_putloglev 1 * "typoing in all caps"
  }
  if {[string trim $oldLine] != [string trim $line]} {
    cMotion_plugins_settings_set "output:typos" "typosDone" "" "" "yes"
  }
  return $line
}
proc cMotion_plugin_output_typos_adderror { channel err } {
  set currentErr [cMotion_plugins_settings_get "output:typos" "typos" "" ""]
  if {$currentErr == ""} {
    set currentErr $err
  } else {
    append currentErr " $err"
  }
  cMotion_plugins_settings_set "output:typos" "typos" "" "" $currentErr
}
cMotion_abstract_register "typoFix"
cMotion_abstract_batchadd "typoFix" { "oops" "oops %SETTING{output:typos:typos:_:_}" "%colen" "ffs" "grrr %SETTING{output:typos:typos:_:_}" "%SETTING{output:typos:typos:_:_}" "-typo" "/butterfingers"
}
cMotion_plugin_add_output "typos" cMotion_plugin_output_typos 1 "all"
