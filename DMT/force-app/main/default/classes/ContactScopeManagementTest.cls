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
public class ContactScopeManagementTest {

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
	public static void setupRows() { //NOSONAR - no tiene sentido en este caso
		// Final Id rtGROUPCC = Schema.SObjectType.Account.getRecordTypeInfosByName().get(Label.DES_RT_NAME_COMMERCIAL_CLIENT).getRecordTypeId();
		Final Id rtGROUP = Schema.SObjectType.Account.getRecordTypeInfosByName().get(Label.DES_STR_TYPE_Group).getRecordTypeId();
		Final Id rtSUPRAG = Schema.SObjectType.Account.getRecordTypeInfosByName().get(Label.DES_RT_Supragroup).getRecordTypeId();
		// Final Id rtSUBG = Schema.SObjectType.Account.getRecordTypeInfosByName().get(Label.DES_RT_Subgroup).getRecordTypeId();
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
    	final Account accFilial = utilTestClass.createClient();
        	accFilial.Name = 'Filial_A_JP';
        	accFilial.DES_BBVA_Segmentation__c = 'B';
        	accFilial.DES_Structure_Type__c = SUBSIDIARYVALUE;
        	accFilial.DES_Entity_Hierarchy__c = 'N';
        	accFilial.DES_Main_Parent__c = accGroup.Id;
        	accFilial.DES_Country_Client__c = 'JP';
			accFilial.recordTypeId = rtFILIAL;
    	lstAccounts.add(accFilial);
    	final Account accGroup2 = utilTestClass.createClient();
        	accGroup2.Name = 'Grupo_B_MX';
        	accGroup2.DES_BBVA_Segmentation__c = 'C';
        	accGroup2.DES_Structure_Type__c = 'Group';
        	accGroup2.DES_Country_Client__c = 'MX';
        	accGroup2.RecordTypeID = Schema.SObjectType.Account.getRecordTypeInfosByName().get(Label.DES_RT_Group).getRecordTypeId();
			accGroup.recordTypeId = rtSUPRAG;
    	insert accGroup2;
    	final Account accMatrix2 = utilTestClass.createClient();
        	accMatrix2.Name = 'Matrix_B_FR';
        	accMatrix2.DES_BBVA_Segmentation__c = 'C';
        	accMatrix2.DES_Structure_Type__c = SUBSIDIARYVALUE;
        	accMatrix2.DES_Entity_Hierarchy__c = 'S';
        	accMatrix2.DES_Main_Parent__c = accGroup2.Id;
        	accMatrix2.DES_Country_Client__c = 'FR';
			accMatrix2.recordTypeId = rtFILIAL;
    	lstAccounts.add(accMatrix2);
    	final Account accFilial2 = utilTestClass.createClient();
        	accFilial2.Name = 'Filial_B_SL';
        	accFilial2.DES_BBVA_Segmentation__c = 'C';
        	accFilial2.DES_Structure_Type__c = SUBSIDIARYVALUE;
        	accFilial2.DES_Entity_Hierarchy__c = 'N';
        	accFilial2.DES_Main_Parent__c = accGroup2.Id;
        	accFilial2.DES_Country_Client__c = 'SL';
			accFilial2.recordTypeId = rtFILIAL;
    	lstAccounts.add(accFilial2);
    	insert lstAccounts;

    	lstAccounts.clear();

    	createAccs(lstAccounts,accMatrix,accMatrix2,accGroup,accGroup2);
    }

