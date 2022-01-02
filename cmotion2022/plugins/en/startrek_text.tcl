## Startrek plugin for cMotion

# Init some plugin specific vars if they arent already created
if {![info exists cMotionStarTrek]} {
 set cMotionStarTrek(cloaked) 0
 set cMotionStarTrek(warp) 0
 set cMotionStarTrek(impulse) 0
 set cMotionStarTrek(brig) ""
 set cMotionStarTrek(brigDelay) 120
}

cMotion_plugin_add_text "st-cloak" "^%botnicks:?,? cloak$" 100 "cMotion_plugin_text_startrek_cloak" "en"
cMotion_plugin_add_text "st-decloak" "^%botnicks:?,? decloak$" 100 "cMotion_plugin_text_startrek_decloak" "en"
cMotion_plugin_add_text "st-fire" "^%botnicks:?,? fire " 100 "cMotion_plugin_text_startrek_fire" "en"
cMotion_plugin_add_text "st-courtmartial" "^%botnicks:?,? courtmartial " 100 "cMotion_plugin_text_startrek_courtmartial" "en"

#cloak
proc cMotion_plugin_text_startrek_cloak { nick host handle channel text } {
  global cMotionStarTrek
  if {$cMotionStarTrek(cloaked) == 1} {
    cMotionDoAction $channel $nick "Already running cloaked, sir"
    return 1
  }
  set cMotionStarTrek(cloaked) 1
  cMotionDoAction $channel $nick "/shimmers and disappears from view..."
  return 1
}

#decloak
proc cMotion_plugin_text_startrek_decloak { nick host handle channel text } {
  global cMotionStarTrek
  if {$cMotionStarTrek(cloaked) == 0} {
    cMotionDoAction $channel $nick "Already decloaked, sir"
    return 1
  }
  set cMotionStarTrek(cloaked) 0
  cMotionDoAction $channel $nick "/shifts back into view"
  return 1
}

#fire
proc cMotion_plugin_text_startrek_fire { nick host handle channel text } {
  global botnicks cMotionStarTrek
  if [regexp -nocase "$botnicks:?,? fire (.+) at (.+)" $text pop frogs weapon target] {
    set weapon [string tolower $weapon]
    if {![regexp "(phasers|torpedoe?|photon|quantum|cheesecake|everything)" $weapon]} {
      if {[string range $weapon [expr [string length $weapon] - 1] end] == "s"} {
        cMotionDoAction $channel $nick "I haven't got any '$weapon' ... I think they %VAR{fellOffs}."
      } else {
        cMotionDoAction $channel $nick "I haven't got any '$weapon' ... I think it %VAR{fellOffs}."
      }
      return 1
    }

    if [regexp -nocase $botnicks $target] {
      cMotionDoAction $channel $nick "Don't be so silly. Sir."
      return 1
    }

    if {$cMotionStarTrek(cloaked) == 1} {
      cMotionDoAction $channel $nick "/swoops in on $target, decloaking on the way..."
    } else {
      cMotionDoAction $channel $nick "/swoops in on $target"
    }

    if {$weapon == "phasers"} {
      global phaserFires
      cMotionDoAction $channel $target "%VAR{phaserFires}"
    }

    if [regexp "(torpedoe?s|photon|quantum)" $weapon] {
      global torpedoFires
      cMotionDoAction $channel $target "%VAR{torpedoFires}"
    }

    if {$weapon == "everything"} {
      global everythingFires
      cMotionDoAction $channel $target "%VAR{everythingFires}"
    }

    if {$cMotionStarTrek(cloaked) == 1} {
      cMotionDoAction $channel $nick "/recloaks"
    }
    return 1
  }
}

cMotion_abstract_register "fellOffs"
cMotion_abstract_batchadd "fellOffs" {
  "fell off"
  "exploded"
  "imploded"
  "caught fire"
  "got eaten"
  "turned into %noun"
  "got discontinued"
  "ran out"
  "ran off"
  "expired"
  "bounced off"
  "collapsed"
  "split into component atoms"
  "got turned into %VAR{sillyThings}"
}
cMotion_abstract_register "phaserFires"
cMotion_abstract_batchadd "phaserFires" {
  "/fires several shots from the forward phaser banks, disabling %%"
  "/fires several shots from the forward phaser banks, destroying %%%|/flies out through the explosion in an impressive bit of piloting (not to mention rendering :)"
  "/accidentally activates the wrong system and replicates a small tree"
  "/misses a gear and stalls%|Oops%|%bot\[50,¨VAR{ruins}\]"
  "/uses attack pattern alpha, spiralling towards %%, firing all phaser banks%|* %% is blown to pieces as %me flies off into the middle distance"
  "/anchors %% to a small asteriod, paints a target on their upper hull, and fires a full phaser blast at them"
  "/rolls over, flying over %% upside down, firing the dorsal phaser arrays on the way past"
  "/flies around %%, firing the ventral arrays"
  "/jumps to high impulse past %% and fires the aft phaser banks"
  "System failure: TA/T/TS could not interface with phaser command processor (ODN failure)"
  "/pulls the Picard move (the non-uniform one)"
}

