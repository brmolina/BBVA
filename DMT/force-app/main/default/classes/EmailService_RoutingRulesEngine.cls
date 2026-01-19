/*-------------------------------------------------------------------------------
Author:        Juan Carlos Terrón
Company:       Accenture
Description:   Class EmailService_RoutingRulesEngine

History:
<Author>                  <Date>                <Change Description>
Juan Carlos Terrón                              Initial veesrsion.
---------------------------------------------------------------------------------*/
public with sharing class EmailService_RoutingRulesEngine {
/* Methods Get/Set threadId */
public InboundEmailWrapper email {get;set;}
/* Methods Get/Set rulefields */
public Set<String> rulefields {get;set;}
/* Methods Get/Set list Custom Setting RoutingRules */
public List<EmailServiceRoutingRule__c> applyingrules {get;set;}
/* Methods Get/Set emailvalues */
public Map<String,String> emailvalues {get;set;}
/* Methods Get/Set Map Custom Setting RoutingRules */
public Map<String, Map<String,List<EmailServiceRoutingRule__c>>> rules {get;set;}
/* Methods Get/Set Customo Setting Outbondmailbox */
public Map<String,SER_EmailDefaultValues_Assignment__c> settings {get;set;}
/* Methods Get/Set address */
public String address {get;set;}
/* Methods Get/Set businesstype */
public String businesstype {get;set;}
/*-------------------------------------------------------------------------------
Author:        Juan Carlos Terrón
Company:       Accenture
Description:   Method Emailservice_RoutingRulesEngine
---------------------------------------------------------------------------------*/
public Emailservice_RoutingRulesEngine(InboundEmailWrapper email,String businessType) {
this.businessType = businessType;
this.email = email;
    this.mapSettings();
    this.mapRules();
    this.getApplyingRules();
}
/*-------------------------------------------------------------------------------
Author:        Juan Carlos Terrón
Company:       Accenture
Description:   Method processApplyingRules
---------------------------------------------------------------------------------*/
public String processApplyingRules() {
  //delete duplicates
  
  final EmailService_RoutingRulesUtils emailRoutingUtils = new EmailService_RoutingRulesUtils(email, businessType);
    
  final Map<Id,EmailServiceRoutingRule__c> applyingrules = new Map<Id,EmailServiceRoutingRule__c>(); 
  for(EmailServiceRoutingRule__c rule : this.applyingrules) {
    if(applyingrules.containsKey(rule.id) == false) {
      applyingrules.put(rule.id,rule);
    }
  }
  final List<EmailServiceRoutingRule__c> applyRulWeights = emailRoutingUtils.getApplyingRulesWeights(applyingrules);
  system.debug('MSB - ProcessApplyingRules -  applyRulWeights: ' + applyRulWeights);//NOSONAR
  return emailRoutingUtils.getResultMailbox(applyRulWeights);
}
  
  
  
private void getapplyingRules() {
  final List<EmailServiceRoutingRule__c> applyingrules = new List<EmailServiceRoutingRule__c>();
    System.debug('JCT - getapplyingRules - '+this.rules);//NOSONAR
    System.debug('JCT - getapplyingRules - '+this.rules.keyset());//NOSONAR
    System.debug('JCT - getapplyingRules - '+this.rules.get('subject__c'));//NOSONAR
    System.debug('JCT - getapplyingRules - '+this.rules.get('subject__c').keyset());//NOSONAR
    System.debug('JCT - getapplyingRules - '+this.email.Subject);//NOSONAR
    System.debug('JCT - getapplyingRules - '+this.email.ccAddress);//NOSONAR
    if(this.rules.get('fromaddress__c').containskey(this.email.Sender)) {
        applyingrules.addAll(this.rules.get('fromaddress__c').get(this.email.Sender));
    }
    if(this.rules.get('toaddress__c').containskey(this.email.toAddress)) {
        applyingrules.addAll(this.rules.get('toaddress__c').get(this.email.toAddress));
    }
    if(this.rules.get('ccaddress__c').containskey(this.email.ccAddress)) {
        applyingrules.addAll(this.rules.get('ccaddress__c').get(this.email.ccAddress));
    }
  this.applyingrules = applyingrules;
}
private void mapRules() {
  this.rules = new Map<String, Map<String,List<EmailServiceRoutingRule__c>>>();
  this.rulefields = new Set<String>();
  final Map<String,EmailServiceRoutingRule__c> allrules = EmailServiceRoutingRule__c.getAll();
  final Set<String> rulefieldnames = new Set<String>(EmailServiceRoutingRule__c.sObjectType.getDescribe().fields.getMap().keySet());
  Map<String, Map<String,List<EmailServiceRoutingRule__c>>> rules = new Map<String, Map<String,List<EmailServiceRoutingRule__c>>>();

  final Map<String, Schema.SObjectField> rulefields = Schema.SObjectType.EmailServiceRoutingRule__c.fields.getMap();
  for(String field : rulefields.keyset()) {
    system.debug('rulefieldname : '+field);//NOSONAR
    Schema.DescribeFieldResult dfr = rulefields.get(field).getDescribe();
    if(dfr.isCustom()) {
      system.debug('custom : '+field);//NOSONAR
      //final String name = dfr.getName().substring(0,dfr.getName().length()-3).tolowercase();
      final String name = dfr.getName().tolowercase();
      rulefieldnames.add(name);
    } else {
        rulefieldnames.remove(field);
    }
  }
  for(String rulefieldname : rulefieldnames) {
    rules.put(rulefieldname,new Map<String,List<EmailServiceRoutingRule__c>>());
  }
  for(EmailServiceRoutingRule__c rule : allrules.values()) {
    if(rule.get('businesstype__c') == this.businessType) {
    for(String rulefieldname : rulefieldnames) {
      system.debug('rulefieldname : '+rulefieldname);//NOSONAR
      system.debug('fieldvalue : '+rule.get(rulefieldname));//NOSONAR
      final String fieldvalue = (String) rule.get(rulefieldname);
      final Map<String,List<EmailServiceRoutingRule__c>> valuemap = rules.get(rulefieldname);
      if(valuemap.containskey(fieldvalue)) {
        if(valuemap.get(fieldvalue) == null) {
          valuemap.put(fieldvalue, new List<EmailServiceRoutingRule__c>{rule});
        } else {
          final List<EmailServiceRoutingRule__c> esrs = new List<EmailServiceRoutingRule__c>(valuemap.get(fieldvalue));
          esrs.add(rule);
        }
      } else {
        valuemap.put(fieldvalue, new List<EmailServiceRoutingRule__c>{rule});
      }

    }
  }
  this.rules = rules;
  this.rulefields = rulefieldnames;
  }
}
private void mapSettings() {
  this.settings = new Map<String,SER_EmailDefaultValues_Assignment__c>();
  final Map<String,SER_EmailDefaultValues_Assignment__c> settings = SER_EmailDefaultValues_Assignment__c.getAll();
  for(SER_EmailDefaultValues_Assignment__c setting : settings.values()) {
    this.settings.put(setting.SER_FromAddres__c,setting);
  }
}


}