## cMotion plugin: question handlers
# great idea, but 1) too geared towards answering the sex qs (cleaned up some) and 
# 2) conflicts with more specific plugins. 
# Needs to be a rating system or something for best regexp match


cMotion_plugin_add_text "question" {[?>/]$} 100 cMotion_plugin_text_question "en"

proc cMotion_plugin_text_question { nick host handle channel text } {
  cMotion_putloglev 2 * "Question handler triggerred"
  global botnicks cMotionFacts

	if [regexp {\\o/} $text] {
		return
	}

  regsub {(.+)[>\/]$} $text {\1?} text

  cMotion_putloglev 3 * "Checking question for wellbeing"
  ## wellbeing question targeted at me
  if { [regexp -nocase "^$botnicks,?:? how( a|')?re (you|ya)( today|now)?\\??$" $text] ||
       [regexp -nocase "^how( a|')?re (you|ya).*$botnicks ?\\?" $text] ||
       [regexp -nocase "${botnicks}?:? ?(how('?s|z) it going|hoe gaat het|what'?s up|'?sup|how are you),?( ${botnicks})?\\?" $text]} {
      cMotion_plugin_text_wellbeing $nick $host $handle $channel $text 
      return 1
  }

  ## moved here from further down because it'd never be triggered otherwise   --szrof
  cMotion_putloglev 3 * "Checking question for 'what have'"
  ## What have question targeted at me
  if { [regexp -nocase "^$botnicks,?:? what ?have" $text] ||
       [regexp -nocase "^what ?have .* $botnicks ?\\?" $text] } {
    cMotion_plugin_text_question_whathave $nick $channel $host
    return 1
  }

  cMotion_putloglev 3 * "Checking question for 'which/what colour'"
  ## What have question targeted at me
  if { [regexp -nocase "^$botnicks,?:? wh(ich|at) ?colou?r" $text] ||
       [regexp -nocase "^wh(ich|at) ?colou?r .* $botnicks ?\\?" $text] } {
    cMotion_plugin_text_question_whatcolour $nick $channel $host
    return 1
  }

  cMotion_putloglev 3 * "Checking question for 'what are the odds'"
  ## What have question targeted at me
  if { [regexp -nocase "^$botnicks,?:? what ?(are|is|'?s|was|were) the (odds|chance|probability)" $text] ||
       [regexp -nocase "^what ?(are|is|'?s|was|were) the (odds|chance|probability) .* $botnicks ?\\?" $text] } {
    cMotion_plugin_text_question_whatodds $nick $channel $host
    return 1
  }

  cMotion_putloglev 3 * "Checking question for 'what'"
  ## What question targeted at me
  if { [regexp -nocase "what('?s)?(.+)" $text matches s question] ||
       [regexp -nocase "what('?s)? (.*)\\?" $text matches s question] } {
    set term ""
    if [regexp -nocase {what(\'?s| is| was) ([^ ]+)} $text matches ignore term] {
      set question "is $term"
    }
    if {($term == "") && (![cMotionTalkingToMe $text])} { return 0 }
    cMotion_plugin_text_question_what $nick $channel $host $question
    return 1
  }

  cMotion_putloglev 3 * "Checking question for 'with/at/against'"
  ## With/at/against who question targeted at me
  if { [regexp -nocase "^$botnicks,?:? (with|at|against|by) who" $text ma mb prop] ||
       [regexp -nocase "^(with|at|against|by) who .* $botnicks ?\\?" $text ma prop ma] } {
    cMotion_plugin_text_question_with $nick $channel $host $prop
    return 1
  }

  cMotion_putloglev 3 * "Checking question for 'who'"
  ## Who question targeted at me
  if { [regexp -nocase "^$botnicks,?:? who(se|'s)? " $text matches bot owner] ||
       [regexp -nocase "^who(se|'s)? .* $botnicks ?\\?" $text matches owner] } {
    cMotion_plugin_text_question_who $nick $channel $host $owner
    return 1
  }

  cMotion_putloglev 3 * "Checking question for 'want'"
  ## Want question targetted at me
  if { [regexp -nocase "^$botnicks,?:? do you (need|want) (a|these|this|some|the|those|that)" $text] ||
        [regexp -nocase "^do you (want|need) (a|these|this|some|the|those|that) .* $botnicks ?\\?" $text] ||
        [regexp -nocase "^$botnicks,?:? would you like" $text] ||
        [regexp -nocase "^would you like .+ $botnicks" $text] ||
        [regexp -nocase "^$botnicks,?:? (do )?((yo)?u )?wanna" $text] ||
        [regexp -nocase "^(do )?((yo)?u )?wanna .+ $botnicks" $text] } {
      cMotion_plugin_text_question_want $nick $channel $host
      return 1
  }

  cMotion_putloglev 3 * "Checking question for 'why'"
  ## Why question targeted at me
  if { [regexp -nocase "^$botnicks,?:? why" $text] ||
       [regexp -nocase "why.* $botnicks ?\\?" $text] } {
    cMotion_plugin_text_question_why $nick $channel $host
    return 1
  }

  cMotion_putloglev 3 * "Checking question for 'where'"
  ## Where question targeted at me
  if { [regexp -nocase "^$botnicks,?:? where" $text] ||
       [regexp -nocase "^where .* $botnicks ?\\?" $text] } {
    cMotion_question_where $nick $channel $host
    return 1
  }

  cMotion_putloglev 3 * "Checking question for 'how many'"
  ## How many question targeted at me
  if { [regexp -nocase "^$botnicks,?:? how ?many" $text] ||
       [regexp -nocase "^how ?many .* $botnicks ?\\?" $text] } {
    cMotion_plugin_text_question_many $nick $channel $host
    return 1
  }

  cMotion_putloglev 3 * "Checking question for 'how long'"
  ## How many question targeted at me
  if { [regexp -nocase "^$botnicks,?:? how ?long" $text] ||
       [regexp -nocase "^how ?long .* $botnicks ?\\?" $text] } {
    cMotion_plugin_text_question_long $nick $channel $host
    return 1
  }

  cMotion_putloglev 3 * "Checking question for 'how old'"
  ## How many question targeted at me
  if { [regexp -nocase "^$botnicks,?:? how ?old" $text] ||
       [regexp -nocase "^how ?old .* $botnicks ?\\?" $text] } {
    cMotion_plugin_text_question_age $nick $channel $host
    return 1
  }

  cMotion_putloglev 3 * "Checking question 'how big'"
  ## How big question targeted at me
  if { [regexp -nocase "^$botnicks,?:? how ?big" $text] ||
       [regexp -nocase "^how ?big .* $botnicks ?\\?" $text] } {
    cMotion_plugin_text_question_big $nick $channel $host
    return 1
  }

  cMotion_putloglev 3 * "Checking question for 'when'"
  ## When question targeted at me
  if { [regexp -nocase "^$botnicks,?:? (when|what time)" $text] ||
       [regexp -nocase "^(when|what time) .* $botnicks ?\\?" $text] } {
    cMotion_plugin_text_question_when $nick $channel $host
    return 1
  }

  cMotion_putloglev 3 * "Checking question for 'how much'"
  ## How many question targeted at me
  if { [regexp -nocase "^$botnicks,?:? how ?much" $text] ||
       [regexp -nocase "^how ?much .* $botnicks ?\\?" $text] } {
    cMotion_plugin_text_question_much $nick $channel $host
    return 1
  }

  cMotion_putloglev 3 * "Checking question for 'how'"
  ## How question targeted at me
  if { [regexp -nocase "^$botnicks,?:? how" $text] ||
       [regexp -nocase "^how .* $botnicks ?\\?" $text] } {
    cMotion_plugin_text_question_how $nick $channel $host
    return 1
  }

  cMotion_putloglev 3 * "Checking question for some general questions"
  # some other random responses, handled here rather than simple_general so as not to break other code
    if [regexp -nocase  "^${botnicks}:?,? do(n'?t)? you (like|want|find .+ attractive|get horny|(find|think) .+ (is ?)horny|have|keep)" $text] {
    cMotion_putloglev 2 * "$nick general question"
    cMotionDoAction $channel $nick "%VAR{yesnos}"
    return 1
  }

  cMotion_putloglev 3 * "Checking question for 'have you'"
  ## Have you question targeted at me
  if { [regexp -nocase "^$botnicks,?:? have ?you" $text] ||
       [regexp -nocase "^have ?you .* $botnicks ?\\?" $text] } {
    cMotion_plugin_text_question_haveyou $nick $channel $host
    return 1
  }

  cMotion_putloglev 3 * "Checking question for 'did you'"
  ## Did you question targeted at me
  if { [regexp -nocase "^$botnicks,?:? did ?you" $text] ||
       [regexp -nocase "^did ?you .* $botnicks ?\\?" $text] } {
    cMotion_plugin_text_question_didyou $nick $channel $host
    return 1
  }

  cMotion_putloglev 3 * "Checking question for 'will you'"
  ## Will you question targeted at me
  if { [regexp -nocase "^$botnicks,?:? will ?you" $text] ||
       [regexp -nocase "^will ?you .* $botnicks ?\\?" $text] } {
    cMotion_plugin_text_question_willyou $nick $channel $host
    return 1
  }

  cMotion_putloglev 3 * "Checking question for 'would you'"
  ## Would you question targeted at me
  if { [regexp -nocase "^$botnicks,?:? would ?you" $text] ||
       [regexp -nocase "^would ?you .* $botnicks ?\\?" $text] } {
    cMotion_plugin_text_question_wouldyou $nick $channel $host
    return 1
  }

  cMotion_putloglev 3 * "Checking question for 'can you'"
  ## Can you question targeted at me
  if { [regexp -nocase "^$botnicks,?:? can ?you" $text] ||
       [regexp -nocase "^can ?you .* $botnicks ?\\?" $text] } {
    cMotion_plugin_text_question_canyou $nick $channel $host
    return 1
  }

  cMotion_putloglev 3 * "Checking question for 'do you'"
  ## Do you question targeted at me
  if { [regexp -nocase "^$botnicks,?:? do ?you" $text] ||
       [regexp -nocase "^do ?you .* $botnicks ?\\?" $text] } {
    cMotion_plugin_text_question_doyou $nick $channel $host
    return 1
  }

  cMotion_putloglev 3 * "Checking question for 'is your'"
  ## Is your question targeted at me
  if { [regexp -nocase "^$botnicks,?:? is ?your" $text] ||
       [regexp -nocase "^is ?your .* $botnicks ?\\?" $text] } {
    cMotion_plugin_text_question_isyour $nick $channel $host
    return 1
  }
  
  # me .... ?
  if [regexp -nocase "^${botnicks}:?,? (.+)\\?$" $text ming ming2 question] {
    cMotion_putloglev 2 * "$nick final question catch"
    cMotionDoAction $channel $nick "%VAR{randomReplies}"
    return 1
  }

  # ... me?
  if [regexp -nocase "${botnicks}\\?$" $text bhar ming what] {
    cMotion_putloglev 2 * "$nick very final question catch"
    if { [rand 2] == 1 } {
      cMotionDoAction $channel $nick "%VAR{randomReplies}"
      return 1
    }
  }

  if [cMotionTalkingToMe $text] {
    cMotion_putloglev 2 * "$nick talkingtome catch"
    cMotionDoAction $channel $nick "%VAR{randomReplies}"
    return 1
  }
  return 0
}

proc cMotion_plugin_text_question_what { nick channel host question } {
    cMotion_putloglev 2 * "$nick what !$question! question"
    global cMotionInfo cMotionFacts cMotionOriginalInput
    #see if we know the answer to it
    if {$question != ""} {
      if [regexp -nocase {\ma/?s/?l\M} $question] {
        #asl?
        set age [expr [rand 20] + 13]
        cMotionDoAction $channel $nick "%%: $age/$cMotionInfo(gender)/%VAR{locations}"
        return 1
      }
      if [string match -nocase "*time*" $question] {
        #what time: redirect to when
        cMotion_plugin_text_question_when $nick $channel $host
        return 1
      }
      #let's try to process this with facts
      if [regexp -nocase {is ((an?|the) )?([^ ]+)} $question ignore ignore3 ignore2 term] {
        set term [string map {"?" ""} $term]
        catch {
          set term [string tolower $term]
          cMotion_putloglev 1 * "looking for what,$term"
          set answers $cMotionFacts(what,$term)
          #putlog $answers
          if {[llength $answers] > 0} {
            cMotion_putloglev 1 * "I know answers for what,$term"
            if {![cMotionTalkingToMe $cMotionOriginalInput]} {
              cMotion_putloglev 1 * "I wasn't asked directly"
              if {[rand 5] == 0} {
                return 1
              }
              cMotion_putloglev 1 * "... but I shall answer anyway."
            }
          }
          set answer [pickRandom $answers]
          #remove any timestamp
          regsub {(_[0-9]+_ )?(.+)} $answer "\2" answer
          cMotionDoAction $channel [pickRandom $answers] "%VAR{question_what_fact_wrapper}"
          return 1
        } err
        if {$err == 1} {
          return 1
        }
      }
    }
    #generic answer to what
    if [cMotionTalkingToMe $cMotionOriginalInput] {
      cMotion_putloglev 2 * "Talking to me, so using generic answer"
      cMotionDoAction $channel $nick "%VAR{answerWhats}"
      return 1
    }
}

proc cMotion_plugin_text_question_when { nick channel host } {
  cMotion_putloglev 2 * "$nick When question"
  cMotionDoAction $channel $nick "%VAR{answerWhens}"
  return 1
}

proc cMotion_plugin_text_question_with { nick channel host prop } {
  cMotion_putloglev 2 * "$nick with question"
  set answer "$prop %VAR{answerWithWhos}"
  cMotionDoAction $channel $nick $answer
  return 1
}

proc cMotion_plugin_text_question_who { nick channel host owner } {
    cMotion_putloglev 2 * "$nick who question"
  if {$owner == "se"} {
    set line "%OWNER{%VAR{answerWhos}}"
  } else {
    set line "%VAR{answerWhos}"
  }
  cMotionDoAction $channel $nick "$line"
  return 1
}

proc cMotion_plugin_text_question_want { nick channel host } {
    cMotion_putloglev 2 * "$nick Want/need question"
    cMotionDoAction $channel $nick "%VAR{question_want_reply_wrapper}"
    return 1
}

proc cMotion_plugin_text_question_why { nick channel host } {
    cMotion_putloglev 2 * "$nick why question"
  cMotionDoAction $channel $nick "%VAR{answerWhys}"
  return 1
}

proc cMotion_plugin_text_question_many { nick channel host } {
    cMotion_putloglev 2 * "$nick how many question"
  cMotionDoAction $channel $nick "%VAR{answerHowmanys}"
  return 1
}

proc cMotion_plugin_text_question_how { nick channel host } {
    cMotion_putloglev 2 * "$nick how question"
  cMotionDoAction $channel $nick "%VAR{answerHows}"
  return 1
}

## begin sid's functions

proc cMotion_plugin_text_question_whathave { nick channel host } {
    cMotion_putloglev 2 * "$nick what have question"
  cMotionDoAction $channel $nick "%VAR{answerWhathaves}"
  return 1
}

proc cMotion_plugin_text_question_much { nick channel host } {
    cMotion_putloglev 2 * "$nick how much question"
  cMotionDoAction $channel $nick "%VAR{answerHowmanys}"
  return 1
}

proc cMotion_plugin_text_question_haveyou { nick channel host } {
    cMotion_putloglev 2 * "$nick have you question"
  cMotionDoAction $channel $nick "%VAR{answerHaveyous}"
  return 1
}

proc cMotion_plugin_text_question_didyou { nick channel host } {
    cMotion_putloglev 2 * "$nick did you question"
  cMotionDoAction $channel $nick "%VAR{answerDidyous}"
  return 1
}

proc cMotion_plugin_text_question_willyou { nick channel host } {
    cMotion_putloglev 2 * "$nick will you question"
  cMotionDoAction $channel $nick "%VAR{answerWillyous}"
  return 1
}

proc cMotion_plugin_text_question_wouldyou { nick channel host } {
    cMotion_putloglev 2 * "$nick would you question"
  cMotionDoAction $channel $nick "%VAR{answerWouldyous}"
  return 1
}

proc cMotion_plugin_text_question_areyou { nick channel host } {
    cMotion_putloglev 2 * "$nick are you question"
  cMotionDoAction $channel $nick "%VAR{answerAreyous}"
  return 1
}

proc cMotion_plugin_text_question_canyou { nick channel host } {
    cMotion_putloglev 2 * "$nick can you question"
  cMotionDoAction $channel $nick "%VAR{answerCanyous}"
  return 1
}

proc cMotion_plugin_text_question_doyou { nick channel host } {
    cMotion_putloglev 2 * "$nick do you question"
  cMotionDoAction $channel $nick "%VAR{answerDoyous}"
  return 1
}

proc cMotion_plugin_text_question_isyour { nick channel host } {
    cMotion_putloglev 2 * "$nick is your question"
  cMotionDoAction $channel $nick "%VAR{answerIsyours}"
  return 1
}

proc cMotion_plugin_text_question_whatcolour { nick channel host } {
    cMotion_putloglev 2 * "$nick what colour question"
  cMotionDoAction $channel $nick "%VAR{question_colour_wrapper}"
  return 1
}

proc cMotion_plugin_text_question_whatodds { nick channel host } {
    cMotion_putloglev 2 * "$nick what odds question"
  cMotionDoAction $channel $nick "%VAR{answerWhatOdds}"
  return 1
}

proc cMotion_plugin_text_question_long { nick channel host } {
    cMotion_putloglev 2 * "$nick how long question"
  cMotionDoAction $channel $nick "%VAR{answerHowLongs}"
  return 1
}

proc cMotion_plugin_text_question_age { nick channel host } {
    cMotion_putloglev 2 * "$nick how old question"
  cMotionDoAction $channel $nick "%VAR{answerHowOlds}"
  return 1
}

proc cMotion_plugin_text_question_big { nick channel host } {
	cMotion_putloglev 2 * "$nick how big question"
	cMotionDoAction $channel $nick "%VAR{answerHowBigs}"
	return 1
}

cMotion_abstract_register "question_what_fact_wrapper"
cMotion_abstract_batchadd "question_what_fact_wrapper" {
  "%%"
  "%% i guess"
  "i think it's %%"
  "%% i think"
  "%% i suppose"
}

cMotion_abstract_register "question_want_reply_wrapper"
cMotion_abstract_batchadd "question_want_reply_wrapper" {
  "Why? I've got %VAR{sillyThings}!"
  "With %VAR{sillyThings} I have no need for anything else."
  "Ooh yes please, I've had %VAR{sillyThings} for so long it's boring me."
  "Will it feel as good as %VAR{sillyThings} from %ruser?"
  "Hell yes, %ruser's given me %VAR{sillyThings} and I can't wait to get away from it!"
  "I don't know, %VAR{sillyThings} from %ruser just %VAR{fellOffs}."
  "Yes, %VAR{confuciousStart} %VAR{confuciousEnd}."
  "No, %VAR{confuciousStart} %VAR{confuciousEnd}."
  "Can I have a %VAR{chocolates} too?"
  "Yes please, I left %VAR{sillyThings} in %VAR{answerWheres}."
  "Not until %VAR{answerWhens}."
  "Yes please, the Borg Queen offered me %VAR{trekNouns} and I only got %VAR{sillyThings}."
  "%VAR{sweet}."
}

cMotion_abstract_register "question_colour_wrapper"
cMotion_abstract_batchadd "question_colour_wrapper" {
  "%VAR{colours}"
  "hmm.. %VAR{colours}, I think"
  "%VAR{colours}"
  "%VAR{colours}%|No! %VAR{colours}!"
  "%VAR{colours}"
}
