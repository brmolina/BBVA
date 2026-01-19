/****************************************************************
Name:           MatrixTreeGridReportCnt class
Description:    Return a table to be displayed in treegrid grouping by families and products (X) and countries/regions (Y)
Apex Tests:     MatrixTreeGridReportCntTest

Version        Date            Author            Summary of changes
-------------------------------------------------------------------
0.1            07/11/2018      Global Desktop - APC         Initial Version (old name: PotencialBBVAPotencialController)
0.2            11/12/2018      Global Desktop - APC         Now it can be filtered by countries (default value from cmp) or by regionsç
0.3            27/12/2018      Global Desktop - APC         Componetizado y generalista
*****************************************************************/
public with sharing class MatrixTreeGridReportCnt {

    /*
    * mapFV
    */
    private static Map<String, List<Decimal>> mapFV = new Map<String, List<Decimal>>();
    /*
    * mapFullFamilies
    */
    private static Map<String, Map<String, List<Decimal>>> mapFullFamilies = new Map<String, Map<String, List<Decimal>>>();
    /*
    * wrapperParams
    */
    private static Params wrapperParams = new Params();


    /*SINGLETON PATTERN*/
    private static MatrixTreeGridReportCnt instance;

    /*Constructor de la clase*/
    private MatrixTreeGridReportCnt() {
		System.debug('empty constructor singletton pattern MatrixTreeGridReportCnt');
	}

	/*Instancia de la clase*/
	public static MatrixTreeGridReportCnt getInstance() { //NOSONAR
        if (instance == null) {
            instance = new MatrixTreeGridReportCnt();
        }
        return instance;
    }


    /*
    * object Labels
    */
    private class Labels {
        /*
        * labelFirstGr
        */
    	private String labelFirstGr;
        /*
        * labelSecondGr
        */
    	private String labelSecondGr;
        /*
        * fieldFirstGr
        */
    	private String fieldFirstGr;
        /*
        * fieldSecondGr
        */
    	private String fieldSecondGr;
        /*
        * labelTotalColumn
        */
    	private String labelTotalColumn;
        /*
        * fieldRowPrimary
        */
    	private String fieldRowPrimary;
        /*
        * fieldRowChild
        */
    	private String fieldRowChild;
        /*
        * fieldDecimalVal
        */
    	private String fieldDecimalVal;
    }
    /*
    * Object Params
    */
    private class Params {
        /*
        * recordId
        */
    	private String recordId;
        /*
        * columnsGroupBy
        */
    	private String columnsGroupBy;
        /*
        * queryInput
        */
    	private String queryInput;
        /*
        * labels
        */
    	private Labels labels;
    }
    /*
    * Object Params
    */
    private class WrCells {
        /*
        * setFiltrado
        */
    	Final private Set<String> setFiltrado;
        /*
        * mapCells
        */
    	Final private Map<String, Decimal> mapCells;
        /*
        * constructor WrCells(WrapperRow row, List<WrapperRow> lstHijos)
        */
        public WrCells(Map<String, Decimal> mapCells, Set<String> setFiltrado) {
            this.setFiltrado = setFiltrado;
            this.mapCells = mapCells;
        }
    }

    /*
    * @author Global Desktop
    * Description: getInfo
    * @Params: String attributes which will be parsed to Params Apex Object

    notas:  DES_Type__c, DES_Region__c, SOLUTION_CATEGORY_NAME__c
	         familia,      region       y producto
    */
    @auraEnabled
    public static String getInfo(String attributes) {
        try {
            System.debug('::attributes json: ' + JSON.serialize(attributes));
            wrapperParams = (Params)JSON.deserialize(attributes, Params.class);
            System.debug('::wrapperParams: ' + JSON.serialize(wrapperParams));
            String answer;
            if(wrapperParams != null && wrapperParams.labels != null) {
            	Final String mode = wrapperParams.columnsGroupBy;
	            String queryByRecord = wrapperParams.queryInput;
	            queryByRecord = queryByRecord.replaceAll('@THISRECORD@', '\'' + String.escapeSingleQuotes(wrapperParams.recordId) + '\'');
	            System.debug('::::queryByRecord fixed: '+ queryByRecord);
	            List<sObject> lstRowsResult = Database.query(queryByRecord);//NOSONAR TODO
	            System.debug('::::lstRowsResult: ' + lstRowsResult);
	            Final String modo = mode.toUpperCase('EN');
	            System.debug('::::::::::modemodemodemode: ' + mode + ' => ' + modo);

	            if(!lstRowsResult.isEmpty()) {
                    Final String columnTotalName = (wrapperParams.labels.labelTotalColumn == null) ? 'GLOBAL' : wrapperParams.labels.labelTotalColumn;

                    Final WrCells wrCells = fillMapCells(lstRowsResult, mode, modo);
                    Final Set<String> setFiltrado = wrCells.setFiltrado;
                    Final Map<String, Decimal> mapCells = wrCells.mapCells;


	                Final List<String> lstFiltradoSorted = new List<String>(setFiltrado);
	                lstFiltradoSorted.add('AAA_name');//first spot to be used by Name column
	                lstFiltradoSorted.sort();
	                lstFiltradoSorted.add(columnTotalName);//added at the end of the list
	                lstFiltradoSorted.set(0, 'NAME');

	                System.debug('::::set de filtrado: ' + setFiltrado);
	                System.debug('::::lstFiltradoSorted: ' + lstFiltradoSorted);

                    answer = getTheAnswer(mapCells, lstFiltradoSorted);
                }
            }
            return answer;
        } catch (Exception exc) {
            throw new AuraHandledException(Label.DES_Error + exc);
        }
    }
    /*
    * @author Global Desktop  valores de productos por paises
    * Description: getTheAnswer
    * @Params:  Map<String, Decimal> mapCells, List<String> lstFiltradoSorted
    */
    private static String getTheAnswer(Map<String, Decimal> mapCells, List<String> lstFiltradoSorted) {
        //wrapper to be returned: init
        List<WrapperData> listWrapperData;
        //wrapper used by columns
        List<WrapperColumns> columnas;
        String answer;
        if(!mapCells.isEmpty()) {
            listWrapperData = fillLstWrData(mapCells, lstFiltradoSorted);
            columnas = getColumns(lstFiltradoSorted);
        }

        if(columnas != null && listWrapperData != null) {
            answer = createResponse(columnas, listWrapperData);
        }
        return answer;
    }

    /*
    * @author Global Desktop   valores productos -> paises
    * Description: fillLstWrData
    * @Params:  List<sObject> lstRowsResult, String mode, String modo
    */
    private static List<WrapperData> fillLstWrData(Map<String, Decimal> mapCells, List<String> lstFiltradoSorted) {
        List<WrapperData> listWrapperData = new List<WrapperData>();
        System.debug('::::mapCells start: ' + JSON.serialize(mapCells));
        Final Set<String> setKeys = mapCells.keySet();
        Map<String, List<Decimal>> mapChildRows = new Map<String, List<Decimal>>();//row de producto - mapProductoRow
        Final Map<String, List<String>> mapFamilyRows = new Map<String, List<String>>(); //sumatorios individuales por familia
        List<Decimal> lstChildrenRows = new List<Decimal>(); //lstValoresProducto
        //recorre los productos con la clave

        for(String key : setKeys) {
            
            //descompone la clave
            Final List<String> lstKeys = key.split('@@');
            
            //retorna la informacion segun la familia      ejemplo DM {0,324,90}
            lstChildrenRows = mapChildRows.get(lstKeys[2]+'@@'+lstKeys[0]);

           //si no tiene datos llena todo en 0 inicialmente
            if(lstChildrenRows == null) {
                lstChildrenRows = new List<Decimal>();
                for(Integer i = 0; i < lstFiltradoSorted.size(); i++) {
                    lstChildrenRows.add(0);
                }
            }
            System.debug('::::key: ' + key);
            System.debug('::::lstChildrenRows PRE: ' + lstChildrenRows);
            //b) populating list of each product (=row) by its values
            //valida si la clave del producto tiene el pais de la lista

            if(lstFiltradoSorted.contains(lstKeys[1])) {
                //si la clave del producto contiene el pais se optiene la pocision
                Final Integer posicion = lstFiltradoSorted.indexOf(lstKeys[1]);
                if(posicion != -1) {
                    //en la lista de valores 
                    lstChildrenRows.set(posicion, mapCells.get(key));
                }
            }
            //WD CAMBIO 1 key familia> producto
            mapChildRows.put(lstKeys[2]+'@@'+lstKeys[0], lstChildrenRows);//producto y valores SE ESTAN SOBRE ESCRIBIENDO DATOS

            List<String> lstAuxProd = mapFamilyRows.get(lstKeys[2]);
            if(lstAuxProd == null) {
                lstAuxProd = new List<String>();
            }
            if(!lstAuxProd.contains(lstKeys[0])) {
                lstAuxProd.add(lstKeys[0]);
            }
            mapFamilyRows.put(lstKeys[2], lstAuxProd);//mapa falimia producto
        }
        //sumatorio global por producto ¡
        System.debug('::::PREmapChildRows: JSON FINAL' + JSON.serialize(mapChildRows));
        mapChildRows = calculateGlobalByRows(mapChildRows);//calcula el total de la sumatoria por producto


        System.debug('::::mapChildRows: JSON FINAL' + JSON.serialize(mapChildRows));
        System.debug('::::mapFamilyRows JSON: ' + JSON.serialize(mapFamilyRows));

        if(!mapChildRows.isEmpty()) {
            generateMapFamiliaMapProductRevenues(mapFamilyRows, mapChildRows);
            listWrapperData = populateWrapperData(listWrapperData);
        }
        return listWrapperData;
    }
    /*
    * @author Global Desktop
    * Description: fillMapCells
    * @Params:  List<sObject> lstRowsResult, String mode, String modo
    */
    private static WrCells fillMapCells(List<sObject> lstRowsResult, String mode, String modo) {
        Map<String, Decimal> mapCells = new Map<String, Decimal>();//celdas individuales por producto - mapProductRevenues
        Final Set<String> setFiltrado = new Set<String>();
      //  system.debug('#WD SUM1===# lstRowsResult===='+lstRowsResult+' #model#=='+mode+'#modo#=='+modo);
      
        for(sObject row : lstRowsResult) {
      /*      system.debug('#wrapperParams.labels.labelFirstGr#=='+wrapperParams.labels.labelFirstGr);
            system.debug('#wrapperParams.labels.labelSecondGr#=='+wrapperParams.labels.labelSecondGr);
            system.debug('#wrapperParams.labels.fieldFirstGr#=='+wrapperParams.labels.fieldFirstGr);
*/
            if(mode == wrapperParams.labels.labelFirstGr) { //'COUNTRY') {
                setFiltrado.add((String)row.get(wrapperParams.labels.fieldFirstGr));//'DES_Country__c'));
            } else if(mode == wrapperParams.labels.labelSecondGr) {//'REGION') {
                setFiltrado.add((String)row.get(wrapperParams.labels.fieldSecondGr));//region));
            }
            //sumatorio producto por region
            mapCells = calculateSumBySlot(row, mapCells, modo);
        }

        system.debug('#SUMAPOR REGION#=='+mapCells);
        system.debug('#SUMAPOR setFiltrado#=='+setFiltrado);

        return new WrCells(mapCells, setFiltrado);
    }
    /*
    * @author Global Desktop
    * Description: populateWrapperData
    * @Params:  List<WrapperData> lstDataInput
    */
    private static List<WrapperData> populateWrapperData(List<WrapperData> lstDataInput) {
        Final List<WrapperData> listWrapperData = lstDataInput;

        WrapperRow row;
        if(!mapFV.isEmpty()) {
            Final List<WrapperRow> children = new List<WrapperRow>();
            for (String familia : mapFV.keySet()) {//familia o pais tras update
                children.clear();
                Final WrapperRow fam = new WrapperRow(familia, mapFV.get(familia));
                System.debug('::::rowFamilia: ' + fam);
                if(mapFullFamilies.containsKey(familia)) {
                    System.debug('::::mapFULLFILA===: ' + mapFullFamilies.get(familia));
                    Final Map<String, List<Decimal>> mPV = mapFullFamilies.get(familia);
                    Final Set<String> setProducts = mPV.keySet();
                    for(String product : setProducts) {
                        row = new WrapperRow(product, mPV.get(product));
                        children.add(row);
                    }
                }
                Final WrapperData wrapperRowFams = new WrapperData(fam, children);
                System.debug('::::wrapperRowFams: ' + wrapperRowFams);
                listWrapperData.add(wrapperRowFams);
            }
        }
        return listWrapperData;
    }
     /*
    * @author Global Desktop
    * Description: createResponse
    * @Params:  List<WrapperColumns> columnas, List<WrapperData> listWrapperData
    */
    private static String createResponse(List<WrapperColumns> columnas, List<WrapperData> listWrapperData) {
        //global wrapper
        Final WrapperGlobalTableData wrapperGlobal = new WrapperGlobalTableData(columnas, listWrapperData);
        Final String jsonGlobal = JSON.serialize(wrapperGlobal);
        System.debug('::::wrapperGlobal antes de fix: ' + jsonGlobal);

        return helperFixerJson(jsonGlobal);
    }
    /*
    * @author Global Desktop
    * Description: generateMapFamiliaMapProductRevenues
    * @Params: Map<String, List<String>> mapFP, Map<String, List<Decimal>> mapPV
      mapFP familia -> lista den nombre de productos
      mapPV ->productos y valores
    */
    private static void generateMapFamiliaMapProductRevenues(Map<String, List<String>> mapFP, Map<String, List<Decimal>> mapPV) {
        Final Set<String> lstFamilias = mapFP.keySet();
        List<String> lstProductos = new List<String>();
        List<Decimal> lstValores = new List<Decimal>();
        Map<String, List<Decimal>> mapPVFiltered;

        //WD recorre las familias
        for(String familia : lstFamilias) {
            lstProductos = mapFP.get(familia);
            mapPVFiltered = new Map<String, List<Decimal>>();
            //WD recorre los productos por familias

            for(String producto : lstProductos) {
                //WD CAMBIO 2
                lstValores = mapPV.get(familia+'@@'+producto);
                //calcula sumatorio en lstValores
                mapFV = populatingMapFV(familia, lstValores);

                //MapFV2(F,MapPV<P,V)
                if(lstProductos.contains(producto)) {
                    //producto con sus respectivos valores
                    mapPVFiltered.put(producto, lstValores);
                }
                //ingresa la familia con sus respectivos hijos
                mapFullFamilies.put(familia, mapPVFiltered);
            }
        }
        System.debug('::::mapFV FINAL: ' + JSON.serialize(mapFV));
        System.debug('::::mapFullFamilies FINAL: ' + JSON.serialize(mapFullFamilies));
    }
    /*
    * @author Global Desktop
    * Description: populatingMapFV
    * @Params: String familia, List<Decimal> lstValores
    */
    private static Map<String, List<Decimal>> populatingMapFV(String familia, List<Decimal> lstValores) {
        if(lstValores != null) {
            if(mapFV.containsKey(familia)) {
                List<Decimal> lstSumaValues;
                lstSumaValues = mapFV.get(familia);
                lstSumaValues = calculateSumByLists(lstSumaValues ,lstValores);
                mapFV.put(familia, lstSumaValues);
            } else {
                mapFV.put(familia, lstValores);
            }
        }
        return mapFV;
    }
    /*
    * @author Global Desktop
    * Description: calculateSumByLists
    * @Params: List<Decimal> lstSumaValues, List<Decimal> lstValores
    */
    private static List<Decimal> calculateSumByLists(List<Decimal> lstSumaValues, List<Decimal> lstValores) {
        Final List<Decimal> lstSumatorioTotal = new List<Decimal>();
        if(lstSumaValues.size() == lstValores.size()) {
            Decimal auxValor = 0;
            for(Integer i = 0; i < lstValores.size(); i++) {
                auxValor = lstSumaValues[i] + lstValores[i];
                lstSumatorioTotal.add(auxValor);
            }
        }
        System.debug('::::lstSumatorioTotal return: ' + lstSumatorioTotal);
        return lstSumatorioTotal;
    }
    /*
    * @author Global Desktop
    * Description: calculateGlobalByRows
    * @Params: Map<String, List<Decimal>> mapa
    */
    private static Map<String, List<Decimal>> calculateGlobalByRows (Map<String, List<Decimal>> mapa) {
        Decimal auxSumatorio;
        List<Decimal> lstValores = new List<Decimal>();

        Final Set<String> lstKeys = mapa.keySet();
        System.debug('::::lstKeys: ' + JSON.serialize(lstKeys));
        for(String key : lstKeys) {
            auxSumatorio = 0;
            lstValores = mapa.get(key);
            for(Integer i = 0; i < lstValores.size() - 1; i++) {
                auxSumatorio += lstValores[i];
            }
            System.debug('::::auxSumatorio: ' + auxSumatorio);
            lstValores[lstValores.size() - 1] = auxSumatorio;
            System.debug('::::lstValores: ' + lstValores);
            mapa.put(key, lstValores);
        }
        System.debug('::::mapa: ' + JSON.serialize(mapa));
        return mapa;
    }
    /*
    * @author Global Desktop
    * Description: calculateSumBySlot
    * @Params: sObject objeto, Map<String, Decimal> mapCells, String modo
    */
    private static Map<String, Decimal> calculateSumBySlot (sObject objeto, Map<String, Decimal> mapCells, String modo) {
        Decimal auxSumatorio;

        if(modo == wrapperParams.labels.labelFirstGr) { //'COUNTRY') {
        	if(mapCells.containsKey(objeto.get(wrapperParams.labels.fieldRowChild) + '@@' + objeto.get(wrapperParams.labels.fieldFirstGr) + '@@' + objeto.get(wrapperParams.labels.fieldRowPrimary))) {
            	auxSumatorio = mapCells.get(objeto.get(wrapperParams.labels.fieldRowChild) + '@@' + objeto.get(wrapperParams.labels.fieldFirstGr) + '@@' + objeto.get(wrapperParams.labels.fieldRowPrimary));
                auxSumatorio = auxSumatorio + (Decimal)objeto.get(wrapperParams.labels.fieldDecimalVal);//objeto.DES_Revenues__c;
                mapCells.put(objeto.get(wrapperParams.labels.fieldRowChild) + '@@' + objeto.get(wrapperParams.labels.fieldFirstGr) + '@@' + objeto.get(wrapperParams.labels.fieldRowPrimary), auxSumatorio);
	        } else {
                mapCells.put(objeto.get(wrapperParams.labels.fieldRowChild) + '@@' + objeto.get(wrapperParams.labels.fieldFirstGr) + '@@' + objeto.get(wrapperParams.labels.fieldRowPrimary), (Decimal)objeto.get(wrapperParams.labels.fieldDecimalVal));
	        }
    	} else if(modo == wrapperParams.labels.labelSecondGr) {//'REGION') {
    		if(mapCells.containsKey(objeto.get(wrapperParams.labels.fieldRowChild) + '@@' + objeto.get(wrapperParams.labels.fieldSecondGr) + '@@' + objeto.get(wrapperParams.labels.fieldRowPrimary))) {
            	auxSumatorio = mapCells.get(objeto.get(wrapperParams.labels.fieldRowChild) + '@@' + objeto.get(wrapperParams.labels.fieldSecondGr) + '@@' + objeto.get(wrapperParams.labels.fieldRowPrimary));
	            auxSumatorio = auxSumatorio + (Decimal)objeto.get(wrapperParams.labels.fieldDecimalVal);
	            mapCells.put(objeto.get(wrapperParams.labels.fieldRowChild) + '@@' + objeto.get(wrapperParams.labels.fieldSecondGr) + '@@' + objeto.get(wrapperParams.labels.fieldRowPrimary), auxSumatorio);
	        } else {
                mapCells.put(objeto.get(wrapperParams.labels.fieldRowChild) + '@@' + objeto.get(wrapperParams.labels.fieldSecondGr) + '@@' + objeto.get(wrapperParams.labels.fieldRowPrimary), (Decimal)objeto.get(wrapperParams.labels.fieldDecimalVal));
	        }
    	}
        System.debug(':::::::mapCells' + JSON.serialize(mapCells));
        return mapCells;
    }
    /*
    * @author Global Desktop
    * Description: helperFixerJson
    * @Params: String modo
    */
    private static String helperFixerJson(String str) {
        String cadena = str;
        cadena = cadena.replaceAll('children', '_children');
        cadena = cadena.replaceAll(',"_children":\\[\\]', '');
        cadena = cadena.replaceAll('typeReplaceMe', 'type');
        System.debug('::::helperFixerJson: ' + cadena);
        return cadena;
    }
    /*
    * WrapperRow
    */
    public static List<WrapperColumns> getColumns(List<String> lstColumnas) {
        Final List<WrapperColumns> lstWrColumns = new List<WrapperColumns>();
        for(Integer i = 0; i < lstColumnas.size(); i++) {
            Final WrapperColumns wrcolumna = new WrapperColumns(lstColumnas[i], i + 1);
            lstWrColumns.add(wrColumna);
        }
        System.debug('::::getColumns return: ' + lstWrColumns);
        return lstWrColumns;
    }
    /*
    * WrapperRow
    */
    public class WrapperGlobalTableData {
        /*
        * WrapperRow
        */
        private List<WrapperColumns> wrColumns; //NOSONAR - used in client side
        /*
        * WrapperRow
        */
        private List<WrapperData> wrData; //NOSONAR - used in client side
        /*
        * localeCurrency
        */
        private String localeCurrency;//NOSONAR - used in client side
        /*
        * WrapperRow
        */
        public WrapperGlobalTableData(List<WrapperColumns> columns, List<WrapperData> data) {
            this.wrColumns = columns;
            this.wrData = data;
            this.localeCurrency = UserInfo.getDefaultCurrency();
        }
    }
    /*
    * WrapperRow
    */
    public class WrapperColumns {
        /*
        * typeReplaceMe ==> type
        */
        private String typeReplaceMe; //NOSONAR - used in client side
        /*
        * fieldName
        */
        private String fieldName; //NOSONAR - used in client side
        /*
        * label
        */
        private String label; //NOSONAR - used in client side
        /*
        * initialWidth
        */
        private Integer initialWidth; //NOSONAR - used in client side
        /*
        * constructor WrapperColumns(String columna, Integer num)
        */
        public WrapperColumns(String columna, Integer num) {
            if(columna.equalsIgnoreCase('name')) {
                this.typeReplaceMe = 'text';
                this.initialWidth = 250;
                this.label = '';
                this.fieldName = 'name';
            } else {
                this.typeReplaceMe = 'number';
                this.label = columna;
                this.fieldName = 'columna' + num;//String.valueOf(num);
            }
        }
    }
    /*
    * WrapperRow
    */
    public class WrapperRow {
        /*
        * name
        */
        private String name; //NOSONAR - used in client side
        /*
        * lstRevenues
        */
        private List<Decimal> lstRevenues; //NOSONAR - used in client side
        /*
        * WrapperRow constructor (String nombre, List<Decimal> lstValores)
        */
        public WrapperRow(String nombre, List<Decimal> lstValores) {
            if(nombre != null) {
                this.name = nombre;
            }
            if(lstValores != null) {
                this.lstRevenues = lstValores;
            }
        }
    }
    /*
    * WrapperData
    */
    public class WrapperData { //NOSONAR required
        /*
        * lstRevenuesByProduct
        */
        private List<Decimal> lstRevenuesByProduct; //NOSONAR - used in client side
        /*
        * name ej (SOLUTION_CATEGORY_NAME__c)
        */
        private String name; //NOSONAR - used in client side

        /*
        * children - replace by _children before return json
        */
        private List<WrapperData> children = new List<WrapperData>(); //NOSONAR - used in client side
        /*
        * constructor WrapperData(WrapperRow row, List<WrapperRow> lstHijos)
        */   
        public WrapperData(WrapperRow row, List<WrapperRow> lstHijos) { //NOSONAR - required
            
            this.name = row.name; //columna1
            this.lstRevenuesByProduct = row.lstRevenues;
            if(lstHijos != null) {
                for(WrapperRow child : lstHijos) {
                    Final WrapperData hijo = new WrapperData(child, null);
                    this.children.add(hijo);
                }
            }
            Final List<Decimal> lstValores = row.lstRevenues;//= mapRevenuesByProducto.get('key');
             
        }
    }
}