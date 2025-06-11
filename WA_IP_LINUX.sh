#!/bin/bash

check_deps(){

if ! command -v tshark >/dev/null || ! command -v jq>/dev/null
then
echo "[-] Dependency check failed: Please install tshark and jq"
exit
else
echo "[+] jq and tshark are available"
fi

}

mainProg(){

echo "[+] Network Interfaces"
echo ""
ip -4 addr

echo ""
printf "[*] Select the right interface - Enter the number: "
read sno

IP=$( ip -json addr | jq .[$((sno-1))].addr_info[0].local | tr -d '"' )
IFNAME=$( ip -json addr | jq .[$((sno-1))].ifname | tr -d '"')

#echo $IP
#echo $IFNAME

echo "[+] Sniffing on $IFNAME...."

sudo tshark -i "$IFNAME" -Y "stun and ip.src == $IP and frame.len == 86" -T fields -e "_ws.col.info" -e ip.dst

}




check_deps
mainProg
