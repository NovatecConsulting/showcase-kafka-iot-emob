package sim

import (
	"fmt"
	"math"
	"math/rand"
	"time"

	mqtt "github.com/eclipse/paho.mqtt.golang"
)

func NewStation(stationConfig StationConfig, mqttClient mqtt.Client, stop chan struct{}) Station {
	return NewStationWithMqttConfig(stationConfig, mqttClient, StationMqttConfig{
		RetainMsg: true,
		Timeout: 10 * time.Second,
		Retries: 2,
	}, stop)
}

func NewStationWithMqttConfig(stationConfig StationConfig, mqttClient mqtt.Client, mqttConfig StationMqttConfig, stop chan struct{}) Station {
	return &station{
		id: stationConfig.ID,
		topicOut: stationConfig.TopicOut,
		minSecondsFree: stationConfig.MinSecondsFree,
		maxSecondsFree: stationConfig.MaxSecondsFree,
		minSecondsInUse: stationConfig.MinSecondsInUse,
		maxSecondsInUse: stationConfig.MaxSecondsInUse,
		mqttClient: mqttClient,
		retainMsg: mqttConfig.RetainMsg,
		timeout: mqttConfig.Timeout,
		retries: mqttConfig.Retries,
		stop: stop,
	}
}

type station struct {
	id					string
	topicOut 			string
	minSecondsFree		int64
	maxSecondsFree		int64
	minSecondsInUse		int64
	maxSecondsInUse		int64
	
	mqttClient 			mqtt.Client
	retainMsg			bool
	timeout 			time.Duration
	retries				int32

	stop				chan struct{}
}

func (s *station) Start() error {
	for {
		if stopped := s.waitFor(2 * time.Second); stopped {
			return nil
		}
		if err := s.publish(s.topicOut, "ready"); err != nil {
			return err
		}

		freeSeconds := s.randomInt(s.minSecondsFree, s.maxSecondsFree)
		if stopped := s.waitFor(time.Duration(freeSeconds) * time.Second); stopped {
			return nil
		}
		if err := s.publish(s.topicOut, "ev"); err != nil {
			return err
		}

		inUseDuration := time.Duration(s.randomInt(s.minSecondsInUse, s.maxSecondsInUse)) * time.Second
		amountPublishIntervalDuration := time.Duration(int64(5)) * time.Second
		amountPublishCount := inUseDuration.Milliseconds() / amountPublishIntervalDuration.Milliseconds()
		amountPublishRestDuration := inUseDuration % amountPublishIntervalDuration

		maxAmount := int64(20)
		completionAmount := s.completionAmountWithProbability(maxAmount, 0.9)

		if stopped := s.waitFor(2 * time.Second); stopped {
			return nil
		}
		startTime := time.Now()
		if err := s.publish(s.topicOut, fmt.Sprintf("charging %d/%d", 0, maxAmount)); err != nil {
			return err
		}

		for r := int64(0); r < amountPublishCount; r++ {
			if stopped := s.waitFor(amountPublishIntervalDuration); stopped {
				return nil
			}
			currentAmount := s.currentChargingAmount(startTime, inUseDuration, completionAmount)
			if err := s.publish(s.topicOut, fmt.Sprintf("charging %d/%d", currentAmount, maxAmount)); err != nil {
				return err
			}
		}

		if stopped := s.waitFor(amountPublishRestDuration); stopped {
			return nil
		}
		if err := s.publish(s.topicOut, fmt.Sprintf("charged; amount %d of %d", completionAmount, maxAmount)); err != nil {
			return err
		}
	}
}

func (s *station) waitFor(duration time.Duration) (stopped bool) {
	select {
	case <-s.stop:
		stopped = true
	case <- time.After(duration):
		stopped = false
	}
	return
}

func (s *station) publish(topic string, msg string) (err error) {
	tries := int32(0)
	for {
		token := s.mqttClient.Publish(topic, 0, s.retainMsg, msg)

		if !token.WaitTimeout(s.timeout) && token.Error() == nil {
			tries++
			err = fmt.Errorf("timeout, could not connect within %v", s.timeout)
		} else if token.Error() != nil {
			tries++
			err = token.Error()
		} else {
			err = nil
		}

		if err == nil || tries > s.retries {
			return
		}
	}
}

func (s *station) completionAmountWithProbability(maxAmount int64, probabilityCompletion float64) int64 {
	if shouldComplete := s.randomBool(probabilityCompletion); shouldComplete {
		return maxAmount
	}
	return s.randomInt(maxAmount / 2, maxAmount - 1)
}

func (s *station) randomBool(probabilityTrue float64) bool {
	precision := 1000
	val := s.randomInt(1, int64(precision))
	if val <= int64(math.Round(probabilityTrue * float64(precision))) {
		return true
	}
    return false
}

func (s *station) randomInt(min int64, max int64) int64 {
	if min == max {
		return min
	}
    return min + rand.Int63n(max-min)
}

func (s* station) currentChargingAmount(startTime time.Time, totalDuration time.Duration, completionAmount int64) int64 {
	now := time.Now()
	currentDuration := time.Duration(now.Unix() - startTime.Unix()) * time.Second
	completionPercentage := currentDuration.Seconds() / totalDuration.Seconds()
	return int64(math.Floor(completionPercentage * float64(completionAmount)))
}