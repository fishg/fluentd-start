#!/bin/bash --login
/etc/init.d/iptables stop
ps -ef | grep fluentd | grep -v grep | awk '{print $2}'|xargs kill
sleep 2
rvm use 1.9.3
fluentd --daemon /data/fluentd/fluentd25224.pid --config /data/fluentd/fluent.server.conf --log /data/fluentd/fluent/fluent25224.log
fluentd --daemon /data/fluentd/fluentd26224.pid --config /data/fluentd/fluent.server.second.conf --log /data/fluentd/fluent/fluent26224.log
service fluentd start
