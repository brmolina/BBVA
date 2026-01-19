/**
* -----------------------------------------------------------------------------------------------
* @Name           arce_ShadowBankingCtrl_Test
* @Author         santiago.vidal.contractor@bbva.com
* @Date           17-07-2025
*
* @Group          ARCE
* -----------------------------------------------------------------------------------------------
* @Description Test class for arce_ShadowBankingCtrl
* -----------------------------------------------------------------------------------------------
* @Changes
*
* -----------------------------------------------------------------------------------------------
**/
@isTest
private class arce_ShadowBankingCtrl_Test {

    /**
    * -----------------------------------------------------------------------------------------------
    * @description Setup test data.
    * -----------------------------------------------------------------------------------------------
    * @autor    santiago.vidal.contractor@bbva.com
    * @date     17-07-2025
    * -----------------------------------------------------------------------------------------------
    **/
    @TestSetup
    static void makeData(){
        List<Account> lstAcct = new List<Account>();

        Account clientSubsidiary1 = new Account();
        clientSubsidiary1.Name = 'ClientSubsidiary1Insurance';
        clientSubsidiary1.Phone = '666666666';
        clientSubsidiary1.DES_Country_Client__c = 'ES';
        clientSubsidiary1.DES_ID_Fiscal__c = '1111111'; 
        clientSubsidiary1.DES_Structure_Type__c = Label.DES_STR_TYPE_Subsidiary;
        clientSubsidiary1.DES_Activity__c = 'EAA';
        lstAcct.add(clientSubsidiary1);

        Account clientSubsidiary2 = new Account();
        clientSubsidiary2.Name = 'ClientSubsidiary2Corpo';
        clientSubsidiary2.Phone = '666666667';
        clientSubsidiary2.DES_Country_Client__c = 'ES';
        clientSubsidiary2.DES_ID_Fiscal__c = '111112';
        clientSubsidiary2.DES_Activity__c = 'LBE';
        clientSubsidiary2.DES_Structure_Type__c = Label.DES_STR_TYPE_Subsidiary;
        lstAcct.add(clientSubsidiary2);

        insert lstAcct;

        List<Local_Client__c> lstLocalClient = new List<Local_Client__c>();
        Local_Client__c lc1 = TestFactory.createLocalClient();
        Integer randomNumber1 = Integer.valueof((Math.random() * 100000));
        lc1.Alpha_code__c = 'ES' + randomNumber1;
        lc1.Cib_Client__c = clientSubsidiary1.Id;
        lc1.g_residence_country_id__c = 'ES';
        lc1.local_customer_id__c = 'XXXXXXXXXX1';
        lstLocalClient.add(lc1);

        Local_Client__c lc2 = TestFactory.createLocalClient();
        Integer randomNumber2 = Integer.valueof((Math.random() * 100000));
        lc2.Alpha_code__c = 'ES' + randomNumber2;
        lc2.Cib_Client__c = clientSubsidiary2.Id;
        lc2.g_residence_country_id__c = 'ES';
        lc2.local_customer_id__c = 'XXXXXXXXXX1';
        lstLocalClient.add(lc2);

        update lstLocalClient;

        arce_Shadow_Banking__c SB = new arce_Shadow_Banking__c(
            ClientLKP__c = clientSubsidiary2.Id,
            SB__c = true,
            Fecha_Shadow_Banking__c = Date.Today().addDays(-1),
            ComentSB__c = 'Test comentario SB',
            SCRA__c = true,
            Fecha_SCRA__c = Date.Today().addDays(-1),
            CommentSCRA__c = 'Test comentario SCRA',
            MarkScra__c = 'A+'
        );
        insert SB;
          
    }

    /**
    * -----------------------------------------------------------------------------------------------
    * @description Unitary test method for arce_ShadowBankingCtrl.arce_ShadowBankingCtrl() constructor
    * -----------------------------------------------------------------------------------------------
    * @autor    santiago.vidal.contractor@bbva.com
    * @date     17-07-2025
    * -----------------------------------------------------------------------------------------------
    **/
    @isTest
    static void testArce_ShadowBankingCtrl() {
        arce_ShadowBankingCtrl controller = new arce_ShadowBankingCtrl();
        System.assert(controller != null, 'El controlador debería haberse inicializado correctamente.');
    }

    /**
    * -----------------------------------------------------------------------------------------------
    * @description Unitary test method for arce_ShadowBankingCtrl.getInitialData() Flow Insurance
    * -----------------------------------------------------------------------------------------------
    * @autor    santiago.vidal.contractor@bbva.com
    * @date     17-07-2025
    * -----------------------------------------------------------------------------------------------
    **/
    @isTest
    static void testGetInitialDataInsurance() {
        Account client = [SELECT Id FROM Account WHERE DES_ID_Fiscal__c = '1111111'];

        Test.startTest();
        Map<String,Object> result = arce_ShadowBankingCtrl.getInitialData(client.Id);
        Test.stopTest();

        System.assertNotEquals(null, result.get('clientInfo'), 'clientInfo Should not be null');
    }

