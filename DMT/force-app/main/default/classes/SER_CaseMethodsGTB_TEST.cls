/*---------------------------------------------------------------------------------------------
    Company:       BBVA
    Description:   Class to test SER_CaseMethodsGTB.

    History:
    <Date>          <Author>                <Description>
    27/03/2019      Javier Touchard         Initial Version.
----------------------------------------------------------------------------------------------*/
@isTest
private class SER_CaseMethodsGTB_TEST {
    /*Constante '3994'*/
    public static final String OFFICE3994 = '3994';
    /*Constante 'Error técnico'*/
    public static final String ERRORTECNICO = 'Error técnico';

    /*-----------------------------------------------------------------------
        Description: createCase.
    ------------------------------------------------------------------------*/
    private static Void initData() {
        User approver;
        approver = SER_TestUtils.ddCreateUser('BBVA Desktop GTB Standard',false);
        approver.ID_User__c = 'XE00007';
        insert approver;

        SER_Claim_Approver__c claimApprover;
        claimApprover = new SER_Claim_Approver__c(claim_approval_user_id__c = approver.Id,claim_aprvl_user_hier_auth_type__c = 'MO GTB',claim_approval_user_ind_type__c = true,branch_id__c = OFFICE3994);
        insert claimApprover;

        SER_Assignment_GTB_Approvers__c gtbCS;
        gtbCS = new SER_Assignment_GTB_Approvers__c();
        gtbCS.SER_Type__c = ERRORTECNICO;
        gtbCS.SER_Amount_to_be_repaid__c = 6000;
        gtbCS.SER_Amount_Operator__c = '<=';
        gtbCS.SER_Days__c = 180;
        gtbCS.SER_Days_Operator__c = '<=';
        gtbCS.SER_Delegation_Level__c = 'MO GTB';
        gtbCS.Name = 'MO GTB ET';
        insert gtbCS;

        Assignment_GTB_owners__c ownersCS;
        ownersCS = new Assignment_GTB_owners__c();
        ownersCS.Name = 'TEST USER';
        ownersCS.SER_ID_User__c = 'XE00007';
        ownersCS.fromEmail__c = 'Alias@accenture.com';
        insert ownersCS;
    }

    /*-----------------------------------------------------------------------
        Description: createCase.
    ------------------------------------------------------------------------*/
    private static Case createCase() {
        SER_TestUtils_3.initCustomsetting();
        Case newCase;
        newCase = new Case();
        newCase.RecordTypeId= SER_RecordTypeUtils.getRecordTypeByName('Case','SER_GTB_User');
        newCase.SER_Product__c            = 'BBVA FINET';
        newCase.Subject                   = 'test subject';
        newCase.Description               = 'TEST Description';
        newCase.Type                      = ERRORTECNICO;
        newCase.Subtype__c                = 'ACCESO';
        newCase.SER_Type_EST__c           = 'Acceso - FINET';
        newCase.SER_Subtype_STE__c        = 'Url Equivocada';
        newCase.SER_Type_GM__c            = 'Otros';
        newCase.SER_Subtype_GM__c         = 'Otros';
        newCase.SER_Classification__c     = 'Consulta';
        newCase.SuppliedEmail             = 'testemailaddress@example.com';
        newCase.SER_Business_Case_Type__c = SER_Constant.BUSINESS_GTB;
        newCase.origin                    = 'Email GTB';
        newCase.data_incidence_date__c    = Date.valueOf('2018-03-13');
        newCase.ClosedDate                = Date.valueOf('2018-03-17');
        newCase.return_euro_amount__c     = 5000;
        newCase.SER_Office__c             = OFFICE3994;
        newCase.SER_Solution__c           = 'Solution';
        newCase.SER_Close__c              = true;
        newCase.SER_EmailToCaseCode__c    = '0987654321';
        insert newCase;
        return newCase;
    }
    /*-----------------------------------------------------------------------
        Description:   Method to test SER_CaseMethodsGTB.isGTB
    ------------------------------------------------------------------------*/
    @isTest
    static void isGTBTEST() {
        List<Case> newList;
        newList = new List<Case>();
        newList.add(createCase());
        Test.startTest();
            Boolean isGTB;
            isGTB = SER_CaseMethodsGTB.isGTB(newList);
            System.assert(isGTB, 'Error');
        Test.stopTest();
    }

