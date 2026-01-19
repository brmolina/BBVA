@JsonAccess(serializable='always' deserializable='always')
public with sharing class DMT_PasppportMin_Wrapper 
{
    public class Request 
    {
        @AuraEnabled
        public String opportunityId;
        @AuraEnabled
        public String status;
        @AuraEnabled
        public List<Product> products;
    }

    public class Product 
    {
        @AuraEnabled
        public String groupPriorityLineId;
        @AuraEnabled
        public Decimal amount;
        @AuraEnabled
        public String currencyId;
        @AuraEnabled
        public List<ParentConsum> parentConsums {get;set;}
    }

    public class ParentConsum
    {
        @AuraEnabled
        public String productParent;
        @AuraEnabled
        public String parentId;
        @AuraEnabled
        public Decimal amount;
        @AuraEnabled
        public String currencyId;
        @AuraEnabled
        public Date endDateParent;
    }
}