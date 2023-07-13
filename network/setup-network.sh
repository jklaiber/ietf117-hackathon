# Parameters for path-tracing
# TTS_TEMPLATE_VALUE=2
echo "VPP_PATH: ${VPP_BINARY_PATH}"
echo "$VPPCTL_BINARY_PATH_BINARY_PATH: ${$VPPCTL_BINARY_PATH_BINARY_PATH}"
echo "TTS_TEMPLATE: ${TTS_TEMPLATE_VALUE}"

##################################################
# Start vpp instances
##################################################
sudo $VPP_BINARY_PATH api-segment { prefix vpp1 } socksvr { socket-name /run/vpp/api-vpp1.sock } cpu {main-core 3} unix { cli-listen /run/vpp/cli.vpp1.sock  cli-prompt vpp1# startup-config /etc/vpp/vpp1.conf} plugins { plugin dpdk_plugin.so { disable }
sudo $VPP_BINARY_PATH api-segment { prefix vpp2 } socksvr { socket-name /run/vpp/api-vpp2.sock } cpu {main-core 4} unix { cli-listen /run/vpp/cli.vpp2.sock  cli-prompt vpp2# startup-config /etc/vpp/vpp2.conf} plugins { plugin dpdk_plugin.so { disable }
sudo $VPP_BINARY_PATH api-segment { prefix vpp3 } socksvr { socket-name /run/vpp/api-vpp3.sock } cpu {main-core 5} unix { cli-listen /run/vpp/cli.vpp3.sock  cli-prompt vpp3# startup-config /etc/vpp/vpp3.conf} plugins { plugin dpdk_plugin.so { disable }
sudo $VPP_BINARY_PATH api-segment { prefix vpp4 } socksvr { socket-name /run/vpp/api-vpp4.sock } cpu {main-core 6} unix { cli-listen /run/vpp/cli.vpp4.sock  cli-prompt vpp4# startup-config /etc/vpp/vpp4.conf} plugins { plugin dpdk_plugin.so { disable }
sudo $VPP_BINARY_PATH api-segment { prefix vpp5 } socksvr { socket-name /run/vpp/api-vpp5.sock } cpu {main-core 7} unix { cli-listen /run/vpp/cli.vpp5.sock  cli-prompt vpp5# startup-config /etc/vpp/vpp5.conf} plugins { plugin dpdk_plugin.so { disable }
sudo $VPP_BINARY_PATH api-segment { prefix vpp6 } socksvr { socket-name /run/vpp/api-vpp6.sock } cpu {main-core 8} unix { cli-listen /run/vpp/cli.vpp6.sock  cli-prompt vpp6# startup-config /etc/vpp/vpp6.conf} plugins { plugin dpdk_plugin.so { disable }
sudo $VPP_BINARY_PATH api-segment { prefix vpp7 } socksvr { socket-name /run/vpp/api-vpp7.sock } cpu {main-core 9} unix { cli-listen /run/vpp/cli.vpp7.sock  cli-prompt vpp7# startup-config /etc/vpp/vpp7.conf} plugins { plugin dpdk_plugin.so { disable }
sudo sleep 5

##################################################
# Create virtual network (linux veth and bridges)
##################################################
# Virtual links (bridges)
sudo brctl addbr br12
sudo brctl addbr br13
sudo brctl addbr br24
sudo brctl addbr br25
sudo brctl addbr br34
sudo brctl addbr br35
sudo brctl addbr br36
sudo brctl addbr br47
sudo brctl addbr br56
sudo brctl addbr br57
sudo brctl addbr brcollector

# Bring up all bridges
sudo ifconfig br12 up
sudo ifconfig br13 up
sudo ifconfig br24 up
sudo ifconfig br25 up
sudo ifconfig br34 up
sudo ifconfig br35 up
sudo ifconfig br36 up
sudo ifconfig br47 up
sudo ifconfig br56 up
sudo ifconfig br57 up
sudo ifconfig brcollector up

# Create veth pairs between probe generator and vpp 
sudo ip link add linux1 type veth peer name vpp1
sudo ip link add linux6 type veth peer name vpp6
sudo ip link add linux7 type veth peer name vpp7

# Create veth pair between PE nodes (vpp1, vpp6, vpp7 and vpp8) and collector 
sudo ip link add veth0 type veth peer name collector
sudo ip link add veth1 type veth peer name ext-vpp1
sudo ip link add veth6 type veth peer name ext-vpp6
sudo ip link add veth7 type veth peer name ext-vpp7
# Connect bridge with PE nodes to collector
sudo brctl addif brcollector veth0 veth1 veth6 veth7
# Configure probe collector ip address
sudo ip -6 address add 2001:db8:c:e::c/64 dev collector

# Bring up all veth
sudo ifconfig linux1 up
sudo ifconfig linux6 up
sudo ifconfig linux7 up
sudo ifconfig vpp1 up
sudo ifconfig vpp6 up
sudo ifconfig vpp7 up
sudo ifconfig veth0 up
sudo ifconfig veth1 up
sudo ifconfig veth6 up
sudo ifconfig veth7 up
sudo ifconfig collector up
sudo ifconfig ext-vpp1 up
sudo ifconfig ext-vpp6 up
sudo ifconfig ext-vpp7 up

# Create host-1, host-6, host-7, host-8 (in separate network namespaces)
# Setup routes to ping all vpp loopbacks and the other host respectively
sudo ip netns add ns-host-1
sudo ip link set host-1 netns ns-host-1                                                                 # move interface host-1 to new namespace
sudo ip netns exec ns-host-1 ip link set host-1 up
sudo ip netns exec ns-host-1 ip -6 address add 2001:db8:a:1::a/64 dev host-1                            #host-1 interface address
sudo ip netns exec ns-host-1 ip -6 address add fcbb:aa00:1::a/48 dev host-1                             #host-1 "loopback" address
sudo ip netns exec ns-host-1 ip -6 route add fcbb:bb00::/32 via 2001:db8:a:1::1 dev host-1  metric 1    #route to reach internal vpp-network loopbacks
sudo ip netns exec ns-host-1 ip -6 route add fcbb:aa00:7::/48 via 2001:db8:a:1::1 dev host-1 metric 1   #route to reach host-7 from host-1 via vpp network

sudo ip netns add ns-host-7
sudo ip link set host-7 netns ns-host-7                                                                 # move interface host-7 to new namespace
sudo ip netns exec ns-host-7 ip link set host-7 up
sudo ip netns exec ns-host-7 ip -6 address add 2001:db8:a:7::a/64 dev host-7                            #host-7 interface address
sudo ip netns exec ns-host-7 ip -6 address add fcbb:aa00:7::a/48 dev host-7                             #host-7 "loopback" address
sudo ip netns exec ns-host-7 ip -6 route add fcbb:bb00::/32 via 2001:db8:a:7::7 dev host-7  metric 1    #route to reach internal vpp-network loopbacks
sudo ip netns exec ns-host-7 ip -6 route add fcbb:aa00:1::/48 via 2001:db8:a:7::7 dev host-7 metric 1   #route to reach host-1 from host-7 via vpp network

#########################
# VPP 1
#########################
# Interfaces
sudo $VPPCTL_BINARY_PATH -s /run/vpp/cli.vpp1.sock loopback create-interface                                         # Loopback interface
sudo $VPPCTL_BINARY_PATH -s /run/vpp/cli.vpp1.sock set interface state loop0 up
sudo $VPPCTL_BINARY_PATH -s /run/vpp/cli.vpp1.sock enable ip6 interface loop0
sudo $VPPCTL_BINARY_PATH -s /run/vpp/cli.vpp1.sock set interface ip address loop0 fcbb:bb00:1::1/128

sudo $VPPCTL_BINARY_PATH -s /run/vpp/cli.vpp1.sock create tap id 10 host-bridge br13                                 # (vpp1) tap10 <-------> (vpp3) tap32
sudo $VPPCTL_BINARY_PATH -s /run/vpp/cli.vpp1.sock set interface state tap10 up
sudo $VPPCTL_BINARY_PATH -s /run/vpp/cli.vpp1.sock enable ip6 interface tap10
sudo $VPPCTL_BINARY_PATH -s /run/vpp/cli.vpp1.sock set interface ip address tap10 2001:db8:1:3::1/64

sudo $VPPCTL_BINARY_PATH -s /run/vpp/cli.vpp1.sock create tap id 11 host-bridge br12                                 # (vpp1) tap11 <-------> (vpp2) tap20
sudo $VPPCTL_BINARY_PATH -s /run/vpp/cli.vpp1.sock set interface state tap11 up
sudo $VPPCTL_BINARY_PATH -s /run/vpp/cli.vpp1.sock enable ip6 interface tap11
sudo $VPPCTL_BINARY_PATH -s /run/vpp/cli.vpp1.sock set interface ip address tap11 2001:db8:1:2::1/64

sudo $VPPCTL_BINARY_PATH -s /run/vpp/cli.vpp1.sock create host-interface name vpp1                                   # (vpp1) host-vpp1 <-------> (linux) linux1
sudo $VPPCTL_BINARY_PATH -s /run/vpp/cli.vpp1.sock set interface state host-vpp1 up                                  # used by probe-generator binary
sudo $VPPCTL_BINARY_PATH -s /run/vpp/cli.vpp1.sock enable ip6 interface host-vpp1 
sudo $VPPCTL_BINARY_PATH -s /run/vpp/cli.vpp1.sock set interface ip address host-vpp1 2001:db8:1:a::1/64

sudo $VPPCTL_BINARY_PATH -s /run/vpp/cli.vpp1.sock create host-interface name ext-vpp1                               # (vpp1) host-ext-vpp1 <-----> (linux) veth1
sudo $VPPCTL_BINARY_PATH -s /run/vpp/cli.vpp1.sock set interface state host-ext-vpp1 up                              # connecting vpp1 to probe collector
sudo $VPPCTL_BINARY_PATH -s /run/vpp/cli.vpp1.sock enable ip6 interface host-ext-vpp1 
sudo $VPPCTL_BINARY_PATH -s /run/vpp/cli.vpp1.sock set interface ip address host-ext-vpp1 2001:db8:c:e::1/64

sudo $VPPCTL_BINARY_PATH -s /run/vpp/cli.vpp1.sock create host-interface name client-vpp1                            # (linux) host-1 <-----> (vpp1) host-client-vpp1
sudo $VPPCTL_BINARY_PATH -s /run/vpp/cli.vpp1.sock set interface state host-client-vpp1 up                           # --> used to generate and push test traffic (e.g. ping, iperf3) into the network
sudo $VPPCTL_BINARY_PATH -s /run/vpp/cli.vpp1.sock enable ip6 interface host-client-vpp1
sudo $VPPCTL_BINARY_PATH -s /run/vpp/cli.vpp1.sock set interface ip address host-client-vpp1 2001:db8:a:1::1/64

sudo sleep 1
# Static Routing
sudo $VPPCTL_BINARY_PATH -s /run/vpp/cli.vpp1.sock ip route add fcbb:bb00:3::/48 via 2001:db8:1:3::3
sudo $VPPCTL_BINARY_PATH -s /run/vpp/cli.vpp1.sock ip route add fcbb:bb00:2::/48 via 2001:db8:1:2::2
sudo $VPPCTL_BINARY_PATH -s /run/vpp/cli.vpp1.sock ip route add fcbb:bb00:4::/48 via 2001:db8:1:3::3
sudo $VPPCTL_BINARY_PATH -s /run/vpp/cli.vpp1.sock ip route add fcbb:bb00:4::/48 via 2001:db8:1:2::2
sudo $VPPCTL_BINARY_PATH -s /run/vpp/cli.vpp1.sock ip route add fcbb:bb00:5::/48 via 2001:db8:1:3::3
sudo $VPPCTL_BINARY_PATH -s /run/vpp/cli.vpp1.sock ip route add fcbb:bb00:5::/48 via 2001:db8:1:2::2
sudo $VPPCTL_BINARY_PATH -s /run/vpp/cli.vpp1.sock ip route add fcbb:bb00:6::/48 via 2001:db8:1:3::3
sudo $VPPCTL_BINARY_PATH -s /run/vpp/cli.vpp1.sock ip route add fcbb:aa00:1::/48 via 2001:db8:a:1::a
sudo $VPPCTL_BINARY_PATH -s /run/vpp/cli.vpp1.sock ip route add fcbb:aa00:7::/48 via 2001:db8:1:2::2
sudo $VPPCTL_BINARY_PATH -s /run/vpp/cli.vpp1.sock ip route add fcbb:aa00:7::/48 via 2001:db8:1:3::3

# Path Tracing Configuration 
sudo $VPPCTL_BINARY_PATH -s /run/vpp/cli.vpp1.sock pt iface add iface tap10 id 11 tts-template ${TTS_TEMPLATE_VALUE}
sudo $VPPCTL_BINARY_PATH -s /run/vpp/cli.vpp1.sock pt iface add iface tap11 id 10 tts-template ${TTS_TEMPLATE_VALUE}
# TODO
# sudo $VPPCTL_BINARY_PATH -s /run/vpp/cli.vpp1.sock pt probe-inject-iface add iface host-vpp1 

# SRv6 Configuration
sudo $VPPCTL_BINARY_PATH -s /run/vpp/cli.vpp1.sock set sr encaps source addr 2001:db8:c:e::1
sudo $VPPCTL_BINARY_PATH -s /run/vpp/cli.vpp1.sock sr localsid prefix fcbb:bb00:1::/48 behavior un 16
sudo $VPPCTL_BINARY_PATH -s /run/vpp/cli.vpp1.sock sr localsid address fcbb:bb00:1::100 behavior end

# SRv6 Policies
sudo $VPPCTL_BINARY_PATH -s /run/vpp/cli.vpp1.sock sr policy add bsid fcbb:bb00:0001:f0ef:: next 2001:db8:c:e::c encap tef       # Steer pt probes towards collector

#########################
# VPP 2
#########################
# Interfaces
sudo $VPPCTL_BINARY_PATH -s /run/vpp/cli.vpp2.sock loopback create-interface
sudo $VPPCTL_BINARY_PATH -s /run/vpp/cli.vpp2.sock set interface state loop0 up
sudo $VPPCTL_BINARY_PATH -s /run/vpp/cli.vpp2.sock enable ip6 interface loop0
sudo $VPPCTL_BINARY_PATH -s /run/vpp/cli.vpp2.sock set interface ip address loop0 fcbb:bb00:2::1/128

sudo $VPPCTL_BINARY_PATH -s /run/vpp/cli.vpp2.sock create tap id 20 host-bridge br12
sudo $VPPCTL_BINARY_PATH -s /run/vpp/cli.vpp2.sock set interface state tap20 up
sudo $VPPCTL_BINARY_PATH -s /run/vpp/cli.vpp2.sock enable ip6 interface tap20
sudo $VPPCTL_BINARY_PATH -s /run/vpp/cli.vpp2.sock set interface ip address tap20 2001:db8:1:2::2/64

sudo $VPPCTL_BINARY_PATH -s /run/vpp/cli.vpp2.sock create tap id 21 host-bridge br25 
sudo $VPPCTL_BINARY_PATH -s /run/vpp/cli.vpp2.sock set interface state tap21 up
sudo $VPPCTL_BINARY_PATH -s /run/vpp/cli.vpp2.sock enable ip6 interface tap21
sudo $VPPCTL_BINARY_PATH -s /run/vpp/cli.vpp2.sock set interface ip address tap21 2001:db8:2:5::2/64

sudo $VPPCTL_BINARY_PATH -s /run/vpp/cli.vpp2.sock create tap id 22 host-bridge br24
sudo $VPPCTL_BINARY_PATH -s /run/vpp/cli.vpp2.sock set interface state tap22 up
sudo $VPPCTL_BINARY_PATH -s /run/vpp/cli.vpp2.sock enable ip6 interface tap22
sudo $VPPCTL_BINARY_PATH -s /run/vpp/cli.vpp2.sock set interface ip address tap22 2001:db8:2:4::2/64

sudo sleep 1
# Static Routing
sudo $VPPCTL_BINARY_PATH -s /run/vpp/cli.vpp2.sock ip route add fcbb:bb00:1::/48 via 2001:db8:1:2::1
sudo $VPPCTL_BINARY_PATH -s /run/vpp/cli.vpp2.sock ip route add fcbb:bb00:4::/48 via 2001:db8:2:4::4
sudo $VPPCTL_BINARY_PATH -s /run/vpp/cli.vpp2.sock ip route add fcbb:bb00:5::/48 via 2001:db8:2:5::5
sudo $VPPCTL_BINARY_PATH -s /run/vpp/cli.vpp2.sock ip route add fcbb:bb00:3::/48 via 2001:db8:1:2::1
sudo $VPPCTL_BINARY_PATH -s /run/vpp/cli.vpp2.sock ip route add fcbb:bb00:3::/48 via 2001:db8:2:5::5
sudo $VPPCTL_BINARY_PATH -s /run/vpp/cli.vpp2.sock ip route add fcbb:bb00:6::/48 via 2001:db8:2:5::5
sudo $VPPCTL_BINARY_PATH -s /run/vpp/cli.vpp2.sock ip route add fcbb:bb00:7::/48 via 2001:db8:2:4::4
sudo $VPPCTL_BINARY_PATH -s /run/vpp/cli.vpp2.sock ip route add fcbb:bb00:7::/48 via 2001:db8:2:5::5
sudo $VPPCTL_BINARY_PATH -s /run/vpp/cli.vpp2.sock ip route add fcbb:aa00:1::/48 via 2001:db8:1:2::1
sudo $VPPCTL_BINARY_PATH -s /run/vpp/cli.vpp2.sock ip route add fcbb:aa00:7::/48 via 2001:db8:2:4::4
sudo $VPPCTL_BINARY_PATH -s /run/vpp/cli.vpp2.sock ip route add fcbb:aa00:7::/48 via 2001:db8:2:5::5

# Path Tracing Configuration
sudo $VPPCTL_BINARY_PATH -s /run/vpp/cli.vpp2.sock pt iface add iface tap20 id 20 tts-template ${TTS_TEMPLATE_VALUE}
sudo $VPPCTL_BINARY_PATH -s /run/vpp/cli.vpp2.sock pt iface add iface tap21 id 21 tts-template ${TTS_TEMPLATE_VALUE}
sudo $VPPCTL_BINARY_PATH -s /run/vpp/cli.vpp2.sock pt iface add iface tap22 id 22 tts-template ${TTS_TEMPLATE_VALUE}

# SRv6 Configuration
sudo $VPPCTL_BINARY_PATH -s /run/vpp/cli.vpp2.sock set sr encaps source addr fcbb:bb00:2::1
sudo $VPPCTL_BINARY_PATH -s /run/vpp/cli.vpp2.sock sr localsid prefix fcbb:bb00:2::/48 behavior un 16
sudo $VPPCTL_BINARY_PATH -s /run/vpp/cli.vpp2.sock sr localsid address fcbb:bb00:2::100 behavior end

#########################
# VPP 3
#########################
# Interfaces
sudo $VPPCTL_BINARY_PATH -s /run/vpp/cli.vpp3.sock loopback create-interface
sudo $VPPCTL_BINARY_PATH -s /run/vpp/cli.vpp3.sock set interface state loop0 up
sudo $VPPCTL_BINARY_PATH -s /run/vpp/cli.vpp3.sock enable ip6 interface loop0
sudo $VPPCTL_BINARY_PATH -s /run/vpp/cli.vpp3.sock set interface ip address loop0 fcbb:bb00:3::1/128

sudo $VPPCTL_BINARY_PATH -s /run/vpp/cli.vpp3.sock create tap id 30 host-bridge br35
sudo $VPPCTL_BINARY_PATH -s /run/vpp/cli.vpp3.sock set interface state tap30 up
sudo $VPPCTL_BINARY_PATH -s /run/vpp/cli.vpp3.sock enable ip6 interface tap30
sudo $VPPCTL_BINARY_PATH -s /run/vpp/cli.vpp3.sock set interface ip address tap30 2001:db8:3:5::3/64

sudo $VPPCTL_BINARY_PATH -s /run/vpp/cli.vpp3.sock create tap id 31 host-bridge br34 
sudo $VPPCTL_BINARY_PATH -s /run/vpp/cli.vpp3.sock set interface state tap31 up
sudo $VPPCTL_BINARY_PATH -s /run/vpp/cli.vpp3.sock enable ip6 interface tap31
sudo $VPPCTL_BINARY_PATH -s /run/vpp/cli.vpp3.sock set interface ip address tap31 2001:db8:3:4::3/64

sudo $VPPCTL_BINARY_PATH -s /run/vpp/cli.vpp3.sock create tap id 32 host-bridge br13
sudo $VPPCTL_BINARY_PATH -s /run/vpp/cli.vpp3.sock set interface state tap32 up
sudo $VPPCTL_BINARY_PATH -s /run/vpp/cli.vpp3.sock enable ip6 interface tap32
sudo $VPPCTL_BINARY_PATH -s /run/vpp/cli.vpp3.sock set interface ip address tap32 2001:db8:1:3::3/64

sudo $VPPCTL_BINARY_PATH -s /run/vpp/cli.vpp3.sock create tap id 33 host-bridge br36
sudo $VPPCTL_BINARY_PATH -s /run/vpp/cli.vpp3.sock set interface state tap33 up
sudo $VPPCTL_BINARY_PATH -s /run/vpp/cli.vpp3.sock enable ip6 interface tap33
sudo $VPPCTL_BINARY_PATH -s /run/vpp/cli.vpp3.sock set interface ip address tap33 2001:db8:3:6::3/64

sudo sleep 1
# Static Routing
sudo $VPPCTL_BINARY_PATH -s /run/vpp/cli.vpp3.sock ip route add fcbb:bb00:1::/48 via 2001:db8:1:3::1
sudo $VPPCTL_BINARY_PATH -s /run/vpp/cli.vpp3.sock ip route add fcbb:bb00:4::/48 via 2001:db8:3:4::4
sudo $VPPCTL_BINARY_PATH -s /run/vpp/cli.vpp3.sock ip route add fcbb:bb00:5::/48 via 2001:db8:3:5::5
sudo $VPPCTL_BINARY_PATH -s /run/vpp/cli.vpp3.sock ip route add fcbb:bb00:2::/48 via 2001:db8:1:3::1
sudo $VPPCTL_BINARY_PATH -s /run/vpp/cli.vpp3.sock ip route add fcbb:bb00:2::/48 via 2001:db8:3:4::4
sudo $VPPCTL_BINARY_PATH -s /run/vpp/cli.vpp3.sock ip route add fcbb:bb00:6::/48 via 2001:db8:3:6::6
sudo $VPPCTL_BINARY_PATH -s /run/vpp/cli.vpp3.sock ip route add fcbb:bb00:7::/48 via 2001:db8:3:4::4
sudo $VPPCTL_BINARY_PATH -s /run/vpp/cli.vpp3.sock ip route add fcbb:bb00:7::/48 via 2001:db8:3:5::5
sudo $VPPCTL_BINARY_PATH -s /run/vpp/cli.vpp3.sock ip route add fcbb:aa00:1::/48 via 2001:db8:1:3::1
sudo $VPPCTL_BINARY_PATH -s /run/vpp/cli.vpp3.sock ip route add fcbb:aa00:7::/48 via 2001:db8:3:4::4
sudo $VPPCTL_BINARY_PATH -s /run/vpp/cli.vpp3.sock ip route add fcbb:aa00:7::/48 via 2001:db8:3:5::5


# Path Tracing Configuration
sudo $VPPCTL_BINARY_PATH -s /run/vpp/cli.vpp3.sock pt iface add iface tap30 id 30 tts-template ${TTS_TEMPLATE_VALUE} 
sudo $VPPCTL_BINARY_PATH -s /run/vpp/cli.vpp3.sock pt iface add iface tap31 id 31 tts-template ${TTS_TEMPLATE_VALUE}
sudo $VPPCTL_BINARY_PATH -s /run/vpp/cli.vpp3.sock pt iface add iface tap32 id 32 tts-template ${TTS_TEMPLATE_VALUE}
sudo $VPPCTL_BINARY_PATH -s /run/vpp/cli.vpp3.sock pt iface add iface tap33 id 33 tts-template ${TTS_TEMPLATE_VALUE}

# SRv6 Configuration
sudo $VPPCTL_BINARY_PATH -s /run/vpp/cli.vpp3.sock set sr encaps source addr fcbb:bb00:3::1
sudo $VPPCTL_BINARY_PATH -s /run/vpp/cli.vpp3.sock sr localsid prefix fcbb:bb00:3::/48 behavior un 16
sudo $VPPCTL_BINARY_PATH -s /run/vpp/cli.vpp3.sock sr localsid address fcbb:bb00:3::100 behavior end

#########################
# VPP 4
#########################
# Interfaces
sudo $VPPCTL_BINARY_PATH -s /run/vpp/cli.vpp4.sock loopback create-interface
sudo $VPPCTL_BINARY_PATH -s /run/vpp/cli.vpp4.sock set interface state loop0 up
sudo $VPPCTL_BINARY_PATH -s /run/vpp/cli.vpp4.sock enable ip6 interface loop0
sudo $VPPCTL_BINARY_PATH -s /run/vpp/cli.vpp4.sock set interface ip address loop0 fcbb:bb00:4::1/128

sudo $VPPCTL_BINARY_PATH -s /run/vpp/cli.vpp4.sock create tap id 40 host-bridge br24
sudo $VPPCTL_BINARY_PATH -s /run/vpp/cli.vpp4.sock set interface state tap40 up
sudo $VPPCTL_BINARY_PATH -s /run/vpp/cli.vpp4.sock enable ip6 interface tap40
sudo $VPPCTL_BINARY_PATH -s /run/vpp/cli.vpp4.sock set interface ip address tap40 2001:db8:2:4::4/64

sudo $VPPCTL_BINARY_PATH -s /run/vpp/cli.vpp4.sock create tap id 41 host-bridge br34
sudo $VPPCTL_BINARY_PATH -s /run/vpp/cli.vpp4.sock set interface state tap41 up
sudo $VPPCTL_BINARY_PATH -s /run/vpp/cli.vpp4.sock enable ip6 interface tap41
sudo $VPPCTL_BINARY_PATH -s /run/vpp/cli.vpp4.sock set interface ip address tap41 2001:db8:3:4::4/64

sudo $VPPCTL_BINARY_PATH -s /run/vpp/cli.vpp4.sock create tap id 42 host-bridge br47
sudo $VPPCTL_BINARY_PATH -s /run/vpp/cli.vpp4.sock set interface state tap42 up
sudo $VPPCTL_BINARY_PATH -s /run/vpp/cli.vpp4.sock enable ip6 interface tap42
sudo $VPPCTL_BINARY_PATH -s /run/vpp/cli.vpp4.sock set interface ip address tap42 2001:db8:4:7::4/64

sudo sleep 1
# Static Routing
sudo $VPPCTL_BINARY_PATH -s /run/vpp/cli.vpp4.sock ip route add fcbb:bb00:2::/48 via 2001:db8:2:4::2
sudo $VPPCTL_BINARY_PATH -s /run/vpp/cli.vpp4.sock ip route add fcbb:bb00:3::/48 via 2001:db8:3:4::3
sudo $VPPCTL_BINARY_PATH -s /run/vpp/cli.vpp4.sock ip route add fcbb:bb00:5::/48 via 2001:db8:2:4::2
sudo $VPPCTL_BINARY_PATH -s /run/vpp/cli.vpp4.sock ip route add fcbb:bb00:5::/48 via 2001:db8:4:7::7
sudo $VPPCTL_BINARY_PATH -s /run/vpp/cli.vpp4.sock ip route add fcbb:bb00:6::/48 via 2001:db8:2:4::2
sudo $VPPCTL_BINARY_PATH -s /run/vpp/cli.vpp4.sock ip route add fcbb:bb00:6::/48 via 2001:db8:4:7::7
sudo $VPPCTL_BINARY_PATH -s /run/vpp/cli.vpp4.sock ip route add fcbb:bb00:7::/48 via 2001:db8:4:7::7
sudo $VPPCTL_BINARY_PATH -s /run/vpp/cli.vpp4.sock ip route add fcbb:bb00:1::/48 via 2001:db8:2:4::2
sudo $VPPCTL_BINARY_PATH -s /run/vpp/cli.vpp4.sock ip route add fcbb:bb00:1::/48 via 2001:db8:3:4::3
sudo $VPPCTL_BINARY_PATH -s /run/vpp/cli.vpp4.sock ip route add fcbb:aa00:1::/48 via 2001:db8:2:4::2
sudo $VPPCTL_BINARY_PATH -s /run/vpp/cli.vpp4.sock ip route add fcbb:aa00:1::/48 via 2001:db8:3:4::3
sudo $VPPCTL_BINARY_PATH -s /run/vpp/cli.vpp4.sock ip route add fcbb:aa00:7::/48 via 2001:db8:4:7::7

# Path Tracing Configuration 
sudo $VPPCTL_BINARY_PATH -s /run/vpp/cli.vpp4.sock pt iface add iface tap40 id 40 tts-template ${TTS_TEMPLATE_VALUE}
sudo $VPPCTL_BINARY_PATH -s /run/vpp/cli.vpp4.sock pt iface add iface tap41 id 41 tts-template ${TTS_TEMPLATE_VALUE}
sudo $VPPCTL_BINARY_PATH -s /run/vpp/cli.vpp4.sock pt iface add iface tap42 id 42 tts-template ${TTS_TEMPLATE_VALUE}

# SRv6 Configuration
sudo $VPPCTL_BINARY_PATH -s /run/vpp/cli.vpp4.sock set sr encaps source addr fcbb:bb00:4::1
sudo $VPPCTL_BINARY_PATH -s /run/vpp/cli.vpp4.sock sr localsid prefix fcbb:bb00:4::/48 behavior un 16
sudo $VPPCTL_BINARY_PATH -s /run/vpp/cli.vpp4.sock sr localsid address fcbb:bb00:4::100 behavior end

#########################
# VPP 5
#########################
# Interfaces
sudo $VPPCTL_BINARY_PATH -s /run/vpp/cli.vpp5.sock loopback create-interface
sudo $VPPCTL_BINARY_PATH -s /run/vpp/cli.vpp5.sock set interface state loop0 up
sudo $VPPCTL_BINARY_PATH -s /run/vpp/cli.vpp5.sock enable ip6 interface loop0
sudo $VPPCTL_BINARY_PATH -s /run/vpp/cli.vpp5.sock set interface ip address loop0 fcbb:bb00:5::1/128

sudo $VPPCTL_BINARY_PATH -s /run/vpp/cli.vpp5.sock create tap id 50 host-bridge br35
sudo $VPPCTL_BINARY_PATH -s /run/vpp/cli.vpp5.sock set interface state tap50 up
sudo $VPPCTL_BINARY_PATH -s /run/vpp/cli.vpp5.sock enable ip6 interface tap50
sudo $VPPCTL_BINARY_PATH -s /run/vpp/cli.vpp5.sock set interface ip address tap50 2001:db8:3:5::5/64

sudo $VPPCTL_BINARY_PATH -s /run/vpp/cli.vpp5.sock create tap id 51 host-bridge br57
sudo $VPPCTL_BINARY_PATH -s /run/vpp/cli.vpp5.sock set interface state tap51 up
sudo $VPPCTL_BINARY_PATH -s /run/vpp/cli.vpp5.sock enable ip6 interface tap51
sudo $VPPCTL_BINARY_PATH -s /run/vpp/cli.vpp5.sock set interface ip address tap51 2001:db8:5:7::5/64

sudo $VPPCTL_BINARY_PATH -s /run/vpp/cli.vpp5.sock create tap id 52 host-bridge br25
sudo $VPPCTL_BINARY_PATH -s /run/vpp/cli.vpp5.sock set interface state tap52 up
sudo $VPPCTL_BINARY_PATH -s /run/vpp/cli.vpp5.sock enable ip6 interface tap52
sudo $VPPCTL_BINARY_PATH -s /run/vpp/cli.vpp5.sock set interface ip address tap52 2001:db8:2:5::5/64

sudo $VPPCTL_BINARY_PATH -s /run/vpp/cli.vpp5.sock create tap id 53 host-bridge br56
sudo $VPPCTL_BINARY_PATH -s /run/vpp/cli.vpp5.sock set interface state tap53 up
sudo $VPPCTL_BINARY_PATH -s /run/vpp/cli.vpp5.sock enable ip6 interface tap53
sudo $VPPCTL_BINARY_PATH -s /run/vpp/cli.vpp5.sock set interface ip address tap53 2001:db8:5:6::5/64

sudo sleep 1
# Static Routing
sudo $VPPCTL_BINARY_PATH -s /run/vpp/cli.vpp5.sock ip route add fcbb:bb00:2::/48 via 2001:db8:2:5::2
sudo $VPPCTL_BINARY_PATH -s /run/vpp/cli.vpp5.sock ip route add fcbb:bb00:3::/48 via 2001:db8:3:5::3
sudo $VPPCTL_BINARY_PATH -s /run/vpp/cli.vpp5.sock ip route add fcbb:bb00:6::/48 via 2001:db8:5:6::6
sudo $VPPCTL_BINARY_PATH -s /run/vpp/cli.vpp5.sock ip route add fcbb:bb00:7::/48 via 2001:db8:5:7::7
sudo $VPPCTL_BINARY_PATH -s /run/vpp/cli.vpp5.sock ip route add fcbb:bb00:1::/48 via 2001:db8:3:5::3
sudo $VPPCTL_BINARY_PATH -s /run/vpp/cli.vpp5.sock ip route add fcbb:bb00:1::/48 via 2001:db8:2:5::2
sudo $VPPCTL_BINARY_PATH -s /run/vpp/cli.vpp5.sock ip route add fcbb:bb00:4::/48 via 2001:db8:2:5::2
sudo $VPPCTL_BINARY_PATH -s /run/vpp/cli.vpp5.sock ip route add fcbb:bb00:4::/48 via 2001:db8:5:7::7
sudo $VPPCTL_BINARY_PATH -s /run/vpp/cli.vpp5.sock ip route add fcbb:aa00:1::/48 via 2001:db8:3:5::3
sudo $VPPCTL_BINARY_PATH -s /run/vpp/cli.vpp5.sock ip route add fcbb:aa00:1::/48 via 2001:db8:2:5::2
sudo $VPPCTL_BINARY_PATH -s /run/vpp/cli.vpp5.sock ip route add fcbb:aa00:7::/48 via 2001:db8:5:7::7

# Path Tracing Configuration 
sudo $VPPCTL_BINARY_PATH -s /run/vpp/cli.vpp5.sock pt iface add iface tap50 id 50 tts-template ${TTS_TEMPLATE_VALUE}
sudo $VPPCTL_BINARY_PATH -s /run/vpp/cli.vpp5.sock pt iface add iface tap51 id 51 tts-template ${TTS_TEMPLATE_VALUE}
sudo $VPPCTL_BINARY_PATH -s /run/vpp/cli.vpp5.sock pt iface add iface tap52 id 52 tts-template ${TTS_TEMPLATE_VALUE}
sudo $VPPCTL_BINARY_PATH -s /run/vpp/cli.vpp5.sock pt iface add iface tap53 id 53 tts-template ${TTS_TEMPLATE_VALUE}

# SRv6 Configuration
sudo $VPPCTL_BINARY_PATH -s /run/vpp/cli.vpp5.sock set sr encaps source addr fcbb:bb00:5::1
sudo $VPPCTL_BINARY_PATH -s /run/vpp/cli.vpp5.sock sr localsid prefix fcbb:bb00:5::/48 behavior un 16
sudo $VPPCTL_BINARY_PATH -s /run/vpp/cli.vpp5.sock sr localsid address fcbb:bb00:5::100 behavior end


#########################
# VPP 6
#########################
# Interfaces
sudo $VPPCTL_BINARY_PATH -s /run/vpp/cli.vpp6.sock loopback create-interface
sudo $VPPCTL_BINARY_PATH -s /run/vpp/cli.vpp6.sock set interface state loop0 up
sudo $VPPCTL_BINARY_PATH -s /run/vpp/cli.vpp6.sock enable ip6 interface loop0
sudo $VPPCTL_BINARY_PATH -s /run/vpp/cli.vpp6.sock set interface ip address loop0 fcbb:bb00:6::1/128

sudo $VPPCTL_BINARY_PATH -s /run/vpp/cli.vpp6.sock create tap id 60 host-bridge br36
sudo $VPPCTL_BINARY_PATH -s /run/vpp/cli.vpp6.sock set interface state tap60 up
sudo $VPPCTL_BINARY_PATH -s /run/vpp/cli.vpp6.sock enable ip6 interface tap60
sudo $VPPCTL_BINARY_PATH -s /run/vpp/cli.vpp6.sock set interface ip address tap60 2001:db8:3:6::6/64

sudo $VPPCTL_BINARY_PATH -s /run/vpp/cli.vpp6.sock create tap id 61 host-bridge br56
sudo $VPPCTL_BINARY_PATH -s /run/vpp/cli.vpp6.sock set interface state tap61 up
sudo $VPPCTL_BINARY_PATH -s /run/vpp/cli.vpp6.sock enable ip6 interface tap61
sudo $VPPCTL_BINARY_PATH -s /run/vpp/cli.vpp6.sock set interface ip address tap61 2001:db8:5:6::6/64

sudo sleep 1
# Static Routing
sudo $VPPCTL_BINARY_PATH -s /run/vpp/cli.vpp6.sock ip route add fcbb:bb00:2::/48 via 2001:db8:2:5::5
sudo $VPPCTL_BINARY_PATH -s /run/vpp/cli.vpp6.sock ip route add fcbb:bb00:4::/48 via 2001:db8:3:6::3
sudo $VPPCTL_BINARY_PATH -s /run/vpp/cli.vpp6.sock ip route add fcbb:bb00:1::/48 via 2001:db8:3:6::3
sudo $VPPCTL_BINARY_PATH -s /run/vpp/cli.vpp6.sock ip route add fcbb:bb00:3::/48 via 2001:db8:3:6::3
sudo $VPPCTL_BINARY_PATH -s /run/vpp/cli.vpp6.sock ip route add fcbb:bb00:5::/48 via 2001:db8:5:6::5
sudo $VPPCTL_BINARY_PATH -s /run/vpp/cli.vpp6.sock ip route add fcbb:bb00:7::/48 via 2001:db8:5:6::5
sudo $VPPCTL_BINARY_PATH -s /run/vpp/cli.vpp6.sock ip route add fcbb:aa00:1::/48 via 2001:db8:3:6::3
sudo $VPPCTL_BINARY_PATH -s /run/vpp/cli.vpp6.sock ip route add fcbb:aa00:7::/48 via 2001:db8:5:6::5

# Path Tracing Configuration 
sudo $VPPCTL_BINARY_PATH -s /run/vpp/cli.vpp6.sock pt iface add iface tap60 id 60 tts-template ${TTS_TEMPLATE_VALUE}
sudo $VPPCTL_BINARY_PATH -s /run/vpp/cli.vpp6.sock pt iface add iface tap61 id 61 tts-template ${TTS_TEMPLATE_VALUE}

# SRv6 Configuration
sudo $VPPCTL_BINARY_PATH -s /run/vpp/cli.vpp6.sock set sr encaps source addr 2001:db8:c:e::6
sudo $VPPCTL_BINARY_PATH -s /run/vpp/cli.vpp6.sock sr localsid prefix fcbb:bb00:6::/48 behavior un 16
sudo $VPPCTL_BINARY_PATH -s /run/vpp/cli.vpp6.sock sr localsid address fcbb:bb00:6::100 behavior end

#########################
# VPP 7
#########################
# Interfaces
sudo $VPPCTL_BINARY_PATH -s /run/vpp/cli.vpp7.sock loopback create-interface
sudo $VPPCTL_BINARY_PATH -s /run/vpp/cli.vpp7.sock set interface state loop0 up
sudo $VPPCTL_BINARY_PATH -s /run/vpp/cli.vpp7.sock enable ip6 interface loop0
sudo $VPPCTL_BINARY_PATH -s /run/vpp/cli.vpp7.sock set interface ip address loop0 fcbb:bb00:7::1/128

sudo $VPPCTL_BINARY_PATH -s /run/vpp/cli.vpp7.sock create tap id 70 host-bridge br47
sudo $VPPCTL_BINARY_PATH -s /run/vpp/cli.vpp7.sock set interface state tap70 up
sudo $VPPCTL_BINARY_PATH -s /run/vpp/cli.vpp7.sock enable ip6 interface tap70
sudo $VPPCTL_BINARY_PATH -s /run/vpp/cli.vpp7.sock set interface ip address tap70 2001:db8:4:7::7/64

sudo $VPPCTL_BINARY_PATH -s /run/vpp/cli.vpp7.sock create tap id 71 host-bridge br57
sudo $VPPCTL_BINARY_PATH -s /run/vpp/cli.vpp7.sock set interface state tap71 up
sudo $VPPCTL_BINARY_PATH -s /run/vpp/cli.vpp7.sock enable ip6 interface tap71
sudo $VPPCTL_BINARY_PATH -s /run/vpp/cli.vpp7.sock set interface ip address tap71 2001:db8:5:7::7/64

sudo $VPPCTL_BINARY_PATH -s /run/vpp/cli.vpp7.sock create host-interface name vpp7                                   # (vpp7) host-vpp7 <-------> (linux) linux7
sudo $VPPCTL_BINARY_PATH -s /run/vpp/cli.vpp7.sock set interface state host-vpp7 up                                  # used by probe-generator binary
sudo $VPPCTL_BINARY_PATH -s /run/vpp/cli.vpp7.sock enable ip6 interface host-vpp7 
sudo $VPPCTL_BINARY_PATH -s /run/vpp/cli.vpp7.sock set interface ip address host-vpp7 2001:db8:7:a::67/64

sudo $VPPCTL_BINARY_PATH -s /run/vpp/cli.vpp7.sock create host-interface name ext-vpp7                               # (vpp7) host-ext-vpp7 <-----> (linux) veth7
sudo $VPPCTL_BINARY_PATH -s /run/vpp/cli.vpp7.sock set interface state host-ext-vpp7 up                              # connecting vpp7 to probe collector
sudo $VPPCTL_BINARY_PATH -s /run/vpp/cli.vpp7.sock enable ip6 interface host-ext-vpp7 
sudo $VPPCTL_BINARY_PATH -s /run/vpp/cli.vpp7.sock set interface ip address host-ext-vpp7 2001:db8:c:e::7/64

sudo $VPPCTL_BINARY_PATH -s /run/vpp/cli.vpp7.sock create host-interface name client-vpp7                            # (linux) host-7 <-----> (vpp7) host-client-vpp7
sudo $VPPCTL_BINARY_PATH -s /run/vpp/cli.vpp7.sock set interface state host-client-vpp7 up                           # --> used to generate and push test traffic (e.g. ping, iperf3) into the network
sudo $VPPCTL_BINARY_PATH -s /run/vpp/cli.vpp7.sock enable ip6 interface host-client-vpp7
sudo $VPPCTL_BINARY_PATH -s /run/vpp/cli.vpp7.sock set interface ip address host-client-vpp7 2001:db8:a:7::7/64

sudo sleep 1
# Static Routing
sudo $VPPCTL_BINARY_PATH -s /run/vpp/cli.vpp7.sock ip route add fcbb:bb00:4::/48 via 2001:db8:4:7::4
sudo $VPPCTL_BINARY_PATH -s /run/vpp/cli.vpp7.sock ip route add fcbb:bb00:5::/48 via 2001:db8:5:7::5
sudo $VPPCTL_BINARY_PATH -s /run/vpp/cli.vpp7.sock ip route add fcbb:bb00:6::/48 via 2001:db8:5:7::5
sudo $VPPCTL_BINARY_PATH -s /run/vpp/cli.vpp7.sock ip route add fcbb:bb00:1::/48 via 2001:db8:4:7::4
sudo $VPPCTL_BINARY_PATH -s /run/vpp/cli.vpp7.sock ip route add fcbb:bb00:1::/48 via 2001:db8:5:7::5
sudo $VPPCTL_BINARY_PATH -s /run/vpp/cli.vpp7.sock ip route add fcbb:bb00:2::/48 via 2001:db8:4:7::4
sudo $VPPCTL_BINARY_PATH -s /run/vpp/cli.vpp7.sock ip route add fcbb:bb00:3::/48 via 2001:db8:4:7::4
sudo $VPPCTL_BINARY_PATH -s /run/vpp/cli.vpp7.sock ip route add fcbb:bb00:3::/48 via 2001:db8:5:7::5
sudo $VPPCTL_BINARY_PATH -s /run/vpp/cli.vpp7.sock ip route add fcbb:aa00:1::/48 via 2001:db8:4:7::4
sudo $VPPCTL_BINARY_PATH -s /run/vpp/cli.vpp7.sock ip route add fcbb:aa00:1::/48 via 2001:db8:5:7::5
sudo $VPPCTL_BINARY_PATH -s /run/vpp/cli.vpp7.sock ip route add fcbb:aa00:7::/48 via 2001:db8:a:7::a


# Path Tracing Configuration 
sudo $VPPCTL_BINARY_PATH -s /run/vpp/cli.vpp7.sock pt iface add iface tap70 id 70 tts-template ${TTS_TEMPLATE_VALUE}
sudo $VPPCTL_BINARY_PATH -s /run/vpp/cli.vpp7.sock pt iface add iface tap71 id 71 tts-template ${TTS_TEMPLATE_VALUE}
# TODO
# sudo $VPPCTL_BINARY_PATH -s /run/vpp/cli.vpp7.sock pt probe-inject-iface add iface host-vpp7 

# SRv6 Configuration
sudo $VPPCTL_BINARY_PATH -s /run/vpp/cli.vpp7.sock set sr encaps source addr 2001:db8:c:e::7
sudo $VPPCTL_BINARY_PATH -s /run/vpp/cli.vpp7.sock sr localsid prefix fcbb:bb00:7::/48 behavior un 16
sudo $VPPCTL_BINARY_PATH -s /run/vpp/cli.vpp7.sock sr localsid address fcbb:bb00:7::100 behavior end

# SRv6 Policies
sudo $VPPCTL_BINARY_PATH -s /run/vpp/cli.vpp7.sock sr policy add bsid fcbb:bb00:0007:f0ef:: next 2001:db8:c:e::c encap tef

##################################################
# Ping to startup network & arp
##################################################
sudo ip netns exec ns-host-1 ping fcbb:aa00:7::a -c 5 &
sudo ip netns exec ns-host-7 ping fcbb:aa00:1::a -c 5 &
sleep 10