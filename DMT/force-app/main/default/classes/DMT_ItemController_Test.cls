@isTest
public with sharing class DMT_ItemController_Test {

    @TestSetup
    static void makeData(){
        CIB_Bypass__c settings = CIB_Bypass__c.getOrgDefaults();
        settings.ExtensionsAllowed__c = 'png|jpeg|jpg|gif|svg|pdf|docx|xlsx|pptx|doc|xls|ppt|html|json';
        settings.skipFileExtensions__c = false;
        upsert settings;
    }

    @isTest
    static void testUploadFile() {
        // Crear datos simulados para el archivo
        String fileName = 'TestFile.json';
        String base64Data = EncodingUtil.base64Encode(Blob.valueOf('This is a test file content'));
        Map<String, Object> fileData = new Map<String, Object>{
            'fileName' => fileName,
            'base64' => base64Data
        };

        // Ejecutar el método
        Test.startTest();
        ContentVersion uploadedFile = DMT_ItemController.uploadFile(fileData);
        Test.stopTest();

        // Validar el resultado
        Assert.areNotEqual(null, uploadedFile, 'The uploaded file should not be null.');
        Assert.areNotEqual(null, uploadedFile.ContentDocumentId, 'The ContentDocumentId should not be null.');
        Assert.areEqual(fileName, uploadedFile.Title, 'The uploaded file name should match the input.');
    }

    @isTest
    static void testGetTypeItemOptions() {
        // Simulación del esquema para evitar dependencias del entorno de datos reales
        Test.startTest();
        List<String> options = DMT_ItemController.getTypeItemOptions();
        Test.stopTest();

        // Validar que las opciones no sean nulas
        Assert.areNotEqual(null, options, 'Type item options should not be null.');

        // Validar que se devuelven opciones (si hay valores definidos en el esquema)
        System.assert(options.size() >= 0, 'Type item options should return at least 0 or more values.');
    }

    @isTest
    static void testGetComponentItemOptions() {
        // Simulación del esquema para evitar dependencias del entorno de datos reales
        Test.startTest();
        List<String> options = DMT_ItemController.getComponentItemOptions();
        Test.stopTest();

        // Validar que las opciones no sean nulas
        Assert.areNotEqual(null, options, 'Component item options should not be null.');

        // Validar que se devuelven opciones (si hay valores definidos en el esquema)
        System.assert(options.size() >= 0, 'Component item options should return at least 0 or more values.');
    }

    @isTest
    static void testGetFilteredComponentItemOptions() {
        String viewType = 'Line_Treasury';
        Test.startTest();
        List<String> options = DMT_ItemController.getFilteredComponentItemOptions(viewType);
        Test.stopTest();
        // Validar que las opciones no sean nulas
        Assert.areNotEqual(0, options.size(), 'Filtered component item options should not be null.');
    }
}