    /*-----------------------------------------------------------------------
        Description:   Method to test SER_CaseMethodsGTB.assigGTBApprovers
    ------------------------------------------------------------------------*/
    @isTest
    static void assigGTBApproversTEST1() {
        initData();
        List<Case> newList;
        newList = new List<Case>();
        newList.add(createCase());
        Test.startTest();
            SER_CaseMethodsGTB.assigGTBApprovers(newList);
            update newList;
        Test.stopTest();
        System.assertNotEquals(null, newList[0].SER_Authorizer_1__c, 'Error1');
    }

    /*-----------------------------------------------------------------------
        Description:   Method to test SER_CaseMethodsGTB.assigGTBApprovers
    ------------------------------------------------------------------------*/
    @isTest
    static void assigGTBApproversTEST2() {
        initData();

        SER_Assignment_GTB_Approvers__c gtbCS;
        gtbCS = new SER_Assignment_GTB_Approvers__c();
        gtbCS.SER_Type__c = ERRORTECNICO;
        gtbCS.SER_Amount_to_be_repaid__c = 15000;
        gtbCS.SER_Amount_to_be_repaid_2__c = 6001;
        gtbCS.SER_Amount_Operator__c = '*';
        gtbCS.SER_Days__c = 360;
        gtbCS.Days_2__c = 181;
        gtbCS.SER_Days_Operator__c = '*';
        gtbCS.SER_Delegation_Level__c = 'MO GTB';
        gtbCS.Name = 'MO GTB ET2';
        insert gtbCS;

        Case caso;
        caso = new Case();
        caso.SER_Close__c = false;
        caso.return_euro_amount__c = 8000;
        caso.data_incidence_date__c = Date.today().addDays(-300);
        caso.SER_Office__c = OFFICE3994;
        caso.RecordTypeId= SER_RecordTypeUtils.getRecordTypeByName('Case','SER_GTB_User');
        caso.origin = 'Email GTB';
        caso.Type = ERRORTECNICO;
        insert caso;

        Case caso2;
        caso2 = new Case();
        caso2.SER_Close__c = false;
        caso2.return_euro_amount__c = 1000000;
        caso2.data_incidence_date__c = Date.today().addDays(-600);
        caso2.SER_Office__c = OFFICE3994;
        caso2.RecordTypeId= SER_RecordTypeUtils.getRecordTypeByName('Case','SER_GTB_User');
        caso2.origin = 'Email GTB';
        caso2.Type = ERRORTECNICO;
        insert caso2;

        List<Case> newList;
        newList = new List<Case>();
        newList.add(caso);
        newList.add(caso2);
        Test.startTest();
            SER_CaseMethodsGTB.assigGTBApprovers(newList);
        Test.stopTest();
        System.assertNotEquals(null, newList[0].SER_Authorizer_1__c, 'Error2');
    }

    /*-----------------------------------------------------------------------
        Description:    Method to test SER_CaseMethodsGTB.assigGtbOwners
    ------------------------------------------------------------------------*/
    @isTest
    static void assigGtbOwnersTEST1() {
        initData();
        Case newCase;
        newCase = createCase();
        Map<Id,String> mapCaseFromEmail;
        mapCaseFromEmail = new Map<Id,String>();
        mapCaseFromEmail.put(newCase.Id, 'Aliasss@accenture.com');
        Test.startTest();
            SER_CaseMethodsGTB.assigGtbOwners(newCase,newCase,null,mapCaseFromEmail);
        Test.stopTest();
        System.assertEquals(null, newCase.OwnerId, 'Error3');
    }

    /*-----------------------------------------------------------------------
        Description:   Method to test SER_CaseMethodsGTB.assigGtbOwners
    ------------------------------------------------------------------------*/
    @isTest
    static void assigGtbOwnersTEST2() {
        initData();
        Case newCase;
        newCase = createCase();
        newCase = [Select Id,Origin,SER_EmailToCaseCode__c,Recordtype.DeveloperName FROM Case WHERE Id = :newCase.Id];
        Map<Id,String> mapCaseFromEmail;
        mapCaseFromEmail = new Map<Id,String>();
        mapCaseFromEmail.put(newCase.Id, 'alias@accenture.com');
        Test.startTest();
            SER_CaseMethodsGTB.assigGtbOwners(newCase,newCase,null,mapCaseFromEmail);
        Test.stopTest();
        System.assertEquals([select Id FROM User WHERE ID_User__c = 'XE00007'].Id, newCase.OwnerId, 'Error4');
    }
}