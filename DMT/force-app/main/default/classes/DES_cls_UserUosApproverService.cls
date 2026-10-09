/***************************************************************************************
 * @author       BBVA
 * @date         2026
 * @description  Servicio responsable de gestionar la asignación y eliminación
 *               automática de DMT Approver Members y Group Members
 *               en función del UOS (Unidad Organizativa) del usuario.
 *
 *               FUNCIONALIDAD PRINCIPAL:
 *               • Detecta cambios de UOS en actualización de usuario.
 *               • Crea nuevos registros DMT_Approver_Member__c.
 *               • Inserta usuarios en colas (Group) asociadas al Approver.
 *               • Elimina registros antiguos cuando el UOS cambia.
 *               • Ejecuta operaciones DML mediante Queueables.
 *
 * ARQUITECTURA 2026:
 *  • Extraído desde User_Helper como parte del refactor a patrón Facade + Services.
 *  • Separación clara entre:
 *      - Identificación de UOS.
 *      - Construcción de nuevos registros.
 *      - Eliminación de registros antiguos.
 *      - Gestión de duplicados.
 *  • Bulk-safe.
 *  • Asíncrono mediante Queueable para evitar límites DML.
 *
 * DEPENDENCIAS:
 *  • DES_UOS_Utils
 *  • DMT_Approver_Member__c
 *  • Group / GroupMember
 *  • DMT_ApproverMemberQueueableHelper
 *  • DMT_GroupMemberQueueableHelper
 *
 * CONSIDERACIONES IMPORTANTES:
 *  • Solo inserta si existen tanto ApproverMembers como GroupMembers.
 *  • La deduplicación evita conflictos entre insert y delete en misma transacción.
 *  • No realiza DML directo sobre DMT_Approver_Member__c (usa Queueable).
 *
 ***************************************************************************************/
