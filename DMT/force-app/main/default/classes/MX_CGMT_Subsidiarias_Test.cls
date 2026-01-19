/**
* ------------------------------------------------------------------------------------------------
* @Name     MX_CGMT_Subsidiarias_Test
* @Author   Luis González luisalberto.gonzalez.rojas@bbva.com
* @Date     2025-04-11
* @Group    Client & Group Mgm Tool
* -----------------------------------------------------------------------------------------------
* @Description Clase test que cubre las siguientes clases:
*			   - MX_CGMT_Subsidiarias_Ctrl
*              - MX_CGMT_Subsidiarias_Service
* -----------------------------------------------------------------------------------------------
* @Changes
* 2025-04-11   luisalberto.gonzalez.rojas@bbva.com
*              Creación de clase.
* -----------------------------------------------------------------------------------------------
*/
@isTest
public class MX_CGMT_Subsidiarias_Test {
    /**
    @Description Constante para definir el código del grupo
    @Author      Luis Alberto González Rojas - luisalberto.gonzalez.rojas@bbva.com
    **/
    final static String COD_GROUP = 'G20040920161014';
    /**
    @Description Constante para definir el parámetro input
    @Author      Luis Alberto González Rojas - luisalberto.gonzalez.rojas@bbva.com
    **/
    final static String INPUT_C = 'input';
    /**
    @Description Constante para definir el parámetro output
    @Author      Luis Alberto González Rojas - luisalberto.gonzalez.rojas@bbva.com
    **/
    final static String OUTPUT_C = 'output';
    /**
    @Description Constante para definir el parámetro options
    @Author      Luis Alberto González Rojas - luisalberto.gonzalez.rojas@bbva.com
    **/
    final static String OPTIONS_C = 'options';
    /**
    @Description Constante para definir el nombre la columna Page Size
    @Author      Luis Alberto González Rojas - luisalberto.gonzalez.rojas@bbva.com
    **/
    final static String P_SIZE = 'pageSize';
    /**
    @Description Constante para definir el nombre del parámetro holding-group-id
    @Author      Luis Alberto González Rojas - luisalberto.gonzalez.rojas@bbva.com
    **/
    final static String HOLDING = 'holdingGroupId';
    /**
    @Description Constante para definir el nombre del parámetro subsidiaryId
    @Author      Luis Alberto González Rojas - luisalberto.gonzalez.rojas@bbva.com
    **/
    final static String SUBID = 'subsidiaryId';
    /**
    @Description Constante para definir el nombre del parámetro paginationKey
    @Author      Luis Alberto González Rojas - luisalberto.gonzalez.rojas@bbva.com
    **/
    final static String P_KEY = 'paginationKey';
    /**
    @Description Constante para definir el nombre del method getTablesSubsidiaries
    @Author      Luis Alberto González Rojas - luisalberto.gonzalez.rojas@bbva.com
    **/
    final static String G_SUBSINFO = 'getTablesSubsidiaries';
    /**
    @Description Constante para definir el nombre del method getTablesPages getException
    @Author      Luis Alberto González Rojas - luisalberto.gonzalez.rojas@bbva.com
    **/
    final static String G_TABLESINFO = 'getTablesPages';
    /**
    @Description Constante para definir el nombre del method getException
    @Author      Luis Alberto González Rojas - luisalberto.gonzalez.rojas@bbva.com
    **/
    final static String G_EXCEPTION = 'getException';
    /**
    @Description Constante para definir el mensaje de resultado
    @Author      Luis Alberto González Rojas - luisalberto.gonzalez.rojas@bbva.com
    **/
    final static String MESSAGE = 'GroupCode not found';
    /**
    *-------------------------------------------------------------------------------------------------------
    * @Description Method dedicado a estructurar la información de la paginación en un mapa
    *-------------------------------------------------------------------------------------------------------
    * @Author      Luis González luisalberto.gonzalez.rojas@bbva.com
    * @Date        2025-04-11
    * @example     MX_CGMT_Subsidiarias_Test.makeData()
    **/
	@TestSetUp
    static void makeData() {
        DMT_Test_DataFactory.generateAccount();
        final Account cliente = [SELECT Id, Name FROM Account LIMIT 1];
        cliente.DES_Group_Code__c = COD_GROUP;
        update cliente;
    }    
    /**
    *-------------------------------------------------------------------------------------------------------
    * @Description Method que prueba el flujo para obtener información de las subsidiarias mediante ASO
    *-------------------------------------------------------------------------------------------------------
    * @Author      Luis González luisalberto.gonzalez.rojas@bbva.com
    * @Date        2025-04-11
    * @example     MX_CGMT_Subsidiarias_Test.testingDataSubsidiaries()
    **/
    @IsTest
    static void testingDataSubsidiaries() {
        final Account cliente = [SELECT Id, Name, DES_Group_Code__c FROM Account LIMIT 1];
        Map<String,Object> mapObjects =new Map<String,Object>();
        Map<String, Object> mapInput = new Map<String, Object>();
        Map<String, Object> mapOutput = new Map<String, Object>();
        Map<String, Object> mapOptions = new Map<String, Object>();
        mapInput.put(HOLDING,cliente.DES_Group_Code__c);
        mapInput.put(P_KEY, '1');
        mapInput.put(P_SIZE, null);
        mapInput.put(SUBID, null);
        mapObjects.put(INPUT_C,mapInput);
        mapObjects.put(OUTPUT_C,mapOutput);
        mapObjects.put(OPTIONS_C,mapOptions);
        MX_CGMT_Subsidiarias_Ctrl getSubsidiaries = new MX_CGMT_Subsidiarias_Ctrl();
        Test.startTest();
        Object result = getSubsidiaries.call(G_SUBSINFO, mapObjects);
        Test.stopTest();
        System.assertEquals(true, result != null, MESSAGE);
    }
    /**
    *-------------------------------------------------------------------------------------------------------
    * @Description Method que prueba el flujo para obtener información de la paginación mediante ASO
    *-------------------------------------------------------------------------------------------------------
    * @Author      Luis González luisalberto.gonzalez.rojas@bbva.com
    * @Date        2025-04-11
    * @example     MX_CGMT_Subsidiarias_Test.testingDataPagination()
    **/
    @IsTest
    static void testingDataPagination() {
        final Account cliente = [SELECT Id, Name, DES_Group_Code__c FROM Account LIMIT 1];
        Map<String,Object> mapObjects =new Map<String,Object>();
        Map<String, Object> mapInput = new Map<String, Object>();
        Map<String, Object> mapOutput = new Map<String, Object>();
        Map<String, Object> mapOptions = new Map<String, Object>();
        mapInput.put(HOLDING,cliente.DES_Group_Code__c);
        mapInput.put(P_KEY, '1');
        mapInput.put(P_SIZE, null);
        mapInput.put(SUBID, null);
        mapObjects.put(INPUT_C,mapInput);
        mapObjects.put(OUTPUT_C,mapOutput);
        mapObjects.put(OPTIONS_C,mapOptions);
        MX_CGMT_Subsidiarias_Ctrl getSubsidiaries = new MX_CGMT_Subsidiarias_Ctrl();
        Test.startTest();
        Object result = getSubsidiaries.call(G_TABLESINFO, mapObjects);
        Test.stopTest();
        System.assertEquals(true, result != null, MESSAGE);
    }
    /**
    *-------------------------------------------------------------------------------------------------------
    * @Description Method que prueba el flujo de excepciones
    *-------------------------------------------------------------------------------------------------------
    * @Author      Luis González luisalberto.gonzalez.rojas@bbva.com
    * @Date        2025-04-11
    * @example     MX_CGMT_Subsidiarias_Test.testingExceptions()
    **/
    @IsTest
    static void testingElse() {
        Map<String,Object> mapObjects =new Map<String,Object>();
        Map<String, Object> mapInput = new Map<String, Object>();
        Map<String, Object> mapOutput = new Map<String, Object>();
        Map<String, Object> mapOptions = new Map<String, Object>();
        mapInput.put(HOLDING, '');
        mapInput.put(P_KEY, '');
        mapInput.put(P_SIZE, null);
        mapInput.put(SUBID, null);
        mapObjects.put(INPUT_C,mapInput);
        mapObjects.put(OUTPUT_C,mapOutput);
        mapObjects.put(OPTIONS_C,mapOptions);
        MX_CGMT_Subsidiarias_Ctrl getSubsidiaries = new MX_CGMT_Subsidiarias_Ctrl();
        Test.startTest();
        Object result = getSubsidiaries.call(G_EXCEPTION, mapObjects);
        Test.stopTest();
        System.assertEquals(true, result != null, MESSAGE);
    }
    @IsTest
    static void testingException() {
        Map<String,Object> mapObjects =new Map<String,Object>();
        Map<String, Object> mapInput = new Map<String, Object>();
        Map<String, Object> mapOutput = new Map<String, Object>();
        Map<String, Object> mapOptions = new Map<String, Object>();
        mapInput.put('', '');
        mapInput.put('', '');
        mapInput.put('', null);
        mapInput.put('', null);
        mapObjects.put(INPUT_C, mapInput);
        mapObjects.put(OUTPUT_C, mapOutput);
        mapObjects.put(OPTIONS_C, mapOptions);
        MX_CGMT_Subsidiarias_Ctrl getSubsidiaries = new MX_CGMT_Subsidiarias_Ctrl();
        Test.startTest();
        Object result = getSubsidiaries.call(null, mapObjects);
        Test.stopTest();
        System.assertEquals(true, result != null, MESSAGE);
    }
}