#!/bin/bash

set -e

function get_nomad_version {
  local nomad_version

  nomad_version=$(nomad -version | grep 'v[0-9]' | sed 's/Nomad v//g')

  echo $nomad_version
}

function get_nomad_major_version {
  local major_version

  major_version=$(get_nomad_version | cut -d'.' -f1)
  echo $major_version
}

function get_nomad_minor_version {
  local minor_version

  minor_version=$(get_nomad_version | cut -d'.' -f2)
  echo $minor_version
}

function get_nomad_build_version {
  local build_version

  minor_version=$(get_nomad_version | cut -d'.' -f3)
  echo $build_version
}
