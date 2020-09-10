package sim

import "time"

type SimConfig struct {
	Stations					int64
	StationIDFormat				string
	TopicOutNameFormat			string
	MinSecondsFree				int64
	MaxSecondsFree				int64
	MinSecondsInUse				int64
	MaxSecondsInUse				int64
	MqttBrokerURI				string
}

type Simulation interface {
	Start() error
	Stop()
}

type StationConfig struct {
	ID					string
	TopicOut			string
	MinSecondsFree		int64
	MaxSecondsFree		int64
	MinSecondsInUse		int64
	MaxSecondsInUse		int64		
}

type StationMqttConfig struct {
	RetainMsg	bool
	Timeout		time.Duration
	Retries		int32
}


type Station interface {
	Start() error
}