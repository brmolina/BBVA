/**
*
* @author: Global Desktop
*/
@isTest
private class DynamicButtonsStatusHandlerTest {

    /* CIB Variable */
    private static final String CIB = 'CIB';

    /* Opportunity Variable */
    private static final String OPPY = 'Opportunity';

    /* Create NBC Variable */
    private static final String CRTNBC = 'Create_NBC';

    /* Add Sold Order Variable */
    private static final String ASO = 'Add_sold_order';

    /* true NBC assert Variable */
    private static final String TRUECRT = 'true create NBC';

    /*Util Test Class / Test Factory*/
    private static final DES_UtilTestClass TESTFACTORY = new DES_UtilTestClass();

    /*BOOKINGGEOGRAPHY*/
    final static set<String> BOOKINGGEOGRAPHY = new set<String>{'AR', 'NY'};

    @isTest
    static void testButtonASOInvalidProduct() {
        Test.startTest();

        

         /*Create profile*/
         final String idProfile = TESTFACTORY.createProfile();
         final User userSindication = TESTFACTORY.createUser(idProfile);         
         //userSindication.gf_user_syndicated_ind_type__c = true;
         userSindication.gf_user_syndicated_ind_type__c = true;
         userSindication.Alias = 'sindi';
         userSindication.FirstName = 'User Name Test2';
         userSindication.LastName = 'User Last Name Test2';
         userSindication.ID_User__c = '0055';
         userSindication.FederationIdentifier = userSindication.ID_User__c;
         userSindication.username = 'sindi@cation.com';
         userSindication.Email = userSindication.username;
         userSindication.CommunityNickname = userSindication.CommunityNickname+String.valueOf((integer)(Math.random()*1000));
         insert userSindication;
        
        
         

        //final User userSindication = [SELECT Id FROM User WHERE Alias = 'sindi'].get(0);
        /* Create account */
        final Account acc = TESTFACTORY.createClient();
        insert acc;

        /*Create Opportunity*/
        final List<Opportunity> opportunityList = new List<Opportunity>();

        final Opportunity opp1 = TESTFACTORY.createOpportunity(acc);
        opp1.StageName = Label.DES_Proposal;
        opp1.DES_Booking_Geography__c = 'AR';
        opportunityList.add(opp1);

        final Opportunity opp2 = TESTFACTORY.createOpportunity(acc);
        opp2.Name = 'Test Opp';
        opp2.StageName = Label.DES_Approvals;
        opp2.DES_Booking_Geography__c = 'NY';
        opportunityList.add(opp2);

        insert opportunityList;

        System.runAs(userSindication) {
         //User u = [SELECT Id FROM User WHERE Username = :userSindication.Username LIMIT 1];
        // Create a new PermissionSetAssignment
        PermissionSet ps = [SELECT Id FROM PermissionSet WHERE Name = 'OPR_Manage_Sold_Orders' LIMIT 1];
         PermissionSetAssignment psa = new PermissionSetAssignment(
            PermissionSetId = ps.Id,
            AssigneeId = userSindication.Id
         );
         System.debug('PSA es: ' + psa);
        // Insert the new PermissionSetAssignment
         Database.SaveResult sr = Database.insert(psa, false);
            if (!sr.isSuccess()) {
                for(Database.Error err : sr.getErrors()) {
                    System.debug('The following error has occurred.');
                    System.debug(err.getStatusCode() + ': ' + err.getMessage());
                    System.debug('Fields that affected this error: ' + err.getFields());
                }
            }
            
            //Invalid product
            final List<String> lstErrorMessage = ButtonsValidationMessages.getErrorMessagesList([SELECT Id FROM Opportunity WHERE DES_Booking_Geography__c IN :BOOKINGGEOGRAPHY].get(0).Id, OPPY, ASO);
            System.assert(lstErrorMessage.contains(label.Add_sold_order_error_message_invalid_product), label.Add_sold_order_error_message_invalid_product);
        }

        Test.stopTest();
    }

