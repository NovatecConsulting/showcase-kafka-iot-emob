package fetchgeo

import (
	"bufio"
	"bytes"
	"encoding/json"
	"fmt"
	"net/http"
	"strings"
	"text/template"

	"github.com/itchyny/gojq"
	"github.com/Masterminds/sprig"
)

func NewFetchGeo(overpassInterpreterURI string) FetchGeo {
	return &fetchGeo{overpassInterpreterURI: overpassInterpreterURI}
}

type fetchGeo struct {
	overpassInterpreterURI string
}

func (f *fetchGeo) Fetch(request FetchGeoRequest, output *bufio.Writer) error {
	query, err := f.templateQuery(request.OverpassQuery, request.OverpassQueryVariables)
	if err != nil {
		return fmt.Errorf("Could not template query string: %v", err)
	}
	
	resp, err := http.Post(f.overpassInterpreterURI, "application/x-www-form-urlencoded", strings.NewReader(query))
	if err != nil {
		return fmt.Errorf("Could not query overpass api via '%s': %v", f.overpassInterpreterURI, err)
	} else if resp.StatusCode != 200 {
		return fmt.Errorf("Could not query overpass api via '%s': Status code was %d", f.overpassInterpreterURI, resp.StatusCode)
	}

	jsonMap := make(map[string]interface{})
	jsonDecoer := json.NewDecoder(resp.Body)
	err = jsonDecoer.Decode(&jsonMap)
	if err != nil {
		return fmt.Errorf("Could not decode response to json: %v", err)
	}
	
	parsedJqQuery, err := gojq.Parse(request.JqGeoQuery)
	if err != nil {
		return fmt.Errorf("Could not parse JQ query '%s': %v", request.JqGeoQuery, err)
	}
	encoder := json.NewEncoder(output)
	iter := parsedJqQuery.Run(jsonMap)
	for {
		v, ok := iter.Next()
		if !ok {
			break
		}
		if err, ok := v.(error); ok {
			return fmt.Errorf("Could not apply jq query to overpass result: %v", err)
		}
		if err := encoder.Encode(v); err != nil {
			return fmt.Errorf("Could not write output: %v", err)
		}
	}

	return nil
}

func (f *fetchGeo) templateQuery(query string, variables map[string]string) (string, error) {
	tmpl, err := template.New("").Funcs(sprig.TxtFuncMap()).Parse(query)
	if err != nil {
		return "", fmt.Errorf("Could not parse go template: %v", err)
	}
	var out bytes.Buffer
	if err := tmpl.Execute(&out, variables); err != nil {
		return "", fmt.Errorf("Could not template query: %v", err)
	}
	return out.String(), nil
}