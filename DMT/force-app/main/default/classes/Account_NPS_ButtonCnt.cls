/*
*   @author: GlobalDesktop - APC
*   @Method: verifyAccess
*   @Description: Controler of Account_NPS_Button.cmp -
                     Lightning component which will call a visualflow
                     whether the current user has permission to manage it
*/
public with sharing class Account_NPS_ButtonCnt {

    /*SINGLETON PATTERN*/
    private static Account_NPS_ButtonCnt instance;
    /*SINGLETON PATTERN*/
    public static Account_NPS_ButtonCnt getInstance() { //NOSONAR
        if (instance == null) {
            instance = new Account_NPS_ButtonCnt();
        }
        return instance;
    }
     /*
    *   Empty Constructor
    */
	private Account_NPS_ButtonCnt() {
        System.debug('Constructor empty');
	}

    /*
    *   @author: GlobalDesktop - APC
    *   @Method: verifyAccess
    *   @Description:

    *   @Inputs:    void()
    *   @Output:    String => WrapperNPSInfo Serialized:
                        - Boolean userWithAccess : specifies whether the user is member of Edit_Permissions_Desktop_ContactsGroup (PUBLIC GROUP)
                        - Account client: fields: survey_nps_contact_type__c &
    *   @Versions:
            v1 - 2019/05/29 - Initial version
    */
	@AuraEnabled
	public static String verifyAccess(Id recordId) {
        try {
            Final Id USERID = UserInfo.getUserId();
            System.debug('user: ' + USERID);
            WrapperNPSInfo npsInfo;
            npsInfo = new WrapperNPSInfo();
            Boolean isValid;
            isValid = false;

            Final List<GroupMember> lstCGMembers = [SELECT UserOrGroupId FROM GroupMember WHERE Group.DeveloperName = 'Edit_Permissions_Desktop_ContactsGroup'];

            if(! lstCGMembers.isEmpty()) {
                for(GroupMember gMember : lstCGMembers) {
                    if(gMember.UserOrGroupId == userId) {
                        isValid = true;
                        break;
                    }
                }
            }
            if(isValid) {
                npsInfo = getClientNPSInfo(recordId);
            }
            npsInfo.userWithAccess = isValid;
            // return JSON.serialize(new WrapperNPSInfo(acc, isValid));
            return JSON.serialize(npsInfo);
            // return isValid;
        } catch (Exception exc) {
            throw new AuraHandledException(Label.DES_Error + exc);
        }
    }

    /*
    *   @author: GlobalDesktop - APC
    *   @Method: getClientNPSInfo
    *   @Description:

    *   @Inputs:    Id accId
    *   @Output:    Account
    *   @Versions:
            v1 - 2019/05/31 - Initial version
    */
	private static WrapperNPSInfo getClientNPSInfo(Id accId) {
        Final WrapperNPSInfo npsInfo = new WrapperNPSInfo();
        Final List<Account> lstAcc = [SELECT id, name, survey_nps_contact_type__c, DES_Client_Type__c, RecordType.Name FROM Account WHERE id = :accId LIMIT 1];
        System.debug(':::result pre: ' + JSON.serialize(lstAcc));
        if(!lstAcc.isEmpty()) {
            npsInfo.client = lstAcc[0] == null ? null : lstAcc[0];
            if(lstAcc[0].RecordType != null) {
                npsInfo.isGroup = checkRTName(lstAcc[0].RecordType.Name);
            }
        }
        return npsInfo;
    }
    /**
    * @uthor Global Desktop
    * @description validates the recordTypeName
    * @Input RecordTypeName
    * @Output Boolean (true when rtn IN Grupo{2},Supragrupo,Subgrupo,G.Gestión Compartida)
    */
    private static Boolean checkRTName(String rtn) {
        return rtn == Label.DES_RT_NAME_COMMERCIAL_CLIENT || rtn == Label.DES_STR_TYPE_Group || rtn == Label.DES_RT_Supragroup || rtn == Label.DES_RT_Subgroup || rtn == Label.DES_STR_TYPE_Shared_Manag_Group ? true : false;
    }
    /*
    * @author GlobalDesktop - APC
    * @description: wrapper to be sent to client-side (LWC)
    * @constructor: WrapperNPSInfo (Account acc, Boolean hasAccess)
    * @returns: - Account client
    *           - Boolean userWithAccess
    */
    public class WrapperNPSInfo {
        /* Account client */
        public Account client; //NOSONAR - to be tested in test class
        /* Boolean userWithAccess (user as member of Public Group Edit_Permissions_Desktop_ContactsGroup) */
        public Boolean userWithAccess; //NOSONAR - to be tested in test class
        /* Boolean isGroup */
        public Boolean isGroup; //NOSONAR - to be tested in test class

         /* Constructor */
        public WrapperNPSInfo () {
            System.debug('Constructor empty');
        }

        /* Constructor */
        public WrapperNPSInfo (Account acc, Boolean hasAccess) {
            this.client = acc;
            this.userWithAccess = hasAccess;
        }
    }
}