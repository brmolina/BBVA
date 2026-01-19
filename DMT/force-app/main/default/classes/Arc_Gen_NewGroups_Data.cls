/**
  * @File Name          : Arc_Gen_NewGroups_Data.cls
  * @Description        : Data Class for newAnalysis rebuilt
  * @Author             : luisarturo.parra.contractor@bbva.com
  * @Group              : ARCE
  * @Last Modified By   : luisarturo.parra.contractor@bbva.com
  * @Last Modified On   : 12/09/2019
  * @Modification Log   :
  *=======================================================================================================================
  * Ver                  Date                         Author                       Modification
  * 1.0              12/09/2019    luisarturo.parra.contractor@bbva.com         Initial version
  * 1.1              05/12/2019    manuelhugo.castillo.contractor@bbva.com      Modify method 'searchgroupinsf','searchcustomersafterupdate','searchlistpartinsf' replace Account to AccountWrapper
  * 1.2              06/01/2020    mariohumberto.ramirez.contractor@bbva.com    Added validation to update group structure in the back end
  * 1.3              15/01/2020    javier.soto.carrascosa@bbva.com    Remove methods included in Account Interface
  * 1.4              15/09/2020    javier.soto.carrascosa@bbva.com    Remove unused method
  * 1.5              23/09/2020    saimassimilianno.jordana.contractor@bbva.com Added arce. namespace to all classes
                                                                        that are now in the arce-dependencies package
  *=======================================================================================================================
  *
  **/
public without sharing virtual class Arc_Gen_NewGroups_Data {
  /**
  *-------------------------------------------------------------------------------
  * @description method that search group
  *-------------------------------------------------------------------------------
  * @date 12/09/2019
  * @author luisarturo.parra.contractor@bbva.com
  * @param String groupnumber
  * @return List < arce.Arc_Gen_Account_Wrapper >
  * @example public virtual List < arce.Arc_Gen_Account_Wrapper > searchgroupinsf(String groupnumber)
  */
  public virtual List < arce.Arc_Gen_Account_Wrapper > searchgroupinsf(String groupnumber) {
    List<String> lstAccNumber = new List<String>{groupnumber};
    final Map<String,arce.Arc_Gen_Account_Wrapper> mapAccWrap = arce.Arc_Gen_Account_Locator.getAccountByAccNumber(lstAccNumber);
    return mapAccWrap.values();
  }
  /**
  *-------------------------------------------------------------------------------
  * @description method 'searchlistpartinsf' that search list participants
  *-------------------------------------------------------------------------------
  * @date 12/09/2019
  * @author luisarturo.parra.contractor@bbva.com
  * @param List < String > listparticipants
  * @return List < arce.Arc_Gen_Account_Wrapper >
  * @example public virtual List < arce.Arc_Gen_Account_Wrapper > searchlistpartinsf(List < String > listparticipants)
  */
  public virtual List < arce.Arc_Gen_Account_Wrapper > searchlistpartinsf(List < String > listparticipants) {
    final Map<String,arce.Arc_Gen_Account_Wrapper> mapAccWrap = arce.Arc_Gen_Account_Locator.getAccountByAccNumber(listparticipants);
    final List<arce.Arc_Gen_Account_Wrapper> lstAccWrapper = new List<arce.Arc_Gen_Account_Wrapper>();
    for(arce.Arc_Gen_Account_Wrapper accountWrapper : mapAccWrap.values()) {
      lstAccWrapper.add(accountWrapper);
    }
    return lstAccWrapper;
  }
}