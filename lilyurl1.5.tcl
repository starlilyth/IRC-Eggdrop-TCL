# URL 2 IRC by Lily (starlily@gmail.com)
# Scans links in IRC channels and returns titles and tinyurl, and logs to a webpage. 
# Will tag weblog entries NSFW if that appears in the line with the link.
# Has duplicate link detection - displays newest entry only, with link count and poster list.
# For Eggdrop bots. Has only been tested on eggdrop 1.6.19+
# Requires TCL8.4 or greater with http, htmlparse and tls, and the sqlite3 tcl lib. (not mysql!) 
# For deb/ubuntu, the packages needed are tcllib and libsqlite3-tcl. Adjust for your flavor. 

# You must ".chanset #channel +url2irc" for each chan you wish to use this in. 

# This needs to be set to a bot writable dir for the web log pages. 
set url2irc(path) /var/www/html/bonghit/urllog      ;# path to bot writable dir for web log pages

# Optional space separated list of domains/URLs/keywords to ignore. Entries are * expanded both ways, you have been warned.
set url2irc(iglist) "rotten.com lemonparty.org dickscab.com decentsite.tld/somepath/terriblepicture.jpg"

# You may want to change these, but they are set pretty well. 
set url2irc(maxdays) 7   		;# maximum number of days to save on log page
set url2irc(tlength) 90	 		;# minimum url length for tinyurl (tinyurl is 18 chars..) 
set url2irc(pubmflags) "-|-" 	;# user flags required for use
# Fine tuning, safe to ignore. 
set url2irc(ignore) "bdkqr|dkqr" ;# user flags script will ignore 
set url2irc(length) 12	 		;# minimum url length for title (12 chars is the shortest url possible, equalling all)
set url2irc(clength) 90			;# log page url display length 
set url2irc(delay) 2 			;# minimum seconds between use
set url2irc(timeout) 90000 		;# geturl timeout 
set url2irc(maxsize) 1048576    ;# max page size in bytes  

# 01 - Basic features set 20090521 
# 02 - Build logger web page function and title regexp cleanup 20101130
# 05 - Fix logger for multiple chans, user agent string, web dir check 20101204
# 07 - s/regexp/htmlparse/, truncate long url display on log page 20101212
# 09 - some ::http cleanup volunteered by Steve (thanks!) 20110220: Check Content-Type; only get title for text pages 
#   -    under maxsize, otherwise display mime-type. Follow http redirect (not meta refresh or javascript). 
# 10 - converted to sqlite3, main loop cleanup 20110305
# 11 - secure URL handler, NSFW tagger 20110308
# 12 - site blacklist, comment cleanup, chanflag removal (just one now) 20110309
# 14 - post counts, day dividers, dupe detection - display newest w/ counter and poster list, carryover NSFW flag. 20110310
# 15 - logger index.html 20110311 
# 16 - cleanups, 1.0 version for egghelp. 
# 1.2 - fixed shortlink redirects, dbfile varname change, 20120821
# 1.3 - integrated google search. 20120821
# 1.4 - fixed google search 20131217
# 1.5 - fixed redir/reloc. removed google search. 20150825
# Google is shit. A monopolistic bully with zero standards or ethics.
# I hope they choke to death on their advertising dollars. 
# TODO: sticky/hide, urlsearch, convert to ascii? 
# BUGS: alt langs (fixed in tcl8.5?)

################################################

