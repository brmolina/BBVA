/**
* @File Name          : Arc_Gen_SearchCustomerForNewArc_Crtl.cls
* @Description        : Controller class for Serach Customer component
* @Author             : luisarturo.parra.contractor@bbva.com
* @Group              : ARCE
* @Last Modified By   : luisruben.quinto.munoz@bbva.com
* @Last Modified On   : 23/7/2019 19:39:53
* @Modification Log   :
*==============================================================================
* Ver         Date                     Author                 Modification
*==============================================================================
* 1.0    19/06/2019 14:50:32   luisarturo.parra.contractor@bbva.com     Initial Version
* 1.1    19/06/2019 14:50:32   luisruben.quinto.munoz@bbva.com     Documentation
* 1.2    29/11/2919 10:50:10   manuelhugo.castillo.contractor@bbva.com  Method modified 'getaccountsForLookupctrl'
*                                                                       replace Account dependencies to AccountWrapper
* 1.2   23/09/2020     saimassimilianno.jordana.contractor@bbva.com Added arce. namespace to all classes that are now in the arce-dependencies package
**/
public with sharing class Arc_Gen_SearchCustomerForNewArc_Crtl {
    /**
    *-------------------------------------------------------------------------------
    * @description  private method for sonar
    --------------------------------------------------------------------------------
    * @author luisarturo.parra.contractor@bbva.com
    * @date 19/06/2019 14:50:32
    * @param
    * @return
    * @example private Arc_Gen_SearchCustomerForNewArc_Crtl()
  **/
    @TestVisible
    private Arc_Gen_SearchCustomerForNewArc_Crtl() {
    }
    /**
    *-------------------------------------------------------------------------------
    * @description  get account searched by search bar
    --------------------------------------------------------------------------------
    * @author luisarturo.parra.contractor@bbva.com
    * @date 19/06/2019 14:50:32
    * @param searchWord imput from the component
    * @return List <arce.Arc_Gen_Account_Wrapper>(Id,Name) return list of Accounts
    * @example public List<arce.Arc_Gen_Account_Wrapper> accountsForLookup(String searchWord)
    **/
    @AuraEnabled
    public static List <arce.Arc_Gen_Account_Wrapper> getaccountsForLookupctrl(String searchWord) {
      return Arc_Gen_SearchCustomerForNewAr_Service.getaccountsForLookupservice(searchWord);
    }
}