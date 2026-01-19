/**
 * @author Global Desktop
 */

public with sharing class Create_opp_controller {

  /**
     * SINGLETON PATTERN
     */
    private static Create_opp_controller instance;
    /**
     * Constructor
     */
    private Create_opp_controller() {
    }

    /**
     * getInstance
     */
    public static Create_opp_controller getInstance() {//NOSONAR
      if (instance == null) {
        instance = new Create_opp_controller();
      }
      return instance;
    }


  /**
   * Method for Create_opportunity_cmp that returns the Draft Opp Record Type Id
   */
    @AuraEnabled
    public static String getRecordTypeId(String sObjecType, String rtName) {

        try {
            String rtId;
            rtId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get(Label.DES_RT_ACC_Draft_Opportunity).getRecordTypeId();
            if (sObjecType == Opportunity.getSObjectType().getDescribe().getName()) {
              rtId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get(rtName).getRecordTypeId();
            } else if (sObjecType == DES_Opportunity_Management_member__c.getSObjectType().getDescribe().getName()) {
              rtId = Schema.SObjectType.DES_Opportunity_Management_member__c.getRecordTypeInfosByName().get(rtName).getRecordTypeId();
            }
            return rtId;
        } catch(Exception e) {
          system.debug('Exception : ' + e);
          throw new AuraHandledException(Label.DES_IP_ERROR + e);
        }
    }

    /**
     * Devuelve un mapa con las preguntas del formulario de compliance
     */
    @AuraEnabled
    public static Map<String,String> complianceQuestions() {
      try {
          return Desktop_Utils.complianceQuestions();
      } catch(Exception e) {
        throw new AuraHandledException(Label.DES_IP_ERROR + e);
      }
    }
}