package require http
package require htmlparse
package require tls
package require sqlite3
set url2irc(last) 111
set url2irc(agent) "Mozilla/5.0 (X11; Linux i686; rv:40.0) Gecko/20100101 Firefox/40.0"
set udbfile "./urllog.db"
setudef flag url2irc
bind pubm $url2irc(pubmflags) {*://*} pub_url2irc
bind pub $url2irc(pubmflags) !g pub_g

proc pub_g {nick host user chan text} {
 puthelp "PRIVMSG $chan :Google doesn't support anything that won't show an ad."
}

proc pub_url2irc {nick host user chan text} {
global url2irc
global udbfile
global botnick
set url2irc(redirects) 0
  if {([channel get $chan url2irc]) && ([expr [unixtime] - $url2irc(delay)] > $url2irc(last)) && (![matchattr $user $url2irc(ignore)])} {
    regsub "#" $chan "" cname
    if {[string match -nocase "*nsfw*" $text]} { set lflag  NSFW } else { set lflag {} }
    foreach word [split $text] {
      if {[string length $word] >= $url2irc(length) && [regexp {^(f|ht)tp(s|)://} $word] && ![regexp {://([^/:]*:([^/]*@|\d+(/|$))|.*/\.)} $word]} {
        foreach item $url2irc(iglist) {
          if {[string match "*$item*" $word]} {return 0}
        }
        set url2irc(last) [unixtime]
        if {[string length $word] >= $url2irc(tlength)} {
          set newurl [tinyurl $word]
        } else { set newurl "" }
        set urtitle [urltitle $word]
        set lTime [clock seconds]
        sqlite3 ldb $udbfile
          ldb eval {CREATE TABLE IF NOT EXISTS urllog (lTime INTEGER,lchan TEXT,lnick TEXT,lurl TEXT,ltitle TEXT,lflag TEXT)}
          ldb eval {INSERT INTO urllog (lTime, lchan, lnick, lurl, ltitle, lflag)VALUES($lTime,$cname,$nick,$word,$urtitle,$lflag)}
        ldb close
        regsub -all "Imgur" $urtitle "\00309,01Imgur\003" urtitle
        regsub -all "YouTube" $urtitle "You\00304Tube\003" urtitle
        regsub -all "Google" $urtitle "\00302G\00304o\00308o\00302g\00303l\00304e\003" urtitle
        if {[regexp {i.imgur} $word]} { 
          regsub {.*} $urtitle "\00309,01Imgur: $urtitle\003" urtitle
        }
        if {[string length $newurl]} {
          puthelp "PRIVMSG $chan :\002$urtitle\002 ( $newurl ), linked by $nick"
        } else { puthelp "PRIVMSG $chan :\002$urtitle\002, linked by $nick" }
      }
    }
    if {[file isdirectory $url2irc(path)] && [file writable $url2irc(path)]} {
      sqlite3 ldb $udbfile
      set rtime [expr [clock seconds] - ($url2irc(maxdays) * 86400)]
      ldb eval {DELETE FROM urllog WHERE lTime < $rtime}
      set logday 0000
      set htmlpage [ open "$url2irc(path)/$cname.html" w+ ]
      puts $htmlpage "<html><head><meta http-equiv=\"refresh\" content=\"600\" /><title>URL Log for $chan</title><head>"
      set lcount [ldb eval {SELECT COUNT(distinct lurl) FROM urllog where lchan = $cname}]
      set tdays [expr (([clock seconds] - [ldb eval {SELECT lTime FROM urllog where lchan = $cname order by rowid asc limit 1}]) / 86400) +1]
      puts $htmlpage "<body bgcolor=white><p><h1>URL Log for $chan</h1>$lcount URLs in $tdays days<br><small>This page reloads itself every 5 minutes.<br>Go back to the <a href=\"./index.html\">Index</a></small></p><p>Date - Time - <i>Nick</i> - URL<br><b>Title</b>"
      foreach lrowid [ldb eval {SELECT rowid FROM urllog WHERE lchan = $cname order by rowid desc}] {
        set lrurl [ldb eval {SELECT lurl FROM urllog where rowid = $lrowid }]
        set lrucount [ldb eval {SELECT COUNT(1) FROM urllog where lurl = $lrurl AND lchan = $cname}]
        set lrnick [ldb eval {SELECT DISTINCT lnick FROM urllog where lurl = $lrurl AND lchan = $cname}] 
        if {$lrucount > 1 } {
          if {[ldb eval {SELECT rowid from urllog where lurl = $lrurl AND lchan = $cname order by rowid desc limit 1}]!=$lrowid} {
            continue } else {
            regsub -all " " $lrnick "/" lrnick
            set plrnick "linked $lrucount times by $lrnick"
          }
        } else {set plrnick $lrnick}
        set lrtitle [ldb onecolumn {SELECT ltitle FROM urllog where rowid = $lrowid }]
        set lrTime [ldb eval {SELECT lTime FROM urllog where rowid = $lrowid }]
        set tstamp [clock format $lrTime -format {%b. %d - %H:%M}]
        if {[ldb eval {SELECT COUNT(1) FROM urllog where lurl = $lrurl AND lchan = $cname and lflag like '%NSFW%'}]} {
          set lrf " - (marked <font color=\"red\"><b>NSFW</b></font>)"} else {set lrf ""}
        if {[string length $lrurl] >=$url2irc(clength)} {
          set plrurl "[string replace $lrurl $url2irc(clength) end ] ..."
        } else { set plrurl $lrurl }
        if {[clock format $lrTime -format {%m%d}] != $logday} { 
          set plogday [clock format $lrTime -format {%A %B %d}]
          puts $htmlpage "<p><center><b>$plogday</b></center></p><hr>"
          set logday [clock format $lrTime -format {%m%d}]
        }
        puts $htmlpage "<p>$tstamp - <i>$plrnick</i> - <a href=\"$lrurl\">$plrurl</a><br><b>$lrtitle</b>$lrf<hr>" 
      }
      puts $htmlpage "<center><small><b>URL 2 IRC</b> by Lily</small></center></body></html>"
      close $htmlpage
      set indexpage [ open "$url2irc(path)/index.html" w+ ]
      puts $indexpage "<html><head><meta http-equiv=\"refresh\" content=\"600\" /><title>URL Log Index for $botnick</title><head>"
      set ilcount [ldb eval {SELECT COUNT(distinct lurl) FROM urllog}]
      set ichanc [ldb eval {SELECT COUNT(distinct lchan) FROM urllog}]
      puts $indexpage "<body bgcolor=white><p><h1>URL Log Index for $botnick</h1>$ilcount URLs in $ichanc channels<br><small>This page reloads itself every 5 minutes.</small></p><hr>"
      foreach chanid  [ldb eval {SELECT distinct lchan FROM urllog}] {
        set ilcount [ldb eval {SELECT COUNT(distinct lurl) FROM urllog where lchan = $chanid}]
        set ilTime [ldb eval {SELECT lTime from urllog where lchan = $chanid order by rowid desc limit 1}]
        set itstamp [clock format $ilTime -format {%B %d at %H:%M}]
        set iltitle [ldb onecolumn {SELECT ltitle from urllog where lchan = $chanid order by rowid desc limit 1}]
        puts $indexpage "<p><a href=\"./$chanid.html\">\#$chanid</a> - $ilcount URLs - last link posted $itstamp<br>Last link title: <b>$iltitle</b></p><hr>"
      }
      puts $indexpage "<center><small><b>URL 2 IRC</b> by Lily</small></center></body></html>"
      close $indexpage
      ldb close
    } else {
      putlog  "Web log path not valid! Not writing html files."
    }
  }
}

proc urltitle {url} {
global url2irc
  set agent $url2irc(agent)
  if {[info exists url] && [string length $url]} {
    ::http::register https 443 [list ::tls::socket -tls1 1]
    set http [::http::config -useragent $agent]
    if {[catch {::http::geturl $url -timeout $url2irc(timeout) -validate 1} http]} {
      set status [::http::status $http]
      return $status
    }
    array set meta [::http::meta $http]
    ::http::cleanup $http
    while {[info exists meta(Redirect)] && [incr url2irc(redirects)] < 10} {
      ::http::register https 443 [list ::tls::socket -tls1 1]
      set http [::http::config -useragent $agent]
      if {[catch {::http::geturl $meta(Redirect) -timeout $url2irc(timeout) -validate 1} http]} {
        set status [::http::status $http]
        return $status
      }
      array set meta [::http::meta $http]
      putlog "REDIR: $url2irc(redirects) : $meta(Redirect)"
      ::http::cleanup $http
      set url $meta(Redirect)
    }
    while {[info exists meta(Location)] && [incr url2irc(redirects)] < 10} {
      set startloc $meta(Location)
      ::http::register https 443 [list ::tls::socket -tls1 1]
      set http [::http::config -useragent $agent]
      if {[catch {::http::geturl $meta(Location) -timeout $url2irc(timeout) -validate 1} http]} {
        set status [::http::status $http]
        return $status
      }
      array set meta [::http::meta $http]
      #putlog "RELOC: $url2irc(redirects) : $meta(Location)"
      ::http::cleanup $http
      if {$startloc eq $meta(Location)} { 
        set url $startloc
        break 
      }
    }
    if {[info exists meta(Content-Type)]} {
      set content_type [lindex [split $meta(Content-Type) ";"] 0]
    } else {
      set content_type "Unknown"
    }
    if {[info exists meta(Content-Length)]} {
      set content_length $meta(Content-Length)
    } else {
      set content_length 0
    }
    if {$content_length <= $url2irc(maxsize) && [string match -nocase "text/*" $content_type]} {
      ::http::register https 443 [list ::tls::socket -tls1 1]
      set http [::http::config -useragent $agent]
      if {[catch {::http::geturl $url -timeout $url2irc(timeout)} http]} {
        set status [::http::status $http]
        return $status
      }
      set data [split [::http::data $http] \n]
      ::http::cleanup $http
    }
    set title ""
    if {[info exists data] && [regexp -nocase {<title>(.*?)</title>} $data match title]} {
      set title [::htmlparse::mapEscapes $title]
      regsub -all {[\{\}\\]} $title "" title
      regsub -all " +" $title " " title
      set title [string trim $title]
      return $title
    } else {
      return "$content_type"
    }
  }
}

proc tinyurl {url} {
  global url2irc
  set agent $url2irc(agent)
  if {[info exists url] && [string length $url]} {
    #tinyurl doesnt work with https
    set http [::http::config -useragent $agent]
    set http [::http::geturl "http://tinyurl.com/create.php" -query [::http::formatQuery "url" $url] -timeout $url2irc(timeout)]
    set data [split [::http::data $http] \n] ; ::http::cleanup $http
    for {set index [llength $data]} {$index >= 0} {incr index -1} {
      if {[regexp {href="http://tinyurl\.com/\w+"} [lindex $data $index] url]} {
        return [string map { {href=} "" \" "" } $url]
      }
    }
  }
 return ""
}

putlog "URL 2 IRC v1.5 script loaded.."
