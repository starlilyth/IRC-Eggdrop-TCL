## cMotion plugin: interaction handlers

cMotion_plugin_add_action "zzz-failsafe" {^(.+?)s?( at|with)? %botnicks} 100 cMotion_plugin_action_failsafe "en"
cMotion_plugin_add_action "aaa-autogender" {[a-z]+s (his|her) } 100 cMotion_plugin_action_autolearn_gender "en"
proc cMotion_plugin_action_failsafe { nick host handle channel text } {
  regexp {^([^ ]+) ((across|near|at|with|to|against|from|over|under|in|on|next to) )?} $text matches verb dir
  if {$verb == ""} {
    return 2
  }
  cMotion_plugins_settings_set "action:failsafe" "last" "nick" "moo" $nick
	#try to figure out something general about this action
	if [regexp -nocase {(hug(gle)?|p[ae]t|rub|like|<3|sniff|smell|nibble|tickle)s?} $verb] {
		cMotionDoAction $channel $nick "%VAR{failsafe_nice}"
		cMotionGetHappy
		driftFriendship $nick 1
		return 1
	}
	if [regexp -nocase "(squashes|squishes|squee+zes)" $verb] {
		cMotionDoAction $channel $nick "%VAR{squeezeds}"
		cMotionGetHappy
		driftFriendship $nick 1
		return 1
	}
	if [regexp -nocase "(eyes|looks|stares)" $verb] {
		cMotionDoAction $channel $nick "%VAR{whats}"
		return 1
	}
	set whee [rand 10]
	if {$whee > 5} {
  	cMotionDoAction $channel $nick "%VAR{failsafes_a}"
  } else {
  	cMotionDoAction $channel $verb "%VAR{failsafes_b}" $dir
  }
  return 1
}
proc cMotion_plugin_action_autolearn_gender { nick host handle channel text } {
	if {$handle == "*"} {
		return 0
	}
	set gender [getuser $handle XTRA gender]
	if [regexp -nocase {[a-z]+s (his|her) } $text matches pronoun] {
		set pronoun [string tolower $pronoun]
		if {$pronoun == "his"} {
			if {$gender != ""} {
				if {$gender == "male"} {
					return 0
				} else {
					cMotion_putloglev 3 * "would learn gender for $nick as male, but they're already female!"
					return 0
				}
			}
			cMotion_putloglev d * "learning gender = male for $handle (via $nick)"
			setuser $handle XTRA gender male
			return 0
		} else {
			if {$gender != ""} {
				if {$gender == "female"} {
					return 0
				} else {
					cMotion_putloglev 3 * "would learn gender for $nick as female, but they're already male!"
					return 0
				}
			}
			cMotion_putloglev d * "learning gender = female for $handle (via $nick)"
			setuser $handle XTRA gender female
			return 0
		}
	}
	return 0
}
cMotion_abstract_register "failsafe_nice"
cMotion_abstract_batchadd "failsafe_nice" { "mmm" "%VAR{smiles}" "%VAR{smiles}%|/gives %% a %VAR{sillyThings}" }

cMotion_abstract_register "failsafes_a"
cMotion_abstract_batchadd "failsafes_a" { "%VAR{rarrs}" "%REPEAT{3:7:m}" "%VAR{thanks}" "what" "/loves it" "/passes it on to %ruser" "/. o O ( ? )" }

cMotion_abstract_register "failsafes_b"
cMotion_abstract_batchadd "failsafes_b" { "/%% %2 %SETTING{action:failsafe:last:nick:moo} back with a %VAR{sillyThings}" "/%% %2 %SETTING{action:failsafe:last:nick:moo}" "/%VERB{%VAR{sillyThings}{strip}} %2 %SETTING{action:failsafe:last:nick:moo} in return" }

cMotion_abstract_register "squeezeds"
cMotion_abstract_batchadd "squeezeds" { "/pops" "/bursts" "/deflates" "%VAR{smiles}" }

cMotion_abstract_register "whats"
cMotion_abstract_batchadd "whats" { "what?" "hmm?" "hello? yes?" "er... they did it%|/points at %ruser" "/stares back" }
