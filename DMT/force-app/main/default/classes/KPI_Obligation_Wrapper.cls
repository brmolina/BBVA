/**
@Name     KPI_Obligation_Wrapper
@Author   ivan.garces@bosonit.com
@Date     Created: 2023-01-25
------------------------------------------------------------------------------------------------
@Description Wrapper Class for request operations service
------------------------------------------------------------------------------------------------
*/
@SuppressWarnings('PMD.CyclomaticComplexity, PMD.CognitiveComplexity, sf:TooManyMethods, PMD.ExcessiveParameterList, sf:NPathComplexity, PMD.ApexCRUDViolation, PMD.NcssTypeCount, PMD.EmptyStatementBlock, PMD.NcssMethodCount, PMD.AvoidDeeplyNestedIfStmts, PMD.StdCyclomaticComplexity, PMD.ApexSOQLInjection, PMD.FormalParameterNamingConventions, PMD.ExcessiveClassLength , PMD.ExcessivePublicCount, PMD.AvoidGlobalModifier, PMD.UnusedLocalVariable, PMD.ApexAssertionsShouldIncludeMessage, PMD.IfStmtsMustUseBraces, PMD.IfElseStmtsMustUseBraces')
public with sharing class KPI_Obligation_Wrapper {

    /**Description: petitionType*/
    @AuraEnabled
    public List<Data> data {get;set;}

    /* @Description: success */
    @AuraEnabled
    public Boolean success {get;set;}

    /* @Description: message */
    @AuraEnabled
    public String message {get;set;}

    /** @Description: CLass Data */
    public class Data {
        /* @Description: id */
        @AuraEnabled
        public String id {get;set;}

        /* @Description: description */
        @AuraEnabled
        public String description {get;set;}

        /* @Description: obligationType */
        @AuraEnabled
        public ObligationType obligationType {get;set;}

        /* @Description: contract */
        @AuraEnabled
        public Contract contract {get;set;}

        /* @Description: sustainableSubcategory */
        @AuraEnabled
        public SustainableSubcategory sustainableSubcategory {get;set;}

        /* @Description: sustainableAgent*/
        @AuraEnabled
        public SustainableAgent sustainableAgent {get;set;}

        /* @Description: sustainableCoordinator */
        @AuraEnabled
        public Boolean sustainableCoordinator {get;set;}

        /* @Description: feeSustainableCoordinator */
        @AuraEnabled
        public Double feeSustainableCoordinator {get;set;}

        /* @Description: actions*/
        @AuraEnabled
        public List<Actions> actions {get;set;}

        /* @Description: triggerCompliant */
        @AuraEnabled
        public String triggerCompliant{get;set;}

        /* @Description: baselineTarget */
        @AuraEnabled
        public Double baselineTarget{get;set;}
        /* @Description: baselineTarget */
        @AuraEnabled
        public String baselineYear {get;set;}
        /* @Description: marginDiscount */
        @AuraEnabled
        public Double marginDiscount{get;set;}

        /* @Description: extendedDescription */
        @AuraEnabled
        public String extendedDescription{get;set;}

    }

    /**
    * @Description: Class ObligationType
    */
    public class ObligationType {
        /* @Description: id */
        @AuraEnabled
        public String id {get;set;}
    }

    /**
    * @Description: Class ContractKPI
    */
    public class Contract {
        /* @Description: id */
        @AuraEnabled
        public String id {get;set;}
    }

    /**
    * @Description: Class SustainableSubcategory
    */
    public class SustainableSubcategory {
        /* @Description: id */
        @AuraEnabled
        public String id {get;set;}
    }

    /**
    * @Description: Class SustainableAgent
    */
    public class SustainableAgent {
        /* @Description: id */
        @AuraEnabled
        public String id {get;set;}
    }

    /**
    * @Description: Class Actions
    */
    public class Actions {
        /* @Description: id */
        @AuraEnabled
        public String id {get;set;}

        /* @Description: name*/
        @AuraEnabled
        public String name {get;set;}

        /* @Description: triggers*/
        @AuraEnabled
        public List<Triggers> triggers {get;set;}
    }

    /**
    *  @Description: Class Trigger
    */
    public class Triggers {

        /* @Description: id */
        @AuraEnabled
        public String id {get;set;}

        /* @Description: name*/
        @AuraEnabled
        public String name {get;set;}

        /* @Description: obligationRevierWorkflowId*/
        @AuraEnabled
        public String obligationReviewWorkflowId {get;set;}

        /* @Description: scale*/
        @AuraEnabled
        public Scale scale {get;set;}

        /* @Description: reviews*/
        @AuraEnabled
        public List<Review> reviews {get;set;}
    }

    /**
    * @Description: Class Scale
    */
    public class Scale {

        /* @Description: id */
        @AuraEnabled
        public String id {get;set;}

        /* @Description: effectiveStarDate*/
        @AuraEnabled
        public Date effectiveStartDate {get;set;}

        /* @Description: effectiveEndDate*/
        @AuraEnabled
        public Date effectiveEndDate {get;set;}

        /* @Description: criteriaIdMaximum*/
        @AuraEnabled
        public String criteriaIdMaximum {get;set;}

        /* @Description: criteriaValueMaximum*/
        @AuraEnabled
        public Double criteriaValueMaximum {get;set;}

        /* @Description: criteriaIdMinimum*/
        @AuraEnabled
        public String criteriaIdMinimum {get;set;}

        /* @Description: criteriaValueMinimum*/
        @AuraEnabled
        public Double criteriaValueMinimum {get;set;}

        /* @Description: rate*/
        @AuraEnabled
        public String rate {get;set;}

        /* @Description: sortOrder*/
        @AuraEnabled
        public Integer sortOrder {get;set;}

        /* @Description: rating*/
        @AuraEnabled
        public Rating rating {get;set;}
    }

    /**
    * @Description: Class Rating
    */
    public class Rating {
        /* @Description: id */
        @AuraEnabled
        public String id {get;set;}

        /* @Description: name */
        @AuraEnabled
        public String name {get;set;}

        /* @Description: ratingIdMaximum */
        @AuraEnabled
        public String ratingIdMaximum {get;set;}

        /* @Description: ratingNameMaximum */
        @AuraEnabled
        public String ratingNameMaximum {get;set;}

        /* @Description: ratingValueMaximum */
        @AuraEnabled
        public Double ratingValueMaximum {get;set;}

        /* @Description: ratingIdMinimum */
        @AuraEnabled
        public String ratingIdMinimum {get;set;}

        /* @Description: ratingNameMinimum */
        @AuraEnabled
        public String ratingNameMinimum {get;set;}

        /* @Description: ratingValueMinimum */
        @AuraEnabled
        public Double ratingValueMinimum {get;set;}
    }

    /**
    * @Description: Class Reviews
    */
    public class Review {
        /* @Description: id */
        @AuraEnabled
        public String id {get;set;}

        /* @Description: obligationReview */
        @AuraEnabled
        public ObligationReview obligationReview {get;set;}

        /* @Description: idCriteria */
        @AuraEnabled
        public String idCriteria {get;set;}

        /* @Description: alertClasificationDescription */
        @AuraEnabled
        public String alertClasificationDescription {get;set;}

        /* @Description: alertMinimumTrigger */
        @AuraEnabled
        public Double alertMinimumTrigger {get;set;}

        /* @Description: idAction */
        @AuraEnabled
        public String idAction {get;set;}

        /* @Description: AlertTriggerObligation */
        @AuraEnabled
        public String alertTriggerObligation {get;set;}

        /* @Description: alertTriggerOutputFormatDescription */
        @AuraEnabled
        public String alertTriggerOutputFormatDescription {get;set;}

        /* @Description: alertTriggerOutputFormatNumber */
        @AuraEnabled
        public Double alertTriggerOutputFormatNumber {get;set;}

        /* @Description: alertObligationDate */
        @AuraEnabled
        public Date alertObligationDate {get;set;}

        /* @Description: alertCovenant */
        @AuraEnabled
        public AlertCovenant alertCovenant {get;set;}

        /* @Description: receptionDate */
        @AuraEnabled
        public Date receptionDate {get;set;}

        /* @Description: obligationDate */
        @AuraEnabled
        public Date obligationDate {get;set;}

        /* @Description: alertId */
        @AuraEnabled
        public String alertId {get;set;}
    }

    /**
    * @Description: Class ObligationReview
    */
    public class ObligationReview {

        /* @Description: name */
        @AuraEnabled
        public String name {get;set;}

        /* @Description: date */
        @AuraEnabled
        public Date obligationDate {get;set;}

        /* @Description: classificationDescription */
        @AuraEnabled
        public String classificationDescription {get;set;}

        /* @Description: workflowId */
        @AuraEnabled
        public String workflowId {get;set;}

        /* @Description: receptionStatusDescription */
        @AuraEnabled
        public String receptionStatusDescription {get;set;}

        /* @Description: complianceStatusDescription */
        @AuraEnabled
        public String complianceStatusDescription {get;set;}

        /* @Description: covenant */
        @AuraEnabled
        public Covenant covenant {get;set;}
    }

    /**
    * @Description: Class Covenant
    */
    public class Covenant {
        /* @Description: amount */
        @AuraEnabled
        public Double amount {get;set;}

        /* @Description: currency */
        @AuraEnabled
        public String curr {get;set;}
    }

    /**
    * @Description: Class AlertCovenant
    */
    public class AlertCovenant {
        /* @Description: amount*/
        @AuraEnabled
        public Double amount {get;set;}

        /* @Description: currency*/
        @AuraEnabled
        public String curr {get;set;}
    }

    /**
    * @Description: Class request
    */
    public class Request {
        /**Description: petitionType*/
        @AuraEnabled
        public List<Data> obligations {get;set;}
    }
}