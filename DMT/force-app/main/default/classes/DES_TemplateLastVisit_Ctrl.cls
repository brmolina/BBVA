public without sharing class DES_TemplateLastVisit_Ctrl {

  /**
    *
    *
    * @author GlobalDesktop YELLOW
    */
   @AuraEnabled
    public static Boolean setLastVisit(String template) {
        Boolean flag;
        flag = false;
        final List<DES_Template__c> listtmp = new List<DES_Template__c>([SELECT id, Client_Id__c, Last_Visit_to_the_Client_desc__c, Opportunity_Product_Id__c, Pending_approval_type__c, RecordType.DeveloperName FROM DES_Template__c WHERE id = :template LIMIT 1]);

        if(listtmp != null && !listtmp.isEmpty()  && !listtmp[0].Pending_approval_type__c && listtmp[0].RecordType.DeveloperName != LABEL.DES_Template_PF) {
            DES_Template__c templ;
            templ = listtmp[0];
            String dPast;
            dPast = String.valueOf(templ.Last_Visit_to_the_Client_desc__c);
            System.debug('>>>>> STRING dPast: ' + dPast);
            final List<DES_Denorm_AccountVisits__c> listvisit = new List<DES_Denorm_AccountVisits__c>([SELECT id, DES_Start_Date__c FROM DES_Denorm_AccountVisits__c WHERE DES_Client__c = :templ.Client_Id__c AND DES_Start_Date__c != null AND DES_Start_Date__c <= TODAY ORDER BY DES_Start_Date__c DESC]);

            if(listvisit != null && !listvisit.isEmpty()) {
                String visitDate;
                visitDate = String.valueOf(listvisit[0].DES_Start_Date__c);
                visitDate = visitDate.split(' ').get(0);
                System.debug('>>>>> STRING visitDate: ' + visitDate);
                flag = updateTemplIfApplies(templ, dPast, visitDate, flag);
            }
        }
        System.debug('>>>>> flag : ' + flag);
        return flag;
    }

    /**
    *
    *
    * @author GlobalDesktop YELLOW
    */
    public static Boolean updateTemplIfApplies(DES_Template__c templ, String dPast, String visitDate, Boolean flagOrig) {
        Boolean flag = flagOrig;
        System.debug('>>>>> flag : ' + flag);
        system.debug('>>>>> dPast : --' + dPast + '--');
        system.debug('>>>>> visitDate : --' + visitDate + '--');
        // String dPastYear;
        // String dPastMonth;
        // String dPastDay;
        String visitDateYear;
        String visitDateMonth;
        String visitDateDay;
        // dPastYear = dPast.split('-').get(0);//ANIO-MES/DIA
        // dPastMonth = dPast.split('-').get(1);//ANIO-MES/DIA
        // dPastDay = dPast.split('-').get(2);//ANIO-MES/DIA
        visitDateYear = visitDate.split('-').get(0);//ANIO-MES/DIA
        visitDateMonth = visitDate.split('-').get(1);//ANIO-MES/DIA
        visitDateDay = visitDate.split('-').get(2);//ANIO-MES/DIA
        // system.debug('>>>>> dPastYear : ' + dPastYear);
        // system.debug('>>>>> dPastMonth : ' + dPastMonth);
        // system.debug('>>>>> dPastDay : ' + dPastDay);
        system.debug('>>>>> visitDateYear : ' + visitDateYear);
        system.debug('>>>>> visitDateMonth : ' + visitDateMonth);
        system.debug('>>>>> visitDateDay : ' + visitDateDay);
        // if(dPast == null || visitDateYear != dPastYear || visitDateMonth != dPastMonth || visitDateDay != visitDateDay) {
        if(dPast == null || dPast != visitDate) {
            System.debug('>>>>> ANTES: templ.Last_Visit_to_the_Client_desc__c : ' + templ.Last_Visit_to_the_Client_desc__c);
            System.debug('>>>>> date.newinstance(visitDate.year(), visitDate.month(), visitDate.day()) : ' + date.newinstance(Integer.valueof(visitDateYear), Integer.valueof(visitDateMonth), Integer.valueof(visitDateDay)));
            templ.Last_Visit_to_the_Client_desc__c = date.newinstance(Integer.valueof(visitDateYear),Integer.valueof( visitDateMonth), Integer.valueof(visitDateDay));
            try{
                update templ;
                flag = true;
            }catch(Exception error) {
                System.debug('>>>>> Error en update : ' + error);
            }
        }
        System.debug('>>>>> DESPUES UPDATE: templ.Last_Visit_to_the_Client_desc__c : ' + templ.Last_Visit_to_the_Client_desc__c);
        return flag;
    }
}