/*
 * @author GlobalDesktop
 * @description Clase test de la clase InttCmpApexController
 */
@isTest
public class InttCmpApexControllerTest {
	
	/*
	* Met0d0 Test
	*/
    @isTest static void getUserPermission() {
        final Profile profile = [SELECT Id FROM Profile WHERE Name='Standard User'];
        final User user = new User(Alias = 'newUser', Email='newuser@testorg.com',
        					EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US',
         					LocaleSidKey='en_US', ProfileId = profile.Id,
         					TimeZoneSidKey='America/Los_Angeles', UserName='newusertesting.ag@testorg.com', ID_User__c = String.valueOf(Datetime.now()));
        System.runAs(user) {
            final Boolean permission = InttCmpApexController.getPermission();
            System.assert(!permission, 'OK');
            InttCmpApexController intt;
            intt = InttCmpApexController.getInstance();
            System.debug(intt);
        }
    }
}