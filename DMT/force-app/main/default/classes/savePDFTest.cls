@isTest
private class savePDFTest {

  @isTest static void test_method_one() {
    //Datos necesarios
        DES_UtilTestClass utilTestClass = new DES_UtilTestClass();
        String profileTest = utilTestClass.createProfile();

        User userTest1 = utilTestClass.createUser(profileTest);
        //userTest1.ProfileId = [SELECT Id, Name FROM Profile WHERE Name = 'Desktop Integration' LIMIT 1].Id;
        insert userTest1;
        //CIB_User_Org__c userSettings = utilTestClass.createCustomSetting();
        //insert userSettings;
        Account acc = utilTestClass.createClient();
        insert acc;

        Opportunity opp = utilTestclass.createOpportunity(acc);
        insert opp;
        Test.startTest();
        Product2 product1 = utilTestClass.createProduct(Label.DES_Project_Finance_Lending);
        insert product1;

        PricebookEntry pbEntryTest = utilTestClass.createPricebookEntry(product1);
        insert pbEntryTest;

    OpportunityLineItem oppLineItem = utilTestClass.createOppLineItem(opp, product1, pbEntryTest);
    oppLineItem.product_scope_type__c = 'CIB';
    oppLineItem.syndicated_loan_drawn_amount__c = 5;
    oppLineItem.bbva_prtcp_tranche_amount__c = 100000000;
    insert oppLineItem;

    DES_Template__c template = utilTestClass.createTemplate(opp, oppLineItem);
    template.RecordTypeId = Schema.SObjectType.DES_Template__c.getRecordTypeInfosByName().get(Label.DES_Template_CSL).getRecordTypeId();
    template.YTD_RORC_per_CDD__c = 1;
    template.Past_FY_RORC_per_CDD__c = 2;
    template.Standalone_CDD_RaR_number__c = 1;
    template.Standalone_CDD_RORC_number__c = 1;
    insert template;

        system.runAs(userTest1) {

          /*
           *  EMPIEZO CON EL TEST DE LA CONCATENACION DEL CAMPO ANEXO
          **/
          ContentVersion cvc = new Contentversion();
      cvc.title = opp.Name + ' - ' + template.Name;
      cvc.PathOnClient ='test.pdf';
      cvc.versiondata = EncodingUtil.base64Decode('Body TEST');
      cvc.Copy_to_NBC__c = true;
      insert cvc;
      cvc.Category_Type__c = 'Client Snapshot';
      update cvc;
      List<ContentVersion> listCV = new List<ContentVersion>([SELECT Id, ContentDocumentId, Title, Description, PathOnClient, Category_Type__c  FROM ContentVersion WHERE Id = :cvc.Id]);
      cvc = listCV.get(0);
      system.debug('>>>>> cvc : ' + cvc);
      /*
       *Lo vinculo a un template
      **/
      ContentDocumentLink contDocLink = new ContentDocumentLink();
      contDocLink.LinkedEntityId = template.Id;
      contDocLink.ContentDocumentId = cvc.ContentDocumentId;
      contDocLink.ShareType = 'V';
      insert contDocLink;

      cvc.Category_Type__c = null;
      update cvc;


      //valido el template
      template.Template_approved_type__c = true;
      update template;

      PageReference pageRef = Page.templateSavePDFFile;
      Test.setCurrentPage(pageRef);
      ApexPages.currentPage().getParameters().put('id',template.id);

      ApexPages.StandardController scscsc = new ApexPages.StandardController(template);
      SavePDF  saveController = new SavePDF(scscsc);
      saveController.saveAttachement();

      System.assert(template.Template_approved_type__c,'Error');

      Test.stopTest();
    }
  }
}