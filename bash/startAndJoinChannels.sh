#!/bin/bash
#
# SPDX-License-Identifier: Apache-2.0
#

# Create the 3-org 'reviewchannel'
./review.sh createchannel -c reviewchannel

# Join peers of 3 orgs to 'reviewchannel'
./review.sh joinchannel -c reviewchannel -o 3

# Set anchor peer for each of the 3 orgs in 'reviewchannel'
./review.sh updateanchorpeers -c reviewchannel -o 3

# Create the 4-org 'shippingchannel'
./review.sh createchannel -c shippingchannel

# Join peers of 4 orgs to 'shippingchannel'
./review.sh joinchannel -c shippingchannel -o 4

# Set anchor peer for each of the 4 orgs in 'shippingchannel'
./review.sh updateanchorpeers -c shippingchannel -o 4
