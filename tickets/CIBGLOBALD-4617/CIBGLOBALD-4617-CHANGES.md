# CIBGLOBALD-4617 - Replace the Platform Events consumption of the Passport LWCs

Written for: a developer who has to review, stage and deploy this change.

## What this change does

Both Passport LWCs (`dmt_passport` on Lines, `dmt_passport_opportunity` on Opportunities) subscribed to two channels:
`/event/DMT_Task__e` and `/data/Passport__ChangeEvent` (Change Data Capture of Passport__c). In PROD this reached the
~50,000 daily event delivery limit. `Task.trigger` published `DMT_Task__e` for every Task of the org, and every open Passport tab
received every event.

Now:

- `DMT_Task__e` is published only for DMT approval Tasks (record type DMT_Step_Approval) that belong to a Case, and on update only when
  a field the traffic lights use changed (Status, OwnerId, DMT_Step_Result__c, DMT_Step_Type__c, DMT_Task_Type__c, DMT_UserClosedTask__c,
  DMT_Committee_Label__c). One event per transaction and operation.
- The event now carries the Line or Opportunity Id in `records__c` (resolved with `Case.DMT_LineOpportunity__c`: L = Line, O = Opportunity),
  not Task Ids, so an open Passport also catches brand-new replacement Tasks (case reopen). Operations: CREATE, MODIFY, MODIFY_MULTI
  (several Tasks of the same record in one transaction, used by the Opp Close Task detection) and PASSPORT.
- The Passport change event subscription is replaced by a PASSPORT operation of the same event, published by the Passport__c trigger only when
  DMT_Passport_Save__c or DMT_Is_Obsoleted_Passport_Save__c changes. The logic that sets the Obsolete flag is untouched.
- The explicit CASE_UPDATE publish in `restartTasksForRecord` is removed: the cancelled and replacement Tasks already go through Task.trigger.
- `DMT_Task__e` publish behavior changed from PublishImmediately to PublishAfterCommit. With PublishImmediately the event left before the
  transaction committed, so an open Passport re-read old data and the traffic light stayed stale after a reopen (found in testing).
- Both LWCs: one subscription (DMT_Task__e), match on their own Line or Opportunity Id, unsubscribe while the browser tab is hidden and
  refresh once when it comes back after more than 30 seconds.

The CIB_Bypass__c.CIB_skip_platform_event__c bypass is kept: `DTM_Task_Helper` still honors it. If it is true for a user, no event is published for them.
In DMT_TCM_DEV it was true for the System Administrator and BBVA Standard User profiles (a last-minute firefighter workaround) and was cleared on 2026-10-09.

## Files to stage

```
DMT/force-app/main/default/classes/DTM_Task_Helper.cls
DMT/force-app/main/default/classes/DTM_Task_Helper_Test.cls
DMT/force-app/main/default/classes/DTM_Task_Helper_Test.cls-meta.xml
DMT/force-app/main/default/classes/DMT_Passport_TriggerHandler.cls
DMT/force-app/main/default/classes/DMT_ApprovalChangeStep_Helper.cls
DMT/force-app/main/default/triggers/Task.trigger
DMT/force-app/main/default/objects/DMT_Task__e/DMT_Task__e.object-meta.xml
DMT/force-app/main/default/lwc/dmt_passport/dmt_passport.js
DMT/force-app/main/default/lwc/dmt_passport_opportunity/dmt_passport_opportunity.js
```

Anything else that shows as modified in the working tree (for example DMT_Line_Helper, DMT_Case_Steps_Controller) is not part of this ticket.
`manifest/CIBGLOBALD-4617-package.xml` and `manifest/CIBGLOBALD-4617-destructiveChanges.xml` are local tools and are not staged in the work repo.

## Manual post-deployment steps

- Setup > Change Data Capture.
- In Selected Entities, remove Passport (Passport__ChangeEvent). Save.
- Setup > Custom Settings > CIB Bypass > Manage.
- On every row (org default, profile or user) with CIB_skip_platform_event__c checked: Edit, uncheck CIB_skip_platform_event__c, Save.
- Open a Line Passport and an Opportunity Passport: change a Task from another session and check the traffic light updates without reload.

## Retrieve / deploy package

`manifest/CIBGLOBALD-4617-package.xml` (retrieve with `sf project retrieve start -x manifest/CIBGLOBALD-4617-package.xml -o DMT_TCM_DEV`).
Everything is already deployed to DMT_TCM_DEV. Deploy all entries together: the Task trigger needs the new `DTM_Task_Helper.processTask` signature and the LWCs read the new event payload.

## Tests

