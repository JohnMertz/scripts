#!/bin/bash

SERVER_KEY='abcdefghijklmnopqrstuvwxyz0123456789abcdefg=';
SERVER_IP='1.1.1.1';
WG_BLOCK='10.10.0';

if [[ $1 == '' ]]; then
    echo "Need last octet as argument"
    exit
elif grep -Pq '^[0-9]*$' <<< $(echo $1); then
    echo "Good"
else
    echo "Argument must be a number representing the last octet"
    exit
fi

sudo apt update

if grep -Pq '^arm' <<< $(uname -m); then
    sudo apt install -y wireguard wireguard-dkms wireguard-tools raspberrypi-kernel raspberrypi-kernel-headers resolvconf
elif [ -f "/run/.containerenv" ]; then
    sudo apt install -y wireguard wireguard-tools resolvconf
else
    sudo apt install -y wireguard wireguard-tools linux-headers-$(uname -r) resolvconf
fi

if [[ "`which wg 2> /dev/null`" == '' ]]; then
    echo "Failed to install wireguard"
    exit
fi

wg genkey | sudo tee /etc/wireguard/client_private.key | wg pubkey | sudo tee /etc/wireguard/client_public.key

if [[ "`sudo cat /etc/wireguard/client_public.key 2> /dev/null`" == '' ]]; then
    echo "Failed to create keys"
    exit
fi

echo "[Interface]
Address = 10.10.0.${1}/24
DNS = 10.10.0.1
PrivateKey = $(sudo cat /etc/wireguard/client_private.key)

[Peer]
PublicKey = $SERVER_KEY
AllowedIPs = 0.0.0.0/0
Endpoint = $SERVER_IP:51820
PersistentKeepalive = 25" > wg0.conf

sudo mv wg0.conf /etc/wireguard/
sudo chown root:root /etc/wireguard/wg0.conf
sudo chmod 600 /etc/wireguard/wg0.conf

sudo systemctl enable wg-quick@wg0

echo "On server run:

sudo systemctl stop wg-quick@wg0

Then append the following to /etc/wireguard/wg0.conf:

[Peer]
PublicKey = $(sudo cat /etc/wireguard/client_public.key)
AllowedIPs = $WG_BLOCK.${1}/32

Then start it again with

sudo systemctl start wg-quick@wg0

Then on this client, enable and start wireguard:

sudo systemctl enable wg-quick@wg0
sudo systemctl start wg-quick@wg0
"
