package sim

import (
	"fmt"
	"log"
	"math/rand"
	"sync"
	"time"

	mqtt "github.com/eclipse/paho.mqtt.golang"
)

func NewSimulation(simConfig SimConfig) Simulation {
	rand.Seed(time.Now().UnixNano())
	return &simulation{
		stations: simConfig.Stations,
		stationIDFormat: simConfig.StationIDFormat,
		topicOutNameFormat: simConfig.TopicOutNameFormat,
		minSecondsFree: simConfig.MinSecondsFree,
		maxSecondsFree: simConfig.MaxSecondsFree,
		minSecondsInUse: simConfig.MinSecondsInUse,
		maxSecondsInUse: simConfig.MaxSecondsInUse,
		mqttBrokerURI: simConfig.MqttBrokerURI,
		mqttTimeout: 10 * time.Second,
		mqttRetries: 2,
		stop: make(chan struct{})}
}

type simulation struct {
	stations					int64
	stationIDFormat				string
	topicOutNameFormat			string

	minSecondsFree				int64
	maxSecondsFree				int64
	minSecondsInUse				int64
	maxSecondsInUse				int64
	
	mqttBrokerURI				string
	mqttTimeout 				time.Duration
	mqttRetries					int32
	
	stop						chan struct{}
}

func (s *simulation) Start() error {
	log.Printf("Started simulation for %d stations", s.stations)
	mqttClient, err := s.newMqttConnection(fmt.Sprintf("driver%d_%d",1,s.stations))
	if err != nil {
		return fmt.Errorf("Could not connect to %s: %v", s.mqttBrokerURI, err)
	}
	defer mqttClient.Disconnect(uint(s.mqttTimeout.Milliseconds()))
	wg := &sync.WaitGroup{} // new(sync.WaitGroup)
	for no := int64(1); no <= s.stations; no++ {
		wg.Add(1)
		go s.simulateStation(no, mqttClient, wg)
	}
	wg.Wait()
	log.Printf("Stopped simulation for %d stations", s.stations)
	return nil
}

func (s *simulation) Stop() {
	log.Printf("Stopping simulation for %d stations", s.stations)
	close(s.stop)
}

func (s *simulation) newMqttConnection(clientID string) (mqttClient mqtt.Client, err error) {
	mqttClient = s.newMqttClient(clientID)
	err = s.connectMqttClient(&mqttClient)
	return
}

func (s *simulation) newMqttClient(clientID string) mqtt.Client {
	mqttOpts := mqtt.NewClientOptions().
		AddBroker(s.mqttBrokerURI).
		SetClientID(clientID).
		SetKeepAlive(60 * time.Second).
		SetAutoReconnect(true)
	return mqtt.NewClient(mqttOpts)
}

func (s *simulation) connectMqttClient(mqttClient *mqtt.Client) (err error) {
	tries := int32(0)
	for {
		token := (*mqttClient).Connect()

		if !token.WaitTimeout(s.mqttTimeout) && token.Error() == nil {
			tries++
			err = fmt.Errorf("timeout, could not connect within %v", s.mqttTimeout)
		} else if token.Error() != nil {
			tries++
			err = token.Error()
		} else {
			err = nil
		}

		if err == nil || tries > s.mqttRetries {
			return
		}
	}
}

func (s *simulation) simulateStation(no int64, mqttClient mqtt.Client, wg *sync.WaitGroup) {
	defer wg.Done()
	stationConfig := s.newStationConfig(no)
	log.Printf("Started station %s: FreeSeconds[%d;%d], InUseSeconds[%d;%d]", 
		stationConfig.ID, stationConfig.MinSecondsFree, stationConfig.MaxSecondsFree, 
		stationConfig.MinSecondsInUse, stationConfig.MaxSecondsInUse)
	defer log.Printf("Stopped station %s", stationConfig.ID)
	station := NewStation(stationConfig, mqttClient, s.stop)
	if err := station.Start(); err != nil {
		log.Printf("Simulation of station %d aborted: %v", no, err)
	}
}

func (s *simulation) newStationConfig(no int64) StationConfig {
	stationID := fmt.Sprintf(s.stationIDFormat, no)
	topicOut := fmt.Sprintf(s.topicOutNameFormat, stationID)
	minSecondsFree := s.randomInt(s.minSecondsFree, s.maxSecondsFree)
	maxSecondsFree := s.randomInt(minSecondsFree, s.maxSecondsFree)
	minSecondsInUse := s.randomInt(s.minSecondsInUse, s.maxSecondsInUse)
	maxSecondsInUse := s.randomInt(minSecondsInUse, s.maxSecondsInUse)
	return StationConfig{
		ID: stationID,
		TopicOut: topicOut,
		MinSecondsFree: minSecondsFree,
		MaxSecondsFree: maxSecondsFree,
		MinSecondsInUse: minSecondsInUse,
		MaxSecondsInUse: maxSecondsInUse,
	}
}

func (s *simulation) randomInt(min int64, max int64) int64 {
	if min == max {
		return min
	}
    return min + rand.Int63n(max-min)
}