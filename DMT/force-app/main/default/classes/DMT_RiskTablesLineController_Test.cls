@isTest
private class DMT_RiskTablesLineController_Test {

     @TestSetup
    static void setup() {
        // Se hace retrieve de la cola
        Group caseOwner = [SELECT DeveloperName, Name FROM Group WHERE DeveloperName = 'DMT_Approvers1' LIMIT 1];

        // Se crea un grupo de approver
        DMT_Approver__c approver = DMT_Test_DataFactory.generateApprover();
        approver.DMT_Group__c = caseOwner.DeveloperName;
        update approver;

        // Se crea un usuario de prueba
        Profile profileUser = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];
        User testUser = new User(
            LastName = 'testuser1',
            Username = 'testuser' + System.currentTimeMillis() + '@test.com',
            Email = 'testuser' + System.currentTimeMillis() + '@test.com',
            Alias = 'tuser',
            ProfileId = profileUser.Id,
            TimeZoneSidKey = 'Europe/Paris',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            ID_User__c = 'TestDMT_CreateTMA'
        );
        insert testUser;

        List<DMT_Approver_Member__c> approverMembersToInsert = new List<DMT_Approver_Member__c>();

        // Se crea un approver member del approver
        DMT_Approver_Member__c approverMember = new DMT_Approver_Member__c();
        approverMember.DMT_Access_Level__c = 'Edit';
        approverMember.DMT_Approver__c = approver.Id;
        approverMember.DMT_User__c = testUser.Id;
        approverMembersToInsert.add(approverMember);

        // We create another approver Member
        DMT_Approver_Member__c approverMember2 = new DMT_Approver_Member__c();
        approverMember2.DMT_Access_Level__c = 'Edit';
        approverMember2.DMT_Approver__c = approver.Id;
        approverMember2.DMT_User__c = UserInfo.getUserId();
        approverMembersToInsert.add(approverMember2);

        insert approverMembersToInsert;

        // Se crea una línea
        DMT_Test_DataFactory.generateTestTreasuryLines();
        DMT_Line__c line = [SELECT Id FROM DMT_Line__c WHERE Line_Id__c = '00002' LIMIT 1];

        //se crean los risk line terms
        DMT_Risk_Line_Term__c  riskLineTerm = new DMT_Risk_Line_Term__c ();
        riskLineTerm.DMT_Line__c  = line.Id;
        riskLineTerm.Name = 'riskLineTerm1';
        riskLineTerm.DMT_Amount__c = 1000;
        riskLineTerm.DMT_End_Term__c = '1095';
        riskLineTerm.DMT_Init_Term__c = '0';
        riskLineTerm.DMT_Risk_Type__c = 'Derivatives';

        insert riskLineTerm;

        DMT_Risk_Line_Term__c  riskLineTerm2 = new DMT_Risk_Line_Term__c ();
        riskLineTerm2.DMT_Line__c  = line.Id;
        riskLineTerm2.Name = 'riskLineTerm2';
        riskLineTerm2.DMT_Amount__c = 1000;
        riskLineTerm2.DMT_End_Term__c = '1095';
        riskLineTerm2.DMT_Init_Term__c = '0';
        riskLineTerm2.DMT_Risk_Type__c = 'Depos';
        

        insert riskLineTerm2;

        DMT_Risk_Line_Term__c  riskLineTerm3 = new DMT_Risk_Line_Term__c ();
        riskLineTerm3.DMT_Line__c  = line.Id;
        riskLineTerm3.Name = 'riskLineTerm3';
        riskLineTerm3.DMT_Amount__c = 1000;
        riskLineTerm3.DMT_End_Term__c = '1095';
        riskLineTerm3.DMT_Init_Term__c = '0';
        riskLineTerm3.DMT_Risk_Type__c = 'Repos';
        

        insert riskLineTerm3;

        DMT_Risk_Line_Term__c  riskLineTerm4 = new DMT_Risk_Line_Term__c ();
        riskLineTerm4.DMT_Line__c  = line.Id;
        riskLineTerm4.Name = 'riskLineTerm4';
        riskLineTerm4.DMT_Amount__c = 1000;
        riskLineTerm4.DMT_End_Term__c = '1095';
        riskLineTerm4.DMT_Init_Term__c = '0';
        riskLineTerm4.DMT_Risk_Type__c = 'Equities';
        

