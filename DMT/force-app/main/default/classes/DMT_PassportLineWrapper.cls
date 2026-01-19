@JsonAccess(serializable='always' deserializable='always')
public with sharing class DMT_PassportLineWrapper {
    public Data data;
    public class Data{
        public String opportunityId;
        public Datetime auditDate;
        public String version;
        public List<Feature> features;
    }

    public class Feature {
        public String id;
        public String name;
        public String passportSanction;
        public String active;
        public String motorDesc;
        public String stateName;
        public Integer orderNumber;
        public Profitability profitability;

        public List<Validation> validations;
        public List<ConsumptionLimit> consumptionLimits;
        public List<Task> tasks;
        public List<String> lastLevels;
        }

    public class Validation {
        public String state;
        public String name;
        public String message;
    }

    public class ConsumptionLimit {
        public String consumptionLastLevelId;
        public Date cutoffDate;
        public String limitId;
        public String groupId;
        public String limitDesc;
        public String originType;
        public String limitType;
        public Amount amount;
        public String currencyId;
        public Date riskAnalysisExpiryDate;
        public String riskAnalystId;
        public String conditionDesc;
        public String stateName;
    }

    public class Amount {
        public String unavailableRiskAmount;
        public String authorizedRiskAmount;
        public String cmtContDisposedAmount;
        public String uncmtContDisposedAmount;
        public String cmtContNonDspsAmount;
        public String uncmtContNonDspsAmount;
        public String notSignedTrConsumptionAmount;
        public String currentApprovedAmount;
    }


    public class Task {
        public String id;
        public String name;
        public String yesFlag;
        public String noFlag;
        public String naFlag;
        public String nextTask;
        public String status;
        public List<Approver> approvers;
    }

    public class Approver {
        public String id;
        public String name;
        public String entific;
        public String branch;
        public String documentManagerEnable;
    }

    public class Profitability {
        public Audit audit;
        public List<Result> results;

    }

    public class Audit {
        public String engineVersion;
        public Boolean isError;
    }
    public class Result {
        public String productId;
    }



    public static DMT_PassportLineWrapper parseLinePassport(String myData) {
        return (DMT_PassportLineWrapper) JSON.deserialize(myData, DMT_PassportLineWrapper.class);
    }

}