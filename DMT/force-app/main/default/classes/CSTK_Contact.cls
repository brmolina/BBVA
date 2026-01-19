/**
* ____________________________________________________________________________
* Toolkit Contact
* Sample implementation of the interface Contact_Itf
* ____________________________________________________________________________
* @author      Torcuato Tejada <torcuato.tejada.contractor@bbva.com>
* @modifiedBy
* @version     1.0
* @created     2021-05-23
* @modified
* @systemLayer Sample
* ____________________________________________________________________________
* @changes
*
* ____________________________________________________________________________
*/
@SuppressWarnings('PMD, sf:DMLWithoutSharingEnabled')
global class CSTK_Contact {

    /**
    * @description Returns contacts
    * @param toolkitId : Id of the Toolkit
    * @param userId : Id of the User
    * @return Map<String, Boolean> map with the actions and permissions
    */
    global Map<String, Object> getContactInfo(Id toolkitId) {
        final Map<String, Object> res = new Map<String, Object>();
        return res;
    }

}