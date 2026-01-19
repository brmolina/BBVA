/**
* @File Name          : Arc_Gen_SearchCustomerForNewAr_Service.cls
* @Description        : Service class for component Serach Customer
* @Author             : luisarturo.parra.contractor@bbva.com
* @Group              : ARCE
* @Last Modified By   : luisruben.quinto.munoz@bbva.com
* @Last Modified On   : 23/7/2019 19:41:56
* @Modification Log   :
*==============================================================================
* Ver         Date                     Author                 Modification
*==============================================================================
* 1.0    19/06/2019 14:50:32   luisarturo.parra.contractor@bbva.com     Initial Version
* 1.1    23/076/2019 14:50:32    luisruben.quinto.munoz@bbva.com        added coments
* 1.2    29/11/2919 10:50:10   manuelhugo.castillo.contractor@bbva.com  Method modified 'getaccountsForLookupservicehlp'
*                                                                       replace Account dependencies to AccountWrapper
* 1.2    23/09/2020     saimassimilianno.jordana.contractor@bbva.com    Added arce. namespace to all classes that are now in the arce-dependencies package
**/
public with sharing class Arc_Gen_SearchCustomerForNewAr_Service {
/**
*-------------------------------------------------------------------------------
  * @description  private method for sonar
  --------------------------------------------------------------------------------
  * @author luisarturo.parra.contractor@bbva.com
  * @date 19/06/2019 14:50:32
  * @param
  * @return
  * @example private Arc_Gen_SearchCustomerForNewAr_Service()
  **/
  @TestVisible
  private Arc_Gen_SearchCustomerForNewAr_Service() {
  }
  /**
  *-------------------------------------------------------------------------------
  * @description  get account searched by search bar
  --------------------------------------------------------------------------------
  * @author luisarturo.parra.contractor@bbva.com
  * @date 19/06/2019 14:50:32
  * @param searchWord imput from the component for search customer
  * @return  return accountsForLookup(searchWord);-List <arce.Arc_Gen_Account_Wrapper>
  * @example public static List <arce.Arc_Gen_Account_Wrapper> getaccountsForLookupservice(String searchWord)
  **/
  public static List <arce.Arc_Gen_Account_Wrapper> getaccountsForLookupservice(String searchWord) {
  return Arc_Gen_SearchCustomerForNewAr_Helper.getaccountsForLookupservicehlp(searchWord);
  }
}