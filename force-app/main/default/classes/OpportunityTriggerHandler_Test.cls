@isTest
public with sharing class OpportunityTriggerHandler_Test {
  private static testMethod void testErrorHandler() {
    Account a = new Account();
    a.Name = 'Test Account';
    insert a;

    Opportunity o = new Opportunity();
    o.Name = 'Test Opportunity';
    o.StageName = 'Closed Won';
    o.AccountId = a.Id;
    o.Amount = 100.0;
    o.CloseDate = Date.today().addYears(1);
    o.Type = 'Existing Business - Renewal';
    insert o;

    List<Opportunity> oppList = new List<Opportunity>{ o };
    OpportunityTriggerHandler.errorHandler(oppList);

    o.Probability = 20;
    update o;

    oppList = new List<Opportunity>{ o };
    OpportunityTriggerHandler.errorHandler(oppList);
    System.assertEquals(1, oppList.size());
    System.assert(oppList[0].HasErrors());
  }

  private static testMethod void testRenewalOppty() {
    Account a = new Account();
    a.Name = 'Test Account';
    insert a;

    Opportunity o = new Opportunity();
    o.Name = 'Test Opportunity';
    o.StageName = 'Closed Won';
    o.AccountId = a.Id;
    o.Amount = 100.0;
    o.CloseDate = Date.today().addYears(1);
    o.Type = 'Existing Business - Renewal';
    insert o;

    Map<Id, Opportunity> newOpptyMap = new Map<Id, Opportunity>{ o.Id => o };
    Map<Id, Opportunity> oldOpptyMap = new Map<Id, Opportunity>();
    List<Opportunity> newOpptyList = new List<Opportunity>{ o };

    OpportunityTriggerHandler.renewalOppty(
      newOpptyList,
      newOpptyMap,
      oldOpptyMap
    );

    List<Opportunity> oppList = [
      SELECT Id, Name
      FROM Opportunity
      WHERE Name = 'Renewal: Test Opportunity'
    ];
    System.assertEquals(1, oppList.size());
    System.assertEquals('Renewal: Test Opportunity', oppList[0].Name);
  }

  private static testMethod void testCheckAccountForOpenOpps() {
    Account a = new Account();
    a.Name = 'Test Account';
    a.AnnualRevenue = 1000;
    insert a;

    Opportunity o = new Opportunity();
    o.Name = 'Test Opportunity';
    o.StageName = 'Prospecting';
    o.AccountId = a.Id;
    o.Amount = 100.0;
    o.CloseDate = Date.today().addDays(10);
    o.Type = 'New Business';
    insert o;

    Opportunity o1 = new Opportunity();
    o1.Name = 'Test Opportunity 1';
    o1.StageName = 'Prospecting';
    o1.AccountId = a.Id;
    o1.Amount = 100.0;
    o1.CloseDate = Date.today().addDays(10);
    o1.Type = 'New Business';
    insert o1;

    List<Opportunity> newOpptyList = new List<Opportunity>{ o, o1 };

    OpportunityTriggerHandler.checkAccountForOpenOpps(newOpptyList);

    List<Opportunity> oppList = [
      SELECT Id, Amount
      FROM Opportunity
      WHERE Id = :o.Id
    ];
    System.assertEquals(200, oppList[0].Amount);
  }
}
