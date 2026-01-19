/**
* ------------------------------------------------------------------------------------------------
* @Name     Arc_Gen_PersistanceBR_Service
* @Author   Ricardo Almanza Angeles
* @Date     Created: 21/01/2020
* @Group    ARCE
* -----------------------------------------------------------------------------------------------
* @Description Class that get data and create json to persist.
* -----------------------------------------------------------------------------------------------
* @Changes
*
* |2019-01-21 Ricardo Almanza Angeles
*             Class creation.
* |2020-04-14 berthaelena.tellez.contractor@bbva.com
*    resolve fix on mapeo data
* |2020-09-23 saimassimilianno.jordana.contractor@bbva.com
*             Added arce. namespace to all classes that are now in the arce-dependencies package
* |2020-03-12 juanpedro.benito.contractor@bbva.com
*             Change arce__third_participant_per__c for arce__third_prtcpt_intervention_per__c
* |2021-06-17 juanignacio.hita.contractor@bbva.com
*             Rollback last commit  (PR: 1231)
* -----------------------------------------------------------------------------------------------
*/
@SuppressWarnings('sf:UnusedLocalVariable')
public class Arc_Gen_PersistanceBR_Service {
    /**
        * @Description: string with the service name
    */
        Static Final String SERVICE_NAME = 'businessrisk';
    /**
        * @Description: string with the success answer1
    */
        Static Final String SUCC1 = '201';
    /**
        * @Description: string with the success answer2
    */
        Static Final String SUCC2 = '200';
    /**
        * @Description: string with the recordtype Geographies
    */
        Static Final String GEO = 'Geographies';
    /**
        * @Description: string with the recordtype Main_suppliers
    */
        Static Final String MNS = 'Main_suppliers';
    /**
        * @Description: string with the recordtype Main_clients
    */
        Static Final String MNC = 'Main_clients';
    /**
        * @Description: string with the recordtype Shareholders
    */
        Static Final String SHR = 'Shareholders';
    /**
        * @Description: string with the recordtype Main_affiliates
    */
        Static Final String MNA = 'Main_affiliates';
    /**
        * @Description: string with the recordtype Activities
    */
        Static Final String ACT = 'Activities';
    /**
        * @Description: string with the field arce__third_participant_per__c
    */
        Static Final String TPI = 'arce__third_participant_per__c';
    /*------------------------------------------------------------------------------------------------------
    *@Description Builder Arc_Gen_PersistanceBR_Service
    * -----------------------------------------------------------------------------------------------------
    * @Author   Ricardo Almanza
    * @Date     2020-06-02
    * @param    null
    * @return   Arc_Gen_PersistanceBR_Service
    * @example  new Arc_Gen_PersistanceBR_Service()
    * */
    @TestVisible
    private Arc_Gen_PersistanceBR_Service() {}
    /*------------------------------------------------------------------------------------------------------
    *@Description Method to persist persistBR
    * -----------------------------------------------------------------------------------------------------
    * @Author   Ricardo Almanza
    * @Date     2020-06-02
    * @param    List<String> accIds Id's of account
    * @param    List<sObject> listAccsPend Accounts to persist
    * @return   boolean to confirm persistance
    * @example  persistBR()
    * */
    public static Boolean persistBR(List<String> accIds,List<sObject> listAccsPend) {
        Boolean res=true;
        Final String[] flds = codeTerm2ApiList(Label.Arc_Gen_PersBR),tblFlds = codeTerm2ApiList(Label.Arc_Gen_PersTbl),tblSndC = codeTerm2ApiList(Label.Arc_Gen_PersSNdC);
        flds.add('arce__concentration_suppliers_type__c');
        flds.add('arce__cust_conc_clients_type__c');
        Map<String,Map<String,String>> accHaMap, accHaMapDB,geogrMap,activMap,supplMap,clntsMap,shareMap,affltMap;
        String geogJson,acttJson,thrdJson,sharJson,afflJson;
        arce.Arc_Gen_getIASOResponse.serviceResponse iasoResponse = new arce.Arc_Gen_getIASOResponse.serviceResponse();
        Final arce.Arc_Gen_ServiceAndSaveResponse serviceResp = new arce.Arc_Gen_ServiceAndSaveResponse();
        Final List<sObject> listDB = arce.Arc_Gen_AccHasAnalysis_Data.getAccHasAnalysis(accIds), listAccHas = listAccsPend.isEmpty() ? listDB : listAccsPend;
        accHaMapDB = getSobjectVars(listDB, flds);
        accHaMap = getSobjectVars(listAccHas, flds);
        geogJson = buildJsonTbl(getSobjectVars(Arc_Gen_TableContentPerAnalysis_Data.getRecordsbyArcAcc(GEO,accIds), tblFlds));
        acttJson = buildJsonTbl(getSobjectVars(Arc_Gen_TableContentPerAnalysis_Data.getRecordsbyArcAcc(ACT,accIds), tblFlds));
        thrdJson = buildJsonThrd(getSobjectVars(Arc_Gen_ThirdParticipantDetails_Data.getRecordsbyArcAcc(MNS,accIds), tblSndC),getSobjectVars(Arc_Gen_ThirdParticipantDetails_Data.getRecordsbyArcAcc(MNC,accIds), tblSndC),accHaMap);
        sharJson = buildJsonShar(getSobjectVars(Arc_Gen_ThirdParticipantDetails_Data.getRecordsbyArcAcc(SHR,accIds), tblSndC));
        afflJson = buildJsonAffl(getSobjectVars(Arc_Gen_ThirdParticipantDetails_Data.getRecordsbyArcAcc(MNA,accIds), tblSndC));
        Final Id[] accs = new List<Id>();
        Integer i=2, sizeflds = flds.size()-3;
        accs.add(valuefromMaps(flds[sizeflds], accHaMapDB,0));
        Final Map<Id,arce.Arc_Gen_Account_Wrapper> listacc = arce.Arc_Gen_Account_Locator.getAccountInfoById(accs);
        Final String BsDesc =  valuefromMaps(flds[i++], accHaMap,0), BsGeo =  valuefromMaps(flds[i++], accHaMap,0)
            , BsSh =  valuefromMaps(flds[i++], accHaMap,0), BsShCm =  valuefromMaps(flds[i++], accHaMap,0);
        Final String BsExp =  valuefromMaps(flds[i++], accHaMap,0), BsImp =  valuefromMaps(flds[i++], accHaMap,0)
            , GlbBs =  changeValue(valuefromMaps(flds[i++], accHaMap,0)), GeoCm =  valuefromMaps(flds[i++], accHaMap,0);
        Final String GeoArr =  geogJson, MltBs =  changeValue(valuefromMaps(flds[i++], accHaMap,0))
            , ActCm =  valuefromMaps(flds[i++], accHaMap,0), ActArr =  acttJson;
        Final String DivTyp =  valuefromMaps(flds[i++], accHaMap,0), DivCmt =  valuefromMaps(flds[i++], accHaMap,0)
            , VulnTy =  valuefromMaps(flds[i++], accHaMap,0), VulnCmt =  valuefromMaps(flds[i++], accHaMap,0);
        Final String RelFcts =  changeValue(valuefromMaps(flds[i++], accHaMap,0));
        Final String RelCmt =  valuefromMaps(flds[i++], accHaMap,0);
        Final String ThrdArr =  thrdJson;
        Final String ShrTyp =  valuefromMaps(flds[i++], accHaMapDB,0);
        Final String BsType =  valuefromMaps(flds[i++], accHaMapDB,0);
        Final string ShrPrf =  valuefromMaps(flds[i++], accHaMapDB,0);
        Final string ShrCmt =  valuefromMaps(flds[i++], accHaMapDB,0);
        Final string Disgr =  changeValue(valuefromMaps(flds[i++], accHaMapDB,0));
        Final String DisgrCmt =  valuefromMaps(flds[i++], accHaMapDB,0), ShrVar =  changeValue(valuefromMaps(flds[i++], accHaMapDB,0));
        Final String ShrVarCmt =  valuefromMaps(flds[i++], accHaMapDB,0), ShrSup =  valuefromMaps(flds[i++], accHaMapDB,0);
        Final String ShrSupCmt =  valuefromMaps(flds[i++], accHaMapDB,0), ShrArr =  sharJson
            , MngEx =  valuefromMaps(flds[i++], accHaMapDB,0), MngExCmt =  valuefromMaps(flds[i++], accHaMapDB,0);
        Final String RskPrf =  valuefromMaps(flds[i++], accHaMapDB,0), RskPrfCmt =  valuefromMaps(flds[i++], accHaMapDB,0)
            , MngSt =  valuefromMaps(flds[i++], accHaMapDB,0), MngStCmt =  valuefromMaps(flds[i++], accHaMapDB,0);
        Final String AflCmt =  valuefromMaps(flds[i++], accHaMapDB,0), AflArr =  afflJson
            , riskid =  valuefromMaps(flds[0], accHaMapDB,0), participantid =  listacc.get(valuefromMaps(flds[sizeflds], accHaMapDB,0)).accNumber;
        Final String businessid =  valuefromMaps(flds[0], accHaMapDB,0);
        iasoResponse = arce.Arc_Gen_getIASOResponse.calloutIASO(SERVICE_NAME,'{"BsDesc" : "' + BsDesc +'","BsGeo" : "' + BsGeo +'","BsSh" : "' + BsSh
                                                        +'","BsShCm" : "' + BsShCm +'","BsExp" : "' + BsExp +'","BsImp" : "' + BsImp +'","GlbBs" : "' + GlbBs
                                                        +'","GeoCm" : "' + GeoCm +'","GeoArr" : "' + GeoArr +'","MltBs" : "' + MltBs
                                                        +'","ActCm" : "' + ActCm +'","ActArr" : "' + ActArr +'","DivTyp" : "' + DivTyp
                                                        +'","DivCmt" : "' + DivCmt +'","VulnTy" : "' + VulnTy +'","VulnCmt" : "' + VulnCmt
                                                        +'","RelFcts" : "' + RelFcts +'","RelCmt" : "' + RelCmt +'","ThrdArr" : "' + ThrdArr
                                                        +'","ShrTyp" : "' + ShrTyp +'","BsType" : "' + BsType +'","ShrPrf" : "' + ShrPrf
                                                        +'","ShrCmt" : "' + ShrCmt +'","Disgr" : "' + Disgr +'","DisgrCmt" : "' + DisgrCmt
                                                        +'","ShrVar" : "' + ShrVar +'","ShrVarCmt" : "' + ShrVarCmt +'","ShrSup" : "' + ShrSup
                                                        +'","ShrSupCmt" : "' + ShrSupCmt +'","ShrArr" : "' + ShrArr +'","MngEx" : "' + MngEx
                                                        +'","MngExCmt" : "' + MngExCmt +'","RskPrf" : "' + RskPrf
                                                        +'","RskPrfCmt" : "' + RskPrfCmt +'","MngSt" : "' + MngSt
                                                        +'","MngStCmt" : "' + MngStCmt +'","AflCmt" : "' + AflCmt
                                                        +'","AflArr" : "' + AflArr +'","riskid" : "' + riskid
                                                        +'","participantid" : "' + participantid +'","businessid" : "' + businessid +'"}');
        serviceResp.serviceCode = iasoResponse.serviceCode;
        res = serviceResp.serviceCode == SUCC1 || serviceResp.serviceCode == SUCC2 ? true : false;
        serviceResp.serviceMessage = iasoResponse.serviceMessage;
        return res;
    }
    /*------------------------------------------------------------------------------------------------------
    *@Description Method to transform map of maps to Strging for service
    * -----------------------------------------------------------------------------------------------------
    * @Author   Ricardo Almanza
    * @Date     2020-06-02
    * @param    Map<String,Map<String,String>> mapOfMaps of variables to add to map
    * @param    Map<String,Map<String,String>> mapOfMaps of variables to add to map
    * @return   String json to add to service
    * @example  buildJsonTbl(geogrMap)
    * */
    private static String buildJsonThrd(Map<String,Map<String,String>> mapOfSup,Map<String,Map<String,String>> mapOfClnts,Map<String,Map<String,String>> mapOfAHA) {
        String toRet='';
        Integer index=0;
        for (String mapS : mapOfSup.keySet()) {
            toRet += '{\\"thirdPartyDependencyType\\": \\"SUPPLIER\\",';
            toRet += '\\"dependencyDegree\\": \\"'+valuefromMaps('arce__concentration_suppliers_type__c',mapOfAHA,0)+'\\",';
            toRet += '\\"name\\": \\"'+valuefromMaps('arce__third_participant_desc__c',mapOfSup,index)+'\\",';
            toRet += '\\"percentage\\": '+valuefromMaps(TPI,mapOfSup,index)+'';
            toRet += index == mapOfSup.size()-1 ? '}' : '},';
            index++;
        }
        index=0;
        for (String mapS : mapOfClnts.keySet()) {
            toRet += index==0 && String.isNotEmpty(toRet) ? ',' : '';
            toRet += '{\\"thirdPartyDependencyType\\": \\"CUSTOMER\\",';
            toRet += '\\"dependencyDegree\\": \\"'+valuefromMaps('arce__cust_conc_clients_type__c',mapOfAHA,0)+'\\",';
            toRet += '\\"name\\": \\"'+valuefromMaps('arce__third_participant_desc__c',mapOfClnts,index)+'\\",';
            toRet += '\\"percentage\\": '+valuefromMaps(TPI,mapOfClnts,index)+'';
            toRet += index == mapOfClnts.size()-1 ? '}' : '},';
            index++;
        }
        return toRet;
    }
    /*------------------------------------------------------------------------------------------------------
    *@Description Method to transform map of maps to Strging for service
    * -----------------------------------------------------------------------------------------------------
    * @Author   Ricardo Almanza
    * @Date     2020-06-02
    * @param    Map<String,Map<String,String>> mapOfMaps of variables to add to map
    * @return   String json to add to service
    * @example  buildJsonTbl(geogrMap)
    * */
    private static String buildJsonAffl(Map<String,Map<String,String>> mapOfMaps) {
        String toRet = '';
        Integer index=0;
        for (String mapS : mapOfMaps.keySet()) {
            toRet += '{\\"name\\": \\"'+valuefromMaps('arce__Third_Participant_id__r.Name',mapOfMaps,index)+'\\",';
            toRet += '\\"activity\\": \\"'+valuefromMaps('arce__economic_activity_sector_desc__c',mapOfMaps,index)+'\\",';
            toRet += '\\"groupParticipation\\": '+valuefromMaps(TPI,mapOfMaps,index)+',';
            toRet += '\\"consolidationType\\": \\"'+valuefromMaps('arce__consolidation_method_id__c',mapOfMaps,index)+'\\",';
            toRet += '\\"isBBVACustomer\\": '+ ((valuefromMaps('arce__non_customer_type__c',mapOfMaps,index))== '1' ?'true':'false')+'';
            toRet += index == mapOfMaps.size()-1 ? '}' : '},';
            index++;
        }
        return toRet;
    }
    /*------------------------------------------------------------------------------------------------------
    *@Description Method to transform map of maps to Strging for service
    * -----------------------------------------------------------------------------------------------------
    * @Author   Ricardo Almanza
    * @Date     2020-06-02
    * @param    Map<String,Map<String,String>> mapOfMaps of variables to add to map
    * @return   String json to add to service
    * @example  buildJsonTbl(geogrMap)
    * */
    private static String buildJsonShar(Map<String,Map<String,String>> mapOfMaps) {
        String toRet = '';
        Integer index=0;
        for (String mapS : mapOfMaps.keySet()) {
            toRet += '{\\"fullName\\": \\"'+valuefromMaps('arce__Third_Participant_id__r.Name',mapOfMaps,index)+'\\",';
            toRet += '\\"percentage\\": \\"'+valuefromMaps(TPI,mapOfMaps,index)+'\\",';
            toRet += '\\"hasControl\\": \\"'+valuefromMaps('arce__shrhldr_financial_sponsor_type__c',mapOfMaps,index)+'\\",';
            toRet += '\\"joinDate\\": \\"'+valuefromMaps('arce__shareholder_sponsor_year_id__c',mapOfMaps,index)+'\\"';
            toRet += index == mapOfMaps.size()-1 ? '}' : '},';
            index++;
        }
        return toRet;
    }
    /*------------------------------------------------------------------------------------------------------
    *@Description Method to transform map of maps to Strging for service
    * -----------------------------------------------------------------------------------------------------
    * @Author   Ricardo Almanza
    * @Date     2020-06-02
    * @param    Map<String,Map<String,String>> mapOfMaps of variables to add to map
    * @return   String json to add to service
    * @example  buildJsonTbl(geogrMap)
    * */
    private static String buildJsonTbl(Map<String,Map<String,String>> mapOfMaps) {
        String toRet = '';
        Integer index=0;
        for (String mapS : mapOfMaps.keySet()) {
            toRet += '{\\"id\\": \\"'+valuefromMaps('arce__table_content_year__c',mapOfMaps,index)+'\\",';
            toRet += '\\"name\\": \\"'+valuefromMaps('arce__Data_Collection_Id__r.Name',mapOfMaps,index)+'\\",';
            toRet += '\\"value\\": '+valuefromMaps('arce__table_content_percentage__c',mapOfMaps,index)+'';
            toRet += index == mapOfMaps.size()-1 ? '}' : '},';
            index++;
        }
        return toRet;
    }
    /*------------------------------------------------------------------------------------------------------
    *@Description Method to transform object to map getSobjectVars
    * -----------------------------------------------------------------------------------------------------
    * @Author   Ricardo Almanza
    * @Date     2020-06-02
    * @param    sObject[] objLst array of object to obtain fields
    * @param    String[] flds field names to obtain and add to the map
    * @return   Map<String,Map<String,String>> map of fields resulting of the object
    * @example  getSobjectVars()
    * */
    public static Map<String,Map<String,String>> getSobjectVars (sObject[] objLst,String[] flds) {
        Final Map<String,Map<String,String>> vars = new Map<String,Map<String,String>>();
        for(SObject obj : objLst) {
            Final Map<String,String> varsObj = new Map<String,String>();
            for(String fld : flds) {
                if(fld.contains('.')) {
                    Final List<String> fldlst = fld.split('\\.');
                    varsObj.put(fld, String.valueOf(obj.getSobject(fldlst[0]).get(fldlst[1])));
                } else {
                    varsObj.put(fld,String.valueOf(obj.get(fld)));
                }
            }
            vars.put(String.valueOf(obj.get('Id')),varsObj);
        }
        return vars;
    }
    /*------------------------------------------------------------------------------------------------------
    *@Description Method to transform string to array of fields codeTerm2ApiList
    * -----------------------------------------------------------------------------------------------------
    * @Author   Ricardo Almanza
    * @Date     2020-06-02
    * @param    String flds comma separated
    * @return   String[] array of fields coma separated
    * @example  codeTerm2ApiList()
    * */
    public static String[] codeTerm2ApiList (String fldsLst) {
        String toret = fldsLst;
        toret = 'Id,'+toret;
        toret = toret.replace(',', ',arce__');
        toret = 'Name,'+toret;
        return toret.split(',');
    }
    /*------------------------------------------------------------------------------------------------------
    *@Description Method to transform map to value of fields valuefromMaps
    * -----------------------------------------------------------------------------------------------------
    * @Author   Ricardo Almanza
    * @Date     2020-06-02
    * @param    String fld field name to obtain
    * @param    Map<String,String>> basemap map in whom to obtain field
    * @return   String Value from map on the specific field
    * @example  valuefromMaps()
    * */
    public static String valuefromMaps (String fld,Map<String,Map<String,String>> basemap,Integer indexSet) {
        Final List<String> sets = new List<String>(basemap.keySet());
        String ret;
        try {
            ret=basemap.get(sets[indexSet]).get(fld);
        } catch(Exception e) {
            ret='';
        }
        return ret;
    }
    /**
    * -----------------------------------------------------------------------------------------------
    * @Description - Method that returns a jason boolean  value
    * -----------------------------------------------------------------------------------------------
    * @Author   Bertha Elena Téllez Lira  berthaelena.tellez.contractor@bbva.com
    * @Date     Created: 18/03/2020
    * @param value - String with value of picklist
    * @return boolean
    * @example changeValue(value)
    * -----------------------------------------------------------------------------------------------
    **/
    public Static String changeValue(string value) {
        String result = 'false';
        if(!String.isEmpty(value)&& value == '1') { result = 'true';}
        return result;
    }
}