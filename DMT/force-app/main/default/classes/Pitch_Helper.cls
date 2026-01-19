/**********************************************************************************
* @author       Global Desktop
* @date         28/04/2020
* @description  Helper del handler PitchTriggerCustomHandler
**********************************************************************************/
public with sharing class Pitch_Helper {
  /**
  * @author Global Desktop
  * @Description Empty constructor
  */
  private Pitch_Helper() {
    System.debug('Empty constructor');
  }

  /**
  * @author Global Desktop
  * @Description denormalizePitch
  */
  public static void denormalizePitch(final List<pith__Pitch__c> newList) {
    // setAccAlert.clear();
    final List<Denorm_Account_Pitch__c> listDenormPitch = new List<Denorm_Account_Pitch__c>();

    for(pith__Pitch__c iPitch : newList) {
      recursiveFxn(iPitch.pith__participant_id__c, iPitch.Id, listDenormPitch); //Create all relationships
    }

    //finally insert relationships in database
    if(!listDenormPitch.isEmpty()) {
      insert listDenormPitch;
    }
  }

  /**
  * @author Global Desktop
  * @Description recursiveFxn
  */
  public static List<Denorm_Account_Pitch__c> recursiveFxn(Id iAccountId, string iPitchId, List<Denorm_Account_Pitch__c> listDenormPitch) {
    if(iAccountId != null) {
      System.debug('::::::::::Adding Relationship >> A: ' + iAccountId + '/O: ' + iPitchId);
      final Denorm_Account_Pitch__c iDenormPitch = new Denorm_Account_Pitch__c(
        participant_id__c = iAccountId,
        gf_pitch_id__c = iPitchId);
      listDenormPitch.add(iDenormPitch);
    }

    final List<dwp_acmh__GBL_Account_Relationship__c> listAccRel = [SELECT Id,
                                                                      dwp_acmh__Parent_Account__c,
                                                                      dwp_acmh__Vision__c
                                                                    FROM dwp_acmh__GBL_Account_Relationship__c
                                                                    WHERE dwp_acmh__Child_Account__c = :iAccountId];

    for (dwp_acmh__GBL_Account_Relationship__c iAccRel : listAccRel) {
      if(listAccRel.size() == 1 || iAccRel.dwp_acmh__Vision__c == 'Negocio') {
        recursiveFxn(iAccRel.dwp_acmh__Parent_Account__c, iPitchId, listDenormPitch);
      }
    }

    return listDenormPitch;
  }
}