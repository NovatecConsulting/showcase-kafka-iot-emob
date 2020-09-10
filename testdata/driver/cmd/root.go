package cmd

import (
	"strings"

	"github.com/spf13/cobra"
)
var (
	rootCmd = &cobra.Command{
		Use:	"driver",
		Short:	"driver is a tool for simulating car charging processes at electrical loading stations.",
		Long:	"driver is a tool for simulating car charging processes at electrical loading stations.",
	}
)

func Execute() error {
	return rootCmd.Execute()
}

func init()  {
	rootCmd.AddCommand(fetchGeoCmd)
	rootCmd.AddCommand(storeGeoCmd)
	rootCmd.AddCommand(simCmd)
}

func parseBool(value string) bool {
	if strings.EqualFold(value, "true") {
		return true
	}
	return false
}
