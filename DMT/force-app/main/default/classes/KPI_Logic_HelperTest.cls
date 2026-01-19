/**
* Global Desktop
*/
@isTest
public class KPI_Logic_HelperTest {
  /*
  * KPIS Helper Class
  */
  final KPI_Logic_Helper kpiHelper = KPI_Logic_Helper.getInstance();

  /*
   *  Util test class
  **/
  final DES_UtilTestClass utilTestClass = new DES_UtilTestClass();

  /*
   *  @author Global Desktop
   *
  **/
  @isTest
  private static void testInsertUpdateOpp() {
    KPI_Logic_Helper kpiHelper = KPI_Logic_Helper.getInstance();
    final DES_UtilTestClass utilTestClass = new DES_UtilTestClass();
    createKPICustomSetting();
    Map<Id, Opportunity> newMapOpp = new Map<Id, Opportunity>();
    Map<Id, Opportunity> oldMapOpp = new Map<Id, Opportunity>();
    Account acc = utilTestClass.createClient();
    insert acc;
    List<Opportunity> listOppsUpdate = new List<Opportunity>();
    Opportunity oppWon = utilTestClass.createOpportunity(acc);//Opp ganada
    oppWon.StageName = Label.DES_Closed_Won;
    oppWon.opportunity_correct_ind_type__c =  true;
    listOppsUpdate.add(oppWon);// OPP GANADA
    Opportunity oppLost = utilTestClass.createOpportunity(acc);//Opp perdida
    oppLost.StageName = Label.DES_Closed_Lose;
    oppLost.opportunity_correct_ind_type__c = true;
    oppLost.DES_Reasons_Lost__c = 'Pricing';
    oppLost.DES_Description_reason_for_lost_deal__c = 'test';
    listOppsUpdate.add(oppLost);//Opp perdida
    Opportunity oppExp = utilTestClass.createOpportunity(acc);//Opp expirada
    oppExp.StageName = Label.DES_Closed_Lose;
    oppExp.opportunity_correct_ind_type__c = true;
    oppExp.DES_Reasons_Lost__c = Label.Opportunity_expired;
    oppExp.DES_Description_reason_for_lost_deal__c = Label.Opportunity_expired;
    listOppsUpdate.add(oppExp);//Opp expirada
    Opportunity oppLive = utilTestClass.createOpportunity(acc);//Opp viva
    listOppsUpdate.add(oppLive);//Opp viva
    insert listOppsUpdate;
    newMapOpp.put(oppLost.Id, oppLost);
    oldMapOpp.put(oppLost.Id, oppWon);
    Test.startTest();
    kpiHelper.gtNumberOfBankers();
    kpiHelper.checkNeedUpdKpi(true, newMapOpp, oldMapOpp);
    kpiHelper.checkNeedUpdKpi(false, newMapOpp, oldMapOpp);
    Opportunity oppTestNew1 = new Opportunity(Id = oppLost.Id, StageName = 'Proposal', DES_Reasons_Lost__c = Label.Opportunity_expired);
    Opportunity oppTestOld1 = new Opportunity(Id = oppLost.Id, StageName = 'Approval', DES_Reasons_Lost__c = Label.Opportunity_expired);
    newMapOpp.put(oppLost.Id, oppTestNew1);
    oldMapOpp.put(oppLost.Id, oppTestOld1);
    kpiHelper.checkNeedUpdKpi(false, newMapOpp, oldMapOpp);
    List<KPIS__c> listKPIAssert = new List<KPIS__c>([SELECT Id FROM KPIS__c LIMIT 5000]);
		String jobId = system.schedule('Test Check', '0 0 2 * * ?', new Schedulable_KPIS ());
    System.assertEquals(!listKPIAssert.isEmpty(), true);
    Test.stopTest();
  }


  public static void createKPICustomSetting() {
    Global_Desktop_Settings__c gdSettings = new Global_Desktop_Settings__c();
    gdSettings.Enable_KPIS_Logic__c = true;
    insert gdSettings;
  }
}