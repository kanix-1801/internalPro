public class AccountPicklistController {
	public String selectedAccountId { get; set; }
    public String selectedAccountName { get; set; }
    
    public List<SelectOption> getAccountOptions() {
        List<SelectOption> options = new List<SelectOption>();
        options.add(new SelectOption('', '--Select Account--'));
        for (Account acc : [SELECT Id, Name FROM Account ORDER BY Name LIMIT 100]) {
            options.add(new SelectOption(acc.Id, acc.Name));
        }
        return options;
    }
    
    public void showSelectedAccount() {
	 		if (String.isBlank(selectedAccountId)) {
                ApexPages.addMessage(
                    new ApexPages.Message(ApexPages.Severity.ERROR, 'Please select an Account.', 'accPicklist')
                );
                selectedAccountName = null;
                return;
            }
        if (String.isNotBlank(selectedAccountId)) {
            Account acc = [SELECT Name FROM Account WHERE Id = :selectedAccountId LIMIT 1];
            selectedAccountName = acc.Name;
        } else {
            selectedAccountName = 'No account selected!';
        }
    }
}