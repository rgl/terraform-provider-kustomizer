package kustomizer

import (
	"context"

	"github.com/hashicorp/terraform-plugin-sdk/v2/diag"
	"github.com/hashicorp/terraform-plugin-sdk/v2/helper/schema"
	"sigs.k8s.io/kustomize/api/krusty"
	"sigs.k8s.io/kustomize/kyaml/filesys"
)

func dataSourceKustomizerManifest() *schema.Resource {
	return &schema.Resource{
		ReadContext: dataSourceKustomizerManifestRead,
		Schema: map[string]*schema.Schema{
			"files": {
				Type:     schema.TypeMap,
				Required: true,
				Elem: &schema.Schema{
					Type: schema.TypeString,
				},
			},
			"manifest": {
				Type:      schema.TypeString,
				Computed:  true,
				Sensitive: true,
			},
		},
	}
}

func dataSourceKustomizerManifestRead(ctx context.Context, d *schema.ResourceData, m interface{}) diag.Diagnostics {
	kfs := filesys.MakeFsInMemory()

	var diags diag.Diagnostics

	files := d.Get("files").(map[string]interface{})
	for path, content := range files {
		err := kfs.WriteFile(path, []byte(content.(string)))
		if err != nil {
			return diag.Errorf("failed to write file %s: %v", path, err)
		}
	}

	kustomizer := krusty.MakeKustomizer(krusty.MakeDefaultOptions())

	resMap, err := kustomizer.Run(kfs, "/")
	if err != nil {
		return diag.Errorf("failed to run kustomize: %v", err)
	}

	yamlData, err := resMap.AsYaml()
	if err != nil {
		return diag.Errorf("failed to convert to YAML: %v", err)
	}

	err = d.Set("manifest", string(yamlData))
	if err != nil {
		return diag.Errorf("failed to store the manifest result: %v", err)
	}

	d.SetId("TODO")

	return diags
}
