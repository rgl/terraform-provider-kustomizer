package main

import (
	"flag"

	"github.com/hashicorp/terraform-plugin-sdk/v2/helper/schema"
	"github.com/hashicorp/terraform-plugin-sdk/v2/plugin"
	"github.com/rgl/terraform-provider-kustomizer/kustomizer"
)

func main() {
	var debug bool

	// NB You should use the Visual Studio Code Debugger UI to launch this in debug mode.
	// see the .vscode/launch.json file.
	// see https://www.terraform.io/docs/extend/debugging.html#enabling-debugging-in-a-provider
	flag.BoolVar(&debug, "debug", false, "set to true to run the provider with support for debuggers like delve")
	flag.Parse()

	plugin.Serve(&plugin.ServeOpts{
		Debug: debug,
		ProviderFunc: func() *schema.Provider {
			return kustomizer.Provider()
		},
	})
}
