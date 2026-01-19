/**
 * @description       : 
 * @author            : Global Desktop
 * @group             : 
 * @last modified on  : 08-10-2021
 * @last modified by  : Global Desktop
**/
@isTest
public class BannerAccountController_Test {

    static testMethod void testDataFI(){
        gcal__GBL_Google_Calendar_Sync_Environment__c cs_gcal = new gcal__GBL_Google_Calendar_Sync_Environment__c();
        cs_gcal.Name = 'DEV';
        insert cs_gcal;
        Account SampleAccount = UnitTestUtils.GetStandardAccount();
        SampleAccount.YTD_Total_Franchise__c = 123456.78;
        SampleAccount.MTD_Total_Franchise__c = 123456.78;
        SampleAccount.Prior_Year_Franchise__c = 123456.78;

        SampleAccount.Cash_Bond_YTD_Total_Franchise__c = 12345689.78;
        SampleAccount.Cash_Bond_MTD_Total_Franchise__c = 12345689.78;
        SampleAccount.Prior_Year_Franchise_Cash_Bond__c = 12345689.78;

        SampleAccount.FX_YTD_Total_Franchise__c = 1234568901.78;
        SampleAccount.FX_MTD_Total_Franchise__c = 1234568901.78;
        SampleAccount.Prior_Year_Franchise_FX__c = 1234568901.78;

        SampleAccount.CE_YTD_Total_Franchise__c = 12456.78;
        SampleAccount.CE_MTD_Total_Franchise__c = 12456.78;
        SampleAccount.Prior_Year_Franchise_CE__c = 12456.78;
        Insert SampleAccount;
        user SampleUser = UnitTestUtils.GetFISalesUser();
        insert SampleUser;
        AccountShare SampleAccShare = UnitTestUtils.GetAccountShareUser(SampleAccount.id, SampleUser.id);

        insert SampleAccShare;



        System.runAs(SampleUser) {
            Contact SampleContact = UnitTestUtils.GetContact(SampleAccount.id);
            insert SampleContact;

            Task SampleTaskFI = UnitTestUtils.GetTask(SampleUser.Id,SampleAccount.id, SampleContact.id);
            SampleTaskFI.Asset_Class__c = ConstantsUtils.FI;
            insert SampleTaskFI;

            Activity__c newActivityC = new Activity__c(Account__c = SampleAccount.Id, Asset_Class__c = SampleTaskFI.Asset_Class__c, OwnerId = SampleTaskFI.OwnerId, isPublicEquity__c = SampleTaskFI.isPublicEquity__c);
            insert newActivityC;

            /*Event sampleEvent = UnitTestUtils.GetEvent(SampleUser.Id, newActivityC.id, sampleContact.Id);
            sampleEvent.Asset_Class__c = ConstantsUtils.FI;
            sampleEvent.StartDateTime = system.today();
            sampleEvent.Location = 'Madrid, Spain';
            insert sampleEvent;*/

            test.startTest();
            PageReference BannerAccount = Page.BannerAccount;
            test.setCurrentPage(BannerAccount);
            ApexPages.StandardController stdCtrl = new ApexPages.StandardController(SampleAccount);
            BannerAccountController ctrlExt = new BannerAccountController(stdCtrl);
            ctrlExt.getActivitiesByDate();
            ctrlExt.getOpenActivitiesBySubject();
            test.stopTest();
        }
    }


    static testMethod void testDataFX(){
        gcal__GBL_Google_Calendar_Sync_Environment__c cs_gcal = new gcal__GBL_Google_Calendar_Sync_Environment__c();
        cs_gcal.Name = 'DEV';
        insert cs_gcal;
        Account SampleAccount = UnitTestUtils.GetStandardAccount();
        Insert SampleAccount;
        user SampleUser = UnitTestUtils.GetFISalesUser();
        insert SampleUser;
        AccountShare SampleAccShare = UnitTestUtils.GetAccountShareUser(SampleAccount.id, SampleUser.id);
        insert SampleAccShare;
        System.runAs(SampleUser) {
            Opportunity SampleOpportunity = UnitTestUtils.GetOpportunity(SampleAccount);
            insert SampleOpportunity;
            test.startTest();
            PageReference BannerAccount = Page.BannerAccount;
            test.setCurrentPage(BannerAccount);
            ApexPages.StandardController stdCtrl = new ApexPages.StandardController(SampleAccount);
            BannerAccountController ctrlExt = new BannerAccountController(stdCtrl);
            Task SampleTaskFX = UnitTestUtils.GetTask(SampleUser.Id, SampleOpportunity.id, null);
            SampleTaskFX.ActivityDate = system.today();
            SampleTaskFX.SubjectCloned__c = 'Call';
            SampleTaskFX.Asset_Class__c = ConstantsUtils.FX;
            insert SampleTaskFX;
            /*Event SampleEventFX = UnitTestUtils.GetEvent(SampleUser.Id, SampleOpportunity.id, null);
            SampleEventFX.Asset_Class__c = ConstantsUtils.FX;
            SampleEventFX.StartDateTime = Date.today();
                        SampleEventFX.Location = 'Madrid, Spain';

            insert SampleEventFX;*/
            ctrlExt.getActivitiesByDate();
            ctrlExt.getOpenActivitiesBySubject();
            test.stopTest();

        }
    }


