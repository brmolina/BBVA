/*
* Test class for RCFEvolutionCnt
*/
@isTest
public with sharing class RCFEvolutionCnt_Test {
    /*
    * Test method1
    */
    @isTest
    public static void getDataTest() {
        final DES_UtilTestClass test = new DES_UtilTestClass();
        final Account acc = test.createClient();
        insert acc;
        final RCF_Evolution__c evolution = new RCF_Evolution__c();
        evolution.year_month_day_date__c = date.today();
        evolution.participant_id__c = acc.Id;
        evolution.credit_drawn_per__c = 5;
        insert evolution;

        final String data = RCFEvolutionCnt.getData(acc.Id);
        system.assertNotEquals(null, data, 'notnull');
    }

    /*
    * Test method2
    */
    @isTest
    public static void getDataReportTest() {
        final DES_UtilTestClass test = new DES_UtilTestClass();
        final Account acc = test.createClient();
        insert acc;
        final RCF_Evolution__c evolution = new RCF_Evolution__c();
        evolution.year_month_day_date__c = date.today();
        evolution.participant_id__c = acc.Id;
        evolution.credit_drawn_per__c = 5;
        insert evolution;

        final String data = RCFEvolutionCnt.getDataReport(acc.Id);
        system.assertNotEquals(null, data, 'notnull');
    }

    /*
    * Test method3
    */
    @isTest
    public static void getDateNull() {
        final DES_UtilTestClass test = new DES_UtilTestClass();
        final Account acc = test.createClient();
        insert acc;
        final RCF_Evolution__c evolution = new RCF_Evolution__c();
        evolution.participant_id__c = acc.Id;
        evolution.credit_drawn_per__c = 5;
        insert evolution;
        final RCFEvolutionCnt instance = RCFEvolutionCnt.gtInstance(); //NOSONAR
        final String data = RCFEvolutionCnt.getData(acc.Id);
        system.assertNotEquals(null, data, 'notnull');
    }
}