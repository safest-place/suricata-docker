#!/bin/bash
ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime
/bin/suricata -D -c /etc/suricata/suricata.yaml --af-packet
