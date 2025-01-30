# Azure Function with Datalake and ACL

## Create the resources and deploy the function

Be sure to have the Azure Developer CLI [installed](https://learn.microsoft.com/en-us/azure/developer/azure-developer-cli/install-azd?tabs=winget-windows%2Cbrew-mac%2Cscript-linux&pivots=os-windows)

Clone the repository and inside the root folder execute this command:

```bash
azd up
```

### Create the directory

Go to the new datalake and create the following folder

--doc
   |--> result
   |--> labs

In the doc container in the ACL permission give in the **Access permissions** tab give the righ **Read**, **Write** and **Execute** to the **Other**.

Now for the two subdirectory inside the **doc** container give to the **managed identity** of the Azure Function the **Access Permission** **Read** **Write** and **Execute** and the same for the **default permissions**
