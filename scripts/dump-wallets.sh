##
## Debug - Dump test wallets
##

. ./.env

echo '[DEBUG] Osmosis wallet (chain): '$(kujirad keys show $IBC_KEY -a --home $OSMOSISD_HOME --keyring-backend test)
kujirad query bank balances $(kujirad keys show $IBC_KEY -a --home $OSMOSISD_HOME --keyring-backend test) --node $OSMOSIS_RPC
echo '[DEBUG] Cdo wallet (chain): '$(chain-maind keys show $IBC_KEY -a --home $CDO_HOME --keyring-backend test)
chain-maind query bank balances $(chain-maind keys show $IBC_KEY -a --home $CDO_HOME --keyring-backend test) --node $CDO_RPC
echo '[DEBUG] Ki wallet (chain): '$(kid keys show $IBC_KEY -a --home $KID_HOME --keyring-backend test)
kid query bank balances $(kid keys show $IBC_KEY -a --home $KID_HOME --keyring-backend test) --node $KI_RPC
echo '[DEBUG] Cosmos wallet (chain): '$(gaiad keys show $IBC_KEY -a --home $GAIAD_HOME --keyring-backend test)
gaiad query bank balances $(gaiad keys show $IBC_KEY -a --home $GAIAD_HOME --keyring-backend test) --node $COSMOS_RPC
