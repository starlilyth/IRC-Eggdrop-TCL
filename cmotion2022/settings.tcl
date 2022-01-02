#  Settings file

# list of nicks to respond to, separate with the | character [important]
# regexp is ok, but don't use brackets of any sort: () [] {} <-- NO
# your bot will automatically add its own nick to this
set cMotionSettings(botnicks) "bot|the bot"

# greet people we don't know when they join the channel?
# 0 = only greet friends
# 1 = greet everyone
# 2 = disable greetings
set cMotionSettings(friendly) 0

# male or female [important]
set cMotionSettings(gender) "female"

# go away if things get idle?
set cMotionSettings(useAway) 1

# channels to not announce our away status in (lower case)
# some channels don't like public aways, so don't piss them off :)
set cMotionSettings(noAwayFor) { "#irssi" }

# percent of typos (typos_output plugin)
set cMotionSettings(typos) 10

# percent of colloqualisms (colloq_output plugin)
set cMotionSettings(colloq) 15

# space separated list of plugins we should not load, type:name
set cMotionSettings(noPlugin) "text:startrek text:missing"

# minimum delay (mins) between random lines
set cMotionSettings(minRandomDelay) 30

# maximum delay (mins) between random lines
set cMotionSettings(maxRandomDelay) 60

# if nothing's happened on this channel for this much time, don't say something
set cMotionSettings(maxIdleGap) 120

# number of minutes to be silent when told to shut up
set cMotionSettings(silenceTime) 5

# comma separated list of plugin folders for each language (not mgmt)
set cMotionSettings(languages) "en, fr"

# default language to use
set cMotionSettings(deflang) "en"

# seconds per character in line
set cMotionSettings(typingSpeed) 0.1

### Flood checking
#
# whether to disable flood checks that would prevent a malicious user 
# from triggering plugins over and over again
#
# WARNING: Disable flood checks at your own risk! Nobody except for 
# yourself will be responsible for any resulting negative effects,
# including, but not limited to nausea, dizziness, G-lines and rabid
# wolverine attacks.
set cMotionSettings(disableFloodChecks) 1

### Abstracts
#
# (Abstracts are cMotion's word lists, and some of them grow as it sees
# things on IRC)

# amount of time (in seconds) before loaded abstracts are purged from
# memory and written to disk
# you probably don't need to change this
set cMotionSettings(abstractMaxAge) 300

# maximum number of items to keep per abstract
# when an abstract has more than this many items, cMotion will start
# forgetting items at random
set cMotionSettings(abstractMaxNumber) 600

# maximum number of things about which facts can be known
# after enough are known, others are forgotten at random
set cMotionSettings(factsMaxItems) 500

# maximum number of facts to know about an item
# forgotten at random etc
set cMotionSettings(factsMaxFacts) 20

### Sleepy stuff
# These settings give your bot a bedtime and a time to wake up
# When your bot's asleep, there's no way to wake it up!
# If you don't want it to do that, leave the first setting as 0
# and ignore the rest of this section

# Let the bot get tired and go to sleep? [important]
set cMotionSettings(sleepy) 0

# this is the hour and minute we should go to bed at (cMotion will sometimes stay up a bit later)
# these MUST be strings and MUST have leading zeros: 
# NO: set cMotionSettings(bedtime_hour) 9
# YES: set cMotionSettings(bedtime_hour) "09"
set cMotionSettings(bedtime_hour) "21"
set cMotionSettings(bedtime_minute) "00"

# and the time to wake up
set cMotionSettings(wakeytime_hour) "06"
set cMotionSettings(wakeytime_minute) "30"


