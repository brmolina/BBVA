/************************************************************************
* @name:                GBL_BookingInitiativeGroupTest
* @author               bbva.com developers
* @date:                2019
* @version:             1.0
* @group:               Global Desktop
* @description:         test class of GBL_BookingInitiativeGroup
***************************************************************************/
@isTest
public class GBL_BookingInitiativeGroupTest {
  /**
   * @description create test data
   * @return void
   */
  @testSetup
  static void setup() {
    GBL_TestDataFactory_Initiative.newDb('ESPAÑA');
    GBL_TestDataFactory_Initiative.newAccount(1,2);
    GBL_TestDataFactory_Initiative.newCondCamp(1,1);
    GBL_TestDataFactory_Initiative.newCondCamp(1,2);
  }

  /**
   * @description validate change to ended status
   * @return void
   */
  @isTest
  static void testMethods() {
    final Set<String> setCuenta = new Set<String>();
    final Map<String,String> mapGroupFilter = new Map<String,String>();

    final User objUser = GBL_TestDataFactory_Initiative.getUser(true);
    objUser.gf_user_work_product_desc__c = 'codeC';
    objUser.gf_user_work_country_desc__c = 'AE';
    update objUser;

    final Campaign campana = [SELECT Id,
                                sector_desc__c,
                                segment_desc__c,
                                country_name__c,
                                Status,
                                Type,
                                tier_desc__c,
                                solution_name_path_desc__c,
                                gf_user_country_name__c
                              FROM Campaign
                              LIMIT 1][0];
    campana.soluction_category_id__c = 'GM';
    campana.solution_name_path_desc__c = 'codeC';
    campana.gf_user_country_name__c = 'AE';
    System.debug('::::::::::country_name__c: ' + campana.country_name__c);
    update campana;

    System.assertNotEquals(campana, null);

    final GBL_BookingInitiativeGroup objBooking = new GBL_BookingInitiativeGroup();

    final List<Account> listAccount = [SELECT Id FROM Account LIMIT 50];
    for(Account iAccount : listAccount) {
      setCuenta.add(iAccount.Id);
    }

    objBooking.ClientFilter(campana);
    objBooking.InitiativeTeamFilter(campana, mapGroupFilter);
    //objBooking.getBookingClientGroup(campana, setCuenta);
  }
}