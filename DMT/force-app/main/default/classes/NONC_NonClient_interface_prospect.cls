/************************************************************************
* @name:                NonClient_interface_prospect
* @author 				bbva.com developers
* @date:             	2019
* @version:             1.0
* @group:              	Global Desktop
* @description:         Interface that implements validations Non Client
***************************************************************************/
global interface NONC_NonClient_interface_prospect {
  String checkDuplicateNonClients(String strSearchName, String strFieldNameCode, String strFielValueCode);
  String validateNonCliente(Account acc);
  String checkConvertedClients(List<Account> lProspect, Map<String, Account> mapUniqueIDAccount);
}