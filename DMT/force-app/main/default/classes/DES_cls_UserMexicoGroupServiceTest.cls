/***************************************************************************************
 * @author       BBVA
 * @date         2026
 * @description  Clase de test para DES_cls_UserMexicoGroupService.
 *
 * OBJETIVO:
 *  • Cobertura 100% de la clase:
 *      - manage(): ramas add=true / add=false
 *      - early return (usersIds null / vacío)
 *      - getGroup(): rama cache miss (mexicoGroup == null) y cache hit
 *      - members.isEmpty() (se ejecuta vía usersIds no vacío)
 *
 * NOTAS:
 *  • El servicio espera que exista un Public Group con:
 *        Type = 'Regular'
 *        DeveloperName = 'cTMMexico'
 *  • Para hacer el test auto-contenido, se crea el grupo si no existe.
 ***************************************************************************************/
@IsTest
public with sharing class DES_cls_UserMexicoGroupServiceTest{
    // ------------------------------------------------------------
    // Test Setup
    // ------------------------------------------------------------
    @TestSetup
    static void setup(){
        ensureMexicoGroupExists();
        insert buildUsers(2);
    }

    // ------------------------------------------------------------
    // Tests
    // ------------------------------------------------------------
    /***************************************************************************************
     * @description  Cubre el early return cuando usersIds es null o vacío.
     ***************************************************************************************/
    @IsTest
    static void testManage_earlyReturn_nullOrEmpty(){
        Test.startTest();
        DES_cls_UserMexicoGroupService.manage(null, true);
        DES_cls_UserMexicoGroupService.manage(new Set<Id>(), true);
        DES_cls_UserMexicoGroupService.manage(null, false);
        DES_cls_UserMexicoGroupService.manage(new Set<Id>(), false);
        Test.stopTest();

        System.assert(true, 'No debe lanzar excepción en early return.');
    }

    /***************************************************************************************
     * @description  Cubre add=true y add=false + cache miss/hit del getGroup().
     *               - Primera llamada: mexicoGroup == null (query + cache)
     *               - Segunda llamada: mexicoGroup != null (usa cache)
     ***************************************************************************************/
    @IsTest
    static void testManage_addAndRemove_andCache(){

        Group mex = [SELECT Id, DeveloperName, Type
                     FROM Group
                     WHERE Type = 'Regular' AND DeveloperName = 'cTMMexico'
                     LIMIT 1];

        List<User> users = [SELECT Id
                            FROM User
                            WHERE LastName = 'MexicoGroupSvcTest'
                            LIMIT 2];
        System.assertEquals(2, users.size(), 'Se esperaban 2 usuarios de test.');

        Set<Id> userIds = new Set<Id>{ users[0].Id, users[1].Id };

        Test.startTest();

        // 1) ADD -> crea GroupMember (cubre rama add=true, members no vacío, insert)
        DES_cls_UserMexicoGroupService.manage(userIds, true);

        List<GroupMember> inserted = [SELECT Id, GroupId, UserOrGroupId
                                      FROM GroupMember
                                      WHERE GroupId = :mex.Id AND UserOrGroupId IN:userIds];
        System.assertEquals(2, inserted.size(), 'Deben insertarse 2 GroupMember.');

        // 2) REMOVE -> elimina (cubre rama add=false, delete SOQL)
        DES_cls_UserMexicoGroupService.manage(userIds, false);

        Integer afterDelete = [SELECT COUNT()
                               FROM GroupMember
                               WHERE GroupId = :mex.Id AND UserOrGroupId IN:userIds];
        System.assertEquals(0, afterDelete, 'Deben eliminarse los GroupMember.');

        // 3) ADD de nuevo -> fuerza ejecución con cache hit en getGroup()
        DES_cls_UserMexicoGroupService.manage(userIds, true);

        Integer afterReAdd = [SELECT COUNT()
                              FROM GroupMember
                              WHERE GroupId = :mex.Id AND UserOrGroupId IN:userIds];
        System.assertEquals(2, afterReAdd, 'Deben volver a insertarse los GroupMember.');

        Test.stopTest();
    }

    // ------------------------------------------------------------
    // Helpers
    // ------------------------------------------------------------
    private static void ensureMexicoGroupExists(){
        List<Group> existing = [SELECT Id
                                FROM Group
                                WHERE Type = 'Regular' AND DeveloperName = 'cTMMexico'
                                LIMIT 1];

        if (!existing.isEmpty()){
            return;
        }

        // Creamos el Public Group si no existe (auto-contenido).
        Group g = new Group();
        g.Name = 'cTMMexico';
        g.DeveloperName = 'cTMMexico';
        g.Type = 'Regular';
        insert g;
    }

    private static List<User> buildUsers(Integer howMany){

        Profile p = [SELECT Id
                     FROM Profile
                     WHERE Name IN ('Standard User', 'BBVA Standard User')
                     ORDER BY Name
                     LIMIT 1];

        List<User> res = new List<User>();

        for (Integer i = 0; i < howMany; i++){
            String uniq = String.valueOf(DateTime.now().getTime()) + '.' + String.valueOf(Math.abs(Crypto.getRandomInteger())) + '.' + i;
            String uniqueID = 'TST432' + i;
            User u = new User();
            u.ProfileId = p.Id;
            u.FirstName = 'User';
            u.LastName = 'MexicoGroupSvcTest';
            u.Alias = ('mxsvc' + i).left(8);
            u.Username = 'mxsvc.' + uniq + '@test.example';
            u.Email = 'mxsvc.' + uniq + '@test.example';
            u.TimeZoneSidKey = 'Europe/Madrid';
            u.LocaleSidKey = 'en_US';
            u.EmailEncodingKey = 'UTF-8';
            u.LanguageLocaleKey = 'en_US';
            u.ID_User__c = uniqueID;

            res.add(u);
        }

        return res;
    }

}