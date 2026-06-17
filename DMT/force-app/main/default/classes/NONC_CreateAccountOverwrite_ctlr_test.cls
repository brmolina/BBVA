/************************************************************************
* @name:          CreateAccountOverwrite_ctlr_test
* @author         bbva.com developers
* @date:          2019
* @version:       1.0
* @group:         Global Desktop
* @description:   test class of CreateAccountOverwrite_ctlr Controller
***************************************************************************/
@isTest
public class NONC_CreateAccountOverwrite_ctlr_test {
  /**
  * @description Method which creates test data
  **/
  @testSetup static void setup() {

  }

  @isTest
  static void testNClientValidate() {
    try {
      NONC_CreateAccountOverwrite_ctlr.getRTDeveloperName('recordtypeid');
    } catch(exception ex) {

    }
    NONC_CreateAccountOverwrite_ctlr.getDefaultRTId();
    NONC_CreateAccountOverwrite_ctlr.getNonClientRTID();
    NONC_CreateAccountOverwrite_ctlr.getGroupNonClientRTName();
    NONC_CreateAccountOverwrite_ctlr.getGroupNonClientRTID();
    final String rtName = NONC_CreateAccountOverwrite_ctlr.getNonClientRTName();
    final Prospect_validation__c NonClientCS = Prospect_validation__c.getInstance();
    system.assertEquals(NonClientCS.Non_Client_RecordType__c, rtName, 'rtName');
  }
}