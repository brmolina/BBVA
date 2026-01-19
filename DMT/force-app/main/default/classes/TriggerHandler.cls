/*----------------------------------------------------------------------------------------------------
*Autor:         Framework Kevin Ohara
*Proyecto:
*Descripción:   Clase del Framework Kevin Ohara
*_______________________________________________________________________________________________________
*Versión    Fecha           Autor                               Descripción
*1.0        10/AGO/2017     BBVA Administrador                  Se instala el Framework Kevin Ohara
*1.1        10/ABR/2019     Luis Ruben Quinto 	                Refactorización para quitar complejidad
                                                                para hacer un bypass de forma automatica
*1.2        21/MAY/2021     Otilia Veres Oltean                 Se refatoriza el método 'exceeded' para corregir errores major de sonar qube.
                                                                Se añaden comentarios de documentación.
                                                                Se combinan condiciones de if para corregir errores de sonar.
                                                                Se eliminan variables no usadas.
*1.3        24/MAY/2021     Otilia Veres Oltean                 Se cambia la condición del if a comparación positiva del metodo 'setTriggerContext'.
-------------------------------------------------------------------------------------------------------*/
@SuppressWarnings('sf:TooManyMethods')
public virtual class TriggerHandler {

    /**
    * @Description: static map of handlername, times run() was invoked
    */
    private static Map<String, LoopCount> loopCountMap;

    /**
    * @Description: static map of handlername, times run() was invoked
    */
    private static Set<String> bypassedHandlers;

    /**
    * @Description: the current context of the trigger, overridable in tests
    */
    @TestVisible
    private System.TriggerOperation context;

    /**
    * @Description: the current context of the trigger, overridable in tests
    */
    @TestVisible
    private Boolean isTrExecuting;

    /**
    * --------------------------------------------------------------------------------------
    * @Description static initialization
    * --------------------------------------------------------------------------------------
    * @Author   Diego Miguel  diego.miguel.contractor@bbva.com
    * @Date     Created: 2019-05-01
    * --------------------------------------------------------------------------------------
    **/
    static {
        loopCountMap = new Map<String, LoopCount>();
        bypassedHandlers = new Set<String>();
    }

    /**
    * --------------------------------------------------------------------------------------
    * @Description constructor
    * --------------------------------------------------------------------------------------
    * @Author   Diego Miguel  diego.miguel.contractor@bbva.com
    * @Date     Created: 2019-05-01
    * @example TriggerHandler()
    * --------------------------------------------------------------------------------------
    **/
    public TriggerHandler() {
        this.setTriggerContext();
    }

    /***************************************
    * public instance methods
    ***************************************/
    /**
    * --------------------------------------------------------------------------------------
    * @Description main method that will be called during execution
    * --------------------------------------------------------------------------------------
    * @Author   Diego Miguel  diego.miguel.contractor@bbva.com
    * @Date     Created: 2019-05-01
    * @example run()
    * --------------------------------------------------------------------------------------
    **/
    public void run() {

        if(!validateRun()) {return;}
        addToLoopCount();

        // dispatch to the correct handler method
        switch on this.context {
            when BEFORE_INSERT {
                this.beforeInsert();
            }
            when BEFORE_UPDATE {
                this.beforeUpdate();
            }
            when BEFORE_DELETE {
                this.beforeDelete();
            }
            when AFTER_INSERT {
                this.afterInsert();
            }
            when AFTER_UPDATE {
                this.afterUpdate();
            }
            when AFTER_DELETE {
                this.afterDelete();
            }
            when AFTER_UNDELETE {
                this.afterUndelete();
            }
        }

    }

    /**
    * --------------------------------------------------------------------------------------
    * @Description Set max loop count
    * --------------------------------------------------------------------------------------
    * @Author   Diego Miguel  diego.miguel.contractor@bbva.com
    * @Date     Created: 2019-05-01
    * @param max - intenger variable
    * @return  void
    * @example this.setMaxLoopCount(-1);
    * --------------------------------------------------------------------------------------
    **/
    public void setMaxLoopCount(Integer max) {
        if(TriggerHandler.loopCountMap.containsKey(getHandlerName())) {
            TriggerHandler.loopCountMap.get(getHandlerName()).setMax(max);
        } else {
            TriggerHandler.loopCountMap.put(getHandlerName(), new LoopCount(max));
        }
    }

    /**
    * --------------------------------------------------------------------------------------
    * @Description Clear max loop count
    * --------------------------------------------------------------------------------------
    * @Author   Diego Miguel  diego.miguel.contractor@bbva.com
    * @Date     Created: 2019-05-01
    * @param void
    * @return  void
    * @example this.clearMaxLoopCount();
    * --------------------------------------------------------------------------------------
    **/
    public void clearMaxLoopCount() {
        this.setMaxLoopCount(-1);
    }

    /***************************************
    * public static methods
    ***************************************/
    /**
    * --------------------------------------------------------------------------------------
    * @Description public static method bypass
    * --------------------------------------------------------------------------------------
    * @Author   Diego Miguel  diego.miguel.contractor@bbva.com
    * @Date     Created: 2019-05-01
    * @param handlerName - string variable
    * @return  void
    * @example bypass(handlerName);
    * --------------------------------------------------------------------------------------
    **/
    public static void bypass(String handlerName) {
        TriggerHandler.bypassedHandlers.add(handlerName);
    }

    /**
    * --------------------------------------------------------------------------------------
    * @Description public static method crear Bypass
    * --------------------------------------------------------------------------------------
    * @Author   Diego Miguel  diego.miguel.contractor@bbva.com
    * @Date     Created: 2019-05-01
    * @param handlerName - string variable
    * @return  void
    * @example clearBypass(handlerName);
    * --------------------------------------------------------------------------------------
    **/
    public static void clearBypass(String handlerName) {
        TriggerHandler.bypassedHandlers.remove(handlerName);
    }

    /**
    * --------------------------------------------------------------------------------------
    * @Description public static method is Bypassed
    * --------------------------------------------------------------------------------------
    * @Author   Diego Miguel  diego.miguel.contractor@bbva.com
    * @Date     Created: 2019-05-01
    * @param handlerName - string variable
    * @return  boolean value
    * @example isBypassed(handlerName);
    * --------------------------------------------------------------------------------------
    **/
    public static Boolean isBypassed(String handlerName) {
        return TriggerHandler.bypassedHandlers.contains(handlerName);
    }

    /**
    * --------------------------------------------------------------------------------------
    * @Description public static method to clear All Bypasses
    * --------------------------------------------------------------------------------------
    * @Author   Diego Miguel  diego.miguel.contractor@bbva.com
    * @Date     Created: 2019-05-01
    * @param void
    * @return  void
    * @example clearAllBypasses();
    * --------------------------------------------------------------------------------------
    **/
    public static void clearAllBypasses() {
        TriggerHandler.bypassedHandlers.clear();
    }

    /***************************************
    * private instancemethods
    ***************************************/

    /**
    * --------------------------------------------------------------------------------------
    * @Description private instance method to set Trigger Context
    * --------------------------------------------------------------------------------------
    * @Author   Diego Miguel  diego.miguel.contractor@bbva.com
    * @Date     Created: 2019-05-01
    * @param void
    * @return  void
    * @example setTriggerContext();
    * --------------------------------------------------------------------------------------
    **/
    @TestVisible
    private void setTriggerContext() {
        this.setTriggerContext(null, false);
    }

    /**
    * --------------------------------------------------------------------------------------
    * @Description private instance method to set Trigger Context with parameters
    * --------------------------------------------------------------------------------------
    * @Author   Diego Miguel  diego.miguel.contractor@bbva.com
    * @Date     Created: 2019-05-01
    * @param ctx - System.TriggerOperation variable
    * @param testMode - booblean variable
    * @return  void
    * @example setTriggerContext();
    * --------------------------------------------------------------------------------------
    **/
    @TestVisible
    private void setTriggerContext(System.TriggerOperation ctx, Boolean testMode) {
        if(Trigger.isExecuting || testMode) {
            this.isTrExecuting = true;
        } else {
            this.isTrExecuting = false;
            return;
        }

        this.context = Trigger.operationType == null ? ctx : Trigger.operationType;
        if(this.context == System.TriggerOperation.AFTER_UPDATE && TriggerHandler.loopCountMap.containsKey(getHandlerName())) {
            TriggerHandler.loopCountMap.get(getHandlerName()).incrementCountAfter();
    }
  }

    /**
    * --------------------------------------------------------------------------------------
    * @Description private instance method to increment the loop count
    * --------------------------------------------------------------------------------------
    * @Author   Diego Miguel  diego.miguel.contractor@bbva.com
    * @Date     Created: 2019-05-01
    * @param void
    * @return  void
    * @example addToLoopCount();
    * --------------------------------------------------------------------------------------
    **/
    @TestVisible
    private void addToLoopCount() {
        if(TriggerHandler.loopCountMap.containsKey(getHandlerName())) {
            final Boolean exceeded = TriggerHandler.loopCountMap.get(getHandlerName()).increment();
            if(exceeded) {
                final Integer max = TriggerHandler.loopCountMap.get(getHandlerName()).max;
                throw new TriggerHandlerException('Maximum loop count of ' + max + ' reached in ' + getHandlerName());
            }
        }
    }

    /**
    * --------------------------------------------------------------------------------------
    * @Description private instance method to make sure this trigger should continue to run
    * --------------------------------------------------------------------------------------
    * @Author   Diego Miguel  diego.miguel.contractor@bbva.com
    * @Date     Created: 2019-05-01
    * @param void
    * @return  void
    * @example validateRun();
    * --------------------------------------------------------------------------------------
    **/
    @TestVisible
    private Boolean validateRun() {
        Boolean isValidateRun = true;
        if(!this.isTrExecuting || this.context == null) {
            throw new TriggerHandlerException('Trigger handler called outside of Trigger execution');
        }
        if(TriggerHandler.bypassedHandlers.contains(getHandlerName())) {
            isValidateRun = false;
        } else if(TriggerHandler.loopCountMap.containsKey(getHandlerName()) && TriggerHandler.loopCountMap.get(getHandlerName()).countAfter > 1) {
            //Sergio Ortiz: bypass automatico si ya se ha ingresado al after update del trigger
            TriggerHandler.bypassedHandlers.add(getHandlerName());
            isValidateRun = false;
        } else {
            isValidateRun = true;
        }
        return isValidateRun;
    }

    /**
    * --------------------------------------------------------------------------------------
    * @Description private instance method to get Handler Name
    * --------------------------------------------------------------------------------------
    * @Author   Diego Miguel  diego.miguel.contractor@bbva.com
    * @Date     Created: 2019-05-01
    * @param void
    * @return  handler name
    * @example getHandlerName();
    * --------------------------------------------------------------------------------------
    **/
    @TestVisible
    private String getHandlerName() {
        return String.valueOf(this).substring(0,String.valueOf(this).indexOf(':'));
    }

    /***************************************
    * context methods
    ***************************************/

    /**
    * --------------------------------------------------------------------------------------
    * @Description context-specific method for override
    * --------------------------------------------------------------------------------------
    * @Author   Luis Ruben Quinto Muñoz  luisruben.quinto.munoz@bbva.com
    * @Date     Created: 2019-07-30
    * @param void
    * @return  void
    * @example beforeInsert()
    * --------------------------------------------------------------------------------------
    **/
    @TestVisible
    protected virtual void beforeInsert() {}

    /**
    * --------------------------------------------------------------------------------------
    * @Description context-specific method for override
    * --------------------------------------------------------------------------------------
    * @Author   Luis Ruben Quinto Muñoz  luisruben.quinto.munoz@bbva.com
    * @Date     Created: 2019-07-30
    * @param void
    * @return  void
    * @example beforeUpdate()
    * --------------------------------------------------------------------------------------
    **/
    @TestVisible
    protected virtual void beforeUpdate() {}

    /**
    * --------------------------------------------------------------------------------------
    * @Description context-specific method for override
    * --------------------------------------------------------------------------------------
    * @Author   Luis Ruben Quinto Muñoz  luisruben.quinto.munoz@bbva.com
    * @Date     Created: 2019-07-30
    * @param void
    * @return  void
    * @example beforeDelete()
    * --------------------------------------------------------------------------------------
    **/
    @TestVisible
    protected virtual void beforeDelete() {}

    /**
    * --------------------------------------------------------------------------------------
    * @Description context-specific method for override
    * --------------------------------------------------------------------------------------
    * @Author   Luis Ruben Quinto Muñoz  luisruben.quinto.munoz@bbva.com
    * @Date     Created: 2019-07-30
    * @param void
    * @return  void
    * @example afterInsert()
    * --------------------------------------------------------------------------------------
    **/
    @TestVisible
    protected virtual void afterInsert() {}

    /**
    * --------------------------------------------------------------------------------------
    * @Description context-specific method for override
    * --------------------------------------------------------------------------------------
    * @Author   Luis Ruben Quinto Muñoz  luisruben.quinto.munoz@bbva.com
    * @Date     Created: 2019-07-30
    * @param void
    * @return  void
    * @example afterUpdate()
    * --------------------------------------------------------------------------------------
    **/
    @TestVisible
    protected virtual void afterUpdate() {}

    /**
    * --------------------------------------------------------------------------------------
    * @Description context-specific method for override
    * --------------------------------------------------------------------------------------
    * @Author   Luis Ruben Quinto Muñoz  luisruben.quinto.munoz@bbva.com
    * @Date     Created: 2019-07-30
    * @param void
    * @return  void
    * @example afterDelete()
    * --------------------------------------------------------------------------------------
    **/
    @TestVisible
    protected virtual void afterDelete() {}

    /**
    * --------------------------------------------------------------------------------------
    * @Description context-specific method for override
    * --------------------------------------------------------------------------------------
    * @Author   Luis Ruben Quinto Muñoz  luisruben.quinto.munoz@bbva.com
    * @Date     Created: 2019-07-30
    * @param void
    * @return  void
    * @example afterUndelete()
    * --------------------------------------------------------------------------------------
    **/
    @TestVisible
    protected virtual void afterUndelete() {}

    /***************************************
    * inner classes
    ***************************************/

    /**
    * --------------------------------------------------------------------------------------
    * @Description inner class for managing the loop count per handler
    * --------------------------------------------------------------------------------------
    * @Author   Diego Miguel  diego.miguel.contractor@bbva.com
    * @Date     Created: 2019-05-01
    * @param void
    * @return  handler name
    * @example LoopCount a = new LoopCount();
    * --------------------------------------------------------------------------------------
    **/
    @TestVisible
    private class LoopCount {
        /**
        * @Description: Max Number
        */
        private Integer max;

        /**
        * @Description: Total Count
        */
        private Integer count;

        /**
        * @Description: Count After
        */
        private Integer countAfter;

        /**
        * --------------------------------------------------------------------------------------
        * @Description Loop count
        * --------------------------------------------------------------------------------------
        * @Author   Diego Miguel  diego.miguel.contractor@bbva.com
        * @Date     Created: 2019-05-01
        * @param void
        * @example LoopCount();
        * --------------------------------------------------------------------------------------
        **/
        public LoopCount() {
            this.max = 5;
            this.count = 0;
            this.countAfter = 0;
        }
        /**
        * --------------------------------------------------------------------------------------
        * @Description Loop count with variable max parameter
        * --------------------------------------------------------------------------------------
        * @Author   Diego Miguel  diego.miguel.contractor@bbva.com
        * @Date     Created: 2019-05-01
        * @param max - intenger variable
        * @example LoopCount(8);
        * --------------------------------------------------------------------------------------
        **/
        public LoopCount(Integer max) {
            this.max = max;
            this.count = 0;
            this.countAfter = 0;
        }

        /**
        * --------------------------------------------------------------------------------------
        * @Description Increment
        * --------------------------------------------------------------------------------------
        * @Author   Diego Miguel  diego.miguel.contractor@bbva.com
        * @Date     Created: 2019-05-01
        * @param void
        * @return Is exceeded or not
        * @example Boolean isExceeded = increment();
        * --------------------------------------------------------------------------------------
        **/
        public Boolean increment() {
            this.count++;
            return this.exceeded();
        }

        /**
        * --------------------------------------------------------------------------------------
        * @Description Exceeded
        * --------------------------------------------------------------------------------------
        * @Author   Diego Miguel  diego.miguel.contractor@bbva.com
        * @Date     Created: 2019-05-01
        * @param void
        * @return Is exceeded or not
        * @example Boolean isExceeded = exceeded();
        * --------------------------------------------------------------------------------------
        **/
        public Boolean exceeded() {
            Boolean isExceeded = true;
            if(this.max < 0) {
                isExceeded = false;
            } else if(this.count > this.max) {
                isExceeded = true;
            } else {
                isExceeded = false;
            }
            return isExceeded;
        }

        /**
        * --------------------------------------------------------------------------------------
        * @Description Get Max
        * --------------------------------------------------------------------------------------
        * @Author   Diego Miguel  diego.miguel.contractor@bbva.com
        * @Date     Created: 2019-05-01
        * @param void
        * @return Max Number
        * @example Integer max = getMax();
        * --------------------------------------------------------------------------------------
        **/
        public Integer getMax() {
            return this.max;
        }

        /**
        * --------------------------------------------------------------------------------------
        * @Description Get Count
        * --------------------------------------------------------------------------------------
        * @Author   Diego Miguel  diego.miguel.contractor@bbva.com
        * @Date     Created: 2019-05-01
        * @param void
        * @return Count number
        * @example Integer count = getCount();
        * --------------------------------------------------------------------------------------
        **/
        public Integer getCount() {
            return this.count;
        }

        /**
        * --------------------------------------------------------------------------------------
        * @Description Set Max
        * --------------------------------------------------------------------------------------
        * @Author   Diego Miguel  diego.miguel.contractor@bbva.com
        * @Date     Created: 2019-05-01
        * @param max - max number
        * @return void
        * @example setMax(8);
        * --------------------------------------------------------------------------------------
        **/
        public void setMax(Integer max) {
            this.max = max;
        }

        /**
        * --------------------------------------------------------------------------------------
        * @Description Increment Count After
        * --------------------------------------------------------------------------------------
        * @Author   Diego Miguel  diego.miguel.contractor@bbva.com
        * @Date     Created: 2019-05-01
        * @param void
        * @return void
        * @example incrementCountAfter();
        * --------------------------------------------------------------------------------------
        **/
        public void incrementCountAfter() {
            this.countAfter++;
        }

        /**
        * --------------------------------------------------------------------------------------
        * @Description Get Count After
        * --------------------------------------------------------------------------------------
        * @Author   Diego Miguel  diego.miguel.contractor@bbva.com
        * @Date     Created: 2019-05-01
        * @param void
        * @return Count After Number
        * @example getCountAfter();
        * --------------------------------------------------------------------------------------
        **/
        public Integer  getCountAfter() {
            return this.countAfter;
        }
    }

    /**
    * --------------------------------------------------------------------------------------
    * @Description exception class
    * --------------------------------------------------------------------------------------
    * @Author   Luis Ruben Quinto Muñoz  luisruben.quinto.munoz@bbva.com
    * @Date     Created: 2019-07-30
    * @param void
    * @example TriggerHandlerException a = new TriggerHandlerException();
    * --------------------------------------------------------------------------------------
    **/
  public class TriggerHandlerException extends Exception {}

}