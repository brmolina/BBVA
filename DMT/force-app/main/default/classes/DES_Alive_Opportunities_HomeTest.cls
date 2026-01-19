/**
*Autor: Alejandro del Rio
 */
@isTest
public class DES_Alive_Opportunities_HomeTest {
    /**
    *Met0d0 test para la clase DES_Alive_Opportunities_Home
     */
    @isTest
    public static void DES_Alive_Opportunities_HomeTest() {

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

            //GENERO UN CLIENTE
            final Account acc1 = utilTestClass.createClient();
            insert acc1;
            //GENERAR PRODUCTO
            final Product2 prd = utilTestClass.createProduct('Product 1');
            insert prd;
            //GENERAR OPORTUNIDAD
            final Opportunity opp1 = utilTestClass.createOpportunity(acc1);
            insert opp1;
            Test.startTest();
            final PriceBookEntry pbookEntry1 = utilTestClass.createPricebookEntry(prd);
            insert pbookEntry1;
            //GENERAR OpportunityLineItem
            final OpportunityLineItem opli1 = utilTestClass.createOppLineItem(opp1, prd, pbookEntry1);
            insert opli1;
            final OpportunityLineItem opli2 = utilTestClass.createOppLineItem(opp1, prd, pbookEntry1);
            insert opli2;
            Test.stopTest();
            //GENERAR DES_Opportunity_Management_member__c
            final DES_Opportunity_Management_member__c opm1 = utilTestClass.createOppManagementMember(userTest1, opp1);
            insert opm1;
            

            final String curCode = DES_Alive_Opportunities_Home.getCurrentUserISOCode();
            final String dataTable = DES_Alive_Opportunities_Home.getData('2', 'SPA, BHN', true,true);
            final String dataTable2 = DES_Alive_Opportunities_Home.getData('2', 'SPA, BHN',null,false);
            final String dataTable3 = DES_Alive_Opportunities_Home.getData('2',null,null,true);
            system.assertNotEquals(opm1,null,'Correcto');
            system.assertNotEquals(dataTable,null,'Correcto');
            system.assertNotEquals(dataTable2,null,'Correcto');
            system.assertNotEquals(dataTable3,null,'Correcto');
        }

    }
}