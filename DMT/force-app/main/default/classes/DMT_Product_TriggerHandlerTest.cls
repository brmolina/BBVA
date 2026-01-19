@isTest
public class DMT_Product_TriggerHandlerTest {
 
    @testSetup
    static void setupData() {
        DMT_Test_DataFactory.generatePricebook2();
    }

    @isTest
    static void testBeforeInsertAndAfterInsert_ValidTaxonomy() {
                Pricebook2 customPB = new Pricebook2(
            Name = 'Test Pricebook',
            IsActive = true
        );
        insert customPB;

        DMT_Taxonomy_Values__c tax = new DMT_Taxonomy_Values__c(
            Name = 'TEST',
            DMT_Name_EN__c = 'TEST',
            DMT_Name__c = 'TEST',
            DMT_Key__c = 'PRODUCTTEST',
            DMT_Value__c = 'PRODUCTTEST',
            gf_catalog_atrb_val1_name_c__c = '1234567890',
            gf_catalog_atrb_val3_name__c = 'XX',
            gf_catalog_atrb_val4_name__c = 'Product',
            gf_catalog_atrb_val5_name__c = 'OL',
            CurrencyIsoCode = 'USD',
            DMT_External_Id__c = '999999',
            DMT_Catalog__c = 'D744'
        );
        insert tax;
        Product2 prod = new Product2(
            Name = 'Producto Test 1',
            ProductCode = '1234567890',
            CurrencyIsoCode = 'USD',
            DMT_CatalogTaxonomy__c = 'D744',
            DMT_Taxonomy_Value__c = tax.Id
        );

        Test.startTest();
        insert prod;
        Test.stopTest();

        
        Product2 insertedProd = [SELECT Id, DMT_CatalogTaxonomy__c, DMT_Taxonomy_Value__c, DMT_Product_Template__c FROM Product2 WHERE Id = :prod.Id];
        System.assertEquals('D744', insertedProd.DMT_CatalogTaxonomy__c, 'El taxonomy catalog debería mantenerse igual');
        System.assertEquals(tax.Id, insertedProd.DMT_Taxonomy_Value__c, 'El taxonomy value debería mantenerse igual');
        System.assertEquals('OL', insertedProd.DMT_Product_Template__c, 'El taxonomy template debería mantenerse igual');

    }

    @isTest
    static void testBeforeUpdate() {
        Product2 prod = new Product2(
            Name = 'Producto Test 3',
            ProductCode = '9876543210',
            CurrencyIsoCode = 'USD',
            DMT_CatalogTaxonomy__c = 'c372'
        );
        insert prod;

        prod.ProductCode = '1111222233';
        Test.startTest();
        update prod;
        Test.stopTest();

        Product2 updatedProd = [SELECT Id, ProductCode FROM Product2 WHERE Id = :prod.Id];
        System.assertEquals('1111222233', updatedProd.ProductCode, 'El ProductCode debería haberse actualizado');
    
        // Si el trigger hace validaciones en update, aquí haces los asserts correspondientes
    }
}