/**
* ____________________________________________________________________________
* Toolkit Permissions
* CIB implementation of the interface Permissions_Itf
* ____________________________________________________________________________
* @author      Torcuato Tejada <torcuato.tejada.contractor@bbva.com>
* @modifiedBy
* @version     1.0
* @created     2021-05-23
* @modified
* @systemLayer Sample
* ____________________________________________________________________________
* @changes
*
* ____________________________________________________________________________
*/
@SuppressWarnings('PMD.AvoidGlobalModifier, PMD.ExcessiveParameterList')
global with sharing class CSTK_Permission implements cstk.Permissions_Itf {

    /**
    * @description Returns user permissions to manage a toolkit record
    * @param toolkitId : Id of the Toolkit
    * @param userId : Id of the User
    * @return Map<String, Boolean> map with the actions and permissions
    */
    global Map<String, Object> canManageToolkit(Id toolkitId, Id userId, String year, String toolkitYear) {
        String yearforToolkit  = toolkitYear; //NOSONAR
        final Map<String, Object> res = new Map<String, Object>();
        Boolean isToolkitEditUser;
        final Integer editYear = Integer.valueOf(year);
        if (String.isEmpty(toolkitYear)) { //NOSONAR
            yearforToolkit = [SELECT cstk__year__c from cstk__Toolkit__c WHERE Id = :toolkitId][0].cstk__year__c; //NOSONAR
        }
        final Integer editToolkitYear = Integer.valueOf(yearforToolkit);
        final Integer currentYear = System.now().year();
        final Boolean yearEditable =  ((editToolkitYear + 1) == editYear || editYear == (editToolkitYear - 1) || (editToolkitYear + 2) == editYear || editYear == (editToolkitYear - 2) ||  editYear == editToolkitYear);
        isToolkitEditUser = isToolkitEditUser(userId);

        //Allow all GCC Users
        if (!isToolkitEditUser) {
            isToolkitEditUser = isGCC();
        }

        res.put('add', isToolkitEditUser && yearEditable);
        res.put('edit', isToolkitEditUser && yearEditable);
        res.put('delete', isToolkitEditUser && yearEditable);
        res.put('manage', isToolkitEditUser);
        res.put('managetri', isToolkitEditUser);

        System.debug('cstk_Permission environmental sales is createable ' + Schema.sObjectType.cstk__Environmental_sales__c.isCreateable());
        System.debug('cstk_Permission environmental sales is accesible ' + Schema.sObjectType.cstk__Environmental_sales__c.isAccessible());
		System.debug('environmental sales is Updateable ' + Schema.sObjectType.cstk__Environmental_sales__c.isUpdateable());

        Boolean hasPurePlayerEdit = FeatureManagement.checkPermission('PurePlayerEdition');
        System.debug('PurePlayerEdition ' + hasPurePlayerEdit);
        res.put('editPP', isToolkitEditUser && hasPurePlayerEdit);

        Boolean hasESFramworkEdit = FeatureManagement.checkPermission('ESFrameworkEdition');
        System.debug('ESFrameworkEdition ' + hasESFramworkEdit);
        res.put('editESFrmwrk', isToolkitEditUser && yearEditable && hasESFramworkEdit);

        Boolean hasEnggmntPermission = FeatureManagement.checkPermission('EnggmntPlanPermission');
        System.debug('EnggmntPlanPermission ' + hasEnggmntPermission);
        res.put('editEnggmntPlan', isToolkitEditUser && yearEditable && hasEnggmntPermission);
        res.put('PDFEnggmntPlan',  isToolkitEditUser && hasEnggmntPermission);

        Boolean hasPermission = FeatureManagement.checkPermission('PurePlayerValidation');
        System.debug('PurePlayerValidation ' + hasPermission);
        res.put('validPP', hasPermission);

        Boolean hasPermissionTri = FeatureManagement.checkPermission('TriValidationRecalcu');
        System.debug('TriValidationRecalcu ' + hasPermissionTri);
        //res.put('managetri', hasPermissionTri);

        return res;
    }

    /**
    * @description Returns user permissions to manage a toolkit record
    * @param toolkitId : Id of the Toolkit
    * @param userId : Id of the User
    * @return Map<String, Boolean> map with the actions and permissions
    */
    global Map<String, Object> canManageToolkit(Id toolkitId, Id userId) {

        final Map<String, Object> res = new Map<String, Object>();
        Boolean isToolkitEditUser = isToolkitEditUser(userId);

        //Allow all GCC Users
        if (!isToolkitEditUser) {
            isToolkitEditUser = isGCC();
        }

        res.put('add', isToolkitEditUser);
        res.put('edit', isToolkitEditUser);
        res.put('delete', isToolkitEditUser);
        res.put('manage', isToolkitEditUser);
        res.put('managetri', isToolkitEditUser);

        Boolean hasPurePlayerEdit = FeatureManagement.checkPermission('PurePlayerEdition');
        System.debug('PurePlayerEdition ' + hasPurePlayerEdit);
        res.put('editPP', isToolkitEditUser && hasPurePlayerEdit);

        Boolean hasPermission = FeatureManagement.checkPermission('PurePlayerValidation');
        System.debug('PurePlayerValidation ' + hasPermission);
        res.put('validPP', hasPermission);

        Boolean hasPermissionTri = FeatureManagement.checkPermission('TriValidationRecalcu');
        System.debug('TriValidationRecalcu ' + hasPermissionTri);
        //res.put('managetri', hasPermissionTri);

        res.put('editThldPP', hasPermission);

        return res;
    }


    public Boolean isToolkitEditUser(Id userId) {
        final List<User> res = [SELECT cstk_toolkit_manage__c, DES_ARCE_Can_Edit__c FROM User WHERE Id =:userId LIMIT 1];
        final Boolean canManageToolkit = FeatureManagement.checkPermission('cstk_toolkit_manage');
        return(canManageToolkit || res[0].cstk_toolkit_manage__c || res[0].DES_ARCE_Can_Edit__c);
    }

    public Boolean isGCC() {
        Boolean res;
        final Id profileId = UserInfo.getProfileId();
        final String profileName = [SELECT Name FROM Profile WHERE Id =: profileId].Name;

        switch on profileName {
            when 'BBVA Desktop GCC Standard', 'BBVA Desktop GCC Business Development' {
                res = true;
            }
            when else {
                res = false;
            }
        }
        return res;
    }
}