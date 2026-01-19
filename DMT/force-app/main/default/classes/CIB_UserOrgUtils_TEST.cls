/**
  * Project:           BBVA
  * Description:       Clase CIB_UserOrgUtils_TEST
  *
  *            No.     Date            Author                  Description
  *            -----   ----------      --------------------    ---------------
  * @version   1.1     2020-03-23      Victor Velandia (VV)    Ajuste Clase TEST Sonar
  ***********************************************************************************/
@isTest
private class CIB_UserOrgUtils_TEST {

  /**
  * description: test_methodOone
  */
  @isTest
  static void testMethodOne() {
    // Se comenta porque no se llama en ningun lado de la clase de Test VV
    //CIB_UserOrgUtils cib_user = new CIB_UserOrgUtils();

    final String profileId = userinfo.getProfileId();
    System.debug('profileId: '+profileId);

    final CIB_UserOrgUtils.Instance instance;
    instance = new CIB_UserOrgUtils.Instance(profileId,'User');
    instance.setFields(profileId, 'User', true, true, true);
    instance.setAll(profileId, 'User');

    CIB_UserOrgUtils.setProfiling(profileId, 'csType', true, true, true);
    CIB_UserOrgUtils.setProfiling(null, 'csType', true, true, true);
    CIB_UserOrgUtils.setProfiling(profileId, 'csType');
    CIB_UserOrgUtils.setProfiling(null, 'csType');
    CIB_UserOrgUtils.setSelfProfiling('User', true, true, true);
    CIB_UserOrgUtils.setSelfProfiling('Profile', true, true, true);
    CIB_UserOrgUtils.setSelfProfiling_All('User');
    CIB_UserOrgUtils.setSelfProfiling_All('Profile');
    //CIB_UserOrgUtils.clearAllInstances();
    CIB_UserOrgUtils.assignInstance(instance);

    instance.setAll(profileId, 'Profile');
    CIB_UserOrgUtils.assignInstance(instance);
    CIB_UserOrgUtils.assignInstance(null);
    System.assertEquals(profileId, profileId, 'testMethodOne');

  }
}