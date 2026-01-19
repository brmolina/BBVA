/**********************************************************************************
* @author       Global Desktop
* @date         13/04/2019
* @description  Totals alerts
*/

public with sharing class AlertsPotentialActivityController {

	/**
    * SINGLETON PATTERN
    */
    private static AlertsPotentialActivityController instance;
	/*
	* String reason
	*/
	private final static String REASON = 'The alert was matured, its end date was';
	/*
	* String stageDis
	*/
	private final static String STAGEDIS = 'Discarded';
	/*
	* String stageWon
	*/
	private final static String STAGEWON = Label.DES_Won;

	/**
	* @author Global Desktop
	* @description Constructor de la clase
	*/
	private AlertsPotentialActivityController() {

	}


	/**
    * Constructor
    */
    public static AlertsPotentialActivityController gtInstance() {
        if (instance == null) {
			instance = new AlertsPotentialActivityController();
		}
        return instance;
    }

	/**
	* @author Global Desktop
	* @description Recupera las visitas relacionadas con la cuenta
	*/
  	@auraEnabled
  	public static String getAlertInfo(String accId) {
		try {
			List<wrapperClass> listWrapperClass;
			listWrapperClass = new List<wrapperClass>();

			List<DES_Denorm_AccountAlert__c> denRelAlert;
			denRelAlert = new List<DES_Denorm_AccountAlert__c>();
			denRelAlert = [SELECT id, commercial_alert_id__c, commercial_alert_id__r.altm__BBVA_rejection_reason_desc__c,
									commercial_alert_id__r.altm__alert_stage_type__c
									FROM DES_Denorm_AccountAlert__c WHERE participant_id__c = :accId LIMIT 50000];

			Integer totalAlert = 0;
			Integer totalAlertWon = 0;
			Integer totalAlertDiscard = 0;
			Integer totalAlertExpired = 0;
			for(DES_Denorm_AccountAlert__c alert : denRelAlert) {
				totalAlert++;
				if(alert.commercial_alert_id__r.altm__alert_stage_type__c == STAGEWON) {
					totalAlertWon++;
				} else if (alert.commercial_alert_id__r.altm__alert_stage_type__c == STAGEDIS && alert.commercial_alert_id__r.altm__BBVA_rejection_reason_desc__c != null && alert.commercial_alert_id__r.altm__BBVA_rejection_reason_desc__c.contains(REASON)) {
					totalAlertExpired++;
				} else if (alert.commercial_alert_id__r.altm__alert_stage_type__c == STAGEDIS) {
					totalAlertDiscard++;
				}
			}

			listWrapperClass.add(new wrapperClass(totalAlert,totalAlertWon,totalAlertDiscard,totalAlertExpired));

			return JSON.serialize(listWrapperClass);

		} catch(Exception exc) {
			throw new AuraHandledException(Label.DES_Error + exc);
		}
	  }

	/**
	* @author Global Desktop
	* @description Clase que construye la clase wrapper
	*/
	public class wrapperClass {
		/*
		* Variable for wrapperClass
		*/
		private final Integer totalAlert;
		/*
		* Variable for wrapperClass
		*/
		private final Integer totalAlertWon;
		/*
		* Variable for wrapperClass
		*/
		private final Integer totalAlertDiscard;
		/*
		* Variable for wrapperClass
		*/
		private final Integer totalAlertExpired;
		/**
		* @author Global Desktop
		* @description Method que construye la clase wrapper
		*/
		public wrapperClass(Integer totalAlert, Integer totalAlertWon, Integer totalAlertDiscard, Integer totalAlertExpired) {
  			this.totalAlert = totalAlert;
  			this.totalAlertWon = totalAlertWon;
  			this.totalAlertDiscard = totalAlertDiscard;
  			this.totalAlertExpired = totalAlertExpired;
        }
	}
}