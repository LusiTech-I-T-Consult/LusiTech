import boto3
import os

def lambda_handler(event, context):
    primary_asg_name = os.environ['PRIMARY_ASG_NAME']
    dr_asg_name = os.environ['DR_ASG_NAME']
    sns_topic_arn = os.environ['SNS_TOPIC_ARN']
    region = os.environ['REGION']
    dr_region = os.environ['DR_REGION']

    # Initialize clients
    primary_asg_client = boto3.client('autoscaling', region_name=region)
    dr_asg_client = boto3.client('autoscaling', region_name=dr_region)
    sns_client = boto3.client('sns', region_name=region)

    try:
        # Check the primary ASG health
        primary_asg = primary_asg_client.describe_auto_scaling_groups(
            AutoScalingGroupNames=[primary_asg_name]
        )
        primary_instances = primary_asg['AutoScalingGroups'][0]['Instances']

        # If no healthy instances, scale up DR ASG
        if not any(instance['LifecycleState'] == 'InService' for instance in primary_instances):
            print(f"No healthy instances in primary ASG: {primary_asg_name}. Scaling up DR ASG: {dr_asg_name}")
            dr_asg_client.update_auto_scaling_group(
                AutoScalingGroupName=dr_asg_name,
                MinSize=1,
                DesiredCapacity=1
            )

            # Send notification
            sns_client.publish(
                TopicArn=sns_topic_arn,
                Subject="DR Failover Triggered",
                Message=f"Primary region is down. DR ASG '{dr_asg_name}' has been scaled up."
            )
        else:
            print(f"Primary ASG '{primary_asg_name}' is healthy. No action required.")

    except Exception as e:
        print(f"Error occurred: {str(e)}")
        sns_client.publish(
            TopicArn=sns_topic_arn,
            Subject="DR Failover Error",
            Message=f"An error occurred while handling DR failover: {str(e)}"
        )
        raise
