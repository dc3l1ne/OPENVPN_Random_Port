#!/bin/bash
###
ip=
sshuser=root
sshport=122
serverip=192.168.2.1 #VPN服务端地址
clientip=192.168.2.2 #VPN客户端地址
keyfile=s.key
salt=x3KV8lBxynZZ5C2cUmZZpDIgjJ0x2BclvvAZkgBKHn7lB1joDGcZg8d8B1xmVySt #混淆salt
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
			scp -P $sshport server.conf $sshuser@$ip:/etc/openvpn
			ssh -p $sshport $sshuser@$ip "killall openvpn"
			ssh -p $sshport $sshuser@$ip "openvpn --cd /etc/openvpn --config server.conf >> /dev/null &"
			date=`date "+%Y-%m-%d %T"`
			echo "VPN down!Server Restarting.....  $date" >> /mnt/vpnlogs
			echo "VPN down!Server Restarting.....  $date"
}
function restart_vpn_client (){
			killall openvpn
			cp client.conf /etc/openvpn
			openvpn --cd /etc/openvpn --config client.conf >> /dev/null &
			date=`date "+%Y-%m-%d %T"`
			echo "VPN down!Client Restarting.....  $date" >> /mnt/vpnlogs
			echo "VPN down!Client Restarting.....  $date"
}
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
if [ -z "$serverip" ]
then
	echo Please identify your VPN Server address
	exit
else
	ping=`ping -c 5 $serverip |grep received |cut -b 24`
	if [ $ping -eq 0 ]
	then
		((count+=1))
		if [ $count -lt 3 ]
		then
			sleep 5
			restart_vpn_client
			ping=`ping -c 5 $serverip |grep received |cut -b 24`
		else
			random_port_generator
			restart_vpn_server
			restart_vpn_client
			sleep 5
			ping=`ping -c 5 $serverip |grep received |cut -b 24`
			if [ $ping -eq 0 ]
			then
				sleep 5
			else
				date=`date "+%Y-%m-%d %T"`
				echo "VPN Restarted! Port:$rad $date" >> /mnt/vpnlogs
				echo "VPN Restarted! Port:$rad $date"
				x=1
			fi

		ping=`ping -c 5 $serverip |grep received |cut -b 24`
		if [ $ping -eq 0 ]
		then
			sleep 5
		else
			date=`date "+%Y-%m-%d %T"`
			echo "VPN Restarted! $date" >> /mnt/vpnlogs
			echo "VPN Restarted! $date"
		fi
		fi
	else
		date=`date "+%Y-%m-%d %T"`
		echo "VPN is OK   $date" >> /mnt/vpnlogs
		echo "VPN is OK   $date"
	fi
fi
sleep 60
done
