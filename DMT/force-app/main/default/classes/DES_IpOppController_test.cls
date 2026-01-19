/**
*
* @author Global Desktop
*/
@isTest
public class DES_IpOppController_test {
  /*
   * Test method for isOwner function
  */
    @isTest
    public static void testIsOwner() {
        final DES_UtilTestClass utilClass = new DES_UtilTestClass();
        final Account acc = utilClass.createClient();
        insert acc;
        final String profile = utilClass.createProfile();
        final User user1 = utilClass.createUser(profile);
        insert user1;
        boolean isOwner;
        system.runAs(user1) {
            final Opportunity opp = utilClass.createOpportunity(acc);
            insert opp;
            isOwner = DES_IpOppController.isOwner(opp.id);
        }
        system.assert(true,isOwner);
    }

    /*
   * Test method for instance function
  */
    @isTest
    public static void testInstance() {
        final DES_IpOppController instance = DES_IpOppController.getInstance();
        system.assertNotEquals(null, instance, 'msg');
    }

    /*
   * Test method for bbvaUserCode function
  */
    @isTest
    public static void testBBVAUserCode() {
        final DES_UtilTestClass utilClass = new DES_UtilTestClass();
        final Account acc = utilClass.createClient();
        insert acc;
        final String profile = utilClass.createProfile();
        final User user1 = utilClass.createUser(profile);
        insert user1;
        String fedId;
        system.runAs(user1) {
            fedId = DES_IpOppController.bbvaUserCode();
        }
        final User user2 = [SELECT FederationIdentifier FROM User WHERE Id=:user1.id Limit 1];
        system.assertEquals(user2.FederationIdentifier, fedId, 'bbvaCode');
    }

    /*
   * Test method for getopportunity and saveopportunity function
  */
    @isTest
    public static void getOpportunity() {
        final DES_UtilTestClass utilClass = new DES_UtilTestClass();
        final Account acc = utilClass.createClient();
        insert acc;
        final String profile = utilClass.createProfile();
        final User user1 = utilClass.createUser(profile);
        insert user1;
        Opportunity opp, opp2, opp3;
        system.runAs(user1) {
            opp = utilClass.createOpportunity(acc);
            insert opp;
            opp2 = DES_IpOppController.getOpportunityById(opp.id);
            opp = DES_IpOppController.saveOpportunity(opp);
        }
        opp3 = [select id, Name FROM Opportunity WHERE Id=:opp2.id Limit 1];
        system.assertEquals(opp3.Name, opp2.Name, 'Opp');
    }

    /*
   * Test method for getCountries function
  */
    @isTest
    public static void getCountries() {
        String countries = '';
        countries = DES_IpOppController.getCountries();
        system.assertNotEquals('', countries,'countries');
    }

    /*
   * Test method for getObjectType function
  */
    @isTest
    public static void getObjectType() {
        String fields = '';
        fields = DES_IpOppController.getObjectType('Opportunity');
        system.assertNotEquals('', fields,'fields');
    }

    /*
   * Test method for getObjectType function
  */
    @isTest
    public static void getObjectTypeError() {
        try {
            final String fields1 = DES_IpOppController.getObjectType('Test');
            system.assertEquals(null, fields1, 'null');
        } catch(Exception e) {
            system.debug(e.getMessage());
        }
    }

    /*
   * Test method for getRecordTypeId function
  */
    @isTest
    public static void getRecordTypeId() {
        final String rtId = DES_IpOppController.getRecordTypeId(Label.DES_RT_ACC_Draft_Opportunity);
        system.assertNotEquals(null, rtId, 'Not null');
    }

    /*
   * Test method for getRecordTypeId function
  */
    @isTest
    public static void getRecordTypeIdError() {
        try {
            final String rtId1 = DES_IpOppController.getRecordTypeId('Test');
            system.assertEquals(null, rtId1, 'Null');
        } catch(Exception e) {
            system.debug(e.getMessage());
        }
    }
}