/*---------------------------------------------------------------------------------------------
        Company:       BBVA
        Description:   Class to test SER_CaseDetails_CONTROLLER class.
----------------------------------------------------------------------------------------------*/
@isTest
public class SER_CaseDetails_CONTROLLER_TEST {
  /**
  * description: SER_CaseDetails_CONTROLLER.getCase Test. OK
  */
  @isTest
  static void getCaseTEST2() {
    Case newCase;
    newCase = new Case();
    newCase.SER_Classification__c = 'Incidencia';
    newCase.Subject = 'test subject';
    insert newCase;

    Test.startTest();
      Try {
        SER_CaseDetails_CONTROLLER.getCase(newCase.Id);
      } catch(Exception exc) {
        System.assertEquals('Script-thrown exception', exc.getMessage(), 'Error2');
      }
    Test.stopTest();
  }
}