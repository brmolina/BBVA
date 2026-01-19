/***********************************************************************************************
Name:            DES_MigrateProductsOpportunity_Batch
Description:     Batch class to migrate the product of the opportunity
Test Class:      -

Version        Date            Author            Summary of changes
------------------------------------------------------------------------------------------------
1.0            16/08/2019                        Class creation

***********************************************************************************************/
public class DES_MigrateProductsOpportunity_Batch implements Database.Batchable<sObject>, Database.Stateful {
    /**
	 * Query used in the batch
	 */
    String batchQuery;

    /**
	 * Map product code and product version Id
	 */
    Map<String, Id> mapProductVersion {
        get {
            if(mapProductVersion == null) {
                mapProductVersion = new Map<String, Id>();
                for(fprd__GBL_Product_version__c iProductVersion : [SELECT Id,
                                                                        fprd__Product__r.ProductCode
                                                                    FROM fprd__GBL_Product_version__c
                                                                    WHERE fprd__Active__c = false
                                                                        AND fprd__Product__r.ProductCode LIKE '%code%']) {
                    mapProductVersion.put(iProductVersion.fprd__Product__r.ProductCode, iProductVersion.Id);
                }
            }
            return mapProductVersion;
        } set;
    }

    /**
     * Constructor
     */
    public DES_MigrateProductsOpportunity_Batch(String query) {
        this.batchQuery = query;
    }

    /**
	 * Implementation of the start method of the Database.Batchable interface
     */
    public Database.QueryLocator start(Database.BatchableContext batchableContext) {
        return Database.getQueryLocator(batchQuery);
    }

    /**
	 * Implementation of the execute method of the Database.Batchable interface
     */
    public void execute(Database.BatchableContext batchableContext, List<SObject> records) {
        List<Opportunity> listOpp = new List<Opportunity>();
        listOpp = (List<Opportunity>) records;

        final Savepoint iSavePoint = Database.setSavepoint();
        try {
            final List<OpportunityLineItem> listOppLIToInsert = new List<OpportunityLineItem>();
            final List<OpportunityLineItem> listOppLIToDelete = new List<OpportunityLineItem>();

            final Map<String, Schema.SObjectField> fieldMap = OpportunityLineItem.sObjectType.getDescribe().fields.getMap();

            final List<String> fieldNames = new List<String>();
            fieldNames.addAll(fieldMap.keySet());

            final String allFields = String.join(fieldNames, ',').replaceAll('totalprice,', '');

            List<OpportunityLineItem> listOppLI = Database.query('SELECT Product2.ProductCode, ' + allFields + ' FROM OpportunityLineItem WHERE OpportunityId IN :listOpp AND fprd__GBL_Product_version__c = null');
            if(Test.isRunningTest()) { //NOSONAR
                listOppLI = Database.query('SELECT Product2.ProductCode, ' + allFields + ' FROM OpportunityLineItem WHERE OpportunityId IN :listOpp');
            }

            for(OpportunityLineItem iOppLI : listOppLI) {
                OpportunityLineItem newOppLI = new OpportunityLineItem();
                newOppLI = iOppLI.clone(false, true);

                newOppLI.fprd__GBL_Product_version__c = mapProductVersion.get(iOppLI.Product2.ProductCode);

                listOppLIToInsert.add(newOppLI);
                listOppLIToDelete.add(iOppLI);
            }

            if(!listOppLIToInsert.isEmpty()) {
                insert listOppLIToInsert;
            }

            if(!listOppLIToDelete.isEmpty()) {
                delete listOppLIToDelete;
            }
        } catch(Exception e) {
            Database.rollback(iSavePoint);
            System.debug(e);
        }
    }

    /**
	 * Implementation of the finish method of the Database.Batchable interface
     */
    public void finish(Database.BatchableContext batchableContext) {
        System.debug('DES_MigrateProductsOpportunity_Batch finish');
    }
}