    @isTest
    static void testButtonASOOK() {

        final DynamicButtonsStatusHandler buttonsDynamic = new DynamicButtonsStatusHandler();
        /* Create account */
        final Account acc = TESTFACTORY.createClient();
        insert acc;

        /* Create products */
        final List<Product2> productList = createProducts();
        insert productList;

        /* Create PricebookEntry */
        final List<PricebookEntry> pbEntryList = createPBE(productList);
        insert pbEntryList;

        /*Create Opportunity*/
        final List<Opportunity> opportunityList = new List<Opportunity>();

        final Opportunity opp1 = TESTFACTORY.createOpportunity(acc);
        opp1.StageName = Label.DES_Proposal;
        opp1.DES_Booking_Geography__c = 'AR';
        opportunityList.add(opp1);

        final Opportunity opp2 = TESTFACTORY.createOpportunity(acc);
        opp2.Name = 'Test Opp';
        opp2.StageName = Label.DES_Approvals;
        opp2.DES_Booking_Geography__c = 'NY';
        opportunityList.add(opp2);

        insert opportunityList;
        
        /*Create OpportunityLineItem*/
        final List<OpportunityLineItem> opiItemList = createOLI(opportunityList, productList, pbEntryList);
        insert opiItemList;

        /*Create profile*/
        final String idProfile = TESTFACTORY.createProfile();

        Test.startTest();
        final User userSindi = TESTFACTORY.createUser(idProfile);
        userSindi.gf_user_syndicated_ind_type__c = true;
        userSindi.Alias = 'sindi';
        userSindi.FirstName = 'User Name Test2';
        userSindi.LastName = 'User Last Name Test2';
        userSindi.ID_User__c = '0055';
        userSindi.FederationIdentifier = userSindi.ID_User__c;
        userSindi.username = 'sindi@cation.com';
        userSindi.Email = userSindi.username;
		userSindi.CommunityNickname = userSindi.CommunityNickname+String.valueOf((integer)(Math.random()*1000));
        insert userSindi;
        
        /*Create DES_Opportunity_Management_member__c*/
        final List<DES_Opportunity_Management_member__c> lOpManMembers = new List<DES_Opportunity_Management_member__c>();
        
        final DES_Opportunity_Management_member__c oppManMember1 = TESTFACTORY.createOppManagementMember(userSindi, opp1);
        lOpManMembers.add(oppManMember1);
        
        final DES_Opportunity_Management_member__c oppManMember2 = TESTFACTORY.createOppManagementMember(userSindi, opp2);
        lOpManMembers.add(oppManMember2);
        
        insert lOpManMembers;

        //final User userSindication = [SELECT Id FROM User WHERE Alias = 'sindi'].get(0);

        System.runAs(userSindi) {
            PermissionSet ps = [SELECT Id FROM PermissionSet WHERE Name = 'OPR_Manage_Sold_Orders' LIMIT 1];
         	PermissionSetAssignment psa = new PermissionSetAssignment(
            PermissionSetId = ps.Id,
            AssigneeId = userSindi.Id
         );
        System.debug('PSA es: ' + psa);
        // Insert the new PermissionSetAssignment
        Database.SaveResult sr = Database.insert(psa, false);
            System.debug('registro insertado');
            if (!sr.isSuccess()) {
                for(Database.Error err : sr.getErrors()) {
                    System.debug('The following error has occurred.');
                    System.debug(err.getStatusCode() + ': ' + err.getMessage());
                    System.debug('Fields that affected this error: ' + err.getFields());
                }
            } 
        
            final Set<String> buttonsStatusSet = buttonsDynamic.getDynamicButtonStatus(opportunityList[1].Id,OPPY);
            System.debug('ESTE ES EL DEBUG -> ' + buttonsStatusSet);
            System.assert(buttonsStatusSet.contains(ASO), 'ASO');
        }

        Test.stopTest();
    }

