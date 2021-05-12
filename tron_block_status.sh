#!/bin/bash
#monitoring of the blok number and time status
#nksupport.com
wget -O- -q  http://172.16.130.2:8091/walletsolidity/getnowblock|jq '.block_header.raw_data.number,.block_header.raw_data.timestamp' > /tmp/numbers
blocknumb=$(sed -n '1p'  /tmp/numbers)
epochtime13=$(sed -n '2p'  /tmp/numbers)
block_timestamp_epoch=$(expr $epochtime13 / 1000)
block_timestamp=$(date -d @$block_timestamp_epoch)
current_date=$(date '+%s')
time_latency=$(expr $current_date - $block_timestamp_epoch)
#allowed_latency=$(l:OPTARG)
allowed_latency=5

if 
        [ "$time_latency" -lt "$allowed_latency" ]
then
    echo "the block number is $blocknumb time is $block_timestamp"
    exit 0
elif
        [ "$time_latency" -gt "$allowed_latency" ]
then
    echo "the block time is CRITICAL!"
    exit 1
fi
