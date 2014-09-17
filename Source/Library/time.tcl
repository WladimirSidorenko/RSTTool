#!/usr/bin/env wish

# Variables and methods for handling time.

###########
# Methods #
###########
proc start-time { { option {} } } {
    global currentfile begin_date last_date actual_sec

    if {$currentfile != {}} {
	set realtimefile [set-file-name realtime]
	set timefile [set-file-name time]

	set actual_sec 0

	if { $option == "reset" } {
	    if {[file exists $currentfile.rst/$realtimefile]} {
		set g [open $currentfile.rst/$realtimefile w 0644]
		puts $g "hours: 0 \nminutes: 0 \nseconds: 0"
		close $g
	    }
	    if {[file exists $currentfile.rst/$timefile]} {
		set g [open $currentfile.rst/$timefile w 0644]
		puts $g "hours: 0 \nminutes: 0 \nseconds: 0"
		close $g
	    }
	}
	set last_date [clock format [clock seconds]\
			   -format "%a %b %d %H:%M:%S %Z %Y" -gmt 0]
	set begin_date $last_date
    }
}

proc compare-click-times { } {
    global currentfile actual_sec last_date
    global MAX_CLICK_DELAY

    set current_date [clock format [clock seconds]\
			  -format "%a %b %d %H:%M:%S %Z %Y" -gmt 0]
    set time [calc-from-date "$last_date" "$current_date" 0 0 0]
    set time [split $time :]
    set seconds [lindex $time 2]
    set minutes [lindex $time 1]
    set hours [lindex $time 0]
    set minutes [expr $hours * 60 + $minutes]
    set seconds [expr $minutes * 60 + $seconds]
    if {$seconds <= [cast-as-number $MAX_CLICK_DELAY]} {
	set actual_sec [expr $actual_sec + $seconds]
    }
    set last_date $current_date
}

proc calculate-time {hrs min sec filename} {
    global currentfile

    if {$currentfile != {}} {
	set oldhrs 0
	set oldmin 0
	set oldsec 0
	set file [set-file-name $filename]
	if {[file exists $currentfile.rst/$file]} {
	    set f [open $currentfile.rst/$file r]
	    gets $f oldhrs
	    set oldhrs [lindex $oldhrs 1]
	    gets $f oldmin
	    set oldmin [lindex $oldmin 1]
	    gets $f oldsec
	    set oldsec [lindex $oldsec 1]
	    close $f
	}
	set g [open $currentfile.rst/$file w 0644]

	set sec [expr $oldsec + $sec]
	while {$sec >= 60} {
	    set sec [expr $sec - 60]
	    set min [expr $min + 1]
	}
	set min [expr $oldmin + $min]
	while {$min >= 60} {
	    set min [expr $min - 60]
	    set hrs [expr $hrs + 1]
	}
	set hrs [expr $oldhrs + $hrs]

	puts $g "hours: $hrs \nminutes: $min \nseconds: $sec"

	close $g
    }
}

proc export-time { } {
    global actual_sec begin_date

    calculate-time 0 0 $actual_sec realtime

    set current_date [clock format [clock seconds]\
			  -format "%a %b %d %H:%M:%S %Z %Y" -gmt 0]
    set time [calc-from-date "$begin_date" "$current_date" 0 0 0]
    set time [split $time :]
    set seconds [lindex $time 2]
    set minutes [lindex $time 1]
    set hours [lindex $time 0]
    calculate-time $hours $minutes $seconds time
}

proc cast-as-number { mystring } {
    set f [split $mystring {}]
    if {[lindex $f 0] == "0"} {
	set mystring [lindex $f 1]
    }
    return $mystring
}

proc calc-from-date { line1 line2 hour minute second} {
    set endtime [lindex $line2 3]
    set endtime [split $endtime :]
    set endhour [lindex $endtime 0]
    set endhour [cast-as-number $endhour]
    set endminute [lindex $endtime 1]
    set endminute [cast-as-number $endminute]
    set endsecond [lindex $endtime 2]
    set endsecond [cast-as-number $endsecond]

    set starttime [lindex $line1 3]
    set starttime [split $starttime :]
    set starthour [lindex $starttime 0]
    set starthour [cast-as-number $starthour]
    set startminute [lindex $starttime 1]
    set startminute [cast-as-number $startminute]
    set startsecond [lindex $starttime 2]
    set startsecond [cast-as-number $startsecond]
    set second [expr $endsecond - $startsecond + $second]
    set minute [expr $endminute - $startminute + $minute]
    set hour [expr $endhour - $starthour + $hour]
    while {$second >= 60} {
	set second [expr $second - 60]
	set minute [expr $minute + 1]
    }
    if {$second < 0} {
	set second [expr $second + 60]
	set minute [expr $minute - 1]
    }
    while {$minute >= 60} {
	set minute [expr $minute - 60]
	set hour [expr $hour + 1]
    }
    if {$minute < 0} {
	set minute [expr $minute + 60]
	set hour [expr $hour - 1]
    }
    if {$hour < 0} {
	set hour [expr $hour + 24]
    }
    set answer " $hour: $minute: $second"
    return $answer
}
