package cmd

import (
	"fmt"

	"github.com/spf13/cobra"

	"github.com/NovatecConsulting/technologyconsulting-showcase-emob/testdata/driver/pkg/signals"
	"github.com/NovatecConsulting/technologyconsulting-showcase-emob/testdata/driver/pkg/sim"
)

var (
	simCmd = &cobra.Command{
		Use:	"simulate",
		Short:	"simulate is a tool for simulating car charging processes at electrical loading stations.",
		Long:	"simulate is a tool for simulating car charging processes at electrical loading stations.",
		RunE: 	runSimCmd,
	}
	stations					int64
	minSecondsFree				int64
	maxSecondsFree				int64
	minSecondsInUse				int64
	maxSecondsInUse				int64
	stationIDFormat				string
	topicOutFormat				string
	mqttBrokerURI				string
)

func init()  {
	simCmd.PersistentFlags().Int64VarP(&stations, "stations", "s", 1, "Number of stations to simulate")
	simCmd.PersistentFlags().Int64VarP(&minSecondsFree, "min-seconds-free", "a", 30, "Minimum duration in seconds between two charging processes")
	simCmd.PersistentFlags().Int64VarP(&maxSecondsFree, "max-seconds-free", "b", 300, "Maximum duration in seconds between two charging processes")
	simCmd.PersistentFlags().Int64VarP(&minSecondsInUse, "min-seconds-inuse", "c", 30, "Minimum duration of a charging process")
	simCmd.PersistentFlags().Int64VarP(&maxSecondsInUse, "max-seconds-inuse", "d", 300, "Maximum duration of a charging process")
	simCmd.PersistentFlags().StringVarP(&stationIDFormat, "station-id-format", "f", "CIQ%09d", "Format for station id generation, in which value is the station number")
	simCmd.PersistentFlags().StringVarP(&topicOutFormat, "out-topic-format", "o", "%s/out/charge", "Format for station out topic generation, in which value is the station id")	
	simCmd.PersistentFlags().StringVarP(&mqttBrokerURI, "mqtt-broker-uri", "m", "tcp://localhost:1883", "The Mqtt broker URI in the for scheme://host:port, in which 'scheme' is 'tcp' or 'ws'")	
}

func runSimCmd(cmd *cobra.Command, args []string) error {
	stopCh := signals.SetupSignalHandler()
	
	config := sim.SimConfig{
		Stations: stations,
		MinSecondsFree: minSecondsFree,
		MaxSecondsFree: maxSecondsFree,
		MinSecondsInUse: minSecondsInUse,
		MaxSecondsInUse: maxSecondsInUse,
		StationIDFormat: stationIDFormat,
		TopicOutNameFormat: topicOutFormat,
		MqttBrokerURI: mqttBrokerURI,
	}
	simulation := sim.NewSimulation(config)

	go func() {
		<- stopCh
		simulation.Stop()
	}()

	if err := simulation.Start(); err != nil {
		return fmt.Errorf("Could not start simulation: %v", err)
	}

	return nil
}