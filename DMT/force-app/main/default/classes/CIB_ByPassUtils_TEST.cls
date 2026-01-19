/*----------------------------------------------------------------------------------
    Author:        BBVA
    Description:   Method to test CIB_ByPassUtils.
------------------------------------------------------------------------------------*/
@isTest
private class CIB_ByPassUtils_TEST {
  @isTest static void testMethodOne() {
    Test.startTest();
      CIB_ByPassUtils.enableByPassSelfUser(true, true, true, true, true, true);
      CIB_ByPassUtils.enableByPassAllSelfUser();
      CIB_ByPassUtils.enableByPassSelfProfile(true, true, true, true, true, true);
      CIB_ByPassUtils.enableByPassAllSelfProfile();
      CIB_ByPassUtils.clearAllInstances();

      CIB_ByPassUtils.Instance instance;
      instance = new CIB_ByPassUtils.Instance();
      new CIB_ByPassUtils.Instance(UserInfo.getUserId(), 'user', true);
      new CIB_ByPassUtils.Instance(UserInfo.getUserId(), 'user', true, new CIB_Bypass__c());

      instance.skipFields(true,true,true,true,true,true);
      System.assertNotEquals(null, instance, 'Error');
    Test.stopTest();
  }
}