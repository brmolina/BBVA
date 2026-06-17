global with sharing class MARY_SubscriberImpl extends mry.Subscriber {
    public override Map<String, Object> getUserInfo(String userId) {
        User u = [select FederationIdentifier, DES_Country__c, DES_LevelUO_10__c from User where Id = :userId with user_mode];
        return new Map<String, Object>{
            'employeeId' => (String) u.FederationIdentifier,
            'workCountry' => (String) u.DES_Country__c,
            'organizationalUnitCode' => (String) u.DES_LevelUO_10__c
        };
    }
    public override Map<String, Object> logException(Exception e) {
        DES_Exception_Utils.logException(e, null, null, 'MARY', null);
        return new Map<String, Object>();
    }
}