#!/bin/bash

# check all nginx instances respond with expected
# version number.

# ... find all instance ips by tag
echo "INPUT EXPECTED VERSION NUMBER: "
read version

ips=$(
    aws --region eu-west-1 ec2 describe-instances \
        --filter "Name=tag:product,Values=101ways-nginx" \
        --query "Reservations[].Instances[].PublicIpAddress" \
        --out text
)

rc=0
for ip in $ips; do
    url="http://$ip/version.txt"
    echo "Will try if $ip is serving ..." 
    while [[ $(curl -s -o /dev/null -w '%{http_code}' -I $url) -ne 200 ]]; do
        echo "trying $url again ..."
        sleep 3
    done

    echo "... checking version."
    if ! curl -sS $url | grep -Po "^$version$"
    then
        echo "... unexpected version number from $ip."
        rc=1
    fi
done

# ... fail if any errs
if [[ $rc -ne 0 ]]; then
    echo "ERROR: Not all nodes serve correct version"
else
    echo "SUCCESS. All nodes responding."
fi
exit $rc
