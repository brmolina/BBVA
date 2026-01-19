/*-------------------------------------------------------------------------------------------------------------------------------------------------------
    Author:        Javier SS
    Company:       Accenture
    Description:   Class controller para las ActivityCustom

    History:
    <Date>          <Author>                <Description>
    14/11/2017    JSS            Se comenta todo el codigo porque ya no es necesario
--------------------------------------------------------------------------------------------------------------------------------------------------------*/
public with sharing class CustomActivityController {
  
/*    
  public Boolean isLeadOrContact {get; set;}
  
    public static final String FIELD_ACCOUNT = 'Account__c';
    public static final String FIELD_LEAD = 'Lead__c';
    public static final String FIELD_CONTACT = 'Contact__c';
    
    private static Boolean isReady = false;
    
    public String record;
    public String field;
    public String recordAcc;
    
    public Integer moreClosedActivities;
    public Integer moreOpenActivities;
    
    
    // Lista de contactos de la cuenta, si el registro se trata de una cuenta
    public List<Contact> contacts {get; set;}
    
    // Lista de oportunidades de la cuenta, si el registro se trata de una cuenta
    public List<Opportunity> oppys {get; set;}
    
    public String getRecord() { return record; }
    public String getField() { return field; }
    public String getRecordAcc() { return recordAcc; }
    
    
    
    public void setRecord(String record) { 
        this.record = record;
        //system.debug('+++record: ' + record);
        if (record!=null){
            //system.debug('+++Recordisnotnull');
            init();
        }
    }
    
    public void setField(String field) {
        this.field = field;
        init();
    }
    
    public void setRecordAcc(String acc) {
        this.recordAcc = (String.isBlank(acc) ? '' : acc);
        init();
    }    
    
    private List<Task> openTasks;
    private List<Task> closedTasks;
    private List<Event> openEvents;
    private List<Event> closedEvents;
    
    public List<ActivityWrapper> openActivities {get; set;}
    public List<ActivityWrapper> activityHistory {get; set;}
    
    public CustomActivityController() {
        system.debug(LoggingLevel.DEBUG, '*** entrando a CustomActivityController');
        openTasks = new List<Task>();
        openEvents = new List<Event>();
        closedTasks = new List<Task>();
        closedEvents = new List<Event>();
    }
    
    public Integer getMoreOpenActivities() {
        
        try{
            String query = 'Select Count(Id) total From Task Where Status != \'Completed\' And WhatId In ';
            query += '(Select Id From Activity__c Where ' + field + ' = \'' + record + '\'';
            
            if (field == FIELD_ACCOUNT)
                query += ' Or Contact__c In :contacts Or Opportunity__c In :oppys ';
            
            query += ')';
            
            Integer c = (Integer) Database.query(query)[0].get('total');
            
            query = 'Select Count(Id) total From Event Where ActivityDate >= TODAY And WhatId In ';
            query += '(Select Id From Activity__c Where ' + field + ' = \'' + record + '\'';
            
            if (field == FIELD_ACCOUNT)
                query += ' Or Contact__c In :contacts Or Opportunity__c In :oppys ';
            
            query += ')';
            
            c += (Integer) Database.query(query)[0].get('total');
            
            system.debug(LoggingLevel.DEBUG, '*** return method getMoreOpenActivities: ' + c);
            
            return c;
        }catch (exception ex){
            if (record == null){
                System.debug('Error: ' + ex.getMessage());
                ApexPages.addmessage(new ApexPages.message(ApexPages.severity.Error, Label.CustomActivitiesNoRecords));
                return 0;
            }else{
                ApexPages.addmessage(new ApexPages.message(ApexPages.severity.Error, ex.getMessage()));
                return 0;
            }
        }
        
        
        
    }
    
    public Integer getMoreClosedActivities() {
        try{
            String query = 'Select Count(Id) total From Task Where Status = \'Completed\' And Call_Category__c != \'Discard\' And WhatId In ';
            query += '(Select Id From Activity__c Where ' + field + ' = \'' + record + '\'';
            
            if (field == FIELD_ACCOUNT)
                query += ' Or Contact__c In :contacts Or Opportunity__c In :oppys ';
            
            query += ')';
            
            Integer c = (Integer) Database.query(query)[0].get('total');
            
            query = 'Select Count(Id) total From Event Where ActivityDate < TODAY And WhatId In ';
            query += '(Select Id From Activity__c Where ' + field + ' = \'' + record + '\'';
            
            if (field == FIELD_ACCOUNT)
                query += ' Or Contact__c In :contacts Or Opportunity__c In :oppys ';
            
            query += ')';
            
            c += (Integer) Database.query(query)[0].get('total');
            
            system.debug(LoggingLevel.DEBUG, '*** return method getMoreClosedActivities: ' + c);        
            return c;
        }catch (exception ex){
            if (record==null){
                System.debug('Error: ' + ex.getMessage());
                ApexPages.addmessage(new ApexPages.message(ApexPages.severity.Error, Label.CustomActivitiesNoRecords));
                return 0;
            }else{
                ApexPages.addmessage(new ApexPages.message(ApexPages.severity.Error, ex.getMessage()));
                return 0;
            }
        }
        
    }
    
    public String buildQuery(String table, Boolean open) {
        try{
            String query = '';
            
            query += 'Select Id, Subject, OwnerId, Owner.Name, ActivityDate, What.Name ';
            
            if (table == 'Task')
                query += ', Status, Priority ';
            
            query += 'From ' + table + ' ';
            query += 'Where WhatId In (';
            query += 'Select Id ';
            query += 'From Activity__c ';
            query += 'Where ' + field + ' = \'' + record + '\'';
            
            if (field == FIELD_ACCOUNT)
                query += ' Or Contact__c In :contacts Or Opportunity__c In :oppys ';
            
            query += ')';
            
            if (open) {
                if (table == 'Task') {
                    query += 'And Status != \'Completed\' ';
                } else {
                    query += 'And ActivityDate >= TODAY ';
                }
            } else {
                if (table == 'Task') {
                    query += 'And Status = \'Completed\' And Call_Category__c != \'Discard\' ';
                } else {
                    query += 'And ActivityDate < TODAY ';
                }
            }
            
            query += 'Order By ActivityDate Desc ';
            query += 'Limit 5';
            
            system.debug(LoggingLevel.DEBUG, '*** return method buildQuery: ' + query); 
            return query;
        }catch (exception ex){
            if (record == null){
                System.debug('Error: ' + ex.getMessage());
                ApexPages.addmessage(new ApexPages.message(ApexPages.severity.Error, Label.CustomActivitiesNoRecords));
                return null;
            }else{
                ApexPages.addmessage(new ApexPages.message(ApexPages.severity.Error, ex.getMessage()));
                return null;
            }
        }
    }
    
    public void init() {
        if (Record !=null){
            if (isReady)
                onInit();
            else
                isReady = true;
        }
    }
    
    public void onInit() {
        try{
            if (field == FIELD_ACCOUNT) {
                contacts = [Select Id From Contact Where AccountId = :record];
                oppys = [Select Id From Opportunity Where AccountId = :record];
            }
            
            openTasks = Database.query(buildQuery('Task', true));
            openEvents = Database.query(buildQuery('Event', true));
            closedTasks = Database.query(buildQuery('Task', false));
            closedEvents = Database.query(buildQuery('Event', false));
            
            List<ActivityWrapper> oActivities = new List<ActivityWrapper>();
            List<ActivityWrapper> cActivities = new List<ActivityWrapper>();
            
            for (Task t: openTasks)
                oActivities.add(new ActivityWrapper(t));
            
            for (Event e: openEvents)
                oActivities.add(new ActivityWrapper(e));
            
            for (Task t: closedTasks)
                cActivities.add(new ActivityWrapper(t));
            
            for (Event e: closedEvents)
                cActivities.add(new ActivityWrapper(e));
            
            oActivities.sort();
            cActivities.sort();
            
            openActivities = new List<ActivityWrapper>();
            activityHistory = new List<ActivityWrapper>();
            
            Integer i = 0;
            while (openActivities.size() < 5 && i < oActivities.size()) {
                openActivities.add(oActivities[i]);
                i++;
            }
            
            i = 0;
            while (activityHistory.size() < 5 && i < cActivities.size()) {
                activityHistory.add(cActivities[i]);
                i++;
            }
            
            isLeadOrContact = (field == FIELD_CONTACT) || (field == FIELD_LEAD);
        }catch (exception ex){
            if (record == null){
                System.debug('Error: ' + ex.getMessage());
                ApexPages.addmessage(new ApexPages.message(ApexPages.severity.Error,Label.CustomActivitiesNoRecords));
            }else{
                ApexPages.addmessage(new ApexPages.message(ApexPages.severity.Error, ex.getMessage()));
            }
        }
    }
    
    public class ActivityWrapper implements Comparable {
        
        
        public SObject obj {get; set;}
        
        public ActivityWrapper(SObject obj) {
            this.obj = obj; 
        }
        
        private Object getField(String field) {
            if (obj instanceof Task)
                return ((Task) obj).get(field);
            
            if (obj instanceof Event)
                return ((Event) obj).get(field);
            
            return null;
        }
        
        public String getSubject() {
            return (String) getField('Subject');
        }
        
        public String getId() {
            return (String) getField('Id');
        }
        
        public String getOwnerName() {
            return String.valueOf(obj.getSObject('Owner').get('Name'));
        }
        
        public Date getActivityDate() {
            return (Date) getField('ActivityDate');
        }
        
        public String getWhatidName() {
            return String.valueOf(obj.getSObject('What').get('Name'));
        }        
        
        public Integer compareTo(Object obj) {
            try{
                ActivityWrapper aw = (ActivityWrapper) obj;
                
                Integer result;
                
                Date d1 = aw.getActivityDate();
                Date d2 = this.getActivityDate();
                
                if (d1 > d2)
                    result = 1;
                else if (d2 > d1)
                    result = -1;
                else
                    result = 0;
                
                return result;
            }catch (exception ex){
                System.debug('Error: ' + ex.getMessage());
                ApexPages.addmessage(new ApexPages.message(ApexPages.severity.Error, ex.getMessage()));
                return null;
            }
        }
        
    }
*/    
}