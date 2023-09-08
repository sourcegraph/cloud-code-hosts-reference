# GitLab on Google Cloud Platform

This deployment spins up a GCP Project with a GitLab EE instance on a private GCE instance.

The GCE instance is then exposed with a regional internal Application Load Balancer

## Steps

We assume the GitLab instance is available at `gitlab-private-gcp.sg.dev`, which is a private dns name.

### Create GCP Project

Deploy project:

```sh
cd project
cp terraform.example.tfvars.example terraform.tfvars
```

```sh
terraform apply
```

Notes the output project id.

### Create TLS cert

```sh
acme.sh --issue --dns -d gitlab-private-gcp.sg.dev --yes-I-know-dns-manual-mode-enough-go-ahead-please
```

Complete the DNS challenge over cloudflare, then:


```sh
acme.sh --issue --dns -d gitlab-private-gcp.sg.dev --yes-I-know-dns-manual-mode-enough-go-ahead-please --renew
```

Notes the output path to the tls cert and the private key.

### Deploy infra

```sh
cd instance
```

Create `terraform.tfvars``

```sh
cp terraform.example.tfvars.example terraform.tfvars
```

Create `secrets.tfvars` (optional, if you have your VPN infra)

```tf
ts_auth_key = "changeme"
```

Deploy instance:

```sh
terraform apply -var-file secrets.tfvars
```

Notes the output service attachment uri and instance name.

SSH into the VM:

```sh
export PROJECT_ID=$CHANGEME
export INSTANCE_NAME=$CHANGEME
```

Proxy GitLab UI:

```sh
gcloud compute start-iap-tunnel --zone "us-central1-a" "$INSTANCE_NAME" 80 --project "$PROJECT_ID" --local-host-port=localhost:8080
```

SSH into the VM:

```sh
gcloud compute ssh --zone "us-central1-a" --tunnel-through-iap --project "$PROJECT_ID" "$INSTANCE_NAME"
```

Set the initial password

```sh
sudo -i su
gitlab-rake "gitlab:password:reset[root]"
```

Modify config

```sh
vim /etc/gitlab/gitlab.rb
```

```ruby
external_url 'https://gitlab-private-gcp.sg.dev'
letsencrypt['enable'] = false
nginx['listen_port'] = 80
nginx['listen_https'] = false
gitlab_rails['monitoring_whitelist'] = ['127.0.0.0/8', '::1/128', '0.0.0.0/0']
```

Reload GitLab

```sh
gitlab-ctl reconfigure
gitlab-ctl restart
```

First add the record to `/etc/hosts` to resolve the dns name to the ip allocated for the load balancer. Go to tailscale and accept the advertised subnets. Learn more from https://tailscale.com/kb/1019/subnets/

### Set up in Sourcegraph Cloud instance project

Finally, in the consumer project, create a new PSC connection using the name of `gitlab-private-gcp` (the subdomain name). You should be able to connect to it.
