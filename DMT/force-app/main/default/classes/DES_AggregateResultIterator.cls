/***********************************************************************************************************************************************
Name:           DES_AggregateResultIterator 
Description:    Como la clase batch DES_DenormalizeContactsExecute lanza una query con un Aggregate y no son soportados en las clases Apex batch,
				se modifica la clase batch DES_DenormalizeContactsExecute y además se crean 2 nuevas clases: 
					- DES_AggregateResultIterator
					- DES_AggregateResultIterator

Test Class:     DES_DenormalizeContacts_Test

Version        Date            Author            Summary of changes
-------------------------------------------------------------------------------------------------------------------------------------------------
0.1            12/12/2018      Accenture         Class creation    
0.2            13/12/2018      Accenture         Se lanza directamente la query en la clase DES_AggregateResultIterator para que no de error al 
                                                 subir la clase en Bitbucket
************************************************************************************************************************************************/
global with sharing class DES_AggregateResultIterator implements Iterator<AggregateResult> {
 /**
  * 
  * @author       JSS
  * @description  variable returned in method AggregateResult
  */
  AggregateResult [] results {get;set;}
  
  /**
  * 
  * @author       JSS
  * @description  tracks which result item is returned
  */
  Integer index {get; set;} 
       
  /**
  * 
  * @author       JSS
  * @description  Constructor with soql query
  */    
  global DES_AggregateResultIterator() { //(String query) {
  	Final String query = 'SELECT ContactId,Contact.AccountId aid,Contact.CurrencyIsoCode cic, count(AccountId) cnt FROM AccountContactRelation WHERE Contact.RecordType.Name = \'Desktop Contact\' AND Contact.Account.DES_Structure_Type__c = \'Subsidiary\' GROUP BY ContactId,Contact.AccountId,Contact.CurrencyIsoCode HAVING count(AccountId)<2 LIMIT 2000';
    index = 0;
    results = Database.query(query);            
  } 

  global boolean hasNext(){ 
    return results != null && !results.isEmpty() && index < results.size(); 
  }    

  global AggregateResult next(){        
    return results[index++];            
  }       
}