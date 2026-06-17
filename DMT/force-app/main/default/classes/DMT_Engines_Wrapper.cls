@JsonAccess(serializable='always' deserializable='always')
public with sharing class DMT_Engines_Wrapper {

    @AuraEnabled
    public List<ConsumptionLimitItem> data;

    // success'
    @AuraEnabled
    public boolean success;

    // errorMessage
    @AuraEnabled
    public String errorMessage;

    // errorMessage
    @AuraEnabled
    public String callEntityName;

    // Clase interna para representar una cantidad
    @JsonAccess(serializable='always' deserializable='always')
    public class Amount {
        // Importe del riesgo no disponible. Lo que viene en la tabla + Consumo, si es otra divisa hacer tipo de cambio
        @AuraEnabled
        public Decimal unavailableRiskAmount;

        // Importe del riesgo autorizado
        @AuraEnabled
        public Decimal authorizedRiskAmount;

        // Importe dispuesto de los contratos comprometidos
        @AuraEnabled
        public Decimal cmtContDisposedAmount;

        // Importe dispuesto de los contratos no comprometidos
        @AuraEnabled
        public Decimal uncmtContDisposedAmount;

        // Importe no dispuesto de los contratos comprometidos
        @AuraEnabled
        public Decimal cmtContNonDspsAmount;

        // Importe no dispuesto de los contratos no comprometidos
        @AuraEnabled
        public Decimal uncmtContNonDspsAmount;

        // Importe del consumo correspondiente a operaciones que aún no están firmadas por el cliente. Lo que viene en la tabla + Consumo, si es otra divisa hacer tipo de cambio
        @AuraEnabled
        public Decimal notSignedTrConsumptionAmount;//editado

        // Importe actual aprobado como resultado del nuevo proceso de análisis una vez sancionado
        @AuraEnabled
        public Decimal currentApprovedAmount;
    }

    // Clase interna para representar un límite de consumo
    @JsonAccess(serializable='always' deserializable='always')
    public class ConsumptionLimitItem {
        // Identificador nivel último de consumo
        @AuraEnabled
        public String consumptionLastLevelId;

        // Indica la última fecha de actualización del Last Level ID en taxonomy
        @AuraEnabled
        public Date cutoffDate;

        // Código del Límite en hpgr
        @AuraEnabled
        public String limitId;//editado

        // En función del parámetro de entrada indicado para el campo AggregationLevel, facilitará el Identificador del cliente/grupo/golden/agrupación en el modelo global correspondiente al AggregationLevel seleccionado
        @AuraEnabled
        public String aggregationId;

        @AuraEnabled
        public String customerId;
        @AuraEnabled
        public String groupId;
        @AuraEnabled
        public String goldenCustomerId;
        @AuraEnabled
        public String customerGroupId;

        // Descripción de un determinado límite establecido
        @AuraEnabled
        public String limitDesc;//editado

        // Tipo de origen en Modelo Global. Este campo puede tomar valores como por ejemplo: Holding // España // Colombia // Otros
        @AuraEnabled
        public String originType;

        // Indicador del tipo de límite
        @AuraEnabled
        public String limitType;

        // Lista de importes
        @AuraEnabled
        public Amount amount;

        // Código alfanumérico Modelo Global de 3 posiciones que clasifica la divisa/moneda de los países en base al estándar internacional ISO 4217
        @AuraEnabled
        public String currencyId;

        // Fecha de vencimiento del análisis de riesgo actual
        @AuraEnabled
        public Date riskAnalysisExpiryDate;

        // Descripción de la acción a realizar si se supera el límite de consumo
        @AuraEnabled
        public String consumLimitExceededActionDesc;//editado

        // Identificador único para el analista de riesgos
        @AuraEnabled
        public String riskAnalystId;

        // Valor de texto libre cumplimentado por el usuario, observaciones
        @AuraEnabled
        public String conditionDesc;//editado

        // Indica si acorde a los valores obtenidos se sobrepasa o no el límite de consumo, valor obtenido de la diferencia: gf_current_approved_amount - gf_unavailable_risk_amount (Limite Menos Consumo). Posibles valores indicados en el campo: GREEN, RED, ORANGE
        @AuraEnabled
        public String stateName;//editado
    }

    @JsonAccess(serializable='always' deserializable='always')
    public class Request {
        // Indica el producto financiero, dicho producto deberá ser un producto financiero válido para el Motor de Limites.
        @AuraEnabled
        public String productId;

        // Indica el tipo de cliente
        @AuraEnabled
        public String clientType;

        // Indica si el plazo es mayor a un año o no
        @AuraEnabled
        public String termMajor;

        // Indica si existen garantias o no
        @AuraEnabled
        public String guaranteeInd;

        // Indica el importe
        @AuraEnabled
        public Decimal amountValue;

        // Indica la divisa
        @AuraEnabled
        public String currencyId;

        // Indica el nivel de agregación (Cliente Local, Grupo, Subgrupo, Supragrupo, GoldenId, Custom Association)
        @AuraEnabled
        public String aggregationLevel;

        // Indica el identificador asociado al Cliente Local, Grupo, Golden o Agrupación, según corresponda, es decir, identifica por ejemplo el código del cliente esepcifico si en el campo aggregation level se ha indicado "cliente local".
        @AuraEnabled
        public String aggregationId;

        //customerId
        @AuraEnabled
        public String customerId;

        //groupId
        @AuraEnabled
        public String groupId;

        //subGroupId
        @AuraEnabled
        public String subGroupId;

        //level3groupId
        @AuraEnabled
        public String level3groupId;

        //accountId
        @AuraEnabled
        public String accountId;

        //customerName
        @AuraEnabled
        public String customerName;

        //groupName
        @AuraEnabled
        public String groupName;

        //subGroupName
        @AuraEnabled
        public String subGroupName;

        //level3groupName
        @AuraEnabled
        public String level3groupName;

        //accountName
        @AuraEnabled
        public String accountName;

        //ACIsView
        @AuraEnabled
        public String isView;

        //ACIsView
        @AuraEnabled
        public String isViewError;

        //ACIsView
        @AuraEnabled
        public String clientTypeStructure;
    }

    @JsonAccess(serializable='always' deserializable='always')
    public class ResponseItem {
        @AuraEnabled
        public String Name;
        @AuraEnabled
        public String LastUpdate;
        @AuraEnabled
        public String FeatureId;
        @AuraEnabled
        public String Description;
        @AuraEnabled
        public String Capability;
        @AuraEnabled
        public String CapabilityV2;
        @AuraEnabled
        public String Amount;
        @AuraEnabled
        public String Comments;
        //public String Level3groupId;
        @AuraEnabled
        public ChartDataWrapper chartData;
    }

    @JsonAccess(serializable='always' deserializable='always')
    public class Dataset {
        @AuraEnabled
        public String label;
        @AuraEnabled
        public List<Decimal> data;
        @AuraEnabled
        public String backgroundColor;
        @AuraEnabled
        public String hoverBackgroundColor;

        public Dataset(List<Decimal> data, String backgroundColor, String hoverBackgroundColor, String label) {
            this.label = label;
            this.data = data;
            this.backgroundColor = backgroundColor;
            this.hoverBackgroundColor = hoverBackgroundColor;
        }
    }

    // Wrapper class for returning chart data
    @JsonAccess(serializable='always' deserializable='always')
    public class ChartDataWrapper {
        @AuraEnabled
        public List<Decimal> targets;
        @AuraEnabled
        public List<String> labels;
        @AuraEnabled
        public List<Dataset> datasets;
        @AuraEnabled
        public String targetColor;
        @AuraEnabled
        public String originCurrency;
        @AuraEnabled
        public List<String> currencies;
        @AuraEnabled
        public List<String> sections;
        @AuraEnabled
        public List<String> limitLights;
        @AuraEnabled
        public List<String> conditions;
    }

    @JsonAccess(serializable='always' deserializable='always')
    public class PickItem {
        @AuraEnabled
        public String label;
        @AuraEnabled
        public String value;
    }
    @JsonAccess(serializable='always' deserializable='always')
    public class CurrencyResponse {
        @AuraEnabled
        public List<DMT_Engines_Wrapper.PickItem> picklist;
        @AuraEnabled
        public Map<String,String> currencyMap;
    }

    @JsonAccess(serializable='always' deserializable='always')
    public class Message {
        @AuraEnabled
        public String code;
        @AuraEnabled
        public String message;
        @AuraEnabled
        public List<String> parameters;
        @AuraEnabled
        public String type;
    }

    @JsonAccess(serializable='always' deserializable='always')
    public class ErrorResponse {
        @AuraEnabled
        public List<Message> messages;
    }

}