#!/bin/bash
#
# SPDX-License-Identifier: Apache-2.0
#

# Install 'review' contract
./review.sh installcontract -c reviewchannel -p review -o 3
./review.sh initcontract -c reviewchannel -p review -t init

# Install 'letterOfCredit' contract
./review.sh installcontract -c reviewchannel -p letterOfCredit -o 3
./review.sh initcontract -c reviewchannel -p letterOfCredit -t init -a '"review","shippingchannel","shipment","NeuOrgMSP","LumberBank","100000","ThuOrgMSP","ToyBank","200000"'

# Install 'exportLicense' contract
./review.sh installcontract -c shippingchannel -p exportLicense -o 4
./review.sh initcontract -c shippingchannel -p exportLicense -t init -a '"reviewchannel","review","PkuOrgMSP","ConferenceOrgMSP"'

# Install 'shipment' contract
./review.sh installcontract -c shippingchannel -p shipment -o 4
./review.sh initcontract -c shippingchannel -p shipment -t init


# Invoke 'review' contract (this requires user certificates with the right attributes, and won't work with cryptogen-generated certificates)
#./review.sh invokecontract -c reviewchannel -p review -t requestreview -a '"review-78", "NeuOrgMSP", "Teak for Furniture", "650000"' -g thuorg

# Query 'review' contract (this requires user certificates with the right attributes, and won't work with cryptogen-generated certificates)
#./review.sh querycontract -c reviewchannel -p review -t getreviewStatus -a '"review-78"' -g thuorg