        insert riskLineTerm4;

        DMT_Risk_Line_Term__c  riskLineTerm5 = new DMT_Risk_Line_Term__c ();
        riskLineTerm5.DMT_Line__c  = line.Id;
        riskLineTerm5.Name = 'riskLineTerm5';
        riskLineTerm5.DMT_Amount__c = 1000;
        riskLineTerm5.DMT_End_Term__c = '1095';
        riskLineTerm5.DMT_Init_Term__c = '0';
        riskLineTerm5.DMT_Risk_Type__c = 'Singular';
     

        insert riskLineTerm5;

        // Se crea un participante para asociarlo a la línea
        DMT_TeamMember__c teamMember = new DMT_TeamMember__c();
        teamMember.User__c = UserInfo.getUserId();
        teamMember.Line__c = line.Id;
        teamMember.AccessLevel__c = 'Edit';
        teamMember.Team_Role__c = 'coverage team';
        insert teamMember;
        // Se crea el caso con la cola como owner y se asocia a la línea
        Case caseRecord = DMT_Test_DataFactory.generateCase(line.Id, null, caseOwner.Id);
    }

    @isTest
    static void getDataTest() {
        Test.startTest();
        DMT_Line__c line = [SELECT Id FROM DMT_Line__c WHERE Line_Id__c = '00002' LIMIT 1];
        DMT_RiskTablesLineController.getData(line.Id);
        Test.stopTest();
        
    }

    @isTest
    static void updateRiskLineTermAmountTest() {
        Test.startTest();
        DMT_Line__c line = [SELECT Id FROM DMT_Line__c WHERE Line_Id__c = '00002' LIMIT 1];
        DMT_Risk_Line_Term__c Derivatives = [SELECT Id FROM DMT_Risk_Line_Term__c WHERE DMT_Line__c = :line.Id and DMT_Risk_Type__c = 'Derivatives' LIMIT 1];
        DMT_RiskTablesLineController.updateRiskLineTermAmount(Derivatives.Id, 10000);
        System.assertEquals(10000, [SELECT DMT_Amount__c FROM DMT_Risk_Line_Term__c WHERE Id = :Derivatives.Id].DMT_Amount__c);
        Test.stopTest();
        
    }

    @istest
    static void saveProductsTest() {
        Test.startTest();
        DMT_Line__c line = [SELECT Id, currencyIsoCode FROM DMT_Line__c WHERE Line_Id__c = '00002' LIMIT 1];
        List<DMT_Risk_Line_Term__c> Derivatives = [SELECT Id FROM DMT_Risk_Line_Term__c WHERE DMT_Line__c = :line.Id and DMT_Risk_Type__c = 'Derivatives'];
        List<DMT_Risk_Line_Term__c> Depos = [SELECT Id FROM DMT_Risk_Line_Term__c WHERE DMT_Line__c = :line.Id and DMT_Risk_Type__c = 'Depos'];
        List<DMT_Risk_Line_Term__c> Equities = [SELECT Id FROM DMT_Risk_Line_Term__c WHERE DMT_Line__c = :line.Id and DMT_Risk_Type__c = 'Equities'];
        List<DMT_Risk_Line_Term__c> Repos = [SELECT Id FROM DMT_Risk_Line_Term__c WHERE DMT_Line__c = :line.Id and DMT_Risk_Type__c = 'Repos'];
        List<DMT_Line_Product_Item__c>  productItem = [SELECT Id FROM DMT_Line_Product_Item__c WHERE Line__c = :line.Id LIMIT 1];
        DMT_RiskTablesLineController.saveProducts(line.Id, JSON.serialize(Derivatives), JSON.serialize(Depos), JSON.serialize(Equities), JSON.serialize(Repos), JSON.serialize(productItem), '[]','[]','[]','[]',0,0,'','',false,'','','',1000000);
        Test.stopTest();
    }
}