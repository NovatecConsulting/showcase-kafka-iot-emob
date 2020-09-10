package cmd

import (
	"bufio"
	"fmt"
	"io"
	"os"
	"regexp"
	"strings"

	"github.com/spf13/cobra"

	"github.com/NovatecConsulting/technologyconsulting-showcase-emob/testdata/driver/pkg/fetchgeo"
)

var (
	fetchGeoCmd = &cobra.Command{
		Use:	"fetchgeo",
		Short:	"fetchgeo is a tool for fetching geo coordinates from osm via overpass api.",
		Long:	"fetchgeo is a tool for fetching geo coordinates from osm via overpass api.",
		RunE: 	runFetchGeoCmd,
	}
	overpassInterpreterURI	string
	overpassQuery			string
	overpassQueryVariables	*[]string
	jqGeoQuery				string
	outputFilename			string
	toStdOut				string

	defaultOverpassQuery 	string = `
		[out:json];
		area["ISO3166-1"="{{ .country | default "DE" }}"][admin_level=2];
		(node["amenity"="{{ .amenity | default "charging_station" }}"](area););
		out center;`
)

func init()  {
	fetchGeoCmd.PersistentFlags().StringVarP(&overpassInterpreterURI, "overpass-interpreter-uri", "i", "https://overpass-api.de/api/interpreter", "The overpass interpreter to use")
	fetchGeoCmd.PersistentFlags().StringVarP(&overpassQuery, "overpass-query", "q", defaultOverpassQuery, "The overpass query to use")
	overpassQueryVariables = fetchGeoCmd.PersistentFlags().StringSliceP("overpass-query-vars", "v", []string{}, "Variables for the overpass query")
	fetchGeoCmd.PersistentFlags().StringVarP(&jqGeoQuery, "jq-geo-query", "j", ".elements | map({lat,lon})", "The jq query to use, in order to map to a format matching '[{lat,lon}]'")
	fetchGeoCmd.PersistentFlags().StringVarP(&outputFilename, "out-filename", "o", "", "File to which the output should be written. If the file already exists, the query is not executed")
	fetchGeoCmd.PersistentFlags().StringVarP(&toStdOut, "to-stdout", "p", "true", "Defines wheater to print the output to stdout")
}

func runFetchGeoCmd(cmd *cobra.Command, args []string) error {
	
	if strings.EqualFold(outputFilename, "") && ! parseBool(toStdOut) {
		return fmt.Errorf("no output specified")
	}

	var onlyStdout   bool
	var onlyFileout  bool
	var outputExists bool

	if strings.EqualFold(outputFilename, "") && parseBool(toStdOut) {
		onlyStdout = true
	} else if ! strings.EqualFold(outputFilename, "") {
		if ! parseBool(toStdOut) {
			onlyFileout = true
		}
		if stat, err := os.Stat(outputFilename); err == nil && stat.Size() > 0 {
			outputExists = true
		} 
	}

	if onlyStdout || ! outputExists {
		var out *bufio.Writer
		if onlyStdout {
			out = bufio.NewWriter(os.Stdout)
		} else {
			file, err := os.Create(outputFilename);
			if err != nil {
				return fmt.Errorf("could not create output file %s: %v", outputFilename, err)
			}
			defer file.Close()
			out = bufio.NewWriter(file)
		}
		
		fetchGeo := fetchgeo.NewFetchGeo(overpassInterpreterURI)
		
		var overpassQueryVariableMap = make(map[string]string)
		pattern := regexp.MustCompile(`(?P<Key>.+)=(?P<Value>.+)`)
		for _, element := range *overpassQueryVariables {
			keyvalue := pattern.FindStringSubmatch(element)
			if keyvalue == nil || len(keyvalue) < 3 {
				return fmt.Errorf("'%s' is no valid variable assignment", element)
			}
			overpassQueryVariableMap[keyvalue[1]] = keyvalue[2]
		}
	
		request := fetchgeo.FetchGeoRequest{
			OverpassQuery: overpassQuery, 
			OverpassQueryVariables: overpassQueryVariableMap,
			JqGeoQuery: jqGeoQuery,
		}
		if err := fetchGeo.Fetch(request, out); err != nil {
			return fmt.Errorf("could not fetch geo data: %v", err)
		}
	}
	
	if ! onlyStdout && ! onlyFileout {
		file, err := os.Open(outputFilename)
		if err != nil {
			return fmt.Errorf("could not open output file %s: %v", outputFilename, err)
		}
		defer file.Close()
		
		_, err = io.Copy(bufio.NewWriter(os.Stdout), bufio.NewReader(file))
		if err != nil {
			return fmt.Errorf("could not write file %s to stdout: %v", outputFilename, err)
		}
	}

	return nil
}