/**-------------------------------------------------------------------------------------------
* @Name     DMT Consolidate Lines
* @Author   torcuato.tejada.tech@bbva.com
* @Date     Created: 2023-04-24
* ------------------------------------------------------------------------------------------------
* @Description This batch runs every night at 21:00 MON-FRI and consolidate lines modified or created today into a table,
* that is then collected from APX job.
* ------------------------------------------------------------------------------------------------
*/
global class DMT_BatchConsolidateLines implements Database.Batchable<sObject>, Schedulable {

    global final String query;

    public DMT_BatchConsolidateLines() {
        query = 'SELECT Id, Name, RecordType.Name, Amount__c, Max_Tenor__c, Clearing__c, Allowed__c, Status__c, Client__r.DES_Group_Code__c, DvP_Amount__c, Custom_Association__c, FD_Amount__c, Line_Term__c, Start_Date__c, End_Date__c, Product__c, Booking_Geography__c, Closed__c, DvP_Currency__c, FD_Currency__c, Client_Type__c, Treasury_Currency__c, Depos_Limit__c, Depos_Limit_1Y__c, Equity_Limit__c, Repos_Limit__c, Repos_Limit_6M__c, First_Breakclause__c, Breakclause_Frequency__c, Total_Limit_Treasury_Risk__c, First_Term_Treasury_Risk__c, Second_Term_Treasury_Risk__c, Third_Term_Treasury_Risk__c, Fourth_Term_Treasury_Risk__c, Fifth_Term_Treasury_Risk__c, Sixth_Term_Treasury_Risk__c, Seventh_Term_Treasury_Risk__c, Eighth_Term_Treasury_Risk__c, Waiver__c FROM DMT_Line__c WHERE RecordType.Name =\'Settlement\' AND CreatedDate > 2024-06-28T00:00:00Z AND CreatedDate < 2024-06-28T23:59:59Z';
    }

    global Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator(query);
    }

    global void execute(Database.BatchableContext bc, List<DMT_Line__c> lines) {

        List<DMT_Consolidated_Line__c> consolidatedLines = new List<DMT_Consolidated_Line__c>();
        List<Id> ids = new List<Id>();

        Map<String, Account> accounts = getAccountInfo(lines);

        for (DMT_Line__c line : lines) {

            Account acc = accounts.get(line.Client__c);

            if (acc == null) {
                continue;
            }

            DMT_Consolidated_Line__c consolidatedLine = new DMT_Consolidated_Line__c();

            if (acc.DES_Structure_Type__c == 'Subsidiary') {
                consolidatedLine.g_customer_id__c = 'ES1082' + acc.SER_CClient__c;
            } else {
                consolidatedLine.gf_customer_group_id__c = acc.DES_Group_Code__c;
            }

            consolidatedLine.gf_additional_comments_desc__c = line.Name;
            consolidatedLine.gf_from_date__c = line.Start_Date__c;
            consolidatedLine.gf_to_date__c = line.End_Date__c;
            consolidatedLine.g_currency_id__c = line.Treasury_Currency__c;
            consolidatedLine.gf_condition_line_amount__c = line.Amount__c;

            consolidatedLines.add(consolidatedLine);
        }

        if (consolidatedLines.size() > 0) {
            insert consolidatedLines;
        }
    }

    global void finish(Database.BatchableContext bc) {
        AsyncApexJob a = [SELECT Id, Status, NumberOfErrors, JobItemsProcessed, TotalJobItems, CreatedBy.Email FROM AsyncApexJob WHERE Id = :bc.getJobId()];
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        String[] toAddresses = new String[] {a.CreatedBy.Email};
        mail.setToAddresses(toAddresses);
        mail.setSubject('Batch DMT Consolidate Lines finished with status ' + a.Status);
        mail.setPlainTextBody
        ('The batch DMT Consolidate Lines processed ' + a.TotalJobItems +
        ' batches with '+ a.NumberOfErrors + ' failures.');
        Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
    }

    global void execute(SchedulableContext sc) {
        DMT_BatchConsolidateLines batch = new DMT_BatchConsolidateLines();
        Database.executeBatch(batch, 200);
    }

    global static String scheduleBatch() {
        String cron = '0 0 21 * MON-FRI ?';
        DMT_BatchConsolidateLines batch = new DMT_BatchConsolidateLines();
        return System.schedule('DMT_BatchConsolidateLines', cron, batch);
    }

    private Map<String, Account> getAccountInfo(List<DMT_Line__c> lines) {
        List<Id> ids = new List<Id>();
        for (DMT_Line__c line : lines) {
            ids.add(line.Client__c);
        }
        Map<String, Account> accountMap = new Map<String, Account>();
        List<Account> accounts = [SELECT ID, Name, SER_CClient__c, DES_Structure_Type__c, DES_Group_Code__c from Account WHERE id IN :ids];
        for (Account acc : accounts) {
            accountMap.put(acc.Id, acc);
        }
        return accountMap;
    }

}