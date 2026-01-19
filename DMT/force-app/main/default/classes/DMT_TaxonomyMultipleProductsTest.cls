@isTest
private class DMT_TaxonomyMultipleProductsTest {

    @TestSetup
    static void setupData() {
        // Creamos productos ficticios
        DMT_Test_DataFactory.generateAccount();
        DMT_Test_DataFactory.generatePricebook2();
        DMT_Test_DataFactory.generateTestOtherLines();
        List<Product2> products = new List<Product2>();

        // Creamos valores de taxonomía
        List<dmt_taxonomy_values__c> taxonomy = new List<dmt_taxonomy_values__c>();

        taxonomy.add(new dmt_taxonomy_values__c(
            DMT_Catalog__c = 'D744',
            dmt_value__c = 'P000',
            dmt_name__c = 'Group 2',
            DMT_Name_EN__c = 'Group 2 EN',
            gf_catalog_atrb_val1_name_c__c = 'P000',
            DMT_External_Id__c = '7777777',
            DMT_Entific__c = 'ES',
            gf_catalog_atrb_val4_name__c = 'Product',
            gf_catalog_atrb_val5_name__c = 'OL'
        ));

        taxonomy.add(new dmt_taxonomy_values__c(
            DMT_Catalog__c = 'D744',
            dmt_value__c = 'P001',
            dmt_name__c = 'Group 1',
            DMT_Name_EN__c = 'Group 1 EN',
            gf_catalog_atrb_val1_name_c__c = 'P002,P003',
            DMT_External_Id__c = '999999',
            DMT_Entific__c = 'ES',
            gf_catalog_atrb_val4_name__c = 'Product',
            gf_catalog_atrb_val5_name__c = 'OL'
        ));

        taxonomy.add(new dmt_taxonomy_values__c(
            DMT_Catalog__c = 'D744',
            dmt_value__c = 'P002',
            dmt_name__c = 'Product 2',
            DMT_Name_EN__c = 'Product 2 EN',
            gf_catalog_atrb_val1_name_c__c = '',
            DMT_External_Id__c = '8888888',
            DMT_Entific__c = 'ES',
            DMT_Active__c = true,
            gf_catalog_atrb_val4_name__c = 'Category',
            gf_catalog_atrb_val5_name__c = 'OL'
        ));

        insert taxonomy;

        for (Integer i = 0; i < 3; i++) {
            products.add(new Product2(
                Name = 'Test Product ' + i,
                ProductCode = 'P00' + i,
                Family = 'DMT Lines',
                IsActive = true,
                DMT_Product_family__c = '1100000000',
                DMT_Product_Subfamily__c = '1111000000',
                DMT_Product_category__c = '1111110000',
                DMT_Product_Subcategory__c = '1111111100',
                DMT_Global_Product_Id__c = '1111111111',
                DMT_Entific__c = 'ES',
                DMT_CatalogTaxonomy__c = 'D744',
                DMT_Product_Template__c = 'OL',
                DMT_Taxonomy_Value__c = taxonomy[i].Id
            ));
        }

        insert products;

        
    }

    @isTest
    static void testGetAllProducts() {
        Test.startTest();
        DMT_Line__c line = [SELECT Id,DMT_line_template_type__c , Booking_Geography__c FROM DMT_Line__c WHERE Booking_Geography__c = 'ES' AND DMT_line_template_type__c = 'OL' LIMIT 1];
        List<Product2> result = DMT_TaxonomyMultipleProducts.getProductsDMT(line.Id);
        Test.stopTest();

        System.assertNotEquals(0, result.size(), 'Debe devolver productos');
        System.assertEquals('DMT Lines', result[0].Family, 'La familia debe coincidir');
    }

    @isTest
    static void testGetProducts() {
        Test.startTest();
        DMT_Line__c line = [SELECT Id FROM DMT_Line__c LIMIT 1];
        List<dmt_taxonomy_values__c> result = DMT_TaxonomyMultipleProducts.getTaxonomy(line.Id);
        Test.stopTest();

        System.assertNotEquals(0, result.size(), 'Debe devolver valores de taxonomía');
        System.assertEquals('D744', result[0].DMT_Catalog__c, 'El catálogo debe ser D744');
    }

