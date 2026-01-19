/**
* ------------------------------------------------------------------------------------------------
* @Name     Arc_Gen_ContentVersion_TrgHandler
* @Author   david.montero.bellon.contractor@bbva.com
* @Date     Created: 2025-07-02
* @Group    ARCE
* ------------------------------------------------------------------------------------------------
* @Description: Handler for ContentVersion related trigger logic.
* ------------------------------------------------------------------------------------------------
* @Changes
*
* |2025-07-02 david.montero.bellon.contractor@bbva.com.
*              Class creation.
* ------------------------------------------------------------------------------------------------
*/

public with sharing class Arc_Gen_ContentVersion_TrgHandler {

    /**
    * @description: PS_FILES_ALLOWED value
    */
    private static final String PS_FILES_ALLOWED = 'PS_Files_Allowed';

    /**
    * @description: ENABLE_FILES value
    */
    private static final String ENABLE_FILES = 'EnableFilesProposal';

    /**
    * @description: EXTENSION_ALLOWED value
    */
    private static final String EXTENSION_ALLOWED = 'Extension_Allowed';

    /**
    *---------------------------------------------------------------------------------------------------
    * @Description Main method that processes ContentVersion records and applies validations
    *---------------------------------------------------------------------------------------------------
    * @Author   david.montero.bellon.contractor@bbva.com
    * @Date     Created: 2025-07-02
    * @param   newList - List of ContentVersion records being inserted
    * @return  void
    * @example run(Trigger.new)
    * --------------------------------------------------------------------------------------------------
    **/
    @SuppressWarnings('sf:MethodCouldBeStatic')
    public void run(List<ContentVersion> newList) {
        //Should only control users who have the Proposal Files PS assigned
        final arce__Arc_Gen_Proposal_Files__mdt permissSetFiles = [SELECT arce__Value1__c, arce__IsActive__c FROM arce__Arc_Gen_Proposal_Files__mdt WHERE DeveloperName = :PS_FILES_ALLOWED WITH USER_MODE LIMIT 1];
        final List<String> permissSetNames = new List<String>();
        if (permissSetFiles != null && permissSetFiles.arce__IsActive__c == true && String.isNotBlank(permissSetFiles.arce__Value1__c)) {
            for (String name : permissSetFiles.arce__Value1__c.split(';')) {
                if (String.isNotBlank(name)) {
                    permissSetNames.add(name.trim());
                }
            }
        }

        //Check if user has the required permission sets
        if (hasPermissionSet(permissSetNames)) {
            validateContentVersions(newList);
        }
    }

    /**
    *---------------------------------------------------------------------------------------------------
    * @Description Validates ContentVersion records for size and extension based on metadata configuration
    *---------------------------------------------------------------------------------------------------
    * @Author   david.montero.bellon.contractor@bbva.com
    * @Date     Created: 2025-07-07
    * @param   newList - List of ContentVersion records to validate
    * @return  void
    * @example validateContentVersions(newList)
    * --------------------------------------------------------------------------------------------------
    **/
    private static void validateContentVersions(List<ContentVersion> newList) {
        final arce__Arc_Gen_Proposal_Files__mdt maxSizeConfig = [SELECT arce__Value1__c, arce__IsActive__c FROM arce__Arc_Gen_Proposal_Files__mdt WHERE DeveloperName = :ENABLE_FILES WITH USER_MODE LIMIT 1];
        final arce__Arc_Gen_Proposal_Files__mdt allowedExtension = [SELECT arce__Value1__c, arce__IsActive__c FROM arce__Arc_Gen_Proposal_Files__mdt WHERE DeveloperName = :EXTENSION_ALLOWED WITH USER_MODE LIMIT 1];

        for (ContentVersion contentVersion : newList) {
            if(maxSizeConfig != null && maxSizeConfig.arce__IsActive__c == true && String.isNotBlank(maxSizeConfig.arce__Value1__c)) {
                // Check if the file size exceeds the maximum allowed size
                checkMaxSize(contentVersion, maxSizeConfig.arce__Value1__c);
            }
            if(allowedExtension != null && allowedExtension.arce__IsActive__c == true && String.isNotBlank(allowedExtension.arce__Value1__c)) {
                // Check if the file type is in the list of allowed extensions
                checkExtension(contentVersion, allowedExtension.arce__Value1__c);
            }
        }
    }

    /**
    *---------------------------------------------------------------------------------------------------
    * @Description Validates if the file size exceeds the maximum allowed size
    *---------------------------------------------------------------------------------------------------
    * @Author   david.montero.bellon.contractor@bbva.com
    * @Date     Created: 2025-07-02
    * @param   contentVersion - ContentVersion record to validate
    * @return  void
    * @example checkMaxSize(contentVersionRecord)
    * --------------------------------------------------------------------------------------------------
    **/
    public static void checkMaxSize(ContentVersion contentVersion, String maxSizeConfig) {
        final Integer maxSizeInBytes = Integer.valueOf(maxSizeConfig) * 1024 * 1024;

        if (contentVersion.ContentSize > maxSizeInBytes) {
            contentVersion.addError(System.Label.Arc_Gen_FileMaxSize);
        }
    }

    /**
    *---------------------------------------------------------------------------------------------------
    * @Description Validates if the file type is in the list of allowed extensions
    *---------------------------------------------------------------------------------------------------
    * @Author   david.montero.bellon.contractor@bbva.com
    * @Date     Created: 2025-07-02
    * @param   contentVersion - ContentVersion record to validate
    * @return  void
    * @example checkExtension(contentVersionRecord)
    * --------------------------------------------------------------------------------------------------
    **/
    public static void checkExtension(ContentVersion contentVersion, String allowExtensConfig) {

        //Split the allowed extensions by comma
        final List<String> allowedExtensions = allowExtensConfig.split(',');

        final Set<String> allowExtensSet = new Set<String>();
        for (String extension : allowedExtensions) {
            allowExtensSet.add(extension.trim().toLowerCase());
        }

        //Check if the file has an allowed extension
        Boolean isAllowed = false;

        for (String extension : allowExtensSet) {
            if (contentVersion.PathOnClient != null && contentVersion.PathOnClient.endsWithIgnoreCase('.' + extension)) {
                isAllowed = true;
                break;
            }
        }

        //If the file does not have an allowed extension, add an error
        if (!isAllowed) {
            contentVersion.addError(System.Label.Arc_Gen_NotAllowExtension);
        }
    }

    /**
    *---------------------------------------------------------------------------------------------------
    * @Description Verifica si el usuario actual tiene asignado alguno de los Permission Sets requeridos
    *---------------------------------------------------------------------------------------------------
    * @Author   david.montero.bellon.contractor@bbva.com
    * @Date     Created: 2025-07-07
    * @param   permisSetNames - Lista de nombres de Permission Sets a verificar
    * @return  Boolean - true si el usuario tiene al menos uno de los Permission Sets asignados
    * @example hasPermissionSet(permissSetNames)
    * --------------------------------------------------------------------------------------------------
    **/
    private static Boolean hasPermissionSet(List<String> permisSetNames) {
        Boolean hasPermissionSet = false;

        if (!permisSetNames.isEmpty()) {
            final List<PermissionSetAssignment> userAssignments = [SELECT PermissionSet.Name FROM PermissionSetAssignment WHERE AssigneeId = :UserInfo.getUserId() AND PermissionSet.Name IN :permisSetNames WITH USER_MODE LIMIT 1];
            hasPermissionSet = !userAssignments.isEmpty();
        }

        return hasPermissionSet;
    }
}