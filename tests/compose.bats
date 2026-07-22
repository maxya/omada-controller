#!/usr/bin/env bats

@test "host compose keeps mongodb off host ports" {
  run yq -r '.services.mongodb.ports // [] | length' compose/docker-compose.host.yml
  [ "$status" -eq 0 ]
  [ "$output" = "0" ]
}

@test "bridge compose keeps mongodb off host ports" {
  run yq -r '.services.mongodb.ports // [] | length' compose/docker-compose.bridge.yml
  [ "$status" -eq 0 ]
  [ "$output" = "0" ]
}

@test "macvlan compose keeps mongodb off host ports" {
  run yq -r '.services.mongodb.ports // [] | length' compose/docker-compose.macvlan.example.yml
  [ "$status" -eq 0 ]
  [ "$output" = "0" ]
}

@test "host compose keeps controller on host network" {
  run yq -r '.services."omada-controller".network_mode' compose/docker-compose.host.yml
  [ "$status" -eq 0 ]
  [ "$output" = "host" ]
}

@test "host compose names private network omada-controller" {
  run yq -r '.networks."omada-controller".name' compose/docker-compose.host.yml
  [ "$status" -eq 0 ]
  [ "$output" = "omada-controller" ]
}

@test "host compose points controller at private mongodb address" {
  run yq -r '.services."omada-controller".environment.OMADA_MONGODB_URI' compose/docker-compose.host.yml
  [ "$status" -eq 0 ]
  [[ "$output" == *'@${OMADA_MONGO_IPV4:-172.28.0.10}:27017/omada'* ]]
}

@test "bridge compose uses private mongodb network" {
  run yq -r '.services.mongodb.networks[]' compose/docker-compose.bridge.yml
  [ "$status" -eq 0 ]
  [ "$output" = "omada-controller" ]
}

@test "macvlan compose uses private mongodb network" {
  run yq -r '.services.mongodb.networks[]' compose/docker-compose.macvlan.example.yml
  [ "$status" -eq 0 ]
  [ "$output" = "omada-controller" ]
}

@test "host compose controller image matches local tag contract" {
  run yq -r '.services."omada-controller".image' compose/docker-compose.host.yml
  [ "$status" -eq 0 ]
  [[ "$output" == 'local/omada-controller:${OMADA_VERSION:-6.2.10.17}' ]]
}
