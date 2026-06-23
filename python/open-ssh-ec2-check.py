# ============================================================
# Find and Terminate EC2 Instances with SSH Open to the World
# ============================================================
#
# What this script does:
# 1. Finds all security groups that allow SSH (port 22) from anywhere (0.0.0.0/0)
# 2. Finds all running or stopped EC2 instances using those security groups
# 3. Terminates those EC2 instances
#
# Why this matters: Leaving SSH open to the world is a major security risk.
# This is the type of automation you'd build with AWS Lambda to keep your
# environment secure.
# ============================================================

def lambda_handler(event,context):

    # Step 1: Import Modules and Connect to AWS
    import boto3
    import json

    ec2_client = boto3.client("ec2")


    # Step 2: Get All Security Group Rules in the Region
    response = ec2_client.describe_security_group_rules()
    print(json.dumps(response, indent=2, default=str))

    # Get the value of the "SecurityGroupRules" key from the response
    all_sg_rules = response["SecurityGroupRules"]
    print(json.dumps(all_sg_rules, indent=2, default=str))


    # Step 3: Find Security Groups Where SSH (Port 22) is Open to the World (0.0.0.0/0)
    open_ssh_sg_ids = []

    for rule in all_sg_rules:
        if rule.get("FromPort") == 22 and rule.get("CidrIpv4") == "0.0.0.0/0":
            open_ssh_sg_ids.append(rule["GroupId"])

    print("Security Groups with SSH open to the world:", open_ssh_sg_ids)


    # Step 4: Get All EC2 Instances in the Region
    response = ec2_client.describe_instances()
    print(json.dumps(response, indent=2, default=str))

    # Get the value of the "Reservations" key from the response
    reservations = response["Reservations"]
    print(json.dumps(reservations, indent=2, default=str))


    # Step 5: Filter Out Terminated Instances and Keep Only Running or Stopped Instances
    active_instances = []

    for reservation in reservations:
        for instance in reservation["Instances"]:
            if instance["State"]["Name"] != "terminated":
                active_instances.append(instance)

    print(json.dumps(active_instances, indent=2, default=str))


    # Step 6: Get Each Instance ID and Its Security Groups
    instance_info = []

    for instance in active_instances:
        instance_id = instance["InstanceId"]
        sg_ids = [sg["GroupId"] for sg in instance["SecurityGroups"]]
        instance_info.append([instance_id, sg_ids])

    print(json.dumps(instance_info, indent=2, default=str))


    # Step 7: Find Instances That Have a Security Group with SSH Open to the World
    instances_to_terminate = []

    for item in instance_info:
        instance_id = item[0]
        sg_ids = item[1]

        for sg_id in sg_ids:
            if sg_id in open_ssh_sg_ids:
                instances_to_terminate.append(instance_id)

    print("Instances to terminate:", instances_to_terminate)


    # Step 8: Terminate the Insecure Instances
    if instances_to_terminate:
        response = ec2_client.terminate_instances(InstanceIds=instances_to_terminate)
        print(f"Terminated {len(instances_to_terminate)} instance(s):", instances_to_terminate)
    else:
        print("No instances found with SSH open to the world")
