#!/bin/bash
###
ip=133.130.103.118
sshuser=root
sshport=122
serverip=192.168.2.1
clientip=192.168.2.2
keyfile=s.key
salt=x3KV8lBxynZZ5C2cU
###
function random_port_generator (){
while true
do
rad=$RANDOM
if [ $rad -lt 65535 ]
then
cat>client.conf<<EOF
remote $ip $rad
dev tun
;proto tcp-client
ifconfig $clientip $serverip
secret $keyfile
comp-lzo
verb 3
redirect-gateway def1
tun-mtu 7500
obfs-salt $salt
EOF
cat>server.conf<<EOF
dev tun
port $rad
;proto tcp-server
ifconfig $serverip $clientip
secret $keyfile
;keepalive 10 120
comp-lzo
persist-key
persist-tun
status openvpn-status.log
verb 3
push "redirect-gateway def1"
push "dhcp-option DNS 8.8.8.8"
obfs-salt $salt
tun-mtu 7500
EOF
fi
break
done
echo "Port change to:$rad"
echo "Port change to:$rad" >> /mnt/vpnlogs
}
function restart_vpn_server (){
			echo Uploading file....
			scp -P $sshport server.conf $sshuser@$ip:/etc/openvpn
			ssh -p $sshport $sshuser@$ip "killall openvpn"
			ssh -p $sshport $sshuser@$ip "openvpn --cd /etc/openvpn --config server.conf >> /dev/null &"
			date=`date "+%Y-%m-%d %T"`
			echo "Server Restarting.....  $date" >> /mnt/vpnlogs
			echo "Server Restarting.....  $date"
}
function restart_vpn_client (){
			killall openvpn
			cp client.conf /etc/openvpn
			openvpn --cd /etc/openvpn --config client.conf >> /dev/null &
			date=`date "+%Y-%m-%d %T"`
			echo "Client Restarting.....  $date" >> /mnt/vpnlogs
			echo "Client Restarting.....  $date"
}
if [ $# = 1 ]
then
	if [ $1 = 999 ]
		then
			echo Generating new port...
			random_port_generator
			restart_vpn_server
			sleep 1
			restart_vpn_client
	fi
fi
vpn_status=`ifconfig |grep $clientip`
if [ -z "$vpn_status" ]
then
	echo NO VPN Running,Starting VPN....
	openvpn --cd /etc/openvpn --config client.conf >> /dev/null &
	sleep 1
	echo VPN is running
fi
while true
do
	ping=`ping -c 5 $serverip |grep received |cut -b 24`
	if [ $ping -eq 0 ]
	then
		((count+=1))
		if [ $count -lt 3 ]
		then
			restart_vpn_client
			sleep 5
			ping=`ping -c 5 $serverip |grep received |cut -b 24`
		else
			while true
			do
			random_port_generator
			restart_vpn_server
			sleep 5
			restart_vpn_client
			sleep 5
			ping=`ping -c 5 $serverip |grep received |cut -b 24`
			echo $ping
			if [ $ping -eq 0 ]
			then
				sleep 5
			else
				date=`date "+%Y-%m-%d %T"`
				echo "VPN Restarted! Port:$rad $date" >> /mnt/vpnlogs
				echo "VPN Restarted! Port:$rad $date"
				x=1
				break
			fi
			done
		fi
		if [ $ping -eq 0 ]
		then
			sleep 5
		else
			date=`date "+%Y-%m-%d %T"`
			echo "VPN Restarted! $date" >> /mnt/vpnlogs
			echo "VPN Restarted! $date"
		fi
	else
		date=`date "+%Y-%m-%d %T"`
		echo "VPN is OK   $date" >> /mnt/vpnlogs
		echo "VPN is OK   $date"
	fi
sleep 3
done
