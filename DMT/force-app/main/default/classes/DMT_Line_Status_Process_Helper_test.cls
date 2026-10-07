@isTest
public with sharing class DMT_Line_Status_Process_Helper_test {

    // Line_Id__c de las líneas que crea la factory
    private static final String TREASURY_LINE_ID = '00001';
    private static final String OTHER_LINE_ID    = '00003';

    @TestSetup
    static void loadTestData() {
        TriggerBypass.setBypass();
        DMT_Test_DataFactory.generateTestTreasuryLines();
        DMT_Test_DataFactory.generateTestOtherLines();
        TriggerBypass.removeBypass();
    }

    // ─────────────────────────────────────────────────────────────
    // Utilidades
    // ─────────────────────────────────────────────────────────────

    // Lleva la línea Treasury a Closed Won (dispara setDestinationSystemOnClosedWon)
    private static DMT_Line__c moveTreasuryLineToClosedWon(){
        DMT_Line__c line = [
            SELECT Id, Line_Id__c, Status__c, Closed__c, DMT_RecordTypeName__c, Start_Date__c, End_Date__c,
                   DMT_Destination_Status__c, DMT_Destination_Label__c, DMT_Destination_Id__c
            FROM DMT_Line__c
            WHERE Line_Id__c = :TREASURY_LINE_ID
            LIMIT 1
        ];

        line.Start_Date__c = Date.today();
        line.End_Date__c   = Date.today().addYears(1);

        line.Status__c = 'Closed';
        line.Closed__c = 'Won';
        update line;
        return line;
    }

    private static DMT_line_status_process__c buildStatusRecord(String lineCode, Boolean statusOk){
        return buildStatusRecord(lineCode, statusOk, null, null, null);
    }

    private static DMT_line_status_process__c buildStatusRecord(String lineCode, Boolean statusOk,
            String counterpartyCode, String errorDescription, Date responseDate){
        return new DMT_line_status_process__c(
            DMT_Line_Code_SF__c      = lineCode,
            DMT_Status__c            = statusOk,
            DMT_Counterparty_Code__c = counterpartyCode,
            DMT_Description_Error__c = errorDescription,
            DMT_Date__c              = responseDate
        );
    }

    private static DMT_Line__c getLine(String lineCode){
        return [
            SELECT Id, DMT_Destination_Status__c, DMT_Destination_Id__c, DMT_Destination_Label__c,
                   DMT_Destination_Light__c, DMT_Destination_Error__c, DMT_Destination_Date__c
            FROM DMT_Line__c
            WHERE Line_Id__c = :lineCode
            LIMIT 1
        ];
    }

    private static DMT_Destination_Mapping__mdt getTreasuryMapping(){
        return DMT_Destination_Mapping__mdt.getInstance('Treasury_Line');
    }

    // ─────────────────────────────────────────────────────────────
    // Paso a Closed Won (DMT_Line_Helper.setDestinationSystemOnClosedWon)
    // ─────────────────────────────────────────────────────────────

    @isTest
    private static void testClosedWonSetsPendingState(){
        // Simula restos de una respuesta anterior para comprobar que se limpian
        DMT_Line__c line = getLine(TREASURY_LINE_ID);
        line.DMT_Destination_Light__c = DMT_Line_Status_Process_Helper.LIGHT_RED;
        line.DMT_Destination_Error__c = 'Error de una respuesta anterior';
        line.DMT_Destination_Date__c  = Date.today().addDays(-10);
        TriggerBypass.setBypass();
        update line;
        TriggerBypass.removeBypass();

        Test.startTest();
        moveTreasuryLineToClosedWon();
        Test.stopTest();

        DMT_Destination_Mapping__mdt mapping = getTreasuryMapping();
        DMT_Line__c lineAfter = getLine(TREASURY_LINE_ID);

        System.assertEquals(mapping.DMT_Booking_System_Code__c, lineAfter.DMT_Destination_Label__c,
            'Closed Won -> label con el booking system del CMDT');
        System.assertEquals(mapping.DMT_Initial_Status__c, lineAfter.DMT_Destination_Status__c,
            'Closed Won -> status inicial del CMDT');
        System.assertEquals(DMT_Line_Status_Process_Helper.LIGHT_YELLOW, lineAfter.DMT_Destination_Light__c,
            'Closed Won -> semáforo amarillo');
        System.assertEquals(null, lineAfter.DMT_Destination_Error__c,
            'Closed Won -> se limpia el error anterior');
        System.assertEquals(null, lineAfter.DMT_Destination_Date__c,
            'Closed Won -> se limpia la fecha anterior');
    }

    // ─────────────────────────────────────────────────────────────
    // Respuestas de MENTOR (DMT_Line_Status_Process_Helper)
    // ─────────────────────────────────────────────────────────────

    @isTest
    private static void testAllOk(){
        moveTreasuryLineToClosedWon();

        List<DMT_line_status_process__c> statusRecords = new List<DMT_line_status_process__c>{
            buildStatusRecord(TREASURY_LINE_ID, true),
            buildStatusRecord(TREASURY_LINE_ID, true),
            buildStatusRecord(TREASURY_LINE_ID, true)
        };

        Test.startTest();
        insert statusRecords;
        Test.stopTest();

        DMT_Destination_Mapping__mdt mapping = getTreasuryMapping();
        DMT_Line__c line = getLine(TREASURY_LINE_ID);

        System.assertEquals(mapping.DMT_OK_Status__c, line.DMT_Destination_Status__c,
            'Todos OK -> status OK del CMDT');
        System.assertEquals(TREASURY_LINE_ID, line.DMT_Destination_Id__c,
            'El Id de destino debe ser el código de línea');
        System.assertEquals(DMT_Line_Status_Process_Helper.LIGHT_GREEN, line.DMT_Destination_Light__c,
            'Todos OK -> semáforo verde');
        System.assertEquals(null, line.DMT_Destination_Error__c,
            'Todos OK -> sin error');
    }

    @isTest
    private static void testSomeKo(){
        moveTreasuryLineToClosedWon();

        // KO sin descripción: la línea queda en rojo pero sin detalle de error
        List<DMT_line_status_process__c> statusRecords = new List<DMT_line_status_process__c>{
            buildStatusRecord(TREASURY_LINE_ID, true),
            buildStatusRecord(TREASURY_LINE_ID, false),
            buildStatusRecord(TREASURY_LINE_ID, true)
        };

        Test.startTest();
        insert statusRecords;
        Test.stopTest();

        DMT_Destination_Mapping__mdt mapping = getTreasuryMapping();
        DMT_Line__c line = getLine(TREASURY_LINE_ID);

        System.assertEquals(mapping.DMT_KO_Status__c, line.DMT_Destination_Status__c,
            'Un false -> status KO del CMDT');
        System.assertEquals(DMT_Line_Status_Process_Helper.LIGHT_RED, line.DMT_Destination_Light__c,
            'Un false -> semáforo rojo');
        System.assertEquals(null, line.DMT_Destination_Error__c,
            'KO sin descripción -> sin detalle de error');
    }

    @isTest
    private static void testSingleKoErrorWithoutPrefix(){
        moveTreasuryLineToClosedWon();

        Test.startTest();
        insert buildStatusRecord(TREASURY_LINE_ID, false, 'CP001', '  Contrapartida no encontrada  ', Date.today());
        Test.stopTest();

        DMT_Line__c line = getLine(TREASURY_LINE_ID);

        System.assertEquals(DMT_Line_Status_Process_Helper.LIGHT_RED, line.DMT_Destination_Light__c,
            'KO -> semáforo rojo');
        System.assertEquals('Contrapartida no encontrada', line.DMT_Destination_Error__c,
            'Línea con un solo registro -> error sin prefijo de counterparty y sin espacios sobrantes');
        System.assertEquals(Date.today(), line.DMT_Destination_Date__c,
            'La fecha de la línea es la DMT_Date__c de la respuesta');
    }

    @isTest
    private static void testGroupLineErrorsWithCounterpartyPrefix(){
        moveTreasuryLineToClosedWon();

        List<DMT_line_status_process__c> statusRecords = new List<DMT_line_status_process__c>{
            buildStatusRecord(TREASURY_LINE_ID, true,  'CP001', null,          Date.today()),
            buildStatusRecord(TREASURY_LINE_ID, false, 'CP002', 'Error CP002', Date.today()),
            buildStatusRecord(TREASURY_LINE_ID, false, 'CP003', 'Error CP003', Date.today())
        };

        Test.startTest();
        insert statusRecords;
        Test.stopTest();

        DMT_Line__c line = getLine(TREASURY_LINE_ID);

        System.assertEquals(DMT_Line_Status_Process_Helper.LIGHT_RED, line.DMT_Destination_Light__c,
            'Algún KO en línea de Grupo -> semáforo rojo');
        System.assert(line.DMT_Destination_Error__c.contains('[CP002] Error CP002'),
            'Cada error de Grupo lleva el prefijo de su counterparty');
        System.assert(line.DMT_Destination_Error__c.contains('[CP003] Error CP003'),
            'Se recogen todos los errores, no solo el primero');
        System.assert(!line.DMT_Destination_Error__c.contains('CP001'),
            'Los registros OK no aportan error');
        System.assertEquals(2, line.DMT_Destination_Error__c.split('\n').size(),
            'Un error por línea de texto');
    }

    @isTest
    private static void testMostRecentResponseDate(){
        moveTreasuryLineToClosedWon();

        List<DMT_line_status_process__c> statusRecords = new List<DMT_line_status_process__c>{
            buildStatusRecord(TREASURY_LINE_ID, true, 'CP001', null, Date.today().addDays(-5)),
            buildStatusRecord(TREASURY_LINE_ID, true, 'CP002', null, Date.today()),
            buildStatusRecord(TREASURY_LINE_ID, true, 'CP003', null, null)
        };

        Test.startTest();
        insert statusRecords;
        Test.stopTest();

        DMT_Line__c line = getLine(TREASURY_LINE_ID);

        System.assertEquals(Date.today(), line.DMT_Destination_Date__c,
            'Se toma la DMT_Date__c más reciente; los registros sin fecha se ignoran');
        System.assertEquals(DMT_Line_Status_Process_Helper.LIGHT_GREEN, line.DMT_Destination_Light__c,
            'Todos OK -> semáforo verde');
    }

    @isTest
    private static void testRecalculationKoToOk(){
        moveTreasuryLineToClosedWon();

        DMT_line_status_process__c koRecord =
            buildStatusRecord(TREASURY_LINE_ID, false, 'CP001', 'Error temporal', Date.today().addDays(-1));
        insert koRecord;

        DMT_Destination_Mapping__mdt mapping = getTreasuryMapping();

        DMT_Line__c lineAfterKo = getLine(TREASURY_LINE_ID);
        System.assertEquals(mapping.DMT_KO_Status__c, lineAfterKo.DMT_Destination_Status__c,
            'Tras el KO la línea debe estar cancelada');
        System.assertEquals(DMT_Line_Status_Process_Helper.LIGHT_RED, lineAfterKo.DMT_Destination_Light__c,
            'Tras el KO el semáforo debe estar en rojo');
        System.assertEquals('Error temporal', lineAfterKo.DMT_Destination_Error__c,
            'Tras el KO se muestra el error');

        Test.startTest();
        koRecord.DMT_Status__c            = true;
        koRecord.DMT_Description_Error__c = null;
        koRecord.DMT_Date__c              = Date.today();
        update koRecord;
        Test.stopTest();

        DMT_Line__c lineAfterFix = getLine(TREASURY_LINE_ID);
        System.assertEquals(mapping.DMT_OK_Status__c, lineAfterFix.DMT_Destination_Status__c,
            'Corregido a true -> recalcula a confirmada');
        System.assertEquals(DMT_Line_Status_Process_Helper.LIGHT_GREEN, lineAfterFix.DMT_Destination_Light__c,
            'Corregido a true -> semáforo verde');
        System.assertEquals(null, lineAfterFix.DMT_Destination_Error__c,
            'Corregido a true -> se limpia el error');
        System.assertEquals(Date.today(), lineAfterFix.DMT_Destination_Date__c,
            'El update refleja la nueva fecha de respuesta');
    }

    @isTest
    private static void testNonParametrizedRecordType(){
        Test.startTest();
        insert buildStatusRecord(OTHER_LINE_ID, false, 'CP001', 'Error en línea no parametrizada', Date.today());
        Test.stopTest();

        DMT_Line__c lineAfter = getLine(OTHER_LINE_ID);

        System.assertEquals(null, lineAfter.DMT_Destination_Status__c,
            'Record type no parametrizado no recibe status de destino');
        System.assertEquals(null, lineAfter.DMT_Destination_Light__c,
            'Record type no parametrizado no recibe semáforo');
        System.assertEquals(null, lineAfter.DMT_Destination_Error__c,
            'Record type no parametrizado no recibe error');
        System.assertEquals(null, lineAfter.DMT_Destination_Date__c,
            'Record type no parametrizado no recibe fecha');
    }
}