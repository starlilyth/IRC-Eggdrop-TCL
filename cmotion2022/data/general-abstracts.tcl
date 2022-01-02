################################################
## Confirmed common use abstracts
## Core
cMotion_abstract_register "yeses" { "Yes." "yes" "yes." "oui" "si" "absolutely" "yup" "mhm" "true" "affirmative" "yea" "yep" "aye" "exactly" "definitely" "natch" "naturally" "of course" "/nods" "*nod*" }
cMotion_abstract_register "nos" { "no." "no" "No." "No" "never" "are you kidding?" "nope" "negative" "nada" "/shakes head" "*shakes head*" }

cMotion_abstract_register "thanks" { "ty" "thanks" "thank you" "tnx" "thank ya" "merci" "gracias" }

cMotion_abstract_register "smiles" { ":)" ";)" "=)" "=\}" "=D" "^_^" "-_-" ":>" }
cMotion_abstract_register "unsmiles" { ":(" ":O" ":\[" ":<" "=(" "=\[" ":\/" "o_O" }

cMotion_abstract_register "greetings" { "hi" "hi %%" "hiya" "hiya %%" "how's it going %%" "yo" "yo %%" "hey" "hey %%" "hey there %%" "heya" "heya %%" "howdy" "howdy %%" "sup" "sup %%" "hello" "hello %%" "o/" "/waves at %%" }

cMotion_abstract_register "hugs" { "*hugs %%*" "/hugs %% up" "/hugs %%" "/snuggles %%" "/huggles with %%" "/squeezes %%" }

cMotion_abstract_register "rarrs" { "rawr!" "unf!" "ooh baby!" "grr, baby!" ";)" "meOW!" "mmmm" "mmmm %%" ":D" "/wiggles %hisher eyebrows at %%" }

cMotion_abstract_register "blehs" { "bleh" "feh" "meh" ":|" }

cMotion_abstract_register "frightens" { "eek!" "o_O" "erk" "bah!" "dewd!" "woah!" "gosh"  "ohmigod!" "erp!" }

cMotion_abstract_register "awwws" { "awww" "awww, Im sorry" "awww%|want me to kiss it better?" "that sucks" "oh damn" }

cMotion_abstract_register "oops" { "oops" "whoops" "d'oh" "doh" "heh" "um... oops" }

# away_action
cMotion_abstract_register "goodlucks" { "GL" "good luck :)" "good luck" "best of luck to you" "/crosses fingers" }

cMotion_abstract_register "bodypart" { "toe" "foot" "ankle" "leg" "shin" "knee" "butt" "stomach" "solar plexus" "kidney" "chest" "back" "throat" "arm" "hand" "finger" "thumb" "head" "ear" "nose" "eye" "tooth" "tongue" "mouth" }

cMotion_abstract_register "units" { "inches" "miles" "feet" "sq inches" "litres" "meters" "acres" "miles an hour" "kph" "meters per second" "years" "watts" "amps" "decibels" }

cMotion_abstract_register "sound" { "click-click" "klackety" "feep-feep" "*eeeem*" "honk honk!" "uh-uh-uh" "whommm" "eep" "glop" "splish-splash-woah" "FOOM" "CLACK" "hiccup" "hee-haw" "splatter" "slap slap"
	"arrg splutter" "aww" "*kaw*" "ZAP" "fweeee" "sploosh" "snip!" "pap" "*choo choo choo*" "chuff!" "slip-beeeeeee" "smack" "oook-oook" "gah" "gibber" "goo" "harrumph" "whip" "bzz-bzz-bzz-bzz" "splutter" "tweet tweet" "ock" "wobble wobble!" "slash!" }

cMotion_abstract_register "color" { "%VAR{basic_color}" "%VAR{weird_color}" "%VAR{color_adjective} %VAR{basic_color}" "%VAR{color_adjective} %VAR{weird_color}" }
cMotion_abstract_register "weird_color" { "cyan" "magenta" "mauve" "taupe" "ochre" "teal" "crimson" "scarlet" "cobalt" "turquoise" "cornflower blue" "chartreuse" }
cMotion_abstract_register "basic_color" { "red" "blue" "yellow" "green" "violet" "orange" "black" "white" "purple" "silver" "gold" "pink" "grey" }
cMotion_abstract_register "color_adjective" { "brilliant" "pale" "mottled" "shimmering" "bright" "dark" "shining" "faint" "day-glow" "metallic" }

cMotion_abstract_register "socialmedia" { "Twitter" "Pinterest" "Reddit" "Facebook" "OK Cupid" "LinkedIn" "TikTok" }

# away_irc, away_action
cMotion_abstract_register "awayWorks" { "hf %%" "have fun %%" "have a good day %% :)" "don't work too hard!" }

# away_irc, away_action, complex_nightmare
cMotion_abstract_register "goodnights" { "night" "nn" "night %%" "sleep well" "goodnight :)" "night :)" "g'night" "sleep well %%" "nn %%" }

# away_irc, away_action
cMotion_abstract_register "cyas" { "pz" "cya" "bye" "peace" "/waves" "you still here?" "ttyl" "when you coming back?" "toodle doo" "ciao" }

# away_irc, away_action
cMotion_abstract_register "goodMornings" { "Morning %%" "good morning %%" "hold on, first cup still" "already?" "*yawn*" "/looks for coffee" }

# join_irc, away_irc, away_action
cMotion_abstract_register "welcomeBacks" { "re" "wb" "welcome back" "re%%" "wb %%" "welcome back %%" "hey" "hi" "%REPEAT{4:7:bl}" "pop" "heya" "you're back!" }

#SYSTEM - these are used in modules
cMotion_abstract_register "opped" { "muwa%REPEAT{3:10:ha}" "mmm, ops" "i promise to be good and well-behaved with my new op superpowers%|\\kick %%%|whoops!" "%VAR{thanks}" }
cMotion_abstract_register "deopped" { "hey! %VAR{unsmiles} i needed that" "hey! I was using that." "great, now how am i going to kickban people who i hate (e.g. %%)?" "what the..." "CHANNEL TAKEOVER DETECTED! Everyone run around screaming%colen"
	"muwa%REPEAT{3:6:ha} wait a second...%|rats." }

cMotion_abstract_register "blownAways" { "Woah!" "WOW" "What the.." "/blinks" ":O" "o_O" ":o" "woah" "Geez!" }
cMotion_abstract_register "randomAways" { "sex" "coffee" "food" "sleep" "school" "work" "working" "shopping" "gaming" "watching a movie" "brb" "around" "taking over the world" "sekrit" "auto-away" "coding" "beer" "out" "coffee" "porn" "yo mamma" "%ruser" "cookie" "shower" "bath" "taking the dog for a walk" "washing my hair" "removing my enemies from the timeline" }
cMotion_abstract_register "silenceAways" { "bah" "/goes to find someone more interesting to talk to" "fine" "/stamps foot%|*sulk*" "/messages %ruser instead" "%VAR{unsmiles}" }

cMotion_abstract_register "tireds" { "/yawns" "/yawns%|bedtime for %me soon i think" "*yawn*" "/tired" "nearly bedtime" "is that the time? i need to be in bed" "/puts on pajamas" "/gets ready for bed" }
cMotion_abstract_register "go_sleeps" { "bedtime" "nite all" "nn folks" "nn" "nite" "night" "goodnight" "sleepytime for me!" "/goes to bed" "/hits the sack" "/hits the hay" "/hits the hay%|ow, my hay%|wait, what?%|must be bedtime" }
cMotion_abstract_register "wake_ups" { "/wakes up" "/awakens" "good morning!" "good morning" "morning" "/eats breakfast" }
