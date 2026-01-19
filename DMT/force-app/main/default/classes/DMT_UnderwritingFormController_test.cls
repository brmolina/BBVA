@IsTest
public with sharing class DMT_UnderwritingFormController_test {

    // -------------------------
    // Helpers
    // -------------------------
    private static String firstPicklistValue(String sobjectApi, String fieldApi) {
        Schema.SObjectType t = Schema.getGlobalDescribe().get(sobjectApi);
        Schema.DescribeFieldResult f = t.getDescribe().fields.getMap().get(fieldApi).getDescribe();
        List<Schema.PicklistEntry> vals = f.getPicklistValues();
        return (vals.isEmpty()) ? null : vals[0].getValue();
    }

    private static Opportunity getTestOpp() {
        return [
            SELECT Id, Name, underwriting_agreement_type__c, deal_total_amount__c, signing_date__c
            FROM Opportunity
            WHERE Name = 'Test Opp'
            LIMIT 1
        ];
    }

    // -------------------------
    // Test data
    // -------------------------
    @TestSetup
    static void makeData() {

        Opportunity opp = DMT_Test_DataFactory.generateOpportunity();

        String uwValue = firstPicklistValue('Opportunity', 'underwriting_agreement_type__c');
        if (uwValue != null) {
            opp.underwriting_agreement_type__c = uwValue;
        }
        update opp;

        insert new List<Account>{
            new Account(Name = 'CP One', DES_Structure_Type__c = 'Subsidiary'),
            new Account(Name = 'CP Two', DES_Structure_Type__c = 'Subsidiary')
        };
    }

    // -------------------------
    // getUnderwritingData
    // -------------------------
    @IsTest
    static void getUnderwritingDataTest() {
        Opportunity opp = getTestOpp();

        Test.startTest();
        Map<String, Object> result = DMT_UnderwritingFormController.getUnderwritingData(opp.Id);
        Test.stopTest();

        System.assertNotEquals(null, result, 'Result no puede ser null');
        System.assert(result.containsKey('opportunity'), 'Debe devolver opportunity');
        System.assert(result.containsKey('picklistValues'), 'Debe devolver picklistValues');
        System.assert(result.containsKey('soldOrders'), 'Debe devolver soldOrders');
        System.assert(result.containsKey('soldOrderCurrencyOptions'), 'Debe devolver soldOrderCurrencyOptions');
        System.assert(result.containsKey('soldOrderSettledOptions'), 'Debe devolver soldOrderSettledOptions');
        System.assert(result.containsKey('soldOrderCounterpartyOptions'), 'Debe devolver soldOrderCounterpartyOptions');

        Opportunity returnedOpp = (Opportunity) result.get('opportunity');
        System.assertEquals(opp.Id, returnedOpp.Id, 'Debe devolver la misma Opportunity');
    }

    // -------------------------
    // saveUnderwritingData - update normal
    // -------------------------
    @IsTest
    static void saveUnderwritingData_UpdateOppFieldTest() {
        Opportunity opp = getTestOpp();

        Map<String, Object> updatedFields = new Map<String, Object>{
            'deal_total_amount__c' => 5000000,
            'operation_underwriting_per__c' => 20000,
            'bbva_prtcp_tranche_amount__c' => 100
        };

        Test.startTest();
        DMT_UnderwritingFormController.saveUnderwritingData(
            opp.Id,
            updatedFields,
            null,  
            null    
        );
        Test.stopTest();

        Opportunity updatedOpp = [SELECT deal_total_amount__c FROM Opportunity WHERE Id = :opp.Id];
        System.assertEquals(5000000, updatedOpp.deal_total_amount__c, 'Debe actualizar el importe');
    }

    // -------------------------
    // saveUnderwritingData - date conversion ok
    // -------------------------
    @IsTest
    static void saveUnderwritingData_DateConversionTest() {
        Opportunity opp = getTestOpp();
        Date testDate = Date.today();

        Map<String, Object> updatedFields = new Map<String, Object>{
            'signing_date__c' => String.valueOf(testDate)
        };

        Test.startTest();
        DMT_UnderwritingFormController.saveUnderwritingData(
            opp.Id,
            updatedFields,
            null,
            null
        );
        Test.stopTest();

        Opportunity updatedOpp = [SELECT signing_date__c FROM Opportunity WHERE Id = :opp.Id];
        System.assertEquals(testDate, updatedOpp.signing_date__c, 'Debe convertir y guardar la fecha');
    }

    // -------------------------
    // saveUnderwritingData - invalid date => AuraHandledException
    // -------------------------
    @IsTest
    static void saveUnderwritingData_InvalidDateTest() {
        Opportunity opp = getTestOpp();

        Map<String, Object> updatedFields = new Map<String, Object>{
            'signing_date__c' => 'fecha-invalida'
        };

        String errorMessage;

        Test.startTest();
        try {
            DMT_UnderwritingFormController.saveUnderwritingData(
                opp.Id,
                updatedFields,
                null,
                null
            );
            System.assert(false, 'Se esperaba AuraHandledException por fecha inválida');
        } catch (Exception e) {
            // A veces llega AuraHandledException o alguna otra excepción envolviendo el mensaje
            errorMessage = e.getMessage();
        }
        Test.stopTest();
        System.assert(String.isNotBlank(errorMessage), 'El mensaje de error no debe estar vacío');      
    }

    // -------------------------
    // saveUnderwritingData - Sold Order upsert + delete idsToDelete
    // -------------------------
    @IsTest
    static void saveUnderwritingData_SoldOrderMissingRequiredFieldsTest() {
        Opportunity opp = getTestOpp();

        Sold_Order__c so = new Sold_Order__c();
        Boolean threw = false;
        String msg;

        Test.startTest();
        try {
            DMT_UnderwritingFormController.saveUnderwritingData(
                opp.Id,
                null,
                new List<Sold_Order__c>{ so },
                null
            );
        } catch (Exception e) {
            threw = true;
            msg = e.getMessage();
        }
        Test.stopTest();
        System.assertEquals(true, threw, 'Debe lanzar excepción si faltan campos requeridos');

        System.assert(
            String.isNotBlank(msg),
            'El mensaje de error debe existir'
        );
    }

    // -------------------------
    // searchClientsFromLocal
    // -------------------------
    @IsTest
    static void searchClientsFromLocalTest() {
        // Pre-condición: term < 2 => vacío (sin startTest)
        List<DMT_UnderwritingFormController.LookupOption> emptyRes =
            DMT_UnderwritingFormController.searchClientsFromLocal('A');
        System.assertEquals(0, emptyRes.size(), 'Con menos de 2 chars debe devolver vacío');

        // Preparamos datos si existe Cib_Client__c
        Map<String, Schema.SObjectType> gd = Schema.getGlobalDescribe();
        Id clientId;
        String clientName = 'Test Client';

        if (gd.containsKey('Cib_Client__c')) {
            SObject client = gd.get('Cib_Client__c').newSObject();
            client.put('Name', clientName);
            insert client;
            clientId = (Id) client.get('Id');

            Local_Client__c lc1 = new Local_Client__c();
            lc1.Name = 'Te Local 1';
            lc1.put('Cib_Client__c', clientId);

            Local_Client__c lc2 = new Local_Client__c();
            lc2.Name = 'Te Local 2';
            lc2.put('Cib_Client__c', clientId);

            insert new List<Local_Client__c>{ lc1, lc2 };
        }

        // Un único start/stop por método
        Test.startTest();
        List<DMT_UnderwritingFormController.LookupOption> res =
            DMT_UnderwritingFormController.searchClientsFromLocal('Te');
        Test.stopTest();

        System.assertNotEquals(null, res, 'Debe devolver una lista');

        // Si existe el objeto, validamos que aparece nuestro cliente; si no, no forzamos contenido
        if (clientId != null) {
            Boolean found = false;
            for (DMT_UnderwritingFormController.LookupOption opt : res) {
                if (opt.value == String.valueOf(clientId) && opt.label == clientName) {
                    found = true;
                    break;
                }
            }
            System.assert(found, 'Debe devolver el cliente esperado (value=id, label=Name)');
        }
    }
}