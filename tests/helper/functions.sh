#!/bin/bash

#source $(dirname $0)/config.sh
#TODO: above include kept giving file doesnt exist error. fix it later.
source ~/network-client-in-userspace/config.sh

pids=()
interfaces=()

trap ctrl_c INT 

function ctrl_c() {
  kill_threads
  del_interfaces
}

function del_interfaces() {
  for i in ${interfaces[*]}; do
    delete_interface $i
  done
}

function kill_threads() {
  for i in ${pids[*]};
  do
    echo "killing $i "
    kill -9 $i
  done
  echo "done"
}



function wait_for_threads() {
  for i in ${pids[*]}; do
    echo "waiting for $i"
    wait $i
  done
}

function run_in_background() {
  $1 &
  pids+=$!
}

function get_interface_ip() {
 /sbin/ifconfig $1 | grep 'inet addr:' | cut -d: -f2 | awk '{ print $1}'
}

function create_interface() {
  NEW_IF=$1
  count=$2
  if [ -z $NEW_IF ] || [ -z $count ]
    then
    echo "Usage: $0 <interface eg eth0> <unique count for interface eg 10>"
    return
  fi
#echo $1

  ifconfig $NEW_IF > /dev/null

  if [ $? != 0 ] 
    then
    ip link add link $MAIN_IF $NEW_IF type macvlan mode bridge
    ifconfig $NEW_IF up
    #ifconfig $NEW_IF
    interfaces+=$NEW_IF
    echo "...created $NEW_IF"
  fi


#create rules & routes for eth0 if not present
  cat /etc/iproute2/rt_tables | grep $NEW_IF > /dev/null
  if [ $? != 0 ]
    then
    echo "$count $NEW_IF" >> /etc/iproute2/rt_tables
    echo "..added $count $NEW_IF in /etc/iproute2/rt_tables"
  fi 

  IP=`get_interface_ip $NEW_IF`

  if [ -z $IP ]
  then
      dhclient $NEW_IF
      IP=`get_interface_ip $NEW_IF`
      echo "...assigned $IP to $NEW_IF"
  fi

  route_count=`ip route show table $NEW_IF | wc -l`
  if [ $route_count -lt 2 ]
    then
    TABLE=$NEW_IF
    ip route add $SUBNET dev $NEW_IF src $IP table $TABLE
    ip route add default via $GW dev $NEW_IF table $TABLE
    ip route flush cache
    #ip route show table $NEW_IF
    echo "...added routes to table $NEW_IF"
  fi

  ip rule show | grep $IP > /dev/null

  if [ $? != 0 ]
    then
    ip rule add from $IP table $NEW_IF
    #ip rule show
    echo "...added rule"
  fi

  #do ping test to ensure the interface is up
  echo "testing ping ..."
  ping -c 3 -W 3 -I $NEW_IF $GW
  
  if [ $? == 0 ] 
  then
    echo "ping test successful"
  else
    echo "ping test failed"
  fi

}

function delete_interface() {
  NEW_IF=$1
  
  if [ -z $NEW_IF ]
    then
    echo "Usage: $0 <interface eg eth0>"
    return
  fi
#echo $1

  ifconfig $NEW_IF > /dev/null

  if [ $? != 0 ] 
    then
    ifconfig $NEW_IF down
    ip link delete $NEW_IF type macvlan
    #do dhcp for the interface
    #ifconfig $NEW_IF
    echo "...deleted $NEW_IF interface"
  fi

#delete table from rt_tables .. not doing for now
#  cat /etc/iproute2/rt_tables | grep $NEW_IF > /dev/null
#  if [ $? != 0 ]
#    then
#    echo "$count $NEW_IF" >> /etc/iproute2/rt_tables
#    echo "..added $count $NEW_IF in /etc/iproute2/rt_tables"
#  fi 


  ip rule show | grep $IP > /dev/null

  if [ $? != 0 ]
    then
    ip rule del from $IP table $NEW_IF
    #ip rule show
    echo "...deleted rule"
  fi
  
  ip route flush table $NEW_IF
}

function execute_cmd() {
  if [ $DEBUG == 0 ]
  then
    $1 > /dev/null
  else
    $1
  fi
}

function lock {
    if [ "$#" -ne 1 ]; then
        echo 'usage: lock [LOCKFILENAME]' 1>&2
        return 1
    fi

    LOCKFILE="$1"

    # make a file with our PID
    # easy way to show who's waiting for a lock
    if ! touch "$LOCKFILE.$$" ; then
        echo "failed to create PID lockfile: $1" 1>&2
        return 1
    fi

    # try to symlink it
    while ! ln "$LOCKFILE.$$" "$LOCKFILE" 2>/dev/null
    do
        echo "failed to symlink"
        # if the symlink failed, wait for the current lock holder to exit
        sleep 1
    done

    # symlink was created successfully, lock acquired

    # if the locking process exits with unlocking, delete our lock
    trap 'rm -f "$LOCKFILE" "$LOCKFILE.$$"' EXIT

    return 0
}

function unlock {
    if [ "$#" -ne 1 ]; then
        echo 'usage: unlock [LOCKFILENAME]' 1>&2
        return 2
    fi

    rm -f "$LOCKFILE" # the symlink that locks are competing for
    rm -f "$LOCKFILE.$$" 

    return 0
}
