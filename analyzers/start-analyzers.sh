#!/bin/bash

cd ${HOME}/analyzers
python3 pa_analyzer.py --config-file=${ANALYZER_CONFIG_PATH}/node-config.yml --kafka-addr=172.16.16.28 --kafka-port=9093&
python3 pt_analyzer.py --color-file=${ANALYZER_CONFIG_PATH}/edges-colored-dict.yml --kafka-addr=172.16.16.28 --kafka-port=9093 &
python3 tts_analyzer.py --kafka-addr=172.16.16.28 --kafka-port=9093 &