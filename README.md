# What's this?

This code help you connect/operate on DB within Private Network

For example, You have Private Network based on Amazon AWS. And, you'd like to connect RDS within it.

For that, make PortForwarding access and construct RDS....that's troublesome work.

This class do that easily. This is written in R5 class.

# setting up

* 1 copy this repository into your local. `git clone git@github.com:Kensuke-Mitsuzawa/PrivateDbConnection.git`
* 2 change NAT/DB connection inside config/db_connection_settings.yaml
* 3 load PrivateDbConnection.R, and use it

# sample code


```
setwd(path_to_this_repository)
source("PrivateDbConnection/PrivateDbConnection.R")

private_db_connection_obj <- PrivateDbConnection$new("config/db_connection_settings.yaml")
private_db_connection_obj$connection_settings

# construct connection with portforwarding
private_db_connection_obj$OpenNatPortForward()

# create dbconnector object of RMySQL
dbconnector <- private_db_connection_obj$PrepareDbConnection()
print(class(dbconnector))

# you can fetch data
default_table <- "your_table_name"
fetch_query <- "SELECT * FROM your_table LIMIT 10"
fetched_df <- private_db_connection_obj$FetchData(dbconnector = dbconnector, 
                                                  kDefaultTable = default_table, query_sql = fetch_query)
print(class(fetched_df))

# you can update
update_query <- "UPDATE your_table SET column = condition"
update_result <- private_db_connection_obj$UpdateData(dbconnector = dbconnector, query_sql = update_query)
```