# a proposed solution

## DEPLOY

_... ships a load-balanced, autoscaling nginx service_.

```bash
. .setenv # enter AWS creds as prompted.
terraform init -input=false
terraform apply -input=false -auto-approve
```

## VALIDATE SERVICE

Run `check_nginx.sh`.

Will run through each ip in the asg and check
a user-defined version is served by the nginx.

## CHANGE VERSION TEXT
Hard-coded in the cloud-config file.

## CAVEATS

* app deployment is coupled to infra provisioning. In reality we
    would probably move deployment of the app (the nginx static content)
    outside of terraform. e.g. AWS Code Deploy etc ...
    Alternatively we might use FaaS (AWS lambda) or just a web-serving s3 bucket, and
    forget about provisioning infra.
    
* each subsequent terraform run destroys the previous service. In practice
    the resultant loss of service might be unacceptable to the business.
    
* The ELB was selected due to limited time, as ALBs are more complex abstractions in terraform.
    However, classic ELBs are deprecated and should be avoided.
