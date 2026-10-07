@JsonAccess(serializable='always' deserializable='always')
public with sharing virtual class DMT_Wrapper_Passport_Abs
{
    public virtual class Request
    {
        @AuraEnabled
        public String opportunityId;
        @AuraEnabled
        public String version;
        @AuraEnabled
        public Datetime auditDate;
        @AuraEnabled
        public String entific;
        @AuraEnabled
        public String booking;
        @AuraEnabled
        public String branch;
        @AuraEnabled
        public String lineDesc;
        @AuraEnabled
        public String user;
        @AuraEnabled
        public String status;
        @AuraEnabled
        public Date initDate;
        @AuraEnabled
        public Date endDate;
        @AuraEnabled
        public String currencyId;
        @AuraEnabled
        public String body;
    }

    // --- NEW: Inner class for CoreDocs Taxonomy payloads ---
    public virtual class DocumentLoad 
    {
        @AuraEnabled
        public String itemType;
    }

    public virtual class RequestBody
    {
        @AuraEnabled
        public Client client;
        @AuraEnabled
        public Analyst analysts;
        @AuraEnabled
        public List<Feature> features;
        @AuraEnabled
        public List<OptionalFeatures> optionalFeatures;
        @AuraEnabled
        public String templateType;
        @AuraEnabled
        public List<DocumentLoad> documentsloads; // Populated globally across all inherited wrappers
    }

    public virtual class Client
    {
        @AuraEnabled
        public String customerId;
        @AuraEnabled
        public String customerName;
        @AuraEnabled
        public String groupId;
        @AuraEnabled
        public String groupName;
        @AuraEnabled
        public String subgroupId;
        @AuraEnabled
        public String subgroupName;
        @AuraEnabled
        public String supragroupId;
        @AuraEnabled
        public String supragroupName;
        @AuraEnabled
        public String taxpayer;
        @AuraEnabled
        public String country;
        @AuraEnabled
        public String residentCountry;
        @AuraEnabled
        public String taxCountry;
        @AuraEnabled
        public String shortRating;
        @AuraEnabled
        public String longRating;
        @AuraEnabled
        public String customAssociationId;
        @AuraEnabled
        public String customAssociationName;
        @AuraEnabled
        public String clientType;
        @AuraEnabled
        public String sectorTypeId;
        @AuraEnabled
        public String sectorTypeDesc;
        @AuraEnabled
        public String subsectorTypeId;
        @AuraEnabled
        public String subsectorTypeDesc;
        @AuraEnabled
        public String activityTypeId;
        @AuraEnabled
        public String activityTypeDesc;
        @AuraEnabled
        public String camnId;
        @AuraEnabled
        public String camnDesc;
        @AuraEnabled
        public Boolean pureplayer;
        @AuraEnabled
        public List<Aggregation> aggregations;
        @AuraEnabled
        public Boolean extension;
        @AuraEnabled
        public String thresholdType;
        @AuraEnabled
        public String camn;
        @AuraEnabled
        public String industry;
        @AuraEnabled
        public String leveragedlending;
        @AuraEnabled
        public Decimal scoring;
        @AuraEnabled
        public String moodysExternalRating;
        @AuraEnabled
        public String spExternalRating;
        @AuraEnabled
        public String fitchExternalRating;
        @AuraEnabled
        public String sectorHead;
        @AuraEnabled
        public String guarantorNameFiscalId;
    }

    public virtual class Aggregation
    {
        @AuraEnabled
        public String level;
        @AuraEnabled
        public String id;
    }

    public virtual class Product
    {

        @AuraEnabled
        public Date initDate;
        @AuraEnabled
        public Date endDate;
        @AuraEnabled
        public Decimal amount;
        @AuraEnabled
        public String currencyId;
    }

    public virtual class Feature
    {
        @AuraEnabled
        public String id;
        @AuraEnabled
        public String name;
        @AuraEnabled
        public String passportSanction;
        @AuraEnabled
        public String active;
        @AuraEnabled
        public String motorDesc;
        @AuraEnabled
        public String stateName;
        @AuraEnabled
        public String requiredAtStatus; // Dynamic Stage Blocker
        @AuraEnabled
        public List<FeatureGenConsiderations> validations;
    }

    public virtual class OptionalFeatures
    {
        @AuraEnabled
        public String id;
    }

    public virtual class FeatureGenConsiderations
    {
        @AuraEnabled
        public String state;
        @AuraEnabled
        public String name;
        @AuraEnabled
        public String message;
    }

    public virtual class ParentConsum
    {
        @AuraEnabled
        public String productParent;
        @AuraEnabled
        public String parentId;
        @AuraEnabled
        public Decimal amountParent;
        @AuraEnabled
        public String currencyParentId;
        @AuraEnabled
        public Date endDateParent;
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