cMotion_abstract_register "torpedoFires"
cMotion_abstract_batchadd "torpedoFires" {
  "/fires a volley of torpedos at %%"
  "/breaks into a roll and fires torpedos from dorsal and ventral launchers in sequence"
  "/breaks into a roll and ties itself in a knot%|Damn.%|%bot\[50,¨VAR{ruins}\]"
  "System failure: TSC error"
  "/flies past %% and fires a full spread of torpedos from the aft launchers"
  "/heads directly for %%, firing a full spread of torpedos from the forward lauchers%|/flies out through the wreakage"
}

cMotion_abstract_register "everythingFires"
cMotion_abstract_batchadd "everythingFires" {
  "/opens the cargo hold and ejects some plastic drums at %%"
  "/lauches all the escape pods"
  "/fires the Universe Gun(tm) at %%"
  "/launches some torpedos and fires all phasers"
  "/shoots a little stick with a flag reading 'BANG' on it out from the forward torpedo launchers"
  "/lobs General Darian at %%"
}

proc cMotion_plugin_text_startrek_courtmartial { nick host handle channel text } {
  global botnicks cMotionStarTrek
  if [regexp -nocase "$botnicks:?,? courtmartial (.+?)( with banzai)?" $text pop frogs who banzai] {
    if [regexp -nocase "\\m$botnicks\\M" $who] {
      cMotionDoAction $channel $nick "Duh."
      return 1
    }

    if {$banzai != ""} { set cMotionStarTrek(banzaiModeBrig) 1 } else { set cMotionStarTrek(banzaiModeBrig) 0 }

    if {$cMotionStarTrek(brig) != ""} {
      cMotionDoAction $channel $nick "I'm sorry Sir, I already have someone in the brig - please try again later, or empty the Recycle Bin."
			utimer [expr $cMotionStarTrek(brigDelay) + 10] cMotion_brig_flush
      return 1
    }

    if {![onchan $who $channel]} {
      cMotionDoAction $channel $nick "Who?"
      puthelp "NOTICE $nick :Please specify the full nickname of someone in the channel (Couldn't find '$who')."
      return 1
    }

    set cMotionStarTrek(brig) "$who@$channel"
    if {$cMotionStarTrek(banzaiModeBrig) == 1} {
      cMotionDoAction $channel $who "%VAR{brigBanzais}"
      cMotionDoAction $channel $who "Rules simple. Simply decide if you think I'll find %% innocent."
      set cMotionStarTrek(brigInnocent) [list]
      set cMotionStarTrek(brigGuilty) [list]
      bind pub - "!bet" cMotionVoteHandler
      cMotionDoAction $channel $who "Place bets now! (\002!bet innocent\002 and \002!bet guilty\002, one bet per person)"
    }
    cMotionDoAction $channel $who "/throws %% in the brig to await charges"
    utimer $cMotionStarTrek(brigDelay) cMotionDoBrig
    if {$cMotionStarTrek(banzaiModeBrig) == 1} {
      utimer [expr $cMotionStarTrek(brigDelay) / 2 + 7] cMotionBanzaiBrigMidBet
    }
    return 1
  }
}
cMotion_abstract_register "brigBanzais"
cMotion_abstract_batchadd "brigBanzais" {
  "The %% Being In Brig Bet!"
  "The Naughty %% Charge Conundrum!"
  "%%'s Prison Poser!"
}


### Supporting functions
proc cMotionBanzaiBrigMidBet {} {
  global cMotionStarTrek

  set brigStarTrek $cMotionStarTrek(brig)
  if {$brigStarTrek == ""} { return 0 }
  regexp -nocase "(.+)@(.+)" $brigStarTrek pop nick channel

  cMotionDoAction $channel $nick "%VAR{banzaiMidBets}"
  return 0
}

cMotion_abstract_register "banzaiMidBets"
cMotion_abstract_batchadd "banzaiMidBets" {
  "bet bet bet!"
  "bet now! Time running out!"
  "come on, bet!"
  "what you waiting for? bet now!"
  "you want friends to laugh at you? Bet!"
}