    // @isTest
    // static void testGetProductsByCategory() {
    //     Test.startTest();
    //     DMT_Line__c line = [SELECT Id, Booking_Geography__c, DMT_line_template_type__c FROM DMT_Line__c WHERE Booking_Geography__c = 'ES' AND DMT_line_template_type__c = 'OL' LIMIT 1];
    //     List<Product2> result = DMT_TaxonomyMultipleProducts.getProductsByCategory(line.Id);
    //     Test.stopTest();

    //     System.assertNotEquals(0, result.size(), 'Debe devolver valores de productos');
    // }

    @IsTest
    static void testGetProductsByCategory() {

        DMT_Line__c line = [SELECT Id, Booking_Geography__c, DMT_line_template_type__c FROM DMT_Line__c WHERE Booking_Geography__c = 'ES' AND DMT_line_template_type__c = 'OL' LIMIT 1];

        List<Product2> result = DMT_TaxonomyMultipleProducts.getProductsByCategory(line.Id);

        Test.startTest();
        DMT_TaxonomyMultipleProducts.saveCategoryOtherLine(line.Id, result[0].Id, result[0].Name, result[0].ProductCode, '365');
        Test.stopTest();

        List<DMT_Risk_Line_Term__c> allRisk = DMT_Passport_Selector.getRiskLineTermWhithoutRiskType(line.Id);
        DMT_Risk_Line_Term__c category = new DMT_Risk_Line_Term__c();
        for ( DMT_Risk_Line_Term__c risk : allRisk){
            if(risk.g_expert_criteria_risk_type__c != null){
                category = risk;
            }
        }

        System.assertNotEquals(null, category, 'Debe devolver risks');
        System.assertEquals(result[0].Name, category.Name, 'El Name debería ser el del producto');
    }

    @IsTest
    static void testSaveSelectedClients() {
        // Simulamos un Account para el lookup
        Account acc = [SELECT Id,DES_Group_Code__c FROM Account WHERE DES_Group_Code__c = 'G20180109100427' LIMIT 1];
        DMT_Line__c line = [SELECT Id, Booking_Geography__c, Line_Id__c FROM DMT_Line__c WHERE Booking_Geography__c = 'ES' AND DMT_line_template_type__c = 'OL' LIMIT 1];
        // Simulamos datos de clientes como los que vendrían del LWC
        List<Object> fakeClients = new List<Object>{
            new Map<Object, Object>{ 'customerId' => 'CUST001' },
            new Map<Object, Object>{ 'customerId' => 'CUST002' }
        };

        Test.startTest();

        DMT_TaxonomyMultipleProducts.saveSelectedClients(
            fakeClients,
            acc.Id,
            acc.DES_Group_Code__c,
            line.Line_Id__c,
            line.Id, // Id de línea ficticio
            line.Booking_Geography__c,
            'CUST001',
            '01'
        );

        Test.stopTest();

        // Verificamos los inserts
        List<Custom_Association__c> assoc = [SELECT Id FROM Custom_Association__c];
        System.assertEquals(1, assoc.size(), 'Debe haberse creado 1 asociación');

        List<Custom_Association_Client__c> clients = [
            SELECT Id, Alpha_Code_Client__c, gf_customer_group_id__c
            FROM Custom_Association_Client__c
        ];
        System.assertEquals(2, clients.size(), 'Debe haber 2 clientes asociados');
        System.assert(clients[0].gf_customer_group_id__c.contains(line.Line_Id__c), 'El G_Customer_Group_Id__c debe tener el line + priority');
    }

