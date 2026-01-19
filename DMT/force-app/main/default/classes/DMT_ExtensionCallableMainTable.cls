public class DMT_ExtensionCallableMainTable implements Callable {
 
    // Dispatch actual methods
    public Object call(String action, Map<String, Object> args) {
      switch on action {
        when 'fetchData' {system.debug('dentri del action 34343434');
            String all = 'ALL';
            List<String> countries = new List<String>();
            countries.add(all);system.debug('dentri del action ');
            system.debug('Args: '+(String)args.get('selectedTab')+ (Id)args.get('clientId')+ ' countries '+ (String)args.get('searchDate')+ (String)args.get('clientPositionsType')+ (String)args.get('page')+ (String)args.get('pageSize'));
          return DMT_HPG_MainTableCustomController.fetchInitialData((String)args.get('selectedTab'), (Id)args.get('clientId'), countries, (String)args.get('searchDate'), (String)args.get('clientPositionsType'), (String)args.get('page'), (String)args.get('pageSize'), '');
        }
        when else {
         throw new ExtensionMalformedCallException('Method not implemented');
        }
      }
    }
 
    public class ExtensionMalformedCallException extends Exception {}
 }