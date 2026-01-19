/*Class modified - 19/12/2018 */
public without sharing class SER_ProfileUtils {

  /* Profile ID */
  public static Set<Id> setProfileId {get; set;}
  /* Profile ID map */
  public static Map<Id,String> mapProfileId {get; set;}
  /* Profile Name map */
  public static Map<String,Id> mapProfileName {get; set;}

  private SER_ProfileUtils () {
    /*Constructor sin nada*/
  }

  static {
    if(setProfileId == null) {
      setProfileId = new Set<Id>();
    }
    if(mapProfileId == null) {
      mapProfileId    = new Map<Id,String>();
    }
    if(mapProfileName == null) {
      mapProfileName  = new Map<String,Id>();
    }
    if(setProfileId.isEmpty()) {
      loadProfileMaps();
    }
  }

  /*-------------------------------
      Author:        Juan Carlos Terrón
      Company:       Accenture


      History:
          <Author>                <Change Description>
      Juan Carlos Terrón		Initial version
  -----------------*/
  public static void loadProfileMaps() {
    for(Profile pF : [SELECT Id,Name FROM Profile limit 100]) {
      mapProfileId.put(pF.Id, pF.Name);
      mapProfileName.put(pF.Name, pF.Id);
      setProfileId.add(pF.Id);
    }
  }
  /*-------------------------------
      Author:        Juan Carlos Terrón
      Company:       Accenture


      History:
          <Author>                <Change Description>
      Juan Carlos Terrón		Initial version
  -----------------*/
  public static String getProfileId(String profileName) {
    String returnId = null;
    if(mapProfileName.containsKey(profileName)) {
      returnId = mapProfileName.get(profileName);
    }
    return returnId;
  }
  /*-------------------------------
      Author:        Juan Carlos Terrón
      Company:       Accenture


      History:
          <Author>                <Change Description>
      Juan Carlos Terrón		Initial version
  -----------------*/
  public static String getProfileName(String profileId) {
    String returnName = null;
    if(mapProfileId.containsKey(profileId)) {
      returnName = mapProfileId.get(profileId);
    }
    return returnName;
  }
}