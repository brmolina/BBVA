/**
*
* @author Global Desktop
*/
@isTest
public class DES_Ip_UpdateCountry_Test {

    /**
     * Test que crea una oportunidad, visita y formulario y actualiza esos registros por los datos obtenidos por parámetro
     * @param UpdateCountry: lista con los datos a actualizar
     *
     */
	@isTest
    public static void testIsOwner1() {
        final DES_UtilTestClass utilClass = new DES_UtilTestClass();
        final Account acc = utilClass.createClient();
        insert acc;
        final String profile = utilClass.createProfile();
        final User user1 = utilClass.createUser(profile);
        insert user1;
        //Creación de la oportunidad
       	Opportunity opp = new Opportunity();
            opp=utilClass.createOpportunity(acc);
            insert opp;
        //Creación de la visita
        dwp_kitv__Visit__c vis = new dwp_kitv__Visit__c();
            vis=utilClass.createVisit(acc,opp);
            insert vis;
        //Creación del formulario
        Test.startTest();
		final Inside_information_form__c inside = new Inside_information_form__c( Name = 'Test IIF' );
      	insert inside;
        //Se inserta datos a la variable UpdateCountry para actualizar la visita
        final List<DES_Ip_UpdateCountry.IpCountry> updateCountry = new List<DES_Ip_UpdateCountry.IpCountry>();
        final DES_Ip_UpdateCountry.IpCountry uc1 = new DES_Ip_UpdateCountry.IpCountry();
        List <dwp_kitv__Visit__c> viss= new List<dwp_kitv__Visit__c>();
        viss = [Select Id from dwp_kitv__Visit__c where Id =: vis.Id ];
        uc1.operation = 'visit';
        uc1.visits=viss;
        updateCountry.add(uc1);
        DES_Ip_UpdateCountry.DES_Ip_UpdateCountry(updateCountry);
        //Se inserta datos a la variable UpdateCountry para actualizar el formulario
        final List<DES_Ip_UpdateCountry.IpCountry> updateCountry2 = new List<DES_Ip_UpdateCountry.IpCountry>();
        final DES_Ip_UpdateCountry.IpCountry uc2 = new DES_Ip_UpdateCountry.IpCountry();
        uc2.operation = 'form';
        List <Inside_information_form__c> insideinfo= new List<Inside_information_form__c>();
        insideinfo = [Select Id from Inside_information_form__c where Id =: inside.Id ];
        uc2.forms=insideinfo;
        updateCountry2.add(uc2);
        DES_Ip_UpdateCountry.DES_Ip_UpdateCountry(updateCountry2);
        //Se inserta datos a la variable UpdateCountry para actualizar la oportunidad
        final List<DES_Ip_UpdateCountry.IpCountry> updateCountry3 = new List<DES_Ip_UpdateCountry.IpCountry>();
        final DES_Ip_UpdateCountry.IpCountry uc3 = new DES_Ip_UpdateCountry.IpCountry();
        List <Opportunity> oppos= new List<Opportunity>();
        oppos = [Select Id from Opportunity where Id =: opp.Id ];
        uc3.oppo=oppos;
        uc3.operation = 'oppo';
        updateCountry3.add(uc3);
        DES_Ip_UpdateCountry.DES_Ip_UpdateCountry(updateCountry3);
        System.assert(('oppo' == uc3.operation), 'oppo does not equal uc3.operation');
        Test.stopTest();
    }

}