package Cx

import data.generic.cloudformation as cloudFormationLib
import data.generic.common as common_lib

CxPolicy[result] {
	document := input.document[i]
	resource := document.Resources[key]
	resource.Type == "AWS::DocDB::DBCluster"

	properties := resource.Properties
	paramName := properties.MasterUserPassword
	defaultToken := document.Parameters[paramName].Default

	regex.match(`[A-Za-z\d@$!%*"#"?&]{8,}`, defaultToken)
	not cloudFormationLib.hasSecretManager(defaultToken, document.Resources)

	result := {
		"documentId": input.document[i].id,
		"searchKey": sprintf("Parameters.%s.Default", [paramName]),
		"issueType": "IncorrectValue",
		"keyExpectedValue": sprintf("Parameters.%s.Default is defined", [paramName]),
		"keyActualValue": sprintf("Parameters.%s.Default shouldn't be defined", [paramName]),
	}
}

CxPolicy[result] {
	document := input.document[i]
	resource := document.Resources[key]
	resource.Type == "AWS::DocDB::DBCluster"

	properties := resource.Properties
	paramName := properties.MasterUserPassword
	common_lib.valid_key(document, "Parameters")
	not common_lib.valid_key(document.Parameters, paramName)

	defaultToken := paramName

	regex.match(`[A-Za-z\d@$!%*"#"?&]{8,}`, defaultToken)
	not cloudFormationLib.hasSecretManager(defaultToken, document.Resources)

	result := {
		"documentId": input.document[i].id,
		"searchKey": sprintf("Resources.%s.Properties.MasterUserPassword", [key]),
		"issueType": "IncorrectValue",
		"keyExpectedValue": sprintf("Resources.%s.Properties.MasterUserPassword must not be in plain text string", [key]),
		"keyActualValue": sprintf("Resources.%s.Properties.MasterUserPassword must be defined as a parameter or have a secret manager referenced", [key]),
	}
}

CxPolicy[result] {
	document := input.document[i]
	resource := document.Resources[key]
	resource.Type == "AWS::DocDB::DBCluster"

	properties := resource.Properties
	paramName := properties.MasterUserPassword
	not common_lib.valid_key(document, "Parameters")

	defaultToken := paramName

	regex.match(`[A-Za-z\d@$!%*"#"?&]{8,}`, defaultToken)
	not cloudFormationLib.hasSecretManager(defaultToken, document.Resources)

	result := {
		"documentId": input.document[i].id,
		"searchKey": sprintf("Resources.%s.Properties.MasterUserPassword", [key]),
		"issueType": "IncorrectValue",
		"keyExpectedValue": sprintf("Resources.%s.Properties.MasterUserPassword must not be in plain text string", [key]),
		"keyActualValue": sprintf("Resources.%s.Properties.MasterUserPassword must be defined as a parameter or have a secret manager referenced", [key]),
	}
}