- `DTM_Task_Helper_Test` (new, 12 tests) passes in DMT_TCM_DEV, together with DMT_ApprovalChangeStep_HelperTest, DMT_Passport_Handler_test and DMT_Passport_FeatureSync_test (64 of 64).
  Seven existing tests (4 in DMT_Line_TriggerHandler_Test, 3 in DMT_OpportunityTriggerHandler_Test) fail in DMT_TCM_DEV with and without this change.
- Tested live in the browser against DMT_TCM_DEV, no page reload: Line traffic light reject (red) and reopen (yellow); Opportunity traffic light reject (red) and reopen (yellow);
  Opportunity Obsolete warning appears and disappears.
- Not tested yet: Line Obsolete warning (visually), the full chain Opp field edit -> flow -> Obsolete -> warning, hidden tab catch-up, Opp Close Task refresh, two users at once, regression of Request/close/reactivate.

## ANS

Touches common elements: `Task.trigger` and `DTM_Task_Helper` (Task object, shared trigger), and `DMT_Task__e` (payload meaning and publish behavior changed; only DMT code publishes or subscribes to it).

---

## Code applied

### 1. DTM_Task_Helper

`DMT/force-app/main/default/classes/DTM_Task_Helper.cls`

Whole class replaced (it was a 20 line class), **lines 1-161**.

