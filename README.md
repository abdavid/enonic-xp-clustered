# Enonic XP

## Deployment

Deployment contains multiple stages:
- VALIDATE - validates terraform files
- BUILD
  - builds and deploys infrastructure (only on `infra/*` tags)
  - builds a docker image with enonic-xp
- PLAN - performs terraform plan and stores it output in S3 bucket
- APPLY - triggered on `apply/*` tag - applies terraform plan that was stored previously on S3 bucket

Currently it deploys only on stage environment. To add production change `PLAN` stage to plan and apply on stage and plan on production and `APPLY` stage should deploy on production when tagged with `apply/*`

### Useful commands

#### Deploy infrastructure

To deploy infrastructure and (or) build a new AMI image tag your commit with `infra/*` tag. Following command will create dated tag and push changes to the github.

```
git tag infra/$(date +%Y%m%d%H%M) && git push && git push --tags
```


#### Deploy to production (currently staging)

To deploy the enonic-xp master app you need to tag your commit with `apply/*` tag. Although do it after there is a successful build without tag as tagged flow requires plan to be prepared beforehand. Following command adds and pushes tag to the github:

```
git tag apply/$(date +%Y%m%d%H%M) && git push --tags
```

After Travis build is done, you need to manually terminate the instance to make an actual change of environment. This step has an automation potential if required.


### Disclaimer

This is just a proposition. Final deployment flow may be different.

## Development

##### Hosts file for local enonic integration

Add the following to your hosts file

```
127.0.0.1          enonic.local
127.0.0.1       ap-enonic.local
127.0.0.1       bt-enonic.local
127.0.0.1       sa-enonic.local
127.0.0.1       fvn-enonic.local
127.0.0.1       draft-ap-enonic.local
127.0.0.1       draft-bt-enonic.local
127.0.0.1       draft-sa-enonic.local
127.0.0.1       draft-fvn-enonic.local
::1                enonic.local
::1             ap-enonic.local
::1             bt-enonic.local
::1             sa-enonic.local
::1             fvn-enonic.local
::1             draft-ap-enonic.local
::1             draft-bt-enonic.local
::1             draft-sa-enonic.local
::1             draft-fvn-enonic.local
```


### Build and run local Enonic instance with a datadump 

First ensure you have the image built locally

```
$ docker build . -t snoam-enonic-xp:enonic-dev
```
####  Run with a spesific dump. 
Mind that the contents of `data` is expected to be zip files and the argument passed to the image is expected to be the name of the file without the `.zip` extension.
Add your dump file to `data` folder. Then reference the file name as `<MY_DUMP_NAME>` in the command below.

```
$ docker run -p8080:8080  --env DUMP_NAME=<MY_DUMP_NAME> --name enonic-local --rm -ti -v $(pwd)/data:/init-data snoam-enonic-xp:enonic-dev
```

#### Run with automatic deployment of an enonic-app to local enonic
Replace `<path to enonic app project root>` with your local path to the enonic-app project root. Building the enonic app will then automaticly redeploy and reload nessesary services.

```
$ docker run -p8080:8080  --env DUMP_NAME=<MY_DUMP_NAME> --name enonic-local --rm -ti -v $(pwd)/data:/init-data -v <path to enonic app project root>/build/libs:/enonic-xp/home/deploy snoam-enonic-xp:enonic-dev
```


#### Accessing Enonic locally

Go to `http://enonic.local:8080`. Log in with the default development user `su:fivetimes05`

#### Developing antichurn-api locally with a local enonic integration

```
$ ADMIN_SERVICE_HOST=http://[client]-enonic.local:8080 yarn dev
```

## Integrating with enonic through antichurn-api

By default accessing applications hosted on the enonic platform is done through the `/api/config` context path. While accessing static assets hosted there is done through `/api/_`. 

When building applications and deploying them on enonic, the application should have an application key like `no.schibsted.my.application`

**Please note that `no.schibsted` part is required since antichurn-api explicitly sets this to prevent accessing other open services inside enonic.** 

When using `/api/config` you need to specify the application context. So for an application with application key `no.schibsted.my.application` you would need to use `/api/config/my.application` to be able to talk with the correct application. 

Now that we have the application context down, we now need to specify what service
we want to talk with. By default antichurn-api assumes `graphql` since most of our services in applications is graphql, if nothing else is specified.

So if we have a service named `funkytown` running in our application with application key `no.schibsted.my.application` the full url to talk with our applications service would then be the following: 
```
/api/config/:applicationKeySlug/:serviceName
```  
or rather
```
/api/config/my.application/funkytown
```  

## Other relevant resources
* Backend
  - [Enonic XP](https://github.schibsted.io/SNOAM/enonic-xp)
  - [OSOS2 Swagger Documentation](https://kundewebtest.aftenposten.no/tjenester2/swagger-ui.html#/)
  - [OSOS2](https://github.schibsted.io/SNOAM/osos2)
  - [enonic-choose-subscription](https://github.schibsted.io/SNOAM/enonic-choose-subscription)
  - [enonic-fordelssider](https://github.schibsted.io/SNOAM/enonic-fordelssider)
  - [enonic-antichurn-admin](https://github.schibsted.io/SNOAM/antichurn-admin)
* Frontend
  - [antichurn](https://github.schibsted.io/SNOAM/antichurn)
  - [benefits](https://github.schibsted.io/SNOAM/benefits)
  - [choose-subscription](https://github.schibsted.io/SNOAM/choose-subscription)

