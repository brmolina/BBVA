/*-------------------------------------------------------------------------
 * Name: Product_cls
 * Description : Class to insert a record from Account
 * Created date : May 15 2018
 * Developer name: Isaías Velázquez Cortés Indra(México)
 * Last Modified by : Eduardo Castillo Sunahata Indra(Perú)
 * Last Modified date: Oct 01 2018
--------------------------------------------------------------------------*/

@isTest
public class Product_cls_test {
	static List<Profile> p; 
    static List<UserRole> userRole;
    static Map<String, Profile> perfilMapa = new Map<String, Profile>();    
	static{
        p = new List<Profile>([SELECT Id, Name FROM Profile]);
        userRole = new List<UserRole>([SELECT Id, Name FROM UserRole]);
        for(Profile perfil:p){ perfilMapa.put(perfil.Name, perfil); }
    }
    
	@isTest 
	static void Product_Gurantee_test() {
        DES_UtilTestClass testClass = new DES_UtilTestClass();
        String idProfile = testClass.createProfile();
        User u = testClass.createUser(idProfile);
		insert u;

		test.startTest();
        System.runAs(u){ 

	Local_Client__c MyAcc = TestFactory.createLocalClient();
            String idcuenta = MyAcc.Id; 

            List<Account_BBVA_Information__c> listaABI = new  List<Account_BBVA_Information__c>();
            Account_BBVA_Information__c accbbvai= null;
            for(integer i=0;i<3;i++){
                accbbvai= new Account_BBVA_Information__c();
                accbbvai.year_month_day_date__c = date.newInstance(2018, 09, 06); 
                accbbvai.average_balance_amount__c = 1560.0;	
                if(i==0){
                	accbbvai.type__c = '01';
                    accbbvai.product_group_classification_id__c = 'DIRECTA';	
                	accbbvai.product_desc__c = 'RIESGO DIRECTO';
                } else if (i==1) {
                	accbbvai.type__c = '01';
                    accbbvai.product_group_classification_id__c = 'INDIRECTA';	
                	accbbvai.product_desc__c = 'RIESGO INDIRECTO';    
                } else if (i==2) {
                    accbbvai.type__c = '02';
                    accbbvai.product_group_classification_id__c = 'RECURSOS GESTIONADOS';	
                	accbbvai.product_desc__c = 'RECURSOS CAPTADOS';    
                } 
                accbbvai.current_balance_var_year_amount__c = 27.0;	
                accbbvai.current_balance_var_quart_amount__c = 27.0;	
                accbbvai.current_balance_var_month_amount__c = 27.0;	
                accbbvai.current_balance_var_day_amount__c = 0.0;	
                accbbvai.current_balance_var_day_amount__c = 849.9;	
                accbbvai.Local_Client_id__c = idcuenta;
                listaABI.add(accbbvai);
            }
            insert listaABI; 
            
            //Crear OpportunityLineItem_Local__c con Producto - 1 ECS
			OpportunityLineItem_Local__c testOP= new OpportunityLineItem_Local__c();
			testOP.Name='TESTOP';
        	testOP.StageName__c='02';
            testOp.Local_Client_id__c=MyAcc.Id;
        	testOP.CloseDate__c=Date.today();
        	testOP.Amount__c = 10000;
            testOP.CurrencyIsoCode='PEN';
			insert testOP;
        
			Product2Local__c testPr = new Product2Local__c();
			testPr.Name='TestProd';	
            testPr.Type_of_quote__c='COTIZA Beta';
			insert testPr;
        
        	Pricebook2 testPB = new Pricebook2();
        	testPB.Name='MyPrice';
        	//testPB.IsStandard=true;
        	insert testPB;
	        Id pricebookId = Test.getStandardPricebookId();

        	PricebookEntry_Local__c testPE = new PricebookEntry_Local__c();
        	testPE.unitPrice__c=120;
        	testPE.CurrencyIsoCode='PEN';
        	testPE.Pricebook2id__c=pricebookId;
        	testPE.Product2id__c=testPr.Id;
        	testPE.isActive__c=true;
            insert testPE;
        
			OpportunityLineItem_Local__c testLOPP = new OpportunityLineItem_Local__c();
        	testLOPP.TotalPrice__c=120;
			testLOPP.OpportunityId__c=testOP.Id;
			testLOPP.product2Id__c=testPr.Id;
        	testLOPP.pricebookentryid__c=testPE.Id;
        	testLOPP.Quantity__c=1;
            testLOPP.CurrencyIsoCode='PEN';
        	testLOPP.gipr_Tipo_Garantia__c='03';
			insert testLOPP;
            //Crear Oportunidad con Producto - 1 Fin
            
			Commit_Inter_Garant__c testPG = new Commit_Inter_Garant__c();
            testPG.GBL_Opportunity_product__c=testOP.Id;        	
			insert testPG;

			Commit_Inter_Garant__c testPP = new Commit_Inter_Garant__c();
            testPP.GBL_Opportunity_product__c=testOP.Id;
			insert testPP;

			Product_cls.getIdProductByOpportunity(testOP.Id);
			
			Product_cls.getGuaranteeDataByProduct(testOP.Id,testPr.Id);

			Product_cls.getParticipantDataByProduct(testOP.Id,testPr.Id);

        	testLOPP.gipr_Tipo_Garantia__c='02';
        	update testLOPP;
     		System.assert(true,'This Works!');
		test.stopTest();
        }
	}
    
