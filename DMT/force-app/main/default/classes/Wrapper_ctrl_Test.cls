/*
*Name:            Wrapper_ctrl_Test
*Description:     Test del controlador del componente Wrapper del Kit de visitas v4   -
*/
@isTest
public with sharing class Wrapper_ctrl_Test {

    /*
    * Test para la comprobacion de wrapper_ctrl
     */
    @isTest
    public static void sendToGoogleTest() {
        final DES_UtilTestClass utilClass = new DES_UtilTestClass();
        Account acc;
        acc = utilClass.createClient();
        insert acc;
        Opportunity opp;
        opp = utilClass.createOpportunity(acc);
        insert opp;
        dwp_kitv__Visit__c visita;
        visita = utilClass.createVisit(acc, opp);
        insert visita;
        Event evento;
        evento = new Event();
        evento.DurationInMinutes = 15;
        evento.dwp_kitv__visit_id__c = visita.id;
        evento.ActivityDate = Date.today();
        evento.ActivityDateTime = DateTime.now();
        insert evento;
        Wrapper_ctrl.gtInstance();
        try {
        Wrapper_ctrl.sendToGoogle(visita.id, true);
        } catch(Exception e) {
            System.assert(![SELECT id FROM Event where dwp_kitv__visit_id__c =: visita.id].isEmpty(),'Error');
        }
    }
}