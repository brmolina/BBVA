/**
 * @description       :
 * @author            : Global Desktop
 * @group             :
 * @last modified on  : 12-05-2022
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
public with sharing class GlobalBankerClientsController {

    @AuraEnabled
    public static String fetchAccts(Id recordId) {
        System.debug('>>>>>>> fetchAccts:' + recordId);
        List<DES_BBVA_Management_team__c> lTeamMember = [Select DES_User__c from DES_BBVA_Management_team__c where Id = :recordId LIMIT 10];
        List<DES_BBVA_Management_team__c> lAccounts = [Select DES_Client__c, DES_Client__r.Name, DES_Client__r.DES_Client_Type__c, DES_Client__r.DES_ID_Fiscal__c, DES_Client__r.DES_Country__c,
                                                        DES_Client__r.DES_Client_Matrix__c, DES_Client__r.DES_Client_Matrix__r.Name, DES_Client__r.DES_Client_Matrix__r.DES_ID_Fiscal__c
                                                        from DES_BBVA_Management_team__c where
                                                        DES_Client__r.DES_Group_Code__c != null
                                                        and DES_User__c = :lTeamMember[0].DES_User__c] ;
        List<wrapperClass> listWrapperClass = new List<wrapperClass>();
        for(DES_BBVA_Management_team__c btm : lAccounts) {
            listWrapperClass.add(new wrapperClass(btm.DES_Client__c, btm.DES_Client__r.DES_Client_Matrix__c, btm.DES_Client__r.Name , btm.DES_Client__r.DES_ID_Fiscal__c , btm.DES_Client__r.DES_Country__c  , btm.DES_Client__r.DES_Client_Type__c, btm.DES_Client__r.DES_Client_Matrix__r.Name, btm.DES_Client__r.DES_Client_Matrix__r.DES_ID_Fiscal__c ));
        }
        return JSON.serialize(listWrapperClass);
    }

    /**
    * @author Global Desktop
    * @description clase para construir lista wrapper
    */
    public class wrapperClass {

		/**
      	* @author Global Desktop
      	* @description Variables de la clase wrapper
      	*/
      	/*Nombre de account*/
      	private String accName; //NOSONAR
      	/*Url de la account*/
      	private String accUrl; //NOSONAR
        /*Url de la account*/
        	/*Nombre de account*/
      	private String accNameParent; //NOSONAR
      	/*Url de la account*/
      	private String accUrlParent; //NOSONAR
        /*Url de la account*/
      	private String idFiscal; //NOSONAR
        /*Url de la account*/
         /*Url de la account*/
      	private String idFiscalParent; //NOSONAR
        /*Url de la account*/
      	private String country; //NOSONAR
          /*Url de la account*/
      	private String clientType; //NOSONAR
      	/**
      	* @author Global Desktop
      	* @description Construye lista wrapper
      	*/
      	public wrapperClass(Id accId, Id accParId, String accNameO, String idFiscalO, String countryO, String clientTypeO, String accNameParO, String idFiscalParO) {
          this.accUrl = '/lightning/r/Account/' + accId + '/view';
          this.accUrlParent = '/lightning/r/Account/' + accParId + '/view';
      		this.accName = accNameO;
          this.idFiscal = idFiscalO;
          this.accNameParent = accNameParO;
          this.idFiscalParent = idFiscalParO;
          this.country = countryO;
          this.clientType = clientTypeO;
      	}
    }
}