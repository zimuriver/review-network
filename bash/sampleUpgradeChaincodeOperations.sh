# Upgrade 'review' contract
./review.sh upgradecontract -c reviewchannel -p review -o 3 -t init

# Upgrade 'letterOfCredit' contract
./review.sh upgradecontract -c reviewchannel -p letterOfCredit -o 3 -t init -a '"[\"ExportingEntityOrgMSP\",\"LumberBank\",\"700000\"]"'

# Upgrade 'exportLicense' contract
./review.sh upgradecontract -c shippingchannel -p exportLicense -o 4 -t init

# Upgrade 'shipment' contract
./review.sh upgradecontract -c shippingchannel -p shipment -t init -o 4
