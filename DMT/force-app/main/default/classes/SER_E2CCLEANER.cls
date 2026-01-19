/*@Author:        Juan Carlos Terrón
        @Company:       Accenture Cloud First
        @Description:   Clase para gestionar los correos y sus casos de email-to-case

        History:

        <Date>              <Author>                <Change Description>
        ??/06/2017          Juan Carlos Terrón      Initial Version.
        01/09/2017          Brian Capilla           Corregidos varios errores en validate_Addresses que evitaban la correcta distribución entre buzones.
        06/09/2017          Brian Capilla           Corregido un error que provocaba la llegada de casos ya borrados del metodo checker_duplicatedEmailToCase, al validate_Addresses.
        07/09/2017          Brian Capilla           Englobados los metodos con captura de errores para mayor control sobre estos.
        05/12/2018					Juan Carlos Terrón			Corregidos errores de Sonar*/
public with sharing class SER_E2CCLEANER implements Queueable {
  /*Log To insert*/
  CIB_Log__c log;
  /*Newest case creation date*/
  public Datetime newestCD {get; set;}
  /*Oldest case creation date*/
  public Datetime oldestCD {get; set;}
  /*Base case creation date*/
  public Datetime timerange {get; set;}
  /*Mapa de casos a procesar para el borrado*/
  public Map<Id,Case> mapCases {get; set;}
  /*Mapa de casos para borrar tras el procesamiento*/
  public Map<Id,Case> mapToDelete {get; set;}
  /*Mapa de e2c code y caso asociado*/
  public Map<String,Case> mapCodes {get; set;}
  /*@Description Constructor*/
  public SER_E2CCLEANER(Map<Id,Case> mapCases) {
    final Boolean mapIsEmpty = mapCases == null;
    this.log = new CIB_Log__c();
    if(mapIsEmpty == false && mapCases.isEmpty() == false) {
      this.mapCases = mapCases;
    } else {
      this.mapCases = new Map<Id,Case>();
    }
    this.mapToDelete = new Map<Id,Case>();
    this.mapCodes = new Map<String,Case>();
    this.timerange = Datetime.now().addHours(-3);
  }
  /*Public Overrided execute method from schedulable class*/
  public void execute(QueueableContext context) {
    try {
      if(this.firstprocess() && this.secondprocess()) {
        this.finalprocess();
        this.log.CIB_Subject__c = 'E2C Cleaner Log';
        insert this.log;
      }
    } catch (Exception err) {
      this.log = new CIB_Log__c();
      this.log.CIB_Subject__c = 'E2C Cleaner TESTING';
      this.log.CIB_ErrorMessage__c = err.getMessage();
      insert this.log;
    }
  }
  /*@Author: Juan Carlos terrón Ruiz
    @Método : primer procesamiento de duplicidad sobre los casos*/
  public Boolean firstprocess() {
    Boolean result;
    for(Case caso : this.mapCases.values()) {
      this.calculateTimeRange(caso);
      this.checkCode(caso);
    }
    if(this.mapCodes.isEmpty() == false) {
      result = true;
    } else {
      result = false;
    }
    this.log.CIB_ErrorMessage__c += 'first process - mapCodes '+'\n'+this.mapCodes.keyset()+'\n';
    this.log.CIB_ErrorMessage__c += 'first process - mapToDelete '+'\n'+this.mapToDelete.keyset()+'\n';
    return result;
  }
  /*@Author: Juan Carlos terrón Ruiz
    @Método : segundo procesamiento de duplicidad sobre los casos*/
  public Boolean secondprocess() {
    Boolean result;
    Map<Id,Case> duplicatedCases;
    duplicatedCases = this.retrieveDuplicatedCases();
    if((this.oldestCD == null) == false) {
      this.newestCD = oldestCD.addSeconds(30);
      this.oldestCD = oldestCD.addSeconds(-30);
    }
    for(Case caso : duplicatedCases.values()) {
      if(this.checkTimeRange(caso)) {
        this.checkCode(caso);
      }
    }
    if(this.mapToDelete.isEmpty() == false) {
      result = true;
    } else {
      result = false;
    }
    this.log.CIB_ErrorMessage__c += 'second process - duplicatedCases '+'\n'+duplicatedCases.keyset()+'\n';
    this.log.CIB_ErrorMessage__c += 'second process - mapCodes '+'\n'+this.mapCodes.keyset()+'\n';
    this.log.CIB_ErrorMessage__c += 'second process - mapToDelete '+'\n'+this.mapToDelete.keyset()+'\n';
    return result;
  }
  /*@Author: Juan Carlos terrón Ruiz
    @Método : último procesamiento de duplicidad sobre los casos*/
  public void finalprocess() {
    Boolean process;
    process = true;
    while(process) {
      try {
        if(this.mapToDelete.isEmpty() == false) {
          this.deleteCases();
        }
        this.log.CIB_ErrorMessage__c += 'final process - delete success '+'\n'+this.mapToDelete.keyset()+'\n';
        process = false;
      } catch(DmlException dex) {
        String caseId,errorMsg;
        errorMsg = dex.getMessage();
        caseId = errorMsg.substring(errorMsg.indexOfIgnoreCase('500'),errorMsg.indexOfIgnoreCase('500')+18);
        this.log.CIB_ErrorMessage__c += 'final process - delete error:'+'\n'+errorMsg+'\n';
        this.log.CIB_ErrorMessage__c += 'final process - delete error id:'+caseId+'\n';
        if(String.isNotBlank(caseId) && errorMsg.contains('UNABLE_TO_LOCK_ROW') == false) {
          this.mapToDelete.remove(caseId);
          this.log.CIB_ErrorMessage__c += 'final process - delete error not lock row, deleted id: '+caseId+'\n';
        } else {
          this.log.CIB_ErrorMessage__c += 'final process - delete error lock row, enqueued Job';
          System.enqueueJob(new SER_E2CCLEANER(this.mapCases));
          process = false;
        }
      }
    }
  }
  /*@Author: Juan Carlos terrón Ruiz
    @Método : extraer los posibles casso duplicados de bbdd*/
  public Map<Id,Case> retrieveDuplicatedCases() {
    Map<Id,Case> mapDuplicated;
    mapDuplicated = new Map<Id,Case>();
    for(Case caso :
        [
          select Id,CaseNumber,
          CreatedDate,
          SER_EmailToCaseCode__c,
          SER_Business_Case_Type__c
          from Case
          where IsDeleted = false
                            AND
                              ((CreatedDate <= :this.newestCD
                                AND CreatedDate >= :this.oldestCD)
                              OR
                                (Id not in :this.mapCases.keyset()
                                AND CreatedDate >= :this.timerange))
                            AND SER_EmailToCaseCode__c in :this.mapCodes.keyset()
                            order by CaseNumber asc
        ]) {
      mapDuplicated.put(caso.Id,caso);
    }
    return mapDuplicated;
  }
  /*@Author: Juan Carlos terrón Ruiz
    @Método : borrado de los casos procesados*/
  public void deleteCases() {
    delete this.mapToDelete.values();
  }
  /*@Author: Juan Carlos terrón Ruiz
    @Método : establecimiento de fecha base de duplicidad*/
  public void calculateTimeRange(Case caso) {
    final Datetime casoCD = caso.CreatedDate;
    if((this.oldestCD == null) == false && casoCD < this.oldestCD) {
      this.oldestCD = casoCD;
    } else if(this.oldestCD == null) {
      this.oldestCD = casoCD;
    }
  }
  /*@Author: Juan Carlos terrón Ruiz
    @Método : comprueba si el caso está dentro del rango de fechas del procesamiento*/
  public Boolean checkTimeRange(Case caso) {
    Boolean result;
    final Datetime casoCD = caso.CreatedDate;
    if(casoCD >= this.oldestCD && casoCD <= this.newestCD) {
      result = true;
    } else {
      result = false;
    }
    return result;
  }
  /*@Author: Juan Carlos terrón Ruiz
    @Método : comprueba que el código del caso sea válido */
  public void checkCode(Case caso) {
    String code;
    code = caso.SER_EmailToCaseCode__c;
    if(this.mapCodes.containsKey(code) && this.mapCodes.get(code) != null) {
      this.compareCase(caso,this.mapCodes.get(code));
    } else {
      this.mapCodes.put(code,caso);
    }
  }
  /*@Author: Juan Carlos terrón Ruiz
    @Método : compara dos casos para saber cual va primero*/
  public Boolean compareCase(Case newcase,Case oldcase) {
    Boolean result;
    if((newcase.Id == oldcase.ID) == false) {
      if((newcase.CaseNumber == oldcase.CaseNumber) == false && newcase.CaseNumber < oldcase.CaseNumber) {
        if(newcase.CreatedDate <= oldcase.CreatedDate) {
          result = true;
          this.mapToDelete.put(oldcase.Id,oldcase);
          this.mapCodes.put(newcase.SER_EmailToCaseCode__c,newcase);
        }
      } else {
        result = false;
        this.mapToDelete.put(newcase.Id,newcase);
        this.mapCodes.put(oldcase.SER_EmailToCaseCode__c,oldcase);
      }
    } else {
      result = false;
    }
    return result;
  }
}