```apex
public with sharing class DTM_Task_Helper {

    // CIBGLOBALD-4617 - operations carried by DMT_Task__e.Operation__c. records__c now holds the
    // Line / Opportunity Ids affected (not Task Ids), so a subscribed Passport can match on the
    // record it is open on, including brand-new replacement Tasks it has never seen.
    // MODIFY_MULTI = more than one approval Task of the same record changed in the same transaction
    // (e.g. all Tasks of a Case finished at once on Close Task).
    @TestVisible private static final String OP_CREATE = 'CREATE';
    @TestVisible private static final String OP_MODIFY = 'MODIFY';
    @TestVisible private static final String OP_MODIFY_MULTI = 'MODIFY_MULTI';
    // The Passport__c record itself changed (JSON recalculated or Obsolete flag flipped).
    @TestVisible private static final String OP_PASSPORT = 'PASSPORT';

    // CIBGLOBALD-4617 - Task fields that feed the Passport traffic lights / step info
    // (DMT_Case_Steps_Controller.getCurrentStepsFromCases). A change on any other field does not
    // need to wake up the open Passports.
    private static final List<Schema.SObjectField> WATCHED_FIELDS = new List<Schema.SObjectField>{
        Task.Status,
        Task.OwnerId,
        Task.DMT_Step_Result__c,
        Task.DMT_Step_Type__c,
        Task.DMT_Task_Type__c,
        Task.DMT_UserClosedTask__c,
        Task.DMT_Committee_Label__c
    };

    /**
     * CIBGLOBALD-4617 - Publishes DMT_Task__e only for DMT approval Tasks that belong to a Case of a
     * Line or an Opportunity and, on update, only when a watched field changed. Previously it
     * published for every Task of the org.
     * @param newList   Trigger.new
     * @param oldMap    Trigger.oldMap on update, null on insert
     * @param operation CREATE or MODIFY (the trigger context)
     */
    public static void processTask(List<Task> newList, Map<Id, Task> oldMap, String operation) {
        publish(buildTaskEvents(newList, oldMap, operation));
    }

    @TestVisible
    private static List<DMT_Task__e> buildTaskEvents(List<Task> newList, Map<Id, Task> oldMap, String operation) {
        List<DMT_Task__e> events = new List<DMT_Task__e>();
        CIB_Bypass__c byPass = CIB_Bypass__c.getInstance();
        if (byPass.CIB_skip_platform_event__c) {
            return events;
        }

        List<Task> relevantTasks = new List<Task>();
        Set<Id> caseIds = new Set<Id>();
        for (SObject record : DES_RecordType_Utils.filter((List<SObject>) newList, 'Task', DMT_Constants.TASK_RT_APPROVAL_STEP)) {
            Task t = (Task) record;
            if (t.WhatId == null || t.WhatId.getSObjectType() != Case.SObjectType) {
                continue;
            }
            if (oldMap != null && !hasWatchedChange(t, oldMap.get(t.Id))) {
                continue;
            }
            relevantTasks.add(t);
            caseIds.add(t.WhatId);
        }
        if (relevantTasks.isEmpty()) {
            return events;
        }

        Map<Id, Case> casesById = new Map<Id, Case>([
            SELECT Id, DMT_LineOpportunity__c, DMT_Line__c, opportunity_id__c
            FROM Case
            WHERE Id IN :caseIds
            WITH SYSTEM_MODE
        ]);

        // Line / Opportunity Id -> how many of its approval Tasks changed in this transaction
        Map<Id, Integer> changedTasksByRecordId = new Map<Id, Integer>();
        for (Task t : relevantTasks) {
            Case relatedCase = casesById.get(t.WhatId);
            // A Case belongs to either a Line ('L') or an Opportunity ('O'), never both
            // (DMT_LineOpportunity__c, the same discriminator DMT_ApprovalChangeStep_Handler uses)
            Id recordId = relatedCase == null ? null
                : (relatedCase.DMT_LineOpportunity__c == 'L' ? relatedCase.DMT_Line__c
                    : (relatedCase.DMT_LineOpportunity__c == 'O' ? relatedCase.opportunity_id__c : null));
            if (recordId == null) {
                continue;
            }
            Integer count = changedTasksByRecordId.get(recordId);
            changedTasksByRecordId.put(recordId, count == null ? 1 : count + 1);
        }

        List<Id> singleRecordIds = new List<Id>();
        List<Id> multiRecordIds = new List<Id>();
        for (Id recordId : changedTasksByRecordId.keySet()) {
            if (operation == OP_MODIFY && changedTasksByRecordId.get(recordId) > 1) {
                multiRecordIds.add(recordId);
            } else {
                singleRecordIds.add(recordId);
            }
        }

        if (!singleRecordIds.isEmpty()) {
            events.add(new DMT_Task__e(Operation__c = operation, records__c = String.join(singleRecordIds, ',')));
        }
        if (!multiRecordIds.isEmpty()) {
            events.add(new DMT_Task__e(Operation__c = OP_MODIFY_MULTI, records__c = String.join(multiRecordIds, ',')));
        }
        return events;
    }

    /**
     * CIBGLOBALD-4617 - Replaces the Passport__ChangeEvent subscription: publishes DMT_Task__e
     * (Operation PASSPORT, keyed by Line / Opportunity Id) only when the Passport JSON or its
     * Obsolete flag actually changed, instead of delivering every change of every Passport__c.
     * Called from DMT_Passport_TriggerHandler.afterUpdate.
     */
    public static void processPassportChange(List<Passport__c> newList, Map<Id, Passport__c> oldMap) {
        publish(buildPassportEvents(newList, oldMap));
    }

    @TestVisible
    private static List<DMT_Task__e> buildPassportEvents(List<Passport__c> newList, Map<Id, Passport__c> oldMap) {
        List<DMT_Task__e> events = new List<DMT_Task__e>();
        CIB_Bypass__c byPass = CIB_Bypass__c.getInstance();
        if (byPass.CIB_skip_platform_event__c || oldMap == null) {
            return events;
        }

        Set<Id> recordIds = new Set<Id>();
        for (Passport__c passport : newList) {
            Passport__c oldPassport = oldMap.get(passport.Id);
            if (oldPassport == null) {
                continue;
            }
            Boolean changed = passport.DMT_Is_Obsoleted_Passport_Save__c != oldPassport.DMT_Is_Obsoleted_Passport_Save__c
                || passport.DMT_Passport_Save__c != oldPassport.DMT_Passport_Save__c;
            Id recordId = passport.DMT_Line__c != null ? passport.DMT_Line__c : passport.Opportunity__c;
            if (changed && recordId != null) {
                recordIds.add(recordId);
            }
        }
        if (!recordIds.isEmpty()) {
            events.add(new DMT_Task__e(Operation__c = OP_PASSPORT, records__c = String.join(new List<Id>(recordIds), ',')));
        }
        return events;
    }

    private static void publish(List<DMT_Task__e> events) {
        if (!events.isEmpty()) {
            EventBus.publish(events);
        }
    }

    private static Boolean hasWatchedChange(Task newTask, Task oldTask) {
        if (oldTask == null) {
            return true;
        }
        for (Schema.SObjectField field : WATCHED_FIELDS) {
            if (newTask.get(field) != oldTask.get(field)) {
                return true;
            }
        }
        return false;
    }
}

```

### 2. Task trigger

`DMT/force-app/main/default/triggers/Task.trigger`

**Now lines 37-46** (replaces old lines 37-46)

Old:

```apex
    if (Trigger.isInsert && Trigger.isAfter)
    {
        DTM_Task_Helper.processTask(Trigger.new, 'CREATE');
    }

    if (Trigger.isUpdate && Trigger.isAfter)
    {
        DTM_Task_Helper.processTask(Trigger.new, 'MODIFY');
        if (byPass.CIB_skip_trigger__c) {
            List<Task> dmtTasks = DES_RecordType_Utils.filter((List<SObject>) Trigger.new, 'Task', 'DMT_Step_Approval');
```

New:

