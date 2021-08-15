#!/bin/bash

# setup and connect network namespacess

usage() {
    echo "Usage:"
    echo "  $0 init <gw_name> <gw_addr>"
    echo "  $0 clean <gw_name>"
    echo "  $0 add <ns_name> <ns_addr> <gw_name>"
    echo "  $0 del <ns_name>"
}

get_addr() {
    name=$1
    no_prefix=$2

    ip addr show dev $name | awk '/inet /{print $2}'
}

netns_init() {
    name=$1
    if [ -z "$name" ]; then
	echo "missing args" >&2
	exit 1
    fi
    addr=$2

    ip link add $name type dummy
    ip addr add $addr dev $name

    echo 1 > /proc/sys/net/ipv4/ip_forward
    iptables -t nat -D POSTROUTING -s $addr ! -d $addr -j MASQUERADE 2>/dev/null
    iptables -t nat -A POSTROUTING -s $addr ! -d $addr -j MASQUERADE
}

netns_clean() {
    name=$1
    addr=$(get_addr $name)
    if [ -z "$name" -o -z "$addr" ]; then
	echo "missing args" >&2
	exit 1
    fi

    ip link del $name

    echo 0 > /proc/sys/net/ipv4/ip_forward
    iptables -t nat -D POSTROUTING -s $addr ! -d $addr -j MASQUERADE
}

netns_add() {
    name=$1
    addr=$2
    gw=$3
    if [ -z "$name" -o -z "$addr" -o -z "$gw" ]; then
	echo "missing args" >&2
	exit 1
    fi

    ip netns add $name
    ip netns exec $name ip link set lo up

    ip link add ${name}0 type veth peer ${name}1
    ip link set ${name}1 netns $name
    ip link set ${name}0 up

    ip netns exec $name ip link set ${name}1 up
    ip netns exec $name ip addr add $addr dev ${name}1

    addr=${addr%/*}
    ip route add $addr dev ${name}0
    gw=$(get_addr $gw)
    gw=${gw%/*}
    ip netns exec $name ip route add default via $gw
}

netns_del() {
    name=$1
    if [ -z "$name" ]; then
	echo "missing args" >&2
	exit 1
    fi

    ip netns del $name
    ip link del ${name}0
}

cmd=$1; shift

case $cmd in
    init)
	netns_init "$@"
	;;
    clean)
	netns_clean "$@"
	;;
    add)
	netns_add "$@"
	;;
    del)
	netns_del "$@"
	;;
    *)
	usage
	;;
esac
