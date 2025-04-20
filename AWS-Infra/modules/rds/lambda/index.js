// Lambda function to promote an RDS read replica to a standalone DB instance
exports.handler = async (event) => {
  const AWS = require("aws-sdk");
  const rds = new AWS.RDS();

  // Get the DB instance identifier from environment variables
  const dbInstanceIdentifier = process.env.DB_INSTANCE_IDENTIFIER;

  console.log(`Attempting to promote read replica: ${dbInstanceIdentifier}`);

  try {
    // Check if the instance is actually a read replica
    const describeParams = {
      DBInstanceIdentifier: dbInstanceIdentifier,
    };

    const dbInfo = await rds.describeDBInstances(describeParams).promise();

    if (!dbInfo.DBInstances || dbInfo.DBInstances.length === 0) {
      throw new Error(`DB instance ${dbInstanceIdentifier} not found`);
    }

    const instance = dbInfo.DBInstances[0];

    if (!instance.ReadReplicaSourceDBInstanceIdentifier) {
      console.log(
        `DB instance ${dbInstanceIdentifier} is not a read replica. No action needed.`,
      );
      return {
        statusCode: 200,
        body: `DB instance ${dbInstanceIdentifier} is not a read replica. No action taken.`,
      };
    }

    // Promote the read replica
    const promoteParams = {
      DBInstanceIdentifier: dbInstanceIdentifier,
      BackupRetentionPeriod: 7, // Set the backup retention period
    };

    await rds.promoteReadReplica(promoteParams).promise();

    return {
      statusCode: 200,
      body: `Successfully initiated promotion of read replica ${dbInstanceIdentifier}`,
    };
  } catch (error) {
    console.error("Error:", error);
    return {
      statusCode: 500,
      body: `Error promoting read replica: ${error.message}`,
    };
  }
};
