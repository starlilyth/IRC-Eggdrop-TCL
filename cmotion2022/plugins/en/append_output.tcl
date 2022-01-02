## cMotion output plugin: append
cMotion_plugin_add_output "append" cMotion_plugin_output_append 1 "en"

proc cMotion_plugin_output_append { channel line } {
	if {([string length $line] > 10) && ([rand 100] < 20)} {
		set line [string trim $line]
		# make sure the line ends with a letter (other than D)
		# this is so we don't make ourselves look dumb(er) by adding
		# on the end of a line with a smiley
		if {[rand 2] > 0} {
			if [regexp -nocase {[a-ce-z]$} $line] {
				append line "%VAR{appends}"
			}
		} else {
		    if {![regexp {^/} $line]} {
		      set line "%VAR{prepends} $line"
		    }  
		}
		set line [cMotionDoInterpolation $line "" "" $channel]
	}
	return $line
}

cMotion_abstract_register "appends" {
  ", right?"
  ", you know?"
  ", you know what I mean?"
  ", of course"
  ", probably"
  ", right?"
  ", you know?"
  ", of course"
  ", natch"	
  ", probably"
  ", basically"
  ", in accordance with the prophecy"
  ", in accordance with my master plan"
  ", and you're sitting in it right now"
  ", but it's nothing sexual"
}
cMotion_abstract_register "prepends" {
  "yeah,"
  "well,"
  "so, like,"
  "so uhm,"
  "hey,"
  "hey uh,"
  "like,"
}
