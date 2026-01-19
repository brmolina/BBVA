/************************************************************************************
*   @author: GlobalDesktop - APC
*   @Class: contactScopeManagementTest
*   @Description:  contactScopeManagement - Tests


*   @Versions:
        v1 - 2019/02/01 - Initial version
		v2 - 2019/02/10 - Changes required by business
		v3 - 2019/02/12 - Two new methods added related to the last requirements of business
***********************************************************************************/
@isTest
public class Account_NPS_ButtonCntTest {

    /* Declarando variable */
	private static DES_UtilTestClass utilTestClass = new DES_UtilTestClass();
    /* Declarando variable */
    public static final String SUBSIDIARYVALUE = 'Subsidiary';
	/* Declarando variable */
    public static final String DUMMYVALUE = 'dummy';
	/* Declarando variable */
    public static final String DUMMYEMAIL = '@dummy.es';
	/* Declarando variable */
    public static final String FINANCEVALUE = 'Finance';
    /* Declarando variable */
    public static final String CORRECTASSERT = 'Correcto';


    @testSetup
	/*
	* @author Global Desktop
	* @Description establece los registros necesarios
	*/
	public static void setupRows() {

		Final Id rtGROUP = Schema.SObjectType.Account.getRecordTypeInfosByName().get(Label.DES_STR_TYPE_Group).getRecordTypeId();
		Final Id rtFILIAL = Schema.SObjectType.Account.getRecordTypeInfosByName().get(Label.DES_RT_Subsidiary).getRecordTypeId();

        List<Account> lstAccounts;
		lstAccounts = new List<Account>();

        final Account accGroup = utilTestClass.createClient();
        	accGroup.Name = 'Grupo_A_ES';
        	accGroup.DES_BBVA_Segmentation__c = 'B';
        	accGroup.DES_Structure_Type__c = 'Group';
        	accGroup.DES_Country_Client__c = 'ES';
			accGroup.recordTypeId = rtGROUP;
    	insert accGroup;
    	final Account accMatrix = utilTestClass.createClient();
        	accMatrix.Name = 'Matriz_A_ES';
        	accMatrix.DES_BBVA_Segmentation__c = 'B';
        	accMatrix.DES_Structure_Type__c = SUBSIDIARYVALUE;
        	accMatrix.DES_Entity_Hierarchy__c = 'S';
        	accMatrix.DES_Main_Parent__c = accGroup.Id;
        	accMatrix.DES_Country_Client__c = 'ES';
			accMatrix.recordTypeId = rtFILIAL;
    	lstAccounts.add(accMatrix);

        insert lstAccounts;
    }
    /******************************************************************************************************************************************************
*   @author: GlobalDesktop - APC
*   @Class: verifyAccessOK
*   @Description:  Caso 1 - Contacto asociado a Account Grupo -> Scope = Global


*   @Versions:
        v1 - 2019/05/03 - Initial version
******************************************************************************************************************************************************/
	@isTest
	public static void verifyAccessOK() {
        Final Account_NPS_ButtonCnt accNPS = Account_NPS_ButtonCnt.getInstance();
        System.debug(accNPS);
        Final Account cliente = [SELECT Id FROM Account WHERE Name = 'Grupo_A_ES'];
        Final Group gro = [SELECT Id, DeveloperName FROM Group Where DeveloperName ='Edit_Permissions_Desktop_ContactsGroup'];

        Final Id USERID = UserInfo.getUserId();
        GroupMember grMember = new GroupMember();
        grMember.GroupId = gro.Id;
        grMember.UserOrGroupId = USERID;
        insert grMember;

		Test.startTest();
		Final String response = Account_NPS_ButtonCnt.verifyAccess(cliente.Id);
        Final Account_NPS_ButtonCnt.WrapperNPSInfo wrResponse = (Account_NPS_ButtonCnt.WrapperNPSInfo)JSON.deserialize(response, Account_NPS_ButtonCnt.WrapperNPSInfo.class);
		System.assert(wrResponse.userWithAccess, CORRECTASSERT);
    	Test.stopTest();
	}
}