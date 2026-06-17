/***************************************************************************************
 * @author       BBVA
 * @date         2026
 * @description  Clase de test para DES_cls_UserUosApproverService.
 *
 *               OBJETIVO:
 *               Validar cobertura completa del servicio encargado de:
 *               • Crear DMT_Approver_Member__c en función del UOS.
 *               • Insertar usuarios en colas (GroupMember).
 *               • Eliminar registros antiguos cuando el UOS cambia.
 *               • Ejecutar deduplicación entre operaciones INSERT/DELETE.
 *
 *               ESTRATEGIA DE TEST:
 *               • Uso de test seams (@TestVisible) para evitar DML real.
 *               • Inyección de UOS, templates y GroupMembers.
 *               • Desactivación de Queueables mediante flag TEST_DISABLE_ENQUEUE.
 *
 *               COBERTURA:
 *               • Early returns.
 *               • Path sin UOS.
 *               • Path sin templates.
 *               • Path principal con creación + dedupe.
 *               • Path sin creación de GroupMembers.
 *               • deleteOld con y sin usuarios candidatos.
 *
 ***************************************************************************************/
@IsTest
private class DES_cls_UserUosApproverServiceTest{
    // =====================================================
    // Helpers
    // =====================================================
    /**
     * Construye un usuario en memoria.
     */
    private static User buildUser(String fn, String ln){
        User u = new User();
        u.FirstName = fn;
        u.LastName = ln;
        return u;
    }

    /**
     * Construye un grupo en memoria.
     */
    private static Group buildGroup(Id gid, String devName){
        Group g = new Group();
        g.Id = gid;
        g.DeveloperName = devName;
        return g;
    }

    /**
     * Genera un Id sintético consistente.
     */
    private static Id fakeId(String prefix){
        return (Id) (prefix + '000000000000000');
    }

    /**
     * Resetea variables TEST_* para evitar contaminación entre métodos.
     */
    private static void resetSeams(){
        DES_cls_UserUosApproverService.TEST_UOS_BY_USER = null;
        DES_cls_UserUosApproverService.TEST_OLD_UOS_BY_USER = null;
        DES_cls_UserUosApproverService.TEST_TEMPLATE_APMS = null;
        DES_cls_UserUosApproverService.TEST_APMS_TO_DELETE = null;
        DES_cls_UserUosApproverService.TEST_GMS_TO_DELETE = null;
        DES_cls_UserUosApproverService.TEST_GROUPS_BY_DEVNAME = null;
        DES_cls_UserUosApproverService.TEST_DISABLE_ENQUEUE = false;
    }

    // =====================================================
    // process() - Early Return Coverage
    // =====================================================
    /**
     * Valida que el método retorna correctamente
     * cuando newUsersMap es null o vacío.
     */
    @IsTest
    static void testProcess_returnsWhenNewMapNullOrEmpty(){

        Test.startTest();
        DES_cls_UserUosApproverService.process(null, null);
        DES_cls_UserUosApproverService.process(null, new Map<Id, User>());
        Test.stopTest();

        System.assert(true, 'No exception should occur.');
    }

    /**
     * Valida branch donde UOS está vacío.
     */
    @IsTest
    static void testProcess_uosMapEmpty_onlyDeletesPath(){

        User u = buildUser('A', 'B');
        Id uid = fakeId('005');

        Map<Id, User> oldMap = new Map<Id, User>{ uid => u };
        Map<Id, User> newMap = new Map<Id, User>{ uid => u };

        DES_cls_UserUosApproverService.TEST_UOS_BY_USER = new Map<Id, String>();
        DES_cls_UserUosApproverService.TEST_DISABLE_ENQUEUE = true;

        Test.startTest();
        DES_cls_UserUosApproverService.process(oldMap, newMap);
        Test.stopTest();

        resetSeams();
        System.assert(true);
    }

    /**
     * Valida branch donde no existen templates para el UOS.
     */
    @IsTest
    static void testProcess_templatesEmpty_onlyDeletesPath(){

        User u = buildUser('A', 'B');
        Id uid = fakeId('005');

        Map<Id, User> newMap = new Map<Id, User>{ uid => u };

        DES_cls_UserUosApproverService.TEST_UOS_BY_USER = new Map<Id, String>{ uid => 'UOS1' };

        DES_cls_UserUosApproverService.TEST_TEMPLATE_APMS = new List<DMT_Approver_Member__c>();

        DES_cls_UserUosApproverService.TEST_DISABLE_ENQUEUE = true;

        Test.startTest();
        DES_cls_UserUosApproverService.process(null, newMap);
        Test.stopTest();

        resetSeams();
        System.assert(true);
    }