    /**
    * -----------------------------------------------------------------------------------------------
    * @description Unitary test method for arce_ShadowBankingCtrl.getInitialData() Flow Corpo 
    * -----------------------------------------------------------------------------------------------
    * @autor    santiago.vidal.contractor@bbva.com
    * @date     17-07-2025
    * -----------------------------------------------------------------------------------------------
    **/
    @isTest
    static void testGetInitialDataCorpo() {
        Account client = [SELECT Id FROM Account WHERE DES_ID_Fiscal__c = '111112'];

        Test.startTest();
        Map<String,Object> result = arce_ShadowBankingCtrl.getInitialData(client.Id);
        Test.stopTest();

        System.assertNotEquals(null, result.get('clientInfo'), 'clientInfo Should not be null');
    }

    /**
    * -----------------------------------------------------------------------------------------------
    * @description Unitary test method for arce_ShadowBankingCtrl.saveInfo() new SB insertion
    * -----------------------------------------------------------------------------------------------
    * @autor    santiago.vidal.contractor@bbva.com
    * @date     17-07-2025
    * -----------------------------------------------------------------------------------------------
    **/
    @isTest
    static void testSaveInfoSBInsert() {
        Local_Client__c localClient = [SELECT Id, local_customer_id__c, Cib_Client__c FROM Local_Client__c WHERE Cib_Client__r.DES_ID_Fiscal__c = '1111111'];

        Test.startTest();
        Map<String,Object> result = arce_ShadowBankingCtrl.saveInfo(localClient, true, false, '', 'test', 'SB', 'YES', 'YES', 'YES', 'YES', 'YES', 'YES', 'YES', 'YES', 'YES', '2');
        Test.stopTest();

        List<arce_Shadow_Banking__c> sb = [SELECT id, ClientLKP__c , SB__c, SCRA__c, ComentSB__c, Fecha_SCRA__c, Fecha_Shadow_Banking__c
                                    FROM arce_Shadow_Banking__c 
                                    WHERE ClientLKP__c  = :localClient.Cib_Client__c
                                    ];

        System.assertEquals(1, sb.size(), 'Shadow Banking record should exist');
        System.assertEquals('test', sb[0].ComentSB__c, 'SB Comment has not been inserted');
        System.assertEquals(true, sb[0].SB__c, 'SB should be true');
    }

    /**
    * -----------------------------------------------------------------------------------------------
    * @description Unitary test method for arce_ShadowBankingCtrl.saveInfo() update existing SB
    * -----------------------------------------------------------------------------------------------
    * @autor    santiago.vidal.contractor@bbva.com
    * @date     17-07-2025
    * -----------------------------------------------------------------------------------------------
    **/
    @isTest
    static void testSaveInfoSBUpdate() {
        Local_Client__c localClient = [SELECT Id, local_customer_id__c, Cib_Client__c FROM Local_Client__c WHERE Cib_Client__r.DES_ID_Fiscal__c = '111112'];
        
        Test.startTest();
        Map<String,Object> result = arce_ShadowBankingCtrl.saveInfo(localClient, false, false, '', 'Comentario actualizado SB', 'SB', 'YES', 'YES', 'YES', 'YES', 'YES', 'YES', 'YES', 'YES', 'YES', '3');
        Test.stopTest();

        List<arce_Shadow_Banking__c> sb = [SELECT id, ClientLKP__c , SB__c, SCRA__c, ComentSB__c, Fecha_SCRA__c, Fecha_Shadow_Banking__c
                                    FROM arce_Shadow_Banking__c 
                                    WHERE ClientLKP__c  = :localClient.Cib_Client__c
                                    ];

        System.assertEquals(1, sb.size(), 'Shadow Banking record should exist');
        System.assertEquals('Comentario actualizado SB', sb[0].ComentSB__c, 'SB Comment has not been updated');
        System.assertEquals(false, sb[0].SB__c, 'SB should be false');

    }

    /**
    * -----------------------------------------------------------------------------------------------
    * @description Unitary test method for arce_ShadowBankingCtrl.saveInfo() new SB insertion with SCRA data
    * -----------------------------------------------------------------------------------------------
    * @autor    santiago.vidal.contractor@bbva.com
    * @date     17-07-2025
    * -----------------------------------------------------------------------------------------------
    **/
    @isTest
    static void testSaveInfoSCRAInsert() {
        Local_Client__c localClient = [SELECT Id, local_customer_id__c, Cib_Client__c FROM Local_Client__c WHERE Cib_Client__r.DES_ID_Fiscal__c = '1111111'];

        Test.startTest();
        Map<String,Object> result = arce_ShadowBankingCtrl.saveInfo(localClient, false, true, 'A+', 'test', 'SCRA', '----', '----', '----', '----', '----', '----', '----', '----', '----', '----');
        Test.stopTest();

        List<arce_Shadow_Banking__c> sb = [SELECT id, ClientLKP__c , MarkScra__c, SB__c, SCRA__c, CommentSCRA__c, Fecha_SCRA__c, Fecha_Shadow_Banking__c
                                    FROM arce_Shadow_Banking__c 
                                    WHERE ClientLKP__c  = :localClient.Cib_Client__c
                                    ];

        System.assertEquals(1, sb.size(), 'Shadow Banking record should exist');
        System.assertEquals(sb[0].CommentSCRA__c, 'test', 'SCRA Comment has not been inserted');
        System.assertEquals(true, sb[0].SCRA__c, 'SCRA should be true');
        System.assertEquals('A+', sb[0].MarkScra__c, 'SCRA Mark should be A+');
    }

