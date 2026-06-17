/**
* Helper class to update custom metadata records with environment-specific configurations.
*/
@SuppressWarnings('sf:OnlyOneReturn')
public without sharing class MetadataDeploy implements Metadata.DeployCallback {
    /** Error literal **/
    private static final String ERROR_LIT = 'Error';

    /**
    * arce__Arce_Config__mdt configuration
    */
    public static void updateAllCustomMetadata() {
        try {
            updateIASOCustomMetadata();
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'Error updating metadata: ' + e.getMessage());
        }
    }

    /**
    * updateIASOCustomMetadata
    */
    public static String updateIASOCustomMetadata() {
        try {
            final Metadata.DeployContainer container = new Metadata.DeployContainer();

            final List<iaso__GBL_integration_service__mdt> records = [
                SELECT DeveloperName, MasterLabel, NamespacePrefix, iaso__Authentication_Service__c
                FROM iaso__GBL_integration_service__mdt
                WHERE iaso__Authentication_Service__c IN ('GrantingTicketsGlobal', 'GrantingTickets_PRO', 'GrantingTicketsES_PRO', 'GrantingTicketsMX_PRO')
                WITH USER_MODE
            ];
           for (iaso__GBL_integration_service__mdt record : records) {
                final Metadata.CustomMetadata metadata = new Metadata.CustomMetadata();
                metadata.fullName = 'iaso__GBL_integration_service__mdt.' + getNamespace(record.NamespacePrefix) + record.DeveloperName;
                metadata.label = record.MasterLabel;

                final String newAuthService = getAuthenticationService(record.iaso__Authentication_Service__c);
                addField(metadata, 'iaso__Authentication_Service__c', newAuthService);
                container.addMetadata(metadata);
            }

            return deployMetadata(container);
        } catch (Exception e) {
            return ERROR_LIT + ': ' + e.getMessage();
        }
    }

    /**
    * getAuthenticationService
    */
    private static String getAuthenticationService(String currentValue) {
        if (currentValue == 'GrantingTicketsES_PRO') {
            return 'GrantingTicketsES_INT';
        } else if (currentValue == 'GrantingTicketsMX_PRO') {
            return 'GrantingTicketsMX_INT';
        } else if (currentValue == 'GrantingTicketsGlobal' || currentValue == 'GrantingTickets_PRO') {
            return 'GrantingTickets_INT';
        }
        return currentValue;
    }

    /**
    * getNamespace
    */
    private static String getNamespace(String namespacePrefix) {
        return namespacePrefix == 'arce' ? 'arce__' : '';
    }

    /**
    * addField
    */
    private static void addField(Metadata.CustomMetadata metadata, String fieldName, String value) {
        final Metadata.CustomMetadataValue field = new Metadata.CustomMetadataValue();
        field.field = fieldName;
        field.value = value;
        metadata.values.add(field);
    }

    /**
    * deployMetadata
    */
    private static String deployMetadata(Metadata.DeployContainer container) {
        try {
            final MetadataDeploy callback = new MetadataDeploy();
            final Id jobId = Metadata.Operations.enqueueDeployment(container, callback);
            System.debug('Deployment job ID: ' + jobId);
            return 'Success - Job ID: ' + jobId;
        } catch (Exception e) {
            return 'Deployment failed: ' + e.getMessage();
        }
    }

    /**
    * handleResult
    */
    public void handleResult(Metadata.DeployResult result, Metadata.DeployCallbackContext context) {
        if (result.status == Metadata.DeployStatus.SUCCEEDED) {
            System.debug('Deployment succeeded');
        } else {
            System.debug('Deployment failed: ' + result);
        }
    }
}