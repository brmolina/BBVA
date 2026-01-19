/********************************************************************************************
Name:            PitchTriggerHandler
Description:     Handler del trigger PitchTrigger
Test Class:

Version        Date            Author            Summary of changes
---------------------------------------------------------------------------------------------
1              15/10/2019      Global Desktop    Class creation
*********************************************************************************************/
public without sharing class PitchTriggerCustomHandler {
  /*
  * @author Global Desktop
  * @Description Cambia el recordType del de cración al de visualización
  */
  public void changeRecordType(List<pith__Pitch__c> triggerNew) {
    final Id idPitchView = Schema.SObjectType.pith__Pitch__c.getRecordTypeInfosByName().get(System.Label.PitchRecordLayout).getRecordTypeId();
    for(pith__Pitch__c pitch : triggerNew) {
      pitch.RecordTypeId = idPitchView;
      if(pitch.gf_filter_type_participant_id__c != null && pitch.pith__participant_id__c == null) {
        pitch.pith__participant_id__c = pitch.gf_filter_type_participant_id__c;
      }
    }
  }

  /**
  * @author Global Desktop
  * @Description onAfterInsert
  */
  public static void onAfterInsert(List<pith__Pitch__c> newList) {
    Pitch_Helper_Comm_Alert.changeCommAlertStatusInsert(newList);
    Pitch_Helper.denormalizePitch(newList);
  }


  /**
  * @author Global Desktop
  * @Description onAfterUpdate
  */
  public static void onAfterUpdate(Map<Id, pith__Pitch__c> newMap, Map<Id, pith__Pitch__c> oldMap) {
    Pitch_Helper_Comm_Alert.changeCommAlertStatusUpdate(newMap, oldMap);
  }
}