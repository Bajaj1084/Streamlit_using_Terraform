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
  language    = "PYTHON"
  return_type = "STRING"

  runtime_version = "3.11"
  packages        = ["snowflake-snowpark-python"]
  handler         = "main"

  statement = <<-EOT
    import snowflake.snowpark as snowpark
    from datetime import datetime

    def main(session: snowpark.Session, DATABASE_NAME: str, SCHEMA_NAME: str, QC_ID: str, SQL_QUERY: str,  
             START_TS: str, END_TS: str, CYCL_TIME_ID: str, OUTPUT: str, THRESHOLD_OPERATOR: str, THRESHOLD_VALUE: str):
        try:
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
            session.sql(sql_query).collect()
            return 'Inserted into CDQ_STATUS_LOG successfully'
        except Exception as e:
            return f"Error in SP_Status_Log: {str(e)}"
  EOT
}

