/**
* ------------------------------------------------------------------------------------------------
* @Name     DES_Arc_User_Locator
* -----------------------------------------------------------------------------------------------
* @Description Class "Arc_GBL_User_Locator"
* -----------------------------------------------------------------------------------------------
*/
@SuppressWarnings('sf:AvoidDuplicateLiterals')
global with sharing class DES_Arc_User_Locator implements arce.Arc_Gen_User_Interface {//NOSONAR

  /**
  *-------------------------------------------------------------------------------
  * @description  Method that retrieves full user information
  --------------------------------------------------------------------------------
  * @author Global Desktop
  * @date 2021-03-09
  * @param Id userId
  * @return wrapper user data
  * @example public static WrapperUser getUserInfo(Id userId) {
  **/
  public static arce.Arc_Gen_User_Wrapper getUserInfo(Id userId) {
    final arce.Arc_Gen_User_Wrapper wus = new arce.Arc_Gen_User_Wrapper();
    final User userInfo = getBasicInfoUser(userId);
    wus.userBasicInfo = userInfo;
    wus.branchId = '9999';
    wus.branchText = '9999';
    wus.ambitUser = userInfo.gf_user_operation_ambit_name__c;
    wus.branchlevel = '99';
    wus.businessAgentId = userInfo.FederationIdentifier;
    wus.profileName = userInfo.Profile.Name;
    wus.cr = '9999';
    wus.officeName = wus.branchText + '/' + wus.cr;
    return wus;
  }

  /**
  * ---------------------------------------------------------------------------------------------------
  * @Description - Method to find users
  * ---------------------------------------------------------------------------------------------------
  * @author Global Desktop
  * @date 2021-03-09
  * @param inputTerm - String to find users
  * @return a list users
  * @example getUsers(inputTerm)
  * ---------------------------------------------------------------------------------------------------
  **/
  public static List<arce.Arc_Gen_User_Wrapper> getUsers(String inputTerm) {
    final List<arce.Arc_Gen_User_Wrapper> listWrapper = new List<arce.Arc_Gen_User_Wrapper>();
    for (User user : [SELECT Id, Name, Profile.Name, FederationIdentifier FROM User WHERE Name like :'%'+inputTerm+'%' and isActive = true]) {
      final arce.Arc_Gen_User_Wrapper wrap = new arce.Arc_Gen_User_Wrapper();
      wrap.userBasicInfo = user;
      wrap.branchId = '9999';
      wrap.branchText = '9999';
      wrap.branchlevel = '99';
      wrap.businessAgentId = user.FederationIdentifier;
      wrap.profileName = user.Profile.Name;
      listWrapper.add(wrap);
    }
    return listWrapper;
  }
  /**
  * ---------------------------------------------------------------------------------------------------
  * @Description - Private method to find user from the userId
  * ---------------------------------------------------------------------------------------------------
  * @author Global Desktop
  * @date 2021-03-09
  * @param userId - User Id
  * @return a list users
  * @example getBasicInfoUser(userId)
  * ---------------------------------------------------------------------------------------------------
  **/
  private static User getBasicInfoUser(Id userId) {
    return [SELECT Id, Name, Profile.Name, FederationIdentifier, gf_user_operation_ambit_name__c FROM User WHERE Id =:userId];
  }
}