package storegeo

import (
	"bufio"
	"context"
	"encoding/json"
	"fmt"
	"log"
	"math/rand"
	"time"

	"go.mongodb.org/mongo-driver/bson"
	"go.mongodb.org/mongo-driver/mongo"
	"go.mongodb.org/mongo-driver/mongo/options"
)

func NewStoreGeo(mongoDb StoreGeoMongoDb) StoreGeo {
	return NewStoreGeoWithFieldMapping(
		mongoDb,
		StoreGeoMongoDbFieldMapping{
			StaionIDField: "CLIENT_ID",
			LatitudeField: "latitude",
			LongitudeField: "longitude",
		},
	)
}

func NewStoreGeoWithFieldMapping(mongoDb StoreGeoMongoDb, fieldMapping StoreGeoMongoDbFieldMapping) StoreGeo {
	return &storeGeo{mongoDb: mongoDb, fieldMapping: fieldMapping}
}

type storeGeo struct {
	mongoDb 	 StoreGeoMongoDb
	fieldMapping StoreGeoMongoDbFieldMapping
}

type stationLocation struct {
	Station *string
	Lat 	float32 `json:"lat"`
	Lon 	float32 `json:"lon"`
}

func (s *storeGeo) Store(request StoreGeoRequest, input *bufio.Reader) error {
	locations, err := s.jsonToStruct(input)
	if err != nil {
		return fmt.Errorf("Could not decode to json: %v", err)
	}
	locationCount := int64(len(locations))
	if request.StationsToStore > locationCount {
		return fmt.Errorf("Could not store more than %d stations", locationCount)
	}

	s.assignStations(request.StationsToStore, request.StationToStoreIDFormat, locations)

	err = s.storeAssignedStationsToDB(locations)
	if err != nil {
		return fmt.Errorf("Could not store stations to db: %v", err)
	}

	return nil
}

func (s *storeGeo) jsonToStruct(input *bufio.Reader) ([]stationLocation, error) {
	locations := make([]stationLocation,0)
	geosDecoder := json.NewDecoder(input)
	if err := geosDecoder.Decode(&locations); err != nil {
		return nil, err
	}
	return locations, nil
}

func (s *storeGeo) assignStations(stationCount int64, stationIDFormat string, locations []stationLocation) {
	rand.Seed(time.Now().UnixNano())
	for i := int64(1); i <= stationCount; i++ {
		var locationPos int64
		for {
			locationPos = s.randomInt(0, int64(len(locations)) - 1)
			if locations[locationPos].Station == nil {
				break
			}
		}
		stationID := fmt.Sprintf(stationIDFormat, i)
		locations[locationPos].Station = &stationID
	}
}

func (s *storeGeo) randomInt(min int64, max int64) int64 {
	return min + rand.Int63n(max-min)
}

func (s *storeGeo) storeAssignedStationsToDB(locations []stationLocation) error {
	ctx, _ := context.WithTimeout(context.Background(), 10*time.Second)
	client, err := s.connectToMongoDb(ctx)
	if err != nil {
		return err
	}
	log.Printf("Connected to MongoDB!")
	defer client.Disconnect(ctx)

	collection := client.Database(s.mongoDb.MongoDbDatabase).Collection(s.mongoDb.MongoDbCollection)
	log.Printf("Start loading stations to %s", s.mongoDb.MongoDbCollection)
	count := 0
	for _, location := range locations {
		if location.Station != nil {
			_, err := collection.InsertOne(ctx, bson.D{
				{s.fieldMapping.StaionIDField, location.Station},
				{s.fieldMapping.LatitudeField, location.Lat},
				{s.fieldMapping.LongitudeField, location.Lon},
			})
			if err != nil {
				return err
			}
			count++
		}
	}
	log.Printf("Stored %d stations in %s", count, s.mongoDb.MongoDbCollection)
	return nil
}

func (s *storeGeo) connectToMongoDb(ctx context.Context) (*mongo.Client, error) {
	clientOptions := options.Client().ApplyURI(s.mongoDb.MongoDbURI)
	// Connect to MongoDB
	client, err := mongo.Connect(ctx, clientOptions)
	if err != nil {
		return nil, err
	}
	log.Printf("Connected")
	// Check the connection
	err = client.Ping(ctx, nil)
	if err != nil {
		return nil, err
	}
	return client, nil
}