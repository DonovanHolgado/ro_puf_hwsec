# Routes the ring oscillator loop nets before the rest of the design, makes
# sure both rings in every pair got the same route, and fixes the routes so
# route_design leaves them alone.
#
# Use as the route_design tcl.pre hook (Implementation settings), after
# ro_placement.tcl has placed the rings.

set NUM_ROS   256
set NUM_PAIRS [expr {$NUM_ROS / 2}]
set LOOP_NETS {t0 t1 t2 t3}

proc ro_net {i name} {
    return [get_nets "gen_ros\[$i\].ro_inst/$name"]
}

# route only the ring loops first, in an otherwise empty fabric
set nets {}
for {set i 0} {$i < $NUM_ROS} {incr i} {
    foreach n $LOOP_NETS {
        lappend nets [ro_net $i $n]
    }
}
route_design -nets $nets

# ring 2p+1 must match ring 2p exactly; copy the route over if it does not
set copied 0
set failed {}
for {set p 0} {$p < $NUM_PAIRS} {incr p} {
    foreach n $LOOP_NETS {
        set net_a [ro_net [expr {2*$p}]   $n]
        set net_b [ro_net [expr {2*$p+1}] $n]
        set route_a [get_property ROUTE $net_a]
        if {$route_a eq [get_property ROUTE $net_b]} { continue }

        route_design -unroute -nets $net_b
        if {[catch {set_property FIXED_ROUTE $route_a $net_b} err]} {
            route_design -nets $net_b
            lappend failed "pair $p net $n: $err"
        } else {
            incr copied
        }
    }
}

set_property IS_ROUTE_FIXED 1 $nets

puts "ro_route: routed [llength $nets] RO loop nets, copied $copied mismatched routes"
if {[llength $failed] > 0} {
    puts "ro_route: WARNING [llength $failed] nets could not be matched:"
    foreach f $failed { puts "  $f" }
}