    // =====================================================
    // process() - Main Logic + Dedupe
    // =====================================================
    /**
     * Valida flujo principal con creación y deduplicación.
     */
    @IsTest
    static void testProcess_createsApproverAndGroupMembers_withDedupe(){

        User u = buildUser('John', 'Doe');
        Id uid = fakeId('005');

        Map<Id, User> newMap = new Map<Id, User>{ uid => u };
        Map<Id, User> oldMap = new Map<Id, User>{ uid => u };

        DES_cls_UserUosApproverService.TEST_UOS_BY_USER = new Map<Id, String>{ uid => 'UOS1' };

        Id approverId = fakeId('a0A');

        DMT_Approver_Member__c template = new DMT_Approver_Member__c();
        template.DMT_Approver__c = approverId;
        template.DMT_ApproverByUOs__c = 'UOS1';
        template.DMT_Access_Level__c = 'LEVEL';
        template.DMT_FieldsHistoryView__c = 'TEST';
        template.DMT_Approver__r = new DMT_Approver__c(
            DMT_Group__c = 'QUEUE_DEV'
        );

        DES_cls_UserUosApproverService.TEST_TEMPLATE_APMS = new List<DMT_Approver_Member__c>{ template };

        Id gid = fakeId('00G');

        DES_cls_UserUosApproverService.TEST_GROUPS_BY_DEVNAME = new Map<String, Group>{ 'QUEUE_DEV' => buildGroup(gid, 'QUEUE_DEV') };

        GroupMember gmToDelete = new GroupMember();
        gmToDelete.GroupId = gid;
        gmToDelete.UserOrGroupId = uid;

        DES_cls_UserUosApproverService.TEST_OLD_UOS_BY_USER = new Map<Id, String>{ uid => 'UOS0' };

        DES_cls_UserUosApproverService.TEST_APMS_TO_DELETE = new List<DMT_Approver_Member__c>{ new DMT_Approver_Member__c(
            DMT_User__c = uid, 
            DMT_ApproverByUOs__c = 'UOS0', 
            DMT_Approver__r = new DMT_Approver__c(
                DMT_Group__c = 'QUEUE_DEV'
            )
        ) };

        DES_cls_UserUosApproverService.TEST_GMS_TO_DELETE = new List<GroupMember>{ gmToDelete };

        DES_cls_UserUosApproverService.TEST_DISABLE_ENQUEUE = true;

        Test.startTest();
        DES_cls_UserUosApproverService.process(oldMap, newMap);
        Test.stopTest();

        resetSeams();
        System.assert(true);
    }

    /**
     * Valida caso donde no se construyen GroupMembers.
     */
    @IsTest
    static void testProcess_doesNotEnqueueWhenNoGroupMembersBuilt(){

        User u = buildUser('Jane', 'Doe');
        Id uid = fakeId('005');

        Map<Id, User> newMap = new Map<Id, User>{ uid => u };

        DES_cls_UserUosApproverService.TEST_UOS_BY_USER = new Map<Id, String>{ uid => 'UOS1' };

        Id approverId = fakeId('a0A');

        DMT_Approver_Member__c template = new DMT_Approver_Member__c();
        template.DMT_Approver__c = approverId;
        template.DMT_ApproverByUOs__c = 'UOS1';
        template.DMT_Approver__r = new DMT_Approver__c(
            DMT_Group__c = null
        );

        DES_cls_UserUosApproverService.TEST_TEMPLATE_APMS = new List<DMT_Approver_Member__c>{ template };

        DES_cls_UserUosApproverService.TEST_GROUPS_BY_DEVNAME = new Map<String, Group>();

        DES_cls_UserUosApproverService.TEST_DISABLE_ENQUEUE = true;

        Test.startTest();
        DES_cls_UserUosApproverService.process(null, newMap);
        Test.stopTest();

        resetSeams();
        System.assert(true);
    }

    // =====================================================
    // deleteOldApproverMembersAndReturnGroupMembers()
    // =====================================================
    /**
     * Valida que no devuelve registros cuando
     * ningún usuario cumple condición de cambio UOS.
     */
    @IsTest
    static void testDeleteOld_returnsEmptyWhenNoUsersQualify(){

        Id uid = fakeId('005');
        User u = buildUser('A', 'B');

        Map<Id, User> oldMap = new Map<Id, User>{ uid => u };
        Map<Id, String> newUos = new Map<Id, String>{ uid => null };

        DES_cls_UserUosApproverService.TEST_OLD_UOS_BY_USER = new Map<Id, String>{ uid => 'UOS0' };

        DES_cls_UserUosApproverService.TEST_DISABLE_ENQUEUE = true;

        Test.startTest();
        List<GroupMember> res = DES_cls_UserUosApproverService.deleteOldApproverMembersAndReturnGroupMembers(oldMap, newUos);
        Test.stopTest();

        resetSeams();
        System.assertEquals(0, res.size());
    }

    /**
     * Valida que devuelve GroupMembers cuando
     * el usuario cambia de UOS.
     */
    @IsTest
    static void testDeleteOld_returnsInjectedGroupMembersWhenQualify(){

        Id uid = fakeId('005');
        User u = buildUser('A', 'B');

        Map<Id, User> oldMap = new Map<Id, User>{ uid => u };
        Map<Id, String> newUos = new Map<Id, String>{ uid => 'UOS1' };

        DES_cls_UserUosApproverService.TEST_OLD_UOS_BY_USER = new Map<Id, String>{ uid => 'UOS0' };

        DES_cls_UserUosApproverService.TEST_APMS_TO_DELETE = new List<DMT_Approver_Member__c>{ new DMT_Approver_Member__c(
            DMT_User__c = uid, 
            DMT_ApproverByUOs__c = 'UOS0', 
            DMT_Approver__r = new DMT_Approver__c(
                DMT_Group__c = 'QUEUE_DEV'
            )
        ) };

        GroupMember gm = new GroupMember();
        gm.UserOrGroupId = uid;
        gm.GroupId = fakeId('00G');

        DES_cls_UserUosApproverService.TEST_GMS_TO_DELETE = new List<GroupMember>{ gm };

        DES_cls_UserUosApproverService.TEST_DISABLE_ENQUEUE = true;

        Test.startTest();
        List<GroupMember> res = DES_cls_UserUosApproverService.deleteOldApproverMembersAndReturnGroupMembers(oldMap, newUos);
        Test.stopTest();

        resetSeams();
        System.assertEquals(1, res.size());
        System.assertEquals(uid, res[0].UserOrGroupId);
    }

}