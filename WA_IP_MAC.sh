#!/bin/bash

check_deps(){
  if ! command -v tshark >/dev/null || ! command -v jq >/dev/null; then
    echo "[-] Dependency check failed: Please install tshark and jq"
    exit 1
  else
    echo "[+] jq and tshark are available"
  fi
}

mainProg(){
  echo "[+] Network Interfaces"
  echo

  # Build an array of non-loopback IPv4 interfaces (without the trailing colon)
  IFACES=()
  while IFS= read -r iface; do
    IFACES+=("$iface")
  done < <(
    ifconfig | awk '
      /^[a-z]/ {
        name = $1
        sub(/:$/, "", name)    # strip trailing colon
        iface = name
      }
      /inet / && $2 != "127.0.0.1" {
        print iface
      }
    ' | uniq
  )

  if [ ${#IFACES[@]} -eq 0 ]; then
    echo "[-] No IPv4 interfaces found."
    exit 1
  fi

  # Print numbered list with their IPv4
  for i in "${!IFACES[@]}"; do
    idx=$((i+1))
    iface=${IFACES[$i]}
    ip=$(ifconfig "$iface" | awk '/inet / && $2 != "127.0.0.1" { print $2; exit }')
    printf "%2d) %s — %s\n" "$idx" "$iface" "${ip:-<no IPv4>}"
  done

  echo
  read -p "[*] Select the right interface — enter the number: " sno

  # validate input
  if ! [[ $sno =~ ^[0-9]+$ ]] || [ "$sno" -lt 1 ] || [ "$sno" -gt "${#IFACES[@]}" ]; then
    echo "[-] Invalid selection."
    exit 1
  fi

  IFNAME=${IFACES[$((sno-1))]}
  IP=$(ifconfig "$IFNAME" | awk '/inet / && $2 != "127.0.0.1" { print $2; exit }')

  if [ -z "$IP" ]; then
    echo "[-] Could not determine an IPv4 address for $IFNAME."
    exit 1
  fi

  echo "[+] Sniffing on $IFNAME (IP $IP)…"
  sudo tshark -i "$IFNAME" \
    -Y "stun and ip.src == $IP and frame.len == 86" \
    -T fields -e "_ws.col.info" -e ip.dst
}

check_deps
mainProg

