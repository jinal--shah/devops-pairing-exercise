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
