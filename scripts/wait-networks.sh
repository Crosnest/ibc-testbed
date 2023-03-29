##
## Wait for networks to be up and running by querying block 1
##

. ./.env

i=60
while [ $i -ge 0 ]; do
    ok=0
    if kujirad query block 1 --node $OSMOSIS_RPC >/dev/null 2>&1; then
        echo "kujira ready"
        ok=$((ok + 1))
    fi
    if chain-maind query block 1 --node $CDO_RPC >/dev/null 2>&1; then
        echo "chain-maind ready"
        ok=$((ok + 1))
    fi
    if kid query block 1 --node $KI_RPC >/dev/null 2>&1; then
        echo "kid ready"
        ok=$((ok + 1))
    fi

    if [ "$ok" = "3" ]; then
        exit 0
    fi
    echo $ok
    i=$((i - 1))
    sleep 1
done

exit 1
