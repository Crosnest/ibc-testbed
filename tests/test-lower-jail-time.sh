##
## Test suite
## Will make the Lum <> Osmosis IBC client expire and run a gov prop
## to revive this client
##

. ./.env

request_transfers() {
    ##
    ## Request IBC coin transfer from networks to Osmosis and from Osmosis to networks
    ##
    echo '[INFO] Transferring coins from Lum to Osmosis...'
    if rly tx transfer $LUM_CHAIN_ID $OSMOSIS_CHAIN_ID 1ulum $(osmosisd keys show $IBC_KEY -a --home $OSMOSISD_HOME --keyring-backend test) --path lum-osmosis --home $RELAYER_HOME >/dev/null 2>&1; then
        echo "[INFO] Transaction accepted"
    else
        echo "[INFO] Transaction rejected"
    fi

    echo '[INFO] Transferring coins from Ki to Osmosis...'
    if rly tx transfer $KI_CHAIN_ID $OSMOSIS_CHAIN_ID 1uxki $(osmosisd keys show $IBC_KEY -a --home $OSMOSISD_HOME --keyring-backend test) --path ki-osmosis --home $RELAYER_HOME >/dev/null 2>&1; then
        echo "[INFO] Transaction accepted"
    else
        echo "[INFO] Transaction rejected"
    fi

    echo '[INFO] Transferring coins from Cosmos to Osmosis...'
    if rly tx transfer $COSMOS_CHAIN_ID $OSMOSIS_CHAIN_ID 1uatom $(osmosisd keys show $IBC_KEY -a --home $OSMOSISD_HOME --keyring-backend test) --path cosmos-osmosis --home $RELAYER_HOME >/dev/null 2>&1; then
        echo "[INFO] Transaction accepted"
    else
        echo "[INFO] Transaction rejected"
    fi

    echo '[INFO] Transferring coins from Osmosis to Lum...'
    if rly tx transfer $OSMOSIS_CHAIN_ID $LUM_CHAIN_ID 1uosmo $(lumd keys show $IBC_KEY -a --home $LUMD_HOME --keyring-backend test) --path lum-osmosis --home $RELAYER_HOME >/dev/null 2>&1; then
        echo "[INFO] Transaction accepted"
    else
        echo "[INFO] Transaction rejected"
    fi

    echo '[INFO] Transferring coins from Osmosis to Ki...'
    if rly tx transfer $OSMOSIS_CHAIN_ID $KI_CHAIN_ID 1uosmo $(kid keys show $IBC_KEY -a --home $KID_HOME --keyring-backend test) --path ki-osmosis --home $RELAYER_HOME >/dev/null 2>&1; then
        echo "[INFO] Transaction accepted"
    else
        echo "[INFO] Transaction rejected"
    fi

    echo '[INFO] Transferring coins from Osmosis to Cosmos...'
    if rly tx transfer $OSMOSIS_CHAIN_ID $COSMOS_CHAIN_ID 1uosmo $(gaiad keys show $IBC_KEY -a --home $GAIAD_HOME --keyring-backend test) --path cosmos-osmosis --home $RELAYER_HOME >/dev/null 2>&1; then
        echo "[INFO] Transaction accepted"
    else
        echo "[INFO] Transaction rejected"
    fi
}

# Trigger all transfers txs
request_transfers

# Relay all packets from all relays (should all work)
echo '[INFO] Relay packets manually (all realyers should work)...'
if  rly tx relay-packets lum-osmosis    --home $RELAYER_HOME >/dev/null 2>&1 \
 && rly tx relay-packets ki-osmosis     --home $RELAYER_HOME >/dev/null 2>&1 \
 && rly tx relay-packets cosmos-osmosis --home $RELAYER_HOME >/dev/null 2>&1; then
    echo "[INFO] Relaying done"
else
    echo "[ERROR] Relaying failed"
    exit 1
fi

echo '[INFO] Running gov proposal on Osmosis to revive change jail parameters...'
cat << EOF > /tmp/proposal.json
{
  "title": "Lower the block window for offline detection",
  "description": "If successfull, this proposal will lower the block window from 30k blocks to 2500.\n\nThe objective is to quickly remove offline validators who have an impact on the blockrate, mainly after epoch\n2500 blocks correspond to a duration of 4h\nNote that there is no slashing due to downtime and validators can unjail after 1 minute of being jailed, so this increases chain efficiency and allows validators to get back in active set immediately when their problem is fixed.",
  "changes": [
    {
      "subspace": "slashing",
      "key": "params",
      "value": {"signed_block_window":"80"}
    }
  ],
  "deposit": "1000uosmo"
}
EOF

osmosisd tx gov submit-proposal param-change /tmp/proposal.json --from $IBC_KEY --home $OSMOSISD_HOME --keyring-backend test --broadcast-mode block --chain-id $OSMOSIS_CHAIN_ID --node $OSMOSIS_RPC --yes >/dev/null 2>&1
osmosisd tx gov vote 1 yes --from $IBC_KEY --home $OSMOSISD_HOME --keyring-backend test --broadcast-mode block --chain-id $OSMOSIS_CHAIN_ID --node $OSMOSIS_RPC --yes >/dev/null 2>&1

echo '[INFO] Waiting '$GOV_VOTE_DURATION's for the proposal to pass...'
sleep $GOV_VOTE_DURATION

# Trigger all transfers txs again
request_transfers

# Relay all packets from all relays (should all work)
echo '[INFO] Relay packets manually...'
if rly tx relay-packets lum-osmosis     --home $RELAYER_HOME >/dev/null 2>&1 \
 && rly tx relay-packets ki-osmosis     --home $RELAYER_HOME >/dev/null 2>&1 \
 && rly tx relay-packets cosmos-osmosis --home $RELAYER_HOME >/dev/null 2>&1; then
    echo "[INFO] Relaying done"
else
    echo "[ERROR] Relaying failed"
    exit 1
fi

# End test manual verification
# Each IBC transfer should have passed
# Even the ones done while Lum <> Osmosis relayer was out of service since we revived the relayer
# Depending on some unpredictable behaviour the Lum wallet might have only 2 (in case the tx was rejected which should be logged as well)
echo '[DEBUG] Dumping test wallets:\n - Osmosis wallet should have 3 ibc denom with 2 coins each\n - Each network should have an extra denom with 2 coins (uosmo IBC)'
sh scripts/dump-wallets.sh
