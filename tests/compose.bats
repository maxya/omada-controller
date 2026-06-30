#!/usr/bin/env bats

@test "host compose keeps mongodb bound to loopback" {
  run yq -r '.services.mongodb.command[]' compose/docker-compose.host.yml
  [ "$status" -eq 0 ]
  [[ "$output" == *"--bind_ip"* ]]
  [[ "$output" == *"127.0.0.1"* ]]
}

@test "host compose controller image matches local tag contract" {
  run yq -r '.services."omada-controller".image' compose/docker-compose.host.yml
  [ "$status" -eq 0 ]
  [[ "$output" == 'local/omada-controller:${OMADA_VERSION:-6.2.10.17}' ]]
}
