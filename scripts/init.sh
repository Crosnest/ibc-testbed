##
## Initialize all networks
##

. ./.env

set -x

echo '[INFO] Testbed directory is '$IBC_TESDBED_HOME

sh scripts/stop-daemons.sh

echo '[INFO] Cleaning up testbed directories...'
rm -rf $CDO_HOME
rm -rf $OSMOSISD_HOME
rm -rf $KID_HOME
#rm -rf $GAIAD_HOME
rm -rf $RELAYER_HOME

echo '[INFO] Initializing networks keyring...'
kujirad keys add $IBC_KEY --home $OSMOSISD_HOME --keyring-backend test
chain-maind keys add $IBC_KEY --home $CDO_HOME --keyring-backend test
kid keys add $IBC_KEY --home $KID_HOME --keyring-backend test
#gaiad keys add $IBC_KEY --home $GAIAD_HOME --keyring-backend test

echo '[INFO] Initializing Osmosis Network...'
cp ./genesis_config/kujirad.json $OSMOSISD_HOME/config/genesis.json
kujirad add-genesis-account $(kujirad keys show $IBC_KEY -a --home $OSMOSISD_HOME --keyring-backend test) 1000000000000000ukuji --home $OSMOSISD_HOME
kujirad gentx $IBC_KEY 1000000000000ukuji --chain-id=$OSMOSIS_CHAIN_ID --home $OSMOSISD_HOME --keyring-backend test --commission-max-change-rate 0.02 --commission-rate 0.05 --commission-max-rate 0.2
kujirad collect-gentxs --home $OSMOSISD_HOME

echo '[INFO] Initializing Lum Network...'
cp ./genesis_config/chain-maind.json $CDO_HOME/config/genesis.json
chain-maind add-genesis-account $(chain-maind keys show $IBC_KEY -a --home $CDO_HOME --keyring-backend test) 1000000000000000basecro --home $CDO_HOME
chain-maind gentx $IBC_KEY 1000000000000basecro --chain-id=$CDO_CHAIN_ID --home $CDO_HOME  --keyring-backend test
chain-maind collect-gentxs --home $CDO_HOME

echo '[INFO] Initializing Ki Network...'
cp ./genesis_config/kid.json $KID_HOME/config/genesis.json
kid add-genesis-account $(kid keys show $IBC_KEY -a --home $KID_HOME --keyring-backend test) 1000000000000000uxki --home $KID_HOME
kid gentx $IBC_KEY 1000000000000uxki --chain-id=$KI_CHAIN_ID --home $KID_HOME --keyring-backend test
kid collect-gentxs --home $KID_HOME

#echo '[INFO] Initializing Cosmos Network...'
#cp ./genesis_config/gaiad.json $GAIAD_HOME/config/genesis.json
#gaiad add-genesis-account $(gaiad keys show $IBC_KEY -a --home $GAIAD_HOME --keyring-backend test) 1000000000000000uatom --home $GAIAD_HOME
#gaiad gentx $IBC_KEY 1000000000000uatom --chain-id=$COSMOS_CHAIN_ID --home $GAIAD_HOME --keyring-backend test
#gaiad collect-gentxs --home $GAIAD_HOME

echo '[INFO] Initializing relayer confg and wallets...'
rly config init --home $RELAYER_HOME
cp ./relayer/$RELAYER_CONFIG_NAME $RELAYER_HOME/config/config.yaml
rly keys add $OSMOSIS_CHAIN_ID $RLY_KEY --home $RELAYER_HOME
rly keys add $CDO_CHAIN_ID $RLY_KEY --home $RELAYER_HOME
rly keys add $KI_CHAIN_ID $RLY_KEY --home $RELAYER_HOME
#rly keys add $COSMOS_CHAIN_ID $RLY_KEY --home $RELAYER_HOME
