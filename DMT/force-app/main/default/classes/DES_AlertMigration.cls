/**********************************************************************************
* @author       Global Desktop
* @date         12/04/2020
* @description  Batch Migration alert
**********************************************************************************/
public without sharing class DES_AlertMigration implements Database.Batchable<Sobject>, Database.Stateful {
  /* Query attribute */
  private final String pQuery;
  /* Map stages */
  static final Map<String, String> MAPIDSTATUS = new Map<String, String>();
  /* Map stages */
  static final Map<String, String> MAPIDCOMMENTS = new Map<String, String>();
  /* Map stages */
  static final Map<String, String> MAPIDREASON = new Map<String, String>();
  /* GF recordtype */
  final static String RTALERTGF = 'Commercial Task GF';
  /* PendingActions */
  final static String PENDACTIONS = 'Pending Actions';

  /*
  * constructor method
  */
  public DES_AlertMigration() {
    pQuery = 'SELECT Id, almd__commercial_alert_id__c, almd__Client_rejection_reason_desc__c, almd__Others_rejection_reason_desc__c, almd__commercial_alert_record_type__c, almd__alert_stage_type__c, almd__alert_sub_stage_type__c, almd__BBVA_rejection_reason_desc__c, almd__Rejection_reason_desc__c, almd__commercial_alert_end_date__c, (Select id from almd__Opportunities__r), (Select id from almd__Visits__r) FROM almd__Commercial_Alert__c' + (Test.isRunningTest()?' LIMIT 10':'');
  }

  /*
  * start method
  */
  public Database.QueryLocator start(Database.BatchableContext bch) {
    return Database.getQueryLocator(pQuery);
  }

  /*
  * Execute method
  */
  public void execute(Database.BatchableContext bch, List<almd__Commercial_Alert__c> scope) {
    final Map<String, String> mapIdRecordType = new Map<String, String>();
    final Set<String> alertIds = new Set<String>();
    for(almd__Commercial_Alert__c alert : scope) {
      mapIdRecordType.put(alert.almd__commercial_alert_id__c, alert.almd__commercial_alert_record_type__c);
      alertIds.add(alert.almd__commercial_alert_id__c);
      checkPending(alert);
    }
    final List<altm__Commercial_Alert__c> newAlerts = new List<altm__Commercial_Alert__c>([
      SELECT Id, altm__commercial_alert_id__c, altm__commercial_alert_task_type__c, altm__alert_stage_type__c, altm__BBVA_rejection_reason_desc__c, altm__Rejection_reason_desc__c, altm__commercial_alert_record_type__c, OwnerId, altm__participant_id__c, altm__commercial_product_type__c, altm__country_id__c, Group_Name__c, Group_Product__c, Group_Type__c, business_group_id__c FROM altm__Commercial_Alert__c WHERE altm__commercial_alert_id__c IN :alertIds
    ]);

    for(altm__Commercial_Alert__c newAlert : newAlerts) {
      newAlert.altm__alert_stage_type__c = MAPIDSTATUS.get(newAlert.altm__commercial_alert_id__c);
      if(mapIdRecordType.get(newAlert.altm__commercial_alert_id__c) == RTALERTGF) {
        newAlert.altm__commercial_alert_record_type__c = 'Commercial Task IBF';
      } else {
        newAlert.altm__commercial_alert_record_type__c = mapIdRecordType.get(newAlert.altm__commercial_alert_id__c);
      }
      if(newAlert.altm__commercial_alert_id__c != null && MAPIDCOMMENTS.get(newAlert.altm__commercial_alert_id__c) != null) {
        newAlert.altm__Rejection_reason_desc__c = MAPIDCOMMENTS.get(newAlert.altm__commercial_alert_id__c);
      }
      if(newAlert.altm__commercial_alert_id__c != null && MAPIDREASON.get(newAlert.altm__commercial_alert_id__c) != null) {
        newAlert.altm__BBVA_rejection_reason_desc__c = MAPIDREASON.get(newAlert.altm__commercial_alert_id__c);
      }
      newAlert.Alert_migrated__c = true;
    }
    Commercial_Alert_Helper.informGroupName(newAlerts);
    Commercial_Alert_Helper.stRecordType(newAlerts);
    Commercial_Alert_Helper.informOwner(newAlerts, null);
    Commercial_Alert_Helper.stCampaignIdOnInsert(newAlerts);
    Commercial_Alert_Helper.addOwner(newAlerts);
    Commercial_Alert_Helper.increaseNumberOfAlerts(newAlerts);
    update newAlerts;
  }

  /*
  * @author David Ivan
  * @Description checkPending
  */
  private static void checkPending(almd__Commercial_Alert__c alert) {
    if(alert.almd__alert_stage_type__c == PENDACTIONS) {
      MAPIDSTATUS.put(alert.almd__commercial_alert_id__c, Label.COMMERCIAL_ALERT_STATUS_PENDING);
    } else if(alert.almd__alert_stage_type__c == 'In progress' && alert.almd__Opportunities__r != null && alert.almd__Opportunities__r.size() <= 0 && alert.almd__Visits__r.size() <= 0) {
      MAPIDSTATUS.put(alert.almd__commercial_alert_id__c, Label.COMMERCIAL_ALERT_STATUS_PENDING);
    } else {
      checkManaged(alert);
    }
  }

  /*
  * @author David Ivan
  * @Description checkManaged
  */
  private static void checkManaged(almd__Commercial_Alert__c alert) {
    if(alert.almd__alert_stage_type__c == 'In progress' && alert.almd__Opportunities__r != null && (alert.almd__Opportunities__r.size() > 0 || alert.almd__Visits__r.size() > 0)) {
      MAPIDSTATUS.put(alert.almd__commercial_alert_id__c, Label.COMMERCIAL_ALERT_STATUS_MANAGED);
    } else if(alert.almd__alert_stage_type__c == Label.DES_CLOSED && alert.almd__alert_sub_stage_type__c == 'Won') {
      MAPIDSTATUS.put(alert.almd__commercial_alert_id__c, Label.COMMERCIAL_ALERT_STATUS_MANAGED);
    } else {
      chkDisableMature(alert);
    }
  }

  /*
  * @author David Ivan
  * @Description chkDisableMature
  */
  private static void chkDisableMature(almd__Commercial_Alert__c alert) {
    if(alert.almd__alert_stage_type__c == Label.DES_CLOSED && alert.almd__alert_sub_stage_type__c == Label.COMMERCIAL_ALERT_STATUS_DISCARDED && alert.almd__Rejection_reason_desc__c != null && alert.almd__Rejection_reason_desc__c.contains('1970')) {
      MAPIDSTATUS.put(alert.almd__commercial_alert_id__c, Label.COMMERCIAL_ALERT_STATUS_DISABLED);
    } else if(chkIfMature(alert)) {
      MAPIDSTATUS.put(alert.almd__commercial_alert_id__c, Label.COMMERCIAL_ALERT_STATUS_MATURED);
      MAPIDCOMMENTS.put(alert.almd__commercial_alert_id__c, alert.almd__Rejection_reason_desc__c);
    } else {
      chkEndDateDisbled(alert);
    }
  }

  /*
  * @author David Ivan
  * @Description chkDisableMature
  */
  private static boolean chkIfMature(almd__Commercial_Alert__c alert) {
    Boolean matured = false;
    if(alert.almd__alert_stage_type__c == Label.DES_CLOSED && alert.almd__alert_sub_stage_type__c == Label.COMMERCIAL_ALERT_STATUS_DISCARDED && alert.almd__Rejection_reason_desc__c != null && alert.almd__Rejection_reason_desc__c.contains('alert was matured') && !alert.almd__Rejection_reason_desc__c.contains('1970')) {
      matured = true;
    }
    return matured;
  }


  /*
  * @author David Ivan
  * @Description chkEndDateDisbled
  */
  private static void chkEndDateDisbled(almd__Commercial_Alert__c alert) {
    if(alert.almd__alert_stage_type__c == Label.DES_CLOSED && alert.almd__alert_sub_stage_type__c == Label.COMMERCIAL_ALERT_STATUS_DISCARDED && alert.almd__commercial_alert_end_date__c == Date.newInstance(1970, 1, 1)) {
      MAPIDSTATUS.put(alert.almd__commercial_alert_id__c, Label.COMMERCIAL_ALERT_STATUS_DISABLED);
      MAPIDCOMMENTS.put(alert.almd__commercial_alert_id__c, alert.almd__Rejection_reason_desc__c);
    } else {
      checkNotAction(alert);
    }
  }

  /*
  * @author David Ivan
  * @Description checkNotAction
  */
  private static void checkNotAction(almd__Commercial_Alert__c alert) {
    if(alert.almd__alert_stage_type__c == Label.DES_CLOSED && alert.almd__alert_sub_stage_type__c == Label.COMMERCIAL_ALERT_STATUS_DISCARDED && alert.almd__BBVA_rejection_reason_desc__c != null && alert.almd__BBVA_rejection_reason_desc__c.contains('Risk')) {
      MAPIDSTATUS.put(alert.almd__commercial_alert_id__c, Label.COMMERCIAL_ALERT_STATUS_DISCARDED);
      MAPIDCOMMENTS.put(alert.almd__commercial_alert_id__c, buildComment(alert.almd__Others_rejection_reason_desc__c, alert.almd__Client_rejection_reason_desc__c));
      MAPIDREASON.put(alert.almd__commercial_alert_id__c, 'No possible action - Risk limitation');
    } else if(alert.almd__alert_stage_type__c == Label.DES_CLOSED && alert.almd__alert_sub_stage_type__c == Label.COMMERCIAL_ALERT_STATUS_DISCARDED && alert.almd__BBVA_rejection_reason_desc__c == 'Pricing') {
      MAPIDSTATUS.put(alert.almd__commercial_alert_id__c, Label.COMMERCIAL_ALERT_STATUS_DISCARDED);
      MAPIDCOMMENTS.put(alert.almd__commercial_alert_id__c, buildComment(alert.almd__Others_rejection_reason_desc__c, alert.almd__Client_rejection_reason_desc__c));
      MAPIDREASON.put(alert.almd__commercial_alert_id__c, 'No possible action - Pricing');
    } else {
      checkOthers(alert);
    }
  }

  /*
  * @author David Ivan
  * @Description checkOthers
  */
  private static void checkOthers(almd__Commercial_Alert__c alert) {
    if(alert.almd__alert_stage_type__c == Label.DES_CLOSED && alert.almd__alert_sub_stage_type__c == Label.COMMERCIAL_ALERT_STATUS_DISCARDED && alert.almd__BBVA_rejection_reason_desc__c == 'Missed Deadline') {
      MAPIDSTATUS.put(alert.almd__commercial_alert_id__c, Label.COMMERCIAL_ALERT_STATUS_DISCARDED);
      MAPIDCOMMENTS.put(alert.almd__commercial_alert_id__c, buildComment(alert.almd__Others_rejection_reason_desc__c, alert.almd__Client_rejection_reason_desc__c));
      MAPIDREASON.put(alert.almd__commercial_alert_id__c, 'Too late / Deal Missed');
    } else if(alert.almd__alert_stage_type__c == Label.DES_CLOSED && alert.almd__alert_sub_stage_type__c == Label.COMMERCIAL_ALERT_STATUS_DISCARDED && (alert.almd__BBVA_rejection_reason_desc__c == 'Client withdrawn' || alert.almd__BBVA_rejection_reason_desc__c == 'N/A')) {
      MAPIDSTATUS.put(alert.almd__commercial_alert_id__c, Label.COMMERCIAL_ALERT_STATUS_DISCARDED);
      MAPIDCOMMENTS.put(alert.almd__commercial_alert_id__c, buildComment(alert.almd__Others_rejection_reason_desc__c, alert.almd__Client_rejection_reason_desc__c));
      MAPIDREASON.put(alert.almd__commercial_alert_id__c, 'Others');
    } else {
      checkDiscarded(alert);
    }
  }

  /*
  * @author David Ivan
  * @Description checkDiscarded
  */
  private static void checkDiscarded(almd__Commercial_Alert__c alert) {
    if(alert.almd__alert_stage_type__c == Label.DES_CLOSED && alert.almd__alert_sub_stage_type__c == Label.COMMERCIAL_ALERT_STATUS_DISCARDED) {
      MAPIDSTATUS.put(alert.almd__commercial_alert_id__c, Label.COMMERCIAL_ALERT_STATUS_DISCARDED);
      MAPIDCOMMENTS.put(alert.almd__commercial_alert_id__c, alert.almd__Rejection_reason_desc__c);
    } else {
      MAPIDSTATUS.put(alert.almd__commercial_alert_id__c, Label.COMMERCIAL_ALERT_STATUS_PENDING);
    }
  }

  /*
  * @author David Ivan
  * @Description buildComment
  */
  private static String buildComment(String others, String deal) {
    return deal != null ? String.format('{0}\r\n{1}',new List<String>{deal, others != null ? others : ''}) : others != null ? others : ''; //NOSONAR
  }

  /*
  * Finish method
  */
  public void finish(Database.BatchableContext bch) {
    final Id batchInstanceId = Database.executeBatch(new Alert_Migration_Opp_Visit(), 2000);
    final AsyncApexJob job = [SELECT Id, Status, NumberOfErrors, JobItemsProcessed, TotalJobItems, CreatedBy.Email FROM AsyncApexJob WHERE Id = :bch.getJobId()];
    System.debug('>>>>> SUMMARY: ');
    System.debug('>>>>>   Batches Created: ' + job.JobItemsProcessed);
    System.debug('>>>>>   Number of Errors: ' + job.NumberOfErrors);
    System.debug('>>>>>   Status: ' + job.Status);
    System.debug('>>>>>   batchInstanceId: ' + batchInstanceId);
  }
}