    @isTest
    static void testButtonASOWrongStage() {

        /* Create account */
        final Account acc = TESTFACTORY.createClient();
        insert acc;

        /* Create products */
        final List<Product2> productList = createProducts();
        insert productList;

        /* Create PricebookEntry */
        final List<PricebookEntry> pbEntryList = createPBE(productList);
        insert pbEntryList;

        /*Create Opportunity*/
        final List<Opportunity> opportunityList = new List<Opportunity>();

        final Opportunity opp1 = TESTFACTORY.createOpportunity(acc);
        opp1.StageName = Label.DES_Proposal;
        opp1.DES_Booking_Geography__c = 'AR';
        opportunityList.add(opp1);

        final Opportunity opp2 = TESTFACTORY.createOpportunity(acc);
        opp2.Name = 'Test Opp';
        opp2.StageName = Label.DES_Approvals;
        opp2.DES_Booking_Geography__c = 'NY';
        opportunityList.add(opp2);

        insert opportunityList;

        /*Create OpportunityLineItem*/
        final List<OpportunityLineItem> opiItemList = createOLI(opportunityList, productList, pbEntryList);
        insert opiItemList;

        Test.startTest();
        /*Create profile*/
        final String idProfile = TESTFACTORY.createProfile();

        final User userSindi = TESTFACTORY.createUser(idProfile);
        //userSindi.gf_user_syndicated_ind_type__c = true;
        userSindi.Alias = 'sindi';
        userSindi.FirstName = 'User Name Test2';
        userSindi.LastName = 'User Last Name Test2';
        userSindi.ID_User__c = '0055';
        userSindi.FederationIdentifier = userSindi.ID_User__c;
        userSindi.username = 'sindi@cation.com';
        userSindi.Email = userSindi.username;
		userSindi.CommunityNickname = userSindi.CommunityNickname+String.valueOf((integer)(Math.random()*1000));
        insert userSindi;


        //final User userSindication = [SELECT Id FROM User WHERE Alias = 'sindi'].get(0);
        System.runAs(userSindi) {
            PermissionSet ps = [SELECT Id FROM PermissionSet WHERE Name = 'OPR_Manage_Sold_Orders' LIMIT 1];
         //User u = [SELECT Id FROM User WHERE Username = :userSindication.Username LIMIT 1];
        // Create a new PermissionSetAssignment
         PermissionSetAssignment psa = new PermissionSetAssignment(
            PermissionSetId = ps.Id,
            AssigneeId = userSindi.Id
         );
        System.debug('PSA es: ' + psa);
        // Insert the new PermissionSetAssignment
         insert psa;
            final List<Opportunity> oppList = opportunityList;
            oppList[1].StageName = Label.DES_Proposal;
            update oppList;

            final List<String> lstErrorMessage = ButtonsValidationMessages.getErrorMessagesList(oppList.get(1).Id, OPPY, ASO);
            System.debug('el error mensaje es: ' + lstErrorMessage);
            System.assert(lstErrorMessage.contains(label.Add_sold_order_error_message_wrong_stage_name), label.Add_sold_order_error_message_wrong_stage_name); //NOSONAR

        }

        Test.stopTest();
    }


    @isTest
    static void testButtonAddSoldOrderKO() {
        Test.startTest();

        /*Create profile*/
        final String idProfile = TESTFACTORY.createProfile();

        /*Create user */
        final User userTest = TESTFACTORY.createUser(idProfile);
        userTest.Alias = 'nosindi';
        insert userTest;

        //final User userNoSindication = [SELECT Id FROM user WHERE Alias = 'nosindi'].get(0);

        final User userNoSindication = userTest;

        System.runAs(userNoSindication) {

            //Invalid group
            final List<String> lstErrorMessage = ButtonsValidationMessages.getErrorMessagesList(null, OPPY, ASO);
            System.assert(lstErrorMessage.contains(label.Add_sold_order_error_message_invalid_group), label.Add_sold_order_error_message_invalid_group);
        }

        Test.stopTest();
    }


