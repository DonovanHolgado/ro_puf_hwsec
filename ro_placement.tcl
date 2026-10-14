# Places every ring oscillator with an identical layout so the two rings in a
# pair differ only by silicon variation, not by placement.
#
#   ring 2i   : all 4 LUTs in slice (X, Y)     divider in slice (X, Y+1)
#   ring 2i+1 : all 4 LUTs in slice (X, Y+2)   divider in slice (X, Y+3)
#
# Both rings of a pair share a slice column, so they sit in the same tile type
# and slice position with the same BELs and LUT pins. Slots never straddle a
# clock region or the HCLK row in the middle of one. Sites are taken from the
# target part, so the same script works on the xc7z020 and the xc7z010.
#
# Use as the opt_design tcl.post hook (Implementation settings), or source it
# in an opened synthesized design and save the constraints.

set NUM_ROS   256
set NUM_PAIRS [expr {$NUM_ROS / 2}]

proc ro_cell {i name} {
    return [get_cells "gen_ros\[$i\].ro_inst/$name"]
}

# index every slice site by column and row
set site_at [dict create]
set xs {}
set max_y 0
foreach site [get_sites -filter {SITE_TYPE =~ SLICE*}] {
    if {[regexp {^SLICE_X(\d+)Y(\d+)$} $site -> x y]} {
        dict set site_at "$x,$y" $site
        lappend xs $x
        if {$y > $max_y} { set max_y $y }
    }
}
set xs [lsort -integer -unique $xs]
set max_x [lindex $xs end]

# find NUM_PAIRS slots of 4 vertically adjacent, matching sites
set slots {}
foreach x $xs {
    # stay off the outermost columns
    if {$x < 2 || $x > $max_x - 2} { continue }
    for {set base 0} {$base <= $max_y} {incr base 25} {
        foreach off {0 4 8 12 16 20} {
            set y [expr {$base + $off}]
            set slot {}
            foreach dy {0 1 2 3} {
                set key "$x,[expr {$y + $dy}]"
                if {[dict exists $site_at $key]} {
                    lappend slot [dict get $site_at $key]
                }
            }
            if {[llength $slot] != 4} { continue }

            set objs [get_sites $slot]
            set regions [lsort -unique [get_property CLOCK_REGION $objs]]
            set types   [lsort -unique [get_property TYPE [get_tiles -of_objects $objs]]]
            set stypes  [lsort -unique [get_property SITE_TYPE $objs]]
            if {[llength $regions] != 1 || [llength $types] != 1 || [llength $stypes] != 1} { continue }

            lappend slots [list $x $y $slot]
            if {[llength $slots] == $NUM_PAIRS} { break }
        }
        if {[llength $slots] == $NUM_PAIRS} { break }
    }
    if {[llength $slots] == $NUM_PAIRS} { break }
}

if {[llength $slots] < $NUM_PAIRS} {
    error "ro_placement: only found [llength $slots] of $NUM_PAIRS RO pair slots"
}

set ring_bels {LUT_AND A6LUT LUT_INV0 B6LUT LUT_INV1 C6LUT LUT_INV2 D6LUT}
set div_bels  {LUT_DIV A6LUT FF_DIV AFF}

set pb [create_pblock pblock_ro]
set ro_cells {}
set ranges {}

for {set p 0} {$p < $NUM_PAIRS} {incr p} {
    lassign [lindex $slots $p] x y slot
    lassign $slot ring_a div_a ring_b div_b

    foreach {i ring_site div_site} [list [expr {2*$p}] $ring_a $div_a [expr {2*$p+1}] $ring_b $div_b] {
        foreach {name bel} $ring_bels {
            set c [ro_cell $i $name]
            set_property BEL $bel $c
            set_property LOC $ring_site $c
            lappend ro_cells $c
        }
        foreach {name bel} $div_bels {
            set c [ro_cell $i $name]
            set_property BEL $bel $c
            set_property LOC $div_site $c
            lappend ro_cells $c
        }

        # same physical LUT pins on every ring (A6/A5 are the fastest inputs)
        set_property LOCK_PINS {I0:A5 I1:A6} [ro_cell $i LUT_AND]
        foreach name {LUT_INV0 LUT_INV1 LUT_INV2 LUT_DIV} {
            set_property LOCK_PINS {I0:A6} [ro_cell $i $name]
        }
    }

    lappend ranges "SLICE_X${x}Y${y}:SLICE_X${x}Y[expr {$y + 3}]"
}

# keep all other logic out of the RO slices
add_cells_to_pblock $pb $ro_cells
resize_pblock $pb -add $ranges
set_property EXCLUDE_PLACEMENT 1 $pb

puts "ro_placement: placed $NUM_ROS ROs in $NUM_PAIRS pairs"
