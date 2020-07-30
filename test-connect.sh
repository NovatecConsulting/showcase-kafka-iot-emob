for (( c=1; c<=10; c++ ))
do
    docker run -it --rm --name mqtt-publisher --network showcase_emob efrecon/mqtt-client pub -h hivemq -t "test" -m "{\"id\":$c,\"message\":\"This is a test $c\"}"
done
