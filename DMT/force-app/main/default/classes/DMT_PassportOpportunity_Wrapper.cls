@JsonAccess(serializable='always' deserializable='always')
public with sharing class DMT_PassportOpportunity_Wrapper extends DMT_Wrapper_Passport_Abs
{
    public class Request extends DMT_Wrapper_Passport_Abs.Request
    {

        @AuraEnabled
        public String geographyBranch;
        @AuraEnabled
        public String entity;
    }

    public class RequestBody extends DMT_Wrapper_Passport_Abs.RequestBody
    {

        @AuraEnabled
        public Opportunity opportunity;
        @AuraEnabled
        public Analyst analysts {get;set;}
        @AuraEnabled
        public List<Product> products;

    }


    public class Opportunity{
        @AuraEnabled
        public String counterpart;
        @AuraEnabled
        public Boolean avc;
        @AuraEnabled
        public Boolean europeanBank;
        @AuraEnabled
        public String clientRating;
        @AuraEnabled
        public String externalClientRating;
        @AuraEnabled
        public String scra;
        @AuraEnabled
        public String currencyId;
        @AuraEnabled
        public Decimal clientBDI;
        @AuraEnabled
        public Decimal clientRWA;
        @AuraEnabled
        public Decimal xsellCostToIncome;
        @AuraEnabled
        public String clientSector;
        @AuraEnabled
        public Decimal groupSales;
        @AuraEnabled
        public String thresholdGroupType;
        @AuraEnabled
        public List<Xsells> xsells {get;set;}
        @AuraEnabled
        public List<OpportunitySanctions> opportunitySanctions;
        @AuraEnabled
        public String underwriting;
        @AuraEnabled
        public Decimal opportunityAmount;
        @AuraEnabled
        public Decimal opportunityAmountEUR;
        @AuraEnabled
        public Date businessApprovedDate;
        @AuraEnabled
        public String tenor;
        @AuraEnabled
        public String productArea;
        @AuraEnabled
        public String capitalAction;
        @AuraEnabled
        public String contingentCommitments;
        @AuraEnabled
        public Boolean confidential;
        @AuraEnabled
        public Decimal opportunityAmountDealTotal;
    }

    public class Xsells{
        @AuraEnabled
        public Integer year;
        @AuraEnabled
        public Decimal amount;
        @AuraEnabled
        public String currencyId;
    }

    public class Product extends DMT_Wrapper_Passport_Abs.Product
    {
        @AuraEnabled
        public String name;
        @AuraEnabled
        public String geographyBranch;
        @AuraEnabled
        public String productId;
        @AuraEnabled
        public String businessArea;
        @AuraEnabled
        public String prco;
        @AuraEnabled
        public Date intermediateDate;
        @AuraEnabled
        public String countryRisk;
        @AuraEnabled
        public String groupCountryRisk;
        @AuraEnabled
        public Decimal dealAmount;
        @AuraEnabled
        public Decimal liquidityFee;
        @AuraEnabled
        public String crr2;
        @AuraEnabled
        public String lastLevelId;
        @AuraEnabled
        public String useOfProceeds;
        @AuraEnabled
        public String TXTComentarios;
        @AuraEnabled
        public String countryRating;
        @AuraEnabled
        public List<Mitigant> mitigants {get;set;}
        @AuraEnabled
        public Funding funding {get;set;}
        @AuraEnabled
        public Amortization amortization {get;set;}
        @AuraEnabled
        public Decimal tenorAmount {get;set;}
        @AuraEnabled
        public String committedLine {get;set;}
    }

    public class Mitigant
    {
        @AuraEnabled
        public Boolean avc;
        @AuraEnabled
        public Boolean europeanBank;
        @AuraEnabled
        public String mitigantId;
        @AuraEnabled
        public String mitigantType;
        @AuraEnabled
        public String mitigantCounterpart;
        @AuraEnabled
        public String mitigantRating;
        @AuraEnabled
        public String ratingExternal;
        @AuraEnabled
        public String mitigantScra;
        @AuraEnabled
        public String mitigantLiquidationPeriod;
        @AuraEnabled
        public Date mitigantEndDate;
        @AuraEnabled
        public String mitigantCurrency;
        @AuraEnabled
        public Decimal commercialRisk;
        @AuraEnabled
        public Decimal politicalRisk;
        @AuraEnabled
        public Boolean eca;
        @AuraEnabled
        public String customerId {get;set;} //CIBGLOBALD-2027
        @AuraEnabled
        public String groupId {get;set;} //CIBGLOBALD-2027
        @AuraEnabled
        public String subgroupId {get;set;} //CIBGLOBALD-2027
        @AuraEnabled
        public String supragroupId {get;set;} //CIBGLOBALD-2027
        @AuraEnabled
        public String mitigantCountry;
        @AuraEnabled
        public Decimal scoring;
        
    }

    public class Funding
    {
        @AuraEnabled
        public String fundingType;
        @AuraEnabled
        public String fundingTerm;
        @AuraEnabled
        public Decimal dbFunding;
        @AuraEnabled
        public Decimal fbFunding;
        @AuraEnabled
        public Boolean greenBond;
        @AuraEnabled
        public Boolean socialBond;
        @AuraEnabled
        public String sustainableDeal;
        @AuraEnabled
        public String sustainableDealSubcategory;
        @AuraEnabled
        public String sustainableDealLabel;
        @AuraEnabled
        public String sustainableDelegatedFilter;
        @AuraEnabled
        public Decimal sustainabilityPercentage;
        @AuraEnabled
        public String sustainabilityBonus;
    }

    public class Amortization
    {
        @AuraEnabled
        public String amortizationType;
        @AuraEnabled
        public String paymentFrequency;
        @AuraEnabled
        public Decimal feesPeriodic;
        @AuraEnabled
        public List<AmortizationPayments> payments;
        @AuraEnabled
        public String rateType;
        @AuraEnabled
        public Decimal newmoney;
        @AuraEnabled
        public Decimal oldmoney;
        @AuraEnabled
        public Decimal finaltake;
        @AuraEnabled
        public String pricinggridOrstepUp;
        @AuraEnabled
        public Decimal extensionDurationFees;
        @AuraEnabled
        public Decimal expectedDrawn;
        @AuraEnabled
        public Boolean bullet;
        @AuraEnabled
        public Boolean balloon;
    }

    public class AmortizationPayments
    {
        @AuraEnabled
        public String financeType;
        @AuraEnabled
        public Date paymentDate;
        @AuraEnabled
        public Decimal nominalAmount;
        @AuraEnabled
        public Decimal nominalFb;
        @AuraEnabled
        public Decimal spreadAmount;
        @AuraEnabled
        public Decimal spreadFbAmount;
        @AuraEnabled
        public Decimal feesUpfront;
        @AuraEnabled
        public Decimal feesOther;
    }

    public class OpportunitySanctions
    {
        @AuraEnabled
        public String lineCode;
        @AuraEnabled
        public List<ProductsLine> productsLine;
        @AuraEnabled
        public Date businessApprovedDateStartDate;
        @AuraEnabled
        public Date businessApprovedDateEndDate;
        @AuraEnabled
        public Date riskStartDate;
        @AuraEnabled
        public Date riskEndDate;
        @AuraEnabled
        public Boolean newApproval;
    }

    public class ProductsLine {
        @AuraEnabled
        public String productApproval;
        @AuraEnabled
        public String productOpportunity;
        @AuraEnabled
        public String productId;
    }

        public virtual class Analyst
    {
        @AuraEnabled
        public String approverBankerId;
        @AuraEnabled
        public String businessUnitRiskAnalyst;
        @AuraEnabled
        public String fpRiskAnalyst;
    }
}