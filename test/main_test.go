package test

import (
	"testing"

	"github.com/gruntwork-io/terratest/modules/terraform"
	test_structure "github.com/gruntwork-io/terratest/modules/test-structure"
)

func TestTerraformGcpExample(t *testing.T) {
	vars := map[string]interface{}{
		"subnet_range": "10.0.0.0/16",
		"cluster_name": "testinstance",
		"name_prefix":  "testprefix",
		"location":     "West US",
	}

	t.Parallel()

	exampleDir := test_structure.CopyTerraformFolderToTemp(t, "../", "./examples/base")

	// Configure Terraform setting path to Terraform code, bucket name, and instance name.
	terraformOptions := &terraform.Options{
		// The path to where our Terraform code is located
		TerraformDir: exampleDir,

		// Variables to pass to our Terraform code using -var options
		Vars: vars,
	}

	// At the end of the test, run `terraform destroy` to clean up any resources that were created
	defer terraform.Destroy(t, terraformOptions)

	// This will run `terraform init` and `terraform apply` and fail the test if there are any errors
	terraform.InitAndApply(t, terraformOptions)

	// Run `terraform output` to get the value of some of the output variables
	// vnetID := terraform.Output(t, terraformOptions, "vnet_name")
	// rgName := terraform.Output(t, terraformOptions, "rg_name")

	// builder := authentication.Builder{}
	// config, err := builder.Build()
	// assert.NoError(t, err)
	//
	// fmt.Printf("%v", vnetID)
	//
	// networkClient := network.NewVirtualNetworksClient(config.SubscriptionID)
	// res, err := networkClient.Get(context.TODO(), rgName, vnetID, "")
	// if assert.NoError(t, err) {
	// 	fmt.Printf("%v", res)
	// }

	// assert.Contains(t, network.Subnetworks, "10.0.0.0")
	// assert.Contains(t, network.Subnetworks, "10.1.0.0")
}
