/* Test de Home_NPS_Button_Controller
*/
@istest
public with sharing class Home_NPS_Button_Controller_Test {
    @istest
    private static void doTest() {
        Final Home_NPS_Button_Controller controllerNPS = new Home_NPS_Button_Controller();
        System.System.debug(controllerNPS);
        NPS_Wave__c waveTest;
        waveTest = new NPS_Wave__c();
        waveTest.nps_start_date__c = date.today()+2;
        waveTest.nps_end_date__c = date.today()+4;
        insert waveTest;
        Home_NPS_Button_Controller.getWave();
        waveTest.nps_start_date__c = date.today()-2;
        waveTest.nps_end_date__c = date.today()+2;
        update waveTest;
        Home_NPS_Button_Controller.getWave();
        System.assertEquals(waveTest.nps_start_date__c, date.today()-2, 'Respuesta esperada OK');
    }
}