package fetchgeo

import (
	"bufio"
)

type FetchGeoRequest struct {
	OverpassQuery			string
	OverpassQueryVariables	map[string]string
	JqGeoQuery				string
}

type FetchGeo interface {
	Fetch(request FetchGeoRequest, output *bufio.Writer) error
}