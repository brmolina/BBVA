/**
* ------------------------------------------------------------------------------------------------
* @Name     Arc_GBL_User_Locator
* @Author   juanignacio.hita.contractor@bbva.com
* @Date     Created: 14/11/2019
* @Group    ARCE
* -----------------------------------------------------------------------------------------------
* @Description GBL class that implements arce.Arc_Gen_User_Interface
* -----------------------------------------------------------------------------------------------
* @Changes
*
* |2019-11-14 juanignacio.hita.contractor@bbva.com
*             Class creation.
* |2020-03-30 mariohumberto.ramirez.contractor@bbva.com
*             Update method getUserInfo
* |2020-09-23 saimassimilianno.jordana.contractor@bbva.com
*             Added arce. namespace to all classes that are now in the arce-dependencies package
* |2021-02-23 juanignacio.hita.contractor@bbva.com
*             Add initialization territory param in getUserInfo method
* |2021-04-23 jose.hijar.contractor@bbva.com
*             Add method for querying user filtered by an ambit Id
* -----------------------------------------------------------------------------------------------
*/
global class Arc_GBL_User_Locator implements arce.Arc_Gen_User_Interface {//NOSONAR
    /**
    *-------------------------------------------------------------------------------
    * @description  Method that retrieves full user information
    --------------------------------------------------------------------------------
    * @author javier.soto.carrascosa@bbva.com
    * @date 2019-07-15
    * @param Id userId
    * @return wrapper user data
    * @example public static WrapperUser getUserInfo(Id userId) {
    **/
    public static arce.Arc_Gen_User_Wrapper getUserInfo(Id userId) {
        final arce.Arc_Gen_User_Wrapper wu = new arce.Arc_Gen_User_Wrapper();
        User userInfo = getBasicInfoUser(userId);
        wu.userBasicInfo = userInfo;
        wu.branchId = '0000';
        wu.branchText = 'Placeholder Office';
        wu.ambitUser = '1';
        wu.branchlevel = '10';
        wu.businessAgentId = userInfo.FederationIdentifier;
        wu.profileName = userInfo.Profile.Name;
        wu.cr = '0001';
        wu.territory = 'Office 1';
        wu.officeName = wu.branchText + '/' + wu.cr;
        return wu;
    }
    /**
    * ---------------------------------------------------------------------------------------------------
    * @Description - Method to find users
    * ---------------------------------------------------------------------------------------------------
    * @Author   Angel Fuertes Gomez - angel.fuertes2@bbva.com / BBVA DWP
    * @Date     Created: 2019-05-04
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
            wrap.branchId = '0000';
            wrap.branchText = 'Placeholder Office';
            wrap.branchlevel = '10';
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
    * @Author   Angel Fuertes Gomez - angel.fuertes2@bbva.com / BBVA DWP
    * @Date     Created: 2019-05-04
    * @param userId - User Id
    * @return a list users
    * @example getBasicInfoUser(userId)
    * ---------------------------------------------------------------------------------------------------
    **/
    private static User getBasicInfoUser(Id userId) {
        User userDetails = [SELECT Id, Name, Profile.Name, FederationIdentifier FROM User WHERE Id =:userId];
        Return userDetails;
    }

      /**
  *-------------------------------------------------------------------------------
  * @description getUserByAmbit : Returns a list of user filtered by ambitString parameter (To be implemented by geographies)
  *--------------------------------------------------------------------------------
  * @date   27/04/2021
  * @author ARCE Corporate
  * @param    String : ambitString
  * @return   List<User>
  * @example  Arc_Gen_Workflow_Helper.fetchUsersByAmbit(String ambitString);
  */

    public static List<User> getUserByAmbit(String ambitString) {
      return [
        SELECT Id, Name
        FROM User
        WHERE gf_user_operation_ambit_name__c = :ambitString
        and IsActive = true
        ORDER BY Name ASC
      ];
    }


}