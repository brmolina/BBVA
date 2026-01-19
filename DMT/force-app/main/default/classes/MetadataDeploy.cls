/**
* Helper class to update custom metadata records with specific conditions and configurations.
* !This class is used only for development purposes.
*/
public without sharing class MetadataDeploy implements Metadata.DeployCallback {
    /**
    * @description Update all custom metadata records.
    */
    public static void updateAllCustomMetadata() {
        try {
            updateIASOCustomMetadata();
            updateARCEConfigCustomMetadata();
            updateQVCDCustomMetadata();
            updateServicePersistenceCustomMetadata();
        } catch (Exception e) {
            System.debug('Error: ' + e.getMessage());
        }
    }

    /**
    * @description Update iaso__GBL_integration_service__mdt custom metadata records.
    * @return The result of the deployment.
    */
    public static String updateIASOCustomMetadata() {
        try {
            Metadata.DeployContainer mdContainer = new Metadata.DeployContainer(); 
            List<iaso__GBL_integration_service__mdt> listCMT = [
                SELECT
                    Id,
                    Label,
                    DeveloperName,
                    MasterLabel,
                    iaso__Authentication_Service__c,
                    iaso__Retrieve_Mock_LTA__c,
                    NamespacePrefix
                FROM iaso__GBL_integration_service__mdt
                WITH USER_MODE
            ];
            for (iaso__GBL_integration_service__mdt cmt : listCMT) {
                Metadata.CustomMetadata customMetadata = new Metadata.CustomMetadata();
                final String nameSpace = cmt.NamespacePrefix == 'arce' ? 'arce__' : '';
                customMetadata.fullName = 'iaso__GBL_integration_service__mdt.' + nameSpace + cmt.DeveloperName;
                customMetadata.label = cmt.MasterLabel;
                if (
                    cmt.iaso__Authentication_Service__c == 'GrantingTicketsGlobal' ||
                    cmt.iaso__Authentication_Service__c == 'GrantingTickets_PRO' ||
                    cmt.developername == 'ratingEngine'
                ) {
                    Metadata.CustomMetadataValue customField1 = new Metadata.CustomMetadataValue(); //the values you're changing/updating
                    customField1.field = 'iaso__Authentication_Service__c'; //the custom field API Name that you're wanting to insert/update a value of
                    customField1.value = 'GrantingTickets_INT';
                    customMetadata.values.add(customField1); //add the changes to List of changes to be deployed
                    if (cmt.DeveloperName == 'ratingEngine') {
                        Metadata.CustomMetadataValue customField2 = new Metadata.CustomMetadataValue(); //the values you're changing/updating
                        customField2.field = 'iaso__Querystring_Input_Template_LTA__c'; //the custom field API Name that you're wanting to insert/update a value of
                        final String queryStringInput = '/#riskAssessmentId#/participants/#participantId#/engine-rating-calculations?eventType.id=#eventType#&subEventType.id=#subEvent#&financialStatement.id=#ffssId#&rating.id=#ratingId#&businessAgent.id=#businessAgentId#&economicGroup.participantType.id=#participationType#&bank.id=#bankId#&bank.branch.id=#branchId#&bank.branch.level.id=#branchLevel#&ratingModel.id=#modelId#&riskSegment=LARGE_ENTERPRISES';
                        customField2.value = queryStringInput;
                        customMetadata.values.add(customField2); //add the changes to List of changes to be deployed
                    }
                    mdContainer.addMetadata(customMetadata);
                }
            }
            System.debug('mdContainer es: ' + JSON.serialize(mdContainer));
            return deployCustomMetadata(mdContainer);
            // Metadata.DeployContainer mdContainer = new Metadata.DeployContainer();
            // List<iaso__GBL_integration_service__mdt> listCMT = [select Id,Label,DeveloperName,MasterLabel,iaso__Authentication_Service__c, iaso__Retrieve_Mock_LTA__c,NamespacePrefix from iaso__GBL_integration_service__mdt where iaso__Authentication_Service__c = 'GrantingTicketsGlobal' OR iaso__Authentication_Service__c = 'GrantingTickets_PRO'];
            // for(iaso__GBL_integration_service__mdt cmt : listCMT) {
            //     Metadata.CustomMetadata customMetadata = new Metadata.CustomMetadata();
            //     final String nameSpace = cmt.NamespacePrefix == 'arce' ? 'arce__' : '';
            //     customMetadata.fullName = 'iaso__GBL_integration_service__mdt.' + nameSpace + cmt.DeveloperName;
            //     customMetadata.label = cmt.MasterLabel;
            //     Metadata.CustomMetadataValue customField1 = new Metadata.CustomMetadataValue(); //the values you're changing/updating
            //     customField1.field = 'iaso__Authentication_Service__c'; //the custom field API Name that you're wanting to insert/update a value of
            //     customField1.value = 'GrantingTickets_INT';
            //     customMetadata.values.add(customField1);//add the changes to List of changes to be deployed
            //     mdContainer.addMetadata(customMetadata);
            // }
            // return deployCustomMetadata(mdContainer);
        } catch (Exception e) {
            return e.getMessage();
        }
    }

    /**
    * @description Update arce__Arce_Config__mdt custom metadata records.
    * @return The result of the deployment.
    */
    public static String updateARCEConfigCustomMetadata() {
        try {
            Metadata.DeployContainer mdContainer = new Metadata.DeployContainer();
            List<arce__Arce_Config__mdt> listCMT = [
                SELECT Id, MasterLabel, DeveloperName, arce__Config_Name__c, arce__Value1__c, NamespacePrefix
                FROM arce__Arce_Config__mdt
                WHERE
                    developername IN (
                        'UserInterface',
                        'AccountInterface',
                        'FFSSValidation',
                        'ratingExternalMapping',
                        'localGroupStructure',
                        'ExtRatngCondition',
                        'WorkflowConfig',
                        'RAIPDisplayGroupStructure',
                        'AvailableARCETypes',
                        'RAIPCallTriageEngine',
                        'RAIPEnablePersistActions'
                    )
                WITH USER_MODE
            ];
            Map<String, String> mapa = new Map<String, String>();
            mapa.put('UserInterface', 'DES_Arc_User_Locator');
            mapa.put('AccountInterface', 'DES_Arc_Account_Locator');
            mapa.put('FFSSValidation', 'true');
            mapa.put('ratingExternalMapping', 'arce.Arc_GBL_RatingDetailsMapping');
            mapa.put('localGroupStructure', 'true');
            mapa.put('ExtRatngCondition', 'arce__g_golden_customer_id__c:local_customer_id__c=Local_Client__c');
            mapa.put('WorkflowConfig', 'DES_Arc_GBL_Workflow_Service');
            mapa.put('RAIPDisplayGroupStructure', 'false');
            mapa.put('AvailableARCETypes', 'RAIP');
            mapa.put('RAIPCallTriageEngine', 'false');
            mapa.put('RAIPEnablePersistActions', 'false');
            Set<String> setKeys = mapa.keySet();

            for (arce__Arce_Config__mdt cmt : listCMT) {
                if (setKeys.contains(cmt.DeveloperName)) {
                    Metadata.CustomMetadata customMetadata = new Metadata.CustomMetadata();
                    final String nameSpace = cmt.NamespacePrefix == 'arce' ? 'arce__' : '';
                    customMetadata.fullName = 'arce__Arce_Config__mdt.' + nameSpace + cmt.DeveloperName; //custom metadata name
                    customMetadata.label = cmt.MasterLabel;

                    Metadata.CustomMetadataValue customField = new Metadata.CustomMetadataValue();
                    customField.field = 'arce__Value1__c';
                    customField.value = mapa.get(cmt.DeveloperName);
                    customMetadata.values.add(customField);

                    mdContainer.addMetadata(customMetadata);
                }
            }
            return deployCustomMetadata(mdContainer);
        } catch (Exception e) {
            return e.getMessage();
        }
    }

    /**
    * @description Update qvcd__Fields_Card__mdt custom metadata records.
    * @return The result of the deployment.
    */
    public static String updateQVCDCustomMetadata() {
        try {
            Metadata.DeployContainer mdContainer = new Metadata.DeployContainer();
            List<qvcd__Fields_Card__mdt> listCMT = [
                SELECT
                    MasterLabel,
                    DeveloperName,
                    NamespacePrefix,
                    qvcd__GBL_Name_API_field__c,
                    qvcd__GBL_API_name_object__c
                FROM qvcd__Fields_Card__mdt
                WHERE developername IN ('Arc_Gen_Carousel6', 'Arc_Gen_Carousel7')
                WITH USER_MODE
            ];

            Map<String, String> mapa = new Map<String, String>();
            mapa.put('Arc_Gen_Carousel6', 'DES_Local_Client__r.Alpha_code__c');
            mapa.put('Arc_Gen_Carousel7', 'DES_Local_Client__r.taxpayer_id__c');
            Set<String> setKeys = mapa.keySet();

            for (qvcd__Fields_Card__mdt cmt : listCMT) {
                if (setKeys.contains(cmt.DeveloperName)) {
                    Metadata.CustomMetadata customMetadata = new Metadata.CustomMetadata();
                    final String nameSpace = cmt.NamespacePrefix == 'arce' ? 'arce__' : '';
                    customMetadata.fullName = 'qvcd__Fields_Card__mdt.' + nameSpace + cmt.DeveloperName; //custom metadata name
                    customMetadata.label = cmt.MasterLabel;

                    Metadata.CustomMetadataValue customField = new Metadata.CustomMetadataValue();
                    customField.field = 'qvcd__GBL_Name_API_field__c';
                    customField.value = mapa.get(cmt.DeveloperName);
                    customMetadata.values.add(customField);

                    Metadata.CustomMetadataValue customField2 = new Metadata.CustomMetadataValue();
                    customField2.field = 'qvcd__GBL_API_name_object__c';
                    customField2.value = 'arce__Analysis__c';
                    customMetadata.values.add(customField2);

                    mdContainer.addMetadata(customMetadata);
                }
            }

            return deployCustomMetadata(mdContainer);
        } catch (Exception e) {
            return e.getMessage();
        }
    }

    /**
    * @description Update arce__Service_persistence__mdt custom metadata records.
    * @return The result of the deployment.
    */
    public static String updateServicePersistenceCustomMetadata() {
        try {
            Metadata.DeployContainer mdContainer = new Metadata.DeployContainer();
            List<arce__Service_persistence__mdt> listCMT = [
                SELECT MasterLabel, DeveloperName, NamespacePrefix, arce__JSON_input__c
                FROM arce__Service_persistence__mdt
                WHERE developername IN ('persistenceModifiers')
                WITH USER_MODE
            ];

            Map<String, String> mapa = new Map<String, String>();
            final String jsonInput = '{"modifierObj.arce__Currency_risk_associated_with_debt__c":{"id":"06","type":"MODIFIER_RISK_FACTOR","parentCode":"02"},"modifierObj.arce__Debt_maturity_profile__c":{"id":"07","type":"MODIFIER_RISK_FACTOR","parentCode":"02"},"modifierObj.arce__Interest_rate_risk_associated_with_debt__c":{"id":"08","type":"MODIFIER_RISK_FACTOR","parentCode":"02"},"modifierObj.arce__Investments__c":{"id":"10","type":"MODIFIER_RISK_FACTOR","parentCode":"02"},"modifierObj.arce__Financial_discipline__c":{"id":"11","type":"MODIFIER_RISK_FACTOR","parentCode":"03"},"modifierObj.arce__Financial_policy__c":{"id":"12","type":"MODIFIER_RISK_FACTOR","parentCode":"03"},"modifierObj.arce__Strategic_planning_process__c":{"id":"13","type":"MODIFIER_RISK_FACTOR","parentCode":"05"},"modifierObj.arce__Consistency_of_strategy__c":{"id":"14","type":"MODIFIER_RISK_FACTOR","parentCode":"05"},"modifierObj.arce__Ability_to_track__c":{"id":"15","type":"MODIFIER_RISK_FACTOR","parentCode":"05"},"modifierObj.arce__Comprehensiveness_of_enterprise__c":{"id":"16","type":"MODIFIER_RISK_FACTOR","parentCode":"05"},"modifierObj.arce__Standards_for_operational_performance__c":{"id":"17","type":"MODIFIER_RISK_FACTOR","parentCode":"05"},"modifierObj.arce__Managements_operational_effectiveness__c":{"id":"18","type":"MODIFIER_RISK_FACTOR","parentCode":"05"},"modifierObj.arce__Management_s_expertise_and_experience__c":{"id":"19","type":"MODIFIER_RISK_FACTOR","parentCode":"05"},"modifierObj.arce__Managements_depth_and_breadth__c":{"id":"20","type":"MODIFIER_RISK_FACTOR","parentCode":"05"},"modifierObj.arce__Governance_financial_reporting__c":{"id":"21","type":"MODIFIER_RISK_FACTOR","parentCode":"05"},"modifierObj.arce__Newliquidity_Assestment__c":{"id":"27","type":"MODIFIER_RISK_FACTOR","parentCode":"04"},"modifierObj.arce__Financial_Flexibility_Liquidity_Score__c":{"id":"28","type":"MODIFIER_RISK_FACTOR","parentCode":"05"},"modifierObj.arce__OFF_Balance_Sheet_Risk__c":{"id":"320","type":"MODIFIER_RISK_FACTOR","parentCode":"09"},"modifierObj.arce__Company_Participates_Litig__c":{"id":"321","type":"MODIFIER_RISK_FACTOR","parentCode":"09"}}';
            mapa.put('persistenceModifiers', jsonInput);
            Set<String> setKeys = mapa.keySet();

            for (arce__Service_persistence__mdt cmt : listCMT) {
                if (setKeys.contains(cmt.DeveloperName)) {
                    Metadata.CustomMetadata customMetadata = new Metadata.CustomMetadata();
                    final String nameSpace = cmt.NamespacePrefix == 'arce' ? 'arce__' : '';
                    customMetadata.fullName = 'arce__Service_persistence__mdt.' + nameSpace + cmt.DeveloperName; //custom metadata name
                    customMetadata.label = cmt.MasterLabel;

                    Metadata.CustomMetadataValue customField = new Metadata.CustomMetadataValue();
                    customField.field = 'arce__JSON_input__c';
                    customField.value = mapa.get(cmt.DeveloperName);
                    customMetadata.values.add(customField);

                    mdContainer.addMetadata(customMetadata);
                }
            }

            return deployCustomMetadata(mdContainer);
        } catch (Exception e) {
            return e.getMessage();
        }
    }

    /**
    * @description Helper method to deploy custom metadata records.
    * @param mdContainer The metadata container to be deployed.
    * @return The result of the deployment.
    */
    public static String deployCustomMetadata(Metadata.DeployContainer mdContainer) {
        try {
            MetadataDeploy callback = new MetadataDeploy();
            Id jobId = Metadata.Operations.enqueueDeployment(mdContainer, callback);
            system.debug('jobId is ' + jobId);
            return 'Success';
        } catch (Exception e) {
            return e.getMessage();
        }
    }

    /**
    * @description Helper method to handle the result of the deployment.
    * @param result The result of the deployment.
    * @param context The context of the deployment.
    */
    public void handleResult(Metadata.DeployResult result, Metadata.DeployCallbackContext context) {
        if (result.status == Metadata.DeployStatus.SUCCEEDED) {
            //success
            System.debug(' ===>' + result);
        } else {
            //not success
            System.debug(' ===> fail ' + result);
        }
    }
}