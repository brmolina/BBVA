public without sharing class SER_MassiveWarning_CTRL {
  public String buttonColor {get; set;}
  public List<Case> list_CaseView {get; set;}
  public Map<Id,Case> map_CaseView {get; set;}
  public SER_MassiveWarning_CTRL()
  {
    this.buttonColor = Label.SER_MasterCasesAlerts_ButtonColor;
    this.list_CaseView = new List<Case>();
    this.map_CaseView = new Map<Id,Case>();
    this.refreshView();
  }

  public PageReference refreshView()
  {
    String plv_Closed = Label.SER_CaseStatus_Closed_PLV;
    this.buttonColor = Label.SER_MasterCasesAlerts_ButtonColor;
    this.map_CaseView = new Map<Id,Case>(
      [
        SELECT Id,Status, CaseNumber, Subject, SER_Product__c
        FROM Case
        WHERE   (SER_Is_Master_Case__c = true
                                          AND Status != : plv_Closed)
        OR
          (SER_Is_Master_Case__c = true
                                    AND Status = : plv_Closed
                                                AND ClosedDate > : Date.TODAY()-1)
        ORDER BY LastModifiedDate DESC]);
    this.list_CaseView = new List<Case>(map_CaseView.values());
    return null;
  }
}