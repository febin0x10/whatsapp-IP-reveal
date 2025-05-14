

# Get IP address from the adapter

$adapters = (Get-NetAdapter).Name
$total_adapters = $adapters.Length

echo "[+] Found $total_adapters Network Adapters.... Choose the right one"

$sno=1

Get-NetAdapter | ForEach-Object {

Write-Host -NoNewline $sno") ";
$_.Name;
$sno = $sno + 1 

} 

Write-Host -NoNewline "Enter your choice: "
$choice = Read-Host

if ([int]$choice -gt [int]$adapters.Length){

echo "[-] Invalid Choice!!"
exit

} else {

$iface = $adapters[[int]$choice - 1]
$ip =  (Get-NetIPAddress -InterfaceAlias $iface).IPAddress

echo "[+] Choosing Network Adapter [$iface] that has the IP [$ip] for Sniffing..."

$CWD=$PWD

cd 'C:\Program Files\Wireshark'


.\tshark.exe -i "$iface" -Y "stun and ip.src == $ip and frame.len == 86" -T fields -e "_ws.col.info" -e ip.dst

cd $CWD

}

