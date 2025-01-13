terraform {
  required_providers {
    snowflake = {
      source  = "chanzuckerberg/snowflake"
      version = "0.25.17"
    }
  }

  backend "remote" {
    organization = "my-organization-name"

    workspaces {
      name = "gh-actions-demo"
    }
  }
}

provider "snowflake" {
}

resource "null_resource" "create_procedure" {
  provisioner "local-exec" {
    command = <<EOT
      echo "Creating stored procedure..."
      snowflake -q <<-SQL
      CREATE OR REPLACE PROCEDURE DEMO_DB_V3.DEMO_SCHEMA_V3.INSERT_DOCUMENTS(
          RELATIVE_PATH VARCHAR,
          RAW_TEXT VARCHAR
      )
      RETURNS STRING
      LANGUAGE JAVASCRIPT
      EXECUTE AS CALLER
      AS $$
      try {
          var query = `INSERT INTO DEMO_DB_V3.DEMO_SCHEMA_V3.DOCUMENTS (RELATIVE_PATH, RAW_TEXT)
                       VALUES ('\\${RELATIVE_PATH}', '\\${RAW_TEXT}')`;
          snowflake.execute({ sqlText: query });
          return 'Record inserted successfully';
      } catch (err) {
          return 'Error: ' + err.message;
      }
      $$;
      SQL
    EOT
  }
}
