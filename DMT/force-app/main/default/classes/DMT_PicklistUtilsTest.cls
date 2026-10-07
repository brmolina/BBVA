@isTest
private without sharing class DMT_PicklistUtilsTest {

    @testSetup
    static void setupData() {

        List<DMT_Taxonomy_Values__c> valuesToInsert = new List<DMT_Taxonomy_Values__c>{
            new DMT_Taxonomy_Values__c(
                DMT_Catalog__c = 'T123',
                DMT_Name_EN__c = 'EN Label 1',
                DMT_Name__c = 'ES Label 1',
                DMT_Value__c = 'AA01'
            ),
            new DMT_Taxonomy_Values__c(
                DMT_Catalog__c = 'T123',
                DMT_Name_EN__c = 'EN Label 2',
                DMT_Name__c = 'ES Label 2',
                DMT_Value__c = 'AA02'
            ),
            new DMT_Taxonomy_Values__c(
                DMT_Catalog__c = 'T123',
                DMT_Name_EN__c = 'EN Label 3',
                DMT_Name__c = 'ES Label 3',
                DMT_Value__c = 'BB01'
            )
        };
        insert valuesToInsert;

        DMT_Taxonomy_Values__c initialVal = new DMT_Taxonomy_Values__c(
            DMT_Catalog__c = 'T123',
            DMT_Name_EN__c = 'Initial EN',
            DMT_Name__c = 'Initial ES',
            DMT_Value__c = 'INIT01'
        );

        DMT_Taxonomy_Values__c finalVal = new DMT_Taxonomy_Values__c(
            DMT_Catalog__c = 'T123',
            DMT_Name_EN__c = 'Final EN',
            DMT_Name__c = 'Final ES',
            DMT_Value__c = 'FIN01',
            gf_catalog_atrb_val1_name_c__c = '001'
        );

        insert new List<DMT_Taxonomy_Values__c>{ initialVal, finalVal };

        DMT_Taxonomy_Relationship__c rel = new DMT_Taxonomy_Relationship__c(
            DMT_Id_Catalog__c = 'T123',
            DMT_Id_Catalog_Initial__c = 'T123',
            DMT_Id_Catalog_Final__c = 'T123',
            DMT_Value_Catalog_Initial__c = 'INITKEY',
            DMT_Value_Catalog_Final__c = 'RELVAL01',
            DMT_Initial_Taxonomy_Value__c = initialVal.Id,
            DMT_Final_Taxonomy_Value__c = finalVal.Id
        );
        insert rel;
    }

    @isTest
    static void testGetPicklistValues_Success() {
        // Arrange
        DMT_PicklistUtils picklistUtils = new DMT_PicklistUtils();
        Map<String, Object> inputMap = new Map<String, Object>{
            'objectApiName' => 'Account',
            'fieldApiName' => 'Industry' // Usar un campo picklist estándar
        };
        Map<String, Object> outputMap = new Map<String, Object>();
        Map<String, Object> optionsMap = new Map<String, Object>();

        Map<String, Object> args = new Map<String, Object>{
            'input' => inputMap,
            'output' => outputMap,
            'options' => optionsMap
        };

        // Act
        Test.startTest();
        Map<String, Object> result = (Map<String, Object>) picklistUtils.call('getPicklistValues', args);
        Test.stopTest();

        // Assert
        System.assertNotEquals(null, result, 'El resultado no debe ser nulo');
        System.assert(result.containsKey('options'), 'El resultado debe contener la clave "options"');
        System.assertEquals(null, result.get('error'), 'No debería haber error en un caso exitoso');

        List<Object> optionsList = (List<Object>) result.get('options');
        System.assertNotEquals(null, optionsList, 'La lista de opciones no debe ser nula');
        System.assert(!optionsList.isEmpty(), 'La lista de opciones no debe estar vacía para Account.Industry');

        // Verificar la estructura de una opción
        Map<String, Object> firstOption = (Map<String, Object>) optionsList[0];
        System.assert(firstOption.containsKey('label'), 'La opción debe tener "label"');
        System.assert(firstOption.containsKey('value'), 'La opción debe tener "value"');
        System.assert(firstOption.containsKey('defaultValue'), 'La opción debe tener "defaultValue"');
        System.assertNotEquals(null, firstOption.get('label'));
        System.assertNotEquals(null, firstOption.get('value'));
    }

    @isTest
    static void testGetPicklistValuesLabelsAsValue_Success() {
        // Arrange
        DMT_PicklistUtils picklistUtils = new DMT_PicklistUtils();
        Map<String, Object> inputMap = new Map<String, Object>{
            'objectApiName' => 'Account',
            'fieldApiName' => 'Rating' // Usar otro campo picklist estándar
        };
        Map<String, Object> outputMap = new Map<String, Object>();
        Map<String, Object> optionsMap = new Map<String, Object>();

         Map<String, Object> args = new Map<String, Object>{
            'input' => inputMap,
            'output' => outputMap,
            'options' => optionsMap
        };

        // Act
        Test.startTest();
        Map<String, Object> result = (Map<String, Object>) picklistUtils.call('getPicklistValuesLabeslAsValue', args);
        Test.stopTest();

        // Assert
        System.assertNotEquals(null, result, 'El resultado no debe ser nulo');
        System.assert(result.containsKey('options'), 'El resultado debe contener la clave "options"');
        System.assertEquals(null, result.get('error'), 'No debería haber error en un caso exitoso');

        List<Object> optionsList = (List<Object>) result.get('options');
        System.assertNotEquals(null, optionsList, 'La lista de opciones no debe ser nula');
        System.assert(!optionsList.isEmpty(), 'La lista de opciones no debe estar vacía para Account.Rating');

        // Verificar la estructura y que label == value
        if (!optionsList.isEmpty()) {
            Map<String, Object> firstOption = (Map<String, Object>) optionsList[0];
            System.assert(firstOption.containsKey('label'), 'La opción debe tener "label"');
            System.assert(firstOption.containsKey('value'), 'La opción debe tener "value"');
            System.assert(firstOption.containsKey('defaultValue'), 'La opción debe tener "defaultValue"');
            System.assertEquals(firstOption.get('value'), firstOption.get('label'), 'Label debe ser igual a Value');
             System.assertNotEquals(null, firstOption.get('value'));
        }
    }

     @isTest
    static void testGetPicklistValues_NonPicklistField() {
        // Arrange
        DMT_PicklistUtils picklistUtils = new DMT_PicklistUtils();
        Map<String, Object> inputMap = new Map<String, Object>{
            'objectApiName' => 'Account',
            'fieldApiName' => 'Name' // Campo de texto, no picklist
        };
        Map<String, Object> outputMap = new Map<String, Object>();
        Map<String, Object> optionsMap = new Map<String, Object>();

        Map<String, Object> args = new Map<String, Object>{
            'input' => inputMap,
            'output' => outputMap,
            'options' => optionsMap
        };

        // Act
        Test.startTest();
        Map<String, Object> result = (Map<String, Object>) picklistUtils.call('getPicklistValues', args);
        Test.stopTest();

        // Assert
        System.assertNotEquals(null, result, 'El resultado no debe ser nulo');
        System.assert(result.containsKey('options'), 'El resultado debe contener la clave "options"');
        System.assertEquals(null, result.get('error'), 'No debería haber error para un campo no picklist');

        List<Object> optionsList = (List<Object>) result.get('options');
        System.assertNotEquals(null, optionsList, 'La lista de opciones no debe ser nula');
        // getPicklistValues() en un campo no-picklist devuelve una lista vacía
        System.assert(optionsList.isEmpty(), 'La lista de opciones debe estar vacía para un campo no picklist');
    }

    @isTest
    static void testGetPicklistValues_EmptyOptionForDmtLineBreakclauseFields() {
        DMT_PicklistUtils picklistUtils = new DMT_PicklistUtils();
        Map<String, Object> inputMap = new Map<String, Object>{
            'objectApiName' => 'DMT_Line__c',
            'fieldApiName' => 'First_Breakclause__c'
        };
        Map<String, Object> outputMap = new Map<String, Object>();

        Map<String, Object> args = new Map<String, Object>{
            'input' => inputMap,
            'output' => outputMap,
            'options' => new Map<String, Object>()
        };

        Test.startTest();
        Map<String, Object> result = (Map<String, Object>) picklistUtils.call('getPicklistValues', args);
        Test.stopTest();

        System.assertEquals(null, result.get('error'));
        List<Object> optionsList = (List<Object>) result.get('options');
        System.assert(!optionsList.isEmpty(), 'La lista de opciones no debe estar vacía');

        Map<String, Object> firstOption = (Map<String, Object>) optionsList[0];
        System.assertEquals(' ', firstOption.get('value'), 'El valor de la primera opción debe ser un espacio');
        System.assertEquals(' ', firstOption.get('label'), 'La etiqueta de la primera opción debe ser una cadena vacía');
        System.assertEquals(false, firstOption.get('defaultValue'));
    }

    @isTest
    static void testInvalidAction() {
        // Arrange
        DMT_PicklistUtils picklistUtils = new DMT_PicklistUtils();
        Map<String, Object> inputMap = new Map<String, Object>{
            'objectApiName' => 'Account',
            'fieldApiName' => 'Industry'
        };
        Map<String, Object> outputMap = new Map<String, Object>();
        Map<String, Object> optionsMap = new Map<String, Object>();
        Map<String, Object> originalOutputMap = new Map<String, Object>(outputMap); // Copia para comparar

         Map<String, Object> args = new Map<String, Object>{
            'input' => inputMap,
            'output' => outputMap,
            'options' => optionsMap
        };

        // Act
        Test.startTest();
        Map<String, Object> result = (Map<String, Object>) picklistUtils.call('someInvalidAction', args); // Acción inválida
        Test.stopTest();

        // Assert
        // invokeMethod simplemente no hace nada si la acción no coincide
        System.assertNotEquals(null, result, 'El resultado no debe ser nulo');
        System.assertEquals(null, result.get('error'), 'No debería haber error por acción inválida manejada');
        System.assertEquals(null, result.get('options'), 'No debería añadirse la clave "options"');
        // El mapa devuelto debería ser el mismo que el outputMap original pasado
        System.assertEquals(originalOutputMap.keySet().size(), result.keySet().size(), 'El mapa de salida no debería cambiar significativamente');
    }

    @isTest
    static void testCallInterface() {
         // Arrange
        DMT_PicklistUtils picklistUtils = new DMT_PicklistUtils();
        Map<String, Object> inputMap = new Map<String, Object>{
            'objectApiName' => 'Contact',
            'fieldApiName' => 'LeadSource' // Usar otro objeto/campo
        };
        Map<String, Object> outputMap = new Map<String, Object>();
        Map<String, Object> optionsMap = new Map<String, Object>();

        Map<String, Object> args = new Map<String, Object>{
            'input' => inputMap,
            'output' => outputMap,
            'options' => optionsMap
        };
        String action = 'getPicklistValues';

         // Act
        Test.startTest();
        // Llama directamente a 'call' para asegurar cobertura de ese método
        Object resultObject = picklistUtils.call(action, args);
        Test.stopTest();

         // Assert
        System.assert(resultObject instanceof Map<String, Object>, 'El resultado debe ser un Map');
        Map<String, Object> resultMap = (Map<String, Object>) resultObject;
        System.assert(resultMap.containsKey('options'), 'El mapa resultante debe contener opciones');
        System.assertEquals(null, resultMap.get('error'), 'No debería haber error');
         List<Object> optionsList = (List<Object>) resultMap.get('options');
        System.assert(!optionsList.isEmpty(), 'La lista de opciones no debe estar vacía para Contact.LeadSource');

    }

    @isTest
    static void testGetTaxonomyRelationshipValues_FormattedLabelFalse() {
        DMT_PicklistUtils picklistUtils = new DMT_PicklistUtils();

        Map<String, Object> inputMap = new Map<String, Object>{
            'catalogId' => 'T123',
            'formattedLabel' => false
        };
        Map<String, Object> outMap = new Map<String, Object>();
        Map<String, Object> args = new Map<String, Object>{
            'input' => inputMap,
            'output' => outMap,
            'options' => new Map<String, Object>()
        };

        Test.startTest();
        Map<String, Object> result = (Map<String, Object>) picklistUtils.call('getTaxonomyRelationshipValues', args);
        Test.stopTest();

        System.assertEquals(null, result.get('error'));
        Map<String, Object> mapObj = (Map<String, Object>) result.get('mapTaxonomyRelValuesFixed');
        System.assertNotEquals(null, mapObj);
        System.assert(!mapObj.isEmpty());
    }

    @isTest
    static void testGetTaxonomyRelationshipValues_FormattedLabelTrue() {
        DMT_PicklistUtils picklistUtils = new DMT_PicklistUtils();

        Map<String, Object> inputMap = new Map<String, Object>{
            'catalogId' => 'T123',
            'formattedLabel' => true
        };
        Map<String, Object> outMap = new Map<String, Object>();
        Map<String, Object> args = new Map<String, Object>{
            'input' => inputMap,
            'output' => outMap,
            'options' => new Map<String, Object>()
        };

        Test.startTest();
        Map<String, Object> result = (Map<String, Object>) picklistUtils.call('getTaxonomyRelationshipValues', args);
        Test.stopTest();

        System.assertEquals(null, result.get('error'));
        Map<String, Object> mapObj = (Map<String, Object>) result.get('mapTaxonomyRelValuesFixed');
        System.assertNotEquals(null, mapObj);
        System.assert(!mapObj.isEmpty());
    }

    @isTest
    static void testGetPicklistDependantValuesByParam_Success() {
        DMT_PicklistUtils picklistUtils = new DMT_PicklistUtils();

        Map<String, Object> inputMap = new Map<String, Object>{
            'catalogId' => 'T123'
        };
        Map<String, Object> outMap = new Map<String, Object>();
        Map<String, Object> args = new Map<String, Object>{
            'input' => inputMap,
            'output' => outMap,
            'options' => new Map<String, Object>()
        };

        Test.startTest();
        Map<String, Object> result = (Map<String, Object>) picklistUtils.call('getPicklistDependantValuesByParam', args);
        Test.stopTest();

        System.assertEquals(null, result.get('error'));
        System.assert(result.containsKey('mapCatalogValuesFixed'));
        Map<String, Object> mapObj = (Map<String, Object>) result.get('mapCatalogValuesFixed');
        System.assert(mapObj.containsKey('AA'));
        System.assert(mapObj.containsKey('BB'));
        List<Object> aaList = (List<Object>) mapObj.get('AA');
        System.assertEquals(2, aaList.size());
    }

    @isTest
    static void testCapitalizeString_Normal() {
        DMT_PicklistUtils picklistUtils = new DMT_PicklistUtils();

        Map<String, Object> inputMap = new Map<String, Object>{
            'arguments' => new List<Object>{ 'INDUSTRIALS & TRANSPORTATION' }
        };
        Map<String, Object> args = new Map<String, Object>{
            'input'   => inputMap,
            'output'  => new Map<String, Object>(),
            'options' => new Map<String, Object>()
        };

        Test.startTest();
        Map<String, Object> result = (Map<String, Object>) picklistUtils.call('capitalizeString', args);
        Test.stopTest();

        System.assertEquals(null, result.get('error'));
        System.assertEquals('Industrials & transportation', (String) result.get('result'));
    }

    @isTest
    static void testCapitalizeString_AlreadyLower() {
        DMT_PicklistUtils picklistUtils = new DMT_PicklistUtils();

        Map<String, Object> inputMap = new Map<String, Object>{
            'arguments' => new List<Object>{ 'already lowercase' }
        };
        Map<String, Object> args = new Map<String, Object>{
            'input'   => inputMap,
            'output'  => new Map<String, Object>(),
            'options' => new Map<String, Object>()
        };

        Test.startTest();
        Map<String, Object> result = (Map<String, Object>) picklistUtils.call('capitalizeString', args);
        Test.stopTest();

        System.assertEquals(null, result.get('error'));
        System.assertEquals('Already lowercase', (String) result.get('result'));
    }

    @isTest
    static void testCapitalizeString_Empty() {
        DMT_PicklistUtils picklistUtils = new DMT_PicklistUtils();

        Map<String, Object> inputMap = new Map<String, Object>{
            'arguments' => new List<Object>{ '' }
        };
        Map<String, Object> args = new Map<String, Object>{
            'input'   => inputMap,
            'output'  => new Map<String, Object>(),
            'options' => new Map<String, Object>()
        };

        Test.startTest();
        Map<String, Object> result = (Map<String, Object>) picklistUtils.call('capitalizeString', args);
        Test.stopTest();

        System.assertEquals(null, result.get('error'));
        System.assertEquals('', (String) result.get('result'));
    }
}