    @isTest 
	static void Product_Gurantee_test_fails() {
        DES_UtilTestClass testClass = new DES_UtilTestClass();
        String idProfile = testClass.createProfile();
        User u = testClass.createUser(idProfile);
		insert u;

		test.startTest();
        System.runAs(u){ 

	Local_Client__c MyAcc = TestFactory.createLocalClient();
            String idcuenta = MyAcc.Id; 
               
            //Crear Oportunidad con Producto - 1
			OpportunityLineItem_Local__c testOP= new OpportunityLineItem_Local__c();
			testOP.Name='TESTOP';
        	testOP.StageName__c='02';
            testOp.Local_Client_id__c=MyAcc.Id;
        	testOP.CloseDate__c=Date.today();
        	testOP.Amount__c = 10000;
            testOP.CurrencyIsoCode='PEN';
			insert testOP;
        
			Product2Local__c testPr = new Product2Local__c();
			testPr.Name='TestProd';	
            testPr.Type_of_quote__c='COTIZADOR';
			insert testPr;
        
        	Product2Local__c testPB = new Product2Local__c();
        	testPB.Name='MyPrice';
        	//testPB.IsStandard=true;
        	insert testPB;
	        Id pricebookId = Test.getStandardPricebookId();

        	PricebookEntry_Local__c testPE = new PricebookEntry_Local__c();
        	testPE.unitPrice__c=120;
        	testPE.CurrencyIsoCode='PEN';
        	testPE.Pricebook2id__c=pricebookId;
        	testPE.Product2Id__c=testPr.Id;
        	testPE.isActive__c=true;
            insert testPE;
        
			OpportunityLineItem_Local__c testLOPP = new OpportunityLineItem_Local__c();
        	testLOPP.TotalPrice__c=120;
			testLOPP.OpportunityId__c=testOP.Id;
        	testLOPP.pricebookentryid__c=testPE.Id;
        	testLOPP.gipr_Tipo_Garantia__c='03';
            testLOPP.CurrencyIsoCode='PEN';
			insert testLOPP;
            //Crear Oportunidad con Producto - 1 Fin
            
			Commit_Inter_Garant__c testPG = new Commit_Inter_Garant__c();
            testPG.GBL_Opportunity_product__c=testOP.Id;        	
			insert testPG;

			Commit_Inter_Garant__c testPP = new Commit_Inter_Garant__c();
            testPP.GBL_Opportunity_product__c=testOP.Id;
			insert testPP;
            
            Product_cls.getIdProductByOpportunity('a00127831831831');

            testLOPP.gipr_Tipo_Garantia__c='02';
        	update testLOPP;
     		System.assert(true,'This Works!');
		test.stopTest();
        }
	}
	
}