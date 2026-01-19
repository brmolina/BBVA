/*
* @author Global Desktop
* @description Popup para adjuntar documentos en el pitch
*/
public with sharing class NewPitchPopupCnt {
    
    /*SINGLETON PATTERN*/
    public static NewPitchPopupCnt instance;
    
	/*Private constructor*/
	public NewPitchPopupCnt() {
	}
    
    /*SINGLETON PATTERN*/
    public static NewPitchPopupCnt getInstance() { //NOSONAR
        if (instance == null) {
            instance = new NewPitchPopupCnt();
        }
        return instance;
    }
    
	@AuraEnabled
    public static Boolean getCreated(String recordId){
        pith__Pitch__c isRecentlyCreated = new pith__Pitch__c();
        isRecentlyCreated = [SELECT pith__gf_recent_pitch_type__c from pith__Pitch__c where id=: recordId limit 1];
        return isRecentlyCreated.pith__gf_recent_pitch_type__c;
    }
}