/*******************************************************************************************
 * @Name         ScheduledSWAPIJob
 * @Author       Adam Dalton
 * @Date         01/25/2023
 * @Group        Star Wars API Project
 * @Description  This scheduled apex class contains all of the logic that calls on two other classes that make the HTTP callouts and create the SF records
 *******************************************************************************************/
/* MODIFICATION LOG
 * Version          Developer          Date               Description
 *-------------------------------------------------------------------------------------------
 *  1.0              Adam      01/25/2023          Initial Creation
 *******************************************************************************************/
public with sharing class OpportunityTriggerHandler {
  public static void errorHandler(List<Opportunity> oppList) {
    List<OpportunityLineItem> productList = [
      SELECT Id, OpportunityId
      FROM OpportunityLineItem
      WHERE OpportunityId IN :oppList
    ];
    Map<Id, SObject> productMap = new Map<Id, SObject>();
    for (OpportunityLineItem oppProduct : productList) {
      productMap.put(oppProduct.OpportunityId, oppProduct);
    }
    for (Opportunity opp : oppList) {
      if (opp.Probability > 10 && !productMap.containsKey(opp.Id)) {
        opp.addError('Please enter at least one product for this opportunity');
      }
    }
  }
  /**************************************************************************************
   * @Description  Method that is being used to make the GET request to SWAPI and create the assocaited Star Wars Planet record in Salesforce
   * @Param		     N/A
   * @Return       Void
   * @Example
   **************************************************************************************/
  public static void renewalOppty(
    List<Opportunity> newOpptyList,
    Map<Id, Opportunity> newOpptyMap,
    Map<Id, Opportunity> oldOpptyMap
  ) {
    List<OpportunityLineItem> productList = [
      SELECT
        Id,
        TotalPrice,
        OpportunityId,
        Product2Id,
        PricebookEntryId,
        Quantity
      FROM OpportunityLineItem
      WHERE OpportunityId IN :newOpptyList
    ];

    List<Opportunity> renewalOppList = new List<Opportunity>();
    for (Id oppId : newOpptyMap.keySet()) {
      Opportunity newOpp = newOpptyMap.get(oppId);
      Opportunity oldOpp = oldOpptyMap.get(oppId);
      if (
        newOpp.StageName == 'Closed Won' &&
        oldOpp.StageName != 'Closed Won'
      ) {
        Opportunity renewalOppty = new Opportunity();
        renewalOppty.Name = 'Renewal: ' + newOpp.Name;
        renewalOppty.StageName = 'Value Proposition';
        renewalOppty.ParentOpportunity__c = newOpp.Id;
        renewalOppty.AccountId = newOpp.AccountId;
        renewalOppty.Amount = newOpp.Amount;
        renewalOppty.CloseDate = newOpp.CloseDate.addYears(1);
        renewalOppty.Type = newOpp.Type;
        renewalOppty.LeadSource = newOpp.LeadSource;
        renewalOppty.Description = newOpp.Description;

        renewalOppList.add(renewalOppty);
        System.debug(renewalOppty);
      }
    }
    if (renewalOppList.size() > 0) {
      insert renewalOppList;
    }
    List<Opportunity> insertedOpptys = [
      SELECT Id, ParentOpportunity__c
      FROM Opportunity
      WHERE Id IN :renewalOppList
    ];
    System.debug(insertedOpptys);

    List<OpportunityLineItem> renewalProducts = new List<OpportunityLineItem>();
    if (insertedOpptys.size() > 0) {
      for (Opportunity insertedOpp : insertedOpptys) {
        for (OpportunityLineItem product : productList) {
          if (insertedOpp.ParentOpportunity__c == product.OpportunityId) {
            OpportunityLineItem renewalProduct = new OpportunityLineItem();
            renewalProduct.OpportunityId = insertedOpp.Id;
            renewalProduct.Product2Id = product.Product2Id;
            renewalProduct.PricebookEntryId = product.PricebookEntryId;
            renewalProduct.Quantity = product.Quantity;
            renewalProduct.TotalPrice = product.TotalPrice;
            System.debug(renewalProduct);
            renewalProducts.add(renewalProduct);
          }
        }
      }
    }

    if (renewalProducts.size() > 0) {
      insert renewalProducts;
    }
  }
  //********************************************************* */
  public static void checkAccountForOpenOpps(
    List<Opportunity> newOpportunities
  ) {
    List<Opportunity> opportunitiesToUpdate = new List<Opportunity>();
    Set<Id> accountIds = new Set<Id>();

    // Get the account IDs for all new opportunities
    for (Opportunity opp : newOpportunities) {
      accountIds.add(opp.AccountId);
    }

    // Query for all open opportunities for the same accounts

    List<Opportunity> openOpportunities = [
      SELECT Id, AccountId
      FROM Opportunity
      WHERE
        AccountId IN :accountIds
        AND StageName != 'Closed Won'
        AND StageName != 'Closed Lost'
    ];
    Map<Id, Opportunity> accountOppMap = new Map<Id, Opportunity>();
    for (Opportunity openOpps : openOpportunities) {
      accountOppMap.put(openOpps.AccountId, openOpps);
    }
    System.debug(accountOppMap);

    // Query for the account annual revenue for all accounts in the set
    Map<Id, Account> accountsMap = new Map<Id, Account>(
      [SELECT Id, AnnualRevenue FROM Account WHERE Id IN :accountIds]
    );
    System.debug(accountsMap);

    // Loop through the new opportunities and update as necessary
    for (Opportunity opp : newOpportunities) {
      if (!accountOppMap.containsKey(opp.AccountId)) {
        // Update the opportunity amount to 20% of the account's annual revenue
        Account acc = accountsMap.get(opp.AccountId);
        opp.Amount = acc.AnnualRevenue * 0.2;

        // Send a communication to another user to review the information (you'll need to update the recipient user ID and message)
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        String[] sendingTo = new List<String>{ 'adam.dalton@cloudkettle.com' };
        mail.setToAddresses(sendingTo);
        mail.setSubject('New Opportunity to Review');
        mail.setPlainTextBody(
          'Please review the following opportunity: ' + opp.Name
        );

        try {
          System.debug(' Sending a non-template email.');
          Messaging.sendEmail(new List<Messaging.SingleEmailMessage>{ mail });
        } catch (Exception e) {
          system.debug(
            'Tried to send a non-template email and got an error:  ' + e
          );
        }
      }
    }
  }
}
