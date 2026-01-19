/**
* @File Name          : Arc_gen_Sales_Wrappers.cls
* @Description        : Class wrappers to the sales service
* @Author             : isabel.ascaso.tech@bbva.com
* @Group              : ARCE Team
* @Last Modified By   : isabel.ascaso.tech@bbva.com
* @Last Modified On   : 26/03/2024
* @Changes
*========================================================================================
* Ver         Date   Author                                           Modification
*========================================================================================
* 1.0    26/03/2024  isabel.ascaso.tech@bbva.com     Initial Version
**/
public class Arc_gen_Sales_Wrappers {
    /**
    * -----------------------------------------------------------------------------------------------
    * @description Wrapper storing the service sales response
    * -----------------------------------------------------------------------------------------------
    * @param void
    * @example Arc_gen_Sales_Wrappers.EngineSalesResponseWrapper wrapper = new Arc_gen_Sales_Wrappers.EngineSalesResponseWrapper()
    * -----------------------------------------------------------------------------------------------
    **/
    public class EngineSalesResponseWrapper {
        /**
        * @description List of sales
        */
        public DataWrapper data;
        /**
        * @description List of response of message
        */
        public List<MessageWrapper> messages;

    }

    /**
    * -----------------------------------------------------------------------------------------------
    * @description Wrapper storing the service meesage
    * -----------------------------------------------------------------------------------------------
    * @param void
    * @example Arc_gen_Sales_Wrappers.MessageWrapper wrapper = new Arc_gen_Sales_Wrappers.MessageWrapper()
    * -----------------------------------------------------------------------------------------------
    **/
    public class MessageWrapper {
        /**
        * @description type of response of service
        */
        public String type;
        /**
        * @description parameter of the sales
        */
        public List<ParameterWrapper> parameters;
        /**
        * @description Message of the response service
        */
        public String message;
        /**
        * @description Code of service
        */
        public String code;

    }

    /**
    * -----------------------------------------------------------------------------------------------
    * @description Wrapper storing the service meesage
    * -----------------------------------------------------------------------------------------------
    * @param void
    * @example Arc_gen_Sales_Wrappers.MessageWrapper wrapper = new Arc_gen_Sales_Wrappers.MessageWrapper()
    * -----------------------------------------------------------------------------------------------
    **/
    public class ParameterWrapper {
        /**
        * @description neme of the parameter
        */
        public String name;
    }

    /**
    * -----------------------------------------------------------------------------------------------
    * @description Wrapper of data response
    * -----------------------------------------------------------------------------------------------
    * @param void
    * @example Arc_gen_Sales_Wrappers.ResponseWrapper wrapper = new Arc_gen_Sales_Wrappers.ResponseWrapper()
    * -----------------------------------------------------------------------------------------------
    **/
    public class DataWrapper {
        /**
        * @description List of response of message
        */
        public List<MessageWrapper> messages;
        /**
        * @description Calculation result of sales engine.
        */
        public boolean calculationResult;
        /**
        * @description Identifier of country. Based on ISO 3166-2.
        */
        public String country;
        /**
        * @description String based on ISO-4217 for specifying the currency.
        */
        public String currencyX;
        /**
        * @description Unit of the system of separation of prices and measures in which the amounts of the financial statement are expressed.
        */
        public String unit;
        /**
        * @description Information about the model chosen to calculate the rating.
        */
        public ModelWrapper model;
        /**
        * @description Rating type.
        */
        public RatingTypeWrapper ratingType;
        /**
        * @description Parent subsidiary relationship.
        */
        public RelationParentSubsidiaryWrapper parentSubsidiary;
        /**
        * @description Entity type.
        */
        public EntityTypeWrapper entityType;
        /**
        * @description Bank from which the assessment is created.
        */
        public BankWrapper bank;
        /**
        * @description System of segmentation of legal persons
        */
        public String riskSegment;
        /**
        * @description Code that allows distinguishing different types of segments.
        */
        public String riskSubsegment;
        /**
        * @description List of sales
        */
        public List<SalesWrapper> sales;
        /**
        * @description List of variables
        */
        public List<VariableWrapper> variables;
        /**
        * @description List of sales
        */
        public ExchangeWrapper exchangeRate;
    }

