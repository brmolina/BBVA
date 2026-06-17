/*-------------------------------------------------------------------------------------------
* @Name     HPGR_Users
* @Author   torcuato.tejada.tech@bbva.com
*           cosme.alcazar.tech@bbva.com
* @Date     Created: 2024-07-18
* -------------------------------------------------------------------------------------------
* @Description  Users_Itf implementation class
* -------------------------------------------------------------------------------------------
*/
@SuppressWarnings('PMD.AvoidGlobalModifier')
global with sharing class HPGR_Users implements hpgr.Users_Itf {

    static final String HPGR_ACCESS_CUSTOM_PERMISSION = 'hpgr__Access';
    static final String HPGR_ACCESSRISK_CUSTOM_PERMISSION = 'hpgr__AccessRisk';
    static final String HPGR_ADMIN_CUSTOM_PERMISSION = 'hpgr__Admin';
    static final String EXTERNAL_APP_ACCESS_CUSTOM_PERMISSION = 'DMT_Access';

    /**
    * @description check if user has access to hpgr
    * @param - : no param
    * @return boolean
    */
    public Boolean isHpgrUser() {
        return FeatureManagement.checkPermission(HPGR_ACCESS_CUSTOM_PERMISSION);
    }

    /**
    * @description check if user has external app access
    * @param - : no param
    * @return boolean
    */
    public Boolean isExternalAppUser() {
        return FeatureManagement.checkPermission(EXTERNAL_APP_ACCESS_CUSTOM_PERMISSION);
    }

    /**
    * @description check if user can manage 'Geography Visibility Configuration'
    * @param - : no param
    * @return boolean
    */
    public Boolean isAdmin() {
        return FeatureManagement.checkPermission(HPGR_ADMIN_CUSTOM_PERMISSION);
    }

    /**
    * @description check if is risk user
    * @param - : no param
    * @return boolean
    */
    public Boolean isRiskUser() {
        return FeatureManagement.checkPermission(HPGR_ACCESSRISK_CUSTOM_PERMISSION);
    }

    /**
    * @description check if user can manage 'Override Consumption'
    * @param - : no param
    * @return boolean
    */
    public Boolean canManageOverrides() {
        return FeatureManagement.checkPermission(HPGR_ACCESSRISK_CUSTOM_PERMISSION);
    }

    /**
    * @description check if user can manage 'Transactions'
    * @param - : no param
    * @return boolean
    */
    public Boolean canManageTransactions() {
        return FeatureManagement.checkPermission(HPGR_ACCESSRISK_CUSTOM_PERMISSION);
    }

    /**
    * @description check if user can download csv
    * @param - : no param
    * @return boolean
    */
    public Boolean canDownloadCsv() {
        return FeatureManagement.checkPermission(HPGR_ACCESSRISK_CUSTOM_PERMISSION);
    }

    /**
    * @description get user ISO-3 country code
    * @param - : no param
    * @return string ISO-3 country code
    */
    public String getUserCountry() {
        final Id userId = UserInfo.getUserId();
        final String userCountry = [SELECT DES_Country__c FROM User WHERE Id=:userId].DES_Country__c;
        return userCountry;
    }

    /**
    * @description check if user can reassign contracts
    * @param - : no param
    * @return boolean
    */
    public Boolean canReassignContracts() {
        return FeatureManagement.checkPermission(HPGR_ACCESSRISK_CUSTOM_PERMISSION);
    }

    /**
    * @description check if user can show capital and provision tab
    * @param - : no param
    * @return boolean
    */
    public Boolean canShowCapitalAndProvisionTab() {
        return true;
    }

    /**
    * @description check if user can show connected clients tab
    * @param - : no param
    * @return boolean
    */
    public Boolean canShowConnectedClientsTab() {
        return true;
    }

    /**
    * @description check if user can show data report tab
    * @param - : no param
    * @return boolean
    */
    public Boolean canShowDataReportTab() {
        return true;
    }

    /**
    * @description check if user can show consumption override tab
    * @param - : no param
    * @return boolean
    */
    public Boolean canShowConsumptionOverrideTab() {
        return true;
    }

    /**
    * @description check if user can show approvals tab
    * @param - : no param
    * @return boolean
    */
    public Boolean canShowApprovalsTab() {
        return true;
    }

    /**
    * @description check if user can show capital and provision summary tab
    * @param - : no param
    * @return boolean
    */
    public Boolean canShowCapitalProvisionSummaryTab() {
        return true;
    }

    /**
    * @description check if user can show risk policy summary tab
    * @param - : no param
    * @return boolean
    */
    public Boolean canShowRiskPolicySummaryTab() {
        return true;
    }

    /**
    * @description check if user can show limits summary tab
    * @param - : no param
    * @return boolean
    */
    public Boolean canShowLimitsSummaryTab() {
        return true;
    }

    /**
    * @description check if user can refresh approvals
    * @param - : no param
    * @return boolean
    */
    public Boolean canRefreshApprovals() {
        return FeatureManagement.checkPermission(HPGR_ACCESSRISK_CUSTOM_PERMISSION);
    }
}