global with sharing class Corporate_Currency
{
    // Use this method to create a standard Map inline rather than 4+ lines of code
    public static Map<String, Object> createMap(String n, Object v) {
        return new Map<string, Object>{
            'name' => n,
            'value' => v
        };
    }
    public static Map<String, Object> getCorporateCurrencyISO() {
    List<Object> variableSettings = new List<Object>();
      Schema.SObjectType targetTypeP = Schema.getGlobalDescribe().get('CurrencyType');
        if (targetTypeP == null) {
            System.debug('CurrencyType doesn\'t exist in the org.');
            return new Map<String, Object>{
            'success' => true,
            'variableSettings' => variableSettings,
            'messages' => new List<String> {''}
            };
        }
            String query2 = 'SELECT IsoCode FROM CurrencyType WHERE IsCorporate = true';
            try {
            SObject corpcurr = Database.query(query2);
            String currencyiso = String.valueOf(corpcurr.get('IsoCode'));

            system.debug('This is the Default Currency: ' + currencyiso);
            ///////////

            return new Map<String, Object>{
              'success' => true,
              'variableSettings' => variableSettings,
              'messages' => new List<String> {'Corporate currency is set to ' + (String)currencyiso + ' '}
            };
            } catch (Exception e) {
            System.debug('something went wrong, no currencies:' + e);
            return new Map<String, Object>{
            'success' => true,
            'variableSettings' => variableSettings,
            'messages' => new List<String> {''}
            };
            }
  }

  /*public static Map<String, Object> getCorporateCurrencyConversionRate() {
    List<Object> variableSettings = new List<Object>();
    Object currencyconversion ;
    try {
      Decimal conversionrate = [SELECT 
      ConversionRate,IsActive,IsCorporate,IsoCode 
      FROM CurrencyType 
      WHERE IsCorporate = true].ConversionRate;

      variableSettings.add(createMap('Corporate_Currency_ConversionRate', conversionrate));
      currencyconversion = conversionrate;
    }
    catch (Exception e) {
      //just in case
      Decimal conversionrate = 1.00;
      variableSettings.add(createMap('Corporate_Currency_ConversionRate', conversionrate));
      currencyconversion = conversionrate;
    }
    return new Map<String, Object>{
            'success' => true,
            'variableSettings' => variableSettings,
            'messages' => new List<String> {' '}
    };
  }*/
}