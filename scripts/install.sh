##
## Install base tools
##

echo '[INFO] Initializing environment...'
. ./.env

echo '[INFO] Installing build essentials...'
sudo apt-get install build-essential --yes

#echo '[INFO] Installing go v1.19.5...'
#wget -q -O - https://git.io/vQhTU | bash -s -- --version 1.19.5

##
## Preparing tmp directory
##
mkdir ./tmp
cd ./tmp

##
## Install IBC enabled binaries
##

echo '[INFO] Installing Kujira binary...'
git clone https://github.com/Team-Kujira/core
cd osmosis
git checkout v0.8.4-mainnet
make install
cd ..

echo '[INFO] Installing chain-main Network binary...'
git clone https://github.com/crypto-org-chain/chain-main chain-main
cd chain-main
git checkout v4.2.2
go mod tidy
make install
cd ..

echo '[INFO] Installing Ki binary...'
git clone https://github.com/KiFoundation/ki-tools.git
cd ki-tools
git checkout -b v2.0.1 tags/2.0.1
make install
cd ..

echo '[INFO] Installing Gaiad binary...'
git clone https://github.com/cosmos/gaia
cd gaia
git checkout v9.0.1
make install
cd ..

##
## Install go relayer
##

echo '[INFO] Installing Go Relayer...'
git clone https://github.com/cosmos/relayer
cd relayer
git checkout main
make install
cd ..

##
## Leaving tmp directory
##
cd ..

##
## Installing chain daemons
##

echo '[INFO] Installing networks daemons...'
sudo cp ./daemons/* /etc/systemd/system/.
sudo systemctl daemon-reload
sudo systemctl enable osmosisd
sudo systemctl enable chain-maind
sudo systemctl enable kid
sudo systemctl enable gaiad