    static testMethod void testDataEQ(){
        gcal__GBL_Google_Calendar_Sync_Environment__c cs_gcal = new gcal__GBL_Google_Calendar_Sync_Environment__c();
        cs_gcal.Name = 'DEV';
        insert cs_gcal;
        Account SampleAccount = UnitTestUtils.GetStandardAccount();
        Insert SampleAccount;
        user SampleEQSalesUser = UnitTestUtils.GetFISalesUser();
        insert SampleEQSalesUser;
        AccountShare SampleAccShare = UnitTestUtils.GetAccountShareUser(SampleAccount.id, SampleEQSalesUser.id);
        insert SampleAccShare;
        System.runAs(SampleEQSalesUser) {
            Opportunity SampleOpportunity = UnitTestUtils.GetOpportunity(SampleAccount);
            insert SampleOpportunity;
            test.startTest();
            PageReference BannerAccount = Page.BannerAccount;
            test.setCurrentPage(BannerAccount);
            ApexPages.StandardController stdCtrl = new ApexPages.StandardController(SampleAccount);
            BannerAccountController ctrlExt = new BannerAccountController(stdCtrl);
            Task SampleTaskEQ = UnitTestUtils.GetTask(SampleEQSalesUser.Id, SampleOpportunity.id, null);
            SampleTaskEQ.ActivityDate = system.today();
            SampleTaskEQ.SubjectCloned__c = 'Call';
            SampleTaskEQ.Asset_Class__c = ConstantsUtils.EQ;
            insert SampleTaskEQ;
            /*Event SampleEventEQ = UnitTestUtils.GetEvent(SampleEQSalesUser.Id, SampleOpportunity.id, null);
            SampleEventEQ.Asset_Class__c = ConstantsUtils.EQ;
            SampleEventEQ.StartDateTime = Date.today();
                        SampleEventEQ.Location = 'Madrid, Spain';

            insert SampleEventEQ;*/
            ctrlExt.getActivitiesByDate();
            ctrlExt.getOpenActivitiesBySubject();
            Map<Integer, Integer> map_int;
            BannerAccountController.toMonthList(null);
            BannerAccountController.listToChain(null);
            test.stopTest();

        }
    }


     static testMethod void testDataFI_FX(){
         gcal__GBL_Google_Calendar_Sync_Environment__c cs_gcal = new gcal__GBL_Google_Calendar_Sync_Environment__c();
        cs_gcal.Name = 'DEV';
        insert cs_gcal;
        Account SampleAccount = UnitTestUtils.GetStandardAccount();
        Insert SampleAccount;
        user SampleUser = UnitTestUtils.GetFISalesUser();
        insert SampleUser;
        AccountShare SampleAccShare = UnitTestUtils.GetAccountShareUser(SampleAccount.id, SampleUser.id);
        insert SampleAccShare;
        System.runAs(SampleUser) {
            Opportunity SampleOpportunity = UnitTestUtils.GetOpportunity(SampleAccount);
            insert SampleOpportunity;
            test.startTest();
            PageReference BannerAccount = Page.BannerAccount;
            test.setCurrentPage(BannerAccount);
            ApexPages.StandardController stdCtrl = new ApexPages.StandardController(SampleAccount);
            BannerAccountController ctrlExt = new BannerAccountController(stdCtrl);
            Task SampleTaskEQ = UnitTestUtils.GetTask(SampleUser.Id, SampleOpportunity.id, null);
            SampleTaskEQ.ActivityDate = system.today();
            SampleTaskEQ.SubjectCloned__c = 'Call';
            SampleTaskEQ.Asset_Class__c = ConstantsUtils.FI;
            insert SampleTaskEQ;
            /*Event SampleEventEQ = UnitTestUtils.GetEvent(SampleUser.Id, SampleOpportunity.id, null);
            SampleEventEQ.Asset_Class__c = ConstantsUtils.FI;
            SampleEventEQ.StartDateTime = Date.today();
                        SampleEventEQ.Location = 'Madrid, Spain';

            insert SampleEventEQ;*/
            ctrlExt.getActivitiesByDate();
            ctrlExt.getOpenActivitiesBySubject();
            test.stopTest();

        }
    }


    static testMethod void testDataAccountError(){
       Account SampleAccount = UnitTestUtils.GetStandardAccount();
            test.startTest();
            PageReference BannerAccount = Page.BannerAccount;
            test.setCurrentPage(BannerAccount);
            ApexPages.StandardController stdCtrl = new ApexPages.StandardController(SampleAccount);
            BannerAccountController ctrlExt = new BannerAccountController(stdCtrl);

            ctrlExt.getActivitiesByDate();
            ctrlExt.getOpenActivitiesBySubject();
            test.stopTest();
    }



}