# Data Pipeline
 
A data pipeline script is made up of a few sections:
 1. Set the common variables (lots of boilerplate)
 2. Define a bunch of config files that use these variables
 3. Tell Azure to Initialise all the infrastructure you'll need, including:
	- A Resource Group (to gather your infrastructure under a heading, so you can kill it all easily later)
	- A (blob/data lake) storage account
	- A SQL Server (this is true infrastructure)
	- A Data Factory (this is more of a gathering place for jobs)
	- Note: You could potentially do the above in parallel
 4. Grab the details of the infrastructure, and pass the details to Data Factory. Details include:
	- Linked services files, for example:
		- Storage Linked Services, telling Data Factory where your Blob stoage is
		- SQL DB Linked services
		- HDInsight services, and so on
		
	- Usernames and passwords


