# see https://github.com/hashicorp/terraform
terraform {
  required_version = "1.9.5"
  required_providers {
    # see https://registry.terraform.io/providers/hashicorp/helm
    # see https://github.com/hashicorp/terraform-provider-helm
    helm = {
      source  = "hashicorp/helm"
      version = "2.15.0"
    }
    # see https://registry.terraform.io/providers/rgl/kustomizer
    # see https://github.com/rgl/terraform-provider-kustomizer
    kustomizer = {
      source  = "rgl/kustomizer"
      version = "0.0.1"
    }
  }
}

locals {
  kubernetes_version = "1.31.0"
  # NB zot chat is an example of a chart that does not allow the user to use a
  #    non-default namespace, hence, we need to use the kustomizer_manifest
  #    terraform resource.
  #    see https://github.com/project-zot/helm-charts/issues/46
  zot_namespace      = "example"
  zot_domain         = "zot.example.test"
  zot_cluster_domain = "zot.${local.zot_namespace}.svc.cluster.local"
  zot_cluster_ip     = "10.96.0.20"
  zot_cluster_host   = "zot.${local.zot_namespace}.svc.cluster.local:5000"
  zot_cluster_url    = "http://${local.zot_cluster_host}"
}

# set the configuration.
# NB the default values are described at:
#       https://github.com/project-zot/helm-charts/tree/zot-0.1.60/charts/zot/values.yaml
#    NB make sure you are seeing the same version of the chart that you are installing.
# see https://zotregistry.dev/v2.1.0/install-guides/install-guide-k8s/
# see https://registry.terraform.io/providers/hashicorp/helm/latest/docs/data-sources/template
data "helm_template" "zot" {
  namespace  = local.zot_namespace
  name       = "zot"
  repository = "https://zotregistry.dev/helm-charts"
  chart      = "zot"
  # see https://artifacthub.io/packages/helm/zot/zot
  # renovate: datasource=helm depName=zot registryUrl=https://zotregistry.dev/helm-charts
  version      = "0.1.60" # app version 2.1.1.
  kube_version = local.kubernetes_version
  api_versions = []
  values = [yamlencode({
    service = {
      type      = "ClusterIP"
      clusterIP = local.zot_cluster_ip
    }
    ingress = {
      enabled   = true
      className = null
      pathtype  = "Prefix"
      hosts = [
        {
          host = local.zot_domain
          paths = [
            {
              path     = "/"
              pathType = "Prefix"
            }
          ]
        }
      ]
      tls = [
        {
          secretName = "zot-tls"
          hosts = [
            local.zot_domain,
          ]
        }
      ]
    }
    persistence = true
    pvc = {
      create           = true
      storageClassName = "linstor-lvm-r1"
      storage          = "8Gi"
    }
    mountConfig = true
    configFiles = {
      "config.json" = jsonencode({
        storage = {
          rootDirectory = "/var/lib/registry"
        }
        http = {
          address = "0.0.0.0"
          port    = "5000"
          auth = {
            htpasswd = {
              path = "/secret/htpasswd"
            }
          }
          accessControl = {
            repositories = {
              "**" = {
                policies = [{
                  users   = ["talos"]
                  actions = ["read"]
                }],
                anonymousPolicy = []
                defaultPolicy   = []
              }
            }
            adminPolicy = {
              users   = ["admin"]
              actions = ["read", "create", "update", "delete"]
            }
          }
        }
        log = {
          level = "debug"
        }
        extensions = {
          ui = {
            enable = true
          }
          search = {
            enable = true
            cve = {
              updateInterval = "2h"
            }
          }
        }
      })
    }
    mountSecret = true
    secretFiles = {
      # htpasswd user:pass pairs:
      #   admin:admin
      #   talos:talos
      # create a pair with:
      #   echo "talos:$(python3 -c 'import bcrypt;print(bcrypt.hashpw("talos".encode(), bcrypt.gensalt()).decode())')"
      # NB the pass value is computed as bcrypt(pass).
      htpasswd = <<-EOF
        admin:$2y$05$vmiurPmJvHylk78HHFWuruFFVePlit9rZWGA/FbZfTEmNRneGJtha
        talos:$2b$12$5nolGXPDH09gv7mGwsEpJOJx5SZj8w8y/Qt3X33wZJDnCdRs6y1Zm
        EOF
    }
    authHeader = base64encode("talos:talos")
  })]
}

# see https://registry.terraform.io/providers/rgl/kustomizer/latest/docs/data-sources/manifest
data "kustomizer_manifest" "example" {
  files = {
    "kustomization.yaml"       = <<-EOF
      apiVersion: kustomize.config.k8s.io/v1beta1
      kind: Kustomization
      namespace: ${yamlencode(local.zot_namespace)}
      resources:
        - resources/resources.yaml
    EOF
    "resources/resources.yaml" = data.helm_template.zot.manifest
  }
}

output "manifest" {
  sensitive = true
  value     = data.kustomizer_manifest.example.manifest
}
