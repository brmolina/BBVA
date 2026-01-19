/**********************************************************************************
* @author       Global Desktop
* @date         18/02/2020
* @description  Helper del trigger de pith__Related_opportunity_pitch__c
**********************************************************************************/
public with sharing class Related_Opp_Pitch_Helper {
  /**
  * @author Global Desktop
  * @Description Empty constructor
  */
  private Related_Opp_Pitch_Helper() {
    System.debug('Empty constructor');
  }

  /**
  * @author Global Desktop
  * @Description checkAlertTraceabilityPitchOpp
  */
  public static void checkAlertTraceabilityPitchOpp(final List<pith__Related_opportunity_pitch__c> newList) {
    final Set<Id> setPitch = new Set<Id>();
    final Set<Id> setOpp = new Set<Id>();
    for(pith__Related_opportunity_pitch__c iRelOppPitch : newList) {
      setPitch.add(iRelOppPitch.pith__pitch_opportunity_id__c);
      setOpp.add(iRelOppPitch.pith__opportunity_pitch_id__c);
    }

    final Map<Id, pith__Pitch__c> mapIdPitch = new Map<Id, pith__Pitch__c>([SELECT Id, commercial_alert_id__c FROM pith__Pitch__c WHERE Id IN :setPitch]);
    final Map<Id, Opportunity> mapIdOpp = new Map<Id, Opportunity>([SELECT Id, commercial_alert_id__c FROM Opportunity WHERE Id IN :setOpp]);

    final List<pith__Pitch__c> listPitch = new List<pith__Pitch__c>();
    final List<Opportunity> listOpp = new List<Opportunity>();
    for(pith__Related_opportunity_pitch__c iRelOppPitch : newList) {
      if(mapIdOpp.get(iRelOppPitch.pith__opportunity_pitch_id__c).commercial_alert_id__c != null
        && mapIdPitch.get(iRelOppPitch.pith__pitch_opportunity_id__c).commercial_alert_id__c == null) {
        mapIdPitch.get(iRelOppPitch.pith__pitch_opportunity_id__c).commercial_alert_id__c = mapIdOpp.get(iRelOppPitch.pith__opportunity_pitch_id__c).commercial_alert_id__c;
        listPitch.add(mapIdPitch.get(iRelOppPitch.pith__pitch_opportunity_id__c));
      } else if(mapIdOpp.get(iRelOppPitch.pith__opportunity_pitch_id__c).commercial_alert_id__c == null
        && mapIdPitch.get(iRelOppPitch.pith__pitch_opportunity_id__c).commercial_alert_id__c != null) {
        mapIdOpp.get(iRelOppPitch.pith__opportunity_pitch_id__c).commercial_alert_id__c = mapIdPitch.get(iRelOppPitch.pith__pitch_opportunity_id__c).commercial_alert_id__c;
        listOpp.add(mapIdOpp.get(iRelOppPitch.pith__opportunity_pitch_id__c));
      }
    }

    if(!listPitch.isEmpty()) {
      update listPitch;
    }
    if(!listOpp.isEmpty()) {
      update listOpp;
    }
  }
}