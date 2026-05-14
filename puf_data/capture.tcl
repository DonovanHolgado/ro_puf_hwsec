# Get correct device
set device [get_hw_devices xc7z010_1]
current_hw_device $device

# Reload probes without reprogramming
set_property PROBES.FILE {/home/donovan/ro_puf/ro_puf.runs/impl_1/top_level.ltx} $device
refresh_hw_device $device

# Get ILA
set ila [get_hw_ilas hw_ila_1]

# Check probe names
puts "Available probes:"
puts [get_hw_probes -of_objects $ila]

# Set up trigger on done_sig going high
set_property CONTROL.TRIGGER_POSITION 0 $ila
set_property TRIGGER_COMPARE_VALUE eq1'b1 [get_hw_probes done_sig -of_objects $ila]

# Create output directory
file mkdir /home/donovan/puf_data

# Run 100 captures
set num_runs 100
puts "Starting $num_runs captures..."

for {set i 0} {$i < $num_runs} {incr i} {
    catch {
        run_hw_ila $ila
        wait_on_hw_ila $ila
        set ila_data [upload_hw_ila_data $ila]
        set filename "/home/donovan/puf_data_zybo/run_${i}.csv"
        write_hw_ila_data -csv_file $filename $ila_data
        puts "Captured run $i of $num_runs"
    } err
    if {$err ne ""} {
        puts "Warning: Run $i failed - $err, skipping"
    }
    after 5000
}
puts "Done - all $num_runs runs captured"
puts "Data saved to /home/donovan/puf_data/"
