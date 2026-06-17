@isTest
private without sharing class DMT_cloneParticipantForLineFromFlow_Test {

    @TestSetup
    static void makeData(){
        // Se crea una línea
        DMT_Test_DataFactory.generateTestTreasuryLines();
        DMT_Test_DataFactory.generateUserWithoutPermissions();
        DMT_Line__c line = [SELECT Id, Client__c FROM DMT_Line__c WHERE Line_Id__c = '00002' LIMIT 1];
        User userId = [SELECT Id, Name FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];

        // Se crea un participante para asociarlo a la línea
        DMT_TeamMember__c teamMember = new DMT_TeamMember__c();
        teamMember.User__c = UserInfo.getUserId();
        teamMember.Line__c = line.Id;
        teamMember.AccessLevel__c = 'Edit';
        teamMember.DMT_ApprovalEdit__c = false;
        insert teamMember;

        // Se crea los Coverage Team del Cliente
        List<DES_BBVA_Management_team__c> lstTeamMag = new List<DES_BBVA_Management_team__c>();
        DES_BBVA_Management_team__c teamMmg1 = new DES_BBVA_Management_team__c();
        teamMmg1.DES_Local_Banker_Country__c = 'ES';
        teamMmg1.DES_Member_Role__c = Label.DES_Role_Transactional_Banker;
        teamMmg1.DES_User__c = userId.Id;
        teamMmg1.DES_Client__c = line.Client__c;
        lstTeamMag.add(teamMmg1);

       DES_BBVA_Management_team__c teamMmg2 = new DES_BBVA_Management_team__c();
        teamMmg2.DES_Local_Banker_Country__c = 'Global';
        teamMmg2.DES_Member_Role__c = Label.DES_ROLE_GLOBAL_BANKER;
        teamMmg2.DES_User__c = userId.Id;
        teamMmg2.DES_Client__c = line.Client__c;
        lstTeamMag.add(teamMmg2);

       DES_BBVA_Management_team__c teamMmg3 = new DES_BBVA_Management_team__c();
        teamMmg3.DES_Local_Banker_Country__c = 'Global';
        teamMmg3.DES_Member_Role__c = Label.DES_ROLE_GLOBAL_BANKER;
        teamMmg3.DES_User__c = userId.Id;
        teamMmg3.DES_Client__c = line.Client__c;
        lstTeamMag.add(teamMmg3);
        insert lstTeamMag;
    }

    @isTest
    static void testCloneCoverageTeamToTeamMbembers() {
        DMT_Line__c oldLine = [SELECT Id,Client__c,Client__r.DES_Group_Code__c FROM DMT_Line__c WHERE Line_Id__c = '00002' LIMIT 1];
        DMT_Line__c newLine = [SELECT Id, Client__c,Client__r.DES_Group_Code__c FROM DMT_Line__c WHERE Line_Id__c = '00001' LIMIT 1];
        // Crear la lista de entrada para el método invocable
        List<DMT_cloneParticipantForLineFromFlow.WrapperClone> inputList = new List<DMT_cloneParticipantForLineFromFlow.WrapperClone>();
        // Instanciar y poblar el wrapper con los datos de prueba
        DMT_cloneParticipantForLineFromFlow.WrapperClone wrapper = new DMT_cloneParticipantForLineFromFlow.WrapperClone();
        wrapper.accounId = newLine.Client__c;
        wrapper.localClient = '';
        wrapper.oldLineId = oldLine.Id;
        wrapper.newLineId = newLine.Id;
        wrapper.isDeleteOrUpdate = true;
        wrapper.accauntGroup = 'ES0182054986618';
        wrapper.localClientGroup = '';

        inputList.add(wrapper);

        Test.startTest();
        DMT_cloneParticipantForLineFromFlow.cloneProcess(inputList);
        Test.stopTest();
        List<DMT_TeamMember__c> clonedParticipants = [
            SELECT Id, Line__c
            FROM DMT_TeamMember__c
            WHERE Line__c = :newLine.Id
        ];


        System.assertEquals(1, clonedParticipants.size(),
            'Debería haberse creado un nuevo participante para la nueva línea.');
        System.assertEquals(newLine.Id, clonedParticipants[0].Line__c,
            'El campo "Line__c" del participante clonado debe coincidir con la de la nueva Linea.');
    }
    @isTest
    static void testCloneTeamMember() {
        DMT_Line__c oldLine = [SELECT Id,Client__c,Client__r.DES_Group_Code__c FROM DMT_Line__c WHERE Line_Id__c = '00002' LIMIT 1];
        DMT_Line__c newLine = [SELECT Id, Client__c,Client__r.DES_Group_Code__c FROM DMT_Line__c WHERE Line_Id__c = '00001' LIMIT 1];

        // Se añade un Grupo al Cliente para verificar si son del mismo grupo
        Account testAcc = DMT_Test_DataFactory.generateAccount();
        testAcc.DES_Group_Code__c = 'ES0182054986618';
        update testAcc;

        oldLine.Client__c = testAcc.Id;
        update oldLine;
        newLine.Client__c = testAcc.Id;
        update newLine;
        // Se crea un participante para asociarlo a la línea
        DMT_TeamMember__c teamMember = new DMT_TeamMember__c();
        teamMember.User__c = UserInfo.getUserId();
        teamMember.Line__c = oldLine.Id;
        teamMember.AccessLevel__c = 'Edit';
        teamMember.DMT_ApprovalEdit__c = false;
        insert teamMember;
        // Crear la lista de entrada para el método invocable
        List<DMT_cloneParticipantForLineFromFlow.WrapperClone> inputList = new List<DMT_cloneParticipantForLineFromFlow.WrapperClone>();

        // Instanciar y poblar el wrapper con los datos de prueba
        DMT_cloneParticipantForLineFromFlow.WrapperClone wrapper = new DMT_cloneParticipantForLineFromFlow.WrapperClone();
        wrapper.accounId = newLine.Client__c;
        wrapper.localClient = '';
        wrapper.oldLineId = oldLine.Id;
        wrapper.newLineId = newLine.Id;
        wrapper.isDeleteOrUpdate = true;
        wrapper.accauntGroup = 'ES0182054986618';
        wrapper.localClientGroup = '';

        inputList.add(wrapper);

        Test.startTest();
        DMT_cloneParticipantForLineFromFlow.cloneProcess(inputList);
        Test.stopTest();
        List<DMT_TeamMember__c> clonedParticipants = [
            SELECT Id, Line__c
            FROM DMT_TeamMember__c
            WHERE Line__c = :newLine.Id
        ];
        System.assertEquals(1, clonedParticipants.size(),
            'Debería haberse creado un nuevo participante para la nueva línea.');
        System.assertEquals(newLine.Id, clonedParticipants[0].Line__c,
            'El campo "Line__c" del participante clonado debe coincidir con la de la nueva Linea.');
    }
    @isTest
    static void testCloneisDeleteOrUpdateFalse() {
        DMT_Line__c oldLine = [SELECT Id,Client__c,Client__r.DES_Group_Code__c FROM DMT_Line__c WHERE Line_Id__c = '00002' LIMIT 1];
        DMT_Line__c newLine = [SELECT Id, Client__c,Client__r.DES_Group_Code__c FROM DMT_Line__c WHERE Line_Id__c = '00001' LIMIT 1];

        Account testAcc = DMT_Test_DataFactory.generateAccount();
        testAcc.DES_Group_Code__c = 'ES0182054986618';
        update testAcc;
        Local_Client__c lClient = new Local_Client__c(Cib_Client__c = testAcc.Id);
        insert lClient;
        String idLocalCLient = lClient.Id;
        DMT_cloneParticipantForLine_Selector.getLocalClient(idLocalCLient);

        oldLine.Client__c = testAcc.Id;
        update oldLine;
        newLine.Client__c = testAcc.Id;
        update newLine;
        // Se crea un participante para asociarlo a la línea
        DMT_TeamMember__c teamMember = new DMT_TeamMember__c();
        teamMember.User__c = UserInfo.getUserId();
        teamMember.Line__c = oldLine.Id;
        teamMember.AccessLevel__c = 'Edit';
        teamMember.DMT_ApprovalEdit__c = false;
        insert teamMember;
        // Crear la lista de entrada para el método invocable
        List<DMT_cloneParticipantForLineFromFlow.WrapperClone> inputList = new List<DMT_cloneParticipantForLineFromFlow.WrapperClone>();

        // Instanciar y poblar el wrapper con los datos de prueba
        DMT_cloneParticipantForLineFromFlow.WrapperClone wrapper = new DMT_cloneParticipantForLineFromFlow.WrapperClone();
        wrapper.accounId = newLine.Client__c;
        wrapper.localClient = lClient.Id;
        wrapper.oldLineId = oldLine.Id;
        wrapper.newLineId = newLine.Id;
        wrapper.isDeleteOrUpdate = false;
        wrapper.accauntGroup = 'ES0182054986618';
        wrapper.localClientGroup = '';

        inputList.add(wrapper);

        Test.startTest();
        DMT_cloneParticipantForLineFromFlow.cloneProcess(inputList);
        Test.stopTest();
        List<DMT_TeamMember__c> clonedParticipants = [
            SELECT Id, Line__c
            FROM DMT_TeamMember__c
            WHERE Line__c = :newLine.Id
        ];
        System.assertEquals(0, clonedParticipants.size(),
            'No Debería haberse creado un nuevo participante para la nueva línea.');

    }

}