    @isTest
    static void testAmiwebError() {

        /* Create account */
        final Account acc = TESTFACTORY.createClient();
        insert acc;

        /* Create products */
        final List<Product2> productList = createProducts();
        insert productList;

        /* Create PricebookEntry */
        final List<PricebookEntry> pbEntryList = createPBE(productList);
        insert pbEntryList;

        /*Create Opportunity*/
        final List<Opportunity> opportunityList = new List<Opportunity>();

        final Opportunity opp1 = TESTFACTORY.createOpportunity(acc);
        opp1.StageName = Label.DES_Proposal;
        opp1.DES_Booking_Geography__c = 'AR';
        opportunityList.add(opp1);

        final Opportunity opp2 = TESTFACTORY.createOpportunity(acc);
        opp2.Name = 'Test Opp';
        opp2.StageName = Label.DES_Approvals;
        opp2.DES_Booking_Geography__c = 'NY';
        opportunityList.add(opp2);

        insert opportunityList;

        /*Create OpportunityLineItem*/
        final List<OpportunityLineItem> opiItemList = createOLI(opportunityList, productList, pbEntryList);
        insert opiItemList;

        Test.startTest();

        //final String oppId = [SELECT Id FROM Opportunity WHERE DES_Booking_Geography__c = 'AR'].get(0).Id;

        System.assert(ButtonsValidationMessages.getErrorMessagesList(opportunityList[0].Id, OPPY, 'Amiweb').isEmpty(), TRUECRT);

        Test.stopTest();
    }

    @isTest
    static void testTemplateWC() {

        final DynamicButtonsStatusHandler buttonsDynamic = new DynamicButtonsStatusHandler();

        /*Create profile*/
        final String idProfile = TESTFACTORY.createProfile();

        /*Create user */
        final List<User> userList = new List<User>();
        final User userTest = TESTFACTORY.createUser(idProfile);
        userTest.Alias = 'nosindi';
        userList.add(userTest);

        final User userSindication = TESTFACTORY.createUser(idProfile);
        userSindication.gf_user_syndicated_ind_type__c = true;
        userSindication.Alias = 'sindi';
        userSindication.FirstName = 'User Name Test2';
        userSindication.LastName = 'User Last Name Test2';
        userSindication.ID_User__c = '0055';
        userSindication.FederationIdentifier = userSindication.ID_User__c;
        userSindication.username = 'sindi@cation.com';
        userSindication.Email = userSindication.username;
		userSindication.CommunityNickname = userSindication.CommunityNickname+String.valueOf((integer)(Math.random()*1000));
        userList.add(userSindication);

        insert userList;

        List<Opportunity> opportunityList;
        opportunityList = new List<Opportunity>();
        Test.startTest();
        System.runAs(userTest) {

            /* Create account */
            final Account acc = TESTFACTORY.createClient();
            insert acc;

            /* Create products */
            final List<Product2> productList = createProducts();
            insert productList;

            /* Create PricebookEntry */
            final List<PricebookEntry> pbEntryList = createPBE(productList);
            insert pbEntryList;

            /*Create Opportunity*/
            final Opportunity opp1 = TESTFACTORY.createOpportunity(acc);
            opp1.StageName = Label.DES_Proposal;
            opp1.DES_Booking_Geography__c = 'AR';
            opportunityList.add(opp1);

            final Opportunity opp2 = TESTFACTORY.createOpportunity(acc);
            opp2.Name = 'Test Opp';
            opp2.StageName = Label.DES_Approvals;
            opp2.DES_Booking_Geography__c = 'NY';
            opportunityList.add(opp2);

            insert opportunityList;

            /*Create OpportunityLineItem*/
            final List<OpportunityLineItem> opiItemList = createOLI(opportunityList, productList, pbEntryList);
            insert opiItemList;

            /* Create template config */
            insert createTemplateConfig(productList);
			Test.stopTest();
            /* Create BBVA team */
            insert createBBVAMT(userTest, acc);
        }

        //final String oppId = [SELECT Id FROM Opportunity WHERE DES_Booking_Geography__c = 'AR'].get(0).Id;

        final Set<String> buttonsStatusSet = buttonsDynamic.getDynamicButtonStatus(opportunityList[0].Id, OPPY);

        ComponentNBC_Controller.getTemplateId(Label.DES_Transaction_Trade_Finance, null, 100000, 'CIB',false);
        ComponentNBC_Controller.getTemplateId(Label.DES_Leverage_Buyout_LBOs, null, 100000, 'CIB',true);

        if(ComponentNBC_Controller.instance!= null) {
            ComponentNBC_Controller.typeNBC(opportunityList[0].Id);
        }

        System.assert(buttonsStatusSet.contains(CRTNBC), TRUECRT);
    }

