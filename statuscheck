#!/bin/ash

# Default health is zero which equals healthy
HEALTH=0

# Check - Core Daemon - running is healthy
TEST="$(/usr/bin/pgrep /usr/bin/coredns)"
if [ $? -eq 1 ] ; then
 HEALTH=1
fi

TEST="$(/usr/bin/curl localhost:8080/health)"
if [ ! "OK" -eq $TEST ] ; then
 HEALTH=1
fi

TEST="$(/usr/bin/curl localhost:8181/ready)"
if [ ! "OK" -eq $TEST ] ; then
 HEALTH=1
fi

# https://www.hostinger.com/tutorials/how-to-use-the-dig-command-in-linux/#Short_Answers
# dig hostinger.com +noall +answer
#  dig drone.cicd.cluster.local +noall +answer @localhost

return $HEALTH

