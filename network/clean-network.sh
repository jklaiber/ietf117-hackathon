#!/bin/bash

# kill all vpp instances 
echo "Killing all vpp instances"
sudo kill $(pidof vpp)

## Bring down host namespaces
echo "Delete host namespaces"
sudo ip netns del ns-host-1
sudo ip netns del ns-host-7

# If not successful remove the client-vpp1 and client-vpp8 interfaces manually
if [ $? -eq 0 ]; then
   echo "Bringing all interfaces and bridges down..."
else
   echo "Somehow ns's not tear down correctly, solving..."
   echo "Bringing all interfaces and bridges down..."
   sudo ifconfig client-vpp1 down
   sudo ifconfig client vpp7 down
   sudo ip link del client-vpp1
   sudo ip link del client-vpp7
fi

# bring all bridges down 
sudo ifconfig br12 down
sudo ifconfig br13 down
sudo ifconfig br24 down
sudo ifconfig br25 down
sudo ifconfig br34 down
sudo ifconfig br35 down
sudo ifconfig br36 down
sudo ifconfig br47 down
sudo ifconfig br56 down
sudo ifconfig br57 down
sudo ifconfig brcollector down

# delete all linux bridges 
sudo brctl delbr br12
sudo brctl delbr br13
sudo brctl delbr br24
sudo brctl delbr br25
sudo brctl delbr br34
sudo brctl delbr br35
sudo brctl delbr br36
sudo brctl delbr br47
sudo brctl delbr br56
sudo brctl delbr br57
sudo brctl delbr brcollector

# delete all veth pairs 
sudo ip link delete linux1 type veth peer name vpp1
sudo ip link delete linux7 type veth peer name vpp7
sudo ip link delete veth0 type veth peer name collector
sudo ip link delete veth1 type veth peer name ext-vpp1
sudo ip link delete veth7 type veth peer name ext-vpp7