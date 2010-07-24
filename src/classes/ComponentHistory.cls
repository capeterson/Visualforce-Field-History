public with sharing class ComponentHistory {
	public sObject subject {get; set;}
	public History thisHistory {get; set;}
	
	
	public ComponentHistory(){
	}
	public void getInit(){
		thisHistory = new History(subject);
		thisHistory.buildEntries();
		thisHistory.invertList();
	}
}