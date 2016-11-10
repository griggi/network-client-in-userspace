#!/bin/bash

SUBNET="192.168.7.0/24"
GW=192.168.7.1
MAIN_IF=eth0

pids=()
trap ctrl_c INT 

function ctrl_c() {
  echo "killing all threads "
  for i in ${pids[*]};
  do
    kill -2 $i
    echo -n "."
  done
  echo "done"
}

function wait_for_threads() {
  for i in ${pids[*]}; do
    echo "waiting for $i"
    wait $i
  done
}
