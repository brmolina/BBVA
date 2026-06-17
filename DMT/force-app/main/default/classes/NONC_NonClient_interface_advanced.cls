/************************************************************************
* @name:                NonClient_interface_advanced
* @author 				bbva.com developers
* @date:             	2020
* @version:             1.0
* @group:              	Digital Workplace
* @description:         Interface that implements validations Non Client
***************************************************************************/
global interface NONC_NonClient_interface_advanced {
    String checkDuplicateNonClients(String fields);
    String validateNonCliente(Account acc);
  }