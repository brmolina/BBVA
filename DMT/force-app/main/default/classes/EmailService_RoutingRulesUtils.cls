/*-------------------------------------------------------------------------------
Author:        Miriam Simon
Company:       UST
Description:   Class EmailService_RoutingRulesUtils

History:
<Author>                  <Date>                <Change Description>
Miriam Simon               07/12/2021           Aditional Version of EmailService_RoutingRuleEngine
---------------------------------------------------------------------------------*/
public with sharing class EmailService_RoutingRulesUtils {
    /* Methods Get/Set threadId */
    public InboundEmailWrapper email {get;set;}
    /* Methods Get/Set businesstype */
    public String businesstype {get;set;}
    /* Constant Size*/
    public static final Integer SIZEONE = 1;
    /*-------------------------------------------------------------------------------
  Author:        Miriam Simon
  Company:       UST
  Description:   Method EmailService_RoutingRulesUtils
  ---------------------------------------------------------------------------------*/
    public EmailService_RoutingRulesUtils(InboundEmailWrapper email,String businessType) {
        this.businessType = businessType;
        this.email = email;
    }
    /*-------------------------------------------------------------------------------
  Author:        Miriam Simon
  Company:       UST
  Description:   Method getApplyingRulesWeights
  ---------------------------------------------------------------------------------*/
    public List<EmailServiceRoutingRule__c> getApplyingRulesWeights(Map<Id,EmailServiceRoutingRule__c> applyingrules) {
        final List<EmailServiceRoutingRule__c> applyRulWeights = new List<EmailServiceRoutingRule__c>();
        Integer maxweight = 0; //NOSONAR
        Boolean biggerOrEqualWeight = false; //NOSONAR 
        Integer weight;
        for(EmailServiceRoutingRule__c rule : applyingrules.values()) {
            weight = this.getWeight(rule);
            biggerOrEqualWeight = weight > 0 && weight >= maxweight;
            if(biggerOrEqualWeight) {
                if(weight > maxweight) {
                    applyRulWeights.clear();
                }
                applyRulWeights.add(rule);
                maxweight = weight;
            }
        }
        return applyRulWeights;
    }
    /*-------------------------------------------------------------------------------
  Author:        Miriam Simon
  Company:       UST
  Description:   Method getResultMailbox
  ---------------------------------------------------------------------------------*/
    public String getResultMailbox(List<EmailServiceRoutingRule__c> applyRulWeights) {
        String result;
        if(applyRulWeights.size() == SIZEONE) {
            final EmailServiceRoutingRule__c chosenrule = applyRulWeights.get(0);
            if(this.ruleapplies(chosenrule)) {
                result = chosenrule.Mailbox__c;
            }
        }
        return result;
    }
    
    private Boolean matchsubject(String ruleSubject) {
        Boolean result;
        if (String.isNotBlank(ruleSubject)) {
            if(this.email.subject.contains(ruleSubject)) {
                result = true;
            } else {
                result = false;
            }
        } else if(String.isblank(ruleSubject)) {
            result = true;
        } else {
            result = false;
        }
        return result;
    }
    
    
    private Boolean matchFromAddress(String sender) {
        return this.email.email.FromAddress.equalsIgnoreCase(sender);
    }
    private Boolean matchtoAddress(String toAddress) {
        Boolean result;
        final Set<String> emailaddresses = new Set<String>(this.email.addresses.get('to'));
        final Set<String> ruleaddresses = new Set<String>();
        if(String.isNotBlank(toAddress) && toAddress.contains(';')) { //the string is not null and contains the split key
            for(String word : toAddress.split(';')) { //We add every splitted string to the returned list.
                ruleaddresses.add(word.trim().toLowerCase());
            }
        } else if (String.isNotBlank(toAddress)) { //The string si not null but does not contains the split key
            ruleaddresses.add(toAddress);
        }
        if(ruleaddresses.isEmpty() == false) {
            if(emailaddresses.containsAll(ruleaddresses)) {
                result = true;
            } else {
                result = false;
            }
        } else {
            if(toAddress != null && emailaddresses.isEmpty()) {
                result = true;
            } else {
                result = false;
            }
        }
        return result;
    }
    private Boolean matchccAddress(String ccAddress) {
        Boolean result;
        final Set<String> emailaddresses = new Set<String>(this.email.addresses.get('cc'));
        final Set<String> ruleaddresses = new Set<String>();
        if(String.isNotBlank(ccAddress) && ccAddress.contains(';')) { //the string is not null and contains the split key
            for(String word : ccAddress.split(';')) { //We add every splitted string to the returned list.
                ruleaddresses.add(word.trim().toLowerCase());
            }
        } else if(String.isNotBlank(ccAddress)) { //The string si not null but does not contains the split key
            ruleaddresses.add(ccAddress);
        }
        if(ruleaddresses.isEmpty() == false) {
            if(emailaddresses.containsAll(ruleaddresses)) {
                result = true;
            } else {
                result = false;
            }
        } else {
            if(ccAddress != null && emailaddresses.isEmpty()) {
                result = true;
            } else {
                result = false;
            }
        }
        return result;
    }
    private Boolean ruleapplies(EmailServiceRoutingRule__c rule) {
        Boolean result;
        final Boolean noMatchAddress = String.isnotblank(rule.FromAddress__c) && this.matchFromAddress(rule.FromAddress__c) == false;
        final Boolean noMatchSubject = String.isnotblank(rule.Subject__c) && this.matchsubject(rule.Subject__c) == false;
        final Boolean noMatchToAddress = String.isnotblank(rule.toAddress__c) && this.matchtoAddress(rule.toAddress__c) == false;
        final Boolean noMatchccAddress = String.isnotblank(rule.ccAddress__c) && this.matchccAddress(rule.ccAddress__c) == false;
        system.debug('MSB - ruleapplies - noMatchAddress: ' + noMatchAddress);//NOSONAR
        system.debug('MSB - ruleapplies - noMatchSubject: ' + noMatchSubject);//NOSONAR
        system.debug('MSB - ruleapplies - noMatchToAddress: ' + noMatchToAddress);//NOSONAR
        system.debug('MSB - ruleapplies - noMatchccAddress: ' + noMatchccAddress);//NOSONAR
        if(noMatchAddress) {
            result = false;
        } else if (noMatchSubject) {
            result = false;
        } else if(noMatchToAddress) {
            result = false;
        } else if(noMatchccAddress) {
            result = false;
        } else {
            result = true;
        }
        return result;
    }
    private Integer getWeight(EmailServiceRoutingRule__c rule) {
        Integer weight;
        weight = 0;
        final String ruleSubject = rule.Subject__c;
        final String ruleSender = rule.FromAddress__c;
        final String ruleToAdd = rule.toAddress__c;
        final String ruleCcAdd = rule.ccAddress__c;
        if (this.matchsubject(ruleSubject)) {
            weight += 3;
        }
        if(this.matchFromAddress(ruleSender)) {
            weight += 2;
        }
        if(this.matchtoAddress(ruleToAdd)) {
            weight += 1;
        }
        if(this.matchccAddress(ruleCcAdd)) {
            weight += 1;
        }
        return weight;
    }
}