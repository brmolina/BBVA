/********************************************************************************************
Name:             DES_Batch_UpdatePitchFamily
Description:      Actualiza la familia de los pitches GF, CF y producto STF de GTB

Version        Date            Author            Summary of changes
---------------------------------------------------------------------------------------------
0.1            23/01/2020      Global Desktop    Actualiza la familia de las visitas GF
*********************************************************************************************/
public without sharing class DES_Batch_UpdatePitchFamily implements Database.Batchable<Sobject>, Database.Stateful {

	/*Variables globales*/
    final static String GFFAMILY = 'GF';
    /*Variables globales*/
    final static String CFFAMILY = 'CF';
    /*Variables globales*/
    final static String GTBFAMILY = 'GTB';
    /*Variables globales*/
    final static String STFPRODUCTO = 'Structured Trade Finance';

    /*Query*/
  	final private String query = 'SELECT pith__solution_category_name__c, pith__solution_name_path_desc__c FROM pith__Pitch__c ' +
        + 'WHERE pith__solution_category_name__c = :GFFAMILY OR pith__solution_category_name__c = :CFFAMILY ' +
        + 'OR (pith__solution_category_name__c = :GTBFAMILY AND pith__solution_name_path_desc__c = :STFPRODUCTO)';

	/*Constructor method*/
    public DES_Batch_UpdatePitchFamily() {
    	system.debug('>>>>> Query: ' + query);
  	}

	/*Start method*/
    public Database.QueryLocator start(Database.BatchableContext batchc) {
    	return Database.getQueryLocator(query);
  	}

	/*Execute method*/
    public void execute(Database.BatchableContext batchc, List<pith__Pitch__c> listPitches) {
		final List<pith__Pitch__c> listUpdate = new List<pith__Pitch__c>();
        for(pith__Pitch__c pitch : listPitches) {
            pitch.pith__solution_category_name__c = 'IBF';
            listUpdate.add(pitch);
        }
        update listUpdate;
  	}

    /*Finish method*/
    public void finish(Database.BatchableContext batchc) {
        final AsyncApexJob job = [SELECT Id, Status, NumberOfErrors, JobItemsProcessed, TotalJobItems, CreatedBy.Email FROM AsyncApexJob WHERE Id = :batchc.getJobId()];
        System.debug('>>>>> SUMMARY: ');
        System.debug('>>>>>   Batches Created: ' + job.JobItemsProcessed);
        System.debug('>>>>>   Number of Errors: ' + job.NumberOfErrors);
        System.debug('>>>>>   Status: ' + job.Status);
  	}

}