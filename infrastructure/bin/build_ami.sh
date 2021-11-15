#!/usr/bin/env bash

packer init infrastructure/ami
packer build infrastructure/ami