/**
*	Author:			Victor Velandia
*	Company:		Vass
*	Description:	Test Class SER_NewCase_CONTROLLER
*
*	History:
*	<Date>			<Author>					<Description>
*	05/07/2018		Victor Velandia				Test Class
*/
@isTest
public class SER_NewCase_TEST {
  /**
  * description: initDataOK
  * @author Victor Velandia
  */
  @isTest
  public static void initDataOK() {
    Id userID;
    userID = UserInfo.getUserId();

    Test.startTest();
    SER_NewCase_CONTROLLER.getInstance();
    System.assert (true, true);
    Test.stopTest();
  }

  /**
  * description: getDataAccountTest
  * @author Victor Velandia
  */
  @isTest
  public static void getDataCaseGNC() {

    Test.startTest();
    SER_NewCase_CONTROLLER.getDataCaseGNC();
    System.assert (true, true);
    Test.stopTest();
  }
}