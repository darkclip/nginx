# Production Ready OpenResty Docker Image

Docker Hub Registry: `darkclip/nginx`

This docker image is integrated with

- GeoIP2
- RTMP
- ModSecurity
- CrowdSec
- acme.sh


## Data Folder Structure

|Folder   |Content|
|:-       |:-    |
|acme     |acme config and certs home|
|bin      |user executable|
|crowdsec |crowdsec nginx bouncer config|
|openresty|openresty config and log|
|www      |openresty default www home|


## acme.sh

Set account email with environment variable: `ACCOUNT_EMAIL=user@example.com`

For http-01, include `/etc/nginx/conf.d/common/acme-challenge.conf` in server conf, then:

```bash
acme.sh --issue -d "example.com" -d "sub.example.com" --nginx
```

For dns-01, set dns api key in docker environment variable, then:

```bash
acme.sh --issue -d "example.com" -d "*.example.com" --dns dns_cf
```

To install cert:

```bash
acme.sh --install-cert -d "example.com" \
--fullchain-file "/data/ssl/example.com/fullchain.pem" \
--key-file "/data/ssl/example.com/key.pem" \
--reloadcmd "nginx -s reload"
```


## Useful Files

### Common nginx conf snippets

`/etc/nginx/conf.d/common/*.conf`

### ModSecurity

```nginx
modsecurity on;
modsecurity_rules_file /etc/nginx/modsecurity.conf;
```

### CrowdSec config file

`/data/crowdsec/crowdsec-openresty-bouncer.conf`
