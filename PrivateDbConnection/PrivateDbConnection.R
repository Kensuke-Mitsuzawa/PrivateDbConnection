# this is R5 class file
library(yaml)
library(DBI)
library(RMySQL)

PrivateDbConnection <- setRefClass(
  Class = "PrivateDbConnection",
  
  fields = list (
    yaml_setting_file = "character",
    connection_settings = "list"
  ),
  
  methods = list(
    initialize = function(yaml_setting_file=NULL) {
      if(file.exists(yaml_setting_file)==F){
        stop("yaml_setting_file path does not exist. You must input with abs path")
      }
      abs_path_yaml_setting <- normalizePath(yaml_setting_file)
      connection_settings <<- yaml::yaml.load_file(abs_path_yaml_setting)
    },
    
    OpenNatPortForward = function(){
      
      kLocalPortNumber <- connection_settings$nat$localPortNumber
      kPortNumber <- connection_settings$nat$DbPort
      kTargetServer <- connection_settings$nat$DbAddress
      kUserNameNat <- connection_settings$nat$NatServerUser
      kServerNat <- connection_settings$nat$NatServerAdress
      kPathToKeyFile <- connection_settings$nat$NatServerSshPath
      
      cm_open_tunnel <- sprintf('ssh -f -L %s:%s:%s -N %s@%s -i %s', kLocalPortNumber,
                                kTargetServer,
                                kPortNumber,
                                kUserNameNat, 
                                kServerNat, 
                                kPathToKeyFile)
      tryCatch(expr = system(cm_open_tunnel), 
               error = function(e){ 
                 stop(sprintf("opening portfowarding with %s", cm_open_tunnel)) 
                 }
               )
      
      return(T)
    },
    
    
    CloseNatPortForward = function(){
      cm_tunnel_close <- "kill `ps aux | grep 'ssh.* -f -L' | awk '{print $2}'`"
      system(cm_tunnel_close)
      
      return(T)
    },
    
    
    .__T__InitializeDriver = function(){
      md <- DBI::dbDriver("MySQL")
      
      return(md)
    },
    
    
    .__T__InitializeConnector = function(md){
      dbconnector <- DBI::dbConnect(md, host=connection_settings$nat$FowardTo, 
                                    dbname=connection_settings$db$DbName, 
                                    user=connection_settings$db$Dbuser, 
                                    password=connection_settings$db$DbPass,
                                    port=connection_settings$nat$localPortNumber)
      
      return(dbconnector)  
    },
    
    
    
    PrepareDbConnection = function(){
      md <- .__T__InitializeDriver()
      dbconnector <- .__T__InitializeConnector(md)
      
      return(dbconnector)
    },
    
    
    FetchData = function(dbconnector, kDefaultTable, query_sql){
      if(CheckConnection(dbconnector, kDefaultTable)==F){
        message("DB connection is invalid. Check connection status")
        return(F)
      }
      
      tryCatch({
        if(CheckConnection(dbconnector, kDefaultTable)==F){
          message("DB connection is invalid. Check connection status")
          return(F)
        }        
        res <- DBI::dbSendQuery(dbconnector, query_sql)
        df_fetched_data <- DBI::dbFetch(res, n = -1)
        dbClearResult(res)
      
        return(df_fetched_data)
      }, error = function(e){
        message("error happens while updating")
        return(F)
      })
    },
    
    
    UpdateData = function(dbconnector, sql_query){
      updates_res <- RMySQL::dbSendQuery(conn = dbconnector, statement = sql_query)
      RMySQL::dbClearResult(res = updates_res)
      
    },
    
    
    CloseDbConnection = function(dbconnector){
      tryCatch({DBI::dbDisconnect(dbconnector)
      }, error = function(e){
        print('DB is Alredy disabled')
      })
      
      return(T)
    },
    
    
    CheckConnection = function(dbconnector, table_name){
      res_check_result <- DBI::dbExistsTable(dbconnector, table_name)
      return(res_check_result)
    }
  )
)

  
  
