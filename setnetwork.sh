#!/bin/bash

echo "Hostname (fqdn):"
read hostname
if [ "$hostname" = "" ]; then
        echo "Hostname is mandatory!"
        exit 1
fi

echo "IP adress:"
read ip
if [ "$ip" = "" ]; then
        echo "IP is mandatory!"
        exit 1
fi

IFS='.' read -a ipd <<< "$ip"
ipnet="${ipd[0]}.${ipd[1]}.${ipd[2]}"
brcast="$ipnet.255"
netw="$ipnet.0"

echo "Netmask: [255.255.255.0]"
read mask
if [ "$mask" = "" ]; then
        mask="255.255.255.0"
fi

echo "Gateway: [192.168.15.1]"
read gw
if [ "$gw" = "" ]; then
        gw="192.168.15.1"
fi

echo "Network: [$netw]"
read network
if [ "$network" = "" ]; then
        network="$netw"
fi

echo "Broadcast: [$brcast]"
read broadcast
if [ "$broadcast" = "" ]; then
        broadcast="$brcast"
fi

echo "DNS Server: [192.168.15.1]"
read dns
if [ "$dns" = "" ]; then
        dns="192.168.15.1"
fi

echo "DNS Search: [l4rs.net]"
read dnssearch
if [ "$dnssearch" = "" ]; then
        dnssearch="l4rs.net"
fi

ip a
echo "NIC interface [ens18]:"
read nic
if [ "$nic" = "" ]; then
        nic="ens18"
fi

IFS='.' read -a ipd <<< "$ip"
ipnet="${ipd[0]}.${ipd[1]}.${ipd[2]}"
broadcast="$ipnet.255"
network="$ipnet.0"

echo "Please confirm:"
echo "############################"
echo "Hostname (fqdn): " $hostname
echo "IP: " $ip
echo "Netmask: " $mask
echo "Gateway :" $gw
echo "DNS Server: "$dns
echo "DNS Search: "$dnssearch
echo "NIC: "$nic
echo "Network: "$network
echo "Broadcast: "$broadcast
echo ""
echo "Set hostname and network config? [y/N]:"
read confirm
if [ "$confirm" != "y" ]; then
      echo "cancel...."
      exit 1
fi

echo "setting NIC...."
rm -rf /tmp/interfaces && awk -f changeInterface.awk /etc/network/interfaces action=remove device=$nic >> /tmp/interfaces
rm -rf /tmp/interfaces2 && awk -f changeInterface.awk /tmp/interfaces action=add device=$nic mode=static address=$ip netmask=$mask \
 gateway=$gw broadcast=$broadcast network=$network >> /tmp/interfaces2
awk -f changeInterface.awk /tmp/interfaces2 device=$nic mode=static nameservers=$dns search=$dnssearch domain=$dnssearch | \
 grep -v dns-nameservers | grep -v dns-search | grep -v dns-domain | \
 sed -e 's/nameservers/dns-nameservers/g' | \
 sed -e 's/search/dns-search/g' | \
 sed -e 's/domain/dns-domain/g' >> /tmp/interfaces_new

cp /etc/network/interfaces /etc/network/interfaces.bak
cp /tmp/interfaces_new /etc/network/interfaces

rm -rf /tmp/interfaces*

echo "done!"
echo "############################"
cat /etc/network/interfaces
echo ""
echo "setting hostname..."
hostnamectl set-hostname $hostname

IFS='.' read -a fqdn <<< "$hostname"
host="${fqdn[0]}"
cat /etc/hosts | grep -v 127.0.1.1 > /etc/hosts
echo "127.0.1.1         $hostname        $host" >> /etc/hosts

echo "done bootsrtaping!"
