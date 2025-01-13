terraform {
  required_providers {
    snowflake = {
      source  = "chanzuckerberg/snowflake"
      version = "0.25.17"
    }
  }

  backend "remote" {
    organization = "Demo_Using_Terraform"

    workspaces {
      name = "gh-actions-demo"
    }
  }
}

provider "snowflake" {
}

resource "snowflake_procedure" "sp_cdq_status_log" {
  name        = "SP_CDQ_STATUS_LOG"
  database    = "DEMO_DB_V3"
  schema      = "DEMO_SCHEMA_V3"
  # language    = "PYTHON"

  arguments {
    name = "DATABASE_NAME"
    type = "VARCHAR"
  }
  arguments {
    name = "SCHEMA_NAME"
    type = "VARCHAR"
  }
  arguments {
    name = "QC_ID"
    type = "VARCHAR"
  }
  arguments {
    name = "SQL_QUERY"
    type = "VARCHAR"
  }
  arguments {
    name = "START_TS"
    type = "TIMESTAMP"
  }
  arguments {
    name = "END_TS"
    type = "TIMESTAMP"
  }
  arguments {
    name = "CYCL_TIME_ID"
    type = "VARCHAR"
  }
  arguments {
    name = "OUTPUT"
    type = "VARCHAR"
  }
  arguments {
    name = "THRESHOLD_OPERATOR"
    type = "VARCHAR"
  }
  arguments {
    name = "THRESHOLD_VALUE"
    type = "VARCHAR"
  }

  comment             = "Procedure to log CDQ status"
  return_type         = "STRING"
  execute_as          = "CALLER"
  return_behavior     = "IMMUTABLE"
  null_input_behavior = "RETURNS NULL ON NULL INPUT"

  statement = <<EOT
import snowflake.snowpark as snowpark
from datetime import datetime

def main(session: snowpark.Session, DATABASE_NAME: str, SCHEMA_NAME: str, QC_ID: str, SQL_QUERY: str,
         START_TS: str, END_TS: str, CYCL_TIME_ID: str, OUTPUT: str, THRESHOLD_OPERATOR: str, THRESHOLD_VALUE: str):
    try:
        # Construct the SQL query to log the status
        sql_query = f"""
        INSERT INTO {DATABASE_NAME}.{SCHEMA_NAME}.CDQ_STATUS_LOG (
            QC_ID, DQM_ID, DQM_NAME, DQM_DESC, DMN_CD, DMN_SUB_CD, TBL_NM, COL_NM, 
            DQ_STATUS, DQ_QUERY, IS_CRITICAL, START_TS, END_TS, CYCL_TIME_ID, UPDTD_BY
        ) 
        SELECT QC_ID, DQM_ID, DQM_NAME, DQM_DESC, DMN_CD, DMN_SUB_CD, TBL_NM, COL_NM, 
               CASE WHEN {OUTPUT} {THRESHOLD_OPERATOR} {THRESHOLD_VALUE} THEN 'P' ELSE 'F' END AS DQ_STATUS,
               '{SQL_QUERY.replace("'", "''")}', IS_CRITICAL, '{START_TS}', '{END_TS}', '{CYCL_TIME_ID}', CURRENT_USER()
        FROM {DATABASE_NAME}.{SCHEMA_NAME}.CDQ_CONFIG 
        WHERE QC_ID = '{QC_ID}'
        """
        # Execute the SQL statement
        session.sql(sql_query).collect()
        return 'Inserted into CDQ_STATUS_LOG successfully'
    except Exception as e:
        return f"Error in SP_CDQ_STATUS_LOG: {str(e)}"
EOT
}


resource "snowflake_procedure" "sp_cdq_exec_log" {
  name        = "SP_CDQ_EXEC_LOG"
  database    = "DEMO_DB_V3"
  schema      = "DEMO_SCHEMA_V3"
  # language    = "PYTHON"

  arguments {
    name = "DATABASE_NAME"
    type = "VARCHAR"
  }
  arguments {
    name = "SCHEMA_NAME"
    type = "VARCHAR"
  }
  arguments {
    name = "QC_ID"
    type = "VARCHAR"
  }
  arguments {
    name = "EXEC_STATUS"
    type = "VARCHAR"
  }
  arguments {
    name = "ERROR_MSG"
    type = "VARCHAR"
  }
  arguments {
    name = "START_TS"
    type = "TIMESTAMP"
  }
  arguments {
    name = "END_TS"
    type = "TIMESTAMP"
  }
  arguments {
    name = "CYCL_TIME_ID"
    type = "VARCHAR"
  }

  comment             = "Procedure to log CDQ execution status"
  return_type         = "STRING"
  execute_as          = "CALLER"
  return_behavior     = "IMMUTABLE"
  null_input_behavior = "RETURNS NULL ON NULL INPUT"

  statement = <<EOT
import snowflake.snowpark as snowpark
from datetime import datetime

def main(session: snowpark.Session, DATABASE_NAME: str, SCHEMA_NAME: str, QC_ID: str, EXEC_STATUS: str, ERROR_MSG: str, 
         START_TS: str, END_TS: str, CYCL_TIME_ID: str):
    try:
        # Construct the SQL query to log execution status
        sql_query = f"""
        INSERT INTO {DATABASE_NAME}.{SCHEMA_NAME}.CDQ_EXEC_LOG (
            QC_ID, DQM_ID, DQM_NAME, DQM_DESC, DMN_CD, DMN_SUB_CD, TBL_NM, COL_NM, 
            EXEC_STATUS, ERR_MSG, START_TS, END_TS, CYCL_TIME_ID, UPDTD_BY
        ) 
        SELECT QC_ID, DQM_ID, DQM_NAME, DQM_DESC, DMN_CD, DMN_SUB_CD, TBL_NM, COL_NM, 
               '{EXEC_STATUS}', '{ERROR_MSG.replace("'", "''")}', '{START_TS}', '{END_TS}', '{CYCL_TIME_ID}', CURRENT_USER()
        FROM {DATABASE_NAME}.{SCHEMA_NAME}.CDQ_CONFIG 
        WHERE QC_ID = '{QC_ID}'
        """
        # Execute the SQL statement
        session.sql(sql_query).collect()
        return 'Inserted into CDQ_EXEC_LOG successfully'
    except Exception as e:
        return f"Error in SP_CDQ_EXEC_LOG: {str(e)}"
EOT
}

