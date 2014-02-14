# Lilys Simple Weather (lily@disorg.net)
# International Weather script for eggdrop bots
# Will return weather from www.wunderground.com 
# Requires TCL8.0 or greater, has only been tested on eggdrop 1.6.15+
# VERSION 4.0 - output string rewrite 
# VERSION 4.2 - http::cleanup, agent string update
# VERSION 4.3 - Single tag change in mobile.wunderground source (first in 4-ish years).
# VERSION 4.4 - fixed no windm var bug. 
# VERSION 4.5 - Single tag change in mobile.wunderground source for forecast. 
# VERSION 4.6 - Made default scale configurable 

# You must ".chanset #channel +weather" for each chan you wish to use this in. 
# USAGE !w <input> 
# Input can be <zip> <post code> <city, st> <city, country> <airport code>

# Uncomment to set Metric scale as the default in the output. 
#set metric "true"

####################################################################

package require http
setudef flag weather
bind pub - !w pub_w
set agent "Mozilla/5.0 (X11; Linux i686; rv:2.0.1) Gecko/20100101 Firefox/4.0.1"
proc pub_w {nick uhand handle chan input} {
  if {[lsearch -exact [channel info $chan] +weather] != -1} {
    global botnick agent metric
    if {[llength $input]==0} {
      putserv "PRIVMSG $chan :Lilys Simple Weather V4"
    } else {
      set query "http://mobile.wunderground.com/cgi-bin/findweather/getForecast?brand=mobile&query="
      for { set index 0 } { $index<[llength $input] } { incr index } {
        set query "$query[lindex $input $index]"
          if {$index<[llength $input]-1} then {
            set query "$query+"
          }
      }
    }

#    putserv "PRIVMSG $chan : $query"
    set http [::http::config -useragent $agent]    
    set http [::http::geturl $query]
    set html [::http::data $http]; ::http::cleanup $http
    regsub -all "\n" $html "" html
    regexp {City Not Found} $html - nf
    if {[info exists nf]==1} {
      putserv "PRIVMSG $chan : $input not found on wunderground.com"
      return 0
    }
    regexp {Search results for} $html - mc
    if {[info exists mc]==1} {
    putserv "PRIVMSG $chan : There are multiple choices for $input on wunderground.com"
      return 0
    }
    regexp {Observed at<b>(.*)</b> </td} $html - loc
    if {[info exists loc]==0} { 
      putserv "PRIVMSG $chan : The current conditions are not available for $input"
      return 0
    }
    regexp {Updated: <b>(.*?) on} $html - updated
    regsub -all "\<.*?\>" $updated "" updated

    regexp {Updated: <b>(.*?)Visibility</td} $html - data
    regexp {Temperature</td>  <td>  <span class="nowrap"><b>(.*?)</b>&deg;F</span>  /  <span class="nowrap"><b>(.*?)</b>&deg;C</span>} $data - tempf tempc
    if {[info exists tempf]==0} { 
      putserv "PRIVMSG $chan : Weather for $loc"
      putserv "PRIVMSG $chan : is not currently available"
      return 0
    }
    regexp {Conditions</td><td><b>(.*?)</b></td>} $data - cond
    if {[info exists cond]==0} { 
       set cond "unknown"
    }
    regexp {Wind</td><td><b>(.*?)</b> at  <span class="nowrap"><b>(.*?)</b>&nbsp;mph</span>  /  <span class="nowrap"><b>(.*?)</b>&nbsp;km/h</span>} $data - windd windm windk
    if {[info exists windm]==0} { set windm "0" } 
    if {$windm==0} { 
      set windout "no wind."
    } else {
      if {[info exists metric]} {
        set windout "a $windk KPH ($windm MPH) wind from the $windd."
      } else {	
        set windout "a $windm MPH ($windk KPH) wind from the $windd."
      }
    }
    regexp {Humidity</td><td><b>(.*?)</b>} $data - hum

	if {[info exists metric]} {
	  putserv "PRIVMSG $chan :$nick, in $loc at $updated\
it was $tempc degrees C ($tempf F),\
with $cond sky and $windout\
The humidity was at $hum."
    } else {	
      putserv "PRIVMSG $chan :$nick, in $loc at $updated\
it was $tempf degrees F ($tempc C),\
with $cond sky and $windout\
The humidity was at $hum."
	}

    regexp {Forecast as(.*?)<br /><b>} $html - fdata
    regexp {<b>Forecast as(.*?)</tr>	<tr>} $html - fidata
    if {[info exists fdata]==1} {
      regexp {<b>(.*?)</b>} $fdata - fday
      regexp { alt="" /><br />(.*?)<br />} $fdata - fcast
      putserv "PRIVMSG $chan :The forecast for $loc for $fday is $fcast"
    } elseif {[info exists fidata]==1} {
#        putserv "PRIVMSG $chan :$fidata"
        regexp {<b>(.*?)</b>} $fidata - fiday
        regexp {</b><br />(.*?)</td>} $fidata - ficast
        regsub -all "&deg;" $ficast "" ficast
        putserv "PRIVMSG $chan :The forecast for $loc $fiday is$ficast"
    } else {
      return 0
    } 
  
  }
}

putlog "Lilys Weather V4.6 loaded!"