proc cMotionDoBrig {} {
  global cMotionStarTrek 
  set brigStarTrek $cMotionStarTrek(brig)
  if {$brigStarTrek == ""} { return 0 }
  regexp -nocase "(.+)@(.+)" $brigStarTrek pop nick channel

  if {![onchan $nick $channel]} {
    putlog "cMotion: Was trying to courtmartial $nick on $channel, but they're not there no more :("
    set cMotionStarTrek(brig) ""
    return 0
  }

  if {$cMotionStarTrek(banzaiModeBrig) == 1} {
    cMotionDoAction $channel $nick "Betting ends!"
  }

  cMotionDoAction $channel $nick "%%, you are charged with %VAR{charges}, and %VAR{charges}"
  set cMotionStarTrek(brig) ""

  set guilty [rand 2]
  if {$guilty} {
    cMotionDoAction $channel $nick "You have been found guilty, and are sentenced to %VAR{punishments}. And may God have mercy on your soul."
    if {$cMotionStarTrek(banzaiModeBrig) == 1} {
      if {[llength $cMotionStarTrek(brigGuilty)] > 0} {
        cMotionDoAction $channel $cMotionStarTrek(brigGuilty) "Congraturation go to big winner who are %%. Well done! Riches beyond your wildest dreams are yours to taking!"
      }
    }
  } else {
    cMotionDoAction $channel $nick "You have been found innocent, have a nice day."
    if {$cMotionStarTrek(banzaiModeBrig) == 1} {
      if {[llength $cMotionStarTrek(brigInnocent)] > 0} {
        cMotionDoAction $channel $cMotionStarTrek(brigInnocent) "Congraturation go to big winner who are %%. Well done! Glory and fame are yours!"
      }
    }
  }

  if {$cMotionStarTrek(banzaiModeBrig) == 1} {
    set cMotionStarTrek(banzaiModeBrig) 0
  }
  return 0
}
cMotion_abstract_register "trekNouns"
cMotion_abstract_batchadd "trekNouns" {
  "Neelix"
  "Captain Janeway"
  "Deputy Wall Licker 97th Class Splock"
  "the USS Enterspace"
  "the USS Enterprise"
  "the USS Voyager"
  "a class M planet"
  "a class Y planet"
  "the holodeck"
  "Deanna Troi"
  "Tasha Yar"
  "Lt Cmdr Tuvok"
  "a shuttle"
  "the phaser bank"
  "several female Maquis crewmembers"
  "the entire male crew"
  "the entire female crew"
  "the entire crew"
  "the Kazon"
  "a PADD"
  "the FLT processor"
  "the Crystalline Entity(tm)"
  "a Targ"
  "a proton"
  "a Black Hole"
  "Dr Crusher"
  "the EMH"
  "the Borg"
  "Deep Space 9"
}

cMotion_abstract_register "charges"
cMotion_abstract_batchadd "charges" {
  "exploding %VAR{trekNouns}"
  "setting fire to %VAR{trekNouns}"
  "gross incompetence"
  "teaching the replicators to make decaffinated beverages"
  "existing"
  "misuse of %VAR{trekNouns}"
  "improper use of %VAR{trekNouns}"
  "improper conduct with %VAR{trekNouns}"
  "plotting with %VAR{trekNouns}"
  "doing warp 5 in a 3 zone"
  "phase-shifting %VAR{trekNouns}"
  "having sex on %VAR{trekNouns}"
  "having sex with %VAR{trekNouns}"
  "attempting to replicate %VAR{trekNouns}"
  "terraforming %VAR{trekNouns}"
  "putting %VAR{trekNouns} into suspended animation"
  "writing a character development episode"
  "timetravelling without a safety net"
}

cMotion_abstract_register "punishments"
cMotion_abstract_batchadd "punishments" {
  "talk to Neelix for 5 hours"
  "be keel-dragged through an asteriod field"
  "play chess against 7 of 9 (you may leave as soon as you win)"
  "degauss the entire viewscreen with a toothpick"
  "be Neelix's food taster for a day"
  "have your holodeck priviledges removed for a week"
  "listen to Harry Kim practice the clarinet"
  "polish Captain Picard's head"
  "polish the EMH's head"
  "lick %% clean"
  "watch that really bad warp 10 episode of Voyager. Twice"
  "listen to an album by Olivia Newton-John"
  "explain quantum physics to Jade"
  "carry out a level 1 diagonstic single handed"
  "find Geordi a date"
}
# apparently we forgot someone was in the brig
proc cMotion_brig_flush { } {
	global cMotionStarTrek

	if {$cMotionStarTrek(brig) == ""} {
		return
	}

	cMotion_putloglev d * "Flushing brig..."

  regexp -nocase "(.+)@(.+)" $cMotionStarTrek(brig) pop nick channel
	cMotionDoAction $channel $nick "Whoops... I forgot %% was in the brig%|/sweeps corpse under the rug"
	set cMotionStarTrek(brig) ""
}

proc cMotionVoteHandler {nick host handle channel text} {
  global cMotionStarTrek
  set brigStarTrek $cMotionStarTrek(brig)
  if {$brigStarTrek == ""} {
    #unbind
    putlog "cMotion: Oops, need to unbind votes"
    unbind pubm - "!bet" cMotionVoteHandler
    return 0
  }

  if {[lsearch $cMotionStarTrek(brigInnocent) $nick] != -1} {
    puthelp "NOTICE $nick :You have already bet."
    return 0
  }

  if {[lsearch $cMotionStarTrek(brigGuilty) $nick] != -1} {
    puthelp "NOTICE $nick :You have already bet."
    return 0
  }

  if [string match -nocase "innocent" $text] {
    lappend cMotionStarTrek(brigInnocent) $nick
    putlog "cMotion: Accepted innocent bet from $nick"
    return 0
  }

  if [string match -nocase "guilty" $text] {
    lappend cMotionStarTrek(brigGuilty) $nick
    putlog "cMotion: Accepted guilty bet from $nick"
    return 0
  }
  puthelp "NOTICE $nick: Syntax: !bet <guilty|innocent>"
}
