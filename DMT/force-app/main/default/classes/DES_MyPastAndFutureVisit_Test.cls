/**
*Autor: Alejandro del Rio
 */
@isTest
public class DES_MyPastAndFutureVisit_Test {
    /**
    *Met0d0 test para la clase DES_MyPastAndFutureVisit
     */
    @isTest
    public static void MyPastAndFutureVisitTest() {
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

            Test.startTest();
            //GENERO UN CLIENTE
           final Account acc1 = utilTestClass.createClient();
            insert acc1;
            final Product2 prd = utilTestClass.createProduct('Product 1');
            insert prd;
            //GENERAR OPORTUNIDAD
            final Opportunity opp1 = utilTestClass.createOpportunity(acc1);
            insert opp1;
            final dwp_kitv__Visit__c visit1 =  utilTestClass.createVisit(acc1,opp1);	
            insert visit1;
            final dwp_kitv__Visit_Management_Team__c visMember = utilTestClass.createVisitManagementTeam(visit1,userTest1);
			insert visMember;
            system.debug('visMember'+visMember);
            Test.stopTest();
            final String dataTable = DES_MyPastAndFutureVisit.getData(2,true);
            final String dataTable2 = DES_MyPastAndFutureVisit.getData(2,false);
            system.assertNotEquals(dataTable,null,'Correcto');
            system.assertNotEquals(dataTable2,null,'Correcto');
        }
    }
}