public with sharing class DES_cls_UserUosApproverService{
    // =====================================================
    // Test Seams (inyección controlada para testing)
    // =====================================================
    @TestVisible
    static Map<Id, String> TEST_UOS_BY_USER;
    @TestVisible
    static Map<Id, String> TEST_OLD_UOS_BY_USER;
    @TestVisible
    static List<DMT_Approver_Member__c> TEST_TEMPLATE_APMS;
    @TestVisible
    static List<DMT_Approver_Member__c> TEST_APMS_TO_DELETE;
    @TestVisible
    static List<GroupMember> TEST_GMS_TO_DELETE;
    @TestVisible
    static Map<String, Group> TEST_GROUPS_BY_DEVNAME;
    @TestVisible
    static Boolean TEST_DISABLE_ENQUEUE = false;
    // =====================================================
    // MÉTODO PRINCIPAL
    // =====================================================
    /***************************************************************************************
     * @description  Punto de entrada principal.
     *               Orquesta la creación/eliminación de registros DMT
     *               en función del UOS actual del usuario.
     *
     * @param        oldUserMap   Mapa de usuarios antes del update.
     * @param        newUsersMap  Mapa de usuarios nuevos.
     ***************************************************************************************/
    public static void process(Map<Id, User> oldUserMap, Map<Id, User> newUsersMap){

        if (newUsersMap == null || newUsersMap.isEmpty()){
            return;
        }

        Map<Id, String> mapUosUser;

        if (Test.isRunningTest() && TEST_UOS_BY_USER != null){
            mapUosUser = TEST_UOS_BY_USER;
        } else{
            DES_UOS_Utils uosUtilClass = new DES_UOS_Utils();
            mapUosUser = uosUtilClass.indentifyUserUos(newUsersMap.values());
        }

        List<GroupMember> groupMemberToDelete = new List<GroupMember>();

        //Contexto update: borrar registros antiguos y filtrar solo usuarios con cambio de UOS
        if (oldUserMap != null && !oldUserMap.isEmpty()){

            // Llamar con el mapa completo (sin filtrar) para que deleteOld compare correctamente
            groupMemberToDelete = deleteOldApproverMembersAndReturnGroupMembers(oldUserMap, mapUosUser);

            Map<Id, String> mapUosUserOld;

            if (Test.isRunningTest() && TEST_OLD_UOS_BY_USER != null){
                mapUosUserOld = TEST_OLD_UOS_BY_USER;
            } else{
                DES_UOS_Utils uosUtilOld = new DES_UOS_Utils();
                mapUosUserOld = uosUtilOld.indentifyUserUos(oldUserMap.values());
            }

            Set<Id> changedUsers = filterUsersWithUosChange(mapUosUser, mapUosUserOld);
            Map<Id, String> filteredMapUosUser = new Map<Id, String>();

            for (Id uid : changedUsers){
                filteredMapUosUser.put(uid, mapUosUser.get(uid));
            }

            mapUosUser = filteredMapUosUser;
        }

        if (mapUosUser == null || mapUosUser.isEmpty()){

            if (!groupMemberToDelete.isEmpty() && !(Test.isRunningTest() && TEST_DISABLE_ENQUEUE)){

                System.enqueueJob(new DMT_GroupMemberQueueableHelper(groupMemberToDelete, 'DELETE'));
            }
            return;
        }

        List<DMT_Approver_Member__c> approverMemberUos;

        if (Test.isRunningTest() && TEST_TEMPLATE_APMS != null){
            approverMemberUos = TEST_TEMPLATE_APMS;
        } else{
            approverMemberUos = [SELECT Id, DMT_Approver__c, DMT_Access_Level__c, DMT_FieldsHistoryView__c, DMT_ApproverByUOs__c, DMT_User__c, DMT_Approver__r.DMT_Group__c
                                 FROM DMT_Approver_Member__c
                                 WHERE DMT_ApproverByUOs__c IN:mapUosUser.values()];
        }

        if (approverMemberUos == null || approverMemberUos.isEmpty()){

            if (!groupMemberToDelete.isEmpty() && !(Test.isRunningTest() && TEST_DISABLE_ENQUEUE)){

                System.enqueueJob(new DMT_GroupMemberQueueableHelper(groupMemberToDelete, 'DELETE'));
            }
            return;
        }

        Map<String, Set<Id>> approverIdsByUos = new Map<String, Set<Id>>();
        Map<Id, DMT_Approver_Member__c> templateByApproverId = new Map<Id, DMT_Approver_Member__c>();
        Set<String> approverGroupDeveloperNames = new Set<String>();

        for (DMT_Approver_Member__c apm : approverMemberUos){

            if (apm.DMT_Approver__r != null && String.isNotBlank(apm.DMT_Approver__r.DMT_Group__c)){

                approverGroupDeveloperNames.add(apm.DMT_Approver__r.DMT_Group__c);
            }

            if (!approverIdsByUos.containsKey(apm.DMT_ApproverByUOs__c)){
                approverIdsByUos.put(apm.DMT_ApproverByUOs__c, new Set<Id>());
            }

            approverIdsByUos.get(apm.DMT_ApproverByUOs__c).add(apm.DMT_Approver__c);

            templateByApproverId.put(apm.DMT_Approver__c, apm);
        }

        Map<String, Group> groupsByDeveloperName = new Map<String, Group>();

        if (Test.isRunningTest() && TEST_GROUPS_BY_DEVNAME != null){
            groupsByDeveloperName.putAll(TEST_GROUPS_BY_DEVNAME);
        } else{
            if (!approverGroupDeveloperNames.isEmpty()){
                for (Group grp : [SELECT DeveloperName, Id
                                  FROM Group
                                  WHERE DeveloperName IN:approverGroupDeveloperNames]){
                    groupsByDeveloperName.put(grp.DeveloperName, grp);
                }
            }
        }

        List<DMT_Approver_Member__c> newApproverMembers = new List<DMT_Approver_Member__c>();
        List<GroupMember> newGroupMembers = new List<GroupMember>();

        for (Id userId : mapUosUser.keySet()){

            String uosCode = mapUosUser.get(userId);
            if (String.isBlank(uosCode))
                continue;
            Set<Id> approverIds = approverIdsByUos.get(uosCode);
            if (approverIds == null)
                continue;
            for (Id approverId : approverIds){

                DMT_Approver_Member__c template = templateByApproverId.get(approverId);

                if (template == null)
                    continue;
                User u = newUsersMap.get(userId);

                DMT_Approver_Member__c newApm = new DMT_Approver_Member__c();

                newApm.Name = (u != null ? u.FirstName + ' ' + u.LastName : null);

                newApm.DMT_Approver__c = approverId;
                newApm.DMT_User__c = userId;
                newApm.DMT_Access_Level__c = template.DMT_Access_Level__c;
                newApm.DMT_Is_Active__c = false;
                newApm.DMT_FieldsHistoryView__c = template.DMT_FieldsHistoryView__c;
                newApm.DMT_ApproverByUOs__c = uosCode;

                newApproverMembers.add(newApm);

                String devName = template.DMT_Approver__r != null ? template.DMT_Approver__r.DMT_Group__c : null;

                Group targetGroup = String.isBlank(devName) ? null : groupsByDeveloperName.get(devName);

                if (targetGroup != null){
                    GroupMember gm = new GroupMember();
                    gm.UserOrGroupId = userId;
                    gm.GroupId = targetGroup.Id;
                    newGroupMembers.add(gm);
                }
            }
        }

        if (!newApproverMembers.isEmpty() && !newGroupMembers.isEmpty()){

            if (!(Test.isRunningTest() && TEST_DISABLE_ENQUEUE)){

                System.enqueueJob(new DMT_ApproverMemberQueueableHelper(newApproverMembers, 'INSERT'));
            }

            DedupResult dedup = dedupeInsertVsDelete(newGroupMembers, groupMemberToDelete);

            newGroupMembers = dedup.toInsert;
            groupMemberToDelete = dedup.toDelete;

            if (!newGroupMembers.isEmpty() && !(Test.isRunningTest() && TEST_DISABLE_ENQUEUE)){

                System.enqueueJob(new DMT_GroupMemberQueueableHelper(newGroupMembers, 'INSERT'));
            }
        }

        if (!groupMemberToDelete.isEmpty() && !(Test.isRunningTest() && TEST_DISABLE_ENQUEUE)){

            System.enqueueJob(new DMT_GroupMemberQueueableHelper(groupMemberToDelete, 'DELETE'));
        }
    }

    // =====================================================
    // MÉTODO DELETE OLD
    // =====================================================
    /***************************************************************************************
     * @description  Elimina registros DMT_Approver_Member__c
     *               asociados al UOS anterior.
     ***************************************************************************************/
    public static List<GroupMember> deleteOldApproverMembersAndReturnGroupMembers(Map<Id, User> oldUserMap, Map<Id, String> mapUosUserNew){

        Map<Id, String> mapUosUserOld;

        if (Test.isRunningTest() && TEST_OLD_UOS_BY_USER != null){
            mapUosUserOld = TEST_OLD_UOS_BY_USER;
        } else{
            DES_UOS_Utils util = new DES_UOS_Utils();
            mapUosUserOld = util.indentifyUserUos(oldUserMap.values());
        }

        Set<Id> usersToDeleteApprover = new Set<Id>();

        for (Id userId : mapUosUserOld.keySet()){

            String oldUos = mapUosUserOld.get(userId);
            String newUos = mapUosUserNew.get(userId);

            if (oldUos != null && oldUos != newUos){
                usersToDeleteApprover.add(userId);
            }
        }

        if (usersToDeleteApprover.isEmpty()){
            return new List<GroupMember>();
        }

        List<DMT_Approver_Member__c> apmsToDelete;

        if (Test.isRunningTest() && TEST_APMS_TO_DELETE != null){
            apmsToDelete = TEST_APMS_TO_DELETE;
        } else{
            apmsToDelete = [SELECT Id, DMT_User__c, DMT_Approver__r.DMT_Group__c
                            FROM DMT_Approver_Member__c
                            WHERE DMT_User__c IN:usersToDeleteApprover];
        }

        Set<String> devNames = new Set<String>();
        Set<Id> userIds = new Set<Id>();

        for (DMT_Approver_Member__c apm : apmsToDelete){

            if (apm.DMT_User__c != null){
                userIds.add(apm.DMT_User__c);
            }

            if (apm.DMT_Approver__r != null && String.isNotBlank(apm.DMT_Approver__r.DMT_Group__c)){

                devNames.add(apm.DMT_Approver__r.DMT_Group__c);
            }
        }

        List<GroupMember> gms;

        if (Test.isRunningTest() && TEST_GMS_TO_DELETE != null){
            gms = TEST_GMS_TO_DELETE;
        } else{
            gms = [SELECT Id, GroupId, UserOrGroupId
                   FROM GroupMember
                   WHERE UserOrGroupId IN:userIds];
        }

        if (!apmsToDelete.isEmpty() && !(Test.isRunningTest() && TEST_DISABLE_ENQUEUE)){

            System.enqueueJob(new DMT_ApproverMemberQueueableHelper(apmsToDelete, 'DELETE'));
        }

        return gms;
    }

    // =====================================================
    // FILTRO UOS
    // =====================================================
    private static Set<Id> filterUsersWithUosChange(Map<Id, String> mapUosUserNew, Map<Id, String> mapUosUserOld){

        Set<Id> changedUsers = new Set<Id>();

        if (mapUosUserNew == null || mapUosUserOld == null){
            return changedUsers;
        }

        for (Id userId : mapUosUserNew.keySet()){

            String newUos = mapUosUserNew.get(userId);
            String oldUos = mapUosUserOld.get(userId);
            System.debug(' *** UserId: ' + userId + ' | OldUOS: ' + oldUos + ' | NewUOS: ' + newUos);
            if (newUos != null && newUos != oldUos){
                changedUsers.add(userId);
            }
        }

        return changedUsers;
    }

    // =====================================================
    // DEDUPE INTERNO
    // =====================================================
    private class DedupResult{
        public List<GroupMember> toInsert;
        public List<GroupMember> toDelete;
        public DedupResult(List<GroupMember> ins, List<GroupMember> del){
            toInsert = ins;
            toDelete = del;
        }

    }

    private static DedupResult dedupeInsertVsDelete(List<GroupMember> inserts, List<GroupMember> deletes){

        if (inserts == null)
            inserts = new List<GroupMember>();
        if (deletes == null)
            deletes = new List<GroupMember>();
        Set<String> deleteKeys = new Set<String>();

        for (GroupMember d : deletes){
            if (d == null)
                continue;
            deleteKeys.add(String.valueOf(d.GroupId) + '|' + 
                                            String.valueOf(d.UserOrGroupId));
        }

        List<GroupMember> newInserts = new List<GroupMember>();
        Set<String> matchedKeys = new Set<String>();

        for (GroupMember ins : inserts){

            String key = String.valueOf(ins.GroupId) + '|' + 
                                           String.valueOf(ins.UserOrGroupId);

            if (deleteKeys.contains(key)){
                matchedKeys.add(key);
                continue;
            }
            newInserts.add(ins);
        }

        List<GroupMember> newDeletes = new List<GroupMember>();

        for (GroupMember del : deletes){

            String key = String.valueOf(del.GroupId) + '|' + 
                                           String.valueOf(del.UserOrGroupId);

            if (!matchedKeys.contains(key)){
                newDeletes.add(del);
            }
        }

        return new DedupResult(newInserts, newDeletes);
    }

}