```apex
    if (Trigger.isInsert && Trigger.isAfter)
    {
        DTM_Task_Helper.processTask(Trigger.new, null, 'CREATE');
    }

    if (Trigger.isUpdate && Trigger.isAfter)
    {
        DTM_Task_Helper.processTask(Trigger.new, Trigger.oldMap, 'MODIFY');
        if (byPass.CIB_skip_trigger__c) {
            List<Task> dmtTasks = DES_RecordType_Utils.filter((List<SObject>) Trigger.new, 'Task', 'DMT_Step_Approval');
```

### 3. DMT_Passport_TriggerHandler

`DMT/force-app/main/default/classes/DMT_Passport_TriggerHandler.cls`

**Now lines 27-33** (replaces old lines 27-30)

Old:

```apex

    public override void afterUpdate() {
        // CIBGLOBALD-4507: sync approval Cases/Tasks with the features received from Passport
        DMT_Passport_FeatureSync.sync(this.lstNew, this.mapOld);
```

New:

```apex

    public override void afterUpdate() {
        // CIBGLOBALD-4617: tell open Passports the record changed (replaces Passport__ChangeEvent)
        DTM_Task_Helper.processPassportChange(this.lstNew, this.mapOld);

        // CIBGLOBALD-4507: sync approval Cases/Tasks with the features received from Passport
        DMT_Passport_FeatureSync.sync(this.lstNew, this.mapOld);
```

### 4. DMT_ApprovalChangeStep_Helper

`DMT/force-app/main/default/classes/DMT_ApprovalChangeStep_Helper.cls`

**Now lines 103-110** (replaces old lines 103-110)

Old:

```apex
            Database.update(casesToResetByCaseId.values(), AccessLevel.SYSTEM_MODE);

            // Publishes the LINE/OPPORTUNITY Id, not a Task Id: dmt_passport.js only recognises
            // Task Ids it already knows, so it can never match a brand-new replacement task. It
            // does track the record Id, so this refreshes the traffic light reliably.
            EventBus.publish(new DMT_Task__e(Operation__c = 'CASE_UPDATE', records__c = String.valueOf(recordId)));
        } catch (Exception e) {
            Database.rollback(sp);
```

New:

```apex
            Database.update(casesToResetByCaseId.values(), AccessLevel.SYSTEM_MODE);

            // CIBGLOBALD-4617 - no explicit event here anymore: the cancelled and the replacement
            // Tasks go through Task.trigger -> DTM_Task_Helper, which already publishes one
            // DMT_Task__e keyed by this Line / Opportunity Id, so open Passports refresh the traffic
            // light without a second event.
        } catch (Exception e) {
            Database.rollback(sp);
```

### 5. DMT_Task__e (event definition)

`DMT/force-app/main/default/objects/DMT_Task__e/DMT_Task__e.object-meta.xml`

**Now lines 5-8** (replaces old lines 5-8)

Old:

```xml
    <label>DMT_Task</label>
    <pluralLabel>DMT_Tasks</pluralLabel>
    <publishBehavior>PublishImmediately</publishBehavior>
</CustomObject>
```

New:

```xml
    <label>DMT_Task</label>
    <pluralLabel>DMT_Tasks</pluralLabel>
    <publishBehavior>PublishAfterCommit</publishBehavior>
</CustomObject>
```

### 6. dmt_passport.js (Lines)

`DMT/force-app/main/default/lwc/dmt_passport/dmt_passport.js`

**Now lines 42-48** (replaces old lines 42-45)

Old:

```javascript
import hasLineGodPermission from '@salesforce/customPermission/DMT_Line_God';

export default class Dmt_passport extends LightningElement {

```

New:

```javascript
import hasLineGodPermission from '@salesforce/customPermission/DMT_Line_God';

// CIBGLOBALD-4617 - refresh once on return if the tab was hidden longer than this (events are not delivered while unsubscribed)
const CATCH_UP_AFTER_HIDDEN_MS = 30000;

export default class Dmt_passport extends LightningElement {

```

**Now lines 111-121** (replaces old lines 108-116)

Old:

```javascript


  //Change Data Capture
  channelNamePassport = '/data/Passport__ChangeEvent';
  subscriptionPassport = {}; // holds subscription, used for unsubscribe
  channelNameTask = '/event/DMT_Task__e';
  subscriptionTask = {}; // holds subscription, used for unsubscribe

  wiredLineResult; // holds the line information
```

New:

```javascript


  // CIBGLOBALD-4617 - single filtered channel. DMT_Task__e is published only for DMT approval Task
  // changes and for Passport JSON / Obsolete changes, keyed by Line / Opportunity Id.
  // The Passport__ChangeEvent subscription was removed.
  channelNameTask = '/event/DMT_Task__e';
  subscriptionTask = null; // holds subscription, used for unsubscribe
  hiddenAt = null; // timestamp of the moment the tab became hidden
  visibilityHandler;

  wiredLineResult; // holds the line information
```

