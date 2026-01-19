/**********************************************************************************
* @author       Global Desktop
* @date         29/04/2020
* @description  Controller del componente de Pitch_Related_List
**********************************************************************************/
public with sharing class Pitch_Related_List_Controller {
  /**
  * @author Global Desktop
  * @Description Empty constructor
  */
  private Pitch_Related_List_Controller() {
    System.debug('Empty constructor');
  }

  /**
  * @author Global Desktop
  * @description Method para recuperar los pitches relacionadas al cliente
  */
  @auraEnabled
  public static String relatedPitches(String tableSize, String iAccountId, String family) {
    try {
      final String famFilter = '%' + family + '%';
      system.debug(famFilter);

      final Set<Id> setPitchId = new Set<Id>();
      final List<Denorm_Account_Pitch__c> listDenormPitch = [SELECT Id,
                                                        participant_id__c,
                                                        gf_pitch_id__c
                                                      FROM Denorm_Account_Pitch__c
                                                      WHERE participant_id__c = :iAccountId];
      setPitchId.add(listDenormPitch[0].gf_pitch_id__c);

      List<pith__Pitch__c> listPitch = new List<pith__Pitch__c>();
      if(trueCondition(family)) {
        System.debug('::::::::::famfilter: ' + famfilter);
        listPitch = [SELECT Id,
                      Name,
                      pith__participant_id__c,
                      pith__participant_id__r.Name,
                      pith__solution_category_name__c,
                      pith__solution_name_path_desc__c,
                      pith__country_name__c
                    FROM pith__Pitch__c
                    WHERE Id IN :setPitchId
                      AND pith__solution_category_name__c LIKE :famfilter];
      } else {
        listPitch = [SELECT Id,
                      Name,
                      pith__participant_id__c,
                      pith__participant_id__r.Name,
                      pith__solution_category_name__c,
                      pith__solution_name_path_desc__c,
                      pith__country_name__c
                    FROM pith__Pitch__c
                    WHERE Id IN :setPitchId];
      }

      List<WrapperClass> listWrapperClass = new List<WrapperClass>();
      for(pith__Pitch__c iPitch : listPitch) {
        WrapperClass iWrapperClass;
          iWrapperClass= new WrapperClass(
          iPitch.Name,
          iPitch.Id,
          iPitch.pith__participant_id__r.Name,
          iPitch.pith__participant_id__c,
          iPitch.pith__solution_category_name__c,
          // iPitch.pith__solution_name_path_desc__c,
          iPitch.pith__country_name__c,
          listPitch.size());
        listWrapperClass.add(iWrapperClass);
      }

      listWrapperClass = getListWrapper(listWrapperClass, tableSize);

      return JSON.serialize(listWrapperClass);
    } catch(Exception exc) {
      throw new AuraHandledException(Label.DES_Error + exc);
    }
  }

  /**
   * @author Global Desktop
   * @description Method auxiliar para crear la lista de los pitches que se quieren mostrar
   */
  private static List<WrapperClass> getListWrapper(List<WrapperClass> listWrapperClass, String tableSize) {
    Integer tSize;
    if(tableSize != null) {
      tSize = Integer.valueOf(tableSize);
    }
    final List<wrapperClass> listaWrapperAux = new List<wrapperClass>();
    if(tSize != null) {
      Integer regTable = tSize;
      if(tSize > listWrapperClass.size()) {
        regTable = listWrapperClass.size();
      }
      for(Integer cn = 0; cn < regTable ; cn++) {
        if(!listWrapperClass.isEmpty() && listWrapperClass.get(cn) != null) {
          listaWrapperAux.add(listWrapperClass.get(cn));
        }
      }
    }

    return listaWrapperAux;
  }

  /**
   * @author Global Desktop
   * @description Method auxiliar para comprobar una condicion negativa
   */
  private static boolean trueCondition(String family) {
    Boolean isTrue = false;
    if(family != null && family != '' && family != 'Todos' && family != 'All') {
      isTrue = true;
    }
    return isTrue;
  }

  /**
   * @author Global Desktop
   * @description clase para construir lista wrapper
   */
  public class WrapperClass {
    /**
     * @author Global Desktop
     * @description Variables de la clase wrapper
     */
    /* Pitch Name */
    private String pitchName; //NOSONAR
    /* Pitch URL */
    private String pitchURL; //NOSONAR
    /* Client Name */
    private String clientName; //NOSONAR
    /* Client URL */
    private String clientURL; //NOSONAR
    /* Pitch Product */
    private String pitchProduct; //NOSONAR
    /* Pitch Country */
    private String pitchCountry; //NOSONAR
    /* Pitch Number */
    private Integer pitchNumber; //NOSONAR

    /**
     * @author Global Desktop
     * @description Construye lista wrapper
     */
    public wrapperClass(String pitchName, Id pitchURL, String clientName, Id clientURL, String pitchProduct, String pitchCountry, Integer pitchNumber) {
      this.pitchName = pitchName;
      this.pitchURL = '/lightning/r/pith_Pitch__c/' + pitchURL + '/view';
      this.clientName = clientName;
      this.clientURL = '/lightning/r/Account/' + clientURL + '/view';
      this.pitchProduct = pitchProduct;
      this.pitchCountry = pitchCountry;
      this.pitchNumber = pitchNumber;
    }
  }
}