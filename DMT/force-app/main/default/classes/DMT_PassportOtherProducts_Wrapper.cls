@JsonAccess(serializable='always' deserializable='always')
public with sharing class DMT_PassportOtherProducts_Wrapper extends DMT_Wrapper_Passport_Abs
{
    public class RequestBody extends DMT_Wrapper_Passport_Abs.RequestBody
    {
        @AuraEnabled
        public Line line;
        @AuraEnabled
        public List<Product> products;
    }
  
    public class Product extends DMT_Wrapper_Passport_Abs.Product 
    {
        @AuraEnabled
        public String productName;
        @AuraEnabled
        public String family;
        @AuraEnabled
        public String subfamily;
        @AuraEnabled
        public String category;
        @AuraEnabled
        public String subcategory;
        @AuraEnabled
        public String productCode;
        @AuraEnabled
        public List<Provisions> currencyProvision;
        @AuraEnabled
        public List<Warranty> warranty;
        @AuraEnabled
        public String lastLevelId;
        @AuraEnabled
        public String productId;
        @AuraEnabled
        public String globalProductId;
        @AuraEnabled
        public String globalProductSubcategoryId;
        @AuraEnabled
        public String globalProductCategoryId;
        @AuraEnabled
        public String globalProductSubfamilyId;
        @AuraEnabled
        public String globalProductFamilyId;
        @AuraEnabled
        public String bulletIndicatorType;
        @AuraEnabled
        public String minimumInternalRatingLimitation;
        @AuraEnabled
        public String initTerm;
        @AuraEnabled
        public String endTerm;
        @AuraEnabled
        public String assetAllocationSectLimit;
        @AuraEnabled
        public String assetAllocationSubSectLimit;
        @AuraEnabled
        public String branchLimitation;
        @AuraEnabled
        public Decimal monthsGracePeriod;
        @AuraEnabled
        public Decimal loanValuePerct;
        @AuraEnabled
        public Boolean notaryFormIndType;
        @AuraEnabled
        public Boolean publicAdmIndType;
        @AuraEnabled
        public Decimal loanEcaContribPerct;
        @AuraEnabled
        public Decimal minRaroEcFgPerct;
        @AuraEnabled
        public Decimal minRaroEcWoFgPerct;
        @AuraEnabled
        public Decimal minRorcFcgPerct;
        @AuraEnabled
        public Decimal minRorWocFcgPerc;
        @AuraEnabled
        public Decimal revolvencePdDaysNumber;
        @AuraEnabled
        public Boolean multiOperationIndType;
        @AuraEnabled
        public String comments;
        @AuraEnabled
        public Boolean indRenovada;
        @AuraEnabled
        public List<ParentConsum> parentConsums;
    }

    public class Provisions
    {
        @AuraEnabled
        public String currencyId;
    }

    public class Warranty
    {
        @AuraEnabled
        public String warrantyId;
    }

    public class Line
    {
        @AuraEnabled
        public Decimal amount;
        @AuraEnabled
        public String lastLevelId;
        @AuraEnabled
        public Decimal minRaroEcWoFgPerct;
        @AuraEnabled
        public Decimal minRorWocFcgPerc;
    }

}