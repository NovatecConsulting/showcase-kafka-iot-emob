package main

import (
	"fmt"
	"os"

	"github.com/NovatecConsulting/technologyconsulting-showcase-emob/testdata/driver/cmd"
)

func main() {
	if err := cmd.Execute(); err != nil {
		fmt.Printf("%v\n", err)
		os.Exit(1)
	}
}
