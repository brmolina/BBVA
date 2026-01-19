/*------------------------------------------------------------------------------------------------------
    Author:
    Company:       Accenture
    Description:   Case deletion batch

    History:
    2017-03-27                          Creación de la clase
    --------------------------------------------------------------------------------------------------------*/
global without sharing class SER_CaseCleaner_BATCH implements Database.Batchable<sObject> {
  /* Query used to filter case to delete */
  String stQuery;

  /*--------------------------------------------------------------------------------------------
      Author:
      Company:       Accenture
      Description:   Constructor that gets the query used to filter the cases to delete.

      History:
      <Date>                  <Author>                <Change Description>
      07/08/2017                                                       Initial version
      ---------------------------------------------------------------------------------------------*/
  global SER_CaseCleaner_BATCH(String query) {
    this.stQuery = query;
  }

  /*--------------------------------------------------------------------------------
      Author:
      Company:       Accenture
      Description:   Constructor that uses a query predefined on a CustomLabel.

      History:
      <Date>                  <Author>                <Change Description>
      07/08/2017                                                       Initial version
      ----------------------------------------------------------------------------------*/
  global SER_CaseCleaner_BATCH() {
    this.stQuery = Label.SER_UntypedCaseCleanerJOB_Query;
  }

  /*--------------------------------------------------------------------------------
      Author:
      Company:       Accenture
      Description:   Implementation of Start method
          IN:            BatchableContext
      OUT:           void

      History:
      <Date>                  <Author>                <Change Description>
      07/08/2017                                                       Initial version
      ----------------------------------------------------------------------------------*/
  global Database.QueryLocator start(Database.BatchableContext pBC) {
    return Database.getQueryLocator(this.stQuery);
  }

  /*-----------------------------------------------------------------------------------------
      Author:
      Company:       Accenture
      Description:   Executes the deletion batch over a list of objects received by parameter
          IN:            BatchableContext, List<sObject>
      OUT:           void

      History:
      <Date>                  <Author>                <Change Description>
      07/08/2017                                                       Initial version
      -------------------------------------------------------------------------------------------*/
  global void execute(Database.BatchableContext pBC, List<sObject> scope) {
    delete scope;
  }

  /*--------------------------------------------------------------------------------
      Author:
      Company:       Accenture
      Description:   No action on finish.

      IN:            BatchableContext
      OUT:           void

      History:
      <Date>                  <Author>                <Change Description>
      07/08/2017                                                       Initial version
      ----------------------------------------------------------------------------------*/
  global void finish(Database.BatchableContext pBC) {

  }

}