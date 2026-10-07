/**
 * @description Apex controller to manage DMT_NotificationSubscription__c records from LWC.
 *              Allows the current user to subscribe/unsubscribe to global event notifications.
 */
public with sharing class DMT_NotificationSubscriptionController {

    /**
     * @description Returns true if the current user has any subscription for the given type.
     *              Checks both global (Client__c = NULL) and client-specific subscriptions.
     * @param type     Picklist value, e.g. 'Closed_Won'.
     * @return Boolean true when any subscription record exists for this user and type.
     */
    @AuraEnabled(cacheable=true)
    public static Boolean getSubscription(String type) {
        if (String.isBlank(type)) {
            return false;
        }
        Id userId = UserInfo.getUserId();
        List<DMT_NotificationSubscription__c> subs = [
            SELECT Id
            FROM DMT_NotificationSubscription__c
            WHERE User__c = :userId
              AND Type__c  = :type
            WITH USER_MODE
            LIMIT 1
        ];
        return !subs.isEmpty();
    }

    /**
     * @description Creates a global subscription record for the current user if one does not already exist.
     * @param type     Picklist value, e.g. 'Closed_Won'.
     */
    @AuraEnabled
    public static void saveSubscription(String type) {
        if (String.isBlank(type)) {
            throw new AuraHandledException('type is required.');
        }
        Id userId = UserInfo.getUserId();
        List<DMT_NotificationSubscription__c> existing = [
            SELECT Id
            FROM DMT_NotificationSubscription__c
            WHERE User__c = :userId
              AND Client__c = NULL
              AND Type__c  = :type
            WITH USER_MODE
            LIMIT 1
        ];
        if (existing.isEmpty()) {
            DMT_NotificationSubscription__c sub = new DMT_NotificationSubscription__c(
                User__c   = userId,
                Client__c = null,
                Type__c   = type
            );
            insert as user sub;
        }
    }

    /**
     * @description Deletes ALL subscription records for the current user and type.
     *              Removes both global (Client__c = NULL) and client-specific subscriptions.
     * @param type     Picklist value, e.g. 'Closed_Won'.
     */
    @AuraEnabled
    public static void deleteSubscription(String type) {
        if (String.isBlank(type)) {
            return;
        }
        Id userId = UserInfo.getUserId();
        List<DMT_NotificationSubscription__c> toDelete = [
            SELECT Id
            FROM DMT_NotificationSubscription__c
            WHERE User__c = :userId
              AND Type__c  = :type
            WITH USER_MODE
        ];
        if (!toDelete.isEmpty()) {
            delete as user toDelete;
        }
    }
}