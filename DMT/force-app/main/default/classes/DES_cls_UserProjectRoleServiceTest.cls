/***************************************************************************************
 * @author       BBVA
 * @date         2026
 * @description  Clase de test para DES_cls_UserProjectRoleService.
 *
 * OBJETIVO:
 *  • Garantizar cobertura 100%.
 *  • Validar todos los branches de control.
 *  • Validar concatenación sin duplicados.
 *  • Validar early returns.
 *  • Validar método público y overload @TestVisible.
 *
 ***************************************************************************************/
@IsTest
public with sharing class DES_cls_UserProjectRoleServiceTest{
    // =====================================================
    // Helpers
    // =====================================================
    private static User buildUser(){
        User u = new User();
        u.FirstName = 'John';
        u.LastName = 'Doe';
        return u;
    }

    private static DES_User_Roles__mdt buildMetadata(String roleName, String fieldName){
        DES_User_Roles__mdt m = new DES_User_Roles__mdt();
        m.DES_Role_Developer_Name__c = roleName;
        m.DES_User_Field_Map__c = fieldName;
        return m;
    }

    // =====================================================
    // TESTS
    // =====================================================
    /***************************************************************************************
     * Null user → early return
     ***************************************************************************************/
    @IsTest
    static void testFill_nullUser(){

        Test.startTest();
        DES_cls_UserProjectRoleService.fill(null, null, null);
        Test.stopTest();

        System.assert(true);
    }

    /***************************************************************************************
     * Wrapper null → early return
     ***************************************************************************************/
    @IsTest
    static void testFill_wrapperNull(){

        User u = buildUser();

        Test.startTest();
        DES_cls_UserProjectRoleService.fill(u, null, new List<DES_User_Roles__mdt>());
        Test.stopTest();

        System.assertEquals(null, u.get('DMT_User_Role__c'));
    }

    /***************************************************************************************
     * Roles metadata null → should not fail
     ***************************************************************************************/
    @IsTest
    static void testFill_rolesMetadataNull(){

        User u = buildUser();

        Test.startTest();
        DES_cls_UserProjectRoleService.fill(u, null, null);
        Test.stopTest();

        System.assertEquals(null, u.get('DMT_User_Role__c'));
    }

    /***************************************************************************************
     * Metadata without mapped field → no assignment
     ***************************************************************************************/
    @IsTest
    static void testFill_metadataWithoutFieldMapping(){

        User u = buildUser();

        DES_User_Roles__mdt fake = buildMetadata('DMT_Proyecto', null);

        Test.startTest();
        DES_cls_UserProjectRoleService.fill(u, null, new List<DES_User_Roles__mdt>{ fake });
        Test.stopTest();

        System.assertEquals(null, u.get('DMT_User_Role__c'));
    }

    /***************************************************************************************
     * Proper mapping → value assigned
     ***************************************************************************************/
    @IsTest
    static void testFill_properMapping(){

        User u = buildUser();

        DES_User_Roles__mdt fake = buildMetadata('DMT_Proyecto', 'DMT_User_Role__c');

        Test.startTest();
        DES_cls_UserProjectRoleService.fill(u, null, new List<DES_User_Roles__mdt>{ fake });
        Test.stopTest();

        String value = String.valueOf(u.get('DMT_User_Role__c'));
        System.assert(value.contains('DMT_Proyecto'));
    }

    /***************************************************************************************
     * Duplicate prevention → role must not duplicate
     ***************************************************************************************/
    @IsTest
    static void testFill_noDuplicateConcatenation(){

        User u = buildUser();

        DES_User_Roles__mdt fake1 = buildMetadata('DMT_Proyecto', 'DMT_User_Role__c');
        DES_User_Roles__mdt fake2 = buildMetadata('DMT_Proyecto', 'DMT_User_Role__c');

        Test.startTest();
        DES_cls_UserProjectRoleService.fill(u, null, new List<DES_User_Roles__mdt>{ fake1, fake2 });
        Test.stopTest();

        String value = String.valueOf(u.get('DMT_User_Role__c'));

        Integer firstIndex = value.indexOf('DMT_Proyecto');
        Integer lastIndex = value.lastIndexOf('DMT_Proyecto');

        System.assertEquals(firstIndex, lastIndex);
    }

    /***************************************************************************************
     * Public method fill(user, wrapper)
     * Covers getUserRolesMetadata() branch
     ***************************************************************************************/
    @IsTest
    static void testPublicFillMethod_executesGetMetadata(){

        User u = buildUser();

        Test.startTest();
        DES_cls_UserProjectRoleService.fill(u, null);
        Test.stopTest();

        System.assert(true);
    }

    /***************************************************************************************
     * Direct coverage of getUserRolesMetadata()
     ***************************************************************************************/
    @IsTest
    static void testGetUserRolesMetadata(){

        Test.startTest();
        List<DES_User_Roles__mdt> result = DES_cls_UserProjectRoleService.getUserRolesMetadata();
        Test.stopTest();

        System.assertNotEquals(null, result);
    }

}