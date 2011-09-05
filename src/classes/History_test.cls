@isTest
private class History_test {
	
	static testmethod void testContactHistory(){
		Contact newContact = new Contact(LastName = 'Bob');
		
		insert newContact;
		
		History objHistory = new History(newContact);
		objHistory.buildEntries();
		System.assertEquals(0,objHistory.events.size());
		
		newContact.firstName = 'first name';
		update newContact;
		
		ContactHistory thisHistory = new ContactHistory(ContactId = newContact.id, field = 'created');
		insert thisHistory;
		
		History.FieldHistory thisUpdate = new History.FieldHistory(null, 'oldVal', 'newVal', DateTime.now(), 'firstName');
		objHistory.injectedResults = new List<History.FieldHistory>{ thisUpdate };
		
		objHistory.buildEntries(); 
		System.debug('\nContact History: '+objHistory.events);
		
	}
}