/**
* ------------------------------------------------------------------------------------------------
* @Name     MX_CGMT_Subsidiarias_Ctrl
* @Author   Luis González luisalberto.gonzalez.rojas@bbva.com
* @Date     2025-04-21
* @Group    Client & Group Mgm Tool
* -----------------------------------------------------------------------------------------------
* @Description Clase controller para alimentar el Integration Procedure CGMT_getGroupDetall
* -----------------------------------------------------------------------------------------------
* @Changes
* 2025-04-21   luisalberto.gonzalez.rojas@bbva.com
*              Creación de clase.
* -----------------------------------------------------------------------------------------------
*/
global with sharing class MX_CGMT_Subsidiarias_Ctrl implements Callable {
    /**
    @Description Cadena con el nombre del mapa a retornar en el method invokeMethod dedicado a grupos
    @Author      Luis Alberto González Rojas - luisalberto.gonzalez.rojas@bbva.com
    **/
    final static String DATAGCS = 'returnGetDataGCS';
    /**
    @Description Cadena con el nombre del mapa a retornar en el method invokeMethod dedicado a subsidiarias
    @Author      Luis Alberto González Rojas - luisalberto.gonzalez.rojas@bbva.com
    **/
    final static String T_SUBS = 'getTableSubsidiary';
    /**
    @Description Cadena con el nombre del mapa a retornar en el method invokeMethod dedicado a la paginación
    @Author      Luis Alberto González Rojas - luisalberto.gonzalez.rojas@bbva.com
    **/
    final static String T_PAGES = 'returnGetDataPages';
    /**
    @Description Cadena con la palabra input usada como parámetro
    @Author      Luis Alberto González Rojas - luisalberto.gonzalez.rojas@bbva.com
    **/
    final static String INPUT = 'input';
    /**
    @Description Cadena con la palabra output usada como parámetro
    @Author      Luis Alberto González Rojas - luisalberto.gonzalez.rojas@bbva.com
    **/
    final static String OUTPUT = 'output';
    /**
    @Description Cadena con la palabra options usada como parámetro
    @Author      Luis Alberto González Rojas - luisalberto.gonzalez.rojas@bbva.com
    **/
    final static String OPTIONS = 'options';
    /**
    @Description Cadena con la palabra Error usada para gestionar excepciones
    @Author      Luis Alberto González Rojas - luisalberto.gonzalez.rojas@bbva.com
    **/
    final static String ERROR = 'ERROR';
    /**
    @Description Conjunto tipo enum que específica el method a ejecutar
    @Author      Luis Alberto González Rojas - luisalberto.gonzalez.rojas@bbva.com
    */
    private enum METHODS {GETTABLESSUBSIDIARIES, GETTABLESGROUP, GETTABLESPAGES, GETEXCEPTION}
    /**
    *-------------------------------------------------------------------------------------------------------
    * @Description Objeto que estructura los parámetros a enviar hacia el method invokeMethod
    *-------------------------------------------------------------------------------------------------------
    * @Author      Luis González luisalberto.gonzalez.rojas@bbva.com
    * @Date        2025-04-21
    * @param       String action - Nombre de la acción a ejecutar
    * @param       Map<String, Object> - Argumentos que contienen información de salida, entrada y datos adicionales
    * @return      invokeMethod - Retorna un wrapper ya estructurado resultado del method invokeMethod
    * @example     MX_CGMT_Subsidiarias_Ctrl.call(action, args)
    **/
    public Object call(String action, Map<String, Object> args) {
        Map<String, Object> input = (Map<String, Object>)args.get(INPUT);
        Map<String, Object> output = (Map<String, Object>)args.get(OUTPUT);
        Map<String, Object> options = (Map<String, Object>)args.get(OPTIONS);
        return invokeMethod(action, input, output, options);
    }
    /**
    *-------------------------------------------------------------------------------------------------------
    * @Description Method que redirige a otro method dependiendo del parámetro methodName
    *-------------------------------------------------------------------------------------------------------
    * @Author      Luis González luisalberto.gonzalez.rojas@bbva.com
    * @Date        2025-04-21
    * @param       String methodName - Nombre del method a ejecutar
    * @param       Map<String, Object> inputMap - Contiene la información extraida del Integration Procedure
    * @param       Map<String, Object> outMap - Contiene la información a completar para poder ser retornada
    * @param       Map<String, Object> options - Recibe parámetros opcionales configurados en el Integration Procedure
    * @return      Map<String, Object> outMap - Contiene la información a retornar ya estructurada
    * @example     MX_CGMT_Subsidiarias_Ctrl.invokeMethod(methodName, inputMap, outMap, options)
    **/
    private Object invokeMethod(String methodName, Map<String, Object> inputMap, Map<String, Object> outMap, Map<String, Object> options) {
        try {
            final METHODS method = METHODS.valueOf(methodName.toUpperCase());
            switch on (method) {
				when GETTABLESSUBSIDIARIES {
                    outMap.put(T_SUBS, MX_CGMT_Subsidiarias_Service.getDataTableSubsidiaries(inputMap));
                } when GETTABLESPAGES {
                    outMap.put(T_PAGES, MX_CGMT_Subsidiarias_Service.getDataTablePagination(inputMap));
                } when else {
                     outMap.put(ERROR, MX_CGMT_Subsidiarias_Service.getDataTableSubsidiaries(inputMap));
                }
            }
        } catch (Exception e) {
            outMap.put(ERROR, e.getMessage());
        }
        return outMap;
    }    
}