    @isTest
    static void testCRTNBCError() {

        /*Create profile*/
        final String idProfile = TESTFACTORY.createProfile();

        /*Create user */
        final List<User> userList = new List<User>();
        final User userTest = TESTFACTORY.createUser(idProfile);
        userTest.Alias = 'nosindi';
        userList.add(userTest);

        final User userSindication = TESTFACTORY.createUser(idProfile);
        userSindication.gf_user_syndicated_ind_type__c = true;
        userSindication.Alias = 'sindi';
        userSindication.FirstName = 'User Name Test2';
        userSindication.LastName = 'User Last Name Test2';
        userSindication.ID_User__c = '0055';
        userSindication.FederationIdentifier = userSindication.ID_User__c;
        userSindication.username = 'sindi@cation.com';
        userSindication.Email = userSindication.username;
		userSindication.CommunityNickname = userSindication.CommunityNickname+String.valueOf((integer)(Math.random()*1000));
        userList.add(userSindication);

        insert userList;

        final List<Opportunity> opportunityList;
        opportunityList = new List<Opportunity>();
        Test.startTest();
        System.runAs(userTest) {

            /* Create account */
            final Account acc = TESTFACTORY.createClient();
            insert acc;

            /* Create products */
            final List<Product2> productList = createProducts();
            insert productList;

            /* Create PricebookEntry */
            final List<PricebookEntry> pbEntryList = createPBE(productList);
            insert pbEntryList;

            /*Create Opportunity*/

            final Opportunity opp1 = TESTFACTORY.createOpportunity(acc);
            opp1.StageName = Label.DES_Proposal;
            opp1.DES_Booking_Geography__c = 'AR';
            opportunityList.add(opp1);

            final Opportunity opp2 = TESTFACTORY.createOpportunity(acc);
            opp2.Name = 'Test Opp';
            opp2.StageName = Label.DES_Approvals;
            opp2.DES_Booking_Geography__c = 'NY';
            opportunityList.add(opp2);

            insert opportunityList;

            /*Create OpportunityLineItem*/
            final List<OpportunityLineItem> opiItemList = createOLI(opportunityList, productList, pbEntryList);
            insert opiItemList;

            /* Create template config */
            insert createTemplateConfig(productList);
			Test.stopTest();
            /* Create BBVA team */
            insert createBBVAMT(userTest, acc);
        }


        //final String oppId = [SELECT Id FROM Opportunity WHERE DES_Booking_Geography__c = 'AR'].get(0).Id;
        final String oppId = opportunityList[0].Id;

        System.assert(ButtonsValidationMessages.getErrorMessagesList(oppId, OPPY, CRTNBC).isEmpty(), 'An NBC template has already been created for this opportunity');


    }

    private static List<Template_Configurations__c> createTemplateConfig (List<Product2> productList) {
        final Template_Configurations__c tmplconfig1 = new Template_Configurations__c();
        final List<Template_Configurations__c> listConfig = new List<Template_Configurations__c>();

        tmplconfig1.Product_id__c = productList[0].id;
        tmplconfig1.Template_type__c = 'PF';
        tmplconfig1.Amount_num__c = 0;
        listconfig.add(tmplconfig1);

        final Template_Configurations__c tmplconfig2 = new Template_Configurations__c();
        tmplconfig2.Product_id__c = productList[1].id;
        tmplconfig2.Template_type__c = 'CSL';
        tmplconfig2.Amount_num__c = 25000000;
        tmplconfig2.Booking_type__c = 'LATAM';
        listconfig.add(tmplconfig2);

        final Template_Configurations__c tmplconfig3 = new Template_Configurations__c();
        tmplconfig3.Product_id__c = productList[2].id;
        tmplconfig3.Template_type__c = 'CSL';
        tmplconfig3.Amount_num__c = 0;
        listconfig.add(tmplconfig3);

        final Template_Configurations__c tmplconfig4 = new Template_Configurations__c();
        tmplconfig4.Product_id__c = productList[3].id;
        tmplconfig4.Template_type__c = 'GTB';
        tmplconfig4.Amount_num__c = 25000000;
        tmplconfig4.Booking_type__c = 'NY';
        listconfig.add(tmplconfig4);

        return listConfig;
    }