    /**
    * -----------------------------------------------------------------------------------------------
    * @description Wrapper storing the SalesWrapper service response
    * -----------------------------------------------------------------------------------------------
    * @param void
    * @example Arc_gen_Sales_Wrappers.ResponseWrapper wrapper = new Arc_gen_Sales_Wrappers.ResponseWrapper()
    * -----------------------------------------------------------------------------------------------
    **/
    public class SalesWrapper {
        /**
        * @description String with number of sale
        */
        public Decimal sales;
        /**
        * @description Year of the ffss
        */
        public String year;
        /**
        * @description currency of the ffss
        */
        public String currencyX;
        /**
        * @description Unit of the ffss
        */
        public String unit;
        /**
        * @description financialStatement wrapper class
        */
        public FinancialWrapper finStatement;
        /**
        * @description financialStatement wrapper class
        */
        public ExchangeWrapper exchangeRate;
        /**
        * @description Indicates if the sales correspond to the Anchor.
        */
        public Boolean isAnchor;
    }

    /**
    * -----------------------------------------------------------------------------------------------
    * @description Wrapper storing the FinancialWrapper service response
    * -----------------------------------------------------------------------------------------------
    * @param void
    * @example Arc_gen_Sales_Wrappers.ResponseWrapper wrapper = new Arc_gen_Sales_Wrappers.ResponseWrapper()
    * -----------------------------------------------------------------------------------------------
    **/
    public class FinancialWrapper {
        /**
        * @description Id
        */
        public String idLong;
        /**
        * @description Balance indicator.
        */
        public Boolean adjustedIndicator;
        /**
        * @description It contains financial statement information.
        */
        public FinancialStatementTypeWrapper finStatType;
    }

    /**
    * -----------------------------------------------------------------------------------------------
    * @description Wrapper storing the FinancialStatementTypeWrapper service response
    * -----------------------------------------------------------------------------------------------
    * @param void
    * @example Arc_gen_Sales_Wrappers.FinancialStatementTypeWrapper wrapper = new Arc_gen_Sales_Wrappers.FinancialStatementTypeWrapper()
    * -----------------------------------------------------------------------------------------------
    **/
    public class FinancialStatementTypeWrapper {
        /**
        * @description Id
        */
        public String idLong;
    }

    /**
    * -----------------------------------------------------------------------------------------------
    * @description Wrapper storing the EntityTypeWrapper service response
    * -----------------------------------------------------------------------------------------------
    * @param void
    * @example Arc_gen_Sales_Wrappers.EntityTypeWrapper wrapper = new Arc_gen_Sales_Wrappers.EntityTypeWrapper()
    * -----------------------------------------------------------------------------------------------
    **/
    public class EntityTypeWrapper {
        /**
        * @description Id
        */
        public String idLong;
    }

    /**
    * -----------------------------------------------------------------------------------------------
    * @description Wrapper storing the ModelWrapper service response
    * -----------------------------------------------------------------------------------------------
    * @param void
    * @example Arc_gen_Sales_Wrappers.ModelWrapper wrapper = new Arc_gen_Sales_Wrappers.ModelWrapper()
    * -----------------------------------------------------------------------------------------------
    **/
    public class ModelWrapper {
        /**
        * @description Id
        */
        public String idLong;
    }

    /**
    * -----------------------------------------------------------------------------------------------
    * @description Wrapper storing the RatingTypeWrapper service response
    * -----------------------------------------------------------------------------------------------
    * @param void
    * @example Arc_gen_Sales_Wrappers.RatingTypeWrapper wrapper = new Arc_gen_Sales_Wrappers.RatingTypeWrapper()
    * -----------------------------------------------------------------------------------------------
    **/
    public class RatingTypeWrapper {
        /**
        * @description Id
        */
        public String idLong;
    }

    /**
    * -----------------------------------------------------------------------------------------------
    * @description Wrapper storing the RelationParentSubsidiaryWrapper service response
    * -----------------------------------------------------------------------------------------------
    * @param void
    * @example Arc_gen_Sales_Wrappers.RelationParentSubsidiaryWrapper wrapper = new Arc_gen_Sales_Wrappers.RelationParentSubsidiaryWrapper()
    * -----------------------------------------------------------------------------------------------
    **/
    public class RelationParentSubsidiaryWrapper {
        /**
        * @description Id
        */
        public String idLong;
        /**
        * @description Description parent subsidiary relationship.
        */
        public String description;
    }

