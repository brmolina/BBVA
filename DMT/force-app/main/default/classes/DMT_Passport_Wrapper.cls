@JsonAccess(serializable='always' deserializable='always')
public with sharing class DMT_Passport_Wrapper extends DMT_Wrapper_Passport_Abs
{
    public class RequestBody extends DMT_Wrapper_Passport_Abs.RequestBody
    {
        @AuraEnabled
        public Client client;
        @AuraEnabled
        public Boolean guaranteeInd;
    }

    public class Client extends DMT_Wrapper_Passport_Abs.Client
    {
        @AuraEnabled
        public List<Product> products;
        @AuraEnabled
        public Boolean indRenovada;
        @AuraEnabled
        public List<ParentConsum> parentConsums;
    }

    public class Product extends DMT_Wrapper_Passport_Abs.Product 
    {
        @AuraEnabled
        public String applicationId;
        @AuraEnabled
        public String lineSource;
        @AuraEnabled
        public Settlement settlement;
        @AuraEnabled
        public Treasury treasury;
    }

    public class Settlement 
    {
        @AuraEnabled
        public Decimal dvpAmount;
        @AuraEnabled
        public Decimal fdAmount;
    }

    public class Treasury 
    {
        @AuraEnabled
        public Decimal reposLimit;
        @AuraEnabled
        public Decimal reposLimitM;
        @AuraEnabled
        public String breakClauseDate;
        @AuraEnabled
        public Decimal breakClauseNumber;
        @AuraEnabled
        public String waiver;
        @AuraEnabled
        public Decimal deposInitTerms;
        @AuraEnabled
        public Decimal deposEndTerms;
        @AuraEnabled
        public Decimal deposAmount;
        @AuraEnabled
        public Decimal equitiesInitTerm;
        @AuraEnabled
        public Decimal equitiesEndTerm;
        @AuraEnabled
        public Decimal equitiesAmount;
        @AuraEnabled
        public Decimal derivativesInitTerm;
        @AuraEnabled
        public Decimal derivativesEndTerm;
        @AuraEnabled
        public Decimal derivativesAmount;
        @AuraEnabled
        public String derivativesRestProductType;
        @AuraEnabled
        public String derivativesRestMaxTenorWOClearing;
        @AuraEnabled
        public String derivativesRestMaxTenorWClearing;
        @AuraEnabled
        public String approvalOperation;
        @AuraEnabled
        public String approvalProposalRarRorc;
        @AuraEnabled
        public String approvalNominal;
        @AuraEnabled
        public String approvalComments;
        @AuraEnabled
        public String approvalFranchise;
    }

}