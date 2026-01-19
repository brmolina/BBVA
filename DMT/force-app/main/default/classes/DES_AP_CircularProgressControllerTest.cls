/**********************************************************************************
    * @author       Global Desktop 
    * @date         22/07/2019
    * @description  Clase de test de DES_AP_CircularProgressController
    * @Revision     
    **********************************************************************************/
    @isTest
    public class DES_AP_CircularProgressControllerTest {
        
        /*
    * @author       Global Desktop                 
    * @Description  Chart
    */
        @IsTest
        static void getDataTest() {
            final DES_UtilTestClass utils = new DES_UtilTestClass();
            final DES_UtilTestClassAux utilsAux = new DES_UtilTestClassAux();
            
            //Creación cuenta
            final Account account = utils.createClient();
            insert account;
            
            DES_Booking__c booking;
            booking = utils.createBooking(account, 'ARGENTINA', 'AMESUR', 100000, 'GM', '2018');
            booking.SOLUTION_CATEGORY_NAME__c = 'Rates';
            insert booking;
            system.debug(booking);

            final acpl__AP_PeriodConfiguration__c apConfig = utils.createAPConfig();
            insert apConfig;
            
            final acpl__AP_Period__c apPeriod = utils.createAPPeriod();
            apPeriod.acpl__gf_ap_edit_start_date__c = date.Today()+1;
            insert apPeriod;

            final acpl__Account_Plan_Settings__c apSettings = new acpl__Account_Plan_Settings__c();
            apSettings.acpl__Unlock_when_change_DueDate__c = false;
            insert apSettings;
            
            //Creación del account planning
            final acpl__Account_Planning__c accountPlanning = utils.createAccountPlanning(account);
            accountPlanning.acpl__gf_ap_launch_period_desc__c = '20/21';
            insert accountPlanning;
            
            final bupl__BusinessPlan__c businessPlan = utilsAux.createBusinessPlan(accountPlanning, account);
            insert businessPlan;
            
            final bupl__BusinessPlan_Version__c bpVersion = utilsAux.createBusinessPlanVersion(businessPlan);
            bpVersion.bupl__gf_bus_pl_lst_vldt_vr_ind_type__c  = true;
            bpVersion.bupl__gf_business_plan_act_ind_type__c = 'Yes';
            insert bpVersion;
            
            final bupl__BusinessPlan_Item__c bpItem = utilsAux.createBusinessPlanItemNormal(bpVersion);
            bpItem.bupl__gf_total_revenues_ytd_amount__c = 1000;
            bpItem.bupl__expected_revenue_amount__c = 2000;
            bpItem.bupl__total_revenues_py_amount__c = 3000;
            insert bpItem;


            
            final DES_Group_Analysis__c groupAnalysis = utilsAux.createGroupAnalysis(accountPlanning, account);
            insert groupAnalysis;
            Test.startTest();
            DES_AP_CircularProgressController.calculateCircleInfo(groupAnalysis.Id); 
            Test.stopTest();
            final List<bupl__BusinessPlan_Item__c> bpItemList = [SELECT Id FROM bupl__BusinessPlan_Item__c 
                                                            WHERE bupl__gf_business_plan_version_id__r.bupl__gf_business_plan_act_ind_type__c = 'Yes'
                                                        AND bupl__gf_business_plan_version_id__r.bupl__gf_bus_pl_lst_vldt_vr_ind_type__c = true
                                                        AND bupl__gf_business_plan_version_id__r.bupl__gf_business_plan_id__r.bupl__participant_id__c = :account.Id];
            System.assert(!bpItemList.isEmpty(), 'No chart data');
        }
        
        @IsTest
        static void getDataTest2() {
            final DES_UtilTestClass utils = new DES_UtilTestClass();
            final DES_UtilTestClassAux utilsAux = new DES_UtilTestClassAux();
            final string yearToday =  string.valueOf(System.Today().year());
            final string nextYear =  string.valueOf(System.Today().addYears(+1).year());
            string launchPeriod;
            final string year1 = yearToday.substring(2,4);
            final string year2 = nextYear.substring(0,2);
            launchPeriod =+ year1 +'/'+ year2;
            //Creación cuenta
            final Account account = utils.createClient();
            insert account;
            
            DES_Booking__c booking;
            booking = utils.createBooking(account, 'ARGENTINA', 'AMESUR', 100000, 'GM', yearToday);
            booking.SOLUTION_CATEGORY_NAME__c = 'Rates';
            insert booking;
            system.debug(booking);

            final acpl__AP_PeriodConfiguration__c apConfig = utils.createAPConfig();
            insert apConfig;
            
            final acpl__AP_Period__c apPeriod = utils.createAPPeriod();
            apPeriod.acpl__gf_ap_edit_start_date__c = date.Today()+1;
            insert apPeriod;

            final acpl__Account_Plan_Settings__c apSettings = new acpl__Account_Plan_Settings__c();
            apSettings.acpl__Unlock_when_change_DueDate__c = false;
            insert apSettings;
            
            //Creación del account planning
            final acpl__Account_Planning__c accountPlanning = utils.createAccountPlanning(account);
            accountPlanning.acpl__gf_ap_launch_period_desc__c = launchPeriod;
            insert accountPlanning;
            
            final bupl__BusinessPlan__c businessPlan = utilsAux.createBusinessPlan(accountPlanning, account);
            insert businessPlan;
            
            final bupl__BusinessPlan_Version__c bpVersion = utilsAux.createBusinessPlanVersion(businessPlan);
            bpVersion.bupl__gf_bus_pl_lst_vldt_vr_ind_type__c  = true;
            bpVersion.bupl__gf_business_plan_act_ind_type__c = 'Yes';
            insert bpVersion;
            
            final bupl__BusinessPlan_Item__c bpItem = utilsAux.createBusinessPlanItemNormal(bpVersion);
            bpItem.bupl__gf_total_revenues_ytd_amount__c = 1000;
            bpItem.bupl__expected_revenue_amount__c = 2000;
            bpItem.bupl__total_revenues_py_amount__c = 3000;
            insert bpItem;


            
            final DES_Group_Analysis__c groupAnalysis = utilsAux.createGroupAnalysis(accountPlanning, account);
            insert groupAnalysis;
            Test.startTest();
            DES_AP_CircularProgressController.calculateCircleInfo(groupAnalysis.Id); 
            Test.stopTest();
            final List<bupl__BusinessPlan_Item__c> bpItemList = [SELECT Id FROM bupl__BusinessPlan_Item__c 
                                                            WHERE bupl__gf_business_plan_version_id__r.bupl__gf_business_plan_act_ind_type__c = 'Yes'
                                                        AND bupl__gf_business_plan_version_id__r.bupl__gf_bus_pl_lst_vldt_vr_ind_type__c = true
                                                        AND bupl__gf_business_plan_version_id__r.bupl__gf_business_plan_id__r.bupl__participant_id__c = :account.Id];
            System.assert(!bpItemList.isEmpty(), 'No chart data');
            
        }
        
        @IsTest
        static void getDataTest3() {
            final DES_UtilTestClass utils = new DES_UtilTestClass();
            final DES_UtilTestClassAux utilsAux = new DES_UtilTestClassAux();
            final string yearToday =  string.valueOf(System.Today().year());
            //Creación cuenta
            final Account account = utils.createClient();
            insert account;
            
            DES_Booking__c booking;
            booking = utils.createBooking(account, 'ARGENTINA', 'AMESUR', 100000, 'GM', yearToday);
            booking.SOLUTION_CATEGORY_NAME__c = 'Rates';
            insert booking;
            system.debug(booking);

            final acpl__AP_PeriodConfiguration__c apConfig = utils.createAPConfig();
            insert apConfig;
            
            final acpl__AP_Period__c apPeriod = utils.createAPPeriod();
            apPeriod.acpl__gf_ap_edit_start_date__c = date.Today()+1;
            insert apPeriod;

            final acpl__Account_Plan_Settings__c apSettings = new acpl__Account_Plan_Settings__c();
            apSettings.acpl__Unlock_when_change_DueDate__c = false;
            insert apSettings;
            
            //Creación del account planning
            final acpl__Account_Planning__c accountPlanning = utils.createAccountPlanning(account);
            accountPlanning.acpl__gf_ap_launch_period_desc__c = '20/21';
            insert accountPlanning;
            
            final bupl__BusinessPlan__c businessPlan = utilsAux.createBusinessPlan(accountPlanning, account);
            insert businessPlan;
            
            final bupl__BusinessPlan_Version__c bpVersion = utilsAux.createBusinessPlanVersion(businessPlan);
            bpVersion.bupl__gf_bus_pl_lst_vldt_vr_ind_type__c  = true;
            bpVersion.bupl__gf_business_plan_act_ind_type__c = 'Yes';
            insert bpVersion;
            
            final bupl__BusinessPlan_Item__c bpItem = utilsAux.createBusinessPlanItemNormal(bpVersion);
            bpItem.bupl__gf_total_revenues_ytd_amount__c = 1000;
            bpItem.bupl__expected_revenue_amount__c = 2000;
            bpItem.bupl__total_revenues_py_amount__c = 3000;
            insert bpItem;


            
            final DES_Group_Analysis__c groupAnalysis = utilsAux.createGroupAnalysis(accountPlanning, account);
            insert groupAnalysis;
            Test.startTest();
            DES_AP_CircularProgressController.calculateCircleInfo(groupAnalysis.Id); 
            Test.stopTest();
            final List<bupl__BusinessPlan_Item__c> bpItemList = [SELECT Id FROM bupl__BusinessPlan_Item__c 
                                                            WHERE bupl__gf_business_plan_version_id__r.bupl__gf_business_plan_act_ind_type__c = 'Yes'
                                                        AND bupl__gf_business_plan_version_id__r.bupl__gf_bus_pl_lst_vldt_vr_ind_type__c = true
                                                        AND bupl__gf_business_plan_version_id__r.bupl__gf_business_plan_id__r.bupl__participant_id__c = :account.Id];
            System.assert(!bpItemList.isEmpty(), 'No chart data');
            
        }

        
        

        
    }