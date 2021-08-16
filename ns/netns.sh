#!/bin/bash

# setup and connect network namespacess

NS_IFNAME=ns0
NS_IFADDR_SKIP=10

netns_usage() {
    echo "Basic commands:"
    echo "  $0 create <name> <gw_addr/prelen> <ns_count>"
    echo "  $0 delete <name>"
    echo "Lower level commands:"
    echo "  $0 create_gw <gw_name> <gw_addr/prelen>"
    echo "  $0 delete_gw <gw_name>"
    echo "  $0 create_ns <ns_name> <ns_addr> <gw_name>"
    echo "  $0 delete_ns <ns_name>"
}

get_addr() {
    local name=$1
    local no_prefix=$2

    ip addr show dev $name | awk '/inet /{print $2}'
}

get_ns_links() {
    local name=$1

    ip link show type veth | sed -n -e "s/^[[:digit:]]\+:[[:space:]]*\(${name}_[[:digit:]]\+\)@.*/\1/p"
}

netns_create_gw() {
    local name=$1
    local addr=$2
    if [ -z "$name" -o -z "$addr" ]; then
	echo "missing args" >&2
	exit 1
    fi
    echo ">>> creating gw interface $name addr $addr"

    ip link add $name type dummy
    ip addr add $addr dev $name

    echo 1 > /proc/sys/net/ipv4/ip_forward
    iptables -t nat -D POSTROUTING -s $addr ! -d $addr -j MASQUERADE 2>/dev/null
    iptables -t nat -A POSTROUTING -s $addr ! -d $addr -j MASQUERADE
}

netns_delete_gw() {
    local name=$1
    if [ -z "$name" ]; then
	echo "missing args" >&2
	exit 1
    fi
    echo ">>> deleting gw interface $name"

    local addr=$(get_addr $name)
    if [ -z "$addr" ]; then
	echo "no address for gw interface $name"
	exit 2
    fi

    ip link del $name

    echo 0 > /proc/sys/net/ipv4/ip_forward
    iptables -t nat -D POSTROUTING -s $addr ! -d $addr -j MASQUERADE
}

netns_create_ns() {
    local name=$1
    local addr=$2
    local gw=$3
    if [ -z "$name" -o -z "$addr" -o -z "$gw" ]; then
	echo "missing args" >&2
	exit 1
    fi
    echo ">>> creating ns $name interface $name addr $addr gw $gw"

    ip netns add $name
    ip netns exec $name ip link set lo up

    ip link add $name type veth peer $NS_IFNAME
    ip link set $NS_IFNAME netns $name
    ip link set $name up

    ip netns exec $name ip link set $NS_IFNAME up
    ip netns exec $name ip addr add $addr/32 dev $NS_IFNAME

    ip route add $addr dev $name
    gw=$(get_addr $gw)
    gw=${gw%/*}
    ip netns exec $name ip route add $gw scope link dev $NS_IFNAME
    ip netns exec $name ip route add default via $gw
}

netns_delete_ns() {
    local name=$1
    if [ -z "$name" ]; then
	echo "missing args" >&2
	exit 1
    fi
    echo ">>> deleting ns $name"

    ip netns del $name
    ip link del $name
}

netns_create() {
    local name=$1
    local gw=$2
    local count=$3
    if [ -z "$name" -o -z "$gw" -o -z "$count" ]; then
	echo "missing args" >&2
	exit 1
    fi

    local i
    netns_create_gw $name $gw
    for i in $(seq 1 $count); do
	i=$((NS_IFADDR_SKIP+$i))
	local ns_name=${name}_$i
	local ns_addr=${gw%.*}.$i
	netns_create_ns $ns_name $ns_addr $name
    done
}

netns_delete() {
    local name=$1
    if [ -z "$name" ]; then
	echo "missing args" >&2
	exit 1
    fi

    for ns_name in $(get_ns_links $name); do
	netns_delete_ns $ns_name
    done
    netns_delete_gw $name
}

cmd=$1; shift

case $cmd in
    create)
	netns_create "$@"
	;;
    delete)
	netns_delete "$@"
	;;
    create_gw)
	netns_create_gw "$@"
	;;
    delete_gw)
	netns_delete_gw "$@"
	;;
    create_ns)
	netns_create_ns "$@"
	;;
    delete_ns)
	netns_delete_ns "$@"
	;;
    *)
	netns_usage
	;;
esac
