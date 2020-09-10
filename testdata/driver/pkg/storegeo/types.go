package storegeo

import (
	"bufio"
)

type StoreGeoMongoDb struct {
	MongoDbURI			string
	MongoDbDatabase		string
	MongoDbCollection	string
}

type StoreGeoMongoDbFieldMapping struct {
	StaionIDField		string
	LatitudeField		string
	LongitudeField		string
}


type StoreGeoRequest struct {
	StationsToStore			int64
	StationToStoreIDFormat  string
}

type StoreGeo interface {
	Store(request StoreGeoRequest, input *bufio.Reader) error
}