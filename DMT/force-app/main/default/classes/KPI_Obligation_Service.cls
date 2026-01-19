/**
* ------------------------------------------------------------------------------------------------
* @Name     KPI_Obligation_Service
* @Author   ivan.garces.contractor@bbva.com
* @Date     Created: 2023-02-15
* ------------------------------------------------------------------------------------------------
* @Description Controller class for KPI_search component
* ------------------------------------------------------------------------------------------------
* @Changes
*
* |2023-02-15 ivan.garces.contractor@bbva.com
*             Class Creation
* -----------------------------------------------------------------------------------------------
*/
@SuppressWarnings('sf:AvoidFinalLocalVariable, sf:LogicInversion, sf:DUDataflowAnomalyAnalysis, sf:NcssMethodCount, sf:NPathComplexity, sf:CyclomaticComplexity, sf:TooManyMethods')
public with sharing class KPI_Obligation_Service {
     /**
     * @Description : Wrapper of petition
    */
    public class Data {
        /**
        * @Description: petitionType
        */
        public List<Response> data {get;set;}
        /**
        * @Description: Empty Constructor
        **/
        public Data() {}
        /**
        * @Description: Constructor
        **/
        public Data(List<Response> data) {
            this.data = data;
        }
    }

     /**
    * @Description : Wrapper of response
    */
    public class Response {

        /**
        * @Description: id_y
        */

        public String id_y {get;set;}
        /**
        * @Description: description
        */

        public String description {get;set;}
        /**
        * @Description: obligationType
        */
        public ObligationType obligationType {get;set;}

        /**
        * @Description: sustainableSubcategory
        */
        public SustainableSubcategory sustainableSubcategory {get;set;}
        /**
        * @Description: sustainableAgent
        */
        public SustainableAgent sustainableAgent {get;set;}

        /**
        * @Description: sustainableCoordinator
        */
        public Boolean sustainableCoordinator {get;set;}

        /**
        * @Description: feeSustainableCoordinator
        */
        public Double feeSustainableCoordinator {get;set;}
        /**
        * @Description: actions
        */
        public List<Actions> actions {get;set;}


        /**
        * @Description: Empty Constructor
        **/
        public Response() {}

        /**
        * @Description: Constructor
        **/
        public Response(String id_y, String description, ObligationType obligationType, SustainableSubcategory sustainableSubcategory , 
        Boolean sustainableCoordinator, Double feeSustainableCoordinator, List<Actions> actions) {
        this.id_y = id_y;
        this.description = description;
        this.obligationType = obligationType;
        this.sustainableSubcategory = sustainableSubcategory;
        this.sustainableCoordinator = sustainableCoordinator;
        this.feeSustainableCoordinator = feeSustainableCoordinator;
        this.actions = actions;
        }
    }
    /** 
    * @Description : Wrapper of ObligationType
    */
    public class ObligationType {
        /**
        * @Description: id_y
        */
        public String id_y {get;set;}

        /**
        * @Description: Constructor
        **/
        public ObligationType(String id_y) {
            this.id_y = id_y;
        }

    }
    /** 
    * @Description : Wrapper of ContractKPI
    */
    public class ContractKPI{
        /**
        * @Description: id_y
        */
        public String id_y {get;set;}
        /**
        * @Description: Constructor
        **/
        public ContractKPI(String id_y) {
            this.id_y = id_y;
        }
    }
    /** 
    * @Description : Wrapper of SustainableSubcategory
    */
    public class SustainableSubcategory{
        /**
         *  @Description: id_y
         */
        public String id_y {get;set;}
        /**
         * @Description: Constructor
         */
        public SustainableSubcategory(String id_y) {
            this.id_y = id_y;
        }
    }
    /** 
    * @Description : Wrapper of SustainableAgent
    */
    public class SustainableAgent{
        /**
         * @Description:id_y
         */
        public String id_y {get;set;}
        /**
         * @Description: Constructor
         */
        public SustainableAgent(String id_y) {
            this.id_y = id_y;
        }
    }
    /** 
    * @Description : Wrapper of Actions
    */
    public class Actions{
        /**
         *  @Description: id_y
         */
        public String id_y {get;set;}
        /**
         *  @Description: name
         */
        public String name {get;set;}
        /**
         *  @Description: triggers
         */
        public Triggers triggers {get;set;}
        /**
         *  @Description: constructor
         */
        public Actions (String id_y , String name ,Triggers triggers ){
            this.id_y = id_y;
            this.name = name;
            this.triggers = triggers;
        }
    }

    /** 
    * @Description : Wrapper of Triggers
    */
    public class Triggers{
        /** 
        * @Description : id_y
        */
        public String id_y {get;set;}
        /** 
        * @Description : name
        */
        public String name {get;set;}
        /** 
        * @Description : obligationRevierWorkflowId
        */
        public String obligationRevierWorkflowId {get;set;}
        /** 
        * @Description : scale
        */
        public Scale scale {get;set;}
        /** 
        * @Description : reviews
        */
        public List<Reviews> reviews {get;set;}
        /** 
        * @Description : constructor
        */
        public Triggers(String id_y, String name, String obligationRevierWorkflowId, Scale scale, List<Reviews> reviews){
            this.id_y = id_y;
            this.name = name;
            this.obligationRevierWorkflowId = obligationRevierWorkflowId;
            this.scale = scale;
            this.reviews = reviews;
        }
        
    }
    
    /** 
    * @Description : Wrapper of Scale
    */
    public class Scale{
        /** 
        * @Description : id_y
        */
        public String id_y{get;set;}
        /** 
        * @Description : effectiveStarDate
        */
        public Date effectiveStarDate{get;set;}
        /** 
        * @Description : effectiveEndDate
        */
        public Date effectiveEndDate{get;set;}
        /** 
        * @Description : criteriaIdMaximum
        */
        public String criteriaIdMaximum{get;set;}
        /** 
        * @Description : criteriaValueMaximum
        */
        public Double criteriaValueMaximum{get;set;}
        /** 
        * @Description : criteriaIdMinimum
        */
        public String criteriaIdMinimum{get;set;}
        /** 
        * @Description : criteriaValueMinimum
        */
        public Double criteriaValueMinimum{get;set;}
        /** 
        * @Description : rate
        */
        public String rate{get;set;}
        /** 
        * @Description : sortOrder
        */
        public Double sortOrder{get;set;}
        /** 
        * @Description : rating
        */
        public Rating rating{get;set;}
        /** 
        * @Description : Constructo
        */
        public Scale(String id_y, Date effectiveStarDate,  Date effectiveEndDate, String criteriaIdMaximum,
        Double criteriaValueMaximum, String criteriaIdMinimum, Double criteriaValueMinimum, String rate, Double sortOrder, Rating rating){
           this.id_y = id_y ;
           this.effectiveStarDate = effectiveStarDate ;
           this.effectiveEndDate = effectiveEndDate ;
           this.criteriaIdMaximum = criteriaIdMaximum ;
           this.criteriaValueMaximum = criteriaValueMaximum ;
           this.criteriaIdMinimum = criteriaIdMinimum ;
           this.criteriaValueMinimum = criteriaValueMinimum ;
           this.rate = rate ;
           this.sortOrder = sortOrder ;
           this.rating = rating ;
        }
    }
    /** 
    * @Description : Wrapper of Rating
    */
    public class Rating{
        /** 
        * @Description : id_y
        */
        public String id_y{get;set;}
        /** 
        * @Description : name
        */
        public String name{get;set;}
        /** 
        * @Description : ratingIdMaximum
        */
        public String ratingIdMaximum{get;set;}
        /** 
        * @Description : ratingNameMaximum
        */
        public String ratingNameMaximum{get;set;}
        /** 
        * @Description : ratingValueMaximum
        */
        public Double ratingValueMaximum{get;set;}
        /** 
        * @Description : ratingIdMinimum
        */
        public String ratingIdMinimum{get;set;}
        /** 
        * @Description : ratingNameMinimum
        */
        public String ratingNameMinimum{get;set;}
        /** 
        * @Description : ratingValueMinimum
        */
        public Double ratingValueMinimum{get;set;}
        /** 
        * @Description : Constructor
        */
        public Rating(String id_y, String name, String ratingIdMaximum, String ratingNameMaximum, Double ratingValueMaximum, String ratingIdMinimum,
        String ratingNameMinimum, Double ratingValueMinimum){
            this.id_y = id_y;
            this.name = name;
            this.ratingIdMaximum = ratingIdMaximum;
            this.ratingNameMaximum = ratingNameMaximum;
            this.ratingValueMaximum = ratingValueMaximum;
            this.ratingIdMinimum = ratingIdMinimum;
            this.ratingNameMinimum = ratingNameMinimum;
            this.ratingValueMinimum = ratingValueMinimum;
        }
    }
    /** 
    * @Description : Wrapper of Reviews
    */
    public class Reviews{
        /** 
        * @Description : id_y
        */
        public String id_y{get;set;}
        /** 
        * @Description : obligationReview
        */
        public ObligationReview obligationReview{get;set;}
        /** 
        * @Description : idCriteria
        */
        public String idCriteria{get;set;}
        /** 
        * @Description : alertClasificationDescription
        */
        public String alertClasificationDescription{get;set;}
        /** 
        * @Description : alertMinimumTrigger
        */
        public Double alertMinimumTrigger{get;set;}
        /** 
        * @Description : idAction
        */
        public String idAction{get;set;}
        /** 
        * @Description : AlertTriggerObligation
        */
        public String alertTriggerObligation{get;set;}
        /** 
        * @Description : alertTriggerOutputFormatDescription
        */
        public String alertTriggerOutputFormatDescription{get;set;}
        /** 
        * @Description : alertTriggerOutputFormatNumber
        */
        public Double alertTriggerOutputFormatNumber{get;set;}
        /** 
        * @Description : alertObligationDate
        */
        public Date alertObligationDate{get;set;}
        /** 
        * @Description : alertCovenant
        */
        public AlertCovenant alertCovenant{get;set;}
        /** 
        * @Description : Constructor
        */
        public Reviews(String id_y, ObligationReview obligationReview, String idCriteria, String alertClasificationDescription, Double alertMinimumTrigger, 
        String idAction, String alertTriggerObligation, String alertTriggerOutputFormatDescription, Double alertTriggerOutputFormatNumber, 
        Date alertObligationDate, AlertCovenant alertCovenant){
            this.id_y = id_y;
            this.obligationReview = obligationReview;
            this.idCriteria = idCriteria;
            this.alertClasificationDescription = alertClasificationDescription;
            this.alertMinimumTrigger = alertMinimumTrigger;
            this.idAction = idAction;
            this.alertTriggerObligation = alertTriggerObligation;
            this.alertTriggerOutputFormatDescription = alertTriggerOutputFormatDescription;
            this.alertTriggerOutputFormatNumber = alertTriggerOutputFormatNumber;
            this.alertObligationDate = alertObligationDate;
            this.alertCovenant = alertCovenant;
        }
    }
    /** 
    * @Description : Wrapper of ObligationReview
    */
    public class ObligationReview{
        /** 
        * @Description : name
        */
        public String name{get;set;}
        /** 
        * @Description : date
        */
        public Date date_y{get;set;}
        /** 
        * @Description : classificationDescription
        */
        public String classificationDescription{get;set;}
        /** 
        * @Description : workflowId
        */
        public String workflowId{get;set;}
        /** 
        * @Description : receptionStatusDescription
        */
        public String receptionStatusDescription{get;set;}
        /** 
        * @Description : complianceStatusDescription
        */
        public String complianceStatusDescription{get;set;}
        /** 
        * @Description : covenant
        */
        public Covenant covenant{get;set;}
        /** 
        * @Description : constructor
        */
        public ObligationReview(String name, Date date_y, String classificationDescription, String workflowId, String receptionStatusDescription,
        String complianceStatusDescription, Covenant covenant){
            this.name = name;
            this.date_y = date_y;
            this.classificationDescription = classificationDescription;
            this.workflowId = workflowId;
            this.receptionStatusDescription = receptionStatusDescription;
            this.complianceStatusDescription = complianceStatusDescription;
            this.covenant = covenant;
        }
    }
    /**
     * @Description : Wrapper of Covenant
     */
    public class Covenant{
        /**
        * @Description : amount
        */
        public Double amount {get;set;}
        /**
        * @Description : currency
        */
        public String currency_y {get;set;}
        /**
        * @Description : constructor
        */
        public Covenant(Double amount, String currency_y ){
            this.amount= amount;
            this.currency_y = currency_y;
        }
    }
    /**
     * @Description : Wrapper of AlertCovenant
     */
    public class AlertCovenant{
        /**
        * @Description : amount
        */
        public Double amount {get;set;}
        /**
        * @Description : currency
        */
        public String currency_y {get;set;}
        /**
        * @Description : constructor
        */
        public AlertCovenant(Double amount, String currency_y ){
            this.amount= amount;
            this.currency_y = currency_y;
        }
    }
}