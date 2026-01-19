/*--------------------------------------------------------------------------------
  @author       Accenture
  @date         17/01/2018
  @description  TEST for Profile utils.
------------------------------------------------------------------------------------*/
@isTest //NOSONAR
private class SER_ProfileUtils_TEST {
  /*--------------------------------------------------------------------------------
    @author       Accenture
    @date         17/01/2018
    @description  TEST for profile utils
  ------------------------------------------------------------------------------------*/
  @isTest static void testmethodone() {

    final List<Profile> lstProfiles = [SELECT Id,Name FROM Profile limit 10000];

    for(Profile prof : lstProfiles) {
      SER_ProfileUtils.setProfileId.add(prof.Id);
      SER_ProfileUtils.mapProfileId.put(prof.Id, prof.Name);
      SER_ProfileUtils.mapProfileName.put(prof.Name, prof.Id);
    }


    Test.startTest();
    final String profId1 = SER_ProfileUtils.getProfileId(null);
    final string profName1 = SER_ProfileUtils.getProfileName(null);

    final string profId2 = SER_ProfileUtils.getProfileId(lstProfiles[0].Name);
    final string profName2 = SER_ProfileUtils.getProfileName(lstProfiles[0].Id);
    Test.stopTest();
    System.assert (profId1==null && profName1 == null && profId2!=null && profName2 !=null,'testmethodone' );
  }
}