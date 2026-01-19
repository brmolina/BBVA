@isTest
public  class DMT_OpportunityLineItemHandler_Test {
    @isTest
    static void testTrigger() {
        
        DES_UtilTestClass testClass;
        testClass = new DES_UtilTestClass();
        String idProfile;
        idProfile = testClass.createProfile();
        User userTest;
        userTest = testClass.createUser(idProfile);
        insert userTest;
        CIB_User_Org__c userSettings;
        userSettings = testClass.createCustomSetting();
        insert userSettings;
      
        system.runAs(userTest) {
            Account acc;
            acc = testClass.createClient();
            insert acc;  
            Product2 prod;
            prod = testClass.createProduct('Cash Management');
            insert prod; 
            PricebookEntry pbEntryTest;
            pbEntryTest = testClass.createPricebookEntry(prod);
            insert pbEntryTest;  
            Opportunity opp;
            opp = testClass.createOpportunity(acc);
            insert opp;               
            OpportunityLineItem oppLineItem;
            oppLineItem = testClass.createOppLineItem(opp, prod, pbEntryTest);
            insert oppLineItem;
            String oppId = String.valueOf(opp.Id);
            List<OpportunityLineItem> oppLineItemsList = new List<OpportunityLineItem>();
            oppLineItemsList.add(oppLineItem);
            DMT_OpportunityLineItemHandler.handleAfterInsertOrUpdate(oppLineItemsList);
            DMT_OpportunityLineItemHandler.recalculatePriority(oppId);
            
        }
    }
@isTest
static void testInvokeMethodRecalculatePriority() {

    // Preparación del entorno con tu utility class
    DES_UtilTestClass testClass = new DES_UtilTestClass();
    String idProfile = testClass.createProfile();
    User userTest = testClass.createUser(idProfile);
    insert userTest;

    CIB_User_Org__c userSettings = testClass.createCustomSetting();
    insert userSettings;

    system.runAs(userTest) {

        // Crear datos base
        Account acc = testClass.createClient();
        insert acc;

        Product2 prod = testClass.createProduct('Cash Management');
        insert prod;

        PricebookEntry pbEntryTest = testClass.createPricebookEntry(prod);
        insert pbEntryTest;

        Opportunity opp = testClass.createOpportunity(acc);
        insert opp;

        OpportunityLineItem oli = testClass.createOppLineItem(opp, prod, pbEntryTest);
        oli.gf_initial_date__c = Date.newInstance(2025, 11, 20);
        oli.gf_maturity_date__c = Date.newInstance(2026, 11, 20);
        insert oli;

        // Mapas para simular args del método call()
        Map<String, Object> input = new Map<String, Object>();
        input.put('oppId', opp.Id);

        Map<String, Object> output = new Map<String, Object>();
        Map<String, Object> options = new Map<String, Object>();

        Map<String, Object> args = new Map<String, Object>{
            'input' => input,
            'output' => output,
            'options' => options
        };

        // Llamada al método público call(), que internamente llama a invokeMethod()
        DMT_OpportunityLineItemHandler handler = new DMT_OpportunityLineItemHandler();
        handler.call('recalculatePriority', args);

    }
}

}