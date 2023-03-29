##
## Init relayers wallets and paths
##

. ./.env

echo '[INFO] Sending 1Mi KUJI to relayer...'
kujirad tx bank send $(kujirad keys show $IBC_KEY -a --home $OSMOSISD_HOME --keyring-backend test) $(rly keys show $OSMOSIS_CHAIN_ID $RLY_KEY --home $RELAYER_HOME) 1000000000000ukuji --chain-id $OSMOSIS_CHAIN_ID --home $OSMOSISD_HOME --keyring-backend test --broadcast-mode block --node $OSMOSIS_RPC --yes  >/dev/null 2>&1 

echo '[INFO] Sending 1Mi CDO to relayer...'
chain-maind tx bank send $(chain-maind keys show $IBC_KEY -a --home $CDO_HOME --keyring-backend test) $(rly keys show $CDO_CHAIN_ID $RLY_KEY --home $RELAYER_HOME) 1000000000000basecro --chain-id $CDO_CHAIN_ID --home $CDO_HOME --keyring-backend test --broadcast-mode block --node $CDO_RPC --yes  >/dev/null 2>&1 

echo '[INFO] Sending 1Mi XKI to relayer...'
kid tx bank send $(kid keys show $IBC_KEY -a --home $KID_HOME --keyring-backend test) $(rly keys show $KI_CHAIN_ID $RLY_KEY --home $RELAYER_HOME) 1000000000000uxki --chain-id $KI_CHAIN_ID --home $KID_HOME --keyring-backend test --broadcast-mode block --node $KI_RPC --yes  >/dev/null 2>&1 

echo '[INFO] Initializing Ki <> KUJI relayer...'
rly paths new $KI_CHAIN_ID $OSMOSIS_CHAIN_ID ki-osmosis --home $RELAYER_HOME  >/dev/null 2>&1 
rly tx clients ki-osmosis --home $RELAYER_HOME >/dev/null 2>&1 
sleep 5
rly tx connection ki-osmosis --home $RELAYER_HOME >/dev/null 2>&1 
sleep 5
rly tx link ki-osmosis --home $RELAYER_HOME >/dev/null 2>&1 

echo '[INFO] Initializing CdO <> KUJI relayer...'
rly paths new $CDO_CHAIN_ID $OSMOSIS_CHAIN_ID cdo-osmosis --home $RELAYER_HOME >/dev/null 2>&1 
rly tx clients cdo-osmosis --home $RELAYER_HOME >/dev/null 2>&1 
sleep 5
rly tx connection cdo-osmosis --home $RELAYER_HOME >/dev/null 2>&1 
sleep 5
rly tx link cdo-osmosis --home $RELAYER_HOME >/dev/null 2>&1 
