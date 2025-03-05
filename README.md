# Oracle Cloud Integration
Houses code for Myrmex's OCI integration. Includes code for:
* OCI's log collections permissions.

## Create OCI Policy Stack
The setup creates an OCI resource manager (ORM) stack which uses terraform to:

* Create policies in order to allow integration hub to get audit logs from different compartments of the tenancy

[![Deploy to Oracle Cloud](https://oci-resourcemanager-plugin.plugins.oci.oraclecloud.com/latest/deploy-to-oracle-cloud.svg)](https://cloud.oracle.com/resourcemanager/stacks/create?zipUrl=https://github.com/AINEXTECH/oracle-cloud-integration/releases/latest/download/myrmex-oci-orm.zip)
