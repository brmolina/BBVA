@isTest
public class DMT_JSONToItem_Test {
    
    @isTest
    static void testConvertToItemsAndInsert() {
        // Crear datos de prueba para DMT_View__c
        DMT_ApproversView__c testView = new DMT_ApproversView__c(Name = 'Test View', DMT_DeveloperName__c = 'Test View');
        insert testView;

        // Crear datos de prueba existentes para asegurarse de que son eliminados
        DMT_Items__c existingItem = new DMT_Items__c(
            DMT_order_display__c = 1,
            Type_Item__c = 'Component',
            DMT_Component_Item__c = 'Treasury Line',
            DMT_Text__c = 'Old Text',
            DMT_View__c = testView.Id
        );
        insert existingItem;

        // Crear el JSON de prueba
        String testJson = '[{"orderDisplay": 1, "type": "Component", "component": "Treasury Line", "textValue": "Test Text 1"},' +
                          '{"orderDisplay": 2, "type": "Component", "component": "Treasury Client", "textValue": "Test Text 2"}]';

        // Crear el request de entrada
        List<DMT_JSONToItem.RequestWrapper> inputRequests = new List<DMT_JSONToItem.RequestWrapper>();
        DMT_JSONToItem.RequestWrapper request = new DMT_JSONToItem.RequestWrapper();
        request.jsonItems = testJson;
        request.viewId = testView.Id;
        inputRequests.add(request);

        // Ejecutar el método
        Test.startTest();
        DMT_JSONToItem.convertToItemsAndInsert(inputRequests);
        Test.stopTest();

        // Validar que los ítems existentes fueron eliminados
        List<DMT_Items__c> oldItems = [
            SELECT Id FROM DMT_Items__c WHERE Id = :existingItem.Id
        ];
        System.assertEquals(0, oldItems.size(), 'Old items should be deleted.');

        // Validar que los nuevos ítems fueron insertados
        List<DMT_Items__c> newItems = [
            SELECT DMT_order_display__c, Type_Item__c, DMT_Component_Item__c, DMT_Text__c
            FROM DMT_Items__c
            WHERE DMT_View__c = :testView.Id
            ORDER BY DMT_order_display__c
        ];
        System.assertEquals(2, newItems.size(), 'Two new items should have been inserted.');

        // Validar datos del primer ítem
        System.assertEquals(1, newItems[0].DMT_order_display__c, 'Order display of first item should be 1.');
        System.assertEquals('Component', newItems[0].Type_Item__c, 'Type of first item should be Text.');
        System.assertEquals('Treasury Line', newItems[0].DMT_Component_Item__c, 'Component of first item should match.');
        System.assertEquals('Test Text 1', newItems[0].DMT_Text__c, 'Text value of first item should match.');

        // Validar datos del segundo ítem
        System.assertEquals(2, newItems[1].DMT_order_display__c, 'Order display of second item should be 2.');
        System.assertEquals('Component', newItems[1].Type_Item__c, 'Type of second item should be Image.');
        System.assertEquals('Treasury Client', newItems[1].DMT_Component_Item__c, 'Component of second item should match.');
        System.assertEquals('Test Text 2', newItems[1].DMT_Text__c, 'Text value of second item should match.');
    }

    @isTest
    static void testErrorHandling() {
        // Crear datos de prueba para DMT_View__c
        DMT_ApproversView__c testView = new DMT_ApproversView__c(Name = 'Test View for Error', DMT_DeveloperName__c = 'Test View for Error');
        insert testView;

        // Crear el JSON de prueba con datos incorrectos
        String invalidJson = '[{"orderDisplay": "invalid", "type": "Text"}]'; // 'orderDisplay' es inválido

        // Crear el request de entrada
        List<DMT_JSONToItem.RequestWrapper> inputRequests = new List<DMT_JSONToItem.RequestWrapper>();
        DMT_JSONToItem.RequestWrapper request = new DMT_JSONToItem.RequestWrapper();
        request.jsonItems = invalidJson;
        request.viewId = testView.Id;
        inputRequests.add(request);

        // Ejecutar el método y capturar cualquier excepción
        Test.startTest();
        Boolean exceptionThrown = false;
        String exceptionMessage = '';
        String exceptionType = 'Unknown';
        try {
            DMT_JSONToItem.convertToItemsAndInsert(inputRequests);
        } catch (Exception e) {
            exceptionThrown = true;
            exceptionMessage = e.getMessage();
            if (e instanceof AuraHandledException) {
                exceptionType = 'AuraHandledException';
            } else if (e instanceof DmlException) {
                exceptionType = 'DmlException';
            } else {
                exceptionType = 'Other Exception';
            }
        }
        Test.stopTest();
        // Asegurar que se lanzó una excepción
        System.assert(exceptionThrown, 'An exception should have been thrown for invalid JSON.');

        // Registrar detalles adicionales para depuración
        System.debug('Exception Message: ' + exceptionMessage);
        System.debug('Exception Type: ' + exceptionType);
    }
}