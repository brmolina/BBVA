/*-------------------------------------------------------------------------------------------
* @Name     Users implementation class
* @Author   torcuato.tejada.tech@bbva.com
*           roberto.rioboo.contractor@bbva.com
* @Date     Created: 2026-03-05
* -------------------------------------------------------------------------------------------
* @Description implementation of UsersInterface
* -------------------------------------------------------------------------------------------
*/
global with sharing class CGUR_Users implements cgur.UsersInterface {

    public String getUserCountry() {
        Id userId = UserInfo.getUserId();
        String country = [SELECT DES_Country__c FROM User WHERE Id = :userId LIMIT 1].DES_Country__c;
        return country;
    }
}