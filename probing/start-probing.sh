#!/bin/bash

###############################################
# Start probgenerator instances
###############################################
sudo ${PT_PROBEGEN_PATH} --ptprobegen-port=linux1 --api-endpoint=0.0.0.0:50001 &

sleep 5

###############################################
# Start probegenerator-client instances
###############################################
sudo ${PT_PROBEGEN_CLIENT_PATH} \
    --fls=1 \
    --fle=60 \
    --ppf=100 \
    --pps=5 \
    --tc=1 \
    --src-addr=fcbb:bb00:1::1 \
    --tef-sid=fcbb:bb00:7:f0ef:: \
    --segment-list=fcbb:bb00:7:f0ef:: \
    --ptprobegen=127.0.0.1:50001 &