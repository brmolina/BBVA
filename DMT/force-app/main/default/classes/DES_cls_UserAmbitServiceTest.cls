/***************************************************************************************
 * @author       BBVA
 * @date         2026
 * @description  Clase de test para DES_cls_UserAmbitService.
 *
 * OBJETIVO:
 *  • Cobertura 100% de DES_cls_UserAmbitService:
 *      - Rama early return: users == null
 *      - Rama early return: users.isEmpty()
 *      - Rama principal: for(User usr : users) con:
 *          a) ambit == null  -> flags FALSE
 *          b) ambit != null  -> flags según metadata
 *
 * NOTA IMPORTANTE:
 *  • Este test NO hace DML de User (el servicio trabaja en memoria).
 *  • Para cubrir la rama ambit != null dependemos de que exista al menos
 *    un registro Arce_ambit_hierarchy__mdt en el org, ya que Custom Metadata
 *    no se puede insertar por DML en test.
 *
 *  Si en algún entorno NO existe esa metadata, no se puede garantizar 100%
 *  sin introducir seams (@TestVisible) en el Provider/Service.
 ***************************************************************************************/
@IsTest
public with sharing class DES_cls_UserAmbitServiceTest{
    /***************************************************************************************
     * @description  Cubre early return cuando users == null.
     ***************************************************************************************/
    @IsTest
    static void testApply_returnsWhenNullList(){
        Test.startTest();
        DES_cls_UserAmbitService.apply(null);
        Test.stopTest();

        System.assert(true, 'No debe lanzar excepción con lista null.');
    }

    /***************************************************************************************
     * @description  Cubre early return cuando users está vacío.
     ***************************************************************************************/
    @IsTest
    static void testApply_returnsWhenEmptyList(){
        Test.startTest();
        DES_cls_UserAmbitService.apply(new List<User>());
        Test.stopTest();

        System.assert(true, 'No debe lanzar excepción con lista vacía.');
    }

    /***************************************************************************************
     * @description  Cubre:
     *               - ambit == null (gf_user_operation_ambit_name__c null / no encontrado)
     *               - ambit != null (cuando existe metadata y se encuentra la key)
     ***************************************************************************************/
    @IsTest
    static void testApply_setsFlags_forAmbitFoundAndNotFound(){
        
        User uNoAmbit = new User();
        uNoAmbit.gf_user_operation_ambit_name__c = 'THIS KEY DOES NOT EXIST (TEST)';
        uNoAmbit.DES_ARCE_Can_Propose__c = true;
        uNoAmbit.DES_ARCE_Can_Validate__c = true;
        uNoAmbit.DES_ARCE_Can_Edit__c = true;
        
        Map<String, Arce_ambit_hierarchy__mdt> mapAmbit = DES_cls_UserAmbitProvider.getMap();
        System.assert(mapAmbit != null, 'El provider no debe devolver null.');

        System.assert(mapAmbit.size() > 0, 'Se requiere al menos 1 Arce_ambit_hierarchy__mdt en el org para cubrir la rama ambit != null.');
        
        String anyKey = null;
        for (String k : mapAmbit.keySet()){
            anyKey = k;
            break;
        }
        System.assertNotEquals(null, anyKey, 'Debe existir una key de metadata.');

        Arce_ambit_hierarchy__mdt anyMdt = mapAmbit.get(anyKey);

        User uWithAmbit = new User();
        uWithAmbit.gf_user_operation_ambit_name__c = anyKey;
        
        List<User> users = new List<User>{ uNoAmbit, uWithAmbit };

        Test.startTest();
        DES_cls_UserAmbitService.apply(users);
        Test.stopTest();
        
        System.assertEquals(false, uNoAmbit.DES_ARCE_Can_Propose__c, 'Si el ambit no existe, Can_Propose debe quedar FALSE.');
        System.assertEquals(false, uNoAmbit.DES_ARCE_Can_Validate__c, 'Si el ambit no existe, Can_Validate debe quedar FALSE.');
        System.assertEquals(false, uNoAmbit.DES_ARCE_Can_Edit__c, 'Si el ambit no existe, Can_Edit debe quedar FALSE.');
        
        System.assertEquals(anyMdt.canPropose__c, uWithAmbit.DES_ARCE_Can_Propose__c, 'Can_Propose debe reflejar el valor de metadata.');
        System.assertEquals(anyMdt.canValidate__c, uWithAmbit.DES_ARCE_Can_Validate__c, 'Can_Validate debe reflejar el valor de metadata.');
        System.assertEquals(anyMdt.canEdit__c, uWithAmbit.DES_ARCE_Can_Edit__c, 'Can_Edit debe reflejar el valor de metadata.');
    }

}