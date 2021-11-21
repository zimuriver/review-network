/*
SPDX-License-Identifier: Apache-2.0
*/

var os = require('os');
var path = require('path');

var tempdir = "../bash/client-certs";

// Frame the endorsement policy
var FOUR_ORG_MEMBERS_AND_ADMIN = [{
	role: {
		name: 'member',
		mspId: 'NeuOrgMSP'
	}
}, {
	role: {
		name: 'member',
		mspId: 'ThuOrgMSP'
	}
}, {
	role: {
		name: 'member',
		mspId: 'PkuOrgMSP'
	}
}, {
	role: {
		name: 'member',
		mspId: 'ConferenceOrgMSP'
	}
}, {
	role: {
		name: 'admin',
		mspId: 'ReviewOrdererOrgMSP'
	}
}];

var FIVE_ORG_MEMBERS_AND_ADMIN = [{
	role: {
		name: 'member',
		mspId: 'NeuOrgMSP'
	}
}, {
	role: {
		name: 'member',
		mspId: 'ExportingEntityOrgMSP'
	}
}, {
	role: {
		name: 'member',
		mspId: 'ThuOrgMSP'
	}
}, {
	role: {
		name: 'member',
		mspId: 'PkuOrgMSP'
	}
}, {
	role: {
		name: 'member',
		mspId: 'ConferenceOrgMSP'
	}
}, {
	role: {
		name: 'admin',
		mspId: 'ReviewOrdererOrgMSP'
	}
}];

var ONE_OF_FOUR_ORG_MEMBER = {
	identities: FOUR_ORG_MEMBERS_AND_ADMIN,
	policy: {
		'1-of': [{ 'signed-by': 0 }, { 'signed-by': 1 }, { 'signed-by': 2 }, { 'signed-by': 3 }]
	}
};

var ALL_FOUR_ORG_MEMBERS = {
	identities: FOUR_ORG_MEMBERS_AND_ADMIN,
	policy: {
		'4-of': [{ 'signed-by': 0 }, { 'signed-by': 1 }, { 'signed-by': 2 }, { 'signed-by': 3 }]
	}
};

var ALL_FIVE_ORG_MEMBERS = {
	identities: FIVE_ORG_MEMBERS_AND_ADMIN,
	policy: {
		'5-of': [{ 'signed-by': 0 }, { 'signed-by': 1 }, { 'signed-by': 2 }, { 'signed-by': 3 }, { 'signed-by': 4 }]
	}
};

var ALL_ORGS_EXCEPT_REGULATOR = {
	identities: FOUR_ORG_MEMBERS_AND_ADMIN,
	policy: {
		'3-of': [{ 'signed-by': 0 }, { 'signed-by': 1 }, { 'signed-by': 2 }]
	}
};

var ACCEPT_ALL = {
	identities: [],
	policy: {
		'0-of': []
	}
};

var chaincodeLocation = '../chaincode';

var networkId = 'review-network';

var networkConfig = './config.json';

var networkLocation = '../bash';

var channelConfig = 'channel-artifacts/%s/channel.tx';

var IMPORTER_ORG = 'thuorg';
var EXPORTER_ORG = 'neuorg';
var EXPORTING_ENTITY_ORG = 'exportingentityorg';
var CARRIER_ORG = 'pkuorg';
var REGULATOR_ORG = 'conferenceorg';

var CHANNEL_NAME = 'reviewchannel';
var CHAINCODE_PATH = 'github.com/review_workflow';
var CHAINCODE_ID = 'reviewcc';
var CHAINCODE_VERSION = 'v0';
var CHAINCODE_UPGRADE_PATH = 'github.com/review_workflow_v1';
var CHAINCODE_UPGRADE_VERSION = 'v1';

var TRANSACTION_ENDORSEMENT_POLICY = ALL_FOUR_ORG_MEMBERS;

module.exports = {
	tempdir: tempdir,
	chaincodeLocation: chaincodeLocation,
	networkId: networkId,
	networkConfig: networkConfig,
	networkLocation: networkLocation,
	channelConfig: channelConfig,
	IMPORTER_ORG: IMPORTER_ORG,
	EXPORTER_ORG: EXPORTER_ORG,
	EXPORTING_ENTITY_ORG: EXPORTING_ENTITY_ORG,
	CARRIER_ORG: CARRIER_ORG,
	REGULATOR_ORG: REGULATOR_ORG,
	CHANNEL_NAME: CHANNEL_NAME,
	CHAINCODE_PATH: CHAINCODE_PATH,
	CHAINCODE_ID: CHAINCODE_ID,
	CHAINCODE_VERSION: CHAINCODE_VERSION,
	CHAINCODE_UPGRADE_PATH: CHAINCODE_UPGRADE_PATH,
	CHAINCODE_UPGRADE_VERSION: CHAINCODE_UPGRADE_VERSION,
	ALL_FOUR_ORG_MEMBERS: ALL_FOUR_ORG_MEMBERS,
	ALL_FIVE_ORG_MEMBERS: ALL_FIVE_ORG_MEMBERS,
	TRANSACTION_ENDORSEMENT_POLICY: TRANSACTION_ENDORSEMENT_POLICY
};
