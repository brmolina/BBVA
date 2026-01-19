/**
        Autor: Alejandro del Rio
         */
@isTest
public  class NBC_Template_Email_Test {//NOSONAR

    /**
        Autor: Alejandro del Rio
         */
    @isTest
	public  static void NBC_Template_Email_Test() {//NOSONAR
        /**
        Creacion del set de datos del test
         */
         DES_UtilTestClass utils;
        utils = new DES_UtilTestClass();
        User usr;
        usr = utils.createUser(utils.createProfile());
        insert usr;
        Account acc;
        acc = utils.createGroupClient('Account Name', null, usr.id);
        upsert acc;
        NBC__c nbc;
        nbc = utils.createNBC();
        nbc.Committee_Start_Date__c = Date.today();
        upsert nbc;
        Opportunity opp;
        opp = utils.createOpportunity(acc);
        opp.Template_approved_type__c = true;
        opp.Committee_id__c = nbc.id;
        upsert opp;
        Product2 prod;
        prod = utils.createProduct('Product Name');
        upsert prod;
        PricebookEntry pbookEntry;
        pbookEntry = utils.createPricebookEntry(prod);
        upsert pbookEntry;
        OpportunityLineItem oppLine;
        oppLine = utils.createOppLineItem(opp, prod, pbookEntry);
        oppLine.opportunity_nbc_recm_date__c = Date.today();
        upsert oppLine;
        Test.startTest();
        DES_Template__c templ;
        templ = utils.createTemplate(opp, oppLine);
        templ.curncy_trans_year_one_type__c = 'EUR';
        templ.curncy_trans_year_two_type__c = 'GBP';
        templ.curncy_trans_year_three_type__c = 'AUD';
        templ.curncy_trans_year_four_type__c = 'CAD';
        templ.New_Money_for_BBVA1_desc__c = '12\n45';
        templ.YTD_RORC_per_CDD__c = 1;
        templ.Past_FY_RORC_per_CDD__c = 2;
        templ.Standalone_CDD_RaR_number__c = 1;
        templ.Standalone_CDD_RORC_number__c = 1;
        upsert templ;
        /**
        Asignacion de los datos necesrios para el test
         */
        Final EmailTemplate templates=[Select id, HtmlValue from EmailTemplate where developername like '%DES_Send_Virtual_NBC%' limit 1];
		Final list<String> addresses = new list<String>();
        addresses.add(usr.Id);

        Final List<NBC_Template_Email.FlowInputs> flowInput = new List<NBC_Template_Email.FlowInputs>();
        NBC_Template_Email.FlowInputs argument;
        argument = new NBC_Template_Email.FlowInputs();
        argument.record = nbc.Id;
        argument.body = templates.HtmlValue;
        argument.address = addresses;
        flowInput.add(argument);

        NBC_Template_Email.gettemplates(flowInput);
        system.assertNotEquals(nbc.Id, null);
         Test.stopTest();
    }
}