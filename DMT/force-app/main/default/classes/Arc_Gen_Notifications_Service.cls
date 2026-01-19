/**
  * @File Name          : public with sharing class Arc_Gen_Notifications_Service.cls
  * @Description        : Service class of notifications function
  * @Author             : juanmanuel.perez.ortiz.contractor@bbva.com
  * @Group              : ARCE
  * @Last Modified By   : juanmanuel.perez.ortiz.contractor@bbva.com
  * @Last Modified On   : 3/1/2020 17:22:39
  * @Modification Log   :
  *==============================================================================
  * Ver         Date                     Author                 Modification
  *==============================================================================
  * 1.0   3/01/2020 17:22:39  juanmanuel.perez.ortiz.contractor@bbva.com   Initial Version
  * 1.1   23/09/2020     saimassimilianno.jordana.contractor@bbva.com      Added arce. namespace
  *                                 to all classes that are now in the arce-dependencies package
**/
public with sharing class Arc_Gen_Notifications_Service {
    /**
    *-------------------------------------------------------------------------------
    * @description Empty private constructor
    --------------------------------------------------------------------------------
    * @author juanmanuel.perez.ortiz.contractor@bbva.com
    * @date 2020-01-06
    * @example private Arc_Gen_Notifications_Service ()
    **/
        @TestVisible
        private Arc_Gen_Notifications_Service () {
        }
    /**
    *-------------------------------------------------------------------------------
    * @description Get owners of account has analysis added in carrousel
    --------------------------------------------------------------------------------
    * @author juanmanuel.perez.ortiz.contractor@bbva.com
    * @date 3/01/2020
    * @param String arceId
    * @return List < User >
    * @example public static void getUsersIds(String arceId)
    **/
    public static List<User> getUsersIds(Id arceId) {
        final List<arce.Arc_Gen_Account_Has_Analysis_Wrapper> ltsAccHas = arce.Arc_Gen_AccHasAnalysis_Data.getListAHAWrapper(arce.Arc_Gen_AccHasAnalysis_Data.getAccHasAnFromArce(arceId));
        List<User> ltsUsers = new list<User>();
        Set<Id> setIds = new Set<Id>();
          for (arce.Arc_Gen_Account_Has_Analysis_Wrapper accHas : ltsAccHas) {
            if (accHas.accWrapperObj != null) {
                  setIds.add(accHas.accWrapperObj.participantOwnerId);
            }
          }
          for (Id usId : setIds) {
              user newUser = new user();
              newUser.id = usId;
              ltsUsers.add(newUser);
          }
        return ltsUsers;
    }

}