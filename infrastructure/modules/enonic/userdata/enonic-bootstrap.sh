#!/bin/bash

DOCKER_IMG="${dockerImage}"

awsRegion="${ebsRegion}"
awsGroup="${ebsGroup}"

cwLogGroup="${logGroup}"

mountPoint="/data/nvm"
destDevice="/dev/xvdh"
destPartition="$destDevice"1

s3bucket="${s3Bucket}"
s3mountPoint="/data/s3"

xpHome="/enonic-xp/home"

ecr_login() {
    if [[ "$DOCKER_IMG" =~ dkr.ecr ]]; then
        echo "Logging into ECR"
        ecr="$${DOCKER_IMG%:*}"
        aws ecr get-login-password --region "$awsRegion" | docker login --username AWS --password-stdin "$ecr"
    else
        echo "Skipping login. ECR image not found at $DOCKER_IMG"
    fi
}

run_application() {
    ecr_login
    docker run -itd \
        -p 8080:8080 \
        -p 2609:2609 \
        --mount type=bind,source=${mountPoint}/home:${xpHome} \
        --mount type=bind,source=${s3mountPoint}/config,target=${xpHome}/config \
        --mount type=bind,source=${s3mountPoint}/deploy,target=${xpHome}/deploy \
        --mount type=bind,source=${s3mountPoint}/snapshots,target=${xpHome}/snapshots \
        -e XP_OPTS="${XP_OPTS}" \
        --restart unless-stopped \
        --log-driver=awslogs \
        --log-opt awslogs-region="$awsRegion" \
        --log-opt awslogs-group="$cwLogGroup" \
        "$DOCKER_IMG"
}

log_msg() {
    echo "[$(date "+%Y-%m-%d %H:%M:%S")] [*] [$1] $2"
}

msg_exit() {
    errcode=$1
    shift

    log_msg ERROR "$*"
    exit "$errcode"
}

check_exists() {
    checkResource="$1"
    if [ -b "$checkResource" ]; then
        log_msg INFO "Resource $checkResource found."
        return 0 # Everything ok!
    else
        if [ "x$2" != "xagain" ]; then
            log_msg WARN "Resource $checkResource not found. Waiting 10 seconds before second try."
            sleep 10 #Timeout sleep
            log_msg INFO "Checking $checkResource again..."
            check_exists "$checkResource" "again"
        fi
    fi

    return 1
}

check_ebs_exists() {
    check_exists "/dev/xvdh"
    return $?
}

check_ebs_partition_exists() {
    check_exists "/dev/xvdh1"
    return $?
}

create_partition() {
    log_msg "Creating partition"

    fdisk $destDevice <<EOF
p
o
n
p
1


p
w
EOF
    # Let it sync
    log_msg " - waiting for sync"
    sleep 2
    mkfs.ext4 $destPartition
}

prepare_partition_mount() {
    echo "# Immutable data storage (dedicated EBS)" | tee -a /etc/fstab
    echo "$destPartition $mountPoint	 ext4	defaults	0 0" | tee -a /etc/fstab
    log_msg INFO "Mounting partition $destPartition on $mountPoint"
    mkdir -p $mountPoint
    chown 1337 $mountPoint
    mount $destPartition $mountPoint || return 1
}

prepare_s3_mount() {
    echo "# S3fs app storage" | tee -a /etc/fstab
    echo "$s3bucket $s3mountPoint fuse.s3fs _netdev,allow_other,iam_role=auto 0 0" | tee -a /etc/fstab

    mkdir -p $s3mountPoint/{config,deploy,snapshots}
    chown -R 1337 $s3mountPoint
    mount $s3mountPoint || return 1
}

