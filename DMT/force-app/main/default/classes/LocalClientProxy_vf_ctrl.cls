/**
* -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
* @Name OOO_AccountProxy_vf_control
* @Author Oscar Garcia
* @Date Created: 2021-01-25 joseoscar.garcia.contractor@bbva.com
* @Group Service
* @Description Visual force Controller. That class is in charge of translating the received by POST customerId into an internal SFDC ID
* @Changes
*
* |2021-01-25 joseoscar.garcia.contractor@bbva.com
* First version
*/
@SuppressWarnings('PMD.ApexXSSFromURLParam, sf:AvoidGetSetMethods')
public with sharing class LocalClientProxy_vf_ctrl {
  private String clientId; //NOSONAR
	private String customerId; //NOSONAR

  /**
	* -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
	* @Author JOscar Garcia
	* @Date 2019-06-12
	* @Description Class constructor
	**/
	@SuppressWarnings('PMD.ApexXSSFromURLParam')
	// SuppressWarnings because in requirement to get a POST param
	public LocalClientProxy_vf_ctrl() {
	  final String param = ApexPages.currentPage().getParameters().get('customerId');
	  this.customerId = param.escapeHtml3();
	  system.debug('param='+param);
	}

  /**
	* -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
	* @Author Oscar Garcia
	* @Date 2019-06-12
	* @Description Setter fot the customerId property
	* @return String
	**/
	public void setCustomerId(String customerId) {
	  this.customerId = customerId;
	}

  /**
	* -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
	* @Author Oscar Garcia
	* @Date 2019-06-12
	* @Description Getter fot the clientId property
	* @return String
	**/
	public String getClientId() {
    try {
      String toReturn = 'customerId-not-found';
      if(!(customerId == null || customerId == '')) {
        List<Local_Client__c> customerIdList = [select id from Local_Client__c where Alpha_code__c = :customerId];
        if(customerIdList.size() == 1) {
          toReturn = customerIdList.get(0).Id;
        }
      }
      return toReturn;
    } catch(Exception e) {
        return 'customerId-not-found';
    }
  }

  /**
  * -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
  * @Author Oscar Garcia
  * @Date 2019-06-12
  * @Description Getter fot the customerId property
  * @return String
  **/
  public String getCustomerId() {
    return customerId;
  }
}