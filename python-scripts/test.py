import numpy as np
import tensorflow as tf
import tensorflow_io.kafka as kafka_io
import tensorflow_datasets as tfds

with open('XXXX') as f: #specify .avsc with Afro format here
    schema = f.read()

import sys

# incomplete code! WORK IN PROGRESS

print("Options: ", sys.argv)

servers = sys.argv[1]   # which server to use, Kafka Bootstrap server
topic = sys.argv[2]     # name of topic to consume from
offset = sys.argv[3]    # offset to start
result_topic = sys.argv[4]  # name of topic where the results should be written to
mode = sys.argv[5].strip().lower()  # train or predict mode
if mode != "predict" and mode != "train":
    print("Mode is invalid, must be either 'train' or 'predict':", mode)
    sys.exit(1)


def kafka_dataset(servers, topic, offset, schema, eof=True):
    print("Create: ", "{}:0:{}".format(topic, offset))
    dataset = kafka_io.KafkaDataset(["{}:0:{}".format(topic, offset, offset)], servers=servers,
                                    group="XXX", eof=eof, config_global=kafka_config)


# 1. deserialize data
# 2. if mode==train then train model
#    if mode==predict then download and load model, do prediction, write back to result topic
