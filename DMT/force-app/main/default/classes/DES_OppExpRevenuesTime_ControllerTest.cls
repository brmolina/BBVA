@isTest
public class DES_OppExpRevenuesTime_ControllerTest {
    
    @isTest
    public static void DES_OppExpRevenuesTime_ControllerTest() {
        
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
            accRel1.AMH_Type__c = '03 - Filial'; // Subgroup
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
            opp2.StageName = Label.DES_Approvals;
            opp2.DES_Booking_Geography__c = 'HK';
            listaOpps.add(opp2);
            Opportunity opp3 = utilTestClass.createOpportunity(listaCuentas.get(0));
            opp3.Name = 'Test Opportunity 3';
            //opp3.DES_Expected_Probability__c = 95;
            opp3.OwnerId = userTest1.Id;
            opp3.StageName = Label.DES_Approvals;
            opp3.DES_Booking_Geography__c = 'GB';
            listaOpps.add(opp3);
            Opportunity opp4 = utilTestClass.createOpportunity(listaCuentas.get(0));
            opp4.Name = 'Test Opportunity 3';
            //opp3.DES_Expected_Probability__c = 95;
            opp4.OwnerId = userTest1.Id;
            opp4.StageName = Label.DES_Approvals;
            opp4.DES_Booking_Geography__c = 'NY';
            listaOpps.add(opp4);
            Opportunity opp5 = utilTestClass.createOpportunity(listaCuentas.get(0));
            opp5.Name = 'Test Opportunity 3';
            //opp3.DES_Expected_Probability__c = 95;
            opp5.OwnerId = userTest1.Id;
            opp5.StageName = Label.DES_Approvals;
            opp5.DES_Booking_Geography__c = 'MX';
            listaOpps.add(opp5);
            insert listaOpps;

            Product2 prd1 = utilTestClass.createProduct('Producto 1');
            insert prd1;
            
            PricebookEntry pbe1 = utilTestClass.createPricebookEntry(prd1);
            insert pbe1;
      Test.startTest();
            List<OpportunityLineItem> listaOpli = new List<OpportunityLineItem>();
            OpportunityLineItem opli1 = utilTestClass.createOppLineItem(listaOpps.get(0), prd1, pbe1);
            opli1.pre_oppy_revenue_next_12m_amount__c = 50;
            listaOpli.add(opli1);
            OpportunityLineItem opli2 = utilTestClass.createOppLineItem(listaOpps.get(1), prd1, pbe1);
            opli2.pre_oppy_revenue_next_12m_amount__c = 50;
            listaOpli.add(opli2);
            OpportunityLineItem opli3 = utilTestClass.createOppLineItem(listaOpps.get(2), prd1, pbe1);
            opli3.pre_oppy_revenue_next_12m_amount__c = 50;
            listaOpli.add(opli3);
            OpportunityLineItem opli4 = utilTestClass.createOppLineItem(listaOpps.get(3), prd1, pbe1);
            opli4.pre_oppy_revenue_next_12m_amount__c = 50;
            listaOpli.add(opli4);
            OpportunityLineItem opli5 = utilTestClass.createOppLineItem(listaOpps.get(4), prd1, pbe1);
            opli5.pre_oppy_revenue_next_12m_amount__c = 50;
            listaOpli.add(opli5);           
            insert listaOpli;
            
      
            listaOpps.get(1).StageName = 'Ready to close';
            listaOpps.get(1).DES_Reasons_Lost__c = 'Pricing';
            listaOpps.get(1).DES_Description_reason_for_lost_deal__c = 'Descripción de ejemplo';
            listaOpps.get(2).StageName = 'Ready to close';
            update listaOpps;
            
            listaOpps.get(1).StageName = Label.DES_Closed_Lose;
            listaOpps.get(2).StageName = Label.DES_Closed_Won;
            //update listaOpps;
            
      
            String oppsProducts = DES_OppExpRevenuesTime_Controller.getOppProducts(listaCuentas.get(0).Id);
            String curUserIso = DES_OppExpRevenuesTime_Controller.getCurrentUserISOCode();
            Test.stopTest();
            String dataChart = DES_OppExpRevenuesTime_Controller.getData(listaCuentas.get(0).Id);

            String data = RevenuesStageProduct_ReportChartCont.getData(listaCuentas.get(0).Id);
            String products = RevenuesStageProduct_ReportChartCont.getOppProducts(listaCuentas.get(0).Id);
            String codeIso = RevenuesStageProduct_ReportChartCont.getCurrentUserISOCode();
            
            String data2 = PotRevenuesByRegionProductCnt.getData(listaCuentas.get(0).Id);
            String products2 = PotRevenuesByRegionProductCnt.getOppProducts(listaCuentas.get(0).Id);
            String codeIso2 = PotRevenuesByRegionProductCnt.getCurrentUserISOCode();
            
        }
        
    }
}