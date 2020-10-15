package cmd

import (
	"bufio"
	"fmt"
	"os"
	"strings"

	"github.com/spf13/cobra"

	"github.com/NovatecConsulting/technologyconsulting-showcase-emob/testdata/driver/pkg/storegeo"
)

var (
	storeGeoCmd = &cobra.Command{
		Use:	"storegeo",
		Short:	"storegeo is a tool for storing stations with geo location on mongodb.",
		Long:	"storegeo is a tool for storing stations with geo location on mongodb.",
		RunE: 	runStoreGeoCmd,
	}
	geoJSONInputFile		string
	stationsToStore			int64
	stationToStoreIDFormat  string
	mongoDbURI				string
	mongoDbDatabase			string
	mongoDbCollection		string
	fieldStationID			string
	fieldLatitude			string
	fieldLongitude			string
)

func init()  {
	storeGeoCmd.PersistentFlags().StringVarP(&geoJSONInputFile, "in-filename", "f", "", "Json file with geo data, with format matching '[{lat,lon}]'")
	storeGeoCmd.PersistentFlags().Int64VarP(&stationsToStore, "stations-to-store", "l", 1, "Number of stations to to store")
	storeGeoCmd.PersistentFlags().StringVarP(&stationToStoreIDFormat, "station-to-store-id-format", "y", "CIQ%09d", "Format for station id generation, in which value is the station number")
	storeGeoCmd.PersistentFlags().StringVarP(&mongoDbURI, "mongodb-uri", "t", "mongodb://localhost:27017/?replicaSet=rs0", "The connection string for mongo db")
	storeGeoCmd.PersistentFlags().StringVarP(&mongoDbDatabase, "mongodb-database", "g", "mongoDB", "The mongo db database in which the stations should be stored")	
	storeGeoCmd.PersistentFlags().StringVarP(&mongoDbCollection, "mongodb-collection", "k", "WallboxLocation", "The mongo db collection in which the stations should be stored")	
	storeGeoCmd.PersistentFlags().StringVarP(&fieldStationID, "field-stationid", "i", "CLIENT_ID", "The name of the field in which the Station ID is stored")
	storeGeoCmd.PersistentFlags().StringVarP(&fieldLatitude, "field-latitude", "e", "latitude", "The name of the field in which the latitude is stored")
	storeGeoCmd.PersistentFlags().StringVarP(&fieldLongitude, "field-longitude", "j", "longitude", "The name of the field in which the longitude is stored")
}

func runStoreGeoCmd(cmd *cobra.Command, args []string) error {	
	var input *bufio.Reader
	if strings.EqualFold(geoJSONInputFile, "") {
		input = bufio.NewReader(os.Stdin)
	} else {
		file, err := os.Open(geoJSONInputFile)
		if err != nil {
			return fmt.Errorf("could not open output file %s: %v", geoJSONInputFile, err)
		}
		defer file.Close()
		input = bufio.NewReader(file)
	}

	mongoDb := storegeo.StoreGeoMongoDb{
		MongoDbURI: mongoDbURI,
		MongoDbDatabase: mongoDbDatabase,
		MongoDbCollection: mongoDbCollection,
	}
	fieldMapping := storegeo.StoreGeoMongoDbFieldMapping{
		StaionIDField: fieldStationID,
		LatitudeField: fieldLatitude,
		LongitudeField: fieldLongitude,
	}
	storeGeo := storegeo.NewStoreGeoWithFieldMapping(mongoDb, fieldMapping)
	request := storegeo.StoreGeoRequest{
		StationsToStore: stationsToStore,
		StationToStoreIDFormat: stationToStoreIDFormat,
	}
	if err := storeGeo.Store(request, input); err != nil {
		return fmt.Errorf("could not store geo coordinates: %v", err)
	}

	return nil
}
