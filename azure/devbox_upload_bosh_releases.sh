#!/bin/bash
set -x

bosh target 10.0.0.4
bosh login admin PASSWORDHERE

bosh upload release https://bosh.io/d/github.com/cloudfoundry/cf-mysql-release?v=24 --skip-if-exists
bosh upload release https://bosh.io/d/github.com/cloudfoundry/cf-release?v=225 --skip-if-exists
bosh upload release https://bosh.io/d/github.com/cloudfoundry-incubator/garden-linux-release?v=0.338.0 --skip-if-exists
bosh upload release https://bosh.io/d/github.com/cloudfoundry-incubator/etcd-release?v=18 --skip-if-exists
bosh upload release https://bosh.io/d/github.com/cloudfoundry-incubator/diego-release?v=0.1446.0 --skip-if-exists
bosh upload stemcell https://bosh.io/d/stemcells/bosh-azure-hyperv-ubuntu-trusty-go_agent?v=3232.11 --skip-if-exists
