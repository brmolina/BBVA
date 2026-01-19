/**
  * @File Name          : Arc_Gen_SearchCustomerForNewAr_Helper.cls
  * @Description        : Helper class for component Search Sustomer
  * @Author             : luisarturo.parra.contractor@bbva.com
  * @Group              : ARCE
  * @Last Modified By   : luisruben.quinto.munoz@bbva.com
  * @Last Modified On   : 23/7/2019 19:46:13
  * @Modification Log   :
  *==============================================================================
  * Ver         Date                     Author                 Modification
  *==============================================================================
  * 1.0    19/06/2019 14:50:32   luisarturo.parra.contractor@bbva.com     Initial Version
  * 1.1    23/7/2019 19:42:53    luisruben.quinto.munoz@bbva.com     added coments
  * 1.2    29/11/2919 10:50:10   manuelhugo.castillo.contractor@bbva.com  Method modified 'getaccountsForLookupservicehlp'
  *                                                                       replace Account dependencies to AccountWrapper
  * 1.2    23/09/2020     saimassimilianno.jordana.contractor@bbva.com    Added arce. namespace to all classes that are now in the arce-dependencies package
  **/
public with sharing class Arc_Gen_SearchCustomerForNewAr_Helper {
  /**
  *-------------------------------------------------------------------------------
  * @description  private method for sonar
  --------------------------------------------------------------------------------
  * @author luisarturo.parra.contractor@bbva.com
  * @date 19/06/2019 14:50:32
  * @param
  * @return
  * @example private Arc_Gen_SearchCustomerForNewAr_Helper()
  **/
  @TestVisible
  private Arc_Gen_SearchCustomerForNewAr_Helper() {
  }
  /**
  *-------------------------------------------------------------------------------
  * @description  get accounts filtered by searchWord
  --------------------------------------------------------------------------------
  * @author luisarturo.parra.contractor@bbva.com
  * @date 19/06/2019 14:50:32
  * @param searchWord imput from the component to serach Accounts
  * @return  return accountsForLookup(searchWord);-List <arce.Arc_Gen_Account_Wrapper>
  * @example public static List <arce.Arc_Gen_Account_Wrapper> getaccountsForLookupservicehlp(String searchWord)
  **/
  public static List < arce.Arc_Gen_Account_Wrapper > getaccountsForLookupservicehlp(String searchWord) {
    Id currentUser = UserInfo.getUserId();
    List<arce.Arc_Gen_Account_Wrapper> accountstoshow = new List<arce.Arc_Gen_Account_Wrapper>();
    List<arce.Arc_Gen_Account_Wrapper> accsWrapper = arce.Arc_Gen_Account_Locator.accountsForLookup(searchWord);
        for(arce.Arc_Gen_Account_Wrapper accountsingle : accsWrapper) {
            if(accountsingle.participantOwnerId == currentUser) {
                accountstoshow.add(accountsingle);
            }
        }
    return accountstoshow;
  }
}