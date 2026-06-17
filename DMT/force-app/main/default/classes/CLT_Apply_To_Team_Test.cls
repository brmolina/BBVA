/**
 * --------------------------------------------------------------------------------------
 * @Name              : CLT_Apply_To_Team_Test.cls
 * @Author            : Carlos Maqueda  carlosalberto.maqueda.maldona.contractor@bbva.com
 * @Date              : 2026-03-04
 * @Group             : CIB Global Desktop
 * --------------------------------------------------------------------------------------
 * @Description       : Clase test para la cobertura del desarrollo Get Status Request
 *                      CLT_Apply_To_Team_Member_Ctrl.cls
 *                      CLT_Apply_To_Team_Member_Service.cls
 * --------------------------------------------------------------------------------------
 * @Changes
 * 2026-03-04   carlosalberto.maqueda.maldona.contractor@bbva.com
 *              Versión inicial
 * ----------------------------------------------------------------------------------------------------------------------------
**/
@isTest
public with sharing class CLT_Apply_To_Team_Test {
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
    * @Description: Nombre del Servicio para dar de baja
    * @Author:      carlosalberto.maqueda.maldona.contractor@bbva.com
    **/
    static final String SERVICENAME_ASSIGNED = 'IXMAS_Cancel_Request_PROD';
    /**
    * @Description: Nombre del Servicio para dar de alta
    * @Author:      carlosalberto.maqueda.maldona.contractor@bbva.com
    **/
    static final String SERVICENAME_UNASSIGNED = 'IXMAS_Apply_Request_PROD';
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
        new CLT_My_Request_Ctrl();
        new CLT_My_Request_Service();
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
    * @Description Method para generar los datos de prueba para el servicio de IXMAS_Cancel_Request_PROD que se usan en la clase test
    * --------------------------------------------------------------------------------------------------------------------------
    * @Author Carlos Maqueda   carlosalberto.maqueda.maldona.contractor@bbva.com
    * @Date   2026-03-04
    * --------------------------------------------------------------------------------------------------------------------------
    **/
    public static void createSettingsASSIGNED() {
        final bbvacon__GBL_Rest_Services_Url__c iasoSrvAssigned = new bbvacon__GBL_Rest_Services_Url__c(
            Name=SERVICENAME_ASSIGNED, 
            bbvacon__Cache_Partition__c=STRPARTITION,
            bbvacon__Timeout__c=TIMEOUT, 
            bbvacon__Url__c=STRURL,
            bbvacon__isCacheInOrg__c=BOOFALSE, 
            bbvacon__cacheTTLInSecs__c=CACHETTL
        );
        insert new List<bbvacon__GBL_Rest_Services_Url__c> {iasoSrvAssigned};
    }
    /**
    * --------------------------------------------------------------------------------------------------------------------------
    * @Description Method para generar datos de prueba para servicio de IXMAS_Apply_Request_PROD que se usan en la clase test
    * --------------------------------------------------------------------------------------------------------------------------
    * @Author Carlos Maqueda   carlosalberto.maqueda.maldona.contractor@bbva.com
    * @Date   2026-03-04
    * --------------------------------------------------------------------------------------------------------------------------
    **/
    public static void createSettingsUNASSIGNED() {
        final bbvacon__GBL_Rest_Services_Url__c iasoSrvUnassigned = new bbvacon__GBL_Rest_Services_Url__c(
            Name=SERVICENAME_UNASSIGNED, 
            bbvacon__Cache_Partition__c=STRPARTITION,
            bbvacon__Timeout__c=TIMEOUT, 
            bbvacon__Url__c=STRURL,
            bbvacon__isCacheInOrg__c=BOOFALSE, 
            bbvacon__cacheTTLInSecs__c=CACHETTL
        );
        insert new List<bbvacon__GBL_Rest_Services_Url__c> {iasoSrvUnassigned};
    }
    /**
    * --------------------------------------------------------------------------------------------------------------------------
    * @Description Genera el Mock para dar cobertura a la clase CLT_Apply_To_Team_Member_Ctrl.submitApplyCtrl
    * --------------------------------------------------------------------------------------------------------------------------
    * @Author Carlos Maqueda   carlosalberto.maqueda.maldona.contractor@bbva.com
    * @Date   2026-03-04
    * --------------------------------------------------------------------------------------------------------------------------
    **/
    class MockHttpAplyAssignedOk implements HttpCalloutMock {
        /**
        * --------------------------------------------------------------------------------------
        * @Description Clase que simula la respuesta del servicio de IXMAS_Cancel_Request_PROD con ÉXITO
        * --------------------------------------------------------------------------------------
        * @Author Carlos Maqueda   carlosalberto.maqueda.maldona.contractor@bbva.com
        * @Date   2026-03-04
        * @param  req Solicitud HTTP que se envía al servicio simulado
        * @return HttpResponse Respuesta HTTP simulada del servicio
        * @example respond(req)
        * --------------------------------------------------------------------------------------
        **/
        public HttpResponse respond(HttpRequest req) {
            final String mockBody = [SELECT Id,bbvacon__Mock_LTA__c, DeveloperName FROM bbvacon__GBL_integration_service__mdt WHERE DeveloperName =: SERVICENAME_ASSIGNED LIMIT :LIMITVALUE].bbvacon__Mock_LTA__c;
            final HttpResponse res = new HttpResponse();
            res.setStatusCode(CODEOK);
            res.setBody(mockBody);
            return res;
        }
    }
    /**
    * --------------------------------------------------------------------------------------------------------------------------
    * @Description Genera el Mock para dar cobertura a la clase CLT_Apply_To_Team_Member_Ctrl.submitApplyCtrl
    * --------------------------------------------------------------------------------------------------------------------------
    * @Author Carlos Alberto Maqueda Maldonado   carlosalberto.maqueda.maldona.contractor@bbva.com
    * @Date   2026-03-04
    * --------------------------------------------------------------------------------------------------------------------------
    **/
    class MockHttpAplyUnassignedOk implements HttpCalloutMock {
        /**
        * --------------------------------------------------------------------------------------
        * @Description Clase que simula la respuesta del servicio de IXMAS_Apply_Request_PROD con ÉXITO
        * --------------------------------------------------------------------------------------
        * @Author Carlos Maqueda   carlosalberto.maqueda.maldona.contractor@bbva.com
        * @Date   2026-03-04
        * @param  req Solicitud HTTP que se envía al servicio simulado
        * @return HttpResponse Respuesta HTTP simulada del servicio
        * @example respond(req)
        * --------------------------------------------------------------------------------------
        **/
        public HttpResponse respond(HttpRequest req) {
            final String mockBody = [SELECT Id,bbvacon__Mock_LTA__c, DeveloperName FROM bbvacon__GBL_integration_service__mdt WHERE DeveloperName =: SERVICENAME_UNASSIGNED LIMIT :LIMITVALUE].bbvacon__Mock_LTA__c;
            final HttpResponse res = new HttpResponse();
            res.setStatusCode(CODEOK);
            res.setBody(mockBody);
            return res;
        }
    }
    /**
    * --------------------------------------------------------------------------------------------------------------------------
    * @Description Genera Mock para dar cobertura erroneo a la clase CLT_Apply_To_Team_Member_Ctrl.submitApplyCtrl
    * --------------------------------------------------------------------------------------------------------------------------
    * @Author Carlos Alberto Maqueda Maldonado   carlosalberto.maqueda.maldona.contractor@bbva.com
    * @Date   2026-03-04
    * --------------------------------------------------------------------------------------------------------------------------
    **/
    class MockHttpAplyUnassignedError implements HttpCalloutMock {
        /**
        * --------------------------------------------------------------------------------------
        * @Description Clase que simula la respuesta del servicio de IXMAS_Apply_Request_PROD con ERROR
        * --------------------------------------------------------------------------------------
        * @Author Carlos Maqueda   carlosalberto.maqueda.maldona.contractor@bbva.com
        * @Date   2026-03-04
        * @param  req Solicitud HTTP que se envía al servicio simulado
        * @return HttpResponse Respuesta HTTP simulada del servicio
        * @example respond(req)
        * --------------------------------------------------------------------------------------
        **/
        public HttpResponse respond(HttpRequest req) {
            final String mockBody = [SELECT Id,bbvacon__Mock_LTA__c, DeveloperName FROM bbvacon__GBL_integration_service__mdt WHERE DeveloperName =: SERVICENAME_UNASSIGNED LIMIT :LIMITVALUE].bbvacon__Mock_LTA__c;
            final HttpResponse res = new HttpResponse();
            res.setStatusCode(CODEERROR);
            res.setBody(mockBody);
            return res;
        }
    }

    /**
    * --------------------------------------------------------------------------------------------------------------------------
    * @Description Ejecuta prueba para dar cobertura a la clase CLT_Apply_To_Team_Member_Ctrl.submitApplyCtrl con rol Generico
    * --------------------------------------------------------------------------------------------------------------------------
    * @Author Carlos Alberto Maqueda Maldonado   carlosalberto.maqueda.maldona.contractor@bbva.com
    * @Date   2026-03-04
    * --------------------------------------------------------------------------------------------------------------------------
    **/
    @isTest
    static void submitApplyCtrlGlobalRoleOk() {
        createSettingsUNASSIGNED();
        final User ejecutivoCIB = [SELECT Id, Name FROM User WHERE Name =: STRUSERNAME LIMIT :LIMITVALUE];
        Test.setMock(HttpCalloutMock.class, new MockHttpAplyUnassignedOk());
        Test.startTest();
        bbvacon.GBL_Mock.setMock(new MockHttpAplyUnassignedOk());
        System.runAs(ejecutivoCIB) {
            CLT_Apply_To_Team_Member_Ctrl.FlowInput input = new CLT_Apply_To_Team_Member_Ctrl.FlowInput();
            input.idUser = 'T037641';
            input.idRequestedBy = 'T037641';
            input.idCompany = 'G00000000010767';
            input.idRole = 'RGB';
            input.comment = 'Prueba';
            input.mode = 'UNASSIGNED';
            List<CLT_Apply_To_Team_Member_Ctrl.FlowOutput> responseService = CLT_Apply_To_Team_Member_Ctrl.submitApplyCtrl(new List<CLT_Apply_To_Team_Member_Ctrl.FlowInput>{input});
            System.assertEquals(responseService.tostring().contains(CODEOKSTR), BOOTRUE, MSGINFOOK);
        }
        Test.stopTest();
    }

    /**
    * --------------------------------------------------------------------------------------------------------------------------
    * @Description Ejecuta prueba para la clase CLT_Apply_To_Team_Member_Ctrl.submitApplyCtrl con rol Generico con Error
    * --------------------------------------------------------------------------------------------------------------------------
    * @Author Carlos Alberto Maqueda Maldonado   carlosalberto.maqueda.maldona.contractor@bbva.com
    * @Date   2026-03-04
    * --------------------------------------------------------------------------------------------------------------------------
    **/
    @isTest
    static void submitApplyCtrlGlobalRoleError() {
        createSettingsUNASSIGNED();
        final User ejecutivoCIB = [SELECT Id, Name FROM User WHERE Name =: STRUSERNAME LIMIT :LIMITVALUE];
        Test.setMock(HttpCalloutMock.class, new MockHttpAplyUnassignedError());
        Test.startTest();
        bbvacon.GBL_Mock.setMock(new MockHttpAplyUnassignedError());
        System.runAs(ejecutivoCIB) {
            CLT_Apply_To_Team_Member_Ctrl.FlowInput input = new CLT_Apply_To_Team_Member_Ctrl.FlowInput();
            input.idUser = 'T037641';
            input.idRequestedBy = 'T037641';
            input.idCompany = 'G00000000010767';
            input.idRole = 'RGB';
            input.comment = 'Prueba';
            input.mode = 'UNASSIGNED';
            List<CLT_Apply_To_Team_Member_Ctrl.FlowOutput> responseService = CLT_Apply_To_Team_Member_Ctrl.submitApplyCtrl(new List<CLT_Apply_To_Team_Member_Ctrl.FlowInput>{input});
            System.assertEquals(responseService.tostring().contains(CODEERRORSTR), BOOTRUE, MSGINFOOK);
        }
        Test.stopTest();
    }

    /**
    * --------------------------------------------------------------------------------------------------------------------------
    * @Description Ejecuta prueba para dar cobertura a la clase CLT_Apply_To_Team_Member_Ctrl.submitApplyCtrl con rol RTB
    * --------------------------------------------------------------------------------------------------------------------------
    * @Author Carlos Alberto Maqueda Maldonado   carlosalberto.maqueda.maldona.contractor@bbva.com
    * @Date   2026-03-04
    * --------------------------------------------------------------------------------------------------------------------------
    **/
    @isTest
    static void submitApplyCtrlRTBOk() {
        createSettingsUNASSIGNED();
        final User ejecutivoCIB = [SELECT Id, Name FROM User WHERE Name =: STRUSERNAME LIMIT :LIMITVALUE];
        Test.setMock(HttpCalloutMock.class, new MockHttpAplyUnassignedOk());
        Test.startTest();
        bbvacon.GBL_Mock.setMock(new MockHttpAplyUnassignedOk());
        System.runAs(ejecutivoCIB) {
            CLT_Apply_To_Team_Member_Ctrl.FlowInput input = new CLT_Apply_To_Team_Member_Ctrl.FlowInput();
            input.idUser = 'T037641';
            input.idRequestedBy = 'T037641';
            input.idCompany = 'G00000000010767';
            input.idRole = 'RTB';
            input.comment = 'Prueba';
            input.mode = 'UNASSIGNED';
            input.idOffice = '4646';
            input.singleDual = 'SI';
            List<CLT_Apply_To_Team_Member_Ctrl.FlowOutput> responseService = CLT_Apply_To_Team_Member_Ctrl.submitApplyCtrl(new List<CLT_Apply_To_Team_Member_Ctrl.FlowInput>{input});
            System.assertEquals(responseService.tostring().contains(CODEOKSTR), BOOTRUE, MSGINFOOK);
        }
        Test.stopTest();
    }
   
    /**
    * --------------------------------------------------------------------------------------------------------------------------
    * @Description Ejecuta prueba para dar cobertura a la clase CLT_Apply_To_Team_Member_Ctrl.submitApplyCtrl con rol RRB
    * --------------------------------------------------------------------------------------------------------------------------
    * @Author Carlos Alberto Maqueda Maldonado   carlosalberto.maqueda.maldona.contractor@bbva.com
    * @Date   2026-03-04
    * --------------------------------------------------------------------------------------------------------------------------
    **/
    @isTest
    static void submitApplyCtrlRRBOk() {
        createSettingsUNASSIGNED();
        final User ejecutivoCIB = [SELECT Id, Name FROM User WHERE Name =: STRUSERNAME LIMIT :LIMITVALUE];
        Test.setMock(HttpCalloutMock.class, new MockHttpAplyUnassignedOk());
        Test.startTest();
        bbvacon.GBL_Mock.setMock(new MockHttpAplyUnassignedOk());
        System.runAs(ejecutivoCIB) {
            CLT_Apply_To_Team_Member_Ctrl.FlowInput input = new CLT_Apply_To_Team_Member_Ctrl.FlowInput();
            input.idUser = 'T037641';
            input.idRequestedBy = 'T037641';
            input.idCompany = 'G00000000010767';
            input.idRole = 'RRB';
            input.comment = 'Prueba';
            input.mode = 'UNASSIGNED';
            input.idMacroRegion = '4646';
            List<CLT_Apply_To_Team_Member_Ctrl.FlowOutput> responseService = CLT_Apply_To_Team_Member_Ctrl.submitApplyCtrl(new List<CLT_Apply_To_Team_Member_Ctrl.FlowInput>{input});
            System.assertEquals(responseService.tostring().contains(CODEOKSTR), BOOTRUE, MSGINFOOK);
        }
        Test.stopTest();
    }

    /**
    * --------------------------------------------------------------------------------------------------------------------------
    * @Description Ejecuta prueba para dar cobertura a la clase CLT_Apply_To_Team_Member_Ctrl.submitApplyCtrl con rol RLB
    * --------------------------------------------------------------------------------------------------------------------------
    * @Author Carlos Alberto Maqueda Maldonado   carlosalberto.maqueda.maldona.contractor@bbva.com
    * @Date   2026-03-04
    * --------------------------------------------------------------------------------------------------------------------------
    **/
    @isTest
    static void submitApplyCtrlRLBOk() {
        createSettingsUNASSIGNED();
        final User ejecutivoCIB = [SELECT Id, Name FROM User WHERE Name =: STRUSERNAME LIMIT :LIMITVALUE];
        Test.setMock(HttpCalloutMock.class, new MockHttpAplyUnassignedOk());
        Test.startTest();
        bbvacon.GBL_Mock.setMock(new MockHttpAplyUnassignedOk());
        System.runAs(ejecutivoCIB) {
            CLT_Apply_To_Team_Member_Ctrl.FlowInput input = new CLT_Apply_To_Team_Member_Ctrl.FlowInput();
            input.idUser = 'T037641';
            input.idRequestedBy = 'T037641';
            input.idCompany = 'G00000000010767';
            input.idRole = 'RLB';
            input.comment = 'Prueba';
            input.mode = 'UNASSIGNED';
            input.idSubsidiary = 'A02296046,A02373014';
            List<CLT_Apply_To_Team_Member_Ctrl.FlowOutput> responseService = CLT_Apply_To_Team_Member_Ctrl.submitApplyCtrl(new List<CLT_Apply_To_Team_Member_Ctrl.FlowInput>{input});
            System.assertEquals(responseService.tostring().contains(CODEOKSTR), BOOTRUE, MSGINFOOK);
        }
        Test.stopTest();
    }
    /**
    * --------------------------------------------------------------------------------------------------------------------------
    * @Description Ejecuta prueba la clase CLT_Apply_To_Team_Member_Ctrl.submitApplyCtrl con rol General y Cancel
    * --------------------------------------------------------------------------------------------------------------------------
    * @Author Carlos Alberto Maqueda Maldonado   carlosalberto.maqueda.maldona.contractor@bbva.com
    * @Date   2026-03-04
    * --------------------------------------------------------------------------------------------------------------------------
    **/
    @isTest
    static void submitGlobalRoleAssignOk() {
        createSettingsASSIGNED();
        final User ejecutivoCIB = [SELECT Id, Name FROM User WHERE Name =: STRUSERNAME LIMIT :LIMITVALUE];
        Test.setMock(HttpCalloutMock.class, new MockHttpAplyAssignedOk());
        Test.startTest();
        bbvacon.GBL_Mock.setMock(new MockHttpAplyAssignedOk());
        System.runAs(ejecutivoCIB) {
            CLT_Apply_To_Team_Member_Ctrl.FlowInput input = new CLT_Apply_To_Team_Member_Ctrl.FlowInput();
            input.idUser = 'T037641';
            input.idRequestedBy = 'T037641';
            input.idCompany = 'G00000000010767';
            input.idRole = 'RGB';
            input.comment = 'Prueba';
            input.mode = 'ASSIGNED';
            List<CLT_Apply_To_Team_Member_Ctrl.FlowOutput> responseService = CLT_Apply_To_Team_Member_Ctrl.submitApplyCtrl(new List<CLT_Apply_To_Team_Member_Ctrl.FlowInput>{input});
            System.assertEquals(responseService.tostring().contains(CODEOKSTR), BOOTRUE, MSGINFOOK);
        }
        Test.stopTest();
    }
}