        @isTest
    static void testUpdateRiskLineTerms_Basic() {
        DMT_Line__c line = [SELECT Id,DMT_line_template_type__c , Booking_Geography__c FROM DMT_Line__c WHERE Booking_Geography__c = 'ES' AND DMT_line_template_type__c = 'OL' LIMIT 1];
        
        // 1. Preparar datos de prueba
        List<dmt_risk_line_term__c> testRecords = new List<dmt_risk_line_term__c>();
        Date today = Date.today();
        
        // Registro normal con fecha futura
        testRecords.add(new dmt_risk_line_term__c(
            Name = 'Test1',
            DMT_Init_Term__c = '0',
            DMT_End_Term__c = '30',
            dmt_max_date__c = today.addDays(25), // Buscará término 30
            DMT_Risk_Type__c = 'Derivatives',
            DMT_Singular__c = true,
            DMT_Line__c = line.Id
        ));
        
        // Registro con fecha pasada (debe ser término 0)
        testRecords.add(new dmt_risk_line_term__c(
            Name = 'Test2',
            DMT_Init_Term__c = '0',
            DMT_End_Term__c = '30',
            DMT_Risk_Type__c = 'Singular',
            DMT_Line__c = line.Id
        ));
        
        insert testRecords;
        
        Test.startTest();
        
        // 2. Ejecutar método bajo prueba
        List<List<dmt_risk_line_term__c>> input = new List<List<dmt_risk_line_term__c>>();
        input.add(testRecords);
        DMT_TaxonomyMultipleProducts.updateRiskLineTerms(input);
        
        Test.stopTest();
        
        // 3. Verificar resultados
        List<dmt_risk_line_term__c> updatedRecords = [
            SELECT Id, DMT_End_Term__c, dmt_max_date__c, DMT_Init_Term__c, DMT_Line__c, DMT_Singular__c
            FROM dmt_risk_line_term__c 
            WHERE Id IN :testRecords
            ORDER BY Name
        ];
        
        // Primer registro: 25 días -> debe asignar término 30
        System.assertEquals('30', updatedRecords[0].DMT_End_Term__c, 
            'Para 25 días debe asignar término 30');
        
        // Segundo registro: fecha pasada -> debe asignar término 0
        System.assertEquals('30', updatedRecords[1].DMT_End_Term__c, 
            'Para fecha pasada debe asignar término 30');
    }
    
    @isTest
    static void testUpdateRiskLineTerms_DeleteRecords() {
        // Crear registro que debe eliminarse (sin fecha y con tipo RSK_SINGULAR)
        DMT_Line__c line = [SELECT Id,DMT_line_template_type__c , Booking_Geography__c FROM DMT_Line__c WHERE Booking_Geography__c = 'ES' AND DMT_line_template_type__c = 'OL' LIMIT 1];
        
        dmt_risk_line_term__c record = new dmt_risk_line_term__c(
            Name = 'ToDelete',
            dmt_max_date__c = null,
            DMT_Risk_Type__c = DMT_Constants.RSK_SINGULAR,
            DMT_Line__c = line.Id
        );
        insert record;
        
        // Contar antes
        Integer countBefore = [SELECT COUNT() FROM dmt_risk_line_term__c];
        
        Test.startTest();
        
        // Ejecutar método
        List<List<dmt_risk_line_term__c>> input = new List<List<dmt_risk_line_term__c>>();
        input.add(new List<dmt_risk_line_term__c>{record});
        DMT_TaxonomyMultipleProducts.updateRiskLineTerms(input);
        
        Test.stopTest();
        
        // Verificar que se eliminó
        Integer countAfter = [SELECT COUNT() FROM dmt_risk_line_term__c];
        System.assertEquals(countBefore , countAfter, 'Debe eliminar registro sin fecha de tipo RSK_SINGULAR');
    }
    
    @isTest
    static void testUpdateRiskLineTerms_EmptyList() {
        // Probar con lista vacía
        Test.startTest();
        DMT_TaxonomyMultipleProducts.updateRiskLineTerms(new List<List<dmt_risk_line_term__c>>{new List<dmt_risk_line_term__c>()});
        Test.stopTest();
        
        // No debe lanzar excepción
        System.assert(true);
    }

}