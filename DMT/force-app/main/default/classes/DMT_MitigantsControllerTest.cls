@IsTest
private class DMT_MitigantsControllerTest {

    @IsTest
    static void testGetCurrencyValues() {
        // Crear datos de prueba
        List<DMT_Taxonomy_Values__c> taxonomyValues = new List<DMT_Taxonomy_Values__c>{
            new DMT_Taxonomy_Values__c(
                DMT_Catalog__c = 'C264',
                DMT_Value__c = 'USD',
                DMT_Active__c = true
            ),
            new DMT_Taxonomy_Values__c(
                DMT_Catalog__c = 'C264',
                DMT_Value__c = 'EUR',
                DMT_Active__c = true
            ),
            new DMT_Taxonomy_Values__c(
                DMT_Catalog__c = 'C265', // distinto catálogo, no debe aparecer
                DMT_Value__c = 'GBP',
                DMT_Active__c = true
            ),
            new DMT_Taxonomy_Values__c(
                DMT_Catalog__c = 'C264',
                DMT_Value__c = 'JPY',
                DMT_Active__c = false // inactivo, no debe aparecer
            )
        };
        insert taxonomyValues;

        Test.startTest();
        List<String> result = DMT_MitigantsController.getCurrencyValues();
        Test.stopTest();

        // Validaciones
        System.assert(result.contains('USD'), 'Debe incluir USD');
    }
}