    /**
    * -----------------------------------------------------------------------------------------------
    * @description Unitary test method for arce_ShadowBankingCtrl.saveInfo() update existing SB with new SCRA data
    * -----------------------------------------------------------------------------------------------
    * @autor    santiago.vidal.contractor@bbva.com
    * @date     17-07-2025
    * -----------------------------------------------------------------------------------------------
    **/
    @isTest
    static void testSaveInfoSCRAUpdate() {
        Local_Client__c localClient = [SELECT Id, local_customer_id__c, Cib_Client__c  FROM Local_Client__c WHERE Cib_Client__r.DES_ID_Fiscal__c = '111112'];
        
        Test.startTest();
        Map<String,Object> result = arce_ShadowBankingCtrl.saveInfo(localClient, false, false, 'B', 'Comentario actualizado SCRA', 'SCRA', '----', '----', '----', '----', '----', '----', '----', '----', '----', '----');
        Test.stopTest();

        List<arce_Shadow_Banking__c> sb = [SELECT id, ClientLKP__c , MarkScra__c, SB__c, SCRA__c, Fecha_SCRA__c, Fecha_Shadow_Banking__c, CommentSCRA__c
                                    FROM arce_Shadow_Banking__c 
                                    WHERE ClientLKP__c  = :localClient.Cib_Client__c
                                    ];

        System.assertEquals(1, sb.size(), 'Shadow Banking record should exist');
        System.assertEquals('Comentario actualizado SCRA', sb[0].CommentSCRA__c, 'SCRA Comment has not been updated');
        System.assertEquals(false, sb[0].SCRA__c, 'SCRA should be false');
        System.assertEquals('B', sb[0].MarkScra__c, 'SCRA Mark should be B');
    }

    /**
    * -----------------------------------------------------------------------------------------------
    * @description Unitary test method for arce_ShadowBankingCtrl.testCheckCountryIsInList()
    * -----------------------------------------------------------------------------------------------
    * @autor    santiago.vidal.contractor@bbva.com
    * @date     17-07-2025
    * -----------------------------------------------------------------------------------------------
    **/
    @isTest
    static void testCheckCountryIsInList() {
        Map<String,Object> responseFlow1 =  arce_ShadowBankingCtrl.checkCountryIsInList('1', 'ES');
        Map<String,Object> responseFlow2 =  arce_ShadowBankingCtrl.checkCountryIsInList('2', 'ES');

        System.assertEquals(true, responseFlow1.get('countryIsInList'), 'countryIsInList for Flow 1 and Country ES should be true');
        System.assertEquals(true, responseFlow2.get('countryIsInList'), 'countryIsInList for Flow 2 and Country ES should be true');
    }

    /**
    * -----------------------------------------------------------------------------------------------
    * @description Unitary test method for arce_ShadowBankingCtrl.valueType()
    * -----------------------------------------------------------------------------------------------
    * @autor    santiago.vidal.contractor@bbva.com
    * @date     17-07-2025
    * -----------------------------------------------------------------------------------------------
    **/
    /* @isTest
    static void testValueType() {
         
        String financialAct = 'OAA'; // 1 - Financial institution
        String insuranceAct = 'EAA'; // 2 - Insurance 
        String corpoAct = 'LEB'; // 3 - CORPO
        String fundAct = 'ECC'; //4 - FUNDS
        
        
        Test.startTest();
        Map<String,Object> resultFinancial = arce_ShadowBankingCtrl.valueType(financialAct);
        Map<String,Object> resultInsurance = arce_ShadowBankingCtrl.valueType(insuranceAct);
        Map<String,Object> resultCorpo = arce_ShadowBankingCtrl.valueType(corpoAct);
        Map<String,Object> resultFund = arce_ShadowBankingCtrl.valueType(fundAct);
        Test.stopTest();

        System.assertEquals(1, resultFinancial.get('valueType'), 'ValueType for FINANCIAL should be 1');
        System.assertEquals(2, resultInsurance.get('valueType'), 'ValueType for INSURANCE should be 2');
        System.assertEquals(3, resultCorpo.get('valueType'), 'ValueType for CORPO should be 3');
        System.assertEquals(4, resultFund.get('valueType'), 'ValueType for FUNDS should be 4');
        
    } */
}