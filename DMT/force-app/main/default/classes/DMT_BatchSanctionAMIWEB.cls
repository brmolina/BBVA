/**-------------------------------------------------------------------------------------------
* @Name     DMT Sanction AMIWEB
* @Author   diego.peran.tech@bbva.com
* @Date     Created: 2024-010-24
* ------------------------------------------------------------------------------------------------
* @Description This batch runs every night  and update Dmt_Lines with AMIWEB origin and Draft Status
* ------------------------------------------------------------------------------------------------
*/
global class DMT_BatchSanctionAMIWEB implements Database.Batchable<sObject>, Schedulable {

    global final String query;

    public DMT_BatchSanctionAMIWEB() {
        query = 'SELECT Id, Name, Status__c, Closed__c, DMT_Status_Completed__c, g_line_status_type__c FROM DMT_Line__c WHERE Status__c = \'Draft\' AND (DMT_Origin__c =  \'XX\' OR DMT_Origin__c =  \'AMIWEB\') AND Client_Type__c = \'Customer\'';
    }

    global Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator(query);
    }

    global void execute(Database.BatchableContext bc, List<DMT_Line__c> lines) {

        Map<String, String> mapStatus = new Map<String, String>{'DR' => 'Draft', 'PR' => 'Proposal', 'AP' => 'Approval', 'CS' => 'Ready to close', 'CL' => 'Closed', 'CW' => 'Closed'};
        for (DMT_Line__c line : lines) {
            line.Status__c = mapStatus.get(line.g_line_status_type__c);
            if(line.g_line_status_type__c == 'CW'){
                 line.Closed__c = DMT_Constants.WON;
            }
            if(line.g_line_status_type__c == 'CL'){
                 line.Closed__c = 'Lost';
            }
           
        }

        try{   
            if (lines.size() > 0) {
                update lines;
                //Database.update(lines,false);
            }
                
        }catch (DmlException e) {
            System.debug(e.getMessage());
            //DES_Exception_Utils.logException(e,'DMT_BatchSanctionAMIWEB', 'execute', 'DMT', '');
        }
        
    }

    global void finish(Database.BatchableContext bc) {
        AsyncApexJob a = [SELECT Id, Status, NumberOfErrors, JobItemsProcessed, TotalJobItems, CreatedBy.Email FROM AsyncApexJob WHERE Id = :bc.getJobId()];
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        String[] toAddresses = new String[] {a.CreatedBy.Email};
        mail.setToAddresses(toAddresses);
        mail.setSubject('Batch AMIWEB Sanctions finished with status ' + a.Status);
        mail.setPlainTextBody
        ('The batch AMIWEB Sanctions processed ' + a.TotalJobItems +
        ' batches with '+ a.NumberOfErrors + ' failures.');
        Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
    }

    global void execute(SchedulableContext sc) {
        DMT_BatchSanctionAMIWEB batch = new DMT_BatchSanctionAMIWEB();
        Database.executeBatch(batch, 200);
    }



}