#Base64 encoded python script / Unfortunatelly it must be base64 encoded
AWS_BOOTSTRAP_PYSCRIPT="aW1wb3J0IGJvdG8zCmltcG9ydCByZXF1ZXN0cwppbXBvcnQgcHByaW50CmltcG9ydCBzeXMKaW1wb3J0IHRpbWUKCgppZiBsZW4oc3lzLmFyZ3YpIDwgMzoKICAgIHByaW50KCJVc2FnZTogIiArIHN5cy5hcmd2WzBdICsgIiA8UkVHSU9OPiA8R1JPVVBfTkFNRT4iKQogICAgc3lzLmV4aXQoMSkKCmN1cnJlbnRfcmVnaW9uID0gc3lzLmFyZ3ZbMV0KZ3JvdXBfbmFtZSA9IHN5cy5hcmd2WzJdCmZpbHRlcl9saXN0ID0gW3snTmFtZSc6ICd0YWc6R3JvdXAnLCAnVmFsdWVzJzogW2dyb3VwX25hbWVdfV0KCnJldHJpZXMgPSAxMAp3YWl0QmV0d2VlblJldHJpZXMgPSAzICMgc2Vjb25kcwoKZGVmIHNldF9pbnN0YW5jZV91bmhlYWx0aHkoKToKICAgICMgVE9ETyBkbyBzdHVmZgogICAgcGFzcwoKZGVmIGNoZWNrX3JlY29yZF9hel9tYXRjaChyZWNvcmQpOgogICAgaWYgaXNpbnN0YW5jZShyZWNvcmQsIGRpY3QpIGFuZCAnQXZhaWxhYmlsaXR5Wm9uZScgaW4gcmVjb3JkLmtleXMoKSBhbmQgcmVjb3JkWydBdmFpbGFiaWxpdHlab25lJ10gPT0gY3VycmVudF9hejoKICAgICAgICByZXR1cm4gVHJ1ZQogICAgZWxzZToKICAgICAgICByZXR1cm4gRmFsc2UKCmRlZiBhdmFpbGFibGVfdm9sdW1lc19jaGVjayh2b2x1bWUpOgogICAgaWYgbm90IGNoZWNrX3JlY29yZF9hel9tYXRjaCh2b2x1bWUpOgogICAgICAgIHJldHVybiBGYWxzZQoKICAgIGlmICdTdGF0ZScgaW4gdm9sdW1lLmtleXMoKSBhbmQgdm9sdW1lWydTdGF0ZSddID09ICdhdmFpbGFibGUnOgogICAgICAgIHJldHVybiBUcnVlCgogICAgcmV0dXJuIEZhbHNlCgpkZWYgYXZhaWxhYmxlX25ldHdvcmtfaW50ZXJmYWNlc19jaGVjayhuZXR3b3JrX2ludGVyZmFjZSk6CiAgICBpZiBub3QgY2hlY2tfcmVjb3JkX2F6X21hdGNoKG5ldHdvcmtfaW50ZXJmYWNlKToKICAgICAgICByZXR1cm4gRmFsc2UKCiAgICBpZiAnU3RhdHVzJyBpbiBuZXR3b3JrX2ludGVyZmFjZS5rZXlzKCkgYW5kIG5ldHdvcmtfaW50ZXJmYWNlWydTdGF0dXMnXSA9PSAnYXZhaWxhYmxlJzoKICAgICAgICByZXR1cm4gVHJ1ZQoKICAgIHJldHVybiBGYWxzZQoKZGVmIGZpbmRfbW91bnRfdm9sdW1lKCk6CiAgICB2b2x1bWVzID0gY2xpZW50LmRlc2NyaWJlX3ZvbHVtZXMoRmlsdGVycz1maWx0ZXJfbGlzdCkKCiAgICBpZiAnVm9sdW1lcycgaW4gdm9sdW1lcy5rZXlzKCk6CiAgICAgICAgdm9sdW1lcyA9IHZvbHVtZXNbJ1ZvbHVtZXMnXQogICAgZWxzZToKICAgICAgICB2b2x1bWVzID0geydWb2x1bWVzJzogW119CgogICAgYXZhaWxhYmxlX3ZvbHVtZXMgPSBsaXN0KGZpbHRlcihhdmFpbGFibGVfdm9sdW1lc19jaGVjaywgdm9sdW1lcykpCgogICAgcHByaW50LnBwcmludChhdmFpbGFibGVfdm9sdW1lcykKCiAgICBpZiBsZW4oYXZhaWxhYmxlX3ZvbHVtZXMpID4gMDoKICAgICAgICB2b2x1bWVfaWQgPSBhdmFpbGFibGVfdm9sdW1lc1swXVsnVm9sdW1lSWQnXQogICAgICAgIHByaW50KCJGb3VuZCBhdmFpbGFibGUgdm9sdW1lICVzLiBBdHRhY2hpbmcgdG8gaW5zdGFuY2UgJXMuIiAlICh2b2x1bWVfaWQsIGN1cnJlbnRfaW5zdGFuY2VfaWQpKQogICAgICAgIHZvbCA9IGVjMi5Wb2x1bWUodm9sdW1lX2lkKQogICAgICAgIHJlc3BvbnNlID0gdm9sLmF0dGFjaF90b19pbnN0YW5jZShEZXZpY2U9J3h2ZGgnLCBJbnN0YW5jZUlkPWN1cnJlbnRfaW5zdGFuY2VfaWQpCiAgICAgICAgcHByaW50LnBwcmludChyZXNwb25zZSkKCiAgICAgICAgZm9yIHggaW4gcmFuZ2UoMSxyZXRyaWVzKToKICAgICAgICAgICAgaWYgdm9sLnN0YXRlID09ICdpbi11c2UnOgogICAgICAgICAgICAgICAgcHJpbnQoIiAqIHZvbHVtZSBpcyBtb3VudGVkISIpCiAgICAgICAgICAgICAgICByZXR1cm4KICAgICAgICAgICAgcHJpbnQoIiAtIHZvbHVtZSBub3QgbW91bnRlZCB5ZXQiKQogICAgICAgICAgICB0aW1lLnNsZWVwKHdhaXRCZXR3ZWVuUmV0cmllcykKCiAgICAgICAgcHJpbnQoIkludGVyZmFjZSBub3QgbW91bnRlZCBhZnRlciAlZCByZXRyaWVzIiAlIHJldHJpZXMpCiAgICAgICAgc3lzLmV4aXQoNykKCiAgICBlbHNlOgogICAgICAgIHByaW50KCJObyB2b2x1bWVzIGF2YWlsYWJsZSEgRXhpdCIpCiAgICAgICAgIyBUT0RPOiBNYXJrIGluc3RhbmNlIGFzIHVuaGVhbHRoeQogICAgICAgIHN5cy5leGl0KDMpCgpkZWYgZmV0Y2hfbWV0YWRhdGEocmVzb3VyY2UsIGV4aXRfY29kZT0wKToKICAgIHIgPSByZXF1ZXN0cy5nZXQoJ2h0dHA6Ly8xNjkuMjU0LjE2OS4yNTQvbGF0ZXN0L21ldGEtZGF0YS8nICsgcmVzb3VyY2UpCiAgICBpZiByLnN0YXR1c19jb2RlICE9IDIwMDoKICAgICAgICBwcmludCgiTm8gcmVzcG9uc2Ugb24gIiArIGVycm9yX21zZykKICAgICAgICBwcmludChyLnRleHQpCiAgICAgICAgaWYgZXhpdF9jb2RlID4gMDoKICAgICAgICAgICAgc3lzLmV4aXQoZXhpdF9jb2RlKQogICAgcmV0dXJuIHIudGV4dAoKY3VycmVudF9pbnN0YW5jZV9pZCA9IGZldGNoX21ldGFkYXRhKCJpbnN0YW5jZS1pZCIsIDEpCmN1cnJlbnRfYXogPSBmZXRjaF9tZXRhZGF0YSgicGxhY2VtZW50L2F2YWlsYWJpbGl0eS16b25lIiwgMikKbWFjID0gZmV0Y2hfbWV0YWRhdGEoIm1hYyIsIDMpCnZwY19pZCA9IGZldGNoX21ldGFkYXRhKCJuZXR3b3JrL2ludGVyZmFjZXMvbWFjcy8iICsgbWFjICsgIi92cGMtaWQiLCA0KQoKcHJpbnQoIkluc3RhbmNlIElEOiAlcywgQVo6ICVzXG4iICUgKGN1cnJlbnRfaW5zdGFuY2VfaWQsIGN1cnJlbnRfYXopKQoKY2xpZW50ID0gYm90bzMuY2xpZW50KCdlYzInLCByZWdpb25fbmFtZT1jdXJyZW50X3JlZ2lvbikKZWMyID0gYm90bzMucmVzb3VyY2UoJ2VjMicsIHJlZ2lvbl9uYW1lPWN1cnJlbnRfcmVnaW9uKQoKdHJ5OgogICAgIyMjIFZvbHVtZXMKICAgIGZpbmRfbW91bnRfdm9sdW1lKCkKZXhjZXB0IEV4Y2VwdGlvbiBhcyBlOgogICAgIyBNYXJrIGluc3RhbmNlIHVuaGVhbHRoeQogICAgcmFpc2UgZQoK"

## RUNTIME / MAIN

log_msg INFO "Executing aws bootstrap script"

pip3.8 install boto3 requests
echo $AWS_BOOTSTRAP_PYSCRIPT | base64 -d | python3.8 - "$awsRegion" "$awsGroup"

awsBootstrap=$?

log_msg INFO "Executed aws bootstrap: $awsBootstrap"

# If executed properly. Check for mounted resources
if [ $awsBootstrap -eq 0 ]; then
    log_msg INFO "Bootstrap completed"
    log_msg INFO "Waiting for changes to apply ~approx 20 seconds"

    sleep 20
    check_ebs_exists || msg_exit 1 "EBS not found in the system"
    check_ebs_partition_exists || create_partition

    sleep 2
    prepare_partition_mount || msg_exit 3 "Partition not mounted properly"
    prepare_s3_mount || msg_exit 4 "Couldn't mount S3fs bucket"

    sleep 10
    log_msg INFO "Running application"
    run_application
else
    msg_exit 255 "AWS bootstrap has failed. We should rather kill this instance..."
fi
