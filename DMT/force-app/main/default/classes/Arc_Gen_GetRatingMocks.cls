/**
* ------------------------------------------------------------------------------------------------
* @Name     Arc_Gen_getRatingDataService_service
* @Author   Eduardo Efraín Hernández Rendón  eduardoefrain.hernandez.contractor@bbva.com
* @Date     Created: 2020-07-02
* @Group    ARCE
* -----------------------------------------------------------------------------------------------
* @Description Class that builds the Json response for the rating test class
* -----------------------------------------------------------------------------------------------
* @Changes
*
* |2020-07-02 eduardoefrain.hernandez.contractor@bbva.com
*             Class creation.
* -----------------------------------------------------------------------------------------------
*/
@SuppressWarnings('sf:ExcessiveClassLength, sf:AvoidDuplicateLiterals, sf:ExcessiveMethodLength, sf:NPathComplexity')
public without sharing class Arc_Gen_GetRatingMocks {
    /**
    * @Description Private constructor to avoid sonar warnings.
    */
    private Arc_Gen_GetRatingMocks() {}

    /**
    * ------------------------------------------------------------------------------------------------
    * @Description: Method that builds a json response mock for the financial alert
    * ------------------------------------------------------------------------------------------------
    * @Author   Eduardo Efraín Hernández Rendón - eduardoefrain.hernandez.contractor@bbva.com
    * @Date     Created: 2020/07/02
    * @param finAlert   Indicates if the response has financial alert
    * @return String Json response
    * @example getRatingMock(Boolean withAdjust, Boolean stagging, Boolean finAlert)
    * ------------------------------------------------------------------------------------------------
    **/
    private static String finAlertJson(Boolean finAlert) {
        final String finaAlertSt = finAlert == true ? '{'+
        '            "adjustmentType":{'+
        '               "id":"OVERLAY"'+
        '            },'+
        '            "modifier":{'+
        '               "id":"02",'+
        '               "description":"Financial alert example",'+
        '               "modifierType":"01",'+
        '               "value":"02"'+
        '            },'+
        '            "score":4,'+
        '            "defaultProbability":6.3,'+
        '            "shortScaleValue":"A",'+
        '            "longScaleValue":"BBB-1"'+
        '         }' : '';
        Return finaAlertSt;
    }
    /**
    * ------------------------------------------------------------------------------------------------
    * @Description: Method that builds a json response mock for the financial alert
    * ------------------------------------------------------------------------------------------------
    * @Author   Eduardo Efraín Hernández Rendón - eduardoefrain.hernandez.contractor@bbva.com
    * @Date     Created: 2020/07/02
    * @param finAlert   Indicates if the response has financial alert
    * @return String Json response
    * @example getRatingMock(Boolean withAdjust, Boolean stagging, Boolean finAlert)
    * ------------------------------------------------------------------------------------------------
    **/
    private static String staggingJson(Boolean stagging, Boolean finAlert) {
        final String comma = finAlert == true ? ',' : '';
        final String staggingSt = stagging == true ? '{'+
        '            "adjustmentType":{'+
        '               "id":"OVERLAY"'+
        '            },'+
        '            "modifier":{'+
        '               "id":"02",'+
        '               "description":"Financial alert example",'+
        '               "modifierType":"01",'+
        '               "value":"02"'+
        '            },'+
        '            "score":4,'+
        '            "defaultProbability":6.3,'+
        '            "shortScaleValue":"A",'+
        '            "longScaleValue":"BBB-1"'+
        '         }'+ comma : '';
        Return staggingSt;
    }
    /**
    * ------------------------------------------------------------------------------------------------
    * @Description: Method that builds a json response mock for the rating engine service
    * ------------------------------------------------------------------------------------------------
    * @Author   Eduardo Efraín Hernández Rendón - eduardoefrain.hernandez.contractor@bbva.com
    * @Date     Created: 2020/07/02
    * @param withAdjust Indicates if the response has adjustments
    * @param stagging   Indicates if the response has stagging
    * @param finAlert   Indicates if the response has financial alert
    * @return String Json response
    * @example getRatingMock(Boolean withAdjust, Boolean stagging, Boolean finAlert)
    * ------------------------------------------------------------------------------------------------
    **/
    public static String getRatingMock(Boolean withAdjust, Boolean stagging, Boolean finAlert) {
        final String adjustments = withAdjust == true ? '"adjustments":['+
            staggingJson(stagging, finAlert) + finAlertJson(finAlert) +
        '      ],' : '';
        Return '{'+
        '   "data":{'+
        '      "id":"9900013605",'+
        '      "evaluationDate":"2020-02-12",'+
        '      "status":{'+
        '         "id":"CALCULATED"'+
        '      },'+
        '      "calculationType":{'+
        '         "id":"SEMI_AUTOMATIC"'+
        '      },'+
        '      "isSmallMediumEnterprise":false,'+
        '      "ratings":['+
        '         {'+
        '            "score":40.05,'+
        '            "defaultProbability":1.32,'+
        '            "shortScaleValue":"BB-",'+
        '            "longScaleValue":"BB-1",'+
        '            "tool":{'+
        '               "id":"04127025712500000000"'+
        '            },'+
        '            "ratingType":{'+
        '               "id":"STANDALONE"'+
        '            }'+
        '         },'+
        '         {'+
        '            "score":25.22,'+
        '            "defaultProbability":11.91,'+
        '            "shortScaleValue":"BBB+",'+
        '            "longScaleValue":"BBB+",'+
        '            "tool":{'+
        '               "id":"04127025712500000000"'+
        '            },'+
        '            "ratingType":{'+
        '               "id":"OVERLAY"'+
        '            }'+
        '         },'+
        '         {'+
        '            "score":25.22,'+
        '            "defaultProbability":11.91,'+
        '            "shortScaleValue":"CCC+",'+
        '            "longScaleValue":"CCC+",'+
        '            "tool":{'+
        '               "id":"04127025712500000000"'+
        '            },'+
        '            "ratingType":{'+
        '               "id":"OVERRIDE"'+
        '            }'+
        '         },'+
        '         {'+
        '            "score":25.22,'+
        '            "defaultProbability":11.91,'+
        '            "shortScaleValue":"CCC+",'+
        '            "longScaleValue":"CCC+",'+
        '            "tool":{'+
        '               "id":"04127025712500000000"'+
        '            },'+
        '            "ratingType":{'+
        '               "id":"FINAL"'+
        '            }'+
        '         }'+
        '      ],'+
                adjustments +
        '      "variables":['+
        '         {'+
        '            "level":"2",'+
        '            "id":"2111",'+
        '            "parentCode":"1",'+
        '            "blockType":"QUANTITATIVE_BLOCK",'+
        '            "hasFinalScoreWeight":true,'+
        '            "value":"-4.52",'+
        '            "score":{'+
        '               "value":"3.54",'+
        '               "maximumScore":9.22'+
        '            }'+
        '         },'+
        '         {'+
        '            "level":"2",'+
        '            "id":"2211",'+
        '            "parentCode":"1",'+
        '            "blockType":"QUANTITATIVE_BLOCK",'+
        '            "hasFinalScoreWeight":true,'+
        '            "value":"5.87",'+
        '            "score":{'+
        '               "value":"1.08",'+
        '               "maximumScore":1.89'+
        '            }'+
        '         },'+
        '         {'+
        '            "level":"2",'+
        '            "id":"2311",'+
        '            "parentCode":"1",'+
        '            "blockType":"QUANTITATIVE_BLOCK",'+
        '            "hasFinalScoreWeight":true,'+
        '            "value":"2.20",'+
        '            "score":{'+
        '               "value":"2.71",'+
        '               "maximumScore":3.42'+
        '            }'+
        '         },'+
        '         {'+
        '            "level":"2",'+
        '            "id":"2411",'+
        '            "parentCode":"1",'+
        '            "blockType":"QUANTITATIVE_BLOCK",'+
        '            "hasFinalScoreWeight":true,'+
        '            "value":"99999999.00",'+
        '            "score":{'+
        '               "value":"3.31",'+
        '               "maximumScore":3.31'+
        '            }'+
        '         },'+
        '         {'+
        '            "level":"2",'+
        '            "id":"2511",'+
        '            "parentCode":"1",'+
        '            "blockType":"QUANTITATIVE_BLOCK",'+
        '            "hasFinalScoreWeight":true,'+
        '            "value":"0.55",'+
        '            "score":{'+
        '               "value":"0.83",'+
        '               "maximumScore":1.19'+
        '            }'+
        '         },'+
        '         {'+
        '            "level":"2",'+
        '            "id":"2611",'+
        '            "parentCode":"1",'+
        '            "blockType":"QUANTITATIVE_BLOCK",'+
        '            "hasFinalScoreWeight":true,'+
        '            "value":"5.43",'+
        '            "score":{'+
        '               "value":"0.00",'+
        '               "maximumScore":4.98'+
        '            }'+
        '         },'+
        '         {'+
        '            "level":"2",'+
        '            "id":"2711",'+
        '            "parentCode":"1",'+
        '            "blockType":"QUANTITATIVE_BLOCK",'+
        '            "hasFinalScoreWeight":true,'+
        '            "value":"0.60",'+
        '            "score":{'+
        '               "value":"1.82",'+
        '               "maximumScore":8.26'+
        '            }'+
        '         },'+
        '         {'+
        '            "level":"2",'+
        '            "id":"2811",'+
        '            "parentCode":"1",'+
        '            "blockType":"QUANTITATIVE_BLOCK",'+
        '            "hasFinalScoreWeight":true,'+
        '            "value":"99999999.00",'+
        '            "score":{'+
        '               "value":"0.00",'+
        '               "maximumScore":4.38'+
        '            }'+
        '         },'+
        '         {'+
        '            "level":"2",'+
        '            "id":"2911",'+
        '            "parentCode":"1",'+
        '            "blockType":"QUANTITATIVE_BLOCK",'+
        '            "hasFinalScoreWeight":true,'+
        '            "value":"-99999990.00",'+
        '            "score":{'+
        '               "value":"0.00",'+
        '               "maximumScore":1.4'+
        '            }'+
        '         },'+
        '         {'+
        '            "level":"2",'+
        '            "id":"21011",'+
        '            "parentCode":"1",'+
        '            "blockType":"QUANTITATIVE_BLOCK",'+
        '            "hasFinalScoreWeight":true,'+
        '            "value":"-99999994.00",'+
        '            "score":{'+
        '               "value":"0.00",'+
        '               "maximumScore":1.94'+
        '            }'+
        '         },'+
        '         {'+
        '            "level":"1",'+
        '            "id":"1100",'+
        '            "parentCode":"0",'+
        '            "blockType":"QUANTITATIVE_BLOCK",'+
        '            "hasFinalScoreWeight":true,'+
        '            "score":{'+
        '               "value":"13.29",'+
        '               "maximumScore":40.0'+
        '            }'+
        '         },'+
        '         {'+
        '            "level":"1",'+
        '            "id":"1400",'+
        '            "parentCode":"4",'+
        '            "blockType":"EXTRA_BUSINESS_BLOCK",'+
        '            "hasFinalScoreWeight":true,'+
        '            "score":{'+
        '               "value":"20.94",'+
        '               "maximumScore":30.0'+
        '            }'+
        '         },'+
        '         {'+
        '            "level":"2",'+
        '            "id":"23514",'+
        '            "blockType":"EXTRA_BUSINESS_BLOCK",'+
        '            "hasFinalScoreWeight":true,'+
        '            "value":"267",'+
        '            "score":{'+
        '               "value":"8.53",'+
        '               "maximumScore":8.53'+
        '            }'+
        '         },'+
        '         {'+
        '            "level":"2",'+
        '            "id":"23614",'+
        '            "parentCode":"4",'+
        '            "blockType":"EXTRA_BUSINESS_BLOCK",'+
        '            "hasFinalScoreWeight":true,'+
        '            "value":"1",'+
        '            "score":{'+
        '               "value":"3.10",'+
        '               "maximumScore":3.1'+
        '            }'+
        '         },'+
        '         {'+
        '            "level":"2",'+
        '            "id":"23714",'+
        '            "parentCode":"4",'+
        '            "blockType":"EXTRA_BUSINESS_BLOCK",'+
        '            "hasFinalScoreWeight":true,'+
        '            "value":"3",'+
        '            "score":{'+
        '               "value":"0.00",'+
        '               "maximumScore":7.21'+
        '            }'+
        '         },'+
        '         {'+
        '            "level":"2",'+
        '            "id":"23814",'+
        '            "parentCode":"4",'+
        '            "blockType":"EXTRA_BUSINESS_BLOCK",'+
        '            "hasFinalScoreWeight":true,'+
        '            "value":"0.4072",'+
        '            "score":{'+
        '               "value":"6.19",'+
        '               "maximumScore":6.19'+
        '            }'+
        '         },'+
        '         {'+
        '            "level":"2",'+
        '            "id":"23914",'+
        '            "parentCode":"4",'+
        '            "blockType":"EXTRA_BUSINESS_BLOCK",'+
        '            "hasFinalScoreWeight":true,'+
        '            "value":"-4.242245252",'+
        '            "score":{'+
        '               "value":"3.12",'+
        '               "maximumScore":4.97'+
        '            }'+
        '         },'+
        '         {'+
        '            "level":"1",'+
        '            "id":"1300",'+
        '            "parentCode":"3",'+
        '            "blockType":"BEHAVIOURAL_BLOCK",'+
        '            "hasFinalScoreWeight":true,'+
        '            "score":{'+
        '               "value":"5.82",'+
        '               "maximumScore":30.0'+
        '            }'+
        '         },'+
        '         {'+
        '            "level":"2",'+
        '            "id":"22313",'+
        '            "parentCode":"3",'+
        '            "blockType":"BEHAVIOURAL_BLOCK",'+
        '            "hasFinalScoreWeight":true,'+
        '            "value":"0.00",'+
        '            "score":{'+
        '               "value":"0.00",'+
        '               "maximumScore":3.34'+
        '            }'+
        '         },'+
        '         {'+
        '            "level":"2",'+
        '            "id":"22413",'+
        '            "parentCode":"3",'+
        '            "blockType":"BEHAVIOURAL_BLOCK",'+
        '            "hasFinalScoreWeight":true,'+
        '            "value":"0.00",'+
        '            "score":{'+
        '               "value":"0.00",'+
        '               "maximumScore":0.97'+
        '            }'+
        '         },'+
        '         {'+
        '            "level":"2",'+
        '            "id":"22513",'+
        '            "parentCode":"3",'+
        '            "blockType":"BEHAVIOURAL_BLOCK",'+
        '            "hasFinalScoreWeight":true,'+
        '            "value":"0.38",'+
        '            "score":{'+
        '               "value":"0.00",'+
        '               "maximumScore":2.35'+
        '            }'+
        '         },'+
        '         {'+
        '            "level":"2",'+
        '            "id":"22613",'+
        '            "parentCode":"3",'+
        '            "blockType":"BEHAVIOURAL_BLOCK",'+
        '            "hasFinalScoreWeight":true,'+
        '            "value":"0.50",'+
        '            "score":{'+
        '               "value":"0.00",'+
        '               "maximumScore":3.52'+
        '            }'+
        '         },'+
        '         {'+
        '            "level":"2",'+
        '            "id":"22713",'+
        '            "parentCode":"3",'+
        '            "blockType":"BEHAVIOURAL_BLOCK",'+
        '            "hasFinalScoreWeight":true,'+
        '            "value":"999999999.00",'+
        '            "score":{'+
        '               "value":"0",'+
        '               "maximumScore":0.0'+
        '            }'+
        '         },'+
        '         {'+
        '            "level":"2",'+
        '            "id":"22813",'+
        '            "parentCode":"3",'+
        '            "blockType":"BEHAVIOURAL_BLOCK",'+
        '            "hasFinalScoreWeight":true,'+
        '            "value":"0.00",'+
        '            "score":{'+
        '               "value":"0",'+
        '               "maximumScore":0.0'+
        '            }'+
        '         },'+
        '         {'+
        '            "level":"2",'+
        '            "id":"22913",'+
        '            "parentCode":"3",'+
        '            "blockType":"BEHAVIOURAL_BLOCK",'+
        '            "hasFinalScoreWeight":true,'+
        '            "value":"6.00",'+
        '            "score":{'+
        '               "value":"0",'+
        '               "maximumScore":0.0'+
        '            }'+
        '         },'+
        '         {'+
        '            "level":"2",'+
        '            "id":"23013",'+
        '            "parentCode":"3",'+
        '            "blockType":"BEHAVIOURAL_BLOCK",'+
        '            "hasFinalScoreWeight":true,'+
        '            "value":"0.01",'+
        '            "score":{'+
        '               "value":"0",'+
        '               "maximumScore":0.0'+
        '            }'+
        '         },'+
        '         {'+
        '            "level":"2",'+
        '            "id":"23113",'+
        '            "parentCode":"3",'+
        '            "blockType":"BEHAVIOURAL_BLOCK",'+
        '            "hasFinalScoreWeight":true,'+
        '            "value":"0.00",'+
        '            "score":{'+
        '               "value":"5.54",'+
        '               "maximumScore":5.54'+
        '            }'+
        '         },'+
        '         {'+
        '            "level":"2",'+
        '            "id":"23213",'+
        '            "parentCode":"3",'+
        '            "blockType":"BEHAVIOURAL_BLOCK",'+
        '            "hasFinalScoreWeight":true,'+
        '            "value":"-999999996.00",'+
        '            "score":{'+
        '               "value":"0.00",'+
        '               "maximumScore":10.97'+
        '            }'+
        '         },'+
        '         {'+
        '            "level":"2",'+
        '            "id":"23313",'+
        '            "parentCode":"3",'+
        '            "blockType":"BEHAVIOURAL_BLOCK",'+
        '            "hasFinalScoreWeight":true,'+
        '            "value":"-999999998.00",'+
        '            "score":{'+
        '               "value":"0",'+
        '               "maximumScore":0.0'+
        '            }'+
        '         },'+
        '         {'+
        '            "level":"2",'+
        '            "id":"23413",'+
        '            "parentCode":"3",'+
        '            "blockType":"BEHAVIOURAL_BLOCK",'+
        '            "hasFinalScoreWeight":true,'+
        '            "value":"0.01",'+
        '            "score":{'+
        '               "value":"0.28",'+
        '               "maximumScore":3.31'+
        '            }'+
        '         },'+
        '         {'+
        '            "level":"1",'+
        '            "id":"1200",'+
        '            "parentCode":"2",'+
        '            "blockType":"QUALITATIVE_BLOCK",'+
        '            "hasFinalScoreWeight":false,'+
        '            "score":{'+
        '               "value":"0",'+
        '               "maximumScore":0.0'+
        '            }'+
        '         }'+
        '      ],'+
        '      "controls":['+
        '         {'+
        '            "id":"missingData",'+
        '            "description":"Unable to get triage data",'+
        '            "isValid":false'+
        '         }'+
        '      ]'+
        '   }'+
        '}';
    }
}