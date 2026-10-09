# CIBGLOBALD-4617 - deployment notes

## Deploy order

1. Deploy `manifest/CIBGLOBALD-4617-package.xml` in one deployment: the event definition `DMT_Task__e` (publish behavior now PublishAfterCommit), `DTM_Task_Helper`, `DTM_Task_Helper_Test`, `DMT_Passport_TriggerHandler`, `DMT_ApprovalChangeStep_Helper`, the `Task` trigger and the LWCs `dmt_passport` and `dmt_passport_opportunity`. The trigger and the helper must go together (new `processTask` signature), and the LWCs read the new event payload.
2. Check that `CIB_Bypass__c.CIB_skip_platform_event__c` is false for the users of the org. If it is true, no `DMT_Task__e` event is published and the Passports do not refresh live.
3. Verify a Passport on a Line and on an Opportunity (traffic light on a reject and on a reopen, Obsolete warning).
4. Only then run the manual step below.

## Manual post-deployment steps

- Setup > Change Data Capture.
- In Selected Entities, remove Passport (Passport__ChangeEvent). Save.
- Setup > Custom Settings > CIB Bypass > Manage.
- On every row (org default, profile or user) with CIB_skip_platform_event__c checked: Edit, uncheck CIB_skip_platform_event__c, Save.
- Open a Line Passport and an Opportunity Passport: change a Task from another session and check the traffic light updates without reload.
