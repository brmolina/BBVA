/**
 * --------------------------------------------------------------------------------------
 * @Name              : CLT_Get_Context_Test.cls
 * @Author            : Carlos Maqueda  carlosalberto.maqueda.maldona.contractor@bbva.com
 * @Date              : 2026-02-24
 * @Group             : CIB Global Desktop
 * --------------------------------------------------------------------------------------
 * @Description       : Clase test para la cobertura del desarrollo Get Status Request
 *                      CLT_My_Request_Ctrl.cls
 *                      CLT_My_Request_Service.cls
 * --------------------------------------------------------------------------------------
 * @Changes
 * 2026-02-24   carlosalberto.maqueda.maldona.contractor@bbva.com
 *              Versión inicial
 * ----------------------------------------------------------------------------------------------------------------------------
**/
@isTest
public with sharing class CLT_Get_Context_Test {
    /**
    * @Description: Nombre del Usuario
    * @Author:      carlosalberto.maqueda.maldona.contractor@bbva.com
    **/
    static final string STRUSERNAME = 'UserAdmin';
    /**
    * @Description: Perfil para asignar al usuario
    * @Author:      carlosalberto.maqueda.maldona.contractor@bbva.com
    **/
    static final string PROFILENAME = 'BBVA Standard User';
    /**
    * @Description: PermissonSet para uso del usurio
    * @Author:      carlosalberto.maqueda.maldona.contractor@bbva.com
    **/
    static final String STRPERMISION = 'client_info';
    /**
    * @Description: Límite para las consultas
    * @Author:      carlosalberto.maqueda.maldona.contractor@bbva.com
    **/
    final static Integer LIMITVALUE = 1;
    /**
    * @Description: Nombre del servicio
    * @Author:      carlosalberto.maqueda.maldona.contractor@bbva.com
    **/
    static final String SERVICENAME = 'IXMAS_Context_Request_PROD';
    /**
    * @Description: URL genérica para el testeo del servicio
    * @Author:      carlosalberto.maqueda.maldona.contractor@bbva.com
    **/
    final static String STRURL = 'https://www.example.com';
    /**
    * @Description: Asigna una partición IASO
    * @Author:      carlosalberto.maqueda.maldona.contractor@bbva.com
    **/
    final static String STRPARTITION = 'iaso.ServicesPartition';
    /**
    * @Description: Timeout del servicio
    * @Author:      carlosalberto.maqueda.maldona.contractor@bbva.com
    **/
    final static Integer TIMEOUT = 60000;
    /**
    * @Description: Valor falso para el cliente de prueba
    * @Author:      carlosalberto.maqueda.maldona.contractor@bbva.com
    **/
    final static Boolean BOOFALSE = False;
    /**
    * @Description: Valor del cacheTTLInSecs
    * @Author:      carlosalberto.maqueda.maldona.contractor@bbva.com
    **/
    final static Integer CACHETTL = 300;
    /**
    * @Description: Asigna un valor entero que representa un código 200 para enviarlo en el mock del servicio ASO
    * @Author:      carlosalberto.maqueda.maldona.contractor@bbva.com
    **/
    final static Integer CODEOK = 200;
    /**
    * @Description: Asigna un valor de cadena que representa un código 200
    * @Author:      carlosalberto.maqueda.maldona.contractor@bbva.com
    **/
    final static String CODEOKSTR = '200';
    /**
    * @Description: Mensaje de respuesta exitosa
    * @Author:      carlosalberto.maqueda.maldona.contractor@bbva.com
    **/
    final static String MSGINFOOK = 'Existe información';
    /**
    * @Description: Bandera en verdadero para pruebas
    * @Author:      carlosalberto.maqueda.maldona.contractor@bbva.com
    **/
    final static Boolean BOOTRUE = true;
    /**
    * @Description: Variable que asigna un valor entero que representa un código 400.
    * @Author:      carlosalberto.maqueda.maldona.contractor@bbva.com
    **/
    final static Integer CODEERROR = 400;
    /**
    * @Description: Variable que asigna un valor que representa un código 400.
    * @Author:      carlosalberto.maqueda.maldona.contractor@bbva.com
    **/
    final static String CODEERRORSTR = '400';

    /**
    * --------------------------------------------------------------------------------------------------------------------------
    * @Description Method para generar los datos de prueba que se usan en la clase test
    * --------------------------------------------------------------------------------------------------------------------------
    * @Author Carlos Maqueda   carlosalberto.maqueda.maldona.contractor@bbva.com
    * @Date   2026-03-04
    * --------------------------------------------------------------------------------------------------------------------------
    **/
    @testSetup static void setupData() {
        new CLT_Get_Conext_Role_Ctrl();
        new CLT_Get_Context_Role_Service();
        final User usuarioAdmin = New User();
        usuarioAdmin.Id = System.UserInfo.getUserId();
        System.runAs(usuarioAdmin) {
            final User usuarioEjecutivoCIB = Arc_UtilitysDataTest_tst.crearUsuario(STRUSERNAME,PROFILENAME,'');
            insert usuarioEjecutivoCIB;
            final PermissionSet psetOffer = [SELECT Id, Name FROM PermissionSet WHERE Name =: STRPERMISION LIMIT :LIMITVALUE];
            final PermissionSetAssignment asignacionPset = new PermissionSetAssignment(AssigneeId = usuarioEjecutivoCIB.Id, PermissionSetId = psetOffer.Id);
            insert asignacionPset;
        }
    }
    /**
    * --------------------------------------------------------------------------------------------------------------------------
    * @Description Method para generar los datos de prueba para el servicio de IXMAS_Context_Request_PROD que se usan en la clase test
    * --------------------------------------------------------------------------------------------------------------------------
    * @Author Carlos Alberto Maqueda Maldonado   carlosalberto.maqueda.maldona.contractor@bbva.com
    * @Date   2026-03-04
    * --------------------------------------------------------------------------------------------------------------------------
    **/
    public static void createSettings() {
        final bbvacon__GBL_Rest_Services_Url__c iasoSrv = new bbvacon__GBL_Rest_Services_Url__c(
            Name=SERVICENAME, 
            bbvacon__Cache_Partition__c=STRPARTITION,
            bbvacon__Timeout__c=TIMEOUT, 
            bbvacon__Url__c=STRURL,
            bbvacon__isCacheInOrg__c=BOOFALSE, 
            bbvacon__cacheTTLInSecs__c=CACHETTL
        );
        insert new List<bbvacon__GBL_Rest_Services_Url__c> {iasoSrv};
    }
    /**
    * --------------------------------------------------------------------------------------------------------------------------
    * @Description Genera el Mock para dar cobertura a la clase CLT_Get_Conext_Role_Ctrl.getRolesMembers
    * --------------------------------------------------------------------------------------------------------------------------
    * @Author Carlos Alberto Maqueda Maldonado   carlosalberto.maqueda.maldona.contractor@bbva.com
    * @Date   2026-03-04
    * --------------------------------------------------------------------------------------------------------------------------
    **/
    class MockHttpGetRolesOk implements HttpCalloutMock {
        /**
        * --------------------------------------------------------------------------------------
        * @Description Clase que simula la respuesta del servicio de IXMAS_Context_Request_PROD con ÉXITO
        * --------------------------------------------------------------------------------------
        * @Author Carlos Maqueda   carlosalberto.maqueda.maldona.contractor@bbva.com
        * @Date   2026-03-04
        * @param  req Solicitud HTTP que se envía al servicio simulado
        * @return HttpResponse Respuesta HTTP simulada del servicio
        * @example respond(req)
        * --------------------------------------------------------------------------------------
        **/
        public HttpResponse respond(HttpRequest req) {
            final String mockBody = [SELECT Id,bbvacon__Mock_LTA__c, DeveloperName FROM bbvacon__GBL_integration_service__mdt WHERE DeveloperName =: SERVICENAME LIMIT :LIMITVALUE].bbvacon__Mock_LTA__c;
            final HttpResponse res = new HttpResponse();
            res.setStatusCode(CODEOK);
            res.setBody(mockBody);
            return res;
        }
    }
    /**
    * --------------------------------------------------------------------------------------------------------------------------
    * @Description Genera Mock para dar cobertura erroneo a la clase CLT_Get_Conext_Role_Ctrl.getRolesMembers
    * --------------------------------------------------------------------------------------------------------------------------
    * @Author Carlos Alberto Maqueda Maldonado   carlosalberto.maqueda.maldona.contractor@bbva.com
    * @Date   2026-03-04
    * --------------------------------------------------------------------------------------------------------------------------
    **/
    class MockHttpGetRolesError implements HttpCalloutMock {
        /**
        * --------------------------------------------------------------------------------------
        * @Description Clase que simula la respuesta del servicio de IXMAS_Context_Request_PROD con ERROR
        * --------------------------------------------------------------------------------------
        * @Author Carlos Maqueda   carlosalberto.maqueda.maldona.contractor@bbva.com
        * @Date   2026-03-04
        * @param  req Solicitud HTTP que se envía al servicio simulado
        * @return HttpResponse Respuesta HTTP simulada del servicio
        * @example respond(req)
        * --------------------------------------------------------------------------------------
        **/
        public HttpResponse respond(HttpRequest req) {
            final String mockBody = [SELECT Id,bbvacon__Mock_LTA__c, DeveloperName FROM bbvacon__GBL_integration_service__mdt WHERE DeveloperName =: SERVICENAME LIMIT :LIMITVALUE].bbvacon__Mock_LTA__c;
            final HttpResponse res = new HttpResponse();
            res.setStatusCode(CODEERROR);
            res.setBody(mockBody);
            return res;
        }
    }

    /**
    * --------------------------------------------------------------------------------------------------------------------------
    * @Description Ejecuta prueba para dar cobertura a la clase CLT_Get_Conext_Role_Ctrl.getRolesMembers
    * --------------------------------------------------------------------------------------------------------------------------
    * @Author Carlos Alberto Maqueda Maldonado   carlosalberto.maqueda.maldona.contractor@bbva.com
    * @Date   2026-03-04
    * --------------------------------------------------------------------------------------------------------------------------
    **/
    @isTest
    static void getRolesMembersOk() {
        createSettings();
        final User ejecutivoCIB = [SELECT Id, Name FROM User WHERE Name =: STRUSERNAME LIMIT :LIMITVALUE];
        Test.setMock(HttpCalloutMock.class, new MockHttpGetRolesOk());
        Test.startTest();
        bbvacon.GBL_Mock.setMock(new MockHttpGetRolesOk());
        System.runAs(ejecutivoCIB) {
            CLT_Get_Conext_Role_Ctrl.FlowInput input = new CLT_Get_Conext_Role_Ctrl.FlowInput();
            input.mode = 'ASSIGNED';
            input.numClient = 'G00000000000351';
            input.numUser = 'T037641';
            List<CLT_Get_Conext_Role_Ctrl.FlowOutput> responseService = CLT_Get_Conext_Role_Ctrl.getRolesMembers(new List<CLT_Get_Conext_Role_Ctrl.FlowInput>{input});
            System.assertEquals(responseService.tostring().contains(CODEOKSTR), BOOTRUE, MSGINFOOK);
        }
        Test.stopTest();
    }

    /**
    * --------------------------------------------------------------------------------------------------------------------------
    * @Description Ejecuta prueba erronea para cobertura a la clase CLT_Get_Conext_Role_Ctrl.getRolesMembers
    * --------------------------------------------------------------------------------------------------------------------------
    * @Author Carlos Alberto Maqueda Maldonado   carlosalberto.maqueda.maldona.contractor@bbva.com
    * @Date   2026-03-04
    * --------------------------------------------------------------------------------------------------------------------------
    **/
    @isTest
    static void getRolesMembersError() {
        createSettings();
        final User ejecutivoCIB = [SELECT Id, Name FROM User WHERE Name =: STRUSERNAME LIMIT :LIMITVALUE];
        Test.setMock(HttpCalloutMock.class, new MockHttpGetRolesError());
        Test.startTest();
        bbvacon.GBL_Mock.setMock(new MockHttpGetRolesError());
        System.runAs(ejecutivoCIB) {
            CLT_Get_Conext_Role_Ctrl.FlowInput input = new CLT_Get_Conext_Role_Ctrl.FlowInput();
            input.mode = 'ASSIGNED';
            input.numClient = 'G00000000000351';
            input.numUser = 'T037641';
            List<CLT_Get_Conext_Role_Ctrl.FlowOutput> responseService = CLT_Get_Conext_Role_Ctrl.getRolesMembers(new List<CLT_Get_Conext_Role_Ctrl.FlowInput>{input});
            System.assertEquals(responseService.tostring().contains(CODEERRORSTR), BOOTRUE, MSGINFOOK);
        }
        Test.stopTest();
    }
}