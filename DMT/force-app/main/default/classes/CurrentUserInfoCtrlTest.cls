/**
 * 
 * Alejandro del Rio
 */
@isTest
public class CurrentUserInfoCtrlTest {
    /**
     * 
     * Alejandro del Rio
     */	
      @isTest
      public static void fetchUser() {
          System.assertNotEquals(CurrentUserInfoCtrl.fetchUser().Id,'null','Test'); 
     }
     /**
     * Test para el met0d0 legalLogicUser de la clase CurrentUserInfoCtrl
     * Alejandro del Rio
     */
     @isTest
      public static void legalLogicUsertest() {
        final DES_UtilTestClass utilTestClass = new DES_UtilTestClass();
        final UserRole rolPadre = new UserRole(Name = 'RolePadre');
        insert rolPadre;
        final UserRole rolHijo= new UserRole(Name = 'RoleHijo', ParentRoleId = rolPadre.Id);
        insert rolHijo;
        final String profileTest = utilTestClass.createProfile();
        final User userTest1 = utilTestClass.createUser(profileTest);
        userTest1.userRoleId = rolPadre.Id;
        insert userTest1;
        system.runAs(userTest1) {
            final Account acc1 = utilTestClass.createClient();
            insert acc1;
            system.assertNotEquals(CurrentUserInfoCtrl.legalLogicUser('IBF',acc1.id), null, 'msg');
        }
    }
}