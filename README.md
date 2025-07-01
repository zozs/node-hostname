# Node-hostname

## Deployment instructions for day-to-day work

### Deploying a new version of the application

1. Push the desired changes to the Git repository, this will automatically trigger a rebuild of the application, using the Dockerfile in the repository root.
2. After a succesful build, redeploy the application using kubectl, with `kubectl rollout restart deploy/node-hostname`. This will pull the latest image and do a rolling restart.
3. Done!

TODOs:
* Instead of pushing on every build to the `latest` tag, I would probably design a solution where production builds are done when tags are pushed, for example semver tags. That way we can then use a more sane versioning for production deployment, and use the `latest` tag only for something like a staging environment. I have done something similar before in `https://github.com/zozs/a-wild-button-appears/blob/master/.github/workflows/nodejs.yml`.
* Instead of manually deployment the application with a `kubectl rollout`, I would deploy ArgoCD or something similar to manage the deployment. Maybe combined with argocd-image-updater to look for newly tagged images?

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

