/**
------------------------------------------------------------------------------------------------
@Name     KPI_Operations_Service
@Author   ivan.garces@bosonit.com
@Date     Created: 2023-01-25
------------------------------------------------------------------------------------------------
@Description Wrapper Class for request operations service
------------------------------------------------------------------------------------------------
*/
@SuppressWarnings('PMD.CyclomaticComplexity, PMD.CognitiveComplexity, sf:TooManyMethods, PMD.ExcessiveParameterList, sf:NPathComplexity, PMD.ApexCRUDViolation, PMD.NcssTypeCount, PMD.EmptyStatementBlock, PMD.NcssMethodCount, PMD.AvoidDeeplyNestedIfStmts, PMD.StdCyclomaticComplexity, PMD.ApexSOQLInjection, PMD.FormalParameterNamingConventions, PMD.ExcessiveClassLength , PMD.ExcessivePublicCount, PMD.AvoidGlobalModifier, PMD.UnusedLocalVariable, PMD.ApexAssertionsShouldIncludeMessage, PMD.IfStmtsMustUseBraces, PMD.IfElseStmtsMustUseBraces')
global class KPI_FinantialCustomers_Wrapper {

    /* @Description: petitionType */
    @AuraEnabled
    public List<Data> data {get;set;}

    /* @Description: petitionType */
    @AuraEnabled
    public Pagination pagination {get;set;}

    /* @Description: success */
    @AuraEnabled
    public Boolean success {get;set;}

    /* @Description: message */
    @AuraEnabled
    public String message {get;set;}

    /**
    * @Description : Class Data
    */
    public class Data {

        /* @Description: code */
        @AuraEnabled
        public String code {get;set;}

        /* @Description: name */
        @AuraEnabled
        public String name {get;set;}

        /* @Description: clientGroup */
        @AuraEnabled
        public ClientGroup clientGroup {get;set;}

        /* @Description: managerId */
        @AuraEnabled
        public String managerId {get;set;}

        /* @Description: country */
        @AuraEnabled
        public Country country {get;set;}

        /* @Description: contracts */
        @AuraEnabled
        public List<Contracts> contracts {get;set;}
    }

    /**
    * @Description : Class Pagination
    */
    public class Pagination {
        /* @Description: Links */
        @AuraEnabled
        public Links links {get;set;}

        /* @Description: page */
        @AuraEnabled
        public Integer page {get;set;}

        /* @Description: totalPage */
        @AuraEnabled
        public Integer totalPage {get;set;}

        /* @Description: totalElements */
        @AuraEnabled
        public Integer totalElements {get;set;}

        /* @Description: pageSize */
        @AuraEnabled
        public Integer pageSize {get;set;}
    }

    /**
    * @Description : Class Contracts
    */
    public class Contracts {
        /* @Description: id */
        @AuraEnabled
        public String id {get;set;}

        /* @Description: codeLocal */
        @AuraEnabled
        public String codeLocal {get;set;}

        /* @Description: nameOriginSystem */
        @AuraEnabled
        public String nameOriginSystem {get;set;}

        /* @Description: entity */
        @AuraEnabled
        public Entity entity {get;set;}

        /* @Description: country */
        @AuraEnabled
        public Country country {get;set;}

        /* @Description: codeOfficeBooking */
        @AuraEnabled
        public String codeOfficeBooking {get;set;}

        /* @Description: initialDate */
        @AuraEnabled
        public String initialDate {get;set;}

        /* @Description: expirationDate */
        @AuraEnabled
        public String expirationDate {get;set;}

        /* @Description: sustainabilityDate */
        @AuraEnabled
        public String sustainabilityDate {get;set;}

        /* @Description: businessArea */
        @AuraEnabled
        public BusinessArea businessArea {get;set;}

        /* @Description: product */
        @AuraEnabled
        public Product product {get;set;}

        /* @Description: validYears */
        @AuraEnabled
        public Integer validYears {get;set;}

        /* @Description: initialMainAmount */
        @AuraEnabled
        public Double initialMainAmount {get;set;}

        /* @Description: productCurrency */
        @AuraEnabled
        public String productCurrency {get;set;}

        /* @Description: sustainabilityFamily */
        @AuraEnabled
        public SustainabilityFamily sustainabilityFamily {get;set;}

        /* @Description: operationIndicatorType */
        @AuraEnabled
        public Boolean operationIndicatorType {get;set;}

        /* @Description: dataValue */
        @AuraEnabled
        public DataValue dataValue {get;set;}

        /* @Description: agencyIndicatorType */
        @AuraEnabled
        public Boolean agencyIndicatorType {get;set;}

        /* @Description: project */
        @AuraEnabled
        public Project project {get;set;}

        /* @Description: codeOfficeBooking */
        @AuraEnabled
        public Tranch tranch {get;set;}

        /* @Description: initialMarginFee */
        @AuraEnabled
        public String initialObligationFee {get;set;}

        /* @Description: initialMarginFee */
        @AuraEnabled
        public String initialMarginFee {get;set;}

        /* @Description: currentMargin */
        @AuraEnabled
        public String currentMargin {get;set;}

        /* @Description: currentFee */
        @AuraEnabled
        public String currentFee {get;set;}
    }

    /**
    * @Description : Class Entity
    */
    public class Entity {
        /* @Description: id */
        @AuraEnabled
        public String id {get;set;}
    }

    /**
    * @Description : Class Product
    */
    public class Product {
        /* @Description: id */
        @AuraEnabled
        public String id {get;set;}

        /* @Description: description */
        @AuraEnabled
        public String description {get;set;}
    }

    /**
    * @Description : Class BusinessArea
    */
    public class BusinessArea{
        /* @Description: id */
        @AuraEnabled
        public String id {get;set;}

        /* @Description: description */
        @AuraEnabled
        public String description {get;set;}
    }

    /*
    * @Description : Class ClientGroup
    */
    public class ClientGroup {
        /* @Description: id */
        @AuraEnabled
        public String id {get;set;}

        /* @Description: description */
        @AuraEnabled
        public String description {get;set;}

        /* @Description: country */
        @AuraEnabled
        public Country country {get;set;}

        /* @Description: sector */
        @AuraEnabled
        public Sector sector {get;set;}

        /* @Description: segment */
        @AuraEnabled
        public Segment segment {get;set;}

        /* @Description: activity */
        @AuraEnabled
        public Activity activity {get;set;}
    }

    /**
    * @Description : Class SustainabilityFamily
    */
    public class SustainabilityFamily {
        /* @Description: id */
        @AuraEnabled
        public String id {get;set;}

        /* @Description: description */
        @AuraEnabled
        public String description {get;set;}

        /* @Description: sustainabilyAgentId */
        @AuraEnabled
        public String sustainabilyAgentId {get;set;}

        /* @Description: sustainableCoordinator */
        @AuraEnabled
        public String sustainableCoordinator {get;set;}

        /* @Description: feeSustainableCoordinator */
        @AuraEnabled
        public Double feeSustainableCoordinator {get;set;}

        /* @Description: SustainabilityCategory */
        @AuraEnabled
        public SustainabilityCategory sustainabilityCategory {get;set;}
    }

    /**
    * @Description : Class SustainabilityFamily
    */
    public class SustainabilityCategory {
        /* @Description: id */
        @AuraEnabled
        public String id {get;set;}

        /* @Description: description */
        @AuraEnabled
        public String description {get;set;}

        /* @Description: SustainabilityCategory */
        @AuraEnabled
        public SubSustainabilityCategory subsustainabilityCategory {get;set;}
    }

    /**
    * @Description : Class SubSustainabilityCategory
    */
    public class SubSustainabilityCategory {
        /* @Description: id */
        @AuraEnabled
        public String id {get;set;}

        /* @Description: description */
        @AuraEnabled
        public String description {get;set;}
    }

    /**
    * @Description : Class Country
    */
    public class Country {
        /* @Description: id */
        @AuraEnabled
        public String id {get;set;}

        /* @Description: id */
        @AuraEnabled
        public String description {get;set;}
    }

    /**
    * @Description : Class Sector
    */
    public class Sector {
        /* @Description: id */
        @AuraEnabled
        public String id {get;set;}

        /* @Description: description */
        @AuraEnabled
        public String description {get;set;}
    }

    /**
    * @Description : Class Activity
    */
    public class Activity {
        /* @Description: id */
        @AuraEnabled
        public String id {get;set;}

        /* @Description: description */
        @AuraEnabled
        public String description {get;set;}
    }

    /**
    * @Description : Class Segment
    */
    public class Segment {
        @AuraEnabled
        /* @Description: id */
        public String id {get;set;}

        /* @Description: description */
        @AuraEnabled
        public String description {get;set;}

        /* @Description: subSegment */
        @AuraEnabled
        public SubSegment subSegment {get;set;}
    }

    /**
    * @Description : Class SubSegment
    */
    public class SubSegment {
        /* @Description: id */
        @AuraEnabled
        public String id {get;set;}

        /* @Description: description */
        @AuraEnabled
        public String description {get;set;}
    }

    /**
    * @Description : Class Tranch
    */
    public class Tranch {
        /* @Description: id */
        @AuraEnabled
        public String id {get;set;}

        /* @Description: description */
        @AuraEnabled
        public String description {get;set;}
    }

    /**
    * @Description : Class Links
    */
    public class Links {
        /* @Description: first */
        @AuraEnabled
        public String first {get;set;}

        /* @Description: last */
        @AuraEnabled
        public String last {get;set;}

        /* @Description: previous */
        @AuraEnabled
        public String previous {get;set;}

        /* @Description: next */
        @AuraEnabled
        public String next {get;set;}
    }

    /**
    * @Description : Class DataValue
    */
    public class DataValue {
        /* @Description: variation */
        @AuraEnabled
        public Double variation {get;set;}

        /* @Description: value */
        @AuraEnabled
        public Double value {get;set;}
    }

    /**
    * @Description : Class Project
    */
    public class Project {
        /* @Description: id */
        @AuraEnabled
        public String id {get;set;}
    }
}