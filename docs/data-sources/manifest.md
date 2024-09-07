---
page_title: kustomizer_manifest Data Source - terraform-provider-kustomizer
subcategory:
description: |-
  Generate Kubernetes Manifests using the Kustomize Go library.
---

# kustomizer_manifest (Data Source)

This generates a Kubernetes Manifest using the [Kustomize Go library](https://github.com/kubernetes-sigs/kustomize).

## Example Usage

This is normally used as:

```hcl
data "kustomizer_manifest" "example" {
  files = {
    "kustomization.yaml" = <<-EOF
      apiVersion: kustomize.config.k8s.io/v1beta1
      kind: Kustomization
      namespace: my-namespace
      resources:
        - resources
    EOF
    "resources/resources.yaml" = <<-EOF
      apiVersion: v1
      kind: Pod
      metadata:
        name: my-pod
      spec:
        containers:
        - name: my-container
          image: nginx
    EOF
  }
}

output "kustomized_manifest" {
  value = data.kustomizer_manifest.example.manifest
}
```

For a complete example see [rgl/terraform-provider-kustomizer](https://github.com/rgl/terraform-provider-kustomizer).

## Schema

### Required

- **files** (Map of String) The Kustomize project files used to render the `manifest`.

### Attributes

- **manifest** (String) The rendered Kustomize project as a YAML document.
