#!/bin/bash
if [ -z "$1" ]; then
    echo 'usage: gen_tcl.sh [NUM_OF_NODE] [TCP_VERSION]';
    exit
elif [ -z "$2" ]; then
    echo 'usage: gen_tcl.sh [NUM_OF_NODE] [TCP_VERSION]';
    exit
else
    NUM_NODE=$1;
    TCP_VERSION=$2;
    TCP_VERSION_ARR[0]='TCP';
    TCP_VERSION_ARR[1]='TCP/FullTcp/Tahoe';
    TCP_VERSION_ARR[2]='TCP/Reno';
    TCP_VERSION_ARR[3]='TCP/Newreno';
    TCP_VERSION_ARR[4]='TCP/Vegas';

    TCP_VERSION_ARR[5]='TCP';
    TCP_VERSION_ARR[6]='Tahoe';
    TCP_VERSION_ARR[7]='Reno';
    TCP_VERSION_ARR[8]='Newreno';
    TCP_VERSION_ARR[9]='Vegas';
fi
tcl_file=${TCP_VERSION_ARR[$(($2+5))]}"/"$NUM_NODE".tcl";
nam_file=${TCP_VERSION_ARR[$(($2+5))]}"/"$NUM_NODE".nam";
tr_file=${TCP_VERSION_ARR[$(($2+5))]}"/"$NUM_NODE".tr";
echo '
#===================================
#     Simulation parameters setup
#===================================
Phy/WirelessPhy set bandwidth_ 11Mb        ;#Data Rate
Mac/802_11 set dataRate_ 11Mb              ;#Rate for Data Frames
Mac/802_11 set basicRate_ 1Mb              ;#Rate for Control Frames

set val(chan)   Channel/WirelessChannel    ;# channel type
set val(prop)   Propagation/TwoRayGround   ;# radio-propagation model
set val(netif)  Phy/WirelessPhy            ;# network interface type
set val(mac)    Mac/802_11                 ;# MAC type
set val(ifq)    Queue/DropTail/PriQueue    ;# interface queue type
set val(ll)     LL                         ;# link layer type
set val(ant)    Antenna/OmniAntenna        ;# antenna model
set val(ifqlen) 500                         ;# max packet in ifq
' > $tcl_file;

echo "
set val(nn)     $((NUM_NODE+2))                         ;# number of mobilenodes
" >> $tcl_file;

echo '
set val(rp)     AODV                       ;# routing protocol
set val(x)      615                      ;# X dimension of topography
set val(y)      668                      ;# Y dimension of topography
' >> $tcl_file;

echo '
set val(stop)   40                         ;# time of simulation end

#===================================
#        Initialization        
#===================================
#Create a ns simulator
set ns [new Simulator]

#Setup topography object
set topo       [new Topography]
$topo load_flatgrid $val(x) $val(y)
create-god $val(nn)

#Setup topography object
set topo       [new Topography]
$topo load_flatgrid $val(x) $val(y)
create-god $val(nn)

#Open the NS trace file
' >> $tcl_file;

echo "
set tracefile [open $tr_file w]
" >> $tcl_file;

echo '
$ns trace-all $tracefile

#Open the NAM trace file
' >> $tcl_file;

echo "
set namfile [open $nam_file w]
" >> $tcl_file;

echo '
$ns namtrace-all $namfile
$ns namtrace-all-wireless $namfile $val(x) $val(y)
set chan [new $val(chan)];#Create wireless channel

#===================================
#     Mobile node parameter setup
#===================================
$ns node-config -adhocRouting  $val(rp) \
                -llType        $val(ll) \
                -macType       $val(mac) \
                -ifqType       $val(ifq) \
                -ifqLen        $val(ifqlen) \
                -antType       $val(ant) \
                -propType      $val(prop) \
                -phyType       $val(netif) \
                -channel       $chan \
                -topoInstance  $topo \
                -agentTrace    ON \
                -routerTrace   ON \
                -macTrace      ON \
                -movementTrace ON

#===================================
#        Nodes Definition        
#===================================
set n0 [$ns node]
$n0 set X_ 250 
$n0 set Y_ 250
$n0 set Z_ 0.0
$ns initial_node_pos $n0 20
set n1 [$ns node]
$n1 set X_ 490
$n1 set Y_ 250
$n1 set Z_ 0.0
$ns initial_node_pos $n1 20
' >> $tcl_file;
for (( i=2; i<$((NUM_NODE+2)) ; i+=1 )); do
   echo "
set n$i [\$ns node]
\$n$i set X_ $((520+i))
\$n$i set Y_ 250
\$n$i set Z_ 0.0
\$ns initial_node_pos \$n$i 20

#Setup a TCP connection
set tcp$i [new Agent/${TCP_VERSION_ARR[$TCP_VERSION]}]
\$ns attach-agent \$n2 \$tcp$i
set sink$i [new Agent/TCPSink]
\$ns attach-agent \$n0 \$sink$i
\$ns connect \$tcp$i \$sink$i
\$tcp$i set packetSize_ 1500

#Setup a FTP Application over TCP connection
set ftp$i [new Application/FTP]
\$ftp$i attach-agent \$tcp$i
\$ns at 0.0 \"\$ftp$i start\"
\$ns at 40.0 \"\$ftp$i stop\"
   " >> $tcl_file; 
done
echo '
#===================================
#        Termination        
#===================================
#Define a 'finish' procedure
proc finish {} {
    global ns tracefile namfile
    $ns flush-trace
    close $tracefile
    close $namfile
' >> $tcl_file;
#echo "    exec nam $nam_file &" >> $tcl_file;
echo '
exit 0
}
for {set i 0} {$i < $val(nn) } { incr i } {
    $ns at $val(stop) "\$n$i reset"
}
$ns at $val(stop) "$ns nam-end-wireless $val(stop)"
$ns at $val(stop) "finish"
$ns at $val(stop) "puts \"done\" ; $ns halt"
$ns run
' >> $tcl_file;
