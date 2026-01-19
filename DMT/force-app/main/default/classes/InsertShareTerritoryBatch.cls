/**********************************************************************************
* @author  		Global Desktop
* @date         09/09/2019
* @description  Batch que asigna a las account territorios
* @Revision
**********************************************************************************/
public without sharing class InsertShareTerritoryBatch implements Database.Batchable<Sobject>, Database.Stateful {
	/*
   *  VARIABLE
  **/
  private List<sObject> myList; //NOSONAR

  /*
   *  CONSTRUCTOR
  **/
  public InsertShareTerritoryBatch (List<sObject> objList) {
    myList = objList;
    system.debug('>>>>> myList : ' + myList);
  }

  /*
   *  start
  **/
  public Iterable<sObject> start(Database.BatchableContext batchCntx) {
    return myList;
  }


  /*
   *  execute
  **/
  public void execute(Database.BatchableContext batchCntx, List<sObject> objetos) {
    System.debug('::::: objetos : ' + objetos);
    insert objetos;
    System.debug('::::: objetos : ' + objetos);

  }//FIN execute

  /*
   *  finish
  **/
  public void finish(Database.BatchableContext batchCntx) {    }


}