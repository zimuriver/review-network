#!/bin/bash
#
# SPDX-License-Identifier: Apache-2.0
#

# Keeps pushd silent
pushd () {
    command pushd "$@" > /dev/null
}

# Keeps popd silent
popd () {
    command popd "$@" > /dev/null
}
DIR='./crypto-config'
if [ ! "$(ls -A $DIR)" ]; then
    ./review.sh generate -c reviewchannel -o 3
    ./review.sh generate -c shippingchannel -o 4
fi
./review.sh up
./startAndJoinChannels.sh
pushd utils
./generateAllProfiles.sh
popd
./sampleChaincodeOperations.sh
./review.sh startrest
