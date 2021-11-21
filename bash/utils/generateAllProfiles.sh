#!/bin/bash
#
# SPDX-License-Identifier: Apache-2.0
#
mkdir -p ../../gateways
node manage-connection-profile.js --generate neuorg NeuOrgMSP 7051 7054
node manage-connection-profile.js --generate thuorg ThuOrgMSP 8051 8054
node manage-connection-profile.js --generate pkuorg PkuOrgMSP 9051 9054
node manage-connection-profile.js --generate conferenceorg ConferenceOrgMSP 10051 10054
