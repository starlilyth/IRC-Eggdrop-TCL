# cMotion howareyou plugin	
## wellbeing question targeted at me
cMotion_abstract_register "answerWellbeing"
cMotion_abstract_batchadd "answerWellbeing" {
    "fine thanks"
    "not bad, yourself?"
    "I'm much better now"
    "better now that I have %VAR{sillyThings}"
    "oh the pain, the pain, the....I'm fine thanks"
    "I'm not bad thanks, how're you?"
}
cMotion_plugin_add_text  "howareyou1"  "^$botnicks,?:? how( a|')?re (you|ya)( today|now)?\\??$"  100  cMotion_plugin_text_wellbeing  "en"
cMotion_plugin_add_text  "howareyou2"  "^how( a|')?re (you|ya).*$botnicks \\?"  100  cMotion_plugin_text_wellbeing  "en"
#cMotion_plugin_add_text  "howareyou3"  "^$botnicks,?:? (how('?s|z) it going|what'?s up|'?sup)\\??$"  100  cMotion_plugin_text_wellbeing  "en"
#cMotion_plugin_add_text  "howareyou4"  "^(how('?s|z) it going|what'?s up|'?sup),? $botnicks\\??"  100  cMotion_plugin_text_wellbeing  "en"

proc cMotion_plugin_text_wellbeing { nick host handle channel text } {
    cMotionDoAction $channel $nick "%VAR{answerWellbeing}"

#    global mood
#    driftFriendship $nick 2
#    set moodString ""
#    #if {![cMotionTalkingToMe $text]} { return 0 }
#    if {[getFriendship $nick] > 75} {
#	append moodString "Awww, thanks for asking, $nick, "
#    } else {
#	if {[getFriendship $nick] < 35} {
#	    append moodString "What do you care that "
#	}
#   }
#    append moodString "I'm feeling "
#    set moodIndex 0
#    set done 0
#    cMotion_putloglev 4 * "lonely $mood(lonely)"    
#    if {$mood(lonely) > 5} {
#	append moodString "a bit lonely"
#	incr moodIndex -2
#	incr done 1
#    }
#    cMotion_putloglev 4 * "happy $mood(happy)"        
#    if {$mood(happy) > 3} {
#	if {$done > 0} {
#	    append moodString ", "
#	}
#	append moodString "happy"
#	incr moodIndex 1
#	incr done 1
#    }
#    if {$mood(happy) < 0} {
#	if {$done > 0} {
#	    append moodString ", "
#	}
#	append moodString "sad"
#	incr moodIndex -3
#	incr done 1
#    }
#    cMotion_putloglev 4 * "stoned $mood(stoned)"    
#    if {$mood(stoned) > 5} {
#	if {$done > 0} {
#	    append moodString ", "
#	}
#	append moodString "stoned off my tits"
#	incr moodIndex 2
#	incr done 1
#    }
#    if {$done < 1} {
#	append moodString "pretty average :/"
#    } else {
#	if {$moodIndex >= 0} {
#	    append moodString " :)"
#	} else {
#	    append moodString " :("
#	}
#    }
#    cMotionDoAction $channel $nick "%%: $moodString"

    return 1
}
