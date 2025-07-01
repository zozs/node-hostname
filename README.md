# Node-hostname

## Deployment instructions for day-to-day work

### Deploying a new version of the application, or initial deployment

1. Make the required changes to the application.
2. Update the chart version and/or the application version in `deploy/helm/node-hostname/Chart.yaml`. This will ensure that Helm redeploy the application later on.
3. Commit and push the changes to the Git repository, this will automatically trigger a rebuild of the application, using the Dockerfile in the repository root.
4. After a successful build, (re)deploy the application using Helm: `cd deploy/helm/node-hostname && helm upgrade --install hostname .`.
5. Done!

If you, for some reason, do not wish to use Helm, feel free to use the Kubernetes manifest in `deploy/kubernetes/` and apply it with `kubectl apply -f www.yaml`. You then need to trigger a manual rollout upon a build of new docker images with `kubectl rollout restart deploy/node-hostname`.

TODOs:
* Instead of pushing on every build to the `latest` tag, I would probably design a solution where production builds are done when tags are pushed, for example semver tags. That way we can then use a more sane versioning for production deployment, and use the `latest` tag only for something like a staging environment. I have done something similar before in `https://github.com/zozs/a-wild-button-appears/blob/master/.github/workflows/nodejs.yml`.
* Instead of manually deployment the application with a `kubectl rollout` or `helm`, I would deploy ArgoCD or something similar to manage the deployment. Maybe combined with argocd-image-updater to look for newly tagged images?

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