    private static List<Product2> createProducts() {
        final List<Product2> productList = new List<Product2>();

        final Product2 product1 = TESTFACTORY.createProduct(Label.DES_Project_Finance_Lending);
        product1.ProductCode = 'codePFL';
        productList.add(product1);

        final Product2 product2 = TESTFACTORY.createProduct(LABEL.DES_Corporate_Loans);
        product2.ProductCode = 'codeCL';
        productList.add(product2);

        final Product2 product3 = TESTFACTORY.createProduct(LABEL.DES_Leverage_Buyout_LBOs);
        product3.ProductCode = 'codeLBOs';
        productList.add(product3);

        final Product2 product4 = TESTFACTORY.createProduct(LABEL.DES_Working_Capital);
        product4.ProductCode = 'codeWC';
        productList.add(product4);

        return productList;
    }

    private static List<PricebookEntry> createPBE(List<Product2> productList) {
        final List<PricebookEntry> pbEntryList = new List<PricebookEntry>();

        final PricebookEntry pbEntryTest = TESTFACTORY.createPricebookEntry(productList[0]);
        pbEntryList.add(pbEntryTest);

        final PricebookEntry pbEntryTest2 = TESTFACTORY.createPricebookEntry(productList[1]);
        pbEntryList.add(pbEntryTest2);

        final PricebookEntry pbEntryTest3 = TESTFACTORY.createPricebookEntry(productList[2]);
        pbEntryList.add(pbEntryTest3);

        final PricebookEntry pbEntryTest4 = TESTFACTORY.createPricebookEntry(productList[3]);
        pbEntryList.add(pbEntryTest4);

        return pbEntryList;
    }

    private static List<OpportunityLineItem> createOLI(List<Opportunity> opportunityList, List<Product2> productList, List<PricebookEntry> pbEntryList) {
        final list<OpportunityLineItem> opiItemList = new list<OpportunityLineItem>();
        OpportunityLineItem oppLI = TESTFACTORY.createOppLineItem(opportunityList[0], productList[0], pbEntryList[0]);
        oppLI.product_scope_type__c = CIB;
        opiItemList.add(oppLI);

        oppLI = TESTFACTORY.createOppLineItem(opportunityList[1], productList[0], pbEntryList[0]);
        oppLI.product_scope_type__c = CIB;
        oppLI.underwriting_agreement_type__c = 'Yes';
        opiItemList.add(oppLI);

        oppLI = TESTFACTORY.createOppLineItem(opportunityList[0], productList[3], pbEntryList[3]);
        oppLI.product_scope_type__c = CIB;
        oppLI.DES_Amount__c = 25000000;
        opiItemList.add(oppLI);

        oppLI = TESTFACTORY.createOppLineItem(opportunityList[0], productList[1], pbEntryList[1]);
        oppLI.product_scope_type__c = CIB;
        oppLI.bbva_prtcp_tranche_amount__c = 100000000;
        opiItemList.add(oppLI);

        oppLI = TESTFACTORY.createOppLineItem(opportunityList[0], productList[2], pbEntryList[2]);
        oppLI.product_scope_type__c = CIB;
        opiItemList.add(oppLI);

        return opiItemList;
    }

    private static List<DES_BBVA_Management_team__c> createBBVAMT(User userTest, Account acc) {
        final List<DES_BBVA_Management_team__c> listaBBVAMT = new List<DES_BBVA_Management_team__c>();

        final DES_BBVA_Management_team__c bbvaMT = TESTFACTORY.createBBVAManagementTeamMember(userTest, acc);
        listaBBVAMT.add(bbvaMT);
        final DES_BBVA_Management_team__c bbvaMT2 = TESTFACTORY.createBBVAManagementTeamMember(userTest, acc);
        listaBBVAMT.add(bbvaMT2);
        final DES_BBVA_Management_team__c bbvaMT3 = TESTFACTORY.createBBVAManagementTeamMember(userTest, acc);
        listaBBVAMT.add(bbvaMT3);

        return listaBBVAMT;
    }
}