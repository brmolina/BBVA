/***************************************************************************************
* @author       BBVA
* @date         17-07-2020
* @description  Class to test UtilInitiatives.

****************************************************************************************/
@isTest
private class UtilInitiatives_Test {


    /**
    *@Author: Global Desktop
    *Description: INsert
    */
    @isTest
    public static void insertDataloaderTest() {
        Test.startTest();
        final List<intt__Team_initiative__c> lstTeam=new List<intt__Team_initiative__c>();

        final List<User> lstUsuario=[select id,email from user limit 10];
        for(Integer i=0;i<lstUsuario.Size();i++) {

           lstUsuario[i].Email=i+'hdora@gmail.com';
           final intt__Team_initiative__c obj=new intt__Team_initiative__c();
           obj.intt__manager_team_id__c=lstUsuario[i].id;
           obj.intt__manager_team_id__r=lstUsuario[i];
           lstTeam.add(obj);

        }

        UtilInitiatives.sendMailPaquete('hola', '<h1>hola</h1>',lstTeam,true);
        UtilInitiatives.sendMail('hola', '<h1>hola</h1>',lstTeam);
        UtilInitiatives.gtInstance();
        Test.stopTest();
        System.assertNotEquals(lstUsuario.size(), 0);

    }
}