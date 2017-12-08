#!/bin/bash

if [ $HOSTNAME = $1\1 ] ; then
echo "Initializing Docker Swarm for $HOSTNAME on $2"

docker swarm init --advertise-addr $2

docker swarm join-token manager | grep "docker swarm join" > /tmp/token_swarm_manager
docker swarm join-token worker | grep "docker swarm join" > /tmp/token_swarm_worker

ftp -inv 10.237.33.251 << EOF
user anonymous password
cd pub
delete token_swarm_manager
delete token_swarm_worker
put /tmp/token_swarm_manager token_swarm_manager
put /tmp/token_swarm_worker token_swarm_worker
bye
EOF
else
ftp -inv 10.237.33.251 << EOF
user anonymous password
get /pub/token_swarm_manager /tmp/token_swarm_manager
bye
EOF

chmod +x /tmp/token_swarm_manager
/tmp/token_swarm_manager
fi
