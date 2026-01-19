/*-------------------------------------------------------------------------------------------------------------------------------------------------------
    Author:        Javier SS
    Company:       Accenture
    Description:   Class controller para las ActivityCustom

    History:
    <Date>          <Author>                <Description>
    14/11/2017    JSS            Se comenta todo el codigo porque ya no es necesario
--------------------------------------------------------------------------------------------------------------------------------------------------------*/
public with sharing class ActivityListController {

/*    
    public final static String FIELD_ACCOUNT = 'Account__c';
    
    public Id recordId {get; set;}
    public Boolean showOpenActivities {get; set;}
    public String title {get; set;}
    
    public String field {get; set;}
    public String record {get; set;}
    public Boolean closed {get; set;}
    public String recordName {get; set;}
    
    public List<ActivityWrapper> activityList {get; set;}
    public List<Task> tasks {get; set;}
    public List<Event> events {get; set;}
    
    // Listas de contactos y de oportunidades asociados con la cuenta, si se está mostrando la lista
    // de actividades de una cuenta
    public List<Contact> contacts {get; set;}
    public List<Opportunity> oppys {get; set;}
    
    public ActivityListController() {
        activityList = new List<ActivityWrapper>();
        
        Map<String, String> params = ApexPages.currentPage().getParameters();
        record = params.get('id');
        field = params.get('field');
        closed = Boolean.valueOf(params.get('closed'));
        
        getRecordName();
        
        if (field == FIELD_ACCOUNT) {
            contacts = [Select Id From Contact Where AccountId = :record];
            oppys = [Select Id From Opportunity Where AccountId = :record];
        }
        
        tasks = Database.query(buildQuery('Task'));
        events = Database.query(buildQuery('Event'));
        
        for (Task t: tasks)
            activityList.add(new ActivityWrapper(t));
            
        for (Event e: events)
            activityList.add(new ActivityWrapper(e));
            
        activityList.sort();
    }
    @TestVisible
    private String buildQuery(String table) {
        String query = '';
        
        query += 'Select Id, Subject, OwnerId, Owner.Name, ActivityDate ';
        
        if (table == 'Task')
            query += ', Status, Priority ';
        
        query += 'From ' + table + ' ';
        query += 'Where WhatId In (';
            query += 'Select Id ';
            query += 'From Activity__c ';
            query += 'Where ' + field + ' = \'' + record + '\'';
            
            if (field == FIELD_ACCOUNT)
                query += ' Or Contact__c In :contacts Or Opportunity__c In :oppys ';
        query += ') ';
        
        if (closed) {
            if (table == 'Task')
                query += 'And Status = \'Completed\' And Call_Category__c != \'Discard\' ';
            if (table == 'Event')
                query += 'And ActivityDate < TODAY ';
        } else {
            if (table == 'Task')
                query += 'And Status != \'Completed\' ';
            if (table == 'Event')
                query += 'And ActivityDate >= TODAY ';
        }
        
        query += 'Order By ActivityDate Desc';
        
        return query;
    }
    @TestVisible
    private void getRecordName() {
        String table = field.substring(0, field.length() - 3);
        
        String query = 'Select Id, Name From ' + table + ' Where Id = \'' + record + '\'';
        
        List<SObject> results = Database.query(query);
        
        recordName = (String) results[0].get('Name');
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
        
        public String getStatus() {
            if (obj instanceof Task)
                return (String) getField('Status');
            
            return '';
        }
        
        public String getPriority() {
            if (obj instanceof Task)
                return (String) getField('Priority');
            
            return '';
        }
        
        public String getChecked() {
            if (obj instanceof Task)
                return '<img src=\'/img/checkbox_checked.gif\' alt=\'Checked\' width=\'21\' height=\'16\' class=\'checkImg\' title=\'Checked\'/>';
            
            return '<img src=\'/img/checkbox_unchecked.gif\' alt=\'Not Checked\' width=\'21\' height=\'16\' class=\'checkImg\' title=\'Not Checked\'>';
        }
        
        public Integer compareTo(Object obj) {
            ActivityWrapper aw = (ActivityWrapper) obj;
            
            Integer result;
            
            Date d1 = aw.getActivityDate();
            Date d2 = this.getActivityDate();
            System.debug('d1: '+d1+'    '+d2);
            
            if (d1 > d2)
                result = 1;
            else if (d2 > d1)
                result = -1;
            else
                result = 0;
            
            return result;
        }
    }
*/    
}