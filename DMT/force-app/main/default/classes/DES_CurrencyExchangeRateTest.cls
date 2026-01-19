/*
*	ESTA CLASE CONTIENE LAS CLASES DE TEST DE CLASES QUE SE TIENEN QUE BORRAR
*
*
**/
@isTest
private class DES_CurrencyExchangeRateTest{
       
    @isTest
    static void testTrigger(){
        
        DES_UtilTestClass testClass = new DES_UtilTestClass();
        
        String idProfile = testClass.createProfile();
        User userTest = testClass.createUser(idProfile);
        insert userTest;
        CIB_User_Org__c userSettings = testClass.createCustomSetting();
        insert userSettings;
      
        system.runAs(userTest){
            
            DES_CurrencyExchangeRate_Handler currencyExchange = new DES_CurrencyExchangeRate_Handler();
            DES_CustomReportChart customReportChart = new DES_CustomReportChart();
            String str = DES_CustomReportChart.getreport('qwerty');
        }
    }


}