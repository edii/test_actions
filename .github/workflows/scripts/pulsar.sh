#!/usr/bin/env bash

set -o errexit

# install pulsar client
apt-get update
apt-get install -y git wget make gcc rpm
wget https://archive.apache.org/dist/pulsar/pulsar-2.6.1/RPMS/apache-pulsar-client-2.6.1-1.x86_64.rpm
wget https://archive.apache.org/dist/pulsar/pulsar-2.6.1/RPMS/apache-pulsar-client-devel-2.6.1-1.x86_64.rpm

rpm -qa apache-pulsar-client
if !(rpm -qa apache-pulsar-client | grep -q apache-pulsar-client-2.6.1-1.x86_64); then
    rpm -ivh apache-pulsar-client-2.6.1-1.x86_64.rpm
fi

rpm -qa apache-pulsar-client
if !(rpm -qa apache-pulsar-client-devel | grep -q apache-pulsar-client-devel-2.6.1-1.x86_64); then
    rpm -ivh apache-pulsar-client-devel-2.6.1-1.x86_64.rpm
fi

ldconfig
exit 0
