@isTest
public class DES_CustomReportChartOppByCountryTest{
  @isTest
  public static void DES_CustomReportChartOppByCountryTest(){

    DES_UtilTestClass utilTestClass = new DES_UtilTestClass();
    String profileTest = utilTestClass.createProfile();
    User userTest1 = utilTestClass.createUser(profileTest);
    insert userTest1;
    CIB_User_Org__c userSettings = utilTestClass.createCustomSetting();
    insert userSettings;

    system.runAs(userTest1){
      List<Account> listaCuentas = new List<Account>();
      //GENERO UN CLIENTE
      Account acc1 = utilTestClass.createClient();
      listaCuentas.add(acc1);
      Account acc2 = utilTestClass.createClient();
      acc2.Name = 'Client Test 2';
      listaCuentas.add(acc2);
      insert listaCuentas;

          AMH_GBL_Account_Relationship__c accRel1 = new AMH_GBL_Account_Relationship__c();
          accRel1.AMH_Child_Account__c = listaCuentas.get(0).Id;
          accRel1.AMH_Parent_Account__c = listaCuentas.get(1).Id;
          accRel1.AMH_Type__c = '  03 - Filial'; // Subgroup
          accRel1.AMH_Vision__c = 'Negocio';
          insert accRel1;

      List<Opportunity> listaOpps = new List<Opportunity>();
      //GENERAR OPORTUNIDAD
      Opportunity opp1 = utilTestClass.createOpportunity(listaCuentas.get(0));
      opp1.DES_Expected_Probability__c = 100;
      opp1.OwnerId = userTest1.Id;
      opp1.StageName = Label.DES_Proposal;
      listaOpps.add(opp1);
      Opportunity opp2 = utilTestClass.createOpportunity(listaCuentas.get(1));

      opp2.Name = 'Test Opportunity 2';
      opp2.DES_Expected_Probability__c = 80;
      opp2.OwnerId = userTest1.Id;
      opp2.StageName = Label.DES_Proposal;
      listaOpps.add(opp2);
      Opportunity opp3 = utilTestClass.createOpportunity(listaCuentas.get(0));

      opp3.Name = 'Test Opportunity 3';
      opp3.DES_Expected_Probability__c = 95;
      opp3.OwnerId = userTest1.Id;
      opp3.StageName = Label.DES_Proposal;
      listaOpps.add(opp3);
      insert listaOpps;


      Test.startTest();

      Product2 prd1 = utilTestClass.createProduct('Producto 1');
      insert prd1;

      PricebookEntry pbe1 = utilTestClass.createPricebookEntry(prd1);
      insert pbe1;

      List<OpportunityLineItem> listaOpli = new List<OpportunityLineItem>();
      OpportunityLineItem opli1 = utilTestClass.createOppLineItem(listaOpps.get(0), prd1, pbe1);
      opli1.pre_oppy_revenue_next_12m_amount__c = 50;
      insert opli1;

      Test.stopTest();
      String curIso = DES_CustomReportChartOppByCountry.getCurrentUserISOCode();
      String dataChart = DES_CustomReportChartOppByCountry.getDataChart((String) listaCuentas.get(0).Id);
      String dataTable = DES_CustomReportChartOppByCountry.getDataTable((String) listaCuentas.get(0).Id);


    }
  }

}