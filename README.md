# Amazon SNS for the AWS Service Broker
Provision, manage and connect to [Amazon SNS](https://aws.amazon.com/sns/).

## Prerequisites

**IAM resources** - see the [AWS Service Broker Requirements](https://github.com/awslabs/aws-servicebroker-documentation/blob/master/Overview.md#requirements) for details

## Plans

### sns-subscription
Creates an SNS Topic.

### sns-topic
Creates an SNS Subscription.

### sns-topicwithsub
Creates and SNS Topic and Subscription.

## Retained resources

No resources are retained. The SNS resources, data and all associated resources will be fully removed if the Service Instance is deleted.

## Resources

[Getting Started With OCP and the AWS Service Broker](https://github.com/awslabs/aws-servicebroker-documentation/blob/master/getting-started.md)  
[AWS Service Broker Overview](https://github.com/awslabs/aws-servicebroker-documentation/blob/master/Overview.md)  
[FAQ](https://github.com/awslabs/aws-servicebroker-documentation/blob/master/FAQ.md)  
[Troubleshooting](https://github.com/awslabs/aws-servicebroker-documentation/blob/master/Troubleshooting.md)  

## License

This library is licensed under the Apache 2.0 License.