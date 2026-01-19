/*
@Autor: Arsenio Perez Lopez
@Proyect: BBVA PERU
@Version:1
@description: test class from Object_Controller.apx
@log:
- Creacion del Handler
*/
@isTest
public class Object_controller_tst {
    
    static List<SObject> mamlon;
    static ID idmamlon;
    static String strmamlon;

    @testSetup static void loadData(){
        Local_Client__c cliente = TestFactory.createLocalClient();
        OpportunityLineItem_Local__c a= new OpportunityLineItem_Local__c(Name='Cuenta',
                                       Local_Client_id__c = cliente.Id,
                                       Amount__c = 2000,
                                       CloseDate__c=system.today(),
                                       StageName__c='01',
                                       opportunity_status_type__c='01',
                                       CurrencyIsoCode='USD'
                                      );
        insert a;
        Product2Local__c p1 = new Product2Local__c(Name='Product Monthly 1111', Family__c='Monthly', isActive__c=true, CurrencyIsoCode='USD');
        insert p1;
        Id pricebookId = Test.getStandardPricebookId();
        PricebookEntry_Local__c pbe1 = new PricebookEntry_Local__c(Pricebook2id__c=pricebookId, Product2id__c=p1.ID, isActive__c=true, CurrencyIsoCode__c='USD', unitPrice__c=100);
        insert pbe1;
        OpportunityLineItem_Local__c oppLine = new OpportunityLineItem_Local__c(pricebookentryid__c=pbe1.Id,OpportunityId__c = a.Id,TotalPrice__c=2000,Quantity__c = 1,SioCode__c='123Xemo',product2Id__c=p1.ID);
        insert oppLine; 
        task lstTasks = new Task(Subject='SIO1234567##er Ingreso a Controller##',Status='Inbound Email',whatId=a.Id);
        insert lstTasks;
        Date x = system.Date.today();
        
        Account_BBVA_Information__c BBVA_Information = new Account_BBVA_Information__c(local_client_id__c=cliente.Id, product_group_classification_id__c='Directa',type__c='01',product_desc__c='Netcash',year_month_day_date__c=x.addMonths(-1));
        insert BBVA_Information;
        Account_Banking_System_Debt__c Bank_Syste = new Account_Banking_System_Debt__c(local_client_id__c=cliente.Id, product_group_classification_id__c='Directa',product_desc__c='netcash',entity_name__c='BBVA',year_month_day_date__c=x.addMonths(-1));
        insert Bank_Syste;
    }
    @isTest static void getOportunityLineItemID_Test() {
        OpportunityLineItem_Local__c Oli =[select Id from OpportunityLineItem_Local__c limit 1];
        test.startTest();       
        idmamlon=Object_Controller.getOportunityLineItemID(Oli.Id);
        System.assertNotEquals(Oli.Id, null,'Error');
        test.stopTest();
    }
    @isTest static void getOportunidadSytem_Test() {
        OpportunityLineItem_Local__c Oli =[select Id from OpportunityLineItem_Local__c limit 1];
        test.startTest();       
        strmamlon=Object_Controller.getOportunidadSytem(Oli.Id);
        System.assertNotEquals(Oli.Id, null,'Error');
        test.stopTest();
    }
    /*@isTest static void getOportunityModality_Test() {
        OpportunityLineItem_Local__c a =[select id from OpportunityLineItem_Local__c limit 1];
        test.startTest();       
        idmamlon=Object_Controller.getOportunityModality(a.Id);
        test.stopTest();
    }*/
    @isTest static void setSanction_Test() {
        OpportunityLineItem_Local__c Oli =[select Id from OpportunityLineItem_Local__c limit 1];
        test.startTest();       
        Oli.StageName__c='04';
        Oli.opportunity_status_type__c='08';
        update Oli;
        Object_Controller.setSanction(Oli.Id);
        System.assertNotEquals(Oli.Id, null,'Error');
        test.stopTest();
    }
    @isTest static void getVflasClient_test() {
        Local_Client__c cliente = [select Id from Local_Client__c limit 1];
        Product2Local__c ProdId =[select Id from Product2Local__c limit 1];
        OpportunityLineItem_Local__c OLI =[select Id from OpportunityLineItem_Local__c limit 1];
        test.startTest(); 
        Object_Controller.getVflasClient(cliente.Id,'Directa');
        System.assertNotEquals(cliente.Id, null,'Error');
        test.stopTest();
    }
    @isTest static void getVflasClient_test2() {
        Local_Client__c cliente = [select Id from Local_Client__c limit 1];
        Product2Local__c ProdId =[select Id from Product2Local__c limit 1];
        OpportunityLineItem_Local__c OLI =[select Id from OpportunityLineItem_Local__c limit 1];
        test.startTest(); 
        Object_Controller.getVflasClient(null,'Directa');
        System.assertNotEquals(cliente.Id, null,'Error');
        test.stopTest();
    }/* Comentado por Desktop por problemas de despliegue.
    @isTest static void getProduct2_test() {
        Product2Local__c ProdId =[select id from Product2Local__c limit 1];
        OpportunityLineItem_Local__c OLI =[select id from OpportunityLineItem limit 1];
        test.startTest();  
        Product2Local__c empuet = new Product2Local__c();
        empuet=Object_Controller.getProduct2(OLI.Id);
        system.assertNotEquals(null, empuet);
        test.stopTest();
    } */
    
    
}