/*------------------------------------------------------------------------------------------------------
    Author:
    Company:       Accenture
    Description:   Case deletion job that fires CaseCleaner:BATCH

    History:
    2017-03-27                          Creación de la clase
    --------------------------------------------------------------------------------------------------------*/
global without sharing class SER_CaseCleaner_JOB implements Schedulable {
  /*@FieldType : String
      @Value/Usage : Query usada para elegir que casos se borran en el batch.
    */
  String query {get; set;}
  /*
      @Author: Juan Carlos Terrón Ruiz
      @Method: Constructor simple que inicializa la query a blanco para que el execute
      tire directamente del constructor simple del batch.
    */
  public SER_CaseCleaner_JOB() {
    this.query='';
  }
  /*
      @Author: Juan Carlos Terrón Ruiz
      @Method: Constructor con parámetro que inicializa la query al valor pasado para que el execute
      tire directamente del constructor complejo del batch.
    */
  public SER_CaseCleaner_JOB(String query) {
    this.query = query;
  }
  /*--------------------------------------------------------------------------------------------
      Author:
      Company:       Accenture
      Description:   Method that fires the deletion batch using a default query.
          IN:            SchedulableContext
      OUT:           void

      History:
      <Date>                  <Author>                <Change Description>
      07/08/2017                                                       Initial version
      ---------------------------------------------------------------------------------------------*/
  global void execute(SchedulableContext pSc) {
    SER_CaseCleaner_BATCH cleanerBatch;
    if(String.isNotBlank(this.query)) {
      cleanerBatch = new SER_CaseCleaner_BATCH(this.query);
    } else {
      cleanerBatch = new SER_CaseCleaner_BATCH();
    }
    Database.executebatch(cleanerBatch);
  }
}