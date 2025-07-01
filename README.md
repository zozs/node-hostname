# Node-hostname

## Deployment instructions for day-to-day work

### Accessing the application

The application is accessible at `https://hostname.cryptosec.se` over HTTPS.

### Deploying a new version of the application, or initial deployment

1. Make the required changes to the application.
2. Update the chart version and/or the application version in `deploy/helm/node-hostname/Chart.yaml`. For example update `version: 0.2.0` to `version: 0.3.0`. This will ensure that Helm redeploy the application later on.
3. Commit and push the changes to the Git repository, this will automatically trigger a rebuild of the application, using a Github Workflow. The docker image will be built using the Dockerfile in the repository root.
4. After a successful build, (re)deploy the application using Helm: `cd deploy/helm/node-hostname && helm upgrade --install hostname .`.
5. Done!

If you, for some reason, do not wish to use Helm, feel free to use the Kubernetes manifest in `deploy/kubernetes/` and apply it with `kubectl apply -f www.yaml`. You then need to trigger a manual rollout upon a build of new docker images with `kubectl rollout restart deploy/node-hostname`.

TODOs:
* Instead of pushing on every build to the `latest` tag, I would probably design a solution where production builds are done when tags are pushed, for example semver tags. That way we can then use a more sane versioning for production deployment, and use the `latest` tag only for something like a staging environment. I have done something similar before in `https://github.com/zozs/a-wild-button-appears/blob/master/.github/workflows/nodejs.yml`.
* Instead of manually deployment the application with a `kubectl rollout` or `helm`, I would deploy ArgoCD or something similar to manage the deployment. Maybe combined with argocd-image-updater to look for newly tagged images?
* It could be neat to define a dedicated namespace for the application, if the customer ever wants to deploy more things to the cluster.

## Deployment documentation

This section contains information about how the kubernetes cluster were initially setup, for future reference.

### VM creation

A VM was created on Hetzner cloud, to avoid hosting our data on any non-EU cloud provider. Ubuntu 24.04 was used as the base.

TODO:
* There hasn't been any hardening done on this VM; no firewalls, no individual user accounts except root, etc. This would of course need fixing for production.

### Kubernetes installation and configuration

K3s was used to get a production-ready cluster up. Installation was done without any special settings, using: `curl -sfL https://get.k3s.io | sh`.

To use Let's encrypt for TLS certificates, it was configured as an ACME provider by creating the following file:

`/var/lib/rancher/k3s/server/manifests/traefik-config.yaml`

```
kind: HelmChartConfig
metadata:
  name: traefik
  namespace: kube-system
spec:
  valuesContent: |-
    additionalArguments:
      - "--certificatesresolvers.default.acme.email=acme@linuskarlsson.se"
      - "--certificatesresolvers.default.acme.storage=/data/acme.json"
      - "--certificatesresolvers.default.acme.httpchallenge.entrypoint=web"
    ports:
      web:
        exposedPort: 80
      websecure:
        exposedPort: 443
```

TODO: the `/data/acme.json` is actually not stored on a persistent volume, so every restart of Traefik will trigger a new certificate request. Not great, and will quite easy reach the rate limit of lets encrypt.

## TODO: ArgoCD work-in-progress (not finished)

TODO: I've started a small ArgoCD work in `deploy/argocd`. The `app.yaml` includes an ArgoCD application, which would allow the deployment to work like this instead:

1. Commit changes to the application on Github.
2. ArgoCD (using argocd-image-update) would automatically pick up the new image, update the `values.yaml` file with the new image tag, and then trigger a redeploy by itself.
3. The same thing would work for any updates to the Helm chart itself.

I've got this working on my local Kubernetes cluster at home, using the `app.yaml` above. However, I did not have time to actually install and configure ArgoCD and the image updater at the newly created Hetzner cluster, since there's quite a lot of extra work involved getting it up and running.

As an example of such an auto-update, see the following commit made by argocd-image-updater:

```
~/development/k8s on  main
❯ git log -1 -p
commit cfe63097692f69ef1cc897a35e92873599a5246a (HEAD -> main, origin/main, origin/HEAD)
Author: argocd-image-updater <noreply@argoproj.io>
Date:   Tue Jul 1 10:30:54 2025 +0000

    build: automatic update of node-hostname

    updates image zozs/node-hostname tag 'dummy' to 'sha256:bbe240a595f9daeb8cbfc433eb89589b9fec1a416a33a8036eb10dee3a1529c8'

diff --git a/apps/node-hostname/values.yaml b/apps/node-hostname/values.yaml
index 13190de..9902d64 100644
--- a/apps/node-hostname/values.yaml
+++ b/apps/node-hostname/values.yaml
@@ -5,7 +5,7 @@ image:
   repository: ghcr.io/zozs/node-hostname
   # This sets the pull policy for images, we want Always since we use the latest tag.
   pullPolicy: Always
-  tag: "latest@sha256:795938b17fb95431b2200bf30f80c283990d91eb4c725ccd8eaaad249cf0afd7"
+  tag: "latest@sha256:bbe240a595f9daeb8cbfc433eb89589b9fec1a416a33a8036eb10dee3a1529c8"
 imagePullSecrets: []
 nameOverride: ""
 fullnameOverride: ""
```
