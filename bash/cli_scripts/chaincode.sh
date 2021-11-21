#!/bin/bash
#
# SPDX-License-Identifier: Apache-2.0
#

# set global variables
CHANNEL_NAME=$CHANNEL_NAME
NUM_ORGS_IN_CHANNEL=$NUM_ORGS_IN_CHANNEL
PEERORGLIST=$PEERORGLIST
DELAY=3
COUNTER=1
MAX_RETRY=5
ORDERER_HOST=orderer.review.com
ORDERER_PORT=7050
ORDERER_CA=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/review.com/orderers/orderer.review.com/msp/tlscacerts/tlsca.review.com-cert.pem

CC_LANGUAGE=$CC_LANGUAGE
CC_LABEL=${CC_LABEL}
CC_VERSION=${CC_VERSION}
CC_PKG_FILE=${CC_LABEL}_${CC_VERSION}.tar.gz
CC_SEQUENCE_NUM=1
CC_FUNC=${CC_FUNC}
CC_ARGS=${CC_ARGS}
ORGANIZATION=${ORGANIZATION}

# verify the result of the end-to-end test
verifyResult() {
  if [ $1 -ne 0 ]; then
    echo "!!!!!!!!!!!!!!! "$2" !!!!!!!!!!!!!!!!"
    echo "========= ERROR !!! FAILED to execute Chaincode Installation Scenario ==========="
    echo
    exit 1
  fi
}

neuorg_PORT=7051
thuorg_PORT=8051
pkuorg_PORT=9051
conferenceorg_PORT=10051
exportingentityorg_PORT=12051

