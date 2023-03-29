##
## Test suite
## Will make the CDO <> Osmosis IBC client expire and run a gov prop
## to revive this client
##

. ./.env

request_transfers() {
    ##
    ## Request IBC coin transfer from networks to Osmosis and from Osmosis to networks
    ##
    echo '[INFO] Transferring coins from CryptoOrg to Kujira...'
    if rly tx transfer $CDO_CHAIN_ID $OSMOSIS_CHAIN_ID 1ulum $(kujirad keys show $IBC_KEY -a --home $OSMOSISD_HOME --keyring-backend test)  channel-1 --path cdo-osmosis --home $RELAYER_HOME >/dev/null 2>&1; then
        echo "[INFO] Transaction accepted"
    else
        echo "[INFO] Transaction rejected"
    fi

    echo '[INFO] Transferring coins from Ki to Kujira...'
    if rly tx transfer $KI_CHAIN_ID $OSMOSIS_CHAIN_ID 1uxki $(kujirad keys show $IBC_KEY -a --home $OSMOSISD_HOME --keyring-backend test) channel-0 --path ki-osmosis --home $RELAYER_HOME >/dev/null  2>&1; then
        echo "[INFO] Transaction accepted"
    else
        echo "[INFO] Transaction rejected"
    fi

    echo '[INFO] Transferring coins from Kujira to CryptoOrg...'
    if rly tx transfer $OSMOSIS_CHAIN_ID $CDO_CHAIN_ID 1ukuji $(chain-maind keys show $IBC_KEY -a --home $CDO_HOME --keyring-backend test)  channel-1 --path cdo-osmosis --home $RELAYER_HOME >/dev/null 2>&1; then
        echo "[INFO] Transaction accepted"
    else
        echo "[INFO] Transaction rejected"
    fi

    echo '[INFO] Transferring coins from Kujira to Ki...'
    if rly tx transfer $OSMOSIS_CHAIN_ID $KI_CHAIN_ID 1ukuji $(kid keys show $IBC_KEY -a --home $KID_HOME --keyring-backend test)  channel-0 --path ki-osmosis --home $RELAYER_HOME >/dev/null 2>&1; then
        echo "[INFO] Transaction accepted"
    else
        echo "[INFO] Transaction rejected"
    fi
}

# Trigger all transfers txs
request_transfers

# Relay all packets from all relays (should all work)
echo '[INFO] Relay packets manually (all realyers should work)...'
if rly tx flush cdo-osmosis --home $RELAYER_HOME >/dev/null 2>&1 && rly tx flush ki-osmosis --home $RELAYER_HOME >/dev/null 2>&1; then
    echo "[INFO] Relaying done"
else
    echo "[ERROR] Relaying failed"
    exit 1
fi

# Relayer expiration must be high enough for the test to pass so we must wait
echo '[INFO] Waiting 5min for the CDO <> Kujira client to expire...'
sleep 120

# Trigger all transfers txs again
request_transfers

# CDO <> Osmosis relayer should not be working anymore
echo '[INFO] Relay packets between CDO <> Kujira (should not work)...'
if rly tx update-clients cdo-osmosis --home $RELAYER_HOME; then
    echo "[ERROR] Relaying is supposedly working but should not be"
    exit 1
else
    echo "[INFO] Relaying not working as expected"
fi

# Other relayers should work just fine and not be affected by the CDO <> Osmosis relayer issue
echo '[INFO] Relay packets between other networks (should work)...'
if rly tx flush ki-osmosis --home $RELAYER_HOME; then
    echo "[INFO] Relaying done"
else
    echo "[ERROR] Relaying failed"
    exit 1
fi

# Launching IBC fix for CDO <> Osmosis relayer
echo '[INFO] Creating and updating new substitute client to replace the expired one...'
rly tx raw client $OSMOSIS_CHAIN_ID $CDO_CHAIN_ID 07-tendermint-3 --home $RELAYER_HOME
sleep 5
rly tx raw update-client $OSMOSIS_CHAIN_ID $CDO_CHAIN_ID 07-tendermint-3 --home $RELAYER_HOME

echo '[INFO] Running gov proposal on Osmosis to revive CDO <> Osmosis relayer...'
kujirad tx gov submit-proposal update-client 07-tendermint-2 07-tendermint-3 --deposit 1000ukuji --title "update" --description "upt clt" --from $IBC_KEY --home $OSMOSISD_HOME --keyring-backend test --broadcast-mode block --chain-id $OSMOSIS_CHAIN_ID --node $OSMOSIS_RPC --yes
kujirad tx gov vote 1 yes --from $IBC_KEY --home $OSMOSISD_HOME --keyring-backend test --broadcast-mode block --chain-id $OSMOSIS_CHAIN_ID --node $OSMOSIS_RPC --yes

echo '[INFO] Waiting '$GOV_VOTE_DURATION's for the proposal to pass...'
sleep $GOV_VOTE_DURATION

echo '[INFO] Updating substitute client...'
rly tx raw update-client $OSMOSIS_CHAIN_ID $CDO_CHAIN_ID 07-tendermint-3 --home $RELAYER_HOME

# Trigger all transfers txs again
request_transfers

# Relay all packets from all relays (should all work)
echo '[INFO] Relay packets manually...'
if rly tx flush cdo-osmosis --home $RELAYER_HOME && rly tx flush ki-osmosis --home $RELAYER_HOME; then
    echo "[INFO] Relaying done"
else
    echo "[ERROR] Relaying failed"
    exit 1
fi

# End test manual verification
# Each IBC transfer should have passed
# Even the ones done while CDO <> Osmosis relayer was out of service since we revived the relayer
# Depending on some unpredictable behaviour the Lum wallet might have only 2 (in case the tx was rejected which should be logged as well)
echo '[DEBUG] Dumping test wallets:\n - Osmosis wallet should have 3 ibc denom with 3 coins each\n - Each network should have an extra denom with 3 coins (ukuji IBC)'
sh scripts/dump-wallets.sh
