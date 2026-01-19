/**
  * Project:           BBVA
  * Description:       Clase InboundEmailWrapper
  *
  *            No.     Date            Author                  Description
  *            -----   ----------      --------------------    ---------------
  * @version   1.1     2020-03-23      Victor Velandia (VV)    Class InboundEmailWrapper for Sonar
  ***********************************************************************************/
public with sharing class InboundEmailWrapper { //NOSONAR
  /**
  * description: email
  */
  public Messaging.InboundEmail email {get;set;}
  /**
  * description: envelope
  */
  public Messaging.InboundEnvelope envelope {get;set;}
  /**
  * description: body
  */
  public Blob body {get;set;}
  /**
  * description: gui
  */
  public String gui {get;set;}
  /**
  * description: subject
  */
  public String subject {get;set;}
  /**
  * description: sender
  */
  public String sender {get;set;}
  /**
  * description: toAddress
  */
  public String toAddress {get;set;}
  /**
  * description: ccAddress
  */
  public String ccAddress {get;set;}
  /**
  * description: textBody
  */
  public String textBody {get;set;}
  /**
  * description: cacheKey
  */
  public String cacheKey {get;set;}
  /**
  * description: messageID
  */
  public String messageID {get;set;}
  /**
  * description: reference
  */
  public String reference {get;set;}
  /**
  * description: definedToAddressesNum
  */
  public Integer definedToAddressesNum {get;set;}
  /**
  * description: definedCcAddressesNum
  */
  public Integer definedCcAddressesNum {get;set;}
  /**
  * description: definedToAddresses
  */
  public List<String> definedToAddresses {get;set;}
  /**
  * description: definedCcAddresses
  */
  public List<String> definedCcAddresses {get;set;}
  /**
  * description: headers
  */
  public Map<String,String> headers {get;set;}
  /**
  * description: addresses
  */
  public Map<String,List<String>> addresses {get;set;}
    
  /**
  * description: addresses
  */
  public String businessType {get;set;}
  /**
  * description: InboundEmailWrapper
  */
  public InboundEmailWrapper(Messaging.InboundEmail email,Messaging.InboundEnvelope envelope) {
    this.email = email;
    this.subject = this.email.subject;
    this.sender = this.email.fromAddress;

    this.envelope = envelope;
    this.mapHeaders();
    this.mapAddresses();
    this.toAddress = String.join(this.addresses.get('to'), ';');
    this.ccAddress = String.join(this.addresses.get('cc'), ';');
    this.parseBody();
    this.generateCacheKey();
  }
  /**
  * description: mapAddresses
  */
  public Map<String,List<String>> mapAddresses() {
    final Map<String,List<String>> addresses = new Map<String,List<String>>();
      if(this.email.toAddresses == null) {
        addresses.put('to',new List<String>());
      } else {
          addresses.put('to',this.email.toaddresses);
      }
      if(this.email.ccaddresses == null) {
        addresses.put('cc',new List<String>());
      } else {
          addresses.put('cc',this.email.ccaddresses);
      }
      this.addresses = addresses;
      return addresses;
  }

  /**
  * description: mapHeaders
  */
  public Map<String,String> mapHeaders() {
    final Map<String,String> headers = new Map<String,String>(); //Map to return
    for(Messaging.InboundEmail.Header header : this.email.headers) { //Iterate over the Messaging.InboundEmail record headers list
      headers.put(header.name, header.value); //Map each header using its name as key and storing its value
    }
    this.headers = headers;
    if(headers.containsKey('Message-ID') && String.isNotBlank(headers.get('Message-ID'))) {
      this.messageID = headers.get('Message-ID');
    } else if(String.isnotblank(this.email.messageId)) {
      this.messageID = this.email.messageId;
    } else {
      this.messageID = this.email.subject+this.email.fromAddress;
    }
    return headers; //Return the map
  }

  /**
  * description: countDefinedAddresses
  */
  public void countDefinedAddresses(Set<String> defined) {
    Set<String> definedToAddresses,definedCcAddresses;
    if(this.email.toaddresses == null) {
        definedToAddresses = new Set<String>(); //NOSONAR
    } else {
      definedToAddresses = new Set<String>(this.email.toaddresses);
      System.debug('DTA'+definedToAddresses);
      System.debug('DEFINED'+defined);
      definedToAddresses.retainAll(defined);
    }
    if(this.email.ccaddresses == null) {
      definedCcAddresses = new Set<String>();//NOSONAR
    } else {
      definedCcAddresses = new Set<String>(this.email.ccaddresses);
      definedCcAddresses.retainAll(defined);
    }
    System.debug('DTA'+definedToAddresses);
    this.definedToAddresses = new List<String>(definedToAddresses);
    this.definedToAddressesNum = this.definedToAddresses.size();
    this.definedCcAddresses = new List<String>(definedCcAddresses);
    this.definedCcAddressesNum = this.definedCcAddresses.size();
  }

  /**
  * description: parseBody
  */
  public void parseBody() {
    Blob body;
    String textBody;
    if(String.isNotBlank(this.email.HtmlBody)) {
      System.debug('HTMLBODY INFORMADO -->');
      body = Blob.valueOf(this.email.HtmlBody);
      textBody = this.email.HtmlBody;
      System.debug(textbody);
    } else if(String.isNotBlank(this.email.PlainTextBody)) {
      System.debug('HTMLBODY NO INFORMADO -->');
      body = Blob.valueOf(this.email.PlainTextBody);
      textBody = this.email.PlainTextBody;
      System.debug(textbody);
    } else {
      body = Blob.valueOf('');
      textBody = '';
      System.debug(textbody);
    }
    this.body = body;
    this.textBody = textBody;
  }

  /**
  * description: generateCacheKey
  */
  public void generateCacheKey() {
    if(String.isBlank(this.messageId)) {
      this.cacheKey = ''; //Set the class var value to blank due to null messageid
    } else {
      final Blob referenceBlob = Blob.valueOf(this.messageId); //Blob value of the reference to pass to crypto method
      final Blob encryptedKey = Crypto.generateDigest('MD5',referenceBlob); //Converts the blob into MD5 format string(Still too long to be a cache key)
      final String keyHexValue = EncodingUtil.converttohex(encryptedKey); //Converts MD5 string to hexadecimal string, now it's ready to be a cache key.
      this.cacheKey = keyHexValue; //Set the class var value
    }
  }
}