setOrganization() {
  if [[ $# -lt 1 ]]
  then
    echo "Run: setOrganizations <org> [<user>]"
    exit 1
  fi
  ORG=$1
  USER=Admin
  if [[ $# -eq 2 ]]
  then
    USER=$2
  fi
  MSP=
  if [[ "$ORG" == "neuorg" ]]
  then
    MSP=NeuOrgMSP
    PORT=$neuorg_PORT
  elif [[ "$ORG" == "thuorg" ]]
  then
    MSP=ThuOrgMSP
    PORT=$thuorg_PORT
  elif [[ "$ORG" == "pkuorg" ]]
  then
    MSP=PkuOrgMSP
    PORT=$pkuorg_PORT
  elif [[ "$ORG" == "conferenceorg" ]]
  then
    MSP=ConferenceOrgMSP
    PORT=$conferenceorg_PORT
  elif [[ "$ORG" == "exportingentityorg" ]]
  then
    MSP=ExportingEntityOrgMSP
    PORT=$exportingentityorg_PORT
  else
    echo "Unknown Org: "$ORG
    exit 1
  fi
  CORE_PEER_LOCALMSPID=$MSP
  CORE_PEER_TLS_ROOTCERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/$ORG.review.com/peers/peer0.$ORG.review.com/tls/ca.crt
  CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/$ORG.review.com/users/$USER@$ORG.review.com/msp
  CORE_PEER_ADDRESS=peer0.$ORG.review.com:$PORT
  CORE_PEER_TLS_CERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/$ORG.review.com/peers/peer0.$ORG.review.com/tls/server.crt
  CORE_PEER_TLS_KEY_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/$ORG.review.com/peers/peer0.$ORG.review.com/tls/server.key
}

packageChaincode() {
  setOrganization neuorg

  set -x
  peer lifecycle chaincode package $CC_PKG_FILE --path ./contracts/$CC_VERSION/$CC_LABEL/ --lang $CC_LANGUAGE --label $CC_LABEL >&log.txt
  res=$?
  set +x
  cat log.txt
  if [ ! -f $CC_PKG_FILE ]
  then
    res=1
  fi
  verifyResult $res "Chaincode packaging failed"
  echo "===================== Chaincode packaged ===================== "
  echo
}

installChaincodeInOrg() {
  ORG=$1
  setOrganization $ORG

  if [ ! -f $CC_PKG_FILE ]
  then
    res=1
  else
    set -x
    peer lifecycle chaincode install --connTimeout 300s $CC_PKG_FILE >&log.txt
    res=$?
    set +x
  fi
  cat log.txt
  verifyResult $res "Failed to install chaincode on peer0.${ORG}.review.com for channel '$CHANNEL_NAME' "

  CC_PKG_ID_COUNT=$(peer lifecycle chaincode queryinstalled --connTimeout 120s | grep "Label: "$CC_LABEL | wc -l)
  if [ $CC_PKG_ID_COUNT != $CC_SEQUENCE_NUM ]
  then
    verifyResult 1 "Failed to verify chaincode installation on peer0.${ORG}.review.com for channel '$CHANNEL_NAME' "
  fi
}

installChaincode() {
  OLD_CC_PKG_IDS=$(peer lifecycle chaincode queryinstalled --connTimeout 120s | grep -v "Installed\ chaincodes\ on\ peer" | awk '{print $3}')
  for org in $PEERORGLIST; do
    installChaincodeInOrg $org
    echo "===================== Installed chaincode on peer0.${org}.review.com for channel '$CHANNEL_NAME' ===================== "
    echo
  done
}

approveChaincodeDefinitionForOrg() {
  ORG=$1
  setOrganization $ORG

  set -x
  peer lifecycle chaincode approveformyorg --connTimeout 120s -o $ORDERER_HOST:$ORDERER_PORT --ordererTLSHostnameOverride $ORDERER_HOST --channelID $CHANNEL_NAME --name $CC_LABEL --version $CC_VERSION --signature-policy $ENDORSEMENT_POLICY --init-required --package-id $CC_PKG_ID --sequence $CC_SEQUENCE_NUM --tls true --cafile $ORDERER_CA >&log.txt
  res=$?
  set +x
  cat log.txt
  verifyResult $res "Failed to approve chaincode definition for ${ORG} for channel '$CHANNEL_NAME' "
}

approveChaincodeDefinitions() {
  ENDORSEMENT_POLICY=
  for org in $PEERORGLIST; do
    setOrganization $org
    if [ "$ENDORSEMENT_POLICY" == "" ]
    then
      ENDORSEMENT_POLICY="AND('"$MSP.member"'"
    else
      ENDORSEMENT_POLICY=$ENDORSEMENT_POLICY,"'"$MSP.member"'"
    fi
    CC_PKG_ID_COUNT=$(peer lifecycle chaincode queryinstalled --connTimeout 120s | grep "Label: "$CC_LABEL | wc -l)
    if [ $CC_PKG_ID_COUNT != $CC_SEQUENCE_NUM ]
    then
      verifyResult 1 "Failed to verify chaincode installation on peer0.$org.review.com for channel '$CHANNEL_NAME' "
    fi
  done
  ENDORSEMENT_POLICY=$ENDORSEMENT_POLICY")"

  # Get the package ID from an org peer that is guaranteed to run all of our chaincodes
  setOrganization neuorg
  peer lifecycle chaincode queryinstalled --connTimeout 120s | grep -v "Installed\ chaincodes\ on\ peer" | grep $CC_LABEL > install.tmp
  if [ "$OLD_CC_PKG_IDS" != "" ]
  then
    for OLD_CC_PKG_ID in $OLD_CC_PKG_IDS
    do
      grep -v $OLD_CC_PKG_ID install.tmp > install1.tmp
      mv install1.tmp install.tmp
    done
  fi
  CC_PKG_ID=$(cat install.tmp | awk '{print $3}')
  rm install.tmp
  CC_PKG_ID=${CC_PKG_ID:0:${#CC_PKG_ID}-1}	# Remove the comma at the end

  # Approve definition by each peer on the channel
  if [ "$NUM_ORGS_IN_CHANNEL" == "3" ]
  then
    ORG_LIST="neuorg thuorg conferenceorg"
  else
    ORG_LIST="neuorg thuorg pkuorg conferenceorg"
  fi
  if [ "$CC_SEQUENCE_NUM" == "2" ]
  then
    ORG_LIST=$ORG_LIST" exportingentityorg"
  fi
  for org in $ORG_LIST; do
    approveChaincodeDefinitionForOrg $org
    echo "===================== Approved chaincode definitions for ${org} for channel '$CHANNEL_NAME' ===================== "
    echo
  done
}

commitChaincodeDefinition() {
  setOrganization neuorg

  ORG_PEER_CONNECTION=""
  READINESS=$(peer lifecycle chaincode checkcommitreadiness --connTimeout 120s --channelID $CHANNEL_NAME --name $CC_LABEL --version $CC_VERSION --init-required --sequence $CC_SEQUENCE_NUM --tls true --cafile $ORDERER_CA --output json)
  if [ "$NUM_ORGS_IN_CHANNEL" == "3" ]
  then
    ORG_LIST="neuorg thuorg conferenceorg"
  else
    ORG_LIST="neuorg thuorg pkuorg conferenceorg"
  fi
  if [ "$CC_SEQUENCE_NUM" == "2" ]
  then
    ORG_LIST=$ORG_LIST" exportingentityorg"
  fi
  for org in $ORG_LIST; do
    READINESS_FOR_ORG=$(echo $READINESS | jq .approvals.${org})
    if [ ! $READINESS_FOR_ORG ]
    then
      verifyResult 1 "${org} has not approved the chaincode definition for channel '$CHANNEL_NAME' yet"
    fi
    port_key=${org}_PORT
    echo "Chaincode definition approved by ${org}"
    ORG_PEER_CONNECTION=$ORG_PEER_CONNECTION" --peerAddresses peer0.${org}.review.com:${!port_key} --tlsRootCertFiles /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/${org}.review.com/peers/peer0.${org}.review.com/tls/ca.crt"
  done

  ENDORSEMENT_POLICY=
  for org in $PEERORGLIST; do
    setOrganization $org
    if [ "$ENDORSEMENT_POLICY" == "" ]
    then
      ENDORSEMENT_POLICY="AND('"$MSP.member"'"
    else
      ENDORSEMENT_POLICY=$ENDORSEMENT_POLICY,"'"$MSP.member"'"
    fi
  done
  ENDORSEMENT_POLICY=$ENDORSEMENT_POLICY")"

  set -x
  peer lifecycle chaincode commit --connTimeout 120s -o $ORDERER_HOST:$ORDERER_PORT --ordererTLSHostnameOverride $ORDERER_HOST --channelID $CHANNEL_NAME --name $CC_LABEL --version $CC_VERSION --sequence $CC_SEQUENCE_NUM --signature-policy $ENDORSEMENT_POLICY --init-required --tls true --cafile $ORDERER_CA $ORG_PEER_CONNECTION >&log.txt
  res=$?
  set +x
  cat log.txt
  verifyResult $res "Failed to commit chaincode definition for channel '$CHANNEL_NAME' "

  CC_COMMITMENT_MESSAGE="Committed chaincode definition for chaincode '${CC_LABEL}' on channel '${CHANNEL_NAME}'"
  CC_COMMITMENT=$(peer lifecycle chaincode querycommitted --connTimeout 120s --channelID $CHANNEL_NAME --name $CC_LABEL --cafile $ORDERER_CA | grep "$CC_COMMITMENT_MESSAGE" | wc -l)
  if [ $CC_COMMITMENT != 1 ]
  then
    verifyResult 1 "Failed to verify chaincode definition commitment on channel '$CHANNEL_NAME' "
  fi
  echo "===================== Committed chaincode definition on channel '$CHANNEL_NAME' ===================== "
}

initializeChaincode() {
  setOrganization neuorg User1

  ORG_PEER_CONNECTION=""
  for org in $PEERORGLIST; do
    port_key=${org}_PORT
    ORG_PEER_CONNECTION=$ORG_PEER_CONNECTION" --peerAddresses peer0.${org}.review.com:${!port_key} --tlsRootCertFiles /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/${org}.review.com/peers/peer0.${org}.review.com/tls/ca.crt"
  done

  set -x
  peer chaincode invoke --connTimeout 120s -o $ORDERER_HOST:$ORDERER_PORT --ordererTLSHostnameOverride $ORDERER_HOST -C $CHANNEL_NAME -n $CC_LABEL --isInit --tls true --waitForEvent --cafile $ORDERER_CA $ORG_PEER_CONNECTION -c '{"function":"'$CC_FUNC'","Args":['"$CC_ARGS"']}' >&log.txt
  res=$?
  set +x
  cat log.txt
  verifyResult $res "Failed to initialize chaincode on channel '$CHANNEL_NAME' "
  echo "===================== Initialized chaincode on channel '$CHANNEL_NAME' ===================== "
}

installAndApproveContractOnNewOrg() {
  # First, install and approve contract on new org peer
  setOrganization exportingentityorg

  # Use the old chaincode version to install the contract on the new org's peer
  TEMP_CC_VERSION=$CC_VERSION
  CC_VERSION=$OLD_CC_VERSION
  CC_PKG_FILE=${CC_LABEL}_${CC_VERSION}.tar.gz
  packageChaincode
  installChaincodeInOrg exportingentityorg

  ENDORSEMENT_POLICY=
  for org in $PEERORGLIST; do
    setOrganization $org
    if [ "$ENDORSEMENT_POLICY" == "" ]
    then
      ENDORSEMENT_POLICY="AND('"$MSP.member"'"
    else
      ENDORSEMENT_POLICY=$ENDORSEMENT_POLICY,"'"$MSP.member"'"
    fi
  done
  ENDORSEMENT_POLICY=$ENDORSEMENT_POLICY")"
  CC_PKG_ID=$(peer lifecycle chaincode queryinstalled --connTimeout 120s | grep -v "Installed\ chaincodes\ on\ peer" | grep $CC_LABEL)
  CC_PKG_ID=$(echo $CC_PKG_ID | awk '{print $3}')
  CC_PKG_ID=${CC_PKG_ID:0:${#CC_PKG_ID}-1}	# Remove the comma at the end
  approveChaincodeDefinitionForOrg exportingentityorg

  # Use the new chaincode version now, for the upgrade
  CC_VERSION=$TEMP_CC_VERSION
  CC_PKG_FILE=${CC_LABEL}_${CC_VERSION}.tar.gz
}

upgradeContract() {
  # First, install and approve contract on new org peer
  installAndApproveContractOnNewOrg

  # Now increment the sequence number and update the contract on 5 peers in 5 different orgs
  PEERORGLIST=$PEERORGLIST" exportingentityorg"
  CC_SEQUENCE_NUM=2
  packageChaincode
  installChaincode
  approveChaincodeDefinitions
  commitChaincodeDefinition
  initializeChaincode
}

invokeChaincode() {
  setOrganization $ORGANIZATION User1

  ORG_PEER_CONNECTION=""
  for org in $PEERORGLIST; do
    ORG_PEER_CONNECTION=$ORG_PEER_CONNECTION" --peerAddresses peer0.${org}.review.com:${${org}_PORT} --tlsRootCertFiles /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/${org}.review.com/peers/peer0.${org}.review.com/tls/ca.crt"
  done

  set -x
  peer chaincode invoke --connTimeout 120s -o $ORDERER_HOST:$ORDERER_PORT --ordererTLSHostnameOverride $ORDERER_HOST -C $CHANNEL_NAME -n $CC_LABEL --tls true --waitForEvent --cafile $ORDERER_CA $ORG_PEER_CONNECTION -c '{"function":"'$CC_FUNC'","Args":['"$CC_ARGS"']}' >&log.txt
  res=$?
  set +x
  cat log.txt
  verifyResult $res "Failed to invoke chaincode transaction on channel '$CHANNEL_NAME' "
  echo "===================== Invoked chaincode transaction on channel '$CHANNEL_NAME' ===================== "
}

queryChaincode() {
  setOrganization $ORGANIZATION User1

  set -x
  peer chaincode query --connTimeout 120s -C $CHANNEL_NAME -n $CC_LABEL -c '{"function":"'$CC_FUNC'","Args":['"$CC_ARGS"']}' >&log.txt
  res=$?
  set +x
  cat log.txt
  verifyResult $res "Failed to query chaincode function on channel '$CHANNEL_NAME' "
  echo "===================== Queried chaincode function on channel '$CHANNEL_NAME' ===================== "
}


if [[ $# -ne 1 ]]
then
  echo "Run: chaincode.sh [package|install|approve|commit|init|upgrade|invoke|query]"
  exit 1
fi
echo $1
if [ "$1" == "package" ]
then
  ## Package chaincode
  echo "Packaging chaincode..."
  packageChaincode
  echo "========= Chaincode packaging completed =========== "
elif [ "$1" == "install" ]
  then
  ## Install chaincode on org peers
  echo "Installing chaincode on org peers..."
  installChaincode
  echo "========= Chaincode installations completed =========== "
elif [ "$1" == "approve" ]
  then
  ## Approve chaincode definition for orgs
  echo "Approving chaincode definition for orgs..."
  approveChaincodeDefinitions
  echo "========= Chaincode definitions approved =========== "
elif [ "$1" == "commit" ]
  then
  ## Commit chaincode definition to channel ledger
  echo "Committing chaincode definition..."
  commitChaincodeDefinition
  echo "========= Chaincode definition committed =========== "
elif [ "$1" == "init" ]
  then
  ## Initialize chaincode by calling an init function (doesn't have to be named "init")
  echo "Initializing chaincode..."
  initializeChaincode
  echo "========= Chaincode initialized =========== "
elif [ "$1" == "upgrade" ]
  then
  ## Upgrade chaincode by calling package, install, approve, commit, and init
  echo "Upgrading chaincode..."
  upgradeContract
  echo "========= Chaincode upgraded =========== "
elif [ "$1" == "invoke" ]
  then
  ## Invoke chaincode transaction
  echo "Invoking chaincode..."
  invokeChaincode
  echo "========= Chaincode invoked =========== "
elif [ "$1" == "query" ]
  then
  ## Query chaincode function
  echo "Querying chaincode..."
  queryChaincode
  echo "========= Chaincode queried =========== "
else
  echo "Unsupported chaincode operation: "$1
fi

echo

exit 0