**Now lines 205-210** (replaces old lines 200-205)

Old:

```javascript

  disconnectedCallback() {
    unsubscribe(this.subscriptionPassport, () => console.log('Unsubscribed to change events Passport.'));
    unsubscribe(this.subscriptionTask, () => console.log('Unsubscribed to change events Task.'));
    pubsub.unregister('callPassportLWC', this.handleEventObj);
    unregisterRefreshContainer(this.refreshContainerID);
```

New:

```javascript

  disconnectedCallback() {
    document.removeEventListener('visibilitychange', this.visibilityHandler);
    this.unsubscribeFromTaskChannel();
    pubsub.unregister('callPassportLWC', this.handleEventObj);
    unregisterRefreshContainer(this.refreshContainerID);
```

**Now lines 1035-1132** (replaces old lines 1030-1142)

Old:

```javascript

  // Called by connectedCallback()
  registerSubscribe() {
    const changeEventPassportCallback = changeEventPassport => {
      this.processChangePassportEvent(changeEventPassport);
    };

    const changeEventTaskCallback = changeEventTask => {
      this.processChangeTaskEvent(changeEventTask);
    };

    // Sets up subscription and callback for change events
    subscribe(this.channelNamePassport, -1, changeEventPassportCallback).then(subscription => {
      this.subscriptionPassport = subscription;
      console.log('[DEBUG-REFRESH] Subscribed to Passport channel:', this.channelNamePassport, subscription);
    });
    subscribe(this.channelNameTask, -1, changeEventTaskCallback).then(subscription => {
      this.subscriptionTask = subscription;
      console.log('[DEBUG-REFRESH] Subscribed to Task channel:', this.channelNameTask, subscription);
    });

    getRecordNotifyChange([{ recordId: this.passportId }]);
  }

  // Called by registerSubscribe()
  processChangePassportEvent(changeEvent) {
    try {
      const recordIds = changeEvent.data.payload.ChangeEventHeader.recordIds; // avoid deconstruction
      console.log('[DEBUG-REFRESH] processChangePassportEvent received. recordIds:', recordIds, 'this.passportId:', this.passportId);
      if(recordIds.includes(this.passportId)){
          console.log('[DEBUG-REFRESH] Passport event MATCHES this.passportId - refreshing.');
          getRecordNotifyChange([{ recordId: this.passportId }]); // Refresh all components
          console.warn('[CDC] Passport changed. Forcing Wire Refresh.');

          // This forces the wire to go back to the server and get the JSON updated by the Trigger
          refreshApex(this.wiredPassportResult);

          if (this.opportunityId) {
            getRecordNotifyChange([{ recordId: this.opportunityId }]);
          } else if (this.lineId) {
            getRecordNotifyChange([{ recordId: this.lineId }]);
          }
      } else {
          console.log('[DEBUG-REFRESH] Passport event did NOT match this.passportId - ignored.');
      }
    } catch (err) {
      this.handleError(error);
    }
  }

  processChangeTaskEvent(changeEvent) {
    try {
      const recordIds = changeEvent.data.payload.records__c.split(',');
      const operation = changeEvent.data.payload.Operation__c;
      console.log('[DEBUG-REFRESH] processChangeTaskEvent received. recordIds:', recordIds, 'operation:', operation, 'current this.tasksId:', this.tasksId);

      // CIBGLOBALD-4117: DMT_ApprovalChangeStep_Helper.restartTasksForRecord publishes this operation with the
      // Line/Opportunity Id itself, not a Task Id - this.lineId/this.opportunityId are already
      // known from load, unlike a brand-new replacement Task's Id (see the isRelatedTask gap
      // below), so this is a reliable way to detect "this passport's approval state changed"
      // regardless of which specific Tasks were cancelled/created underneath it.
      if (operation === 'CASE_UPDATE') {
          const isRelatedRecord = recordIds.includes(this.lineId) || recordIds.includes(this.opportunityId);
          console.log('[DEBUG-REFRESH] CASE_UPDATE event. this.lineId:', this.lineId, 'this.opportunityId:', this.opportunityId, 'isRelatedRecord:', isRelatedRecord);
          if (isRelatedRecord) {
              refreshApex(this.wiredInformationPassportResult).then(() => {
                  if (this.rawPayload) {
                      console.info('[DEBUG-REFRESH] CASE_UPDATE matched - calling executeSafeSync(TASK_UPDATED).');
                      this.executeSafeSync('TASK_UPDATED');
                  } else {
                      console.info('[DEBUG-REFRESH] CASE_UPDATE matched but this.rawPayload is falsy - executeSafeSync NOT called.');
                  }
              });
          }
          return;
      }

   //   if(operation === 'CREATE'){
        refreshApex(this.wiredInformationPassportResult).then(result => {
          console.log('[DEBUG-REFRESH] wiredInformationPassportResult refreshed after task event. New this.tasksId:', this.tasksId);
          this.searchTask(recordIds);
        });
   //   }
      this.searchTask(recordIds);

    } catch (err) {
      this.handleError(error);
    }
  }

  searchTask(recordIds) {
      // 1. Check if any of the updated tasks belong to this passport
      const isRelatedTask = this.tasksId.some(t => recordIds.includes(t));
      console.log('[DEBUG-REFRESH] searchTask called. recordIds:', recordIds, 'this.tasksId:', this.tasksId, 'isRelatedTask:', isRelatedTask);

      if (isRelatedTask) {
          // 2. Refresh the wire to get latest IDs, then run the Orchestrator
          console.log('[DEBUG-REFRESH] isRelatedTask TRUE - refreshing wiredInformationPassportResult and calling executeSafeSync(TASK_UPDATED).');
          refreshApex(this.wiredInformationPassportResult).then(() => {
              if (this.rawPayload) {
                  // This safely rebuilds the buffer, checks the server, and renders the UI
                  this.executeSafeSync('TASK_UPDATED');
              } else {
                  console.log('[DEBUG-REFRESH] isRelatedTask TRUE but this.rawPayload is falsy - executeSafeSync NOT called.');
              }
          });
      } else {
          console.log('[DEBUG-REFRESH] isRelatedTask FALSE - no refresh triggered for this event. This is the gap: a brand-new task Id would not yet be in this.tasksId.');
      }
  }

  @api
  async callService() {
```