    /**
    * -----------------------------------------------------------------------------------------------
    * @description Wrapper storing the ExchangeWrapper service response
    * -----------------------------------------------------------------------------------------------
    * @param void
    * @example Arc_gen_Sales_Wrappers.ResponseWrapper wrapper = new Arc_gen_Sales_Wrappers.ResponseWrapper()
    * -----------------------------------------------------------------------------------------------
    **/
    public class ExchangeWrapper {
        /**
        * @description String with the date
        */
        public String dateX;

        /**
        * @description baseWrapper class
        */
        public BaseWrapper base;

        /**
        * @description List targetWrapper class
        */
        public List<TargetWrapper> targets;
    }

    /**
    * -----------------------------------------------------------------------------------------------
    * @description Wrapper storing the BaseWrapper service response
    * -----------------------------------------------------------------------------------------------
    * @param void
    * @example Arc_gen_Sales_Wrappers.ResponseWrapper wrapper = new Arc_gen_Sales_Wrappers.ResponseWrapper()
    * -----------------------------------------------------------------------------------------------
    **/
    public class BaseWrapper {
        /**
        * @description Currency of base
        */
        public String currencyX;
    }

    /**
    * -----------------------------------------------------------------------------------------------
    * @description Wrapper storing the TargetWrapper service response
    * -----------------------------------------------------------------------------------------------
    * @param void
    * @example Arc_gen_Sales_Wrappers.ResponseWrapper wrapper = new Arc_gen_Sales_Wrappers.ResponseWrapper()
    * -----------------------------------------------------------------------------------------------
    **/
    public class TargetWrapper {
        /**
        * @description currency of targe
        */
        public String currencyX;

        /**
        * @description Ratio
        */
        public RatioWrapper ratio;

    }

    /**
    * -----------------------------------------------------------------------------------------------
    * @description Wrapper storing the BranchWrapper service response
    * -----------------------------------------------------------------------------------------------
    * @param void
    * @example Arc_gen_Sales_Wrappers.BranchWrapper BranchWrapper = new Arc_gen_Sales_Wrappers.BranchWrapper()
    * -----------------------------------------------------------------------------------------------
    **/
    public class BranchWrapper {
        /**
        * @description Unique bank identifier.
        */
        public String idLong;
    }

    /**
    * -----------------------------------------------------------------------------------------------
    * @description Wrapper storing the BankWrapper service response
    * -----------------------------------------------------------------------------------------------
    * @param void
    * @example Arc_gen_Sales_Wrappers.BankWrapper BankWrapper = new Arc_gen_Sales_Wrappers.BankWrapper()
    * -----------------------------------------------------------------------------------------------
    **/
    public class BankWrapper {
        /**
        * @description Unique bank identifier.
        */
        public String idLong;
        /**
        * @description Identifier of country. Based on ISO 3166-2.
        */
        public String country;
        /**
        * @description Branch from which the assessment is created.
        */
        public BranchWrapper branch;
    }

    /**
    * -----------------------------------------------------------------------------------------------
    * @description Wrapper storing the RatioWrapper service response
    * -----------------------------------------------------------------------------------------------
    * @param void
    * @example Arc_gen_Sales_Wrappers.ResponseWrapper wrapper = new Arc_gen_Sales_Wrappers.ResponseWrapper()
    * -----------------------------------------------------------------------------------------------
    **/
    public class RatioWrapper {
        /**
        * @description ExchangeType
        */
        public ExchangeTypeWrapper exchangeType;
    }

    /**
    * -----------------------------------------------------------------------------------------------
    * @description Wrapper storing the ExchangeTypeWrapper service response
    * -----------------------------------------------------------------------------------------------
    * @param void
    * @example Arc_gen_Sales_Wrappers.ResponseWrapper wrapper = new Arc_gen_Sales_Wrappers.ResponseWrapper()
    * -----------------------------------------------------------------------------------------------
    **/
    public class ExchangeTypeWrapper {
        /**
        * @description value with the exchangeType
        */
        public Decimal value;
    }

    /**
    * -----------------------------------------------------------------------------------------------
    * @description Wrapper storing the service response
    * -----------------------------------------------------------------------------------------------
    * @param void
    * @example Arc_gen_Sales_Wrappers.ResponseWrapper wrapper = new Arc_gen_Sales_Wrappers.ResponseWrapper()
    * -----------------------------------------------------------------------------------------------
    **/
    public class VariableWrapper {
        /**
        * @description Id of the variable
        */
        public String idLong;
        /**
        * @description name of the variable
        */
        public String name;
        /**
        * @description value of the variable
        */
        public String value;
    }
}