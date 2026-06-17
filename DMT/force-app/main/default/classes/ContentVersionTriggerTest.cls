@isTest
public with sharing class ContentVersionTriggerTest {

    @isTest
    public static void filesTest_Insert_update_Anexx(){
        //Datos necesarios
        DES_UtilTestClass utilTestClass = new DES_UtilTestClass();
        String profileTest = utilTestClass.createProfile();
		
        User userTest1 = utilTestClass.createUser(profileTest);
        //userTest1.ProfileId = [SELECT Id, Name FROM Profile WHERE Name = 'Desktop Integration' LIMIT 1].Id;
        insert userTest1;
        CIB_Bypass__c bypassTest = new CIB_Bypass__c();
        bypassTest.ExtensionsAllowed__c = 'png|jpeg|jpg|gif|svg|pdf|docx|xlsx|pptx|doc|xls|ppt|html|json';
        insert bypassTest;
        //CIB_User_Org__c userSettings = utilTestClass.createCustomSetting();
        
        //insert userSettings;
        Account acc = utilTestClass.createClient();
        insert acc;

        Opportunity opp = utilTestclass.createOpportunity(acc);
        insert opp;

        Product2 product1 = utilTestClass.createProduct(Label.DES_Project_Finance_Lending);
        insert product1;

        PricebookEntry pbEntryTest = utilTestClass.createPricebookEntry(product1);
        insert pbEntryTest;

        OpportunityLineItem oppLineItem = utilTestClass.createOppLineItem(opp, product1, pbEntryTest);
        oppLineItem.product_scope_type__c = 'CIB';
        oppLineItem.syndicated_loan_drawn_amount__c = 5;
        oppLineItem.bbva_prtcp_tranche_amount__c = 100000000;
        insert oppLineItem;

        NBC__c nbc = utilTestClass.createNBC();
        insert nbc;
        Test.startTest();
        DES_Template__c template = utilTestClass.createTemplate(opp, oppLineItem);
        template.YTD_RORC_per_CDD__c = 1;
        template.Past_FY_RORC_per_CDD__c = 2;
        template.Standalone_CDD_RaR_number__c = 1;
        template.Standalone_CDD_RORC_number__c = 1;
        insert template;
        system.runAs(userTest1){
            /*
             *  EMPIEZO CON EL TEST DE LA CONCATENACION DEL CAMPO ANEXO
            **/
            ContentVersion cv = new Contentversion();
            cv.title = 'Title1';
            cv.PathOnClient ='test.pdf';
            Blob b = Blob.valueOf('Body TEST');
            cv.versiondata = EncodingUtil.base64Decode('Body TEST');
            cv.Copy_to_NBC__c = true;
            insert cv;
            cv.Category_Type__c = 'Client Snapshot';
            update cv;
            List<ContentVersion> listCV = new List<ContentVersion>([SELECT Id, ContentDocumentId, Title, Description, PathOnClient, Category_Type__c  FROM ContentVersion WHERE Id = :cv.Id]);
            cv = listCV.get(0);
            system.debug('>>>>> cv : ' + cv);
            /*
             *Lo vinculo a un template
            **/
            ContentDocumentLink contDocLink = new ContentDocumentLink();
            contDocLink.LinkedEntityId = template.Id;
            contDocLink.ContentDocumentId = cv.ContentDocumentId;
            contDocLink.ShareType = 'V';
            insert contDocLink;

            cv.Category_Type__c = null;
            update cv;

            //valido el template
            template.Template_approved_type__c = true;
            update template;
            //Vinculo la Opp a un NBC
            opp.Committee_id__c = nbc.Id;
            update opp;

            System.assertEquals(opp.Committee_id__c, nbc.Id);
            Test.stopTest();
        }
    }


    @isTest
    public static void filesTest_Insert_update_no_Anexx(){
        //Datos necesarios
        DES_UtilTestClass utilTestClass = new DES_UtilTestClass();
        String profileTest = utilTestClass.createProfile();

        User userTest1 = utilTestClass.createUser(profileTest);
        //userTest1.ProfileId = [SELECT Id, Name FROM Profile WHERE Name = 'Desktop Integration' LIMIT 1].Id;
        insert userTest1;
        CIB_Bypass__c bypassTest = new CIB_Bypass__c();
        bypassTest.ExtensionsAllowed__c = 'png|jpeg|jpg|gif|svg|pdf|docx|xlsx|pptx|doc|xls|ppt|html|json';
        bypassTest.SetupOwnerId = userTest1.Id;
        insert bypassTest;
        //CIB_User_Org__c userSettings = utilTestClass.createCustomSetting();
        //insert userSettings;
        Account acc = utilTestClass.createClient();
        insert acc;

        Opportunity opp = utilTestclass.createOpportunity(acc);
        insert opp;

        Product2 product1 = utilTestClass.createProduct(Label.DES_Project_Finance_Lending);
        insert product1;

        PricebookEntry pbEntryTest = utilTestClass.createPricebookEntry(product1);
        insert pbEntryTest;

        OpportunityLineItem oppLineItem = utilTestClass.createOppLineItem(opp, product1, pbEntryTest);
        oppLineItem.product_scope_type__c = 'CIB';
        oppLineItem.syndicated_loan_drawn_amount__c = 5;
        oppLineItem.bbva_prtcp_tranche_amount__c = 100000000;
        insert oppLineItem;
        Test.startTest();
        DES_Template__c template = utilTestClass.createTemplate(opp, oppLineItem);
        template.YTD_RORC_per_CDD__c = 1;
        template.Past_FY_RORC_per_CDD__c = 2;
        template.Standalone_CDD_RaR_number__c = 1;
        template.Standalone_CDD_RORC_number__c = 1;
        insert template;
        system.runAs(userTest1){
            /*
             *  EMPIEZO CON EL TEST DE LA CONCATENACION DEL CAMPO ANEXO
            **/
            ContentVersion cv = new Contentversion();
            cv.title = 'Title1';
            cv.PathOnClient ='test.pdf';
            Blob b = Blob.valueOf('Body TEST');
            cv.versiondata = EncodingUtil.base64Decode('Body TEST');
            cv.Category_Type__c = 'Client Snapshot';
            cv.Copy_to_NBC__c = true;
            insert cv;
            cv.Category_Type__c = null;
            update cv;
            List<ContentVersion> listCV = new List<ContentVersion>([SELECT Id, ContentDocumentId, Title, Description, PathOnClient, Category_Type__c  FROM ContentVersion WHERE Id = :cv.Id]);
            cv = listCV.get(0);
            system.debug('>>>>> cv : ' + cv);
            /*
             *Lo vinculo a un template
            **/
            ContentDocumentLink contDocLink = new ContentDocumentLink();
            contDocLink.LinkedEntityId = template.Id;
            contDocLink.ContentDocumentId = cv.ContentDocumentId;
            contDocLink.ShareType = 'V';
            insert contDocLink;

            cv.Category_Type__c = null;
            update cv;


            System.assertEquals(cv.Category_Type__c, null);
            Test.stopTest();
        }
    }

}