New:

```javascript

  // Called by connectedCallback()
  // CIBGLOBALD-4617 - subscribes only to the filtered DMT_Task__e channel, and only while the tab is
  // visible: a hidden tab would otherwise keep consuming event deliveries for nothing.
  registerSubscribe() {
    if (document.visibilityState !== 'hidden') {
      this.subscribeToTaskChannel();
    } else {
      // Loaded in a background tab: remember it, so the first time it becomes visible it catches up
      this.hiddenAt = Date.now();
    }

    this.visibilityHandler = () => this.handleVisibilityChange();
    document.addEventListener('visibilitychange', this.visibilityHandler);

    getRecordNotifyChange([{ recordId: this.passportId }]);
  }

  subscribeToTaskChannel() {
    if (this.subscriptionTask) {
      return; // already subscribed
    }
    this.subscriptionTask = {}; // placeholder so a second call while subscribing is ignored
    subscribe(this.channelNameTask, -1, changeEventTask => {
      this.processChangeTaskEvent(changeEventTask);
    }).then(subscription => {
      this.subscriptionTask = subscription;
    }).catch(error => {
      this.subscriptionTask = null;
      console.error('Task channel subscription failed', JSON.stringify(error));
    });
  }

  unsubscribeFromTaskChannel() {
    if (this.subscriptionTask && this.subscriptionTask.id !== undefined) {
      unsubscribe(this.subscriptionTask, () => {});
    }
    this.subscriptionTask = null;
  }

  handleVisibilityChange() {
    if (document.visibilityState === 'hidden') {
      this.hiddenAt = Date.now();
      this.unsubscribeFromTaskChannel();
      return;
    }

    this.subscribeToTaskChannel();
    // Events published while the tab was hidden were not delivered: catch up with one refresh
    if (this.hiddenAt && Date.now() - this.hiddenAt > CATCH_UP_AFTER_HIDDEN_MS) {
      this.refreshFromBackend();
    }
    this.hiddenAt = null;
  }

  // Re-reads the Passport record (JSON + Obsolete flag) and the Tasks / traffic lights
  refreshFromBackend() {
    refreshApex(this.wiredPassportResult);
    refreshApex(this.wiredInformationPassportResult).then(() => {
      if (this.rawPayload) {
        this.executeSafeSync('TASK_UPDATED');
      }
    });
  }

  // CIBGLOBALD-4617 - DMT_Task__e payload: records__c = Line / Opportunity Ids, Operation__c =
  // CREATE | MODIFY | MODIFY_MULTI (approval Tasks) or PASSPORT (Passport JSON / Obsolete changed).
  // Matching on the record Id also catches brand-new replacement Tasks (e.g. a reopened Case).
  processChangeTaskEvent(changeEvent) {
    try {
      const recordIds = changeEvent.data.payload.records__c.split(',');
      const operation = changeEvent.data.payload.Operation__c;
      const isRelatedRecord = (this.lineId && recordIds.includes(this.lineId))
        || (this.opportunityId && recordIds.includes(this.opportunityId));
      if (!isRelatedRecord) {
        return;
      }

      if (operation === 'PASSPORT') {
        // Forces the wire to go back to the server for the JSON / Obsolete flag the backend updated
        getRecordNotifyChange([{ recordId: this.passportId }]);
        refreshApex(this.wiredPassportResult);
        return;
      }

      refreshApex(this.wiredInformationPassportResult).then(() => {
        if (this.rawPayload) {
          // Safely rebuilds the buffer, checks the server and renders the traffic lights
          this.executeSafeSync('TASK_UPDATED');
        }
      });
    } catch (error) {
      this.handleError(error);
    }
  }

  @api
  async callService() {
```

### 7. dmt_passport_opportunity.js (Opportunities)

`DMT/force-app/main/default/lwc/dmt_passport_opportunity/dmt_passport_opportunity.js`

**Now lines 37-41** (replaces old lines 37-44)

Old:

```javascript
const ERROR_MESSAGE = 'error';
const ERROR_PASSPORT_MESSAGE = 'Error processing passport';
const UNSUBCRIBE_MESSAGE = 'Unsubscribed to change events';
const UNKNOWN_MESSAGE = 'Unknown error';
const PASSPORT_ENTITY = 'Passport__c';
const TASK_ENTTITY = 'Task';
const STRING_TYPE = 'string';
const MOTOR_DESC_FIELD = 'motorDesc';
```

New:

```javascript
const ERROR_MESSAGE = 'error';
const ERROR_PASSPORT_MESSAGE = 'Error processing passport';
const UNKNOWN_MESSAGE = 'Unknown error';
const STRING_TYPE = 'string';
const MOTOR_DESC_FIELD = 'motorDesc';
```

**Now lines 73-81** (replaces old lines 76-81)

Old:

```javascript
const CLOSED_WON_OPPORTUNITY_STATE = 'Closed Won';

const CHANNEL_PASSPORT = '/data/Passport__ChangeEvent';
const CHANNEL_TASK = '/event/DMT_Task__e';


```

New:

```javascript
const CLOSED_WON_OPPORTUNITY_STATE = 'Closed Won';

// CIBGLOBALD-4617 - single filtered channel: DMT_Task__e is published only for DMT approval Task changes
// and for Passport JSON / Obsolete changes, keyed by Line / Opportunity Id. Passport__ChangeEvent was removed.
const CHANNEL_TASK = '/event/DMT_Task__e';
// Refresh once on return if the tab was hidden longer than this (events are not delivered while unsubscribed)
const CATCH_UP_AFTER_HIDDEN_MS = 30000;


```

**Now lines 178-184** (replaces old lines 178-183)

Old:

```javascript
    showfeaturesTable = false;
    featuresId;
    subscriptionPassport;
    subscriptionTask;
    recordType;
    groupedData = [];
```

New:

```javascript
    showfeaturesTable = false;
    featuresId;
    subscriptionTask = null;
    hiddenAt = null;
    visibilityHandler;
    recordType;
    groupedData = [];
```

**Now lines 392-397** (replaces old lines 391-396)

Old:

```javascript

    disconnectedCallback() {
        unsubscribe(this.subscriptionPassport, () => console.info(UNSUBCRIBE_MESSAGE + PASSPORT_ENTITY));
        unsubscribe(this.subscriptionTask, () => console.info(UNSUBCRIBE_MESSAGE + TASK_ENTTITY));
        pubsub.unregister('callPassportLWC', this.handleEventObj);
        unregisterRefreshContainer(this.refreshContainerID);
```

New:

```javascript

    disconnectedCallback() {
        document.removeEventListener('visibilitychange', this.visibilityHandler);
        this.unsubscribeFromTaskChannel();
        pubsub.unregister('callPassportLWC', this.handleEventObj);
        unregisterRefreshContainer(this.refreshContainerID);
```

**Now lines 455-529** (replaces old lines 454-492)

Old:

```javascript
    }

    registerSubscribe() {

        const changeEventPassportCallback = changeEventPassport => {
            this.processChangePassportEvent(changeEventPassport);
        };

        const changeEventTaskCallback = changeEventTask => {
            this.processChangeTaskEvent(changeEventTask);
        };

        subscribe(CHANNEL_PASSPORT, -1, changeEventPassportCallback).then(subscription => {
            this.subscriptionPassport = subscription;
        });
        subscribe(CHANNEL_TASK, -1, changeEventTaskCallback).then(subscription => {
            this.subscriptionTask = subscription;
        });

        notifyRecordUpdateAvailable([{ recordId: this.passportId }]);
    }

    processChangePassportEvent(changeEvent) {
        try {
            const recordIds = changeEvent.data.payload.ChangeEventHeader.recordIds;
            if(recordIds.includes(this.passportId)){
                notifyRecordUpdateAvailable([{ recordId: this.passportId }]);
            }
        } catch (error) {
            this.handleError(error.message);
        }
    }

    processChangeTaskEvent(changeEvent) {
        try {
            const operation = changeEvent.data.payload.Operation__c;
            const recordsInEvent = changeEvent.data.payload.records__c;            

            if (operation === 'CREATE' && this.checkStatusApproval && this.approvalTransitionPending) {
```