    /*
	* @author Global Desktop
	* @Description Method auxiliar para crear accounts
	*/
    private static void createAccs(List<Account> lstAccounts, Account accMatrix, Account accMatrix2, Account accGroup, Account accGroup2) {
    	final Account accGroupMatrix = new Account();
	    	accGroupMatrix.DES_Client_Matrix__c = accMatrix.Id;
	    	accGroupMatrix.Id = accGroup.Id;
	    lstAccounts.add(accGroupMatrix);
    	final Account accGroup2Matrix = new Account();
	    	accGroup2Matrix.DES_Client_Matrix__c = accMatrix2.Id;
	    	accGroup2Matrix.Id = accGroup2.Id;
	    lstAccounts.add(accGroup2Matrix);
	    update lstAccounts;
    }

/******************************************************************************************************************************************************
*   @author: GlobalDesktop - APC
*   @Class: scopeGroupGlobal
*   @Description:  Caso 1 - Contacto asociado a Account Grupo -> Scope = Global


*   @Versions:
        v1 - 2019/02/01 - Initial version
******************************************************************************************************************************************************/
	@isTest
	public static void scopeGroupGlobal() {
		Final ContactScopeManagement csm = ContactScopeManagement.getInstance();
		System.debug(csm);
		final Account cliente = [SELECT Id FROM Account WHERE Name = 'Grupo_A_ES'];
		final Contact con = utilTestClass.createContact(cliente);
			con.LastName = DUMMYVALUE;
			con.Email_ExternalID__c = DUMMYVALUE + DUMMYEMAIL;
			con.DES_Department__c  = FINANCEVALUE;

		Test.startTest();
		insert con;
		final List<Contact> result = [SELECT DES_Scope__c FROM Contact WHERE ID = :con.Id ];
		System.assertEquals('Global',result[0].DES_Scope__c, CORRECTASSERT);
    	Test.stopTest();
	}
/******************************************************************************************************************************************************
*   @author: GlobalDesktop - APC
*   @Class: scopeGroupGlobal
*   @Description:  Caso 2 - Contacto con valor extra de scope, asociado a Account Matrix
					con mismo país que su Global -> Scope = Global + país de matrix
*   @Versions:
        v1 - 2019/02/01 - Initial version
		v2 - 2019/02/05 - New logic: when a contact is related with Group or Matrix and it is created with any value in scope, global won´t be added
******************************************************************************************************************************************************/
	@isTest
	public static void scopeGroupGlobalWithAdditionalCountries() {
		final Account cliente = [SELECT Id, DES_Country_Client__c FROM Account WHERE Name = 'Grupo_A_ES'];
		final Contact con = utilTestClass.createContact(cliente);
			con.LastName = DUMMYVALUE;
			con.Email_ExternalID__c = DUMMYVALUE + DUMMYEMAIL;
			con.DES_Department__c  = FINANCEVALUE;
			con.DES_Scope__c = 'SL';

		Test.startTest();
		insert con;
		final List<Contact> result = [SELECT DES_Scope__c FROM Contact WHERE ID = :con.Id ];
		System.debug(result[0].DES_Scope__c);
		System.assertEquals(con.DES_Scope__c, result[0].DES_Scope__c, CORRECTASSERT); //cambio de lógica
    	Test.stopTest();
	}
/******************************************************************************************************************************************************
*   @author: GlobalDesktop - APC
*   @Class: scopeGroupGlobal
*   @Description:  Caso 3 - Contacto asociado a Account Matrix con mismo país que su Global -> Scope = Global


*   @Versions:
        v1 - 2019/02/01 - Initial version
******************************************************************************************************************************************************/
	@isTest
	public static void scopeMatrixGlobal() {
		final Account cliente = [SELECT Id, DES_Country_Client__c FROM Account WHERE Name = 'Matriz_A_ES'];
		final Contact con = utilTestClass.createContact(cliente);
			con.LastName = DUMMYVALUE;
			con.Email_ExternalID__c = DUMMYVALUE + DUMMYEMAIL;
			con.DES_Department__c  = FINANCEVALUE;

		Test.startTest();
		insert con;
		final List<Contact> result = [SELECT DES_Scope__c FROM Contact WHERE ID = :con.Id ];
		System.assertEquals('Global', result[0].DES_Scope__c, CORRECTASSERT);
    	Test.stopTest();
	}
/******************************************************************************************************************************************************
*   @author: GlobalDesktop - APC
*   @Class: scopeGroupGlobal
*   @Description:  Caso 4 - Contacto  asociado a Account Matrix con distinto país que su Global -> Scope = país de matrix


*   @Versions:
        v1 - 2019/02/01 - Initial version
******************************************************************************************************************************************************/
	@isTest
	public static void scopeMatrixCountry() {
		final Account cliente = [SELECT Id, DES_Country_Client__c FROM Account WHERE Name = 'Matrix_B_FR'];
		final Contact con = utilTestClass.createContact(cliente);
			con.LastName = DUMMYVALUE;
			con.Email_ExternalID__c = DUMMYVALUE + DUMMYEMAIL;
			con.DES_Department__c  = FINANCEVALUE;

		Test.startTest();
		insert con;
		final List<Contact> result = [SELECT DES_Scope__c FROM Contact WHERE ID = :con.Id ];
		System.assertEquals(cliente.DES_Country_Client__c, result[0].DES_Scope__c, CORRECTASSERT);
    	Test.stopTest();
	}
/******************************************************************************************************************************************************
*   @author: GlobalDesktop - APC
*   @Class: scopeGroupGlobal
*   @Description:  Caso 5 - Contacto con valor extra de scope, asociado a Account Matrix con mismo
					país que su Global -> Scope = Global + país de matrix
*   @Versions:
        v1 - 2019/02/01 - Initial version
		v2 - 2019/02/05 - New logic: when a contact is related with Group or Matrix and it is created with any value in scope, global won´t be added
******************************************************************************************************************************************************/
	@isTest
	public static void scopeMatrixGlobalWithAdditionalCountries() {
		System.debug(':::scopeMatrixGlobalWithAdditionalCountries init' );
		final Account cliente = [SELECT Id, DES_Country_Client__c FROM Account WHERE Name = 'Matriz_A_ES'];
		final Contact con = utilTestClass.createContact(cliente);
			con.LastName = DUMMYVALUE;
			con.Email_ExternalID__c = DUMMYVALUE + DUMMYEMAIL;
			con.DES_Department__c  = FINANCEVALUE;
			con.DES_Scope__c = 'SL';

		Test.startTest();
		insert con;
		final List<Contact> result = [SELECT DES_Scope__c FROM Contact WHERE ID = :con.Id ];
		System.debug(result[0].DES_Scope__c);
		System.assertEquals(con.DES_Scope__c, result[0].DES_Scope__c, CORRECTASSERT); //cambio de lógica
    	Test.stopTest();
	}
/******************************************************************************************************************************************************
*   @author: GlobalDesktop - APC
*   @Class: scopeGroupGlobal
*   @Description:  Caso 6 - Contacto asociado a Account Filial(no matriz) -> Scope = país de filial


*   @Versions:
        v1 - 2019/02/01 - Initial version
******************************************************************************************************************************************************/
	@isTest
	public static void scopeFilialCountry() {
		final Account cliente = [SELECT Id, DES_Country_Client__c FROM Account WHERE Name = 'Filial_A_JP'];
		final Contact con = utilTestClass.createContact(cliente);
			con.LastName = DUMMYVALUE;
			con.Email_ExternalID__c = DUMMYVALUE + DUMMYEMAIL;
			con.DES_Department__c  = FINANCEVALUE;

		Test.startTest();
		insert con;
		final List<Contact> result = [SELECT DES_Scope__c FROM Contact WHERE ID = :con.Id ];
		System.assertEquals(cliente.DES_Country_Client__c, result[0].DES_Scope__c, CORRECTASSERT);
    	Test.stopTest();
	}
/******************************************************************************************************************************************************
*   @author: GlobalDesktop - APC
*   @Class: scopeGroupGlobal
*   @Description:  Caso 7 - Contacto con valor extra de scope, asociado a Account Filial(no matriz) -> Scope = país de filial + valor extra


*   @Versions:
        v1 - 2019/02/01 - Initial version
******************************************************************************************************************************************************/
	@isTest
	public static void scopeFilialCountryWithAdditionalCountries() {
		final Account cliente = [SELECT Id, DES_Country_Client__c FROM Account WHERE Name = 'Filial_B_SL'];
		final Contact con = utilTestClass.createContact(cliente);
			con.LastName = DUMMYVALUE;
			con.Email_ExternalID__c = DUMMYVALUE + DUMMYEMAIL;
			con.DES_Department__c  = FINANCEVALUE;
			con.DES_Scope__c = 'ES;';

		Test.startTest();
		insert con;
		final List<Contact> result = [SELECT DES_Scope__c FROM Contact WHERE ID = :con.Id ];
		System.assertEquals(con.DES_Scope__c + cliente.DES_Country_Client__c, result[0].DES_Scope__c, CORRECTASSERT);
    	Test.stopTest();
	}
/******************************************************************************************************************************************************
*   @author: GlobalDesktop - APC
*   @Class: scopeGroupGlobal
*   @Description:  Caso 8 - a) Contacto con valor extra de scope, asociado a Account Filial(no matriz) -> Scope = país de filial + valor extra
							b) Al que se añade otra relación ACR con una filial en Japón -> Scope = scope anterior + JP


*   @Versions:
        v1 - 2019/02/01 - Initial version
******************************************************************************************************************************************************/
	@isTest
	public static void scopeExtraACRfilial() {
		final List<Account> lstAcc = [SELECT Id, DES_Country_Client__c, Name FROM Account WHERE Name = 'Filial_B_SL' OR Name = 'Filial_A_JP' ];
		final Contact con = utilTestClass.createContact(lstAcc[0]);
			con.LastName = DUMMYVALUE;
			con.Email_ExternalID__c = DUMMYVALUE + DUMMYEMAIL;
			con.DES_Department__c  = FINANCEVALUE;
			con.DES_Scope__c = 'ES';
		insert con;

		final AccountContactRelation acr = new AccountContactRelation();
			acr.AccountId = lstAcc[1].Id;
			acr.ContactId = con.Id;

		Test.startTest();
		insert acr;

		final List<Contact> result = [SELECT DES_Scope__c FROM Contact WHERE ID = :con.Id ];
		final List<String> lstScopeResult = result[0].DES_Scope__c.split(';');
		final List<String> lstExpected = new List<String>();
			lstExpected.add(con.DES_Scope__c);
			lstExpected.add('SL');
			lstExpected.add('JP');
		lstExpected.sort();
		lstScopeResult.sort();

		System.assertEquals(lstExpected, lstScopeResult, CORRECTASSERT);
    	Test.stopTest();
	}
/******************************************************************************************************************************************************
*   @author: GlobalDesktop - APC
*   @Class: scopeGroupGlobal
*   @Description:  Caso 9 - a) Contacto con valor extra de scope, asociado a Account Filial(no matriz) -> Scope = país de filial + valor extra
							b) Al que se añade otra relación ACR con una Matriz -> Scope = Scope anterior (+ Global Deprecated, ya no incorpora Global)


*   @Versions:
        v1 - 2019/02/01 - Initial version
		v2 - 2019/02/10 - Without Global (new requirement)
******************************************************************************************************************************************************/
	@isTest
	public static void scopeExtraGlobalACRfilial() {
		final List<Account> lstAcc = [SELECT Id, DES_Country_Client__c, Name FROM Account WHERE Name = 'Filial_B_SL' OR Name = 'Matriz_A_ES' ];
		final Contact con = utilTestClass.createContact(lstAcc[1]);
			con.LastName = DUMMYVALUE;
			con.Email_ExternalID__c = DUMMYVALUE + DUMMYEMAIL;
			con.DES_Department__c  = FINANCEVALUE;
			con.DES_Scope__c = 'FR';
		insert con;

		final AccountContactRelation acr = new AccountContactRelation();
			acr.AccountId = lstAcc[0].Id;
			acr.ContactId = con.Id;

		Test.startTest();
		insert acr;

		final List<Contact> result = [SELECT DES_Scope__c FROM Contact WHERE ID = :con.Id ];
		final List<String> lstScopeResult = result[0].DES_Scope__c.split(';');
		final List<String> lstExpected = new List<String>();
			lstExpected.add(con.DES_Scope__c);
			lstExpected.add('SL');
			// lstExpected.add('Global');
		lstExpected.sort();
		lstScopeResult.sort();

		System.assertEquals(lstExpected, lstScopeResult, CORRECTASSERT);
    	Test.stopTest();
	}
/******************************************************************************************************************************************************
*   @author: GlobalDesktop - APC
*   @Class: scopeGroupGlobal
*   @Description:  Caso 10 - Contacto filial al que se añade ACR Grupo -> no añadir valor a scope


*   @Versions:
        v1 - 2019/02/12 - Initial version
******************************************************************************************************************************************************/
	@isTest
	public static void scopeFilialACRGroup() {
		final List<Account> lstAcc = [SELECT Id, DES_Country_Client__c, Name FROM Account WHERE Name = 'Filial_B_SL' OR Name = 'Grupo_A_ES' ];
		System.debug(':::lst acc para extra acr: ' + lstAcc);
		final Contact con = utilTestClass.createContact(lstAcc[0]);
			con.LastName = DUMMYVALUE;
			con.Email_ExternalID__c = DUMMYVALUE + DUMMYEMAIL;
			con.DES_Department__c  = FINANCEVALUE;
			con.DES_Scope__c = 'JP';
		insert con;

		final AccountContactRelation acr = new AccountContactRelation();
			acr.AccountId = lstAcc[1].Id;
			acr.ContactId = con.Id;

		Test.startTest();
		insert acr;

		final List<Contact> result = [SELECT DES_Scope__c FROM Contact WHERE ID = :con.Id ];
		final List<String> lstScopeResult = result[0].DES_Scope__c.split(';');
		final List<String> lstExpected = new List<String>();
			lstExpected.add(con.DES_Scope__c);
			lstExpected.add('SL');
		lstExpected.sort();
		lstScopeResult.sort();

		System.assertEquals(lstExpected, lstScopeResult, CORRECTASSERT);
    	Test.stopTest();
	}
/******************************************************************************************************************************************************
*   @author: GlobalDesktop - APC
*   @Class: scopeGroupGlobal
*   @Description:  Caso 11 - Contacto filial al que se añade ACR Matriz donde pM == pG -> no añadir valor a scope


*   @Versions:
        v1 - 2019/02/12 - Initial version
******************************************************************************************************************************************************/
	@isTest
	public static void scopeFilialACRMatriz1() {
		final List<Account> lstAcc = [SELECT Id, DES_Country_Client__c, Name FROM Account WHERE Name = 'Filial_B_SL' OR Name = 'Matriz_A_ES' ];
		System.debug(':::lst acc para extra acr: ' + lstAcc);
		final Contact con = utilTestClass.createContact(lstAcc[0]);
			con.LastName = DUMMYVALUE;
			con.Email_ExternalID__c = DUMMYVALUE + DUMMYEMAIL;
			con.DES_Department__c  = FINANCEVALUE;
			con.DES_Scope__c = 'JP';
		insert con;

		final AccountContactRelation acr = new AccountContactRelation();
			acr.AccountId = lstAcc[1].Id;
			acr.ContactId = con.Id;

		Test.startTest();
		insert acr;

		final List<Contact> result = [SELECT DES_Scope__c FROM Contact WHERE ID = :con.Id ];
		final List<String> lstScopeResult = result[0].DES_Scope__c.split(';');
		final List<String> lstExpected = new List<String>();
			lstExpected.add(con.DES_Scope__c);
			lstExpected.add('SL');
		lstExpected.sort();
		lstScopeResult.sort();

		System.assertEquals(lstExpected, lstScopeResult, CORRECTASSERT);
    	Test.stopTest();
	}
/******************************************************************************************************************************************************
*   @author: GlobalDesktop - APC
*   @Class: scopeGroupGlobal
*   @Description:  Caso 12 - Contacto filial al que se añade ACR Matriz donde pM != pG ->  No añadir valor a scope


*   @Versions:
        v1 - 2019/02/12 - Initial version
******************************************************************************************************************************************************/
	@isTest
	public static void scopeFilialACRMatriz2() {
		final List<Account> lstAcc = [SELECT Id, DES_Country_Client__c, Name FROM Account WHERE Name = 'Filial_A_JP' OR Name = 'Matrix_B_FR' ];
		System.debug(':::lst acc para extra acr: ' + lstAcc);
		final Contact con = utilTestClass.createContact(lstAcc[0]);
			con.LastName = DUMMYVALUE;
			con.Email_ExternalID__c = DUMMYVALUE + DUMMYEMAIL;
			con.DES_Department__c  = FINANCEVALUE;
			con.DES_Scope__c = 'JP';
		insert con;

		final AccountContactRelation acr = new AccountContactRelation();
			acr.AccountId = lstAcc[1].Id;
			acr.ContactId = con.Id;

		Test.startTest();
		insert acr;

		final List<Contact> result = [SELECT DES_Scope__c FROM Contact WHERE ID = :con.Id ];
		final List<String> lstScopeResult = result[0].DES_Scope__c.split(';');

		System.debug(':::lstScopeResult: ' + lstScopeResult);

		System.assert(!lstScopeResult.contains('FR'), 'Correcto');
    	Test.stopTest();
	}
	/******************************************************************************************************************************************************
*   @author: GlobalDesktop - APC
*   @Class: scopeGroupGlobal
*   @Description:  Caso 13 - Contacto asociado a Account Supragrupo


*   @Versions:
        v1 - 2019/05/17 - Initial version
******************************************************************************************************************************************************/
	@isTest
	public static void scopeSupragroup() {
		final Account cliente = [SELECT Id, DES_Country_Client__c FROM Account WHERE Name = 'Grupo_B_MX'];
		final Contact con = utilTestClass.createContact(cliente);
			con.LastName = DUMMYVALUE;
			con.Email_ExternalID__c = DUMMYVALUE + DUMMYEMAIL;
			con.DES_Department__c  = FINANCEVALUE;

		Test.startTest();
		insert con;
		final List<Contact> result = [SELECT DES_Scope__c FROM Contact WHERE ID = :con.Id ];
		System.assertEquals('Global', result[0].DES_Scope__c, CORRECTASSERT);
    	Test.stopTest();
	}
	/******************************************************************************************************************************************************
*   @author: GlobalDesktop - APC
*   @Class: scopeGroupGlobal
*   @Description:  Caso 14 - editable_field_type__c validation


*   @Versions:
        v1 - 2019/05/17 - Initial version
******************************************************************************************************************************************************/
	@isTest
	public static void validateEdidModeFieldFlow() {
		final Account cliente = [SELECT Id, DES_Country_Client__c FROM Account WHERE Name = 'Grupo_B_MX'];
		final Contact con = utilTestClass.createContact(cliente);
			con.LastName = DUMMYVALUE;
			con.Email_ExternalID__c = DUMMYVALUE + DUMMYEMAIL;
			con.DES_Department__c  = FINANCEVALUE;

		Test.startTest();
		insert con;
		final List<Contact> result = [SELECT editable_field_type__c FROM Contact WHERE ID = :con.Id ];
		System.assertEquals(false, result[0].editable_field_type__c, CORRECTASSERT);
    	Test.stopTest();
	}
}