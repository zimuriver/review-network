# Submit channel configuration update to add 'exportingentityorg' to 'reviewchannel'
./review.sh updatechannel -c reviewchannel -o 3

# Submit channel configuration update to add 'exportingentityorg' to 'shippingchannel'
./review.sh updatechannel -c shippingchannel -o 4

# Start CA, peer, CouchDB for 'exportingentityorg'
./review.sh startneworg
# Wait for the peer to be ready
sleep 5

# Join peer0.exportingentityorg.review.com to 'reviewchannel'
./review.sh joinneworg -c reviewchannel

# Join peer0.exportingentityorg.review.com to 'shippingchannel'
./review.sh joinneworg -c shippingchannel

# Set peer0.exportingentityorg.review.com as anchor peer for exportingentityorg in 'reviewchannel'
./review.sh updateneworganchorpeer -c reviewchannel

# Set peer0.exportingentityorg.review.com as anchor peer for exportingentityorg in 'shippingchannel'
./review.sh updateneworganchorpeer -c shippingchannel