New:

```javascript
    }

    // CIBGLOBALD-4617 - subscribes only to the filtered DMT_Task__e channel, and only while the tab is
    // visible: a hidden tab would otherwise keep consuming event deliveries for nothing.
    registerSubscribe() {
        if (document.visibilityState !== 'hidden') {
            this.subscribeToTaskChannel();
        } else {
            // Loaded in a background tab: remember it, so the first time it becomes visible it catches up
            this.hiddenAt = Date.now();
        }

        this.visibilityHandler = () => this.handleVisibilityChange();
        document.addEventListener('visibilitychange', this.visibilityHandler);

        notifyRecordUpdateAvailable([{ recordId: this.passportId }]);
    }

    subscribeToTaskChannel() {
        if (this.subscriptionTask) {
            return; // already subscribed
        }
        this.subscriptionTask = {}; // placeholder so a second call while subscribing is ignored
        subscribe(CHANNEL_TASK, -1, changeEventTask => {
            this.processChangeTaskEvent(changeEventTask);
        }).then(subscription => {
            this.subscriptionTask = subscription;
        }).catch(error => {
            this.subscriptionTask = null;
            console.error('Task channel subscription failed', JSON.stringify(error));
        });
    }

    unsubscribeFromTaskChannel() {
        if (this.subscriptionTask && this.subscriptionTask.id !== undefined) {
            unsubscribe(this.subscriptionTask, () => {});
        }
        this.subscriptionTask = null;
    }

    handleVisibilityChange() {
        if (document.visibilityState === 'hidden') {
            this.hiddenAt = Date.now();
            this.unsubscribeFromTaskChannel();
            return;
        }

        this.subscribeToTaskChannel();
        // Events published while the tab was hidden were not delivered: catch up with one refresh
        if (this.hiddenAt && Date.now() - this.hiddenAt > CATCH_UP_AFTER_HIDDEN_MS) {
            notifyRecordUpdateAvailable([{ recordId: this.passportId }]);
            this.refreshAllWires();
            this.getCurrentStepFromFeaturesOpp();
        }
        this.hiddenAt = null;
    }

    // CIBGLOBALD-4617 - DMT_Task__e payload: records__c = Line / Opportunity Ids, Operation__c =
    // CREATE | MODIFY | MODIFY_MULTI (approval Tasks) or PASSPORT (Passport JSON / Obsolete changed).
    // Only events for this Opportunity are processed (the previous handler refreshed on every event).
    processChangeTaskEvent(changeEvent) {
        try {
            const operation = changeEvent.data.payload.Operation__c;
            const recordIds = changeEvent.data.payload.records__c.split(',');

            if (!this.opportunityId || !recordIds.includes(this.opportunityId)) {
                return;
            }

            if (operation === 'PASSPORT') {
                notifyRecordUpdateAvailable([{ recordId: this.passportId }]);
                return;
            }

            if (operation === 'CREATE' && this.checkStatusApproval && this.approvalTransitionPending) {
```

**Now lines 533-542** (replaces old lines 496-505)

Old:

```javascript

            this.refreshAllWires();
            this.getCurrentStepFromFeaturesOpp(); 

            // Detect "Close Task" (step 11): MODIFY event with multiple task IDs
            // means all tasks in the case were set to Finished simultaneously.
            // This is the moment to refresh the passport (callService).
            if (operation === 'MODIFY' && recordsInEvent && recordsInEvent.includes(',') && this.checkStatusReadyToClose) {
                if (!this.readytoclosePassportTriggered.has('_closetask_')) {
                    this.readytoclosePassportTriggered.add('_closetask_');
```

New:

```javascript

            this.refreshAllWires();
            this.getCurrentStepFromFeaturesOpp();

            // Detect "Close Task" (step 11): MODIFY_MULTI means several approval Tasks of this
            // Opportunity changed in the same transaction (all Tasks of the case set to Finished).
            // This is the moment to refresh the passport (callService).
            if (operation === 'MODIFY_MULTI' && this.checkStatusReadyToClose) {
                if (!this.readytoclosePassportTriggered.has('_closetask_')) {
                    this.readytoclosePassportTriggered.add('_closetask_');
```

