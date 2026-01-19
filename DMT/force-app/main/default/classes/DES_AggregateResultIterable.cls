/***********************************************************************************************************************************************
Name:           DES_AggregateResultIterable 
Description:    Como la clase batch DES_DenormalizeContactsExecute lanza una query con un Aggregate y no son soportados en las clases Apex batch,
				se modifica la clase batch DES_DenormalizeContactsExecute y además se crean 2 nuevas clases: 
					- DES_AggregateResultIterable
					- DES_AggregateResultIterator

Test Class:     DES_DenormalizeContacts_Test

Version        Date            Author            Summary of changes
-------------------------------------------------------------------------------------------------------------------------------------------------
0.1            12/12/2018      Accenture         Class creation    
0.2            13/12/2018      Accenture         Se lanza directamente la query en la clase DES_AggregateResultIterator para que no de error al 
                                                 subir la clase en Bitbucket
*************************************************************************************************************************************************/
global with sharing class DES_AggregateResultIterable implements Iterable<AggregateResult> {
  //private String query;

  //--------------------------------------- CONSTRUCTOR METHODS --------------------------------------------------------------------------------
  //global DES_AggregateResultIterable(String soql){
  //  query = soql;
  //}

  /**
  * 
  * @author       JSS
  * @description  Llamada al constructor de la clase DES_AggregateResultIterator
  */
  global Iterator<AggregateResult> iterator() {
    return new DES_AggregateResultIterator(); //DES_